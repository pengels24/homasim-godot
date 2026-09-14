extends Node2D
class_name GuestActor

const HUNGER_THRESHOLD: int = 55  # ANG-357: Erhöht von 40 → Gäste suchen früher Essen/Trinken

# --- Zustände ---

func get_state_name(s: int) -> String:
	var keys = State.keys()
	if s >= 0 and s < keys.size():
		return keys[s]
	return "UNKNOWN"


# =============================================================================
## Gibt eine lesbare Statusbeschreibung zurück (Single Source of Truth für UI).
## Neue States oder POI-Typen HIER eintragen – nie in UI-Klassen!
func get_status_text() -> String:
	match current_state:
		State.AWAITING_CHECKOUT:
			return GameState.T("guest.tooltip.reception")
		State.LEAVING:
			return GameState.T("guest.tooltip.leaving")
		State.WALKING:
			if _is_checkout_walk:
				return GameState.T("guest.tooltip.walking_reception")
			var base := GameState.T("guest.tooltip.walking_room").replace(" (Zimmer)", "")
			if is_instance_valid(_target_room) and _target_room.has_method("get_definition"):
				# Nur Raumnummer zeigen (kürzer) – kein Typ-Name nötig
				var rnum: String = str(_target_room.get("room_number") if _target_room.get("room_number") != null else "")
				if rnum != "" and rnum != "null" and not rnum.contains("_"):
					return "%s (%s)" % [base, rnum]
				# Fallback: Typ-Name ohne Koordinaten-Key
				var rname := GameState.T(_target_room.get_definition().get("name", ""))
				return "%s (%s)" % [base, rname] if rname != "" else base
			return base
		State.IN_POI, State.STUDYING_MENU, State.WAITING_FOR_FOOD, State.EATING, State.WAITING_IN_LINE:
			if _current_poi_id != "" and _map_grid:
				# Spezialfall: vending_machine ist kein eigener Raum (Teil der Lobby)
				if _current_poi_id == "vending_machine":
					return GameState.T("poi.vending_machine")
				var poi_name := _current_poi_id.capitalize()
				var def := _get_poi_def(_current_poi_id)
				if def.has("name"):
					poi_name = GameState.T(def.get("name"))
				var room_key := _get_poi_room_id(_current_poi_id)
				# Koordinaten-Fallback (enthält "_") nicht anzeigen
				if room_key != "" and room_key != "null" and not room_key.contains("_"):
					return "%s %s" % [poi_name, room_key]
				return poi_name
			return GameState.T("guest.tooltip.room")
		State.IN_ROOM, State.SITTING, State.SLEEPING:
			if is_instance_valid(_target_room) and _target_room.has_method("get_definition"):
				var rname := GameState.T(_target_room.get_definition().get("name", ""))
				var rnum: String = str(_target_room.get("room_number") if _target_room.get("room_number") != null else "")
				if rnum != "" and rnum != "null" and not rnum.contains("_"):
					return "%s %s" % [rname, rnum] if rname != "" else rnum
				return rname if rname != "" else GameState.T("guest.tooltip.room")
			return GameState.T("guest.tooltip.room")
		State.IDLE:
			return "-"
		_:
			return "-"

enum State { IDLE, WALKING, IN_ROOM, IN_POI, AWAITING_CHECKOUT, LEAVING, STUDYING_MENU, WAITING_FOR_FOOD, EATING, SITTING, SLEEPING, WAITING_IN_LINE }

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var _guest_member: GuestMember
var _map_grid: Node # MapGrid Referenz
var _guest_manager: GuestManager = null  # Referenz für Budget & POI-Tracking
var _target_room: Node2D = null

var _room_door_world: Vector2 = Vector2.INF

# TODO: In spätere Settings auslagern
const POI_WAIT_TIME_MINUTES: int = 3
const FOOD_WAIT_TIME_MINUTES: int = 90 # Erhöht von 45: Bei Speed 4x = 45 echte Sekunden – genug für Küche + Waiter
var _has_waited_for_functional: bool = false
var _waiting_for_food_timer: float = 0.0

## Verhindert, dass wake_up() den Checkout-Lauf überschreibt
var _is_checkout_walk: bool = false

## Welcher POI aktuell besucht wird (z.B. "lobby", "bar", "spa")
var _current_poi_id: String = ""
var _current_order_id: String = ""
var consumption_type: String = "food" # "food" or "drink"

# Interner Timer für Aufenthaltsdauer
var _action_timer: float = 0.0
var _impatient_timer: float = 0.0
var _base_speed: float = 40.0

var _active_tween: Tween
var _last_interaction_id: String = ""
var _has_claimed_seat: bool = false
## Nach Check-in: POI-Sperre fuer 60 Ingame-Minuten (Gast kommt erst an)
var _checkin_poi_block_until: int = 0
## ANG-361: Pflicht-Ruhepause nach POI-Besuch (in Spielminuten seit Mitternacht)
var _poi_rest_until: int = 0
## Speichert den Konferenzraum-Key waehrend der Mittagspause (event_poi_id wird temporaer geleert)
var _conference_break_poi_key: String = ""
## True wenn Gast gerade aus Konferenz-Pause zurueckkehrt (verhindert doppelte EXP)
var _is_returning_from_break: bool = false

signal sig_poi_income(amount: int, world_pos: Vector2)

@onready var avatar: Node2D = $GuestAvatar

# =============================================================================
func setup(member: GuestMember, map_grid: Node, start_room: Node2D = null, guest_manager: GuestManager = null) -> void:
	_guest_member = member
	_map_grid = map_grid
	_target_room = start_room
	_guest_manager = guest_manager
	
	name = "GuestActor_" + member.id
	add_to_group("guest_actors")
	avatar.setup(member)
	_base_speed = max(10.0, 40.0 + member.speed_offset)
	
	if GastroManager:
		if not GastroManager.sig_order_served.is_connected(_on_order_served):
			GastroManager.sig_order_served.connect(_on_order_served)
	
	var party = _get_my_party()
	if party and party.type == "vip":
		var vip_node = Sprite2D.new()
		vip_node.name = "VIPOverlay"
		vip_node.texture = preload("res://assets/icons/guests/user-star.svg")
		vip_node.modulate = Color(1.0, 0.84, 0.0)
		vip_node.scale = Vector2(0.6, 0.6)
		vip_node.position = Vector2(0, -32)
		vip_node.z_index = 50
		add_child(vip_node)
		
	if party and party.event_poi_id != "":
		var ev_badge = Sprite2D.new()
		ev_badge.name = "EventOverlay"
		ev_badge.texture = preload("res://assets/icons/angelus2010/ang-guest-conference.aseprite")
		
		var color = "#aaaaaa"
		if EventManager and EventManager.get("active_conferences") != null:
			# event_poi_id ist ein String, aber active_conferences nutzt int (instance_id)
			var conf_id = party.event_poi_id.to_int()
			if EventManager.active_conferences.has(conf_id):
				color = EventManager.active_conferences[conf_id].get("color", "#aaaaaa")
				
		ev_badge.modulate = Color(color)
		
		# Positionierung und Skalierung 100% identisch zum HungryIcon
		ev_badge.scale = Vector2(0.25, 0.25)
		ev_badge.position = Vector2(0, -4)
		ev_badge.z_index = 10  # Höherer z-index als HungryIcon (welches auf 0 ist)
		add_child(ev_badge)
	
	if start_room != null:
		_target_room = start_room
		var exit_tile = _get_room_exit_tile(start_room)
		var door_world = _map_grid.tile_to_world(exit_tile)
		_room_door_world = door_world  # sofort cachen!
		
		var is_night = false
		if TimeManager and (TimeManager.get_hour() >= 23 or TimeManager.get_hour() < 7):
			is_night = true
			
		if start_room.has_method("get_room_entry_pos"):
			global_position = start_room.get_room_entry_pos(_map_grid)
		else:
			global_position = door_world
			
		# Neu gespawnte (aus dem Savegame geladene) aktive Gste sollen 
		# im Zimmer auch anfangen zu wandern/schlafen, statt in IDLE zu hngen.
		_change_state(State.IN_ROOM)

		# Check-in POI-Sperre wird in start_checkin() gesetzt (nicht hier - setup laeuft auch beim Save-Load)
		
		# Wenn es Nacht ist, Timer auf fast Null setzen, damit sie direkt ins Bett laufen
		if is_night:
			_action_timer = 0.5
	else:
		_change_state(State.IDLE)
		
	TimeManager.sig_speed_changed.connect(_on_time_speed_changed)
	TimeManager.sig_morning_struck.connect(wake_up)
	
	if has_node("ClickArea"):
		var ca = get_node("ClickArea")
		ca.process_mode = Node.PROCESS_MODE_ALWAYS
		ca.z_index = 10 # Sicherstellen, dass Gäste über dem Raum-ClickArea liegen
		if not ca.input_event.is_connected(_on_click_area_input_event):
			ca.input_event.connect(_on_click_area_input_event)

# =============================================================================
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		GameState.sig_guest_clicked.emit(self)


# =============================================================================
func _process(delta: float) -> void:
	if has_node("VIPOverlay"):
		var vip_node = get_node("VIPOverlay")
		var t = Time.get_ticks_msec() / 1000.0
		var s = 0.6 + sin(t * 4.0) * 0.1
		vip_node.scale = Vector2(s, s)
		
	if has_node("EventOverlay"):
		var ev_node = get_node("EventOverlay")
		var t = Time.get_ticks_msec() / 1000.0
		# Nutze den Base-Scale von 0.25 und pulsiere sanft darum (z.B. +/- 0.02)
		var s = 0.25 + sin(t * 4.0) * 0.02
		ev_node.scale = Vector2(s, s)

	if has_node("HungryIcon"):
		if avatar.visible and _guest_member.saturation <= 40:
			$HungryIcon.visible = true
		else:
			$HungryIcon.visible = false

	match current_state:
		State.IN_ROOM, State.IN_POI, State.STUDYING_MENU, State.EATING, State.IDLE, State.SITTING, State.SLEEPING:
			_process_waiting(delta)
		State.WAITING_FOR_FOOD, State.AWAITING_CHECKOUT, State.WAITING_IN_LINE:
			_process_impatient(delta)



