extends PanelContainer

signal sig_remove_clicked(staff_id: String)

@onready var lbl_name: Label = %LblName
@onready var btn_remove: Button = %BtnRemove

var _staff_id: String = ""

func _ready() -> void:
	btn_remove.pressed.connect(func(): sig_remove_clicked.emit(_staff_id))

func populate(staff: Dictionary) -> void:
	_staff_id = staff.get("id", "")
	lbl_name.text = "%s %s" % [staff.get("first_name", ""), staff.get("last_name", "")]
