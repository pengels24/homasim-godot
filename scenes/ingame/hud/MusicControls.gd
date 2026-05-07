extends Control
## Musik-Steuerung im Ingame-HUD: Pause/Resume + Next.
## Position wechselt automatisch mit SettingsManager.hud_side.

const COLOR_BG       := Color(0.04, 0.07, 0.13, 0.92)
const COLOR_BG_HOVER := Color(0.10, 0.13, 0.20, 0.96)
const COLOR_GOLD     := Color(0.918, 0.702, 0.031, 0.85)
const COLOR_GOLD_HOV := Color(0.918, 0.702, 0.031, 1.0)
const RADIUS         := 10
const MARGIN         := 16.0
const WIDTH          := 100.0   # offset_right – offset_left

@onready var _btn_pause_resume: Button        = $HBox/BtnPauseResume
@onready var _btn_next:         Button        = $HBox/BtnNext
@onready var _hbox:             HBoxContainer = $HBox


func _ready() -> void:
	_apply_style(_btn_pause_resume)
	_apply_style(_btn_next)
	_btn_next.add_theme_font_size_override("font_size", 12)
	_btn_pause_resume.pressed.connect(_on_pause_resume)
	_btn_next.pressed.connect(_on_next)
	MusicManager.playback_changed.connect(_update_icon)
	SettingsManager.hud_side_changed.connect(_reposition)
	_update_icon()
	_reposition()


func _reposition() -> void:
	if SettingsManager.hud_side == "right":
		# HUD rechts → Audio-Controls unten links
		_hbox.anchor_left     = 0.0
		_hbox.anchor_right    = 0.0
		_hbox.offset_left     = MARGIN
		_hbox.offset_right    = MARGIN + WIDTH
		_hbox.grow_horizontal = Control.GROW_DIRECTION_END
	else:
		# HUD links oder Mitte → Audio-Controls unten rechts
		_hbox.anchor_left     = 1.0
		_hbox.anchor_right    = 1.0
		_hbox.offset_left     = -(MARGIN + WIDTH)
		_hbox.offset_right    = -MARGIN
		_hbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN


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
