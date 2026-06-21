extends PanelContainer

var _target_staff: StaffActor
var _timer: float = 5.0

@onready var label_name: Label = %NameLabel
@onready var label_role: Label = %RoleLabel
@onready var label_stats: Label = %StatsLabel
@onready var label_target: Label = %TargetLabel
@onready var label_state: Label = %StateLabel

func setup(staff: StaffActor) -> void:
	_target_staff = staff
	if not is_instance_valid(staff):
		queue_free()
		return
		
	var data = staff.get("_staff_data")
	if data:
		var fn = data.get("first_name", "Unbekannt")
		var ln = data.get("last_name", "")
		label_name.text = fn + (" " + ln if ln != "" else "")
		
		var role = data.get("role", "housekeeping")
		if role == "housekeeping":
			label_role.text = "Beruf: Reinigungskraft"
		elif role == "maintenance":
			label_role.text = "Beruf: Haustechnik"
		elif role == "reception":
			label_role.text = "Beruf: Rezeption"
		else:
			label_role.text = "Beruf: " + role.capitalize()
			
		var skills = data.get("skills", {})
		var motivation = skills.get("motivation", 5)
		label_stats.text = "Motivation: %d / 10" % motivation
	else:
		label_name.text = "Unbekannt"
		label_role.text = "Beruf: Unbekannt"
		label_stats.text = "Motivation: Unbekannt"
		
	_update_target_text()
	_update_pos()

func _process(delta: float) -> void:
	if not is_instance_valid(_target_staff):
		queue_free()
		return
		
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
		return
		
	_update_target_text()
	_update_pos()

func _update_pos() -> void:
	if not is_instance_valid(_target_staff):
		return
	var cam = get_viewport().get_camera_2d()
	if cam:
		var screen_pos = _target_staff.get_global_transform_with_canvas().origin
		position = screen_pos + Vector2(20, -size.y - 10)

func _update_target_text() -> void:
	if not is_instance_valid(_target_staff):
		return
	
	var state = _target_staff.get("_state")
	var s_text = "Status: "
	var t_text = "Ziel: "
	
	match state:
		"idle":
			s_text += "Bereit (Wartet)"
			t_text += "Personalraum"
		"returning":
			s_text += "Rückkehr"
			t_text += "Personalraum"
		"walking":
			s_text += "Unterwegs"
			t_text += _format_task_target()
		"working":
			s_text += "Arbeitet"
			t_text += _format_task_target()
		_:
			s_text += str(state)
			t_text += "???"
			
	label_state.text = s_text
	label_target.text = t_text

func _format_task_target() -> String:
	var task = _target_staff.get("_current_task")
	if task and task.has("target"):
		var t = task["target"]
		if is_instance_valid(t) and t.has_method("get_definition"):
			var r_name = t.get_definition().get("name", "Raum")
			var r_id = t.get("id") if "id" in t else ""
			return "%s (%s)" % [r_name, r_id] if r_id != "" else r_name
		elif typeof(t) == TYPE_VECTOR2 or typeof(t) == TYPE_VECTOR2I:
			return "Position " + str(t)
		else:
			return "Raum/Arbeit"
	return "Arbeit"
