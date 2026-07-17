extends Control

@onready var handle = %DragHandle
@onready var btn_close = %BtnClose
@onready var btn_collapse = %BtnCollapse
@onready var label_title = %Label
@onready var vbox_list = %VBoxList
@onready var panel = %MenuPanel
@onready var resize_handle = %ResizeHandle

var _target_room: Node2D = null
var _dragging = false
var _drag_offset = Vector2()
var _resizing = false
var _resize_start_y: float = 0.0
var _resize_start_h: float = 0.0
var _collapsed := false
var _pre_collapse_h: float = 300.0
var _update_timer = 0.0
var _group_siblings: Dictionary = {}  # sibling -> relative offset (Shift+Drag)

const MIN_HEIGHT := 150.0

func _ready() -> void:
	handle.gui_input.connect(_on_handle_input)
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	btn_close.pressed.connect(close)
	btn_collapse.pressed.connect(_toggle_collapse)
	label_title.add_theme_font_size_override("font_size", 24)
	
	%MenuPanel.gui_input.connect(_on_panel_gui_input)
	resize_handle.gui_input.connect(_on_resize_handle_input)

func _toggle_collapse() -> void:
	_collapsed = not _collapsed
	var content = panel.get_node_or_null("VBoxContainer/MarginContainer")
	if not content: return
	
	if _collapsed:
		_pre_collapse_h = panel.size.y
		content.visible = false
		resize_handle.visible = false
		panel.custom_minimum_size = Vector2(panel.size.x, 0)
		panel.size = Vector2(panel.size.x, 32)
		size = panel.size
		btn_collapse.text = "▼" # eingeklappt -> Pfeil nach unten = aufklappen
	else:
		content.visible = true
		resize_handle.visible = true
		panel.custom_minimum_size = Vector2(panel.size.x, MIN_HEIGHT)
		panel.size = Vector2(panel.size.x, _pre_collapse_h)
		size = panel.size
		btn_collapse.text = "▲" # offen -> Pfeil nach oben = zuklappen
	
func get_target_room() -> Node2D:
	return _target_room

func setup(room: Node2D) -> void:
	_target_room = room
	if is_instance_valid(room) and room.has_method("get_definition"):
		var def = room.get_definition()
		var n = GameState.T("roomdef.name.long." + def.get("id", ""))
		label_title.text = "  ::: Live: " + n
	else:
		label_title.text = "  ::: Live-Details"
		
	_refresh_list()
	
func _process(delta: float) -> void:
	_update_timer += delta
	if _update_timer >= 0.5:
		_update_timer = 0.0
		_refresh_list()
		
func _refresh_list() -> void:
	if not is_instance_valid(_target_room):
		close()
		return
		
	if not _target_room.has_method("get_live_details"):
		return
		
	var details = _target_room.get_live_details()
	
	# Alte Einträge löschen
	for child in vbox_list.get_children():
		child.queue_free()
		
	# Neue Einträge erstellen
	for row in details:
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 24) # Abstand zwischen Texten
		
		var lbl_left = Label.new()
		lbl_left.text = row.get("left", "")
		lbl_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_left.add_theme_font_size_override("font_size", 22)
		lbl_left.clip_text = true # Verhindert, dass der Name alles sprengt
		
		var lbl_right = Label.new()
		lbl_right.text = row.get("right", "")
		lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_right.add_theme_font_size_override("font_size", 22)
		lbl_right.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		lbl_right.custom_minimum_size = Vector2(100, 0) # Platz für Timer reservieren
		
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(16, 0)
		
		hbox.add_child(lbl_left)
		hbox.add_child(lbl_right)
		hbox.add_child(spacer)
		vbox_list.add_child(hbox)
		
func close() -> void:
	queue_free()

func _on_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				move_to_front()
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
				_group_siblings.clear()
				if Input.is_key_pressed(KEY_SHIFT):
					_collect_group_siblings()
			else:
				_dragging = false
				_group_siblings.clear()
	elif event is InputEventMouseMotion and _dragging:
		var new_pos = get_global_mouse_position() - _drag_offset
		if _group_siblings.is_empty():
			global_position = _clamp_to_screen(_apply_snapping(new_pos))
		else:
			# Gruppe verschieben: kein Snapping damit sich die Gruppe nicht selbst bekämpft
			var delta = _clamp_to_screen(new_pos) - global_position
			global_position += delta
			for sibling in _group_siblings:
				if is_instance_valid(sibling):
					sibling.global_position = _clamp_to_screen(sibling.global_position + delta)

func _collect_group_siblings() -> void:
	for sibling in get_parent().get_children():
		if sibling == self or not sibling.has_method("get_target_room"):
			continue
		if not is_instance_valid(sibling):
			continue
		if _is_touching(sibling):
			_group_siblings[sibling] = sibling.global_position - global_position

