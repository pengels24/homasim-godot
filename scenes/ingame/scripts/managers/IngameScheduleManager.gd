extends Node
class_name IngameScheduleManager

signal sig_schedule_event(event_id: String)

var _master_schedule: Array = []
var _daily_queue: Array = []


# =============================================================================
func setup(config_path: String = "res://config/daily_schedule.json") -> void:
  _load_schedule(config_path)

  if not TimeManager.has_signal("sig_minute_passed"):
    push_error("[ScheduleManager] ❌ TimeManager braucht das Signal 'sig_minute_passed'!")
  elif not TimeManager.sig_minute_passed.is_connected(_on_minute_passed):
    TimeManager.sig_minute_passed.connect(_on_minute_passed)

  if not TimeManager.sig_day_ended.is_connected(_on_day_ended):
    TimeManager.sig_day_ended.connect(_on_day_ended)

  _build_daily_queue()


# =============================================================================
func _load_schedule(path: String) -> void:
  if not FileAccess.file_exists(path):
    push_error("[ScheduleManager] ❌ Datei nicht gefunden: " + path)
    return # <-- Jetzt korrekt eingerückt!

  var file := FileAccess.open(path, FileAccess.READ)
  var content := file.get_as_text()
  file.close()

  var data = JSON.parse_string(content)
  if typeof(data) == TYPE_ARRAY:
    _master_schedule = []

    for entry in data:
      if typeof(entry) == TYPE_DICTIONARY and entry.has("hour") and entry.has("event"):
        var h: int = int(entry["hour"])
        var m: int = int(entry.get("minute", 0))
        var trigger_time: int = (h * 60) + m

        _master_schedule.append({
          "trigger_time": trigger_time,
          "event": entry["event"]
        })
      else:
        push_error("[ScheduleManager] ❌ Ungültiges Event-Format in JSON.")

    _master_schedule.sort_custom(func(a, b): return a["trigger_time"] < b["trigger_time"])
  else:
    push_error("[ScheduleManager] ❌ Ungültiges JSON-Format (kein Array) in: " + path)


# =============================================================================
func _build_daily_queue() -> void:
  _daily_queue = _master_schedule.duplicate(true)


# =============================================================================
func _on_minute_passed(current_game_time: int) -> void:
  if _daily_queue.is_empty():
    return

  var next_event = _daily_queue[0]

  if current_game_time >= next_event["trigger_time"]:
    sig_schedule_event.emit(next_event["event"])
    _daily_queue.pop_front()

    # <-- Jetzt korrekt UNTER dem if eingerückt!
    _on_minute_passed(current_game_time)


# =============================================================================
func _on_day_ended(_new_day: int) -> void:
  _build_daily_queue()