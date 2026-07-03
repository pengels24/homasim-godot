extends PanelContainer

signal sig_slot_clicked(slot_index: int)

var slot_index: int = -1
var is_empty: bool = true

@onready var label_number: Label = %SlotNumber
@onready var label_name: Label = %SlotName
@onready var label_info: Label = %SlotInfo

# =============================================================================
func set_selected(selected: bool) -> void:
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8

	if selected:
		style.bg_color = Color(0.10, 0.28, 0.12, 1.0)
	else:
		style.bg_color = Color(0.08, 0.09, 0.12, 1.0)
		
	add_theme_stylebox_override("panel", style)

func _ready() -> void:
	gui_input.connect(_on_gui_input)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	set_selected(false)

	# Fonts anpassen laut Styleguide
	label_name.add_theme_font_size_override("font_size", 20)
	label_name.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	
	label_number.add_theme_font_size_override("font_size", 18)
	label_number.add_theme_color_override("font_color", Color(0.63, 0.63, 0.67))
	
	label_info.add_theme_font_size_override("font_size", 18)
	label_info.add_theme_color_override("font_color", Color(0.63, 0.63, 0.67))

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