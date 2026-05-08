extends Node
## Globales Activity-Log: schreibt Einträge bei jedem Gast-Event.
## UI-Darstellung kommt als eigenes Issue.

signal entry_added(entry: Dictionary)

var _entries: Array = []


func add(type: String, message: String, game_day: int, game_time: int) -> void:
	var entry := {
		"type":       type,
		"message":    message,
		"game_day":   game_day,
		"game_time":  game_time,
		"is_read":    false,
		"created_at": Time.get_datetime_string_from_system(),
	}
	_entries.append(entry)
	entry_added.emit(entry)


func get_entries() -> Array:
	return _entries


func get_unread_count() -> int:
	var n := 0
	for e: Dictionary in _entries:
		if not e.get("is_read", false):
			n += 1
	return n


func mark_all_read() -> void:
	for e: Dictionary in _entries:
		e["is_read"] = true


func clear() -> void:
	_entries.clear()
