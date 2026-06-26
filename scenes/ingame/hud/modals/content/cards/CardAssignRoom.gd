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

func populate(formatted_name: String, room_id: String, _min_staff: int, max_staff: int, assigned_staff: Array) -> void:
	_room_id = room_id
	lbl_room_name.text = formatted_name
	
	var current = assigned_staff.size()
	if current == 0:
		lbl_status.text = "Kein Personal (%d/%d MitarbeiterInnen)" % [current, max_staff]
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4)) # Rot
	elif current < max_staff:
		lbl_status.text = "Teilbesetzt (%d/%d MitarbeiterInnen)" % [current, max_staff]
		lbl_status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2)) # Gelb
	else:
		lbl_status.text = "Vollbesetzt (%d MitarbeiterInnen)" % [current]
		lbl_status.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4)) # Grün
		
	for child in grid_staff.get_children():
		child.queue_free()
		
	for staff_data in assigned_staff:
		if staff_data:
			var row = ROW_STAFF.instantiate()
			grid_staff.add_child(row)
			row.populate(staff_data)
			row.sig_remove_clicked.connect(func(sid): sig_unassign_staff.emit(sid))
