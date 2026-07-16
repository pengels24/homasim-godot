extends PanelContainer

signal sig_unassign_staff(staff_id: String)
signal sig_clicked(room_id: String)

const ROW_STAFF = preload("res://scenes/ingame/hud/modals/content/cards/RowAssignedStaff.tscn")

@onready var lbl_room_name: Label = %LblRoomName
@onready var lbl_status: Label = %LblStatus
@onready var grid_staff: GridContainer = %GridStaff
@onready var _selection_border: Panel = %SelectionBorder

var _room_id: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _selection_border:
		_selection_border.hide()
		
	mouse_entered.connect(func(): self_modulate = Color(1.5, 1.5, 1.5, 1.0))
	mouse_exited.connect(func(): self_modulate = Color(1.0, 1.0, 1.0, 1.0))

func set_selected(sel: bool) -> void:
	if _selection_border:
		_selection_border.visible = sel

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		Toast.show("Room Clicked: " + _room_id)
		sig_clicked.emit(_room_id)

func populate(formatted_name: String, room_id: String, _min_staff: int, max_staff: int, assigned_staff: Array, def: Dictionary = {}) -> void:
	_room_id = room_id
	lbl_room_name.text = formatted_name
	
	var current = assigned_staff.size()
	if current == 0:
		lbl_status.text = GameState.T("ui.staff.assign.status.empty", current, max_staff)
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # Rot
	elif current < max_staff:
		lbl_status.text = GameState.T("ui.staff.assign.status.partial", current, max_staff)
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Gelb
	else:
		lbl_status.text = GameState.T("ui.staff.assign.status.full", current)
		lbl_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) # Grün
		
	for child in grid_staff.get_children():
		child.queue_free()
		
	# Grid auf max 2 Spalten begrenzen, damit lange Namen nicht abgeschnitten werden
	grid_staff.columns = min(max_staff, 2)
		
	for staff_data in assigned_staff:
		if staff_data:
			var row = ROW_STAFF.instantiate()
			grid_staff.add_child(row)
			row.populate(staff_data)
			row.sig_remove_clicked.connect(func(sid): sig_unassign_staff.emit(sid))
			
	var empty_slots = max_staff - current
	
	# Erlaubte Rollen für den Text herausfinden
	var req_r = def.get("required_role", "")
	var allowed = def.get("allowed_roles", [req_r] if req_r != "" else [])
	var role_names = []
	for r in allowed:
		if r == "": continue
		var r_name = StaffManager.staff_config.get("roles", {}).get(r, {}).get("name", r)
		role_names.append(r_name)
	
	var placeholder_text = GameState.T("ui.staff.assign.free_slot", "- Freier Arbeitsplatz -")
	if role_names.size() > 0:
		placeholder_text = "- Frei (%s) -" % "/".join(role_names)
	
	for i in range(empty_slots):
		var p = PanelContainer.new()
		p.theme_type_variation = "InnerPanel"
		p.custom_minimum_size = Vector2(0, 42)
		p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var m = MarginContainer.new()
		m.add_theme_constant_override("margin_left", 12)
		m.add_theme_constant_override("margin_right", 12)
		p.add_child(m)
		
		var l = Label.new()
		l.text = placeholder_text
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.2))
		l.clip_text = true
		m.add_child(l)
		
		grid_staff.add_child(p)
