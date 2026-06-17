extends Control
class_name RoomContextMenu

@onready var panel = %MenuPanel
@onready var handle = %DragHandle
@onready var btn_close = %BtnClose
@onready var btn_details = %BtnDetails
@onready var btn_service = %BtnService
@onready var btn_demolish = %BtnDemolish

var _target_room: Node2D = null
var _dragging = false
var _drag_offset = Vector2.ZERO

# =============================================================================
func _ready() -> void:
	# Fullscreen click out blocker
	gui_input.connect(_on_bg_input)
	
	# Drag logic
	handle.gui_input.connect(_on_handle_input)
	handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	
	# Buttons
	btn_close.pressed.connect(close)
	btn_details.pressed.connect(func(): _on_action("Details anzeigen"))
	btn_service.pressed.connect(_on_service_pressed)
	
	var btn_repair = btn_service.duplicate()
	btn_repair.text = "Wartung rufen"
	btn_service.get_parent().add_child(btn_repair)
	btn_repair.pressed.connect(_on_repair_pressed)
	
	# Demolish button ans Ende verschieben
	btn_demolish.get_parent().move_child(btn_demolish, -1)
	btn_demolish.pressed.connect(func(): _on_action("Zimmer abreißen"))
	
	hide()
	GameState.sig_room_clicked.connect(open)

# =============================================================================
func _on_service_pressed() -> void:
	if is_instance_valid(_target_room):
		# Test-Toggle: Sauber -> Dreckig -> Sauber
		if _target_room.get("is_service_requested"):
			_target_room.set("is_service_requested", false)
			_target_room.set("cleanliness_level", 100)
			if is_instance_valid(Toast):
				Toast.show("Test: Zimmer wieder sauber!")
		else:
			_target_room.set("is_service_requested", true)
			_target_room.set("cleanliness_level", 30)
			GameState.sig_room_needs_cleaning.emit(_target_room)
			if is_instance_valid(Toast):
				Toast.show("Test: Service angefordert!")
		
		# Indikator manuell aktualisieren
		if _target_room.has_method("_update_indicator"):
			_target_room.call("_update_indicator")
			
	close()

# =============================================================================
func open(room: Node2D) -> void:
	if InputHandler.current_mode != InputHandler.InputMode.NORMAL:
		return
		
	_target_room = room
	if _target_room.has_method("set_highlight"):
		_target_room.set_highlight(true)
	
	var canvas_trans = room.get_global_transform_with_canvas()
	var pos_on_screen = canvas_trans.origin
	var sz = room.get_tile_size()
	var width_on_screen = sz.x * 16 * canvas_trans.get_scale().x
	
	# Start-Position: Links daneben
	var start_x = pos_on_screen.x - 220
	if start_x < 0:
		start_x = pos_on_screen.x + width_on_screen + 20
		
	panel.position = Vector2(start_x, pos_on_screen.y)
	
	show()
	# Blockiere andere Inputs
	InputHandler.current_mode = InputHandler.InputMode.MODAL

# =============================================================================
func close() -> void:
	if is_instance_valid(_target_room) and _target_room.has_method("set_highlight"):
		_target_room.set_highlight(false)
		
	hide()
	if InputHandler.current_mode == InputHandler.InputMode.MODAL:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL

# =============================================================================
func _on_action(action_name: String) -> void:
	if is_instance_valid(Toast):
		Toast.show(action_name + ": Coming soon!")
	close()

# =============================================================================
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_escape"):
		get_viewport().set_input_as_handled()
		close()

# =============================================================================
func _on_bg_input(event: InputEvent) -> void:
	# Klick außerhalb des Panels
	if event is InputEventMouseButton and event.pressed:
		close()

# =============================================================================
func _on_handle_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_offset = event.global_position - panel.global_position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		panel.global_position = event.global_position - _drag_offset

# =============================================================================
func _on_repair_pressed() -> void:
	if is_instance_valid(_target_room):
		if _target_room.get("is_repair_requested"):
			_target_room.set("is_repair_requested", false)
			_target_room.set("maintenance_level", 100)
			if _target_room.has_method("_update_indicator"):
				_target_room.call("_update_indicator")
			if is_instance_valid(Toast):
				Toast.show("Test: Zimmer repariert!")
		else:
			_target_room.set("is_repair_requested", true)
			_target_room.set("maintenance_level", 30)
			if _target_room.has_method("_update_indicator"):
				_target_room.call("_update_indicator")
			GameState.sig_room_needs_repair.emit(_target_room)
			if is_instance_valid(Toast):
				Toast.show("Test: Wartung angefordert!")
