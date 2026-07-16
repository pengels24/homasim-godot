extends Node

signal sig_staff_hired(staff_data: Dictionary)
signal sig_staff_fired(staff_id: String)
signal sig_applicants_generated()
signal sig_assignments_changed()

const STAFF_CONFIG_PATH = "res://config/staff.json"

var staff_config: Dictionary = {}
var hired_staff: Dictionary = {}
var daily_applicants: Array = []
var room_assignments: Dictionary = {}  # staff_id → room_id

var _last_generated_day: int = -1
var _auto_assign_timer: float = 0.0

# =============================================================================
func _process(delta: float) -> void:
	if GameState.active_hotel_id <= 0:
		return
		
	_auto_assign_timer -= delta
	if _auto_assign_timer <= 0.0:
		_auto_assign_timer = 2.0
		_process_auto_assign()

# =============================================================================
func _ready() -> void:
	_load_config()
	if TimeManager:
		TimeManager.sig_midnight_struck.connect(_on_midnight_struck)
		TimeManager.sig_morning_struck.connect(_on_morning_struck)

# =============================================================================
func _load_config() -> void:
	if not FileAccess.file_exists(STAFF_CONFIG_PATH):
		push_error("[StaffManager] Konnte staff.json nicht finden: " + STAFF_CONFIG_PATH)
		return

	var file = FileAccess.open(STAFF_CONFIG_PATH, FileAccess.READ)
	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(content)
	if error == OK:
		staff_config = json.data

	else:
		push_error("[StaffManager] JSON Parse Error in staff.json")

# =============================================================================
func load_state(saved_state: Dictionary) -> void:
	hired_staff = saved_state.get("hired", saved_state).duplicate()
	room_assignments = saved_state.get("assignments", {}).duplicate()

	_ensure_daily_applicants()

# =============================================================================
func get_state() -> Dictionary:
	return {
		"hired": hired_staff,
		"assignments": room_assignments
	}

# =============================================================================
func _ensure_daily_applicants() -> void:
	var current_day = GameState.selected_hotel.get("day", 1)
	if current_day != _last_generated_day:
		_generate_daily_applicants()
		_last_generated_day = current_day

# =============================================================================
func _generate_daily_applicants() -> void:
	daily_applicants.clear()
	if not staff_config.has("roles"):
		return
		
	var active_roles: Array = ["housekeeping", "maintenance"]
	
	var built_rooms = []
	if SaveManager.has_method("get_built_plots"):
		built_rooms = SaveManager.get_built_plots()
		
	# Prüfen welche Räume gebaut wurden und deren benötigte Rollen sammeln
	for room_data in built_rooms:
		var room_id = room_data.get("room_id", "")
		if GameState.room_registry.has(room_id):
			var def = GameState.room_registry[room_id].get("def", {})
			var req_role = def.get("required_role", "")
			if req_role != "" and not active_roles.has(req_role):
				active_roles.append(req_role)

	var roles = staff_config["roles"]
	for role_key in roles.keys():
		if not active_roles.has(role_key):
			continue
			
		# Generiere 3 Bewerber pro aktiver Rolle
		for i in 3:
			daily_applicants.append(_generate_single_applicant(role_key))
			
	sig_applicants_generated.emit()


# =============================================================================
func _generate_single_applicant(role_key: String) -> Dictionary:
	var gender = "female" if randf() > 0.5 else "male"
	
	var names_dict = staff_config.get("names", {})
	var first_names = names_dict.get("first_names_" + gender, ["Alex"])
	if first_names.is_empty():
		first_names = ["Alex"]
	var last_names = names_dict.get("last_names", ["Müller"])
	
	var first = first_names[randi() % first_names.size()]
	var last = last_names[randi() % last_names.size()]
	
	var role_data = staff_config["roles"][role_key]
	var base_skills = role_data.get("base_skills", {})
	
	var applicant = {
		"id": str(Time.get_ticks_msec()) + "_" + str(randi()),
		"first_name": first,
		"last_name": last,
		"age": randi_range(18, 65),
		"gender": gender,
		"role": role_key,
		"hire_cost": role_data.get("hire_cost", 200) + randi_range(-20, 20),
		"daily_wage": role_data.get("daily_wage", 80) + randi_range(-10, 10),
		"skills": base_skills.duplicate(),
		"morale": randi_range(80, 100)
	}
	
	for skill_name in base_skills.keys():
		var range_arr = base_skills[skill_name]
		if range_arr.size() == 2:
			var min_val = int(range_arr[0])
			var max_val = int(range_arr[1])
			applicant["skills"][skill_name] = randi_range(min_val, max_val)
		else:
			applicant["skills"][skill_name] = 5
			
	return applicant

# =============================================================================
## Weist einen Mitarbeiter einem Raum zu. Hebt eine evtl. vorhandene Zuweisung des Mitarbeiters auf.
func assign_to_room(staff_id: String, room_id: String) -> void:
	if not hired_staff.has(staff_id):
		return
	# Alte Zuweisung des Mitarbeiters aufheben
	if room_assignments.has(staff_id):
		room_assignments.erase(staff_id)
	room_assignments[staff_id] = room_id
	_save_to_hotel()
	sig_assignments_changed.emit()

# =============================================================================
## Hebt die Raum-Zuweisung eines Mitarbeiters auf.
func unassign_from_room(staff_id: String) -> void:
	if room_assignments.has(staff_id):
		room_assignments.erase(staff_id)
		_save_to_hotel()
		sig_assignments_changed.emit()

