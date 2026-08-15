extends Node

var quests_db: Dictionary = {}
var flat_targets: Dictionary = {}

signal sig_quest_progress_updated(quest_id: String, progress: int, max_val: int)
signal sig_quest_claimable(quest_id: String)
signal sig_quest_claimed(quest_id: String)
signal sig_rank_claimable(cat_id: String)
signal sig_rank_claimed(cat_id: String)

# =============================================================================
func _ready() -> void:
	_load_quests_db()
	GameState.sig_room_built.connect(on_room_built)
	GameState.sig_room_demolished.connect(on_room_demolished)
	if TimeManager:
		TimeManager.sig_day_ended.connect(_on_day_ended_hook)

# =============================================================================
func _load_quests_db() -> void:
	var path = "res://config/quests.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		if typeof(json) == TYPE_DICTIONARY:
			quests_db = json
			
			flat_targets.clear()
			var cats = quests_db.get("categories", {})
			for cat_id in cats:
				var ranks = cats[cat_id].get("ranks", {})
				for rank_id in ranks:
					var targets = ranks[rank_id].get("targets", [])
					for t in targets:
						t["category"] = cat_id
						t["rank"] = rank_id
						flat_targets[t["id"]] = t
		else:
			push_error("QuestManager: Invalid quests.json format")

# =============================================================================
func check_and_activate_quests() -> void:
	if GameState.selected_hotel.is_empty(): return
	
	if not GameState.selected_hotel.has("quests"):
		GameState.selected_hotel["quests"] = {}
		
	var active_quests = GameState.selected_hotel["quests"]
	var cats = quests_db.get("categories", {})
	var changed = false
	
	for cat_id in cats:
		if not active_quests.has(cat_id):
			active_quests[cat_id] = {
				"current_rank": 1,
				"rank_claimable": false,
				"targets": {}
			}
			_activate_rank(cat_id, "1")
			changed = true
			
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func _activate_rank(cat_id: String, rank_id: String) -> void:
	var cat_state = GameState.selected_hotel["quests"][cat_id]
	cat_state["targets"].clear()
	
	var ranks = quests_db["categories"][cat_id].get("ranks", {})
	if ranks.has(rank_id):
		for t in ranks[rank_id].get("targets", []):
			var t_id = t["id"]
			var t_def = flat_targets[t_id]
			var start_prog = 0
			var max_val = t_def.get("target_count", 1)
			
			if t_def["type"] == "build_room":
				var room_count = 0
				for room in GameState.selected_hotel.get("rooms", []):
					if room.get("type") == t_def["target_id"]:
						room_count += 1
				start_prog = min(room_count, max_val)
			else:
				var stats = GameState.selected_hotel.get("quest_stats", {})
				var stat_key = t_def["type"]
				if t_def.get("target_id", "") != "":
					stat_key += "_" + t_def["target_id"]
				start_prog = min(stats.get(stat_key, 0), max_val)
				
			cat_state["targets"][t_id] = { "progress": start_prog, "state": "active" }
			if start_prog >= max_val:
				cat_state["targets"][t_id]["state"] = "claimable"

# =============================================================================
func on_room_built(room_id: String) -> void:
	if GameState.selected_hotel.is_empty(): return
	var quest_state = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for cat_id in quest_state:
		var cat_data = quest_state[cat_id]
		var targets_state = cat_data.get("targets", {})
		
		for t_id in targets_state:
			var t_state = targets_state[t_id]
			if t_state["state"] != "active": continue
			
			var t_def = flat_targets[t_id]
			
			# Check requirements
			var req_tech = t_def.get("requires_tech", "")
			if req_tech != "" and not TechtreeManager.is_tech_unlocked(req_tech):
				continue # Cannot progress if tech is not unlocked
			
			if t_def["type"] == "build_room" and t_def["target_id"] == room_id:
				t_state["progress"] += 1
				var max_val = t_def.get("target_count", 1)
				sig_quest_progress_updated.emit(t_id, t_state["progress"], max_val)
				
				if t_state["progress"] >= max_val:
					t_state["state"] = "claimable"
					sig_quest_claimable.emit(t_id)
					Toast.show(GameState.T("toast.quest.completed", GameState.T(t_def.get("name", ""))), "quest")
				changed = true
				
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func on_guest_checkout(guest_type: String) -> void:
	if GameState.selected_hotel.is_empty(): return
	var quest_state = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for cat_id in quest_state:
		var cat_data = quest_state[cat_id]
		var targets_state = cat_data.get("targets", {})
		
		for t_id in targets_state:
			var t_state = targets_state[t_id]
			if t_state["state"] != "active": continue
			
			var t_def = flat_targets[t_id]
			
			var req_tech = t_def.get("requires_tech", "")
			if req_tech != "" and not TechtreeManager.is_tech_unlocked(req_tech):
				continue
			
			if t_def["type"] == "serve_guests" and t_def["target_id"] == guest_type:
				t_state["progress"] += 1
				var max_val = t_def.get("target_count", 1)
				sig_quest_progress_updated.emit(t_id, t_state["progress"], max_val)
				
				if t_state["progress"] >= max_val:
					t_state["state"] = "claimable"
					sig_quest_claimable.emit(t_id)
					Toast.show(GameState.T("toast.quest.completed", GameState.T(t_def.get("name", ""))), "quest")
				changed = true
				
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)
		
	_increment_quest_progress("total_guests", "")


