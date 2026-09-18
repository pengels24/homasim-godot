extends Node

# =============================================================================
# EventManager.gd
# Verwaltet Zufallsereignisse (Phase 4 / Prestige), die durch P1.1 freigeschaltet werden.
# =============================================================================

signal sig_event_started(event_id: String, event_name: String)
signal sig_event_ended(event_id: String)

enum EventType {
	NONE,
	TRADE_FAIR, # Fachmesse
	CONCERT,    # Konzert
	HOLIDAY,    # Feiertag
	CONFERENCE  # DEPRECATED - Tages-Konferenz (P1.2) - nun getrennt in active_conferences
}

var active_event: EventType = EventType.NONE
var event_days_remaining: int = 0
var is_inspector_coming_today: bool = false

# Speichert aktive Tagungen. Key: room_instance_id, Value: config_dict
var active_conferences: Dictionary = {}

var _conference_configs: Array = []

func _ready() -> void:
	_load_conference_configs()
	TimeManager.sig_morning_struck.connect(_on_morning_struck)
	TimeManager.sig_minute_passed.connect(_on_minute_passed)

func _load_conference_configs() -> void:
	var path := "res://config/events.json"
	if FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var res = JSON.parse_string(f.get_as_text())
		if res is Array:
			_conference_configs = res
# =============================================================================
func _on_minute_passed(current_time: int) -> void:
	if current_time == 1020: # 17:00 (Konferenz-Ende)
		if active_conferences.size() > 0:
			active_conferences.clear()
			_update_hud()

# =============================================================================
func _on_morning_struck() -> void:
	# 0. Check Inspector (G1.4)
	if TechtreeManager and TechtreeManager.is_tech_unlocked("G1.4") and GameState.selected_hotel.get("level", 1) >= 9:
		var last_visit = GameState.selected_hotel.get("last_inspector_day", -999)
		var today = GameState.selected_hotel.get("day", 1)
		# Wenn noch kein Besuch oder letzter Besuch > 30-35 Tage her ist
		if today - last_visit >= 30:
			# Damit es nicht immer genau nach 30 Tagen ist, würfeln wir (oder fix bei Tag 35)
			if randf() < 0.20 or today - last_visit >= 35:
				is_inspector_coming_today = true
	# 1. Konferenzen (P1.2) aufräumen und ggf. neu starten
	active_conferences.clear()
	if TechtreeManager and TechtreeManager.is_tech_unlocked("P1.2"):
		if randf() < 0.25: # 25% Chance für Konferenz
			_start_conference()

	# 2. Stadt-Events (P1.1) prüfen
	if not TechtreeManager or not TechtreeManager.is_tech_unlocked("P1.1"):
		_update_hud()
		return
		
	# Wenn ein Stadt-Event läuft, Tage reduzieren
	if active_event != EventType.NONE:
		if active_event == EventType.CONFERENCE:
			active_event = EventType.NONE # Fix für alte Spielstände
			event_days_remaining = 0
		else:
			event_days_remaining -= 1
			if event_days_remaining <= 0:
				end_event()
			else:
				_update_hud()
				return
		
	# Wenn kein Stadt-Event läuft, würfeln (z.B. 10% Chance pro Tag)
	if active_event == EventType.NONE and randf() < 0.10:
		start_random_event()
	else:
		_update_hud()

# =============================================================================
func _start_conference() -> void:
	var conference_rooms = []
	var hm = get_tree().current_scene.find_child("MapGrid", true, false) if get_tree().current_scene else null
	if hm == null:
		hm = get_tree().get_first_node_in_group("MapGrid")
	if hm:
		var all_rooms = hm.get_placed_rooms() if hm.has_method("get_placed_rooms") else (hm.active_rooms if "active_rooms" in hm else [])
		for room in all_rooms:
			if is_instance_valid(room):
				var r_id = room.get("room_type_id")
				if r_id != null and r_id.begins_with("conference_"):
					conference_rooms.append(room)

	if conference_rooms.size() == 0:
		return
		
	var num_events = randi_range(1, conference_rooms.size())
	conference_rooms.shuffle()
	
	for i in range(num_events):
		var room = conference_rooms[i]
		var cfg = _conference_configs.pick_random() if _conference_configs.size() > 0 else {"id": "default", "name": "Standard-Tagung", "max_participants": 12, "color": "#aaaaaa", "income_per_participant": 150}
		active_conferences[GuestManager._room_key(room)] = cfg
				
	_notify_event("Tageskonferenz!", "%d Tagung(en) heute im Haus!" % num_events)