# =============================================================================
func _process_impatient(delta: float) -> void:
	if TimeManager and TimeManager.is_paused():
		return
		
	var speed = TimeManager.user_speed if TimeManager else 1.0
	_impatient_timer += delta * speed
	
	if current_state == State.WAITING_FOR_FOOD:
		_waiting_for_food_timer += delta * speed
		# Wenn das Limit erreicht ist, bricht der Gast wütend ab
		var wait_limit_seconds = FOOD_WAIT_TIME_MINUTES * (TimeManager.SECONDS_PER_GAME_MINUTE if TimeManager else 1.0)
		if _waiting_for_food_timer >= wait_limit_seconds:
			print("[GuestActor] %s: Timeout erreicht beim Warten auf Essen! Breche ab." % [(_guest_member.name if _guest_member else "?")])
			var party = _get_my_party()
			if party:
				party.modify_satisfaction(-15) # Starke Strafe
			
			# Raum aufräumen / Order canceln
			var poi_room_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(poi_room_node):
				if poi_room_node.has_method("release_interaction"):
					poi_room_node.release_interaction(_guest_member.id)
				if poi_room_node.has_method("leave_seat"):
					poi_room_node.leave_seat(_guest_member.id)
			
			_decide_next_action()
			return
			
	if _impatient_timer >= 60.0: # Alle 60 Ingame-Sekunden
		_impatient_timer = 0.0
		var party = _get_my_party()
		if party:
			party.modify_satisfaction(-2)


# =============================================================================
func _process_waiting(delta: float) -> void:
	if _action_timer <= 0.0:
		return # Gast ruht – kein Timer-Countdown

	# Hinweis: Kein aktiver "Rauswurf" wenn POI schließt - close kommt erst zum open_to.
	# Wer bereits sitzt/isst bleibt bis sein Timer ablaeuft (wie im echten Leben).
	# Neue Eintritte werden bereits in _decide_next_action() via _is_current_poi_open() blockiert.

	var speed = 1.0
	var current_time = 0
	if TimeManager:
		if TimeManager.is_paused():
			return # NEU: Nicht ticken, wenn pausiert!
		speed = TimeManager.user_speed
		current_time = TimeManager.get_game_time()
		
	var party = _get_my_party()
	if party and party.event_poi_id != "":
		# 07:45 (465) bis 12:00 (720) UND 13:50 (830) bis 17:00 (1020)
		var is_event_time = (current_time >= 465 and current_time < 720) or (current_time >= 830 and current_time < 1020)
		
		# Den konkreten Event-Raum explizit über die Party-ID ermitteln!
		var event_room_node = null
		if is_instance_valid(_guest_manager):
			event_room_node = _guest_manager._get_room_node(party.event_poi_id)
			
		var is_in_event_room := false
		if is_instance_valid(event_room_node):
			var def = event_room_node.call("get_definition")
			if def.get("id", "") == _current_poi_id:
				is_in_event_room = true
		
		if is_event_time and not is_in_event_room and current_state != State.WALKING:
			# Force go to event
			if current_state == State.EATING or current_state == State.IN_POI:
				var room_n = event_room_node if is_instance_valid(event_room_node) else _get_poi_room_node(_current_poi_id)
				if is_instance_valid(room_n) and room_n.has_method("release_interaction"): room_n.release_interaction(_guest_member.id)
			_action_timer = 0
			_decide_next_action()
			return
		elif not is_event_time and is_in_event_room and current_state != State.WALKING and current_time < 1020:
			# Pause! Verlasse Konferenz.
			var room_n = event_room_node if is_instance_valid(event_room_node) else _get_poi_room_node(_current_poi_id)
			if is_instance_valid(room_n) and room_n.has_method("release_interaction"): room_n.release_interaction(_guest_member.id)
			_action_timer = 0
			_decide_next_action()
			return
		elif current_time >= 1020 and current_state != State.LEAVING and current_state != State.WALKING:
			# Feierabend -> Gehen
			var room_n = event_room_node if is_instance_valid(event_room_node) else _get_poi_room_node(_current_poi_id)
			if is_instance_valid(room_n) and room_n.has_method("release_interaction"): room_n.release_interaction(_guest_member.id)
			_change_state(State.LEAVING)
			_walk_to_exit()
			return
		
	_action_timer -= delta * speed
	if _action_timer <= 0.0:
		if current_state == State.EATING:
			# Aufstehen: Tisch freigeben
			var poi_room_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(poi_room_node):
				if poi_room_node.has_method("release_interaction"):
					poi_room_node.release_interaction(_guest_member.id)
				if poi_room_node.has_method("leave_seat"):
					poi_room_node.leave_seat(_guest_member.id)
			
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				_decide_next_action()
			return # WICHTIG: Verhindert Fallthrough zu _decide_next_action() am Ende des Blocks
		
		elif current_state == State.STUDYING_MENU:
			# GastroManager übernimmt die gesamte Bestell-Logik – kein room-ID Check mehr nötig
			var room_node = _get_poi_room_node(_current_poi_id)
			
			if not is_instance_valid(room_node):
				print("[GuestActor ERROR] room_node ist ungültig in STUDYING_MENU!")
				_decide_next_action()
				return
			
			# Einmalige Wartezeit falls Raum noch nicht funktional ist
			if room_node.has_method("is_functional") and not room_node.is_functional():
				if not _has_waited_for_functional:
					print("[GuestActor] %s: Raum nicht funktional. Warte %s Minuten." % [(_guest_member.name if _guest_member else "?"), POI_WAIT_TIME_MINUTES])
					_has_waited_for_functional = true
					_action_timer = POI_WAIT_TIME_MINUTES * (TimeManager.SECONDS_PER_GAME_MINUTE if TimeManager else 5.0)
					return
			
			_has_waited_for_functional = false
			
			# GastroManager versucht die Bestellung – er kennt is_functional und can_serve_solo
			var gastro_result = GastroManager.try_gastro_order(
				_guest_member.id, _guest_member.spending_budget, _guest_member.saturation, room_node
			)
			
			if gastro_result.get("ordered", false):
				_change_state(State.WAITING_FOR_FOOD)
			elif gastro_result.get("solo_mode", false):
				# Kein Kellner, aber Barkeeper ist da -> Solo-Drink direkt
				consumption_type = "drink"
				_change_state(State.EATING)
			else:
				# Kein Personal → Platz freigeben und abbrechen
				if room_node.has_method("release_interaction"):
					room_node.release_interaction(_guest_member.id)
				if room_node.has_method("leave_seat"):
					room_node.leave_seat(_guest_member.id)
				_decide_next_action()
			return # WICHTIG: Verhindert Fallthrough zu _decide_next_action() am Ende des Blocks
		
		elif current_state in [State.IN_POI, State.SITTING]:
			var current_hour = 12
			if TimeManager:
				current_hour = TimeManager.get_hour()
			if current_hour >= 23 or current_hour < 6:
				_decide_next_action()
				return

			# Event-Raum Lookup (Tagungsgäste haben eine eigene room-node via party.event_poi_id)
			var room_node = null
			if is_instance_valid(party) and party.event_poi_id != "" and is_instance_valid(_guest_manager):
				var ev_node = _guest_manager._get_room_node(party.event_poi_id)
				if is_instance_valid(ev_node):
					var def = ev_node.call("get_definition")
					if def.get("id", "") == _current_poi_id:
						room_node = ev_node
			
			if not is_instance_valid(room_node):
				room_node = _get_poi_room_node(_current_poi_id)
				
			if is_instance_valid(room_node):
				# SMART ROOM: Gibt es verfügbare Interaktionen?
				var interactions = []
				if room_node.has_method("get_available_interactions"):
					interactions = room_node.get_available_interactions(self)
					
				if interactions.size() > 0:
					var choice = interactions.pick_random()
					if room_node.has_method("release_interaction"):
						room_node.release_interaction(_guest_member.id)
					if room_node.has_method("claim_interaction"):
						var claim_result = room_node.claim_interaction(_guest_member.id, choice.get("id", ""))
						if claim_result.has("target_pos"):
							_execute_poi_move(claim_result.target_pos, room_node)
							var dur = claim_result.get("duration", randf_range(15.0, 30.0))
							_action_timer = dur * TimeManager.SECONDS_PER_GAME_MINUTE
							return
				
				# Keine Interaktionen verfügbar: Platz freigeben
				if _has_claimed_seat and room_node.has_method("release_interaction"):
					room_node.release_interaction(_guest_member.id)
					_has_claimed_seat = false
		
		_decide_next_action()

func _execute_poi_move(target_pos: Vector2, room_node: Node) -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
	_active_tween = create_tween()
	var speed_scale = TimeManager.user_speed if TimeManager and not TimeManager.is_paused() else 1.0
	_active_tween.set_speed_scale(speed_scale)
	_active_tween.tween_interval(0.01) # Verhindert "started with no Tweeners" Error
	
	var local_path = []
	if room_node.has_method("get_local_path"):
		local_path = room_node.get_local_path(global_position, target_pos)
	if local_path.is_empty():
		local_path.append(target_pos)
	
	var curr_pos = global_position
	for p in local_path:
		var dur = curr_pos.distance_to(p) / _base_speed
		if dur > 0.0:
			_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(p))
			_active_tween.tween_property(self, "global_position", p, dur)
		curr_pos = p
		
	# Gastro-Räume wechseln nach Ankunft in STUDYING_MENU (Raum sagt das selbst via is_gastro())
	if is_instance_valid(room_node) and room_node.has_method("is_gastro") and room_node.is_gastro():
		_active_tween.tween_callback(func(): _change_state(State.STUDYING_MENU))

