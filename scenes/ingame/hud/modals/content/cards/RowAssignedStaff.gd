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
	
	if staff.get("training_state", "none") == "in_training":
		lbl_name.text += " [📖]"
		lbl_name.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		btn_remove.disabled = true
		btn_remove.tooltip_text = GameState.T("ui.staff.assign.training_locked", "In Schulung (Gesperrt)")
	else:
		lbl_name.remove_theme_color_override("font_color")
		btn_remove.disabled = false
		btn_remove.tooltip_text = GameState.T("ui.staff.assign.unassign", "Personal freistellen")
