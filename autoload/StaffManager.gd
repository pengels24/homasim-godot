extends Node

signal sig_staff_hired(staff_data: Dictionary)
signal sig_staff_fired(staff_id: String)
signal sig_applicants_generated()

const STAFF_CONFIG_PATH = "res://config/staff.json"

var staff_config: Dictionary = {}
var hired_staff: Dictionary = {}
var daily_applicants: Array = []

var _last_generated_day: int = -1

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
		print("[StaffManager] Staff Config geladen.")
	else:
		push_error("[StaffManager] JSON Parse Error in staff.json")

# =============================================================================
func load_state(saved_state: Dictionary) -> void:
	hired_staff = saved_state.duplicate()
	print("[StaffManager] Gespeichertes Personal geladen: ", hired_staff.size())
	_ensure_daily_applicants()

# =============================================================================
func get_state() -> Dictionary:
	return hired_staff

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
		
	var roles = staff_config["roles"]
	for role_key in roles.keys():
		# Generiere 3 Bewerber pro Rolle
		for i in 3:
			daily_applicants.append(_generate_single_applicant(role_key))
			
	sig_applicants_generated.emit()
	print("[StaffManager] Bewerber für den Tag generiert.")

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
func hire_staff(applicant_id: String) -> bool:
	if hired_staff.size() >= 5:
		Toast.show("Personal-Limit (5) erreicht!")
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
		Toast.show("Nicht genug Kapital!")
		return false
		
	if FinanceManager:
		FinanceManager.add_transaction(-cost, "Personal", "Einstellungsgebühr: " + applicant["first_name"] + " (" + GameState.T("staff.role." + applicant["role"]) + ")")
	else:
		GameState.add_money(-cost)
	
	daily_applicants.remove_at(applicant_idx)
	hired_staff[applicant["id"]] = applicant
	
	# Speichern
	_save_to_hotel()
	
	sig_staff_hired.emit(applicant)
	Toast.show(applicant["first_name"] + " wurde eingestellt!")
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
			FinanceManager.add_transaction(-int(total_wages), "Personal", "Tagesgehälter")
		else:
			GameState.add_money(-int(total_wages))
		print("[StaffManager] Gehälter in Höhe von ", total_wages, " € gezahlt.")

# =============================================================================
func _on_midnight_struck(_day: int) -> void:
	_process_wages()

# =============================================================================
func _on_morning_struck() -> void:
	_ensure_daily_applicants()

# =============================================================================
func _save_to_hotel() -> void:
	if GameState.selected_hotel != null and not GameState.selected_hotel.is_empty():
		GameState.selected_hotel["staff"] = get_state()
		SaveManager.update_hotel(GameState.active_hotel_id, GameState.selected_hotel)