func _is_touching(sibling: Node) -> bool:
	var s_panel = sibling.get_node_or_null("%MenuPanel")
	if not s_panel: return false
	var my_r = Rect2(global_position, panel.size)
	var s_r  = Rect2(sibling.global_position, s_panel.size)
	# Fenster gelten als aneinander wenn sie sich im Snap-Radius berühren
	return my_r.grow(SNAP_DIST * 1.5).intersects(s_r)

func _clamp_to_screen(pos: Vector2) -> Vector2:
	var screen = get_viewport().get_visible_rect().size
	const HANDLE_H := 32.0
	var clamped_x = clamp(pos.x, 0.0, screen.x - panel.size.x)
	var clamped_y = clamp(pos.y, 0.0, screen.y - HANDLE_H)
	return Vector2(clamped_x, clamped_y)

const SNAP_DIST := 15.0

func _apply_snapping(new_pos: Vector2) -> Vector2:
	var my_size = panel.size
	# Eigene Kanten nach dem Move
	var my_left   = new_pos.x
	var my_right  = new_pos.x + my_size.x
	var my_top    = new_pos.y
	var my_bottom = new_pos.y + my_size.y
	
	var snap_x: float = new_pos.x
	var snap_y: float = new_pos.y
	var best_dx := INF
	var best_dy := INF
	
	for sibling in get_parent().get_children():
		if sibling == self or not sibling.has_method("get_target_room"):
			continue
		if not is_instance_valid(sibling):
			continue
		
		var s_panel = sibling.get_node_or_null("%MenuPanel")
		if not s_panel:
			continue
		
		var s_pos  = sibling.global_position
		var s_size = s_panel.size
		var s_left   = s_pos.x
		var s_right  = s_pos.x + s_size.x
		var s_top    = s_pos.y
		var s_bottom = s_pos.y + s_size.y
		
		# Kante-an-Kante horizontal: meine rechte an seiner linken
		var dx = abs(my_right - s_left)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_left - my_size.x
		# Kante-an-Kante horizontal: meine linke an seiner rechten
		dx = abs(my_left - s_right)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_right
		# Kanten-bündig horizontal: linke Kanten ausrichten
		dx = abs(my_left - s_left)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_left
		# Kanten-bündig horizontal: rechte Kanten ausrichten
		dx = abs(my_right - s_right)
		if dx < SNAP_DIST and dx < best_dx:
			best_dx = dx
			snap_x = s_right - my_size.x
		
		# Kante-an-Kante vertikal: meine untere an seiner oberen
		var dy = abs(my_bottom - s_top)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_top - my_size.y
		# Kante-an-Kante vertikal: meine obere an seiner unteren
		dy = abs(my_top - s_bottom)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_bottom
		# Kanten-bündig vertikal: obere Kanten ausrichten (Ecke auf Ecke)
		dy = abs(my_top - s_top)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_top
		# Kanten-bündig vertikal: untere Kanten ausrichten (Ecke auf Ecke)
		dy = abs(my_bottom - s_bottom)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snap_y = s_bottom - my_size.y
	
	return Vector2(snap_x, snap_y)

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			get_viewport().set_input_as_handled()

func _on_resize_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_resizing = true
			_resize_start_y = get_global_mouse_position().y
			_resize_start_h = panel.size.y
		else:
			_resizing = false
	elif event is InputEventMouseMotion and _resizing:
		var delta_y = get_global_mouse_position().y - _resize_start_y
		var raw_h = max(MIN_HEIGHT, _resize_start_h + delta_y)
		var new_h = _snap_resize_height(raw_h)
		panel.custom_minimum_size = Vector2(panel.size.x, new_h)
		panel.size = Vector2(panel.size.x, new_h)
		size = panel.size

func _snap_resize_height(raw_h: float) -> float:
	var my_top = global_position.y
	var my_bottom = my_top + raw_h
	var best_dy := INF
	var snapped_h := raw_h
	
	for sibling in get_parent().get_children():
		if sibling == self or not sibling.has_method("get_target_room"):
			continue
		if not is_instance_valid(sibling):
			continue
		var s_panel = sibling.get_node_or_null("%MenuPanel")
		if not s_panel:
			continue
		var s_top    = sibling.global_position.y
		var s_bottom = sibling.global_position.y + s_panel.size.y
		
		# Meine untere Kante an seiner oberen
		var dy = abs(my_bottom - s_top)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snapped_h = s_top - my_top
		# Meine untere Kante bündig mit seiner unteren
		dy = abs(my_bottom - s_bottom)
		if dy < SNAP_DIST and dy < best_dy:
			best_dy = dy
			snapped_h = s_bottom - my_top
	
	return max(MIN_HEIGHT, snapped_h)
