extends Node2D
class_name IngameClock
## ANG-170 – Spieluhr: Pause/Play/FF, Tagesübergang, Zeitfortschritt.
## Erhält alle nötigen Node-Referenzen via configure(). Keine @onready.

signal day_ended(new_day: int)
signal save_requested(game_time: int)

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


func configure(hotel: Dictionary, time_lbl: Label,
		btn_pause: Button, btn_play: Button, btn_ff: Button) -> void:
	_hotel     = hotel
	_time_lbl  = time_lbl
	_btn_pause = btn_pause
	_btn_play  = btn_play
	_btn_ff    = btn_ff
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
		_game_hour  += int(_game_minute / 60.0)
		_game_minute  = _game_minute % 60
	if _game_hour >= 24:
		_game_hour   = 0
		_game_minute = 0
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
	_game_speed  = 10.0
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	var gold   := Color(0.918, 0.702, 0.031, 1)
	var normal := Color(0.65,  0.65,  0.65,  1)
	_btn_pause.add_theme_color_override("font_color", gold   if _game_paused                            else normal)
	_btn_play.add_theme_color_override( "font_color", gold   if not _game_paused and _game_speed == 1.0 else normal)
	_btn_ff.add_theme_color_override(   "font_color", gold   if _game_speed == 10.0                     else normal)