# =============================================================================

# =============================================================================
func _get_current_room_node(state: int = -1) -> Node2D:
	if not _current_poi_id.is_empty():
		if _current_poi_id == "lobby":
			return _get_lobby_room()
		return _get_poi_room_node(_current_poi_id)
		
	var check_state = current_state if state == -1 else state
	if check_state == State.IN_ROOM or check_state == State.SITTING or check_state == State.SLEEPING:
		return _target_room
		
	return null

func _get_open_pois() -> Array[String]:
	## Gibt alle POI-Typen zurück, die aktuell geöffnet haben.
	## Nutzt open_from / open_to aus der Raumdefinition (Minuten seit Mitternacht).
	var open_pois: Array[String] = []
	
	var all_rooms: Array = _map_grid.active_rooms.duplicate()
	var entry_parcel = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	if entry_parcel and entry_parcel.has_method("get_lobby"):
		var lobby = entry_parcel.get_lobby()
		if is_instance_valid(lobby):
			all_rooms.append(lobby)
	
	for room in all_rooms:
		if not is_instance_valid(room): continue
		var def = room.call("get_definition")
		if not def.get("is_poi", false): continue
		if not def.get("is_guest_poi", true): continue
		
		var room_id: String = def.get("id", "")
		
		# Event-Gast POI Einschränkungen
		var party = _get_my_party()
		var is_event_guest = false
		if party and party.event_poi_id != "":
			is_event_guest = true
		elif _conference_break_poi_key != "":
			is_event_guest = true
		elif party and party.total_stay_days == 0:
			is_event_guest = true
			
		if is_event_guest:
			# Event-Gäste dürfen nur Gastro-Räume und Lobby besuchen
			var is_gastro_room = room.has_method("is_gastro") and room.is_gastro()
			var is_lobby_room = room_id == "lobby"
			if not is_gastro_room and not is_lobby_room:
				continue
				
		# SMART ROOM: Der Raum entscheidet selbst, ob der Gast rein darf!
		if room.has_method("is_guest_allowed") and not room.is_guest_allowed(self):
			continue
		
		# Gasttyp-Filter: allowed_guest_types aus Raumdefinition
		var allowed_types: Array = def.get("allowed_guest_types", [])
		if not allowed_types.is_empty():
			var my_party = _get_my_party()
			var party_type: String = my_party.type if is_instance_valid(my_party) else ""
			if not allowed_types.has(party_type):
				continue

		
		var cost = def.get("visit_income", 0)
		# Gastro-Räume: Mindestbudget 5€ und Hunger-Prüfung
		if room.has_method("is_gastro") and room.is_gastro():
			cost = max(cost, 5)
			if _guest_member.saturation > 50:
				continue
			
		if _guest_member.spending_budget < cost:
			continue
		
		# Öffnungszeiten prüfen (mit 30 Minuten Bestell-Stopp vor Schließung)
		if not GameState.is_facility_open(def, 30):
			continue
		
		# Physischer Check: Ist das benötigte Personal auch wirklich im Raum?
		if room.has_method("is_operational"):
			if not room.is_operational():
				continue
			
		# Max Guests Check
		var max_guests = def.get("max_guests", 0)
		if max_guests > 0:
			var current_count = 0
			for guest in get_tree().get_nodes_in_group("guest_actors"):
				if guest._current_poi_id == room_id:
					current_count += 1
			if current_count >= max_guests:
				continue
			
		if not open_pois.has(room_id):
			open_pois.append(room_id)
			
	# Vending Machine in Lobby (Level 2+)
	if GameState.get_level() >= 2:
		var can_afford = _guest_member.spending_budget >= 5
		var is_hungry = false
		var lobby = _get_lobby_room()
		if is_instance_valid(lobby) and "VENDING_MACHINE_HUNGER_THRESHOLD" in lobby:
			is_hungry = _guest_member.saturation < lobby.VENDING_MACHINE_HUNGER_THRESHOLD
		else:
			is_hungry = _guest_member.saturation < HUNGER_THRESHOLD
			
		if (is_hungry and can_afford) or _current_poi_id == "vending_machine":
			open_pois.append("vending_machine")
	
	return open_pois


# =============================================================================
func _is_current_poi_open() -> bool:
	if _current_poi_id == "":
		return true # Im Zimmer oder sonst wo, gilt als immer offen
		
	var def = _get_poi_def(_current_poi_id)
	if not GameState.is_facility_open(def, 30):
		return false
		
	var room_node = _get_poi_room_node(_current_poi_id)
	if is_instance_valid(room_node):
		if room_node.has_method("is_open") and not room_node.is_open():
			return false
			
	return true


# =============================================================================
func _decide_next_action() -> void:
	if current_state == State.LEAVING:
		return
		
	var party = _get_my_party()
		
	var open_pois := _get_open_pois()
	
	# Check-in Sperre: 60 Min nach Ankunft keine POIs
	if _checkin_poi_block_until > 0:
		var now := TimeManager.get_game_time() if TimeManager else 0
		if now < _checkin_poi_block_until:
			open_pois.clear() # Erzwingt Zimmer-Aufenthalt
		else:
			_checkin_poi_block_until = 0 # Einmalig zuruecksetzen
	
	# ANG-361: Pflicht-Ruhepause nach POI-Besuch (ueberspringen bei Hunger)
	if _poi_rest_until > 0:
		var now_r := TimeManager.get_game_time() if TimeManager else 0
		if now_r < _poi_rest_until:
			var is_hungry_now := _guest_member != null and _guest_member.saturation < HUNGER_THRESHOLD
			if not is_hungry_now:
				open_pois.clear()  # Erzwingt Zimmer-Aufenthalt
		else:
			_poi_rest_until = 0  # Pause abgelaufen
	
	# 2. Nachtruhe-Logik (22:00 - 06:00): 
	# Die Lobby ist nachts als reiner "Zeitvertreib" tabu, um Endlos-Pendeln zu verhindern.
	# Echte POIs wie die Bar (die bis 23:30 auf hat) bleiben aber erlaubt!
	var current_hour = 12
	if TimeManager:
		current_hour = TimeManager.get_hour()
		
	if current_hour >= 23 or current_hour < 6:
		# Nachtruhe! Ab ins Zimmer und schlafen.
		open_pois.clear()
		if current_state == State.SLEEPING:
			_action_timer = randf_range(30.0, 60.0)
			return
		elif current_state == State.IN_ROOM or current_state == State.SITTING:
			if is_instance_valid(_target_room):
				_wander_in_room(_target_room, true) # true = force sleep
			return
		else:
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				_change_state(State.LEAVING)
				_walk_to_exit()
			return
	
	# Kein offener POI? Gast wartet etwas und probiert es später wieder
	# ANG-357: Wenn kein POI verfügbar (z.B. spending_budget leer), Gast ins Zimmer schicken
	if open_pois.is_empty():
		if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING:
			_wander_in_room(_target_room)
			return
		elif current_state != State.WALKING and current_state != State.IDLE:
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				party = _get_my_party()
				if is_instance_valid(party) and party.event_poi_id != "":
					_walk_to_poi("lobby")
				else:
					_change_state(State.LEAVING)
					_walk_to_exit()
			return
		else:
			# IDLE oder WALKING außerhalb des Zimmers → zurück ins Zimmer statt endlos warten
			party = _get_my_party()
			if is_instance_valid(party) and party.event_poi_id != "":
				_action_timer = randf_range(5.0, 10.0)
			elif is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				_action_timer = randf_range(15.0, 45.0)
			return
	
	# Mögliche Ziele: Zimmer (falls vorhanden) + alle offenen POIs
	var possible_targets: Array[String] = []
	if is_instance_valid(_target_room):
		possible_targets.append("room")
	else:
		# TG-Gast ohne Zimmer: nur zum Checkout wenn Tagung wirklich beendet (event_poi_id leer)
		var _p_tg = _get_my_party()
		if is_instance_valid(_p_tg) and _p_tg.event_poi_id == "":
			# Tagung vorbei → direkt zum Checkout, nicht in Lobby-Wander-Loop
			start_checkout()
			return
		else:
			# Tagung läuft noch (oder kein Party-Objekt) → Lobby als Wartepunkt
			possible_targets.append("lobby")
		
	possible_targets.append_array(open_pois)
		
	# POI-Gewichtung: 70% preferred (laut Gasttyp), 30% freie Wahl
	var chosen: String = possible_targets.pick_random()
	var party_for_type = _get_my_party()
	if is_instance_valid(party_for_type) and randf() < 0.7:
		var type_def = party_for_type.get_type_def()
		var preferred: Array = type_def.get("preferred_pois", [])
		# Nur preferred POIs die aktuell offen sind
		var preferred_open: Array[String] = []
		for pref_id in preferred:
			if open_pois.has(pref_id):
				preferred_open.append(pref_id)
		if not preferred_open.is_empty():
			chosen = preferred_open.pick_random()

	
	# Event-Gast Priorität: Wenn es Event-Zeit ist, GEH ZUM EVENT!
	party = _get_my_party()
	if is_instance_valid(party) and party.event_poi_id != "":
		var t = TimeManager.get_game_time() if TimeManager else 0
		var is_event_time = (t >= 465 and t < 720) or (t >= 825 and t < 1020)
		if is_event_time:
			# Prüfen ob der Event-Raum bereits geöffnet hat
			var event_room_node = null
			for room in _map_grid.active_rooms:
				if not is_instance_valid(room): continue
				if is_instance_valid(_guest_manager) and GuestManager._room_key(room) == party.event_poi_id:
					event_room_node = room
					break
			
			var event_room_open = true
			if is_instance_valid(event_room_node) and event_room_node.has_method("is_open"):
				event_room_open = event_room_node.is_open()
			
			if event_room_open:
				chosen = party.event_poi_id
			else:
				# Raum noch geschlossen: Zum Eingang laufen und kurz warten
				if current_state != State.WALKING and current_state != State.IDLE:
					if is_instance_valid(event_room_node):
						# Gehe zur Außentür und warte dort
						var outside_tile = event_room_node.get_target_tile(_map_grid)
						var outside_world = _map_grid.tile_to_world(outside_tile)
						var start_tile = _get_logical_start_tile()
						var path_tiles: Array[Vector2i] = _map_grid.get_path_between_tiles(start_tile, outside_tile, (_guest_member.name if _guest_member else "?"))
						if not path_tiles.is_empty() or start_tile == outside_tile:
							_change_state(State.WALKING)
							_execute_walk(path_tiles, State.IDLE, outside_world)
							_action_timer = 30.0 # Kurz warten dann nochmal prüfen
							return
				_action_timer = 20.0 # Warte und prüfe erneut
				return
	
	# ANG-310: Hunger-Priorisierung! (nur wenn wir nicht gerade zwingend zum Event müssen)
	var ev_id = party.event_poi_id if is_instance_valid(party) else ""
	if chosen != ev_id and _guest_member.saturation < HUNGER_THRESHOLD:
		var food_pois = []
		if open_pois.has("vending_machine"): food_pois.append("vending_machine")
		if open_pois.has("restaurant_small"): food_pois.append("restaurant_small")
		if open_pois.has("bar"): food_pois.append("bar")
		
		# Zu 80% Wahrscheinlichkeit einen Essens-POI erzwingen, falls verfügbar
		if food_pois.size() > 0 and randf() > 0.2:
			chosen = food_pois.pick_random()
			
	# print("[DEBUG] Gast ", _guest_member.id if _guest_member else "?", " _decide_next_action -> chosen: ", chosen, " | current_poi: ", _current_poi_id, " | state: ", current_state)
	
	# Vermeide, dass der Gast ans selbe Ziel geht wie er schon ist
	if chosen == "room" and (current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING):
		if not open_pois.is_empty() and randf() > 0.3:
			chosen = open_pois.pick_random()
		else:
			_wander_in_room(_target_room)
			return
	elif (current_state == State.IN_POI or current_state == State.EATING or current_state == State.STUDYING_MENU or current_state == State.WAITING_FOR_FOOD) and chosen == _current_poi_id:
		party = _get_my_party()
		if is_instance_valid(party) and party.event_poi_id != "":
			if party.event_poi_id == _current_poi_id:
				pass # Wir bleiben beim Event!
			else:
				chosen = party.event_poi_id
		else:
			if not open_pois.is_empty() and randf() > 0.3:
				var other_pois = open_pois.duplicate()
				other_pois.erase(_current_poi_id)
				if not other_pois.is_empty():
					chosen = other_pois.pick_random()
				else:
					var lobby = _get_lobby_room()
					if is_instance_valid(lobby) and chosen == "lobby":
						_wander_in_room(lobby)
					else:
						_walk_to_poi("lobby")
					return
			else:
				chosen = "room"
	
	if chosen == "room":
		# ANG-361: Ruhepause setzen wenn Gast einen bezahlten POI verlaesst
		if _poi_rest_until == 0:
			var _leaving_paid_poi := current_state in [State.IN_POI, State.EATING, State.STUDYING_MENU, State.WAITING_FOR_FOOD]
			if _leaving_paid_poi and _current_poi_id not in ["", "lobby", "vending_machine"]:
				var now_r := TimeManager.get_game_time() if TimeManager else 0
				_poi_rest_until = now_r + randi_range(30, 60)  # 30-60 Ingame-Minuten Pause
		if is_instance_valid(_target_room):
			_walk_to_room(_target_room, State.IN_ROOM)
		else:
			party = _get_my_party()
			if is_instance_valid(party) and party.event_poi_id != "":
				var t = TimeManager.get_game_time() if TimeManager else 0
				if t >= 1020:
					_change_state(State.LEAVING)
					_walk_to_exit()
				else:
					_walk_to_poi("lobby")
			else:
				_change_state(State.LEAVING)
				_walk_to_exit()
	else:
		_walk_to_poi(chosen)


