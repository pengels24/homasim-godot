extends Node

signal sig_tutorial_unlocked(tutorial_id: String)
signal sig_tutorial_triggered(tutorial_data: Dictionary)

const CONFIG_PATH = "res://config/tutorials.json"

var tutorial_registry: Dictionary = {}
var unlocked_tutorials: Array = []

# =============================================================================
func _ready() -> void:
	_load_config()

# =============================================================================
func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("[TutorialManager] Konnte tutorials.json nicht finden: " + CONFIG_PATH)
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY and data.has("tutorials"):
			var tuts = data["tutorials"]
			tutorial_registry.clear()
			for tut in tuts:
				var t_id = tut.get("id", "")
				if t_id != "":
					tutorial_registry[t_id] = tut

		else:
			push_error("[TutorialManager] Ungültiges Format in tutorials.json")
	else:
		push_error("[TutorialManager] JSON Parse Error in tutorials.json")

# =============================================================================
func load_state(saved_state: Array) -> void:
	unlocked_tutorials = saved_state.duplicate()


# =============================================================================
func get_state() -> Array:
	return unlocked_tutorials

# =============================================================================
func reset_all() -> void:
	unlocked_tutorials.clear()
	if GameState.selected_hotel != null and not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["tutorials"] = []
		SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)


# =============================================================================
func trigger(tutorial_id: String) -> void:
	if not tutorial_registry.has(tutorial_id):
		return
		
	if unlocked_tutorials.has(tutorial_id):
		return # Already seen
		
	# Unlock new tutorial
	unlocked_tutorials.append(tutorial_id)
	
	# Save state
	if GameState.selected_hotel != null and not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["tutorials"] = get_state()
		SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
		
	sig_tutorial_unlocked.emit(tutorial_id)
	
	# Trigger UI Popup
	var data = tutorial_registry[tutorial_id]
	sig_tutorial_triggered.emit(data)
	
	var popup_scene = load("res://scenes/ingame/hud/TutorialPopup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.set_content(data)

# =============================================================================
func get_unlocked_data(category: String = "") -> Array:
	var result = []
	for t_id in unlocked_tutorials:
		if tutorial_registry.has(t_id):
			var tut = tutorial_registry[t_id]
			if category == "" or tut.get("category", "tutorial") == category:
				result.append(tut)
	return result
