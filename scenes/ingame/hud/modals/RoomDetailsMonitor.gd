extends Control

@onready var handle = %DragHandle
@onready var btn_close = %BtnClose
@onready var label_title = %Label
@onready var vbox_list = %VBoxList
@onready var panel = %MenuPanel

var _target_room: Node2D = null
var _dragging = false
var _drag_offset = Vector2()
var _update_timer = 0.0

func _ready() -> void:
	handle.gui_input.connect(_on_handle_input)
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	btn_close.pressed.connect(close)
	label_title.add_theme_font_size_override("font_size", 24)
	
	%MenuPanel.gui_input.connect(_on_panel_gui_input)
	
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
		var lbl_left = Label.new()
		lbl_left.text = row.get("left", "")
		lbl_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_left.add_theme_font_size_override("font_size", 22)
		
		var lbl_right = Label.new()
		lbl_right.text = row.get("right", "")
		lbl_right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_right.add_theme_font_size_override("font_size", 22)
		lbl_right.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		
		hbox.add_child(lbl_left)
		hbox.add_child(lbl_right)
		vbox_list.add_child(hbox)
		
func close() -> void:
	queue_free()

func _on_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_dragging = true
				_drag_offset = get_global_mouse_position() - global_position
			else:
				_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		global_position = get_global_mouse_position() - _drag_offset

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			%MenuPanel.accept_event()
