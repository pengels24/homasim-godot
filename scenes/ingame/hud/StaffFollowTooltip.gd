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
		var fn = data.get("first_name", GameState.T("guest.tooltip.unknown"))
		var ln = data.get("last_name", "")
		label_name.text = fn + (" " + ln if ln != "" else "")
		
		var role = data.get("role", "housekeeping")
		if role == "housekeeping":
			label_role.text = GameState.T("staff.tooltip.role.housekeeping")
		elif role == "maintenance":
			label_role.text = GameState.T("staff.tooltip.role.maintenance")
		elif role == "reception":
			label_role.text = GameState.T("staff.tooltip.role.reception")
		else:
			label_role.text = GameState.T("staff.tooltip.role.prefix") + role.capitalize()
			
		var skills = data.get("skills", {})
		var motivation = skills.get("motivation", 5)
		label_stats.text = GameState.T("staff.tooltip.motivation") % motivation
	else:
		label_name.text = GameState.T("guest.tooltip.unknown")
		label_role.text = GameState.T("staff.tooltip.role.prefix") + GameState.T("guest.tooltip.unknown")
		label_stats.text = GameState.T("staff.tooltip.motivation_unknown")
		
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
	var s_text = GameState.T("staff.tooltip.status")
	var t_text = GameState.T("staff.tooltip.target")
	
	match state:
		"idle":
			s_text += GameState.T("staff.tooltip.state.idle")
			t_text += GameState.T("staff.tooltip.target.staffroom")
		"returning":
			s_text += GameState.T("staff.tooltip.state.returning")
			t_text += GameState.T("staff.tooltip.target.staffroom")
		"walking":
			s_text += GameState.T("staff.tooltip.state.walking")
			t_text += _format_task_target()
		"working":
			s_text += GameState.T("staff.tooltip.state.working")
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
			return GameState.T("staff.tooltip.target.position") % str(t)
		else:
			return GameState.T("staff.tooltip.target.room_work")
	return GameState.T("staff.tooltip.target.work")
