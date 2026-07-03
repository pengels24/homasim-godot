extends Node

signal sig_tech_unlocked(tech_id: String)
signal sig_techtree_loaded
signal sig_tier_unlocked(tier_id: String)

const CONFIG_PATH = "res://config/techtree.json"

var tech_registry: Dictionary = {}
var unlocked_techs: Array = []
var unlocked_tiers: Array = []
var tiers_config: Dictionary = {}

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
		if typeof(data) == TYPE_DICTIONARY and data.has("tiers"):
			tiers_config = data["tiers"]
			tech_registry.clear()
			
			for tier_id in tiers_config:
				var tier_data = tiers_config[tier_id]
				var nodes = tier_data.get("nodes", [])
				for node in nodes:
					var tech_id = node.get("id", "")
					if tech_id != "":
						node["tier"] = tier_id
						tech_registry[tech_id] = node
			

			sig_techtree_loaded.emit()
		else:
			push_error("[TechtreeManager] Ungültiges Format in techtree.json")
	else:
		push_error("[TechtreeManager] JSON Parse Error in techtree.json: " + json.get_error_message())

# =============================================================================
func load_state(saved_state: Dictionary) -> void:
	unlocked_techs = saved_state.get("techs", []).duplicate()
	unlocked_tiers = saved_state.get("tiers", ["1"]).duplicate()
	if unlocked_tiers.is_empty(): unlocked_tiers.append("1")


# =============================================================================
func get_state() -> Dictionary:
	return {
		"techs": unlocked_techs,
		"tiers": unlocked_tiers
	}

# =============================================================================
func is_tech_unlocked(tech_id: String) -> bool:
	return unlocked_techs.has(tech_id)

# =============================================================================
func is_tier_unlocked(tier_id: String) -> bool:
	return unlocked_tiers.has(tier_id)

# =============================================================================
func get_tech_node(tech_id: String) -> Dictionary:
	return tech_registry.get(tech_id, {})

# =============================================================================
func can_unlock_tier(tier_id: String) -> bool:
	if is_tier_unlocked(tier_id): return false
	
	var tier_data = tiers_config.get(tier_id, {})
	var gate = tier_data.get("gate", {})
	
	var req_level = gate.get("req_level", 0)
	if GameState.selected_hotel.get("level", 1) < req_level:
		return false
		
	var req_stars = gate.get("req_stars", 0)
	if GameState.selected_hotel.get("stars", 0) < req_stars:
		return false
		
	var req_items = gate.get("req_items_unlocked", 0)
	var unlocked_in_prev_tier = 0
	if req_items > 0:
		var prev_tier_id = str(int(tier_id) - 1)
		var prev_tier_data = tiers_config.get(prev_tier_id, {})
		var prev_nodes = prev_tier_data.get("nodes", [])
		for n in prev_nodes:
			if is_tech_unlocked(n.get("id", "")):
				unlocked_in_prev_tier += 1
		if unlocked_in_prev_tier < req_items:
			return false
			
	var cost_fp = gate.get("cost_fp", 0)
	if GameState.selected_hotel.get("fp", 0) < cost_fp:
		return false
		
	return true

# =============================================================================
func unlock_tier(tier_id: String) -> bool:
	if not can_unlock_tier(tier_id): return false
	
	var tier_data = tiers_config.get(tier_id, {})
	var gate = tier_data.get("gate", {})
	var cost_fp = gate.get("cost_fp", 0)
	
	if cost_fp > 0:
		GameState.add_fp(-cost_fp)
		
	unlocked_tiers.append(tier_id)
	GameState.selected_hotel["techtree"] = get_state()
	SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
	
	sig_tier_unlocked.emit(tier_id)
	return true

# =============================================================================
func is_tech_available(tech_id: String) -> bool:
	var tech = get_tech_node(tech_id)
	if tech.is_empty(): return false
	
	# Check if the tier is unlocked
	if not is_tier_unlocked(tech.get("tier", "1")):
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
		
	# Spezifische Node-Voraussetzungen
	if GameState.selected_hotel.get("level", 1) < tech.get("req_level", 0):
		return false
	if GameState.selected_hotel.get("stars", 0) < tech.get("req_stars", 0):
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
	FinanceManager.add_transaction(-tech.get("cost_money", 0), "research", "tx.research|" + GameState.T(tech.get("name", "Unknown")))
	
	# Eintragen
	unlocked_techs.append(tech_id)
	
	# Speichern
	GameState.selected_hotel["techtree"] = get_state()
	SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
	
	sig_tech_unlocked.emit(tech_id)
	QuestManager.check_and_activate_quests()
	return true
