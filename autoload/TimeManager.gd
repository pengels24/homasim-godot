extends Node

signal sig_hour_passed(hour: int)
signal sig_day_ended(new_day: int)
signal sig_save_requested(game_time: int)

# NEU: Signale für das UI, da der Manager keine Labels/Buttons mehr direkt kennt
signal sig_time_updated(formatted_time: String)
signal sig_day_updated(day_str: String)
signal sig_speed_changed(is_paused: bool, current_speed: float)
signal sig_minute_passed(total_game_minutes: int)
signal sig_time_jumped(new_time: int) # <--- NEU: Signal für den DevConsole Zeitsprung

const SECONDS_PER_GAME_MINUTE := 2.0

var _hotel_ref: Dictionary # Merken wir uns, um Tag/Zeit beim Tageswechsel ins Savegame zu schreiben

var _game_hour: int = 10
var _game_minute: int = 0
var _game_paused: bool = true
var _game_speed: float = 1.0
var _time_accum: float = 0.0


# =============================================================================
# Wird beim Spielstart von Ingame.gd aufgerufen, um die Uhrzeit zu initialisieren
func setup(hotel: Dictionary) -> void:
  _hotel_ref = hotel
  var game_time_min: int = int(hotel.get("game_time", 600))
  _game_hour = int(game_time_min / 60.0)
  _game_minute = game_time_min % 60

  _update_time_ui()
  _update_day_ui()
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func get_game_time() -> int:
  return _game_hour * 60 + _game_minute


# =============================================================================
func get_hour() -> int:
  return _game_hour


# =============================================================================
func is_paused() -> bool:
  return _game_paused


# =============================================================================
func pause() -> void:
  _game_paused = true
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func resume() -> void:
  _game_paused = false
  _game_speed = 1.0
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func fast_forward(ff_speed: float) -> void:
  _game_paused = false
  _game_speed = ff_speed
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func _process(delta: float) -> void:
  # Nur ticken, wenn ein Spiel/Hotel geladen wurde
  if _hotel_ref == null or _hotel_ref.is_empty():
    return

  _tick_game_clock(delta)


# =============================================================================
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
    _game_hour += int(_game_minute / 60.0)
    _game_minute = _game_minute % 60

    if _game_hour != prev_hour and _game_hour < 24:
      sig_hour_passed.emit(_game_hour)

  if _game_hour >= 24:
    _game_hour = 6
    _game_minute = 0
    _game_paused = true
    _game_speed = 1.0
    sig_speed_changed.emit(_game_paused, _game_speed)
    _on_day_end()

  _update_time_ui()
  sig_minute_passed.emit(get_game_time()) # <--- NEU


# =============================================================================
func _on_day_end() -> void:
  var new_day: int = int(_hotel_ref.get("day", 1)) + 1
  _hotel_ref["day"] = new_day
  _update_day_ui()
  sig_day_ended.emit(new_day)
  sig_save_requested.emit(get_game_time())


# =============================================================================
func _update_time_ui() -> void:
  var formatted_time := "%02d:%02d" % [_game_hour, _game_minute]
  sig_time_updated.emit(formatted_time)


# =============================================================================
func _update_day_ui() -> void:
  sig_day_updated.emit(str(_hotel_ref.get("day", 1)))


# =============================================================================
func set_game_time(minutes: int) -> void:
  _game_hour   = int(minutes / 60.0)
  _game_minute = minutes % 60
  _update_time_ui()
  sig_time_jumped.emit(minutes) # <--- NEU: UI und Co. informieren!