# =============================================================================
## Gast ruht – Timer wird gestoppt. Kein unnötiges Polling in der Nacht.
func rest() -> void:
	_action_timer = 0.0


# =============================================================================
## Gast wacht auf (morgens 06:00 via sig_morning_struck). Timer startet neu.
func wake_up() -> void:
	# Engine-Pause um 24:00 kann laufende Tweens einfrieren.
	# Wenn der Gast noch "unterwegs" ist → sofort ins Zimmer teleportieren.
	if current_state == State.WALKING and not _is_checkout_walk:
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		if _room_door_world != Vector2.INF:
			global_position = _room_door_world
		_change_state(State.IN_ROOM)
		# Timer wird beim nächsten Frame neu gesetzt (Gast schläft bis POI öffnet)
		_action_timer = randf_range(5.0, 30.0)
		return
	
	if current_state == State.LEAVING or current_state == State.WAITING_IN_LINE:
		return
	_poi_rest_until = 0  # ANG-361: Ruhepause nach Nacht zurücksetzen
	_action_timer = randf_range(5.0, 30.0)


# =============================================================================
func _on_walk_finished(new_state: int) -> void:
	if is_instance_valid(_map_grid) and _map_grid.has_method("clear_debug_path"):
		_map_grid.clear_debug_path(str(_guest_member.get("name")) if _guest_member else "?")
	_change_state(new_state)


# =============================================================================
func _change_state(new_state: State) -> void:
	var old_state = current_state
	previous_state = old_state
	
	var g_name = _guest_member.get("name") if _guest_member else "Unknown"
	var poi_info = (" [" + _current_poi_id + "]") if new_state == State.IN_POI and not _current_poi_id.is_empty() else ""
	print("[GuestActor] %s changed state: %s -> %s%s" % [g_name, get_state_name(old_state), get_state_name(new_state), poi_info])
	
	
	_has_waited_for_functional = false
	if new_state == State.WAITING_FOR_FOOD:
		_waiting_for_food_timer = 0.0
	
	if old_state == State.SITTING or old_state == State.SLEEPING:
		if is_instance_valid(_target_room):
			if _target_room.has_method("release_interaction"):
				_target_room.release_interaction(_guest_member.id)
			else:
				# Legacy Fallbacks
				if old_state == State.SITTING and _target_room.has_method("room_leave_seat"):
					_target_room.room_leave_seat(_guest_member.id)
				elif old_state == State.SLEEPING and _target_room.has_method("room_leave_bed"):
					_target_room.room_leave_bed(_guest_member.id)
		# Reset avatar visualization if needed
		avatar.rotation = 0
		
	if new_state == State.IDLE or new_state == State.WALKING:
		pass
	elif new_state != State.IN_POI:
		_has_claimed_seat = false
		
	current_state = new_state
	
	# Türsounds werden nun framegenau über _execute_walk getriggert, nicht mehr hier pauschal beim State-Wechsel
	
	# POI-Ankunft: Einnahmen & Boost verarbeiten
	# Wichtig: _on_poi_arrived() kann current_state ändern (z.B. IN_POI -> STUDYING_MENU für Gastro-Räume).
	# Der match-Block danach darf dann NUR den neuen State setzen, NICHT den alten (IN_POI) nochmal verarbeiten.
	var _state_after_poi_arrived := new_state
	if new_state == State.IN_POI:
		_on_poi_arrived()
		_state_after_poi_arrived = current_state # Ggf. geändert von _on_poi_arrived()
	
	# match läuft nur wenn der State nach _on_poi_arrived noch dem erwarteten entspricht
	if _state_after_poi_arrived != new_state:
		return # _on_poi_arrived hat den State bereits vollständig gesetzt
	
	match current_state:
		State.IN_ROOM:
			_action_timer = 0.5 # Immediately wander or sleep upon arriving
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.IN_POI:
			# Aufenthaltsdauer kommt jetzt via duration aus claim_interaction – kein _poi_stay_timer mehr.
			# action_timer = 0.01 triggert sofort den ersten get_available_interactions/claim Zyklus.
			_action_timer = 0.01
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.AWAITING_CHECKOUT:
			# Sichtbar in der Lobby am Checkout warten
			_action_timer = 0.0
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = false
			# TG-Gäste haben kein Zimmer → auto-checkout ohne Spieler-Klick
			if _target_room == null:
				call_deferred("_auto_checkout_tg_guest")
		State.STUDYING_MENU:
			_action_timer = randf_range(5.0, 10.0)
			print("[GuestActor] %s betritt STUDYING_MENU. Wartet %s Sekunden..." % [(_guest_member.name if _guest_member else "?"), _action_timer])
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.WAITING_FOR_FOOD:
			_action_timer = 0.0 # Warten auf Signal
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.EATING:
			_action_timer = 15.0 # Gast isst für 15 Sekunden
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.WALKING, State.LEAVING:
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true


