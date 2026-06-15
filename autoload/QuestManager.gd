extends Node

var quests_db: Dictionary = {}

signal sig_quest_progress_updated(quest_id: String, progress: int, max_val: int)
signal sig_quest_claimable(quest_id: String)
signal sig_quest_claimed(quest_id: String)

# =============================================================================
func _ready() -> void:
	_load_quests_db()
	GameState.sig_room_built.connect(on_room_built)

# =============================================================================
func _load_quests_db() -> void:
	var path = "res://config/quests.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if typeof(json) == TYPE_DICTIONARY:
			quests_db = json
		else:
			push_error("QuestManager: Invalid quests.json format")

# =============================================================================
func check_and_activate_quests() -> void:
	if GameState.selected_hotel.is_empty(): return
	
	if not GameState.selected_hotel.has("quests"):
		GameState.selected_hotel["quests"] = {}
		
	var active_quests = GameState.selected_hotel["quests"]
	
	# Sammle alle "next_quests", um sie bei der Auto-Aktivierung zu ignorieren
	var follow_up_quests = []
	for q_id in quests_db:
		var nq = quests_db[q_id].get("next_quest", "")
		if nq != "": follow_up_quests.append(nq)
	
	for q_id in quests_db:
		if active_quests.has(q_id):
			continue # Bereits aktiv, einlösbar oder abgeschlossen
			
		# Wenn es eine Folgequest ist, wird sie nur durch claim_quest() getriggert!
		if q_id in follow_up_quests:
			continue
		
		var q_data = quests_db[q_id]
		var req_tech = q_data.get("requires_tech", "")
		
		# Wenn keine Voraussetzung oder die Voraussetzung erforscht ist -> Quest aktivieren!
		if req_tech == "" or TechtreeManager.is_tech_unlocked(req_tech):
			active_quests[q_id] = { "progress": 0, "state": "active" }

# =============================================================================
func on_room_built(room_id: String) -> void:
	if GameState.selected_hotel.is_empty(): return
	var active_quests = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for q_id in quests_db:
		var state_data = active_quests.get(q_id)
		if state_data == null or state_data.get("state") != "active":
			continue
		
		var q_data = quests_db[q_id]
		if q_data.get("type") == "build_room" and q_data.get("target_id") == room_id:
			state_data["progress"] = state_data.get("progress", 0) + 1
			var max_val = q_data.get("target_count", 1)
			sig_quest_progress_updated.emit(q_id, state_data["progress"], max_val)
			
			if state_data["progress"] >= max_val:
				state_data["state"] = "claimable"
				sig_quest_claimable.emit(q_id)
				Toast.show("Quest abgeschlossen: " + q_data.get("name", q_id))
			changed = true
			
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func claim_quest(q_id: String) -> void:
	var active_quests = GameState.selected_hotel.get("quests", {})
	var state_data = active_quests.get(q_id)
	
	if state_data != null and state_data.get("state") == "claimable":
		var q_data = quests_db[q_id]
		
		# Belohnung ausschütten
		GameState.add_fp(q_data.get("reward_fp", 0))
		FinanceManager.add_transaction(q_data.get("reward_money", 0), "quest", "Belohnung: " + q_data.get("name", ""))
		
		state_data["state"] = "claimed"
		sig_quest_claimed.emit(q_id)
		
		# Nächste Quest in der Reihe freischalten (falls vorhanden)
		var next_q = q_data.get("next_quest", "")
		if next_q != "" and quests_db.has(next_q):
			active_quests[next_q] = { "progress": 0, "state": "active" }
			Toast.show("Neue Quest verfügbar: " + quests_db[next_q].get("name", ""))
		
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func get_quests_by_state(state_filter: String) -> Array:
	var result = []
	if GameState.selected_hotel.is_empty(): return result
	
	var active_quests = GameState.selected_hotel.get("quests", {})
	for q_id in active_quests:
		if active_quests[q_id].get("state") == state_filter:
			var entry = quests_db[q_id].duplicate()
			entry["id"] = q_id
			entry["progress"] = active_quests[q_id].get("progress", 0)
			result.append(entry)
	
	return result
