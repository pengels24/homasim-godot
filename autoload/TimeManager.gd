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

signal sig_midnight_struck(day: int) # <--- NEU: Für den Kassensturz (23:59)
signal sig_morning_struck()          # <--- NEU: Fürs Aufstehen (06:00)

const SECONDS_PER_GAME_MINUTE := 4.0

var _hotel_ref: Dictionary # Merken wir uns, um Tag/Zeit beim Tageswechsel ins Savegame zu schreiben

var _game_hour: int = 10
var _game_minute: int = 0
var _game_paused: bool = true
var _game_speed: float = 1.0
var _time_accum: float = 0.0

var _ff_tip_shown: bool = false
var _ff_used: bool = false


# =============================================================================
func _ready() -> void:
  # Das macht diesen Autoload immun gegen die Godot-Pause!
  process_mode = Node.PROCESS_MODE_ALWAYS


# =============================================================================
# Wird beim Spielstart von Ingame.gd aufgerufen, um die Uhrzeit zu initialisieren
func setup(hotel: Dictionary) -> void:
  _hotel_ref = hotel
  var game_time_min: int = int(hotel.get("game_time", 600))
  _game_hour = int(game_time_min / 60.0)
  _game_minute = game_time_min % 60

  get_tree().paused = _game_paused # <--- BUGFIX: Engine beim Start hart pausieren!

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
  get_tree().paused = true # <--- NEU: Die harte Engine-Pause!
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func resume() -> void:
  _game_paused = false
  _game_speed = 1.0
  get_tree().paused = false # <--- NEU: Spielwelt läuft weiter
  sig_speed_changed.emit(_game_paused, _game_speed)


# =============================================================================
func fast_forward(ff_speed: float) -> void:
  _ff_used = true
  _game_paused = false
  _game_speed = ff_speed
  get_tree().paused = false # <--- NEU: Spielwelt läuft weiter (schneller)
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

  # Um Punkt Mitternacht ist Schichtwechsel / Tagesabschluss
  if _game_hour >= 24:
    _game_hour = 24
    _game_minute = 0
    _game_paused = true
    get_tree().paused = true
    _game_speed = 1.0
    sig_speed_changed.emit(_game_paused, _game_speed)
    _on_day_end()

  _update_time_ui()
  sig_minute_passed.emit(get_game_time())

  if not _ff_tip_shown and not _ff_used and _game_hour == 6 and _game_minute == 15 and SettingsManager.tutorial_tips:
      if TutorialManager:
          TutorialManager.trigger("tip_fast_forward")
      _ff_tip_shown = true


# =============================================================================
func _on_day_end() -> void:
  var current_day: int = int(_hotel_ref.get("day", 1))

  # 1. Wir rufen laut, dass Mitternacht ist. Der GuestManager kann jetzt seine Strafen verteilen.
  sig_midnight_struck.emit(current_day)

  # 2. Erst DANACH sagen wir dem UI, dass der Tag beendet ist (damit die Strafen in der Kasse sind).
  sig_day_ended.emit(current_day)


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


# =============================================================================
func start_next_day() -> void:
  var new_day: int = int(_hotel_ref.get("day", 1)) + 1
  _hotel_ref["day"] = new_day

  _game_hour = 6
  _game_minute = 0

  # NEU: 3. Wir rufen laut, dass es Morgen ist. Der GuestManager schickt jetzt die Leute zum Checkout.
  sig_morning_struck.emit()

  _update_day_ui()
  _update_time_ui()

  # Der Tag beginnt pausiert!
  sig_save_requested.emit(get_game_time())