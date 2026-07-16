extends PanelContainer

signal sig_remove_clicked(staff_id: String)

@onready var lbl_name: Label = %LblName
@onready var btn_remove: Button = %BtnRemove

var _staff_id: String = ""

func _ready() -> void:
	btn_remove.pressed.connect(func(): sig_remove_clicked.emit(_staff_id))
	btn_remove.tooltip_text = GameState.T("ui.staff.assign.unassign", "Personal freistellen")

func populate(staff: Dictionary) -> void:
	_staff_id = staff.get("id", "")
	var r = staff.get("role", "")
	var r_name = StaffManager.staff_config.get("roles", {}).get(r, {}).get("name", r)
	lbl_name.text = "%s %s (%s)" % [staff.get("first_name", ""), staff.get("last_name", ""), GameState.T(r_name)]