# =============================================================================
func _increment_quest_progress(quest_type: String, target_id: String, amount: int = 1) -> void:
	if GameState.selected_hotel.is_empty(): return
	
	if not GameState.selected_hotel.has("quest_stats"):
		GameState.selected_hotel["quest_stats"] = {}
		
	var stat_key = quest_type
	if target_id != "":
		stat_key += "_" + target_id
		
	var current_val = GameState.selected_hotel["quest_stats"].get(stat_key, 0)
	current_val += amount
	GameState.selected_hotel["quest_stats"][stat_key] = current_val
	
	var quest_state = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for cat_id in quest_state:
		var cat_data = quest_state[cat_id]
		var targets_state = cat_data.get("targets", {})
		
		for t_id in targets_state:
			var t_state = targets_state[t_id]
			if t_state["state"] != "active": continue
			
			var t_def = flat_targets[t_id]
			
			var req_tech = t_def.get("requires_tech", "")
			if req_tech != "" and not TechtreeManager.is_tech_unlocked(req_tech):
				continue
			
			if t_def["type"] == quest_type and (t_def.get("target_id", "") == target_id or target_id == ""):
				var max_val = t_def.get("target_count", 1)
				if t_state["progress"] < max_val:
					t_state["progress"] = min(current_val, max_val)
					sig_quest_progress_updated.emit(t_id, t_state["progress"], max_val)
					changed = true
					
				if t_state["progress"] >= max_val and t_state["state"] == "active":
					t_state["state"] = "claimable"
					sig_quest_claimable.emit(t_id)
					Toast.show(GameState.T("toast.quest.completed", GameState.T(t_def.get("name", ""))), "quest")
					changed = true
					
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func _check_quest_threshold(quest_type: String, target_id: String, current_value: float) -> void:
	if GameState.selected_hotel.is_empty(): return
	var quest_state = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for cat_id in quest_state:
		var cat_data = quest_state[cat_id]
		var targets_state = cat_data.get("targets", {})
		
		for t_id in targets_state:
			var t_state = targets_state[t_id]
			if t_state["state"] != "active": continue
			
			var t_def = flat_targets[t_id]
			
			var req_tech = t_def.get("requires_tech", "")
			if req_tech != "" and not TechtreeManager.is_tech_unlocked(req_tech):
				continue
			
			if t_def["type"] == quest_type and (t_def.get("target_id", "") == target_id or target_id == ""):
				var target_val = float(t_def.get("target_count", 1))
				
				# Only update progress UI if it increased
				if t_state["progress"] < current_value:
					t_state["progress"] = min(current_value, target_val)
					sig_quest_progress_updated.emit(t_id, t_state["progress"], target_val)
					changed = true

				if current_value >= target_val:
					t_state["state"] = "claimable"
					t_state["progress"] = target_val
					sig_quest_claimable.emit(t_id)
					sig_quest_progress_updated.emit(t_id, t_state["progress"], target_val)
					Toast.show(GameState.T("toast.quest.completed", GameState.T(t_def.get("name", ""))), "quest")
					changed = true
				
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func on_poi_used(poi_id: String) -> void:
	_increment_quest_progress("use_poi", poi_id)

func on_food_cooked(amount: int = 1) -> void:
	_increment_quest_progress("cook_food", "", amount)

func on_order_served(poi_id: String) -> void:
	_increment_quest_progress("serve_order", poi_id)

func on_day_ended(revenue: int, satisfaction: float) -> void:
	_check_quest_threshold("daily_revenue", "", float(revenue))
	_check_quest_threshold("satisfaction", "", satisfaction)

func _on_day_ended_hook(day: int) -> void:
	if GameState.selected_hotel.is_empty(): return
	var rev = 0
	var txs = GameState.selected_hotel.get("transactions", [])
	for tx in txs:
		if tx.get("day") == day and tx.get("amount", 0) > 0:
			rev += tx["amount"]
			
	var total_sat = 0.0
	var guest_count = 0
	var guest_data = GameState.selected_hotel.get("guest_data", {})
	var active_guests = guest_data.get("active", [])
	for party in active_guests:
		total_sat += float(party.get("satisfaction", 100))
		guest_count += 1
		
	var avg_sat = 100.0
	if guest_count > 0:
		avg_sat = total_sat / float(guest_count)
		
	on_day_ended(rev, avg_sat)

