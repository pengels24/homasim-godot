extends Node2D
class_name IngameClock
## ANG-170 – Spieluhr: Pause/Play/FF, Tagesübergang, Zeitfortschritt.
## Erhält alle nötigen Node-Referenzen via configure(). Keine @onready.

signal day_ended(new_day: int)
signal save_requested(game_time: int)
signal hour_passed(hour: int)

const SECONDS_PER_GAME_MINUTE := 2.0

var _hotel:       Dictionary
var _time_lbl:    Label
var _btn_pause:   Button
var _btn_play:    Button
var _btn_ff:      Button

var _game_hour:   int   = 10
var _game_minute: int   = 0
var _game_paused: bool  = true
var _game_speed:  float = 1.0
var _time_accum:  float = 0.0

var _sb_normal: StyleBoxFlat
var _sb_active: StyleBoxFlat


func configure(hotel: Dictionary, time_lbl: Label,
		btn_pause: Button, btn_play: Button, btn_ff: Button) -> void:
	_hotel     = hotel
	_time_lbl  = time_lbl
	_btn_pause = btn_pause
	_btn_play  = btn_play
	_btn_ff    = btn_ff
	_sb_normal = _make_ctrl_sb(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55))
	_sb_active = _make_ctrl_sb(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0))
	for btn: Button in [btn_pause, btn_play, btn_ff]:
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	var game_time_min: int = int(hotel.get("game_time", 600))
	_game_hour   = int(game_time_min / 60.0)
	_game_minute = game_time_min % 60
	_update_time_label()
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_ff.pressed.connect(_on_ff_pressed)
	_update_speed_buttons()


func get_game_time() -> int:
	return _game_hour * 60 + _game_minute

func get_hour() -> int:
	return _game_hour


func is_paused() -> bool:
	return _game_paused


func set_game_time(minutes: int) -> void:
	_game_hour   = int(minutes / 60.0)
	_game_minute = minutes % 60
	_update_time_label()


func pause() -> void:
	_game_paused = true
	_update_speed_buttons()


func resume() -> void:
	_game_paused = false
	_game_speed  = 1.0
	_update_speed_buttons()


# ── Prozess ───────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _time_lbl == null:
		return
	_tick_game_clock(delta)


func _tick_game_clock(delta: float) -> void:
	if _game_paused:
		return
	_time_accum += delta * _game_speed
	var minutes_passed := int(_time_accum / SECONDS_PER_GAME_MINUTE)
	if minutes_passed == 0:
		return
	_time_accum -= minutes_passed * SECONDS_PER_GAME_MINUTE
	_game_minute += minutes_passed
	if _game_minute >= 60:
		var prev_hour := _game_hour
		_game_hour    += int(_game_minute / 60.0)
		_game_minute   = _game_minute % 60
		if _game_hour != prev_hour and _game_hour < 24:
			hour_passed.emit(_game_hour)
	if _game_hour >= 24:
		_game_hour   = 6
		_game_minute = 0
		_game_paused = true
		_game_speed  = 1.0
		_update_speed_buttons()
		_on_day_end()
	_update_time_label()


func _on_day_end() -> void:
	var new_day: int = int(_hotel.get("day", 1)) + 1
	_hotel["day"] = new_day
	day_ended.emit(new_day)
	save_requested.emit(get_game_time())


func _update_time_label() -> void:
	if not is_instance_valid(_time_lbl):
		return
	_time_lbl.text = "%02d:%02d" % [_game_hour, _game_minute]


# ── Spielgeschwindigkeit ──────────────────────────────────────────────────────

func _on_pause_pressed() -> void:
	_game_paused = true
	_game_speed  = 1.0
	_update_speed_buttons()


func _on_play_pressed() -> void:
	_game_paused = false
	_game_speed  = 1.0
	_update_speed_buttons()


func _on_ff_pressed() -> void:
	_game_paused = false
	_game_speed  = SettingsManager.ff_speed
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	var gold   := Color(0.918, 0.702, 0.031, 1)
	var normal := Color(0.65,  0.65,  0.65,  1)
	var is_ff := _game_speed == SettingsManager.ff_speed and not _game_paused
	_apply_ctrl_btn(_btn_pause, _game_paused)
	_apply_ctrl_btn(_btn_play,  not _game_paused and _game_speed == 1.0)
	_apply_ctrl_btn(_btn_ff,    is_ff)
	_btn_pause.add_theme_color_override("font_color", gold if _game_paused                           else normal)
	_btn_play.add_theme_color_override( "font_color", gold if not _game_paused and _game_speed == 1.0 else normal)
	_btn_ff.add_theme_color_override(   "font_color", gold if is_ff                                   else normal)


func _apply_ctrl_btn(btn: Button, active: bool) -> void:
	var sb := _sb_active if active else _sb_normal
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb)
	btn.add_theme_stylebox_override("pressed", _sb_active)


func _make_ctrl_sb(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = border
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.shadow_color               = Color(0, 0, 0, 0.4)
	sb.shadow_size                = 3
	sb.shadow_offset              = Vector2(0, 1)
	return sb
