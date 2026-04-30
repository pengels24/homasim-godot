extends Control
## Musik-Steuerung im Ingame-HUD (unten rechts): Pause/Resume + Next.

const COLOR_BG       := Color(0.04, 0.07, 0.13, 0.92)
const COLOR_BG_HOVER := Color(0.10, 0.13, 0.20, 0.96)
const COLOR_GOLD     := Color(0.918, 0.702, 0.031, 0.85)
const COLOR_GOLD_HOV := Color(0.918, 0.702, 0.031, 1.0)
const RADIUS         := 10

@onready var _btn_pause_resume: Button = $HBox/BtnPauseResume
@onready var _btn_next:         Button = $HBox/BtnNext


func _ready() -> void:
	_apply_style(_btn_pause_resume)
	_apply_style(_btn_next)
	_btn_next.add_theme_font_size_override("font_size", 12)
	_btn_pause_resume.pressed.connect(_on_pause_resume)
	_btn_next.pressed.connect(_on_next)
	MusicManager.playback_changed.connect(_update_icon)
	_update_icon()


func _on_pause_resume() -> void:
	MusicManager.toggle_pause()


func _on_next() -> void:
	MusicManager.next_track()


func _update_icon() -> void:
	_btn_pause_resume.text = "II" if not MusicManager.is_paused() else "▶"


func _apply_style(btn: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = COLOR_BG
	sb.corner_radius_top_left     = RADIUS
	sb.corner_radius_top_right    = RADIUS
	sb.corner_radius_bottom_left  = RADIUS
	sb.corner_radius_bottom_right = RADIUS
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.border_color = COLOR_GOLD

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.bg_color     = COLOR_BG_HOVER
	sb_hover.border_color = COLOR_GOLD_HOV

	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color",         COLOR_GOLD)
	btn.add_theme_color_override("font_hover_color",   COLOR_GOLD_HOV)
	btn.add_theme_color_override("font_pressed_color", COLOR_GOLD)
	btn.add_theme_font_size_override("font_size", 18)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
