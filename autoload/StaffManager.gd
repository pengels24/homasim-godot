extends Node

signal sig_staff_hired(staff_data: Dictionary)
signal sig_staff_fired(staff_id: String)
signal sig_staff_training_started(staff_id: String)
signal sig_staff_training_ended(staff_data: Dictionary)
signal sig_applicants_generated()
signal sig_assignments_changed()

const STAFF_CONFIG_PATH = "res://config/staff.json"

var staff_config: Dictionary = {}
var hired_staff: Dictionary = {}
var daily_applicants: Array = []
var room_assignments: Dictionary = {}  # staff_id → room_id

var _last_generated_day: int = -1

const MAX_DAILY_REFRESHES: int = 2

# =============================================================================
func _process(_delta: float) -> void:
	if GameState.active_hotel_id <= 0:
		return

# =============================================================================
func _ready() -> void:
	_load_config()
	if GameState and not GameState.sig_room_demolished.is_connected(_on_room_demolished):
		GameState.sig_room_demolished.connect(_on_room_demolished)
	if TimeManager:
		TimeManager.sig_midnight_struck.connect(_on_midnight_struck)
		TimeManager.sig_morning_struck.connect(_on_morning_struck)
	# Bewerber regenerieren wenn ein neuer Raum gebaut wird (z.B. Küche -> Koch-Bewerber erscheinen sofort)
	if not GameState.sig_room_built.is_connected(_on_room_built):
		GameState.sig_room_built.connect(_on_room_built)

func _on_room_demolished(_type_id: String, room_id: String) -> void:
	# Wenn ein Raum abgerissen wird, werfen wir das zugewiesene Personal raus (auf unassigned)
	var changed = false
	for staff_id in room_assignments.keys():
		if room_assignments[staff_id] == room_id:
			room_assignments.erase(staff_id)
			changed = true
	
	if changed:
		_save_to_hotel()
		sig_assignments_changed.emit()

# =============================================================================
## Wird ausgelöst wenn ein neuer Raum gebaut wurde – regeneriert Bewerber
## falls der neue Raum eine Rolle erfordert, die noch keine Bewerber hat.
func _on_room_built(room_type_id: String) -> void:
	var reg = GameState.room_registry.get(room_type_id, {})
	var def = reg.get("def", {})
	var required_role = def.get("required_role", "")
	var allowed_roles = def.get("allowed_roles", [required_role])
	if allowed_roles.is_empty() and required_role == "": return
	
	# Prüfen ob diese Rollen schon Bewerber haben
	var missing_applicant = false
	for r in allowed_roles:
		if r == "": continue
		var has_applicant_for_role = daily_applicants.any(func(a): return a.get("role", "") == r)
		if not has_applicant_for_role:
			missing_applicant = true
			break
			
	if missing_applicant:
		_generate_daily_applicants()
		sig_applicants_generated.emit()

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
	sig_assignments_changed.emit()

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
	
	var built_plots = []
	if SaveManager.has_method("get_built_plots"):
		built_plots = SaveManager.get_built_plots(GameState.active_hotel_id)
		
	# Prüfen welche Räume gebaut wurden und deren benötigte Rollen sammeln
	for plot in built_plots:
		var rooms: Array = plot.get("rooms", [])
		for room_data in rooms:
			var room_type_id = room_data.get("room_type_id", "")
			if GameState.room_registry.has(room_type_id):
				var def = GameState.room_registry[room_type_id].get("def", {})
				var req_role = def.get("required_role", "")
				var allowed = def.get("allowed_roles", [req_role] if req_role != "" else [])
				for r in allowed:
					if r != "" and not active_roles.has(r):
						active_roles.append(r)

	var roles = staff_config["roles"]
	for role_key in roles.keys():
		if not active_roles.has(role_key):
			continue
			
		# Generiere 3 Bewerber pro aktiver Rolle
		for i in 3:
			daily_applicants.append(_generate_single_applicant(role_key))
			
	sig_applicants_generated.emit()

# =============================================================================
func get_daily_refreshes() -> int:
	return GameState.selected_hotel.get("staff_refreshes", 0)

# =============================================================================
func refresh_applicants() -> bool:
	var refreshes = get_daily_refreshes()
	if refreshes >= MAX_DAILY_REFRESHES:
		return false
	
	GameState.selected_hotel["staff_refreshes"] = refreshes + 1
	_generate_daily_applicants()
	return true



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
func train_staff(staff_id: String, cost: int) -> bool:
	if not hired_staff.has(staff_id): return false
	
	var current_money = GameState.selected_hotel.get("money", 0)
	if current_money < cost: return false
	
	var s = hired_staff[staff_id]
	var role = s.get("role", "")
	var skills = s.get("skills", {})
	var current_val = skills.get(role, 0)
	
	if current_val >= 10: return false
	
	GameState.add_money(-cost)
	if FinanceManager:
		FinanceManager.add_transaction(-cost, "staff", "tx.staff.training")
		
	s["training_state"] = "scheduled"
	
	_save_to_hotel()
	sig_assignments_changed.emit()
	return true

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
## Prüft, ob ein POI genügend Personal hat, um als geöffnet zu gelten.
## POIs ohne required_role (z.B. Lobby) gelten immer als besetzt.
func is_poi_staffed(room_def: Dictionary, room_id: String) -> bool:
	var req_role = room_def.get("required_role", "")
	if req_role == "":
		return true
	var min_s: int = room_def.get("min_staff", 1)
	return _count_role_in_room(room_id, req_role) >= min_s