func _on_order_served(_order_id: String, guest_id: String, recipe_id: String) -> void:
	if guest_id != _guest_member.id:
		return
	if current_state == State.WAITING_FOR_FOOD:
		_current_order_id = ""
		
		# Preis des Gerichts ermitteln
		var price = 0
		var r_name = "Essen"
		var sat = 0
		for r in GameState.recipes:
			if r.get("id") == recipe_id:
				price = r.get("price", 0)
				sat = r.get("saturation", 0)
				r_name = GameState.T(r.get("name_key", ""))
				consumption_type = r.get("type", "food")
				break
		
		# Bezahlen via FinanceManager
		if price > 0:
			_guest_member.spending_budget = max(0, _guest_member.spending_budget - price)
			FinanceManager.add_transaction(price, "gastro", "tx.poi_income|" + _guest_member.name + "|" + r_name)
			if EffectManager: EffectManager.spawn_money_text(price, global_position + Vector2(0, -48))
		
		# Gast gibt EXP wenn er isst (+10)
		if EffectManager: EffectManager.spawn_exp_text(10, global_position + Vector2(0, -32))
		GameState.add_exp(10)
		
		# Sättigung wiederherstellen
		_guest_member.saturation = min(100, _guest_member.saturation + sat)
		
		var party = _get_my_party()
		if TechtreeManager and TechtreeManager.is_tech_unlocked("G1.4") and party:
			party.satisfaction = min(100, party.satisfaction + 5)
		
		# Essen-Status aktivieren
		_change_state(State.EATING)

# =============================================================================
## Verarbeitet die Ankunft in einem POI: Einnahmen buchen, Budget abziehen, Zufriedenheit boosten.
func _on_poi_arrived() -> void:
	if _current_poi_id.is_empty() or _current_poi_id == "lobby":
		return
		
	# Snack-Automat Logik
	if _current_poi_id == "vending_machine":
		var lobby = _get_lobby_room()
		if is_instance_valid(lobby) and lobby.has_method("buy_snack"):
			var snack_result = lobby.buy_snack(_guest_member.spending_budget)
			if snack_result:
				_guest_member.spending_budget = max(0, _guest_member.spending_budget - lobby.VENDING_MACHINE_PRICE)
				var actual_sat = lobby.VENDING_MACHINE_SATURATION + randi_range(-5, 10) # Bricht die Sättigungs-Zyklen auf
				_guest_member.saturation = min(100, _guest_member.saturation + actual_sat)
				
				FinanceManager.add_transaction(lobby.VENDING_MACHINE_PRICE, "gastro", "tx.poi_income|" + _guest_member.name + "|Snack-Automat")
				if EffectManager: EffectManager.spawn_money_text(lobby.VENDING_MACHINE_PRICE, global_position + Vector2(0, -48))
				if EffectManager: EffectManager.spawn_exp_text(lobby.VENDING_MACHINE_EXP, global_position + Vector2(0, -32))
				
				# Gast navigiert (per Lobby-Pfad, damit er um Möbel herumläuft) zum Essplatz
				var target_pos = lobby.get_snack_eating_target_world()
				_change_state(State.WALKING)
				# Direkter Tween mit lobby.get_local_path (umgeht den is_nearby-Check in _execute_walk)
				if _active_tween and _active_tween.is_valid():
					_active_tween.kill()
				_active_tween = create_tween()
				var speed_scale = TimeManager.user_speed if TimeManager and not TimeManager.is_paused() else 1.0
				_active_tween.set_speed_scale(speed_scale)
				_active_tween.tween_interval(0.01)
				# Pfad berechnen damit Navblocker respektiert werden
				var g_name = _guest_member.id if _guest_member else "Unknown"
				var nav_path: Array = []
				if lobby.has_method("get_local_path"):
					nav_path = lobby.get_local_path(global_position, target_pos, g_name)
				if nav_path.is_empty():
					nav_path = [target_pos]
				var curr = global_position
				for pt in nav_path:
					var d = curr.distance_to(pt)
					if d > 1.0:
						_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(pt))
						_active_tween.tween_property(self, "global_position", pt, max(d / _base_speed, 0.05))
					curr = pt
				_active_tween.tween_callback(func(): _change_state(State.EATING))
				return
		
		# Falls Automat nicht klappt
		_action_timer = randf_range(5.0, 15.0)
		return
	
	var poi_def = _get_poi_def(_current_poi_id)
	var income: int = poi_def.get("visit_income", 0)
	
	# Tagungsgäste zahlen KEINEN visit_income – sie haben bereits über das Event-Budget bezahlt
	var my_party := _get_my_party()
	if is_instance_valid(my_party) and my_party.get("event_poi_id") != "":
		income = 0
	
	var room_node = _get_poi_room_node(_current_poi_id)
	
	# Gastro-Räume: visit_income entfällt wenn Waiter vorhanden (Einnahmen laufen via Bestellung)
	if is_instance_valid(room_node) and room_node.has_method("is_gastro") and room_node.is_gastro():
		if room_node.has_method("_has_waiter_assigned") and room_node.call("_has_waiter_assigned"):
			income = 0
	
	# Sitzplatz claimen (alle Raeume sind Smart Rooms)
	var seat_pos = Vector2.ZERO
	# was_fresh_claim = echter Erstbesuch ODER Pause-Rueckkehr ist KEIN Erstbesuch
	var was_fresh_claim := not _is_returning_from_break
	_is_returning_from_break = false  # Immer zuruecksetzen nach Verarbeitung
	if is_instance_valid(room_node) and room_node.has_method("get_available_interactions") and room_node.has_method("claim_interaction"):
		if not _has_claimed_seat:
			var avail = room_node.get_available_interactions(self)
			if avail.size() > 0:
				var choice = avail.pick_random()
				var claim_result = room_node.claim_interaction(_guest_member.id, choice.get("id", ""))
				if claim_result.has("target_pos"):
					seat_pos = claim_result.target_pos
					_has_claimed_seat = true
					was_fresh_claim = true
					# Timer aus claim_result setzen damit Gast NICHT sofort weiterwechselt
					var dur = claim_result.get("duration", randf_range(15.0, 30.0))
					_action_timer = dur * (TimeManager.SECONDS_PER_GAME_MINUTE if TimeManager else 4.0)
		else:
			seat_pos = global_position # bereits geclaimed, dummy um Abbruch zu verhindern
	
	if not _has_claimed_seat and (seat_pos == Vector2.ZERO or seat_pos == Vector2.INF):
		print("[GuestActor] %s bricht Besuch in %s ab: kein Platz verfügbar." % [_guest_member.name, _current_poi_id])
		send_back_to_room()
		return
	
	var party := _get_my_party()
	
	if is_instance_valid(party):
		var bonus = 0
		if income > 0:
			bonus += 2
			
		if is_instance_valid(room_node) and room_node.has_method("has_trait"):
			if room_node.has_trait("wlan"): bonus += 1
			if room_node.has_trait("klima"): bonus += 1
			
		if bonus > 0:
			party.modify_satisfaction(bonus)

	# Einnahmen buchen (falls Eintritt/Basis-Kosten existieren)
	if income > 0:
		_guest_member.spending_budget = max(0, _guest_member.spending_budget - income)
		FinanceManager.add_transaction(
			income, "gastro",
			"tx.poi_income|" + _guest_member.name + "|" + GameState.T(poi_def.get("name", _current_poi_id))
		)
		var spawn_pos = global_position
		if is_instance_valid(room_node):
			var sz = room_node.call("get_tile_size") if room_node.has_method("get_tile_size") else Vector2i(1, 1)
			spawn_pos = room_node.global_position + Vector2(sz.x * 16.0, sz.y * 16.0)
		sig_poi_income.emit(income, spawn_pos)

	# EXP und Quest-Trigger NUR beim echten Erstbesuch (nicht bei Pause-Rueckkehr)
	if was_fresh_claim:
		var visit_exp: int = poi_def.get("visit_exp", 0)
		# Event-Gaeste zahlen keinen visit_exp - analog zu income = 0 (Bezahlung via Event-Budget)
		if is_instance_valid(my_party) and my_party.get("event_poi_id") != "":
			visit_exp = 0
		if visit_exp > 0:
			GameState.add_exp(visit_exp)
			var spawn_pos = global_position
			if EffectManager: EffectManager.spawn_exp_text(visit_exp, spawn_pos)

		# GuestManager über Besuch informieren (für Warenverbrauch-Tracking)
		if is_instance_valid(_guest_manager):
			var room_id = _get_poi_room_id(_current_poi_id)
			_guest_manager.on_poi_visited(room_id)
			
		if QuestManager and QuestManager.has_method("on_poi_used"):
			QuestManager.on_poi_used(_current_poi_id)

	# Gast zum Sitzplatz schicken (is_gastro() bestimmt ob danach STUDYING_MENU kommt)
	if seat_pos != Vector2.ZERO and seat_pos != Vector2.INF:
		_execute_poi_move(seat_pos, room_node)
	else:
		# Kein dedizierter Sitzplatz – sofort in process_waiting gehen
		_action_timer = 0.01


# =============================================================================
## Gibt die Definition eines POIs anhand seiner ID zurück.
func _get_poi_def(poi_id: String) -> Dictionary:
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var def = room.call("get_definition")
		if def.get("id", "") == poi_id:
			return def
	return {}


# =============================================================================
## Gibt den room_key eines POIs anhand seiner Definition-ID zurück.
func _get_poi_room_id(poi_id: String) -> String:
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var def = room.call("get_definition")
		if def.get("id", "") == poi_id:
			return GuestManager._room_key(room)
	return ""

# =============================================================================
## Gibt den Node eines POIs anhand seiner Definition-ID zurück.
func _get_poi_room_node(poi_id: String) -> Node2D:
	if poi_id == "lobby" or poi_id == "vending_machine":
		return _get_lobby_room()
		
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var def = room.call("get_definition")
		if def.get("id", "") == poi_id:
			return room
	return null


# =============================================================================
## Gibt die eigene GuestParty zurück (via GuestManager).
func _get_my_party() -> GuestParty:
	if not is_instance_valid(_guest_manager):
		return null
	return _guest_manager.get_party(_guest_member.party_id)


