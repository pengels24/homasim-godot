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

func _process(_delta: float) -> void:
	if not visible or not is_inside_tree(): return
	var is_hovered = get_global_rect().has_point(get_global_mouse_position())
	if is_hovered:
		self_modulate = Color(1.5, 1.5, 1.5, 1.0)
	else:
		self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func set_selected(sel: bool) -> void:
	if _selection_border:
		_selection_border.visible = sel

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		sig_clicked.emit(_room_id)

signal sig_empty_slot_clicked(room_id: String, allowed_roles: Array)

func populate(formatted_name: String, room_id: String, _min_staff: int, max_staff: int, assigned_staff: Array, def: Dictionary = {}) -> void:
	_room_id = room_id
	lbl_room_name.text = formatted_name
	
	var current = assigned_staff.size()
	lbl_status.text = "%d/%d" % [current, max_staff]
	if current == 0:
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # Rot
	elif current < max_staff:
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Gelb
	else:
		lbl_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) # Grün
		
	for child in grid_staff.get_children():
		child.queue_free()
		
	# Grid auf exakt 3 Spalten erzwingen für eine saubere Tabelle
	grid_staff.columns = 3
		
	for staff_data in assigned_staff:
		if staff_data:
			var row = ROW_STAFF.instantiate()
			grid_staff.add_child(row)
			row.populate(staff_data)
			row.sig_remove_clicked.connect(func(sid): sig_unassign_staff.emit(sid))
			
	var empty_slots = max_staff - current
	
	# Erlaubte Rollen für den Text herausfinden, die ihr Limit noch nicht erreicht haben
	var req_r = def.get("required_role", "")
	var allowed = def.get("allowed_roles", [req_r] if req_r != "" else [])
	var limits = def.get("max_role_limits", {})
	var role_names = []
	
	var count_by_role = {}
	for staff in assigned_staff:
		var r = staff.get("role", "")
		count_by_role[r] = count_by_role.get(r, 0) + 1
		
	for r in allowed:
		if r == "": continue
		if limits.has(r) and count_by_role.get(r, 0) >= limits[r]:
			continue
		var r_name = StaffManager.staff_config.get("roles", {}).get(r, {}).get("name", r)
		role_names.append(GameState.T(r_name))
	
	var placeholder_text = GameState.T("ui.staff.assign.free_slot", "Freier Arbeitsplatz")
	if role_names.size() > 0:
		placeholder_text = GameState.T("ui.staff.assign.free", "Frei") + " (" + "/".join(role_names) + ")"
	
	for i in range(empty_slots):
		var p = _create_slot_panel(placeholder_text, Color(1, 1, 1, 0.2), false, allowed)
		grid_staff.add_child(p)
		
	# Auffüllen auf 3 Spalten mit "Nicht verfügbar", um Flattern zu vermeiden
	var disabled_slots = 3 - max_staff
	if disabled_slots > 0:
		for i in range(disabled_slots):
			var p = _create_slot_panel(GameState.T("ui.staff.assign.not_available", "(Nicht verfügbar)"), Color(1, 1, 1, 0.05), true, [])
			grid_staff.add_child(p)

func _create_slot_panel(lbl_text: String, txt_color: Color, disabled: bool, allowed: Array) -> PanelContainer:
	var p = PanelContainer.new()
	p.theme_type_variation = "InnerPanel"
	p.custom_minimum_size = Vector2(0, 42)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 12)
	m.add_theme_constant_override("margin_right", 8)
	p.add_child(m)
	
	var hbox = HBoxContainer.new()
	m.add_child(hbox)
	
	var l = Label.new()
	l.text = lbl_text
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_color", txt_color)
	l.clip_text = true
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(l)
	
	if not disabled:
		var btn = Button.new()
		btn.text = "..."
		btn.custom_minimum_size = Vector2(28, 28)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var sb_blue = preload("res://assets/UI/menu_button_blue.tres")
		var sb_hover = preload("res://assets/UI/menu_button_blue_hover.tres")
		var sb_pressed = preload("res://assets/UI/menu_button_blue_pressed.tres")
		btn.add_theme_stylebox_override("normal", sb_blue)
		btn.add_theme_stylebox_override("hover", sb_hover)
		btn.add_theme_stylebox_override("pressed", sb_pressed)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(func(): sig_empty_slot_clicked.emit(_room_id, allowed))
		hbox.add_child(btn)
		
	return p
