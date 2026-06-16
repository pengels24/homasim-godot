extends Button

@onready var glow_overlay: Panel = $GlowOverlay
var _glow_style: StyleBoxFlat

func _ready() -> void:
	glow_overlay.hide()
	# Duplicate the stylebox so border color changes don't affect all instances
	if glow_overlay.has_theme_stylebox("panel"):
		_glow_style = glow_overlay.get_theme_stylebox("panel").duplicate()
		glow_overlay.add_theme_stylebox_override("panel", _glow_style)

func set_glow_state(active: bool, is_unlocked: bool) -> void:
	if active:
		glow_overlay.show()
		glow_overlay.modulate.a = 1.0
		if is_unlocked:
			_glow_style.border_color = Color("#366e4d")
		else:
			_glow_style.border_color = Color("#b02e3b")
	else:
		glow_overlay.hide()

func get_glow_node() -> Panel:
	return glow_overlay
