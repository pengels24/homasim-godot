extends HBoxContainer
class_name KeybindingRow

@onready var lbl_action: Label = $LblAction
@onready var btn_primary: Button = $BtnPrimary
@onready var btn_alt: Button = $BtnAlt
@onready var btn_delete: Button = $BtnDelete

var is_hovered: bool = false

func _ready() -> void:
	var update_hover = func():
		var rect = get_global_rect()
		var mpos = get_global_mouse_position()
		var new_hover = rect.has_point(mpos)
		if new_hover != is_hovered:
			is_hovered = new_hover
			queue_redraw()

	mouse_entered.connect(update_hover)
	mouse_exited.connect(update_hover)
	
	for child in get_children():
		if child is Control:
			child.mouse_entered.connect(update_hover)
			child.mouse_exited.connect(update_hover)

func _draw() -> void:
	if is_hovered:
		# Zeichnet ein dunkleres, halbtransparentes Schwarz
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.2))
