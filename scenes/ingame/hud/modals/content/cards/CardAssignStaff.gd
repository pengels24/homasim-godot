extends PanelContainer

signal sig_clicked(staff_id: String)

@onready var lbl_name: Label = %LblName
@onready var lbl_role: Label = %LblRole
@onready var state_dot: ColorRect = %StateDot
@onready var _selection_border: Panel = %SelectionBorder

var _staff_id: String = ""
var _staff_role: String = ""
var _is_matching: bool = true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _selection_border:
		_selection_border.hide()
		
	mouse_entered.connect(func(): if _is_matching: self_modulate = Color(1.5, 1.5, 1.5, 1.0))
	mouse_exited.connect(func(): if _is_matching: self_modulate = Color(1.0, 1.0, 1.0, 1.0))

func set_selected(sel: bool) -> void:
	if _selection_border:
		_selection_border.visible = sel

func set_matching(matches: bool) -> void:
	_is_matching = matches
	if matches:
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(1.0, 1.0, 1.0, 0.4) # Dim out non-matching staff

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_matching:
			accept_event()
			Toast.show("Staff Clicked: " + _staff_id)
			sig_clicked.emit(_staff_id)

func populate(staff: Dictionary) -> void:
	_staff_id = staff.get("id", "")
	_staff_role = staff.get("role", "")
	
	lbl_name.text = staff.get("first_name", "") + " " + staff.get("last_name", "")
	lbl_role.text = GameState.T("staff.role." + _staff_role)
	
	var is_assigned = StaffManager.room_assignments.has(_staff_id)
	state_dot.visible = is_assigned