# =============================================================================
## Gibt alle Mitarbeiter zurück, die einem bestimmten Raum zugewiesen sind.
func get_staff_for_room(room_id: String) -> Array:
	var result: Array = []
	for sid in room_assignments:
		if room_assignments[sid] == room_id:
			if hired_staff.has(sid):
				result.append(hired_staff[sid])
	return result

# =============================================================================
func _process_auto_assign() -> void:
	if hired_staff.is_empty():
		return
		
	# 1. Alle gebauten Räume sammeln, die Personal benötigen
	var active_hotel = GameState.active_hotel_id
	if active_hotel <= 0: return
	
	var all_rooms = []
	for p in SaveManager.get_built_plots(active_hotel):
		for r in p.get("rooms", []):
			var r_type = r.get("room_type_id", "")
			var reg = GameState.room_registry.get(r_type, {})
			var def = reg.get("def", {})
			if def.get("is_poi", false) and def.get("required_role", "") != "":
				all_rooms.append({"id": r["id"], "def": def})
				
	# 2. Unassigned Staff durchgehen
	var unassigned_staff_ids = []
	for staff_id in hired_staff:
		if not room_assignments.has(staff_id):
			unassigned_staff_ids.append(staff_id)
			
	for staff_id in unassigned_staff_ids:
		var staff = hired_staff[staff_id]
		var role = staff.get("role", "")
		var assigned = false
		
		# Prio 1: Räume, die ihren min_staff noch nicht haben
		for r in all_rooms:
			if r["def"].get("required_role", "") == role:
				var c = get_staff_for_room(r["id"]).size()
				var min_s = r["def"].get("min_staff", 1)
				if c < min_s:
					assign_to_room(staff_id, r["id"])
					assigned = true
					break
					
		if assigned: continue
		
		# Prio 2: Räume, die max_staff noch nicht erreicht haben
		for r in all_rooms:
			if r["def"].get("required_role", "") == role:
				var c = get_staff_for_room(r["id"]).size()
				var max_s = r["def"].get("max_staff", 1)
				if c < max_s:
					assign_to_room(staff_id, r["id"])
					break

# =============================================================================
## Prüft, ob ein POI genügend Personal hat, um als geöffnet zu gelten.
## POIs ohne required_role (z.B. Lobby) gelten immer als besetzt.
func is_poi_staffed(room_def: Dictionary, room_id: String) -> bool:
	if room_def.get("required_role", "") == "":
		return true
	var min_s: int = room_def.get("min_staff", 1)
	return get_staff_for_room(room_id).size() >= min_s

# =============================================================================
func hire_staff(applicant_id: String) -> bool:
	if hired_staff.size() >= 5:
		Toast.show(GameState.T("toast.staff.limit_reached"), "personal")
		return false
		
	var applicant_idx = -1
	for i in daily_applicants.size():
		if daily_applicants[i]["id"] == applicant_id:
			applicant_idx = i
			break
			
	if applicant_idx == -1:
		return false
		
	var applicant = daily_applicants[applicant_idx]
	var cost = applicant.get("hire_cost", 200)
	
	if GameState.selected_hotel.get("money", 0) < cost:
		Toast.show(GameState.T("toast.staff.not_enough_capital"), "personal")
		return false
		
	if FinanceManager:
		FinanceManager.add_transaction(-cost, "Personal", "tx.hire|" + applicant["first_name"] + "|" + GameState.T("staff.role." + applicant["role"]))
	else:
		GameState.add_money(-cost)
	
	daily_applicants.remove_at(applicant_idx)
	hired_staff[applicant["id"]] = applicant
	
	# Speichern
	_save_to_hotel()
	
	sig_staff_hired.emit(applicant)
	Toast.show(applicant["first_name"] + " wurde eingestellt!", "personal")
	return true

# =============================================================================
func fire_staff(staff_id: String) -> void:
	if not hired_staff.has(staff_id):
		return
		
	var staff_name = hired_staff[staff_id]["first_name"]
	hired_staff.erase(staff_id)
	
	# Speichern
	_save_to_hotel()
	
	sig_staff_fired.emit(staff_id)
	Toast.show(staff_name + " wurde entlassen.")

# =============================================================================
func _process_wages() -> void:
	var total_wages = 0.0
	for staff in hired_staff.values():
		total_wages += staff.get("daily_wage", 0.0)
		
	if total_wages > 0:
		if FinanceManager:
			FinanceManager.add_transaction(-int(total_wages), "Personal", "tx.daily_wages")
		else:
			GameState.add_money(-int(total_wages))


# =============================================================================
func _process_morale() -> void:
	var to_fire = []
	for staff_id in hired_staff:
		var staff = hired_staff[staff_id]
		var current_morale = staff.get("morale", 100)
		
		# Täglicher Basis-Verfall der Moral (-2)
		current_morale = max(0, current_morale - 2)
		staff["morale"] = current_morale
		
		if current_morale <= 0:
			to_fire.append(staff_id)
		elif current_morale < 20:
			Toast.show(staff["first_name"] + " droht zu kündigen! (Moral kritisch)", "personal")
			
	for staff_id in to_fire:
		Toast.show(hired_staff[staff_id]["first_name"] + " hat gekündigt! (Moral = 0)", "personal")
		fire_staff(staff_id)

# =============================================================================
func _on_midnight_struck(_day: int) -> void:
	_process_wages()
	_process_morale()

# =============================================================================
func _on_morning_struck() -> void:
	_ensure_daily_applicants()

# =============================================================================
func _save_to_hotel() -> void:
	if GameState.selected_hotel != null and not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["staff"] = get_state()
		SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