# =============================================================================
## Prüft, ob ein Mitarbeiter aktuell arbeitsfähig ist (nicht in Schulung, nicht krank, etc.)
func is_staff_available(staff: Dictionary) -> bool:
	if not staff: return false
	if staff.get("training_state", "none") == "in_training": return false
	# Hier können später is_sick, on_vacation etc. eingefügt werden
	return true

# =============================================================================
func _count_role_in_room(room_id: String, role: String) -> int:
	var c = 0
	for s in get_staff_for_room(room_id):
		if s.get("role", "") == role and is_staff_available(s):
			c += 1
	return c

# =============================================================================
func get_max_staff_capacity() -> int:
	var total_capacity = 0
	if SaveManager.has_method("get_built_plots"):
		var plots = SaveManager.get_built_plots(GameState.active_hotel_id)
		for plot in plots:
			var rooms: Array = plot.get("rooms", [])
			for r in rooms:
				var type_id = r.get("room_type_id", "")
				if GameState.room_registry.has(type_id):
					var def = GameState.room_registry[type_id].get("def", {})
					if def.get("is_staff_poi", false):
						total_capacity += def.get("capacity", 0)
	return total_capacity

# =============================================================================
func hire_staff(applicant_id: String) -> bool:
	if hired_staff.size() >= get_max_staff_capacity():
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
	if TimeManager:
		applicant["hired_day"] = TimeManager.get_day()
	else:
		applicant["hired_day"] = 1
	hired_staff[applicant["id"]] = applicant
	
	# Speichern
	_save_to_hotel()
	
	sig_staff_hired.emit(applicant)
	Toast.show(applicant["first_name"] + " wurde eingestellt!", "personal", false)
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
	# 1. Staff Morale Changes and Training
	var to_fire = []
	for sid in hired_staff:
		var s = hired_staff[sid]
		
		# Training Check
		var t_state = s.get("training_state", "none")
		if t_state == "in_training":
			s["training_state"] = "none"
			var role = s.get("role", "")
			var skills = s.get("skills", {})
			skills[role] = min(skills.get(role, 0) + 2, 10)
			s["skills"] = skills
			sig_staff_training_ended.emit(s)
		elif t_state == "scheduled":
			s["training_state"] = "in_training"
			sig_staff_training_started.emit(sid)
		
		# Morale check
		var current_morale = s.get("morale", 100)
		
		# Täglicher Basis-Verfall der Moral (-2)
		current_morale = max(0, current_morale - 2)
		s["morale"] = current_morale
		
		if current_morale <= 0:
			to_fire.append(sid)
		elif current_morale < 20:
			Toast.show(s["first_name"] + " droht zu kündigen! (Moral kritisch)", "personal")
			
	for staff_id in to_fire:
		Toast.show(hired_staff[staff_id]["first_name"] + " hat gekündigt! (Moral = 0)", "personal")
		fire_staff(staff_id)

# =============================================================================
func add_morale(staff_id: String, amount: int, cap: int = 100) -> void:
	if not hired_staff.has(staff_id): return
	var staff = hired_staff[staff_id]
	var current = staff.get("morale", 100)
	if current < cap:
		staff["morale"] = min(cap, current + amount)
		_save_to_hotel()

# =============================================================================
func pay_bonus(staff_id: String) -> bool:
	if not hired_staff.has(staff_id): return false
	var bonus_cost = 100
	if GameState.selected_hotel.get("money", 0) < bonus_cost:
		Toast.show(GameState.T("toast.staff.not_enough_capital"), "personal")
		return false
		
	if FinanceManager:
		FinanceManager.add_transaction(-bonus_cost, "Personal", "tx.bonus|" + hired_staff[staff_id]["first_name"])
	else:
		GameState.add_money(-bonus_cost)
		
	add_morale(staff_id, 25, 100)
	var staff_name = hired_staff[staff_id]["first_name"]
	Toast.show(GameState.T("toast.staff.bonus_received", "%s hat einen Bonus erhalten!") % staff_name, "personal", false)
	return true

# =============================================================================
func _on_midnight_struck(_day: int) -> void:
	_process_wages()
	_process_morale()

# =============================================================================
func _on_morning_struck() -> void:
	# Jeden Morgen den Counter zurücksetzen
	if not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["staff_refreshes"] = 0
		
	_ensure_daily_applicants()

# =============================================================================
func _save_to_hotel() -> void:
	if GameState.selected_hotel != null and not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["staff"] = get_state()
		SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)

# =============================================================================
func get_break_thresholds(_staff_id: String) -> Dictionary:
	var diff_multiplier = GameState.selected_hotel.get("exp_multiplier", 1.0) if GameState.selected_hotel else 1.0
	
	# Basis-Werte (Hard / Knechtschaft)
	var b_start = 40
	var b_bed = 20
	var b_accept = 50
	
	if diff_multiplier > 1.2:
		# Casual
		b_start = 60
		b_bed = 40
		b_accept = 70
	elif diff_multiplier >= 1.0:
		# Normal
		b_start = 50
		b_bed = 30
		b_accept = 60
		
	# Techtree-Boni (Management)
	var traits = TechtreeManager.unlocked_techs if TechtreeManager else []
	if "ui.techtree.feature.m1_2_train" in traits:
		b_start += 10
		b_bed += 10
		b_accept += 10
		
	return {
		"break_start_threshold": b_start,
		"bed_preference_threshold": b_bed,
		"task_accept_threshold": b_accept
	}

func can_demolish_staff_room(capacity_to_remove: int = 4) -> bool:
	var current_staff_count = hired_staff.size()
	var new_max_capacity = max(0, get_max_staff_capacity() - capacity_to_remove)
	return current_staff_count <= new_max_capacity
