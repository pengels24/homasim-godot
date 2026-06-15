extends Node

signal sig_tech_unlocked(tech_id: String)
signal sig_techtree_loaded

const CONFIG_PATH = "res://config/techtree.json"

var tech_registry: Dictionary = {}
var unlocked_techs: Array = []


# =============================================================================
func _ready() -> void:
	_load_config()


# =============================================================================
func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
		push_error("[TechtreeManager] Konnte techtree.json nicht finden: " + CONFIG_PATH)
		return

	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		var data = json.data
		if typeof(data) == TYPE_DICTIONARY and data.has("tech_nodes"):
			for node in data["tech_nodes"]:
				var tech_id = node.get("id", "")
				if tech_id != "":
					tech_registry[tech_id] = node
			print("[TechtreeManager] %d Tech-Nodes geladen." % tech_registry.size())
			sig_techtree_loaded.emit()
		else:
			push_error("[TechtreeManager] Ungültiges Format in techtree.json")
	else:
		push_error("[TechtreeManager] JSON Parse Error in techtree.json: " + json.get_error_message())


# =============================================================================
func load_state(saved_techs: Array) -> void:
	unlocked_techs = saved_techs.duplicate()
	print("[TechtreeManager] Gespeicherte Techs geladen: ", unlocked_techs.size())


# =============================================================================
func get_state() -> Array:
	return unlocked_techs


# =============================================================================
func is_tech_unlocked(tech_id: String) -> bool:
	return unlocked_techs.has(tech_id)


# =============================================================================
func get_tech_node(tech_id: String) -> Dictionary:
	return tech_registry.get(tech_id, {})


# =============================================================================
func is_tech_available(tech_id: String) -> bool:
	# Tier-Gate (Generell erst ab Hotel-Level 5)
	if GameState.selected_hotel.get("level", 1) < 5:
		return false
		
	var tech = get_tech_node(tech_id)
	if tech.is_empty():
		return false
		
	# Sind wir schon freigeschaltet?
	if is_tech_unlocked(tech_id):
		return false
		
	# Haben wir genug FP?
	var current_fp = GameState.selected_hotel.get("fp", 0)
	if current_fp < tech.get("cost_fp", 0):
		return false
		
	# Haben wir genug Geld?
	var current_money = GameState.selected_hotel.get("money", 0)
	if current_money < tech.get("cost_money", 0):
		return false
		
	# Sind alle Abhängigkeiten erfüllt?
	var deps = tech.get("dependencies", [])
	for dep in deps:
		if not is_tech_unlocked(dep):
			return false
			
	return true


# =============================================================================
func unlock_tech(tech_id: String) -> bool:
	if not is_tech_available(tech_id):
		return false
		
	var tech = get_tech_node(tech_id)
	
	# Kosten abziehen
	GameState.add_fp(-tech.get("cost_fp", 0))
	FinanceManager.add_transaction(-tech.get("cost_money", 0), "research", "Forschung: " + tech.get("name", "Unknown"))
	
	# Eintragen
	unlocked_techs.append(tech_id)
	
	# Speichern
	GameState.selected_hotel["unlocked_techs"] = get_state()
	SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
	
	sig_tech_unlocked.emit(tech_id)
	QuestManager.check_and_activate_quests()
	return true