# =============================================================================
# Konferenz-Lebenszyklus-Methoden (werden von ConferenceSmall.broadcast aufgerufen)
# =============================================================================

## 12:00: Mittagspause – TG verlassen den Tagungsraum
func go_conference_break() -> void:
	# event_poi_id wird NICHT mehr geleert, sonst spawnt der GuestManager neue Gäste!
	var party = _get_my_party()
	if is_instance_valid(party) and party.event_poi_id != "":
		_conference_break_poi_key = party.event_poi_id
		# party.event_poi_id = "" # HIER WAR DER BUG FÜR DOPPELTEN SPAWN!
	_has_claimed_seat = false
	_action_timer = 0.0

	# Mögliche Ziele: Bar/Restaurant bevorzugt, Lobby (Snackomat) als Fallback
	var candidates: Array[String] = []
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room):
			continue
		var def = room.call("get_definition") if room.has_method("get_definition") else {}
		if room.has_method("is_gastro") and room.is_gastro():
			# Gastro 3x gewichtet → deutlich bevorzugt gegenüber Lobby
			candidates.append(def.get("id", ""))
			candidates.append(def.get("id", ""))
			candidates.append(def.get("id", ""))
	# Lobby als seltener Fallback (1x)
	candidates.append("lobby")

	var target = candidates.pick_random()
	print("[CONF] go_conference_break | %s | -> %s" % [(_guest_member.name if _guest_member else "?"), target])
	_walk_to_poi(target)

## 13:45: Rueckkehr aus Pause → zurueck zum Tagungsraum (wander_pm bis 14:00)
func return_from_conference_break() -> void:
	# event_poi_id ist nun ohnehin noch intakt, aber wir weisen _conference_break_poi_key zur Sicherheit zu
	var party = _get_my_party()
	if is_instance_valid(party) and _conference_break_poi_key != "":
		party.event_poi_id = _conference_break_poi_key
		_conference_break_poi_key = ""

	_is_returning_from_break = true  # Verhindert doppelte EXP beim Wiedereintritt
	_has_claimed_seat = false
	_action_timer = 0.0
	print("[CONF] return_from_conference_break | %s" % (_guest_member.name if _guest_member else "?"))
	_walk_to_poi("conference_small")

## 17:00: Konferenz-Ende – 50% direkt heim, 50% noch Bar/Restaurant
func end_conference_day() -> void:
	var party = _get_my_party()
	if is_instance_valid(party):
		party.event_poi_id = ""  # Event-Status entfernen → normaler Gast ab jetzt
	_has_claimed_seat = false

	print("[CONF] end_conference_day | %s" % (_guest_member.name if _guest_member else "?"))

	# 50% direkt auschecken
	if randf() < 0.5:
		start_checkout()
		return

	# 50% noch 1-2 Stunden Bar oder Restaurant
	var social_candidates: Array[String] = []
	for room in _map_grid.active_rooms:
		if not is_instance_valid(room):
			continue
		var def = room.call("get_definition") if room.has_method("get_definition") else {}
		if room.has_method("is_gastro") and room.is_gastro():
			social_candidates.append(def.get("id", ""))

	if social_candidates.size() > 0:
		_walk_to_poi(social_candidates.pick_random())
	else:
		start_checkout()

# =============================================================================
func start_checkout() -> void:
	_is_checkout_walk = true
	
	var lobby = _get_lobby_room()
	if not is_instance_valid(lobby):
		queue_free()
		return
		
	var exit_tile = lobby.get_target_tile(_map_grid)
	var start_tile: Vector2i = _get_logical_start_tile()
	
	_change_state(State.WALKING)
		
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile, (str(_guest_member.get("name")) if _guest_member else "?"))
	if path_tiles.is_empty():
		print("[GuestActor] Checkout failed for ", _guest_member.id, ". Path empty from ", start_tile, " to ", exit_tile, ". current_state=", current_state)
		queue_free()
		return
		
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	# Hole Warteposition für den Checkout (lokal in der Lobby)
	var wait_pos = Vector2.INF
	if lobby.has_method("get_checkout_wait_pos"):
		wait_pos = lobby.get_checkout_wait_pos(_guest_member.party_id)
		
	# Jitter damit die Gäste nicht alle exakt auf demselben Pixel stehen
	var jitter = Vector2(randf_range(-6.0, 6.0), randf_range(-10.0, 10.0))
	if wait_pos != Vector2.INF:
		wait_pos += jitter
		
	_execute_walk(path_tiles, State.AWAITING_CHECKOUT, door_world, wait_pos, lobby)
	_current_poi_id = "lobby"



# =============================================================================
## Spieler hat Checkout bestätigt: Gast erscheint an der Lobby und läuft raus.
func complete_checkout(spawn_pos: Vector2) -> void:
	if current_state == State.IDLE or global_position == Vector2.ZERO:
		global_position = spawn_pos  # Notfall-Spawn, z.B. bei Reload
		_current_poi_id = "lobby"    # Smart-Room-Navigation: lokaler Pfad zur Lobby-Ausgangstür
	_change_state(State.LEAVING)  # sichtbar
	_walk_to_exit()


# =============================================================================
## TG-Gäste (kein Hotelzimmer) werden automatisch ausgecheckt.
func _auto_checkout_tg_guest() -> void:
	# Kurz in der Lobby sichtbar warten, dann auto-abreisen
	var wait_time: float = 1.5 / max(1.0, TimeManager.user_speed if TimeManager else 1.0)
	await get_tree().create_timer(wait_time).timeout
	if is_instance_valid(self) and current_state == State.AWAITING_CHECKOUT:
		complete_checkout(global_position)

# =============================================================================
## Wird um 22:00 Uhr aufgerufen: Gast kehrt aus POI ins Zimmer zurück
func send_back_to_room() -> void:
	if current_state in [State.IN_POI, State.STUDYING_MENU, State.WAITING_FOR_FOOD, State.EATING]:
		# Sitz im aktuellen POI freigeben bevor wir weglaufen (verhindert Ghost-Seats)
		if not _current_poi_id.is_empty():
			var poi_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(poi_node) and poi_node.has_method("release_interaction"):
				poi_node.release_interaction(_guest_member.id)
		_has_claimed_seat = false
		_walk_to_room(_target_room, State.IN_ROOM)



# =============================================================================
func start_waiting_in_lobby(spawn_pos: Vector2, delay: float) -> void:
	_current_poi_id = "lobby"
	global_position = spawn_pos
	modulate.a = 0.0  # Unsichtbar bis er an der Reception steht
	_change_state(State.WAITING_IN_LINE)
	
	# Staffelung fuer Partymitglieder
	if delay > 0.0:
		var wait_time = delay
		if TimeManager and not TimeManager.is_paused():
			wait_time = delay / max(1.0, TimeManager.user_speed)
		await get_tree().create_timer(wait_time).timeout
	
	# Gast an einem Reception-Waypoint platzieren und sichtbar machen
	var lobby = _get_lobby_room()
	if is_instance_valid(lobby) and lobby.has_method("get_checkout_wait_pos"):
		var reception_pos = lobby.get_checkout_wait_pos(_guest_member.party_id)
		global_position = reception_pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	modulate.a = 1.0  # Jetzt sichtbar an der Reception

func start_waiting_for_event(spawn_pos: Vector2, delay: float) -> void:
	_current_poi_id = "lobby"
	global_position = spawn_pos
	modulate.a = 0.0  # Unsichtbar bis er an der Reception steht
	
	# Tagesgäste haben kein Zimmer
	_target_room = null
	
	_change_state(State.WAITING_IN_LINE)
	
	if delay > 0.0:
		var wait_time = delay
		if TimeManager and not TimeManager.is_paused():
			wait_time = delay / max(1.0, TimeManager.user_speed)
		await get_tree().create_timer(wait_time).timeout
		
	# Gast an einem Reception-Waypoint platzieren und sichtbar machen (wie normale Gäste)
	var lobby = _get_lobby_room()
	if is_instance_valid(lobby) and lobby.has_method("get_checkout_wait_pos"):
		var reception_pos = lobby.get_checkout_wait_pos(_guest_member.party_id)
		global_position = reception_pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	modulate.a = 1.0  # Jetzt sichtbar an der Reception
	
	# Status IDLE = Gast wartet auf das Event und fängt an POIs zu suchen
	previous_state = State.WAITING_IN_LINE
	_change_state(State.IDLE)
	_action_timer = randf_range(2.0, 5.0)

func _walk_to_world_pos(target_pos: Vector2, finish_state: State) -> void:
	if not is_instance_valid(_map_grid):
		return
	_change_state(State.WALKING)
	var start_tile = _get_logical_start_tile()
	var exit_tile = _map_grid.world_to_tile(target_pos)
	var path_tiles: Array[Vector2i] = _map_grid.get_path_between_tiles(start_tile, exit_tile, (str(_guest_member.get("name")) if _guest_member else "?"))
	if path_tiles.is_empty():
		path_tiles.append(start_tile)
		path_tiles.append(exit_tile)
	_execute_walk(path_tiles, finish_state, target_pos, target_pos)

func start_checkin(room: Node2D, spawn_pos: Vector2, delay: float) -> void:
	_target_room = room
	
	# POI-Sperre: 60 Ingame-Min nach Ankunft kein POI-Besuch (Gast kommt erst an)
	if TimeManager:
		_checkin_poi_block_until = TimeManager.get_game_time() + 60
	
	# Fallback, falls Actor noch nicht in der Lobby ist
	if current_state != State.WAITING_IN_LINE and current_state != State.WALKING:
		global_position = spawn_pos
		
	_change_state(State.WALKING)
	
	# Warte die Check-in-Schlange ab (Zeitskalierung beachten)
	if delay > 0.0:
		var wait_time = delay
		if TimeManager and not TimeManager.is_paused():
			wait_time = delay / max(1.0, TimeManager.user_speed)
		await get_tree().create_timer(wait_time).timeout
	
	_walk_to_room(room, State.IN_ROOM)


