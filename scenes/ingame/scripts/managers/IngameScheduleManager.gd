extends Node
class_name IngameScheduleManager

signal sig_schedule_event(event_id: String)

var _daily_queue: Array = []


# =============================================================================
func setup() -> void:
  if not TimeManager.has_signal("sig_minute_passed"):
    push_error("[ScheduleManager] ❌ TimeManager braucht das Signal 'sig_minute_passed'!")
  elif not TimeManager.sig_minute_passed.is_connected(_on_minute_passed):
    TimeManager.sig_minute_passed.connect(_on_minute_passed)

  if not TimeManager.sig_morning_struck.is_connected(_on_morning_struck):
    TimeManager.sig_morning_struck.connect(_on_morning_struck)

  # ---> NEU: Auf den GameState hören
  if not GameState.sig_configs_reloaded.is_connected(force_reload_from_gamestate):
    GameState.sig_configs_reloaded.connect(force_reload_from_gamestate)

  _build_daily_queue(TimeManager.get_game_time())


# =============================================================================
func _build_daily_queue(start_time: int = 0) -> void:
  _daily_queue.clear()

  # Wir iterieren jetzt über die zentrale Registry im GameState
  for event in GameState.daily_schedule_registry:
    if event["trigger_time"] > start_time:
      _daily_queue.append(event.duplicate())


# =============================================================================
func _on_minute_passed(current_game_time: int) -> void:
  if _daily_queue.is_empty():
    return

  var next_event = _daily_queue[0]

  if current_game_time >= next_event["trigger_time"]:
    sig_schedule_event.emit(next_event["event"])
    _daily_queue.pop_front()
    _on_minute_passed(current_game_time)


# =============================================================================
func _on_morning_struck() -> void:
  _build_daily_queue(TimeManager.get_game_time())
  _on_minute_passed(TimeManager.get_game_time())


# =============================================================================
# Wird vom GameState bei reload_all_configs() aufgerufen
func force_reload_from_gamestate() -> void:
  _build_daily_queue(0)
