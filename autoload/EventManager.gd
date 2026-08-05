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
	CONFERENCE  # Tages-Konferenz (P1.2)
}

var active_event: EventType = EventType.NONE
var event_days_remaining: int = 0

func _ready() -> void:
	TimeManager.sig_morning_struck.connect(_on_morning_struck)

# =============================================================================
func _on_morning_struck() -> void:
	if not TechtreeManager or not TechtreeManager.is_tech_unlocked("P1.1"):
		return
		
	# Wenn ein Event läuft, Tage reduzieren
	if active_event != EventType.NONE:
		event_days_remaining -= 1
		if event_days_remaining <= 0:
			end_event()
		return
		
	# Wenn kein Event läuft, würfeln (z.B. 10% Chance pro Tag)
	if randf() < 0.10:
		start_random_event()

# =============================================================================
func start_random_event() -> void:
	var can_conference = false
	if TechtreeManager and TechtreeManager.is_tech_unlocked("P1.2"):
		# Prüfen ob ein conference_small existiert
		var hm = get_tree().get_first_node_in_group("MapGrid")
		if hm and "active_rooms" in hm:
			for room in hm.active_rooms:
				if is_instance_valid(room) and room.has_method("get_definition"):
					if room.get_definition().get("id") == "conference_small":
						can_conference = true
						break

	var roll = randf()
	
	if can_conference and roll < 0.25: # 25% Chance für Konferenz, falls möglich
		active_event = EventType.CONFERENCE
		event_days_remaining = 1
		_notify_event("Tageskonferenz!", "Ein Bus mit Tagungsgästen ist angekommen.")
	elif roll < 0.40:
		active_event = EventType.TRADE_FAIR
		event_days_remaining = 2
		_notify_event("Fachmesse in der Stadt!", "Viele Geschäftsreisende suchen heute Zimmer.")
	elif roll < 0.70:
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
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("update_state_visuals"):
		hud.update_state_visuals()

# =============================================================================
func _notify_event(title: String, _desc: String) -> void:
	# Toast an UI senden
	var hud = get_tree().get_first_node_in_group("HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast(title)
		
	# Ins Activity Log eintragen (über Signal oder direkten Aufruf)
	GameState.sig_activity_logged.emit(title, "event")

# =============================================================================
func is_event_active() -> bool:
	return active_event != EventType.NONE

func get_active_event() -> EventType:
	return active_event