# =============================================================================
func _walk_to_room(room: Node2D, finish_state: State) -> void:
	if not is_instance_valid(room):
		_action_timer = 5.0
		return
		
	var start_tile = _get_logical_start_tile()
	
	# Sonderfall: Gast kommt aus der Lobby-Rezeption (WAITING_IN_LINE).
	# Das globale AStar muss von der Lobby-Innentür starten (nicht von der soliden Reception).
	# Der lokale Weg (Reception → Innentür) wird in _execute_walk animiert.
	if previous_state == State.WAITING_IN_LINE:
		_current_poi_id = "lobby"
		var lobby_room = _get_lobby_room()
		if is_instance_valid(lobby_room) and lobby_room.has_method("get_target_tile"):
			start_tile = lobby_room.get_target_tile(_map_grid)
	var exit_tile = room.get_target_tile(_map_grid)
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile, (str(_guest_member.get("name")) if _guest_member else "?"))
	if path_tiles.is_empty() and start_tile != exit_tile:
		var g_name = _guest_member.get("name") if _guest_member else "Unbekannt"
		print("[%s] Pfad nicht gefunden! Start: %s Exit: %s. Führe Notfall-Teleport aus." % [g_name, str(start_tile), str(exit_tile)])
		# Notfall-Teleport zur Tür, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(exit_tile)
		if finish_state == State.IN_ROOM:
			_current_poi_id = "" # Notfall: Gast ist im Zimmer, POI leeren!
		_change_state(finish_state)
		return
		
	# previous_state sichern: _change_state() würde es überschreiben,
	# aber _execute_walk braucht den Original-Zustand für local_path_out.
	var saved_previous_state = previous_state
	_change_state(State.WALKING)
	previous_state = saved_previous_state  # wiederherstellen
	
	var door_world = _map_grid.tile_to_world(exit_tile)
	# Tür-Position fürs Zielzimmer cachen (erstmalig oder bei Zimmerwechsel)
	if finish_state == State.IN_ROOM:
		_room_door_world = door_world
		
	var extra_pos = Vector2.INF
	if room.has_method("get_room_entry_pos"):
		extra_pos = room.get_room_entry_pos(_map_grid)
		
	_execute_walk(path_tiles, finish_state, door_world, extra_pos, room)

	if finish_state == State.IN_ROOM:
		_current_poi_id = "" # Ziel ist das Zimmer, nicht mehr der alte POI


## Generischer Walk zu einem beliebigen POI (Bar, Spa, Restaurant, Lobby ...)
## poi_id muss mit der "id" in der Raumdefinition übereinstimmen (oder "lobby")
func _walk_to_poi(poi_id: String) -> void:
	# Budget-Check: Hat der Gast genügend Taschengeld für diesen Besuch?
	if poi_id != "lobby":
		var poi_def = _get_poi_def(poi_id)
		if poi_def != null:
			var income: int = poi_def.get("visit_income", 0)
			if income > 0 and _guest_member.spending_budget < income:
				# Kein Geld mehr für diesen POI -> kurz warten und dann neu entscheiden
				_action_timer = randf_range(5.0, 15.0)
				return
	
	var target_room: Node2D = null
	var exit_tile: Vector2i
	
	if poi_id == "lobby" or poi_id == "vending_machine":
		target_room = _get_lobby_room()
	else:
		for room in _map_grid.active_rooms:
			if not is_instance_valid(room): continue
			# Check if poi_id is an event room key
			var gm = get_tree().current_scene.find_child("GuestManager", true, false)
			if is_instance_valid(gm) and GuestManager._room_key(room) == poi_id:
				target_room = room
				break
			var def = room.call("get_definition")
			if def.get("id", "") == poi_id:
				target_room = room
				break
				
	if not is_instance_valid(target_room):
		_action_timer = 5.0
		return
		
	exit_tile = target_room.get_target_tile(_map_grid)
	
	var start_tile: Vector2i = _get_logical_start_tile()
	
	var path_tiles: Array[Vector2i] = []
	if is_instance_valid(target_room):
		pass
		
	# Wenn wir schon im Zielraum sind (z.B. Wechsel des Sitzplatzes in Konferenz oder Snack-Automat in Lobby)
	# dann brauchen wir keinen globalen Pfad über die Flur-Tür!
	var current_room = _get_current_room_node(current_state)
	var is_same_room = (is_instance_valid(current_room) and is_instance_valid(target_room) and current_room == target_room)
	if is_same_room:
		path_tiles = []
	else:
		path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile, (str(_guest_member.get("name")) if _guest_member else "?"))
		
	if path_tiles.is_empty() and start_tile != exit_tile and not is_same_room:
# 		push_warning("[GuestActor] Pfad nicht gefunden! Start: %s Exit: %s" % [str(start_tile), str(exit_tile)])
		# Notfall-Teleport zur Tür, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(exit_tile)
		_change_state(State.IN_POI)
		return
		
	_change_state(State.WALKING)
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	var extra_pos = Vector2.INF
	if is_instance_valid(target_room):
		if poi_id == "vending_machine" and target_room.has_method("get_vending_target_world"):
			extra_pos = target_room.get_vending_target_world()
		else:
			var seat_pos = Vector2.INF
			
			# --- SMART ROOM API FÜR POIs ---
			if target_room.has_method("get_available_interactions") and target_room.has_method("claim_interaction"):
				var avail = target_room.get_available_interactions(self)
				if avail.size() > 0:
					var choice = avail.pick_random()
					var claim_data = target_room.claim_interaction(_guest_member.id, choice.id)
					if claim_data.has("target_pos"):
						seat_pos = claim_data.target_pos
						_has_claimed_seat = true
			# --- LEGACY FALLBACK FÜR ALTE RÄUME ---
			elif target_room.has_method("claim_seat"):
				pass # Legacy system commented out
			elif target_room.has_method("has_free_room_seat") and target_room.has_free_room_seat():
				pass # Legacy system commented out
				
			if seat_pos != Vector2.INF and seat_pos != Vector2.ZERO:
				extra_pos = seat_pos
			elif target_room.has_method("get_free_walkable_pos"):
				var wander_pos = target_room.get_free_walkable_pos(_map_grid)
				if wander_pos != Vector2.INF:
					extra_pos = wander_pos
			
	_execute_walk(path_tiles, State.IN_POI, door_world, extra_pos, target_room)
	# WICHTIG: _current_poi_id muss der POI-Typ sein (z.B. "conference_small"), NICHT der Raumkey (z.B. "P1")
	# damit _get_poi_room_node() den Raum später korrekt findet!
	# Spezialfall: vending_machine liegt in der Lobby → target_room.get_definition().id = "lobby",
	# also poi_id direkt setzen statt aus der Definition zu lesen!
	if poi_id == "vending_machine":
		_current_poi_id = "vending_machine"
	elif is_instance_valid(target_room) and target_room.has_method("get_definition"):
		var def = target_room.call("get_definition")
		_current_poi_id = def.get("id", poi_id)
	else:
		_current_poi_id = poi_id



# =============================================================================
func _walk_to_exit() -> void:
	var lobby = _get_lobby_room()
	if not is_instance_valid(lobby):
		queue_free()
		return
		
	var exit_tile = lobby.get_street_tile(_map_grid)
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	# target_room = null (statt lobby) damit _execute_walk Phase 1 greift:
	# current_room (lobby, aus _current_poi_id) != target_room (null)
	# → lokaler Pfad von den Schreibtischen / reception-Waypoint zur OUT-Tür wird generiert.
	# Ohne das würde current_room == target_room → kein lokaler Pfad → Gast verschwindet in place.
	_execute_walk([] as Array[Vector2i], State.LEAVING, door_world, Vector2.INF, null)


