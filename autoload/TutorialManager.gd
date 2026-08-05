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


var _popup_queue: Array = []
var _is_popup_active: bool = false

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
	
	var data = tutorial_registry[tutorial_id]
	sig_tutorial_triggered.emit(data)
	
	if not GameState.is_tutorial_mode and not SettingsManager.tutorial_tips:
		return
	
	if _is_popup_active:
		_popup_queue.append(data)
	else:
		_show_popup(data)

func _show_popup(data: Dictionary) -> void:
	_is_popup_active = true
	var popup_scene = load("res://scenes/ingame/hud/TutorialPopup.tscn")
	var popup = popup_scene.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.set_content(data)
	popup.tree_exited.connect(_on_popup_closed)

func _on_popup_closed() -> void:
	if _popup_queue.size() > 0:
		var next_data = _popup_queue.pop_front()
		# We use call_deferred to avoid instantiating while the previous is still in tree_exited
		call_deferred("_show_popup", next_data)
	else:
		_is_popup_active = false
		
# =============================================================================
func get_unlocked_data(category: String = "") -> Array:
	var result = []
	for t_id in unlocked_tutorials:
		if tutorial_registry.has(t_id):
			var tut = tutorial_registry[t_id]
			if category == "" or tut.get("category", "tutorial") == category:
				result.append(tut)
	return result

func get_all_data_for_category(category: String = "") -> Array:
	var result = []
	
	if category == "rooms" and GameState:
		for r_id in GameState.room_registry:
			var def = GameState.room_registry[r_id].get("def", {})
			if not def.get("in_build_menu", false):
				continue
				
			var img_path = "res://assets/roomtypes/" + r_id + ".aseprite"
			if r_id == "kitchen_small":
				img_path = "res://assets/roomtypes/kittchen_small.aseprite"
				
			if not ResourceLoader.exists(img_path):
				img_path = def.get("icon", "")
				
			var entry = {
				"id": "room_" + r_id,
				"category": "rooms",
				"title_key": def.get("name", "tutorial.room_" + r_id + ".title"),
				"desc_key": "tutorial.room_" + r_id + ".desc",
				"image": img_path
			}
			result.append(entry)
			
	for t_id in tutorial_registry.keys():
		var tut = tutorial_registry[t_id]
		if category == "" or tut.get("category", "tutorial") == category:
			# Skip if it's already dynamically added
			var already_added = false
			for r in result:
				if r.get("id", "") == tut.get("id", ""):
					already_added = true
					# Optional: Merge specific properties like custom title_key or desc_key if they differ in json
					if tut.has("desc_key"): r["desc_key"] = tut["desc_key"]
					if tut.has("title_key"): r["title_key"] = tut["title_key"]
					break
			if not already_added:
				result.append(tut)
				
	return result