func check_occupancy(is_full: bool) -> void:
	if is_full:
		_check_quest_threshold("full_occupancy", "", 1.0)



# =============================================================================
func on_room_demolished(room_id: String, _unique_id: String = "") -> void:
	if GameState.selected_hotel.is_empty(): return
	var quest_state = GameState.selected_hotel.get("quests", {})
	var changed = false
	
	for cat_id in quest_state:
		var cat_data = quest_state[cat_id]
		var targets_state = cat_data.get("targets", {})
		
		for t_id in targets_state:
			var t_state = targets_state[t_id]
			# Wir reduzieren den Fortschritt nur, solange das Ziel noch nicht erreicht wurde
			if t_state["state"] == "active":
				var t_def = flat_targets[t_id]
				if t_def["type"] == "build_room" and t_def["target_id"] == room_id:
					if t_state["progress"] > 0:
						t_state["progress"] -= 1
						var max_val = t_def.get("target_count", 1)
						sig_quest_progress_updated.emit(t_id, t_state["progress"], max_val)
						changed = true
						
	if changed:
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func claim_quest(t_id: String) -> void:
	if GameState.selected_hotel.is_empty(): return
	var t_def = flat_targets.get(t_id)
	if t_def == null: return
	
	var cat_id = t_def["category"]
	var cat_state = GameState.selected_hotel["quests"].get(cat_id)
	if cat_state == null: return
	
	var t_state = cat_state["targets"].get(t_id)
	if t_state != null and t_state["state"] == "claimable":
		# Belohnung ausschütten
		GameState.add_fp(t_def.get("reward_fp", 0))
		FinanceManager.add_transaction(t_def.get("reward_money", 0), "quest", GameState.T("toast.quest.reward", GameState.T(t_def.get("name", ""))))
		
		t_state["state"] = "claimed"
		sig_quest_claimed.emit(t_id)
		
		_check_rank_completion(cat_id)
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func _check_rank_completion(cat_id: String) -> void:
	var cat_state = GameState.selected_hotel["quests"][cat_id]
	if cat_state.get("rank_claimable", false): return
	
	var all_claimed = true
	var target_count = 0
	for t_id in cat_state["targets"]:
		target_count += 1
		if cat_state["targets"][t_id]["state"] != "claimed":
			all_claimed = false
			break
			
	if target_count > 0 and all_claimed:
		cat_state["rank_claimable"] = true
		sig_rank_claimable.emit(cat_id)
		Toast.show(GameState.T("toast.quest.rank_complete", cat_state["current_rank"]), "quest")

# =============================================================================
func claim_rank(cat_id: String) -> void:
	if GameState.selected_hotel.is_empty(): return
	var cat_state = GameState.selected_hotel["quests"].get(cat_id)
	if cat_state == null: return
	
	if cat_state.get("rank_claimable", false):
		var r_id = str(cat_state["current_rank"])
		var r_def = quests_db["categories"][cat_id]["ranks"][r_id]
		
		GameState.add_fp(r_def.get("reward_fp", 0))
		FinanceManager.add_transaction(r_def.get("reward_money", 0), "quest", GameState.T("toast.quest.rank_reward", r_id))
		
		cat_state["rank_claimable"] = false
		cat_state["current_rank"] += 1
		
		_activate_rank(cat_id, str(cat_state["current_rank"]))
		
		sig_rank_claimed.emit(cat_id)
		SaveManager.save_quick(GameState.active_hotel_id)

# =============================================================================
func get_quest_state() -> Dictionary:
	if GameState.selected_hotel.is_empty(): return {}
	return GameState.selected_hotel.get("quests", {})

func has_category_claimable(cat_id: String) -> bool:
	if GameState.selected_hotel.is_empty(): return false
	var quest_state = GameState.selected_hotel.get("quests", {})
	var cat_data = quest_state.get(cat_id)
	if cat_data == null: return false
	
	if cat_data.get("rank_claimable", false): return true
	var targets = cat_data.get("targets", {})
	for t_id in targets:
		if targets[t_id].get("state") == "claimable": return true
	return false

func has_any_claimable() -> bool:
	if GameState.selected_hotel.is_empty(): return false
	var quest_state = GameState.selected_hotel.get("quests", {})
	for cat_id in quest_state:
		if has_category_claimable(cat_id): return true
	return false