# =============================================================================
func _execute_walk(path_tiles: Array[Vector2i], finish_state: State, face_pos: Vector2, extra_target_pos: Vector2 = Vector2.INF, target_room: Node2D = null) -> void:
	var world_path: Array[Vector2] = []
	
	# --- SMART ROOM NAVIGATION HANDSHAKE ---
	# PHASE 1: Local Path Out (Raum verlassen)
	var is_leaving_hotel = (finish_state == State.LEAVING)
	var current_room = _get_current_room_node(previous_state)
	
	if is_instance_valid(current_room) and current_room.has_method("get_local_path") and current_room.has_method("get_door_world_inside"):
		# Wenn wir in einem Raum sind und ihn verlassen (egal wie lang der Flur-Pfad ist!)
		if current_room != target_room:
			var door_inside = current_room.get_door_world_inside(_map_grid, is_leaving_hotel)
			var g_name = _guest_member.id if _guest_member else "Unknown"
			var local_path_out = current_room.get_local_path(global_position, door_inside, g_name)
			world_path.append_array(local_path_out)
			
	if _map_grid and "is_miniature" in _map_grid and not _map_grid.is_miniature:
		var lbl = (str(_guest_member.get("name")) if _guest_member else "?")
		_map_grid._debug_paths[lbl] = {"path": path_tiles, "label": lbl}

	var door_index_out := -1
	if world_path.size() > 0:
		door_index_out = world_path.size() - 1

	# PHASE 2: Global Path (Flur)
	for tile in path_tiles:
		world_path.append(_map_grid.tile_to_world(tile))
		
	var door_index_in := -1
	# PHASE 3: Local Path In (Ziel-Raum betreten)
	# Sicherheitscheck: Wenn KEIN globaler Pfad UND KEIN lokaler Austritts-Pfad existiert
	# UND das Ziel weit weg ist → keinen lokalen Pfad erzwingen (verhindert Geisterlinien)
	var has_any_path = path_tiles.size() > 0 or world_path.size() > 0
	var is_nearby = extra_target_pos != Vector2.INF and global_position.distance_to(extra_target_pos) < 200.0
	if extra_target_pos != Vector2.INF and (has_any_path or is_nearby):
		if is_instance_valid(target_room) and target_room.has_method("get_local_path") and target_room.has_method("get_door_world_inside"):
			var path_start_pos = global_position
			if world_path.size() > 0:
				path_start_pos = target_room.get_door_world_inside(_map_grid, false)
				
			var g_name = _guest_member.id if _guest_member else "Unknown"
			var local_path_in = target_room.get_local_path(path_start_pos, extra_target_pos, g_name)
			world_path.append_array(local_path_in)
		else:
			world_path.append(extra_target_pos)
		
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	_active_tween = create_tween()
	
	if TimeManager:
		if not TimeManager.is_paused():
			var speed = TimeManager.user_speed
			_active_tween.set_speed_scale(speed)
		else:
			_active_tween.set_speed_scale(0.0)
		
	var current_pos = global_position
	
	# Denkpause: 1 Sekunde stehen bleiben, bevor er losläuft
	_active_tween.tween_interval(1.0)
	
	var p_idx = 0
	for point in world_path:
		var dist = current_pos.distance_to(point)
		var duration = dist / _base_speed
		
		_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(point))
		_active_tween.tween_property(self, "global_position", point, duration)
		current_pos = point
		
		if p_idx == door_index_out or p_idx == door_index_in:
			_active_tween.tween_callback(func():
				if SettingsManager.play_door_sounds:
					SoundManager.play("door_close")
			)
		p_idx += 1
		
	_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(face_pos))
	_active_tween.tween_interval(0.3)
	
	if finish_state == State.LEAVING:
		_active_tween.tween_property(self, "modulate:a", 0.0, 0.4)
		_active_tween.tween_callback(queue_free)
	else:
		_active_tween.tween_callback(func(): _on_walk_finished(finish_state))

# =============================================================================
func _on_time_speed_changed(is_paused: bool, speed: float) -> void:
	if _active_tween and _active_tween.is_valid():
		if not is_paused:
			_active_tween.set_speed_scale(speed)
		else:
			_active_tween.set_speed_scale(0.0)


# =============================================================================
# --- Helfer-Methoden für Koordinaten ---
# =============================================================================

func _get_logical_start_tile() -> Vector2i:
	var start_tile: Vector2i = _get_current_tile()
	
	if not _current_poi_id.is_empty():
		var poi_room = _get_poi_room_node(_current_poi_id)
		if is_instance_valid(poi_room) and poi_room.has_method("get_target_tile"):
			start_tile = poi_room.get_target_tile(_map_grid)
			
	elif _current_poi_id.is_empty() and (current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING or current_state == State.IDLE):
		if _room_door_world != Vector2.INF:
			start_tile = _map_grid.world_to_tile(_room_door_world)
		elif is_instance_valid(_target_room):
			var t_exit_tile = _get_room_exit_tile(_target_room)
			_room_door_world = _map_grid.tile_to_world(t_exit_tile)
			start_tile = t_exit_tile
	
	var result := _get_closest_walkable_tile(start_tile)
	
	# Safety-Fallback: falls result immer noch solid ist (Gast steckt in Wand/Lobby-Körper),
	# nimm die Lobby-Innentür als Startpunkt. Das passiert wenn _current_poi_id leer ist
	# und der Gast sich physisch innerhalb eines Raum-Körpers befindet.
	if is_instance_valid(_map_grid) and _map_grid.astar.is_in_boundsv(result) and _map_grid.astar.is_point_solid(result):
		var lobby: Node2D = _get_lobby_room()
		if is_instance_valid(lobby) and lobby.has_method("get_target_tile"):
			var lobby_door: Vector2i = lobby.get_target_tile(_map_grid)
			print("[GuestActor] Safety fallback: ", _guest_member.get("name") if _guest_member else "?",
				" stuck at ", result, " (solid) -> using lobby door ", lobby_door,
				" | poi=", _current_poi_id)
			result = lobby_door
	
	return result

func _get_closest_walkable_tile(tile: Vector2i) -> Vector2i:
	if not is_instance_valid(_map_grid) or not _map_grid.astar.is_in_boundsv(tile): return tile
	if not _map_grid.astar.is_point_solid(tile): return tile
	
	var dirs = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1), Vector2i(1,1), Vector2i(-1,-1), Vector2i(1,-1), Vector2i(-1,1)]
	for d in dirs:
		var n = tile + d
		if _map_grid.astar.is_in_boundsv(n) and not _map_grid.astar.is_point_solid(n):
			return n
			
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			var n = tile + Vector2i(dx, dy)
			if _map_grid.astar.is_in_boundsv(n) and not _map_grid.astar.is_point_solid(n):
				return n
				
	return tile

func _get_current_tile() -> Vector2i:
	return _map_grid.world_to_tile(global_position)


func _get_lobby_room() -> Node2D:
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	if entry_parcel and entry_parcel.has_method("get_lobby"):
		return entry_parcel.get_lobby()
	return null

func _get_room_exit_tile(room: Node2D) -> Vector2i:
	var sz: Vector2i = room.get_tile_size()
	var rot: int = room.get("door_rotation")
	var off: int = room.get("door_offset")
	var tx: int = int(room.position.x / _map_grid.TILE_PX)
	var ty: int = int(room.position.y / _map_grid.TILE_PX)
	var px: int = int(room.get_parent().name.split("_")[1])
	var py: int = int(room.get_parent().name.split("_")[2])
	return _map_grid._exit_global(px, py, tx, ty, sz.x, sz.y, rot, off)
# =============================================================================
func _wander_in_room(room: Node2D, force_sleep: bool = false, initial_wait: bool = false) -> void:
	# Fallback: Falls wir nicht IN_ROOM sind, abbrechen (z.B. schon wieder im Laufen)
	if current_state == State.WALKING or current_state == State.WAITING_IN_LINE:
		return
		
	if not is_instance_valid(room):
		_action_timer = 5.0
		return
		
	_change_state(State.WALKING)
		
	var target = Vector2.INF
	var next_state = State.IN_ROOM
	
	if room.has_method("get_available_interactions"):
		var interactions = room.get_available_interactions(self)
		if interactions.size() > 0:
			var valid_interactions = interactions.filter(func(c): return c.id != _last_interaction_id)
			if valid_interactions.is_empty():
				valid_interactions = interactions
				
			var possible_choices = []
			if force_sleep:
				possible_choices = valid_interactions.filter(func(c): return c.type == "sleep")
			else:
				var r = randf()
				if r < 0.1:
					possible_choices = valid_interactions.filter(func(c): return c.type == "sleep")
				elif r < 0.5:
					possible_choices = valid_interactions.filter(func(c): return c.type == "sit")
					
			if possible_choices.is_empty():
				possible_choices = valid_interactions
				
			var choice = possible_choices.pick_random()
			if room.has_method("claim_interaction"):
				var claim = room.claim_interaction(_guest_member.id, choice.id)
				if claim.has("target_pos"):
					_last_interaction_id = choice.id
					target = claim.target_pos
					if choice.type == "sleep": next_state = State.SLEEPING
					elif choice.type == "sit": next_state = State.SITTING
					else: next_state = State.IN_ROOM
			
	if target == Vector2.INF and room.has_method("get_random_walkable_local_pos"):
		target = room.get_random_walkable_local_pos()
		next_state = State.IN_ROOM
		
	if target == Vector2.INF:
		# Fallback falls kein Ziel gefunden wurde (z.B. keine freies Bett und kein Nav-Grid)
		target = global_position
		next_state = State.IN_ROOM
		
	var local_path = []
	if room.has_method("get_local_path"):
		local_path = room.get_local_path(global_position, target)
		
	if local_path.is_empty():
		local_path.append(target)
		
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	_active_tween = create_tween()
	var speed_scale = TimeManager.user_speed if TimeManager and not TimeManager.is_paused() else 1.0
	_active_tween.set_speed_scale(speed_scale)
	_active_tween.tween_interval(0.01) # Verhindert "started with no Tweeners" Error
	
	var current_pos = global_position
	
	for point in local_path:
		var dist = current_pos.distance_to(point)
		var duration = max(dist / _base_speed, 0.1) # Mindestdauer 0.1s, damit es nicht in einem Frame instant-finished
		_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(point))
		_active_tween.tween_property(self, "global_position", point, duration)
		current_pos = point
		
	_active_tween.tween_callback(func(): 
		print("[GuestActor] %s tween finished. changing to next_state=%s (%d)" % [_guest_member.get("name") if _guest_member else "Unknown", get_state_name(next_state), next_state])
		if next_state == State.SLEEPING or next_state == State.SITTING:
			avatar.rotation = 0
			if next_state == State.SITTING and is_instance_valid(_target_room):
				# Table suchen
				var table = _target_room.get_node_or_null("%Table")
				if not is_instance_valid(table):
					var tables = _target_room.find_children("Table", "Sprite2D")
					if not tables.is_empty():
						for t in tables:
							var p = t.get_parent()
							var is_active = true
							while p != _target_room and is_instance_valid(p):
								if "visible" in p and not p.visible:
									is_active = false
									break
								p = p.get_parent()
							if is_active:
								table = t
								break
				if is_instance_valid(table):
					avatar.rotation = avatar.global_position.angle_to_point(table.global_position)
		_change_state(next_state)
	)
	
	_active_tween.tween_callback(func(): 
		if initial_wait:
			_action_timer = randf_range(45.0, 120.0)
		elif TimeManager:
			_action_timer = 15.0 * TimeManager.SECONDS_PER_GAME_MINUTE
		else:
			_action_timer = 60.0
	)