# =============================================================================
func start_random_event() -> void:
	var roll = randf()
	if roll < 0.33:
		active_event = EventType.TRADE_FAIR
		event_days_remaining = 2
		_notify_event("Fachmesse in der Stadt!", "Viele Geschäftsreisende suchen heute Zimmer.")
	elif roll < 0.66:
		active_event = EventType.CONCERT
		event_days_remaining = 1
		_notify_event("Großes Konzert!", "Event-Gäste sind in der Stadt unterwegs.")
	else:
		active_event = EventType.HOLIDAY
		event_days_remaining = 2
		_notify_event("Feiertagswochenende!", "Mehr Familien machen Urlaub.")
		
	sig_event_started.emit(str(active_event), "Event")
	
	# HUD aktualisieren
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("update_state_visuals"):
		hud.update_state_visuals()

# =============================================================================
func end_event() -> void:
	active_event = EventType.NONE
	event_days_remaining = 0
	
	sig_event_ended.emit("none")
	_update_hud()

func _update_hud() -> void:
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("update_state_visuals"):
		hud.update_state_visuals()

# =============================================================================
func force_conference() -> bool:
	var conference_rooms = []
	# Finde das MapGrid, es ist ein Kind der Ingame-Szene (nicht zwingend in einer Gruppe)
	var hm = get_tree().current_scene.find_child("MapGrid", true, false) if get_tree().current_scene else null
	if hm == null:
		hm = get_tree().get_first_node_in_group("MapGrid")
	
	if hm:
		print("[EventManager] MapGrid gefunden!")
		var all_rooms = hm.get_placed_rooms() if hm.has_method("get_placed_rooms") else (hm.active_rooms if "active_rooms" in hm else [])
		print("[EventManager] Untersuche ", all_rooms.size(), " Räume...")
		var found_room_types = []
		for room in all_rooms:
			if is_instance_valid(room):
				var r_id = room.get("room_type_id")
				if r_id != null:
					found_room_types.append(r_id)
					if r_id.begins_with("conference_"):
						print("[EventManager] Konferenzraum identifiziert: ", room.name)
						conference_rooms.append(room)
		print("[EventManager] Gefundene Raum-Typen in der Liste: ", found_room_types)
	else:
		print("[EventManager] FEHLER: MapGrid wurde in der Gruppe 'MapGrid' nicht gefunden!")

	if conference_rooms.size() == 0:
		return false
		
	# Konferenzen berühren NICHT mehr active_event (welches für City-Events reserviert ist)
	
	active_conferences.clear()
	var num_events = randi_range(1, conference_rooms.size())
	conference_rooms.shuffle()
	
	for i in range(num_events):
		var room = conference_rooms[i]
		var cfg = _conference_configs.pick_random() if _conference_configs.size() > 0 else {"id": "default", "name": "Standard-Tagung", "max_participants": 12, "color": "#aaaaaa", "income_per_participant": 150}
		active_conferences[GuestManager._room_key(room)] = cfg
		
		var income = cfg.get("income_per_participant", 150) * min(cfg.get("max_participants", 12), room.call("get_definition").get("max_guests", 12))
		if FinanceManager:
			var translated_name = GameState.T("event.name." + cfg.get("id", "default"), cfg.get("name", "Event"))
			FinanceManager.add_transaction(income, "event", "Tagung gebucht: %s" % translated_name)
			if EffectManager and is_instance_valid(room):
				EffectManager.spawn_money_text(income, room.global_position + Vector2(0, -32))
			
	_notify_event("Tageskonferenz!", "%d Tagung(en) manuell gestartet!" % num_events)
	sig_event_started.emit(str(active_event), "Event")
	
	_update_hud()
		
	return true

# =============================================================================
func force_city_event() -> void:
	# Startet manuell eine Messe als Boost-Event
	active_event = EventType.TRADE_FAIR
	event_days_remaining = 1
	_notify_event("Fachmesse (Dev-Boost)!", "Viele Geschäftsreisende suchen heute Zimmer.")
	sig_event_started.emit(str(active_event), "Event")
	_update_hud()

# =============================================================================
func _notify_event(title: String, _desc: String) -> void:
	# Toast an UI senden
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(title)
		
	# Ins Activity Log eintragen
	if ActivityLog and TimeManager:
		ActivityLog.add("event", title, TimeManager.get_day(), TimeManager.get_game_time())

# =============================================================================
func is_event_active() -> bool:
	return active_event != EventType.NONE and active_event != EventType.CONFERENCE

func is_conference_active() -> bool:
	return active_conferences.size() > 0

func is_any_event_active() -> bool:
	return is_event_active() or is_conference_active()

func get_active_event() -> EventType:
	return active_event

# =============================================================================
func to_save_dict() -> Dictionary:
	return {
		"active_event": active_event,
		"event_days_remaining": event_days_remaining,
		"active_conferences": active_conferences,
		"is_inspector_coming_today": is_inspector_coming_today
	}

# =============================================================================
func load_from_dict(data: Dictionary) -> void:
	active_event = data.get("active_event", EventType.NONE)
	event_days_remaining = data.get("event_days_remaining", 0)
	active_conferences = data.get("active_conferences", {})
	is_inspector_coming_today = data.get("is_inspector_coming_today", false)
	
	if TimeManager and TimeManager.get_game_time() >= 1020:
		active_conferences.clear()
