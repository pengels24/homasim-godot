extends PanelContainer

signal sig_slot_clicked(slot_index: int)

var slot_index: int = -1
var is_empty: bool = true

@onready var label_number: Label = %SlotNumber
@onready var label_name: Label = %SlotName
@onready var label_info: Label = %SlotInfo

# =============================================================================
func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# =============================================================================
func setup(index: int, save_name: String, info_text: String, empty: bool) -> void:
	slot_index = index
	is_empty = empty

	label_number.text = str(index)
	label_name.text = save_name
	label_info.text = info_text


# =============================================================================
func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sig_slot_clicked.emit(slot_index)


# =============================================================================
func set_selected(selected: bool) -> void:
	if selected:
		modulate = Color(0.5, 1.0, 0.5)
	else:
		modulate = Color(1.0, 1.0, 1.0)