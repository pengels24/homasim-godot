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
		# ANG-255: guest_arrival wird dynamisch berechnet, nicht aus der Config
		if event.get("event") == "guest_arrival":
			continue
			
		if event["trigger_time"] > start_time:
			_daily_queue.append(event.duplicate())
			
	# ANG-255: Dynamische Gäste-Spawns
	var guest_mgr: Node = get_tree().get_first_node_in_group("guest_manager")
	if guest_mgr == null:
		# Fallback falls Gruppe nicht gefunden, suche in der aktuellen Szene
		var ingame_root = get_parent()
		if ingame_root.has_node("GuestManager"):
			guest_mgr = ingame_root.get_node("GuestManager")
			
	if guest_mgr and guest_mgr.has_method("generate_daily_schedule"):
		var spawn_times = guest_mgr.generate_daily_schedule(start_time)
		for t in spawn_times:
			_daily_queue.append({
				"trigger_time": t,
				"event": "guest_arrival"
			})
	else:
		print("[ScheduleManager] ERROR: guest_mgr is null or missing generate_daily_schedule!")
			
	# Queue sortieren (wichtig, da wir neue Events hinzugefügt haben)
	_daily_queue.sort_custom(func(a, b): return a["trigger_time"] < b["trigger_time"])
	print("[ScheduleManager] _build_daily_queue completed with ", _daily_queue.size(), " total events. Queue:")
	for ev in _daily_queue:
		print("  - Time: ", ev["trigger_time"], " Event: ", ev["event"])


# =============================================================================
func recalculate_guest_spawns() -> void:
	var current_time = TimeManager.get_game_time()
	print("[ScheduleManager] recalculate_guest_spawns at time ", current_time)
	
	# Alte noch nicht getriggerte "guest_arrival" Events entfernen
	var new_queue := []
	for ev in _daily_queue:
		if ev["event"] != "guest_arrival":
			new_queue.append(ev)
	_daily_queue = new_queue
	
	var guest_mgr: Node = get_tree().get_first_node_in_group("guest_manager")
	if guest_mgr == null:
		var ingame_root = get_parent()
		if ingame_root.has_node("GuestManager"):
			guest_mgr = ingame_root.get_node("GuestManager")
			
	if guest_mgr and guest_mgr.has_method("generate_daily_schedule"):
		var spawn_times = guest_mgr.generate_daily_schedule(current_time)
		for t in spawn_times:
			_daily_queue.append({
				"trigger_time": t,
				"event": "guest_arrival"
			})
			
	_daily_queue.sort_custom(func(a, b): return a["trigger_time"] < b["trigger_time"])
	
	print("[ScheduleManager] Queue updated after recalculation. New queue size: ", _daily_queue.size())

# =============================================================================
func _on_minute_passed(current_game_time: int) -> void:
	if _daily_queue.is_empty():
		return

	var next_event = _daily_queue[0]

	if current_game_time >= next_event["trigger_time"]:
		print("[ScheduleManager] Triggering event: ", next_event["event"], " at time ", current_game_time)
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
