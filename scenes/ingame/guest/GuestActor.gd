extends Node2D
class_name GuestActor

const HUNGER_THRESHOLD: int = 40

# --- Zustände ---

func get_state_name(s: int) -> String:
	var keys = State.keys()
	if s >= 0 and s < keys.size():
		return keys[s]
	return "UNKNOWN"

enum State { IDLE, WALKING, IN_ROOM, IN_POI, AWAITING_CHECKOUT, LEAVING, STUDYING_MENU, WAITING_FOR_FOOD, EATING, SITTING, SLEEPING, WAITING_IN_LINE }

var current_state: State = State.IDLE
var previous_state: State = State.IDLE
var _guest_member: GuestMember
var _map_grid: Node # MapGrid Referenz
var _guest_manager: GuestManager = null  # Referenz für Budget & POI-Tracking
var _target_room: Node2D = null

var _room_door_world: Vector2 = Vector2.INF

## Verhindert, dass wake_up() den Checkout-Lauf überschreibt
var _is_checkout_walk: bool = false

## Welcher POI aktuell besucht wird (z.B. "lobby", "bar", "spa")
var _current_poi_id: String = ""
var _current_order_id: String = ""

# Interner Timer für Aufenthaltsdauer
var _action_timer: float = 0.0
var _poi_stay_timer: float = 0.0
var _impatient_timer: float = 0.0
var _base_speed: float = 40.0

var _active_tween: Tween
var _last_interaction_id: String = ""

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

			
		_change_state(State.IN_ROOM)
		
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
	
	if _impatient_timer >= 60.0: # Alle 60 Ingame-Sekunden
		_impatient_timer = 0.0
		var party = _get_my_party()
		if party:
			party.modify_satisfaction(-2)


# =============================================================================
func _process_waiting(delta: float) -> void:
	if _action_timer <= 0.0:
		return # Gast ruht – kein Timer-Countdown
		
	# Normaler Gast: POI schließt -> zurück ins Zimmer, ABER wer schon bestellt hat oder isst, darf bleiben!
	if current_state in [State.IN_POI, State.STUDYING_MENU] and not _current_poi_id.is_empty() and not _is_current_poi_open():
		var poi_room_node = _get_poi_room_node(_current_poi_id)
		if is_instance_valid(poi_room_node):
			if poi_room_node.has_method("release_interaction"):
				poi_room_node.release_interaction(_guest_member.id)
			if poi_room_node.has_method("leave_seat"):
				poi_room_node.leave_seat(_guest_member.id)
		send_back_to_room()
		return
		
	var speed = 1.0
	if TimeManager:
		if TimeManager.is_paused():
			return # NEU: Nicht ticken, wenn pausiert!
		speed = TimeManager.user_speed
		
	if current_state == State.IN_POI and (_current_poi_id == "pool_small" or _current_poi_id == "gym_small" or _current_poi_id == "spa_small"):
		_poi_stay_timer -= delta * speed
		if _poi_stay_timer <= 0.0:
			var room_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(room_node) and room_node.has_method("leave_seat"):
				room_node.leave_seat(_guest_member.id)
			_decide_next_action()
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
			
			# Der Weg aus dem POI wird nun sauber über local_path_out in _execute_walk animiert!
			# print("[DEBUG] Gast ", _guest_member.id if _guest_member else "?", " beendet EATING. Ziel: Zimmer ist valid! Rufe _walk_to_room auf.")
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				# print("[DEBUG] Gast ", _guest_member.id if _guest_member else "?", " beendet EATING. Ziel: Zimmer ist INVALID! Rufe _decide_next_action auf.")
				_decide_next_action()
		elif current_state == State.STUDYING_MENU:
			var room_node = _get_poi_room_node(_current_poi_id)
			var ordered = false
			if is_instance_valid(room_node) and room_node.has_method("place_order_for_seat"):
				var missing_sat = max(0, 100 - _guest_member.saturation)
				ordered = room_node.place_order_for_seat(_guest_member.id, _guest_member.spending_budget, missing_sat)
				
			if ordered:
				_change_state(State.WAITING_FOR_FOOD)
			else:
				# Gast hat nur Getränk bekommen oder nichts bestellt -> wechselt direkt in EATING (Trink-Timer)
				_change_state(State.EATING)
		elif current_state == State.IN_POI:
			var current_hour = 12
			if TimeManager:
				current_hour = TimeManager.get_hour()
			if current_hour >= 23 or current_hour < 6:
				_decide_next_action()
				return

			var room_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(room_node):
				# SMART ROOM: Gibt es verfügbare Interaktionen?
				var interactions = []
				if room_node.has_method("get_available_interactions"):
					interactions = room_node.get_available_interactions(self)
					
				if interactions.size() > 0:
					var choice = interactions.pick_random()
					if room_node.has_method("release_interaction"):
						room_node.release_interaction(_guest_member.id) # Alten Platz freigeben
					if room_node.has_method("claim_interaction"):
						var claim_result = room_node.claim_interaction(_guest_member.id, choice.get("id", ""))
						if claim_result.has("target_pos"):
							_execute_poi_move(claim_result.target_pos, room_node)
							var dur = claim_result.get("duration", randf_range(15.0, 30.0))
							_action_timer = dur * TimeManager.SECONDS_PER_GAME_MINUTE
							return
				
				# Fallback für alte Räume (Legacy)
				if room_node.has_method("release_interaction"):
					room_node.release_interaction(_guest_member.id)
				if room_node.has_method("leave_seat"):
					room_node.leave_seat(_guest_member.id)
			
			_decide_next_action()
		else:
			# Für alle anderen States (z.B. IN_ROOM, IDLE, SITTING), entscheide was als nächstes passiert
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
		
	if _current_poi_id != "pool_small" and _current_poi_id != "gym_small" and _current_poi_id != "spa_small" and _current_poi_id != "conference_small":
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
		
		# SMART ROOM: Der Raum entscheidet selbst, ob der Gast rein darf!
		if room.has_method("is_guest_allowed") and not room.is_guest_allowed(self):
			continue
		
		var cost = def.get("visit_income", 0)
		if room_id in ["restaurant_small", "bar", "kiosk"]:
			cost = max(cost, 5) # Gastro braucht mindestens 5€ Budget für Essen/Getränke
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
		if room_node.has_method("is_operational") and not room_node.is_operational():
			return false
			
	return true


# =============================================================================
func _decide_next_action() -> void:
	if current_state == State.LEAVING:
		return
	
	# (Müdigkeits-Check entfernt, da GuestMember keine energy Property hat)
		
	var open_pois := _get_open_pois()
	
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
	if open_pois.is_empty():
		if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING:
			_wander_in_room(_target_room)
			return
		elif current_state != State.WALKING and current_state != State.IDLE:
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				var party = _get_my_party()
				if is_instance_valid(party) and party.event_poi_id != "":
					_walk_to_poi("lobby")
				else:
					_change_state(State.LEAVING)
					_walk_to_exit()
			return
		else:
			var party = _get_my_party()
			if is_instance_valid(party) and party.event_poi_id != "":
				_action_timer = randf_range(5.0, 10.0)
			else:
				_action_timer = randf_range(15.0, 45.0)
			return
	
	# Mögliche Ziele: Zimmer (falls vorhanden) + alle offenen POIs
	var possible_targets: Array[String] = []
	if is_instance_valid(_target_room):
		possible_targets.append("room")
	else:
		possible_targets.append("lobby")
		
	possible_targets.append_array(open_pois)
		
	var chosen: String = possible_targets.pick_random()
	
	# ANG-310: Hunger-Priorisierung! Wenn der Gast hungrig ist, soll er Essen fokussieren.
	if _guest_member.saturation < HUNGER_THRESHOLD:
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
	elif (current_state == State.IN_POI or current_state == State.EATING) and chosen == _current_poi_id:
		var party = _get_my_party()
		if is_instance_valid(party) and party.event_poi_id != "":
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
				var lobby = _get_lobby_room()
				if is_instance_valid(lobby) and chosen == "lobby":
					_wander_in_room(lobby)
				else:
					_walk_to_poi("lobby")
				return
		else:
			chosen = "room"
	
	if chosen == "room":
		if is_instance_valid(_target_room):
			_walk_to_room(_target_room, State.IN_ROOM)
		else:
			var party = _get_my_party()
			if is_instance_valid(party) and party.event_poi_id != "":
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
	_action_timer = randf_range(5.0, 30.0)




# =============================================================================
func _change_state(new_state: State) -> void:
	var old_state = current_state
	previous_state = old_state
	
	var g_name = _guest_member.get("name") if _guest_member else "Unknown"
	var poi_info = (" [" + _current_poi_id + "]") if new_state == State.IN_POI and not _current_poi_id.is_empty() else ""
	print("[GuestActor] %s changed state: %s -> %s%s" % [g_name, get_state_name(old_state), get_state_name(new_state), poi_info])
	
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
		
	current_state = new_state
	
	# Türsounds werden nun framegenau über _execute_walk getriggert, nicht mehr hier pauschal beim State-Wechsel
	
	# POI-Ankunft: Einnahmen & Boost verarbeiten
	if new_state == State.IN_POI:
		_on_poi_arrived()
	
	match current_state:
		State.IN_ROOM:
			_action_timer = 0.5 # Immediately wander or sleep upon arriving
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.IN_POI:
			if _current_poi_id == "pool_small" or _current_poi_id == "gym_small" or _current_poi_id == "spa_small" or _current_poi_id == "conference_small":
				var stay_dur = randf_range(60.0, 180.0)
				var poi_def = _get_poi_def(_current_poi_id)
				if poi_def.has("open_to"):
					var open_to = poi_def.get("open_to")
					if open_to < 1440:
						var now = 0
						if TimeManager: now = TimeManager.get_game_time()
						var time_left = open_to - now
						if time_left > 0:
							stay_dur = min(stay_dur, float(time_left))
						else:
							stay_dur = 1.0
				_poi_stay_timer = stay_dur * TimeManager.SECONDS_PER_GAME_MINUTE
				
				if _current_poi_id == "conference_small":
					if poi_def.has("current_speaker_id") and poi_def.get("current_speaker_id") == _guest_member.id:
						pass # Wir können das hier nicht direkt abfragen, weil current_speaker_id auf dem Node liegt.
					# Stattdessen einfach einen schnellen Check machen:
					var room_node = _get_poi_room_node(_current_poi_id)
					if is_instance_valid(room_node) and room_node.get("current_speaker_id") == _guest_member.id:
						_action_timer = randf_range(10.0, 15.0) * TimeManager.SECONDS_PER_GAME_MINUTE
					else:
						_action_timer = randf_range(1.0, 3.0) * TimeManager.SECONDS_PER_GAME_MINUTE # Zuhörer pollen regelmäßig
				else:
					_action_timer = randf_range(15.0, 30.0) * TimeManager.SECONDS_PER_GAME_MINUTE # Erster Wechsel nach 15-30 Ingame-Minuten
				
				avatar.visible = true
			else:
				_action_timer = randf_range(45.0, 120.0)
				avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = avatar.visible
		State.AWAITING_CHECKOUT:
			# Sichtbar in der Lobby am Checkout warten
			_action_timer = 0.0
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = false
		State.STUDYING_MENU:
			_action_timer = randf_range(5.0, 10.0)
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
			if lobby.buy_snack(_guest_member.spending_budget):
				_guest_member.spending_budget = max(0, _guest_member.spending_budget - lobby.VENDING_MACHINE_PRICE)
				var actual_sat = lobby.VENDING_MACHINE_SATURATION + randi_range(-5, 10) # Bricht die Sättigungs-Zyklen auf
				_guest_member.saturation = min(100, _guest_member.saturation + actual_sat)
				
				FinanceManager.add_transaction(lobby.VENDING_MACHINE_PRICE, "gastro", "tx.poi_income|" + _guest_member.name + "|Snack-Automat")
				if EffectManager: EffectManager.spawn_money_text(lobby.VENDING_MACHINE_PRICE, global_position + Vector2(0, -48))
				if EffectManager: EffectManager.spawn_exp_text(lobby.VENDING_MACHINE_EXP, global_position + Vector2(0, -32))
				
				# Gast macht einen Schritt zur Seite, wird wieder sichtbar und isst
				var target_pos = lobby.get_snack_eating_target_world()
				_change_state(State.WALKING)
				_execute_walk([] as Array[Vector2i], State.EATING, global_position, target_pos, lobby)
				return
		
		# Falls Automat nicht klappt
		_action_timer = randf_range(5.0, 15.0)
		return
	
	var poi_def = _get_poi_def(_current_poi_id)
	var income: int = poi_def.get("visit_income", 0)
	
	var room_node = _get_poi_room_node(_current_poi_id)
	
	# Bar Gastro-Loop Dynamik: Wenn die Bar eine Bedienung hat, entfällt der Eintritt
	if _current_poi_id == "bar" and is_instance_valid(room_node) and room_node.has_method("_has_waiter_assigned"):
		if room_node.call("_has_waiter_assigned"):
			income = 0
	
	# ACHTUNG: Wir prüfen ZUERST auf Sitzplätze, damit Gäste nicht zahlen, wenn voll ist!
	var seat_pos = Vector2.ZERO
	var is_smart_room = false
	if is_instance_valid(room_node):
		if room_node.has_method("get_available_interactions"):
			is_smart_room = true
			var avail = room_node.get_available_interactions(self)
			if avail.size() > 0:
				seat_pos = Vector2(1, 1) # Dummy to pass validation
		elif _current_poi_id == "conference_small" and room_node.has_method("claim_podium"):
			seat_pos = room_node.claim_podium(_guest_member.id)
			if seat_pos == Vector2.INF or seat_pos == Vector2.ZERO:
				if room_node.has_method("claim_seat"):
					seat_pos = room_node.claim_seat(_guest_member.id)
		elif room_node.has_method("claim_seat"):
			seat_pos = room_node.claim_seat(_guest_member.id)
			
		if seat_pos == Vector2.ZERO or seat_pos == Vector2.INF:
			# Kein Platz frei! Gast bricht Besuch ab
			var reason = "Unknown"
			if is_smart_room:
				var avail = room_node.get_available_interactions(self)
				reason = "SmartRoom: 0 available interactions. Total seats checked: " + str(avail.size())
			else:
				reason = "Legacy Room: claim_seat returned " + str(seat_pos)
				
			print("[GuestActor] %s bricht Besuch in %s ab. Grund: %s" % [_guest_member.name, _current_poi_id, reason])
			send_back_to_room()
			return
	
	var party := _get_my_party()
	
	if is_instance_valid(party):
		var bonus = 0
		if income > 0:
			bonus += 2 # Base bonus (war vorher 5, reduziert für Balancing)
			
		if is_instance_valid(room_node) and room_node.has_method("has_trait"):
			if room_node.has_trait("wlan"): bonus += 1
			if room_node.has_trait("klima"): bonus += 1
			
		if bonus > 0:
			party.modify_satisfaction(bonus)

	# Einnahmen buchen (falls Eintritt/Basis-Kosten existieren)
	if income > 0:
		# Budget abziehen (per Member – jeder hat seinen eigenen Geldbeutel)
		_guest_member.spending_budget = max(0, _guest_member.spending_budget - income)
		
		# Einnahme buchen
		FinanceManager.add_transaction(
			income, "gastro",
			"tx.poi_income|" + _guest_member.name + "|" + GameState.T(poi_def.get("name", _current_poi_id))
		)
		
		# FloatingValue Signal senden
		var spawn_pos = global_position
		if is_instance_valid(room_node):
			var sz = room_node.call("get_tile_size") if room_node.has_method("get_tile_size") else Vector2i(1, 1)
			spawn_pos = room_node.global_position + Vector2(sz.x * 16.0, sz.y * 16.0)
		sig_poi_income.emit(income, spawn_pos)

	# EXP pro POI-Besuch vergeben (wenn definiert)
	var visit_exp: int = poi_def.get("visit_exp", 0)
	if visit_exp > 0:
		GameState.add_exp(visit_exp)
		var spawn_pos = global_position
		if EffectManager: EffectManager.spawn_exp_text(visit_exp, spawn_pos)

	# GuestManager über Besuch informieren (für Warenverbrauch-Tracking)
	if is_instance_valid(_guest_manager):
		var room_id = _get_poi_room_id(_current_poi_id)
		_guest_manager.on_poi_visited(room_id)

	if is_smart_room:
		_action_timer = 0.0 # Force immediate process_waiting
		return

	if seat_pos != Vector2.ZERO and seat_pos != Vector2.INF:
		# Animierter Gang zum Sitzplatz statt Teleport!
		if _active_tween and _active_tween.is_valid():
			_active_tween.kill()
		_active_tween = create_tween()
		var speed_scale = TimeManager.user_speed if TimeManager and not TimeManager.is_paused() else 1.0
		_active_tween.set_speed_scale(speed_scale)
		_active_tween.tween_interval(0.01) # Verhindert "started with no Tweeners" Error
		
		# Avatar während des Weges zum Platz sichtbar halten!
		avatar.visible = true
		
		var local_path = []
		if is_instance_valid(room_node) and room_node.has_method("get_local_path"):
			local_path = room_node.get_local_path(global_position, seat_pos)
		
		if local_path.is_empty():
			local_path.append(seat_pos)
			
		var curr_pos = global_position
		for p in local_path:
			var dur = curr_pos.distance_to(p) / _base_speed
			if dur > 0.0:
				_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(p))
				_active_tween.tween_property(self, "global_position", p, dur)
			curr_pos = p
			
		if _current_poi_id != "pool_small" and _current_poi_id != "gym_small" and _current_poi_id != "spa_small" and _current_poi_id != "conference_small":
			_active_tween.tween_callback(func(): _change_state(State.STUDYING_MENU))
		return
	else:
		# Kein Platz frei! Gast bricht Besuch ab (sollte eigentlich oben schon gefangen werden, aber sicher ist sicher)
		send_back_to_room()
		return


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
		
	_current_poi_id = "lobby"
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


# =============================================================================
## Spieler hat Checkout bestätigt: Gast erscheint an der Lobby und läuft raus.
func complete_checkout(spawn_pos: Vector2) -> void:
	if current_state == State.IDLE or global_position == Vector2.ZERO:
		global_position = spawn_pos  # Notfall-Spawn, z.B. bei Reload
		
	_change_state(State.LEAVING)  # sichtbar
	_walk_to_exit()


# =============================================================================
## Wird um 22:00 Uhr aufgerufen: Gast kehrt aus POI ins Zimmer zurück
func send_back_to_room() -> void:
	if current_state in [State.IN_POI, State.STUDYING_MENU, State.WAITING_FOR_FOOD, State.EATING]:
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
	modulate.a = 0.0
	
	# Tagesgäste haben kein Zimmer
	_target_room = null
	
	_change_state(State.WALKING)
	
	if delay > 0.0:
		var wait_time = delay
		if TimeManager and not TimeManager.is_paused():
			wait_time = delay / max(1.0, TimeManager.user_speed)
		await get_tree().create_timer(wait_time).timeout
		
	var lobby = _get_lobby_room()
	if is_instance_valid(lobby) and lobby.has_method("get_checkout_wait_pos"):
		var reception_pos = lobby.get_checkout_wait_pos(_guest_member.party_id)
		global_position = reception_pos + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	modulate.a = 1.0
	
	# Status IDLE = Gast wartet auf das Event und fängt an POIs zu suchen
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
		var income: int = poi_def.get("visit_income", 0)
		if income > 0 and _guest_member.spending_budget < income:
			# Kein Geld mehr für diesen POI – kurz warten und dann neu entscheiden
			_action_timer = randf_range(5.0, 15.0)
			return
	
	var target_room: Node2D = null
	var exit_tile: Vector2i
	
	if poi_id == "lobby" or poi_id == "vending_machine":
		target_room = _get_lobby_room()
	else:
		for room in _map_grid.active_rooms:
			if not is_instance_valid(room): continue
			var def = room.call("get_definition")
			if def.get("id", "") == poi_id:
				target_room = room
				break
				
	if not is_instance_valid(target_room):
		_action_timer = 5.0
		return
		
	exit_tile = target_room.get_target_tile(_map_grid)
	
	var start_tile: Vector2i = _get_logical_start_tile()
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile, (str(_guest_member.get("name")) if _guest_member else "?"))
	if path_tiles.is_empty() and start_tile != exit_tile:
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
			if target_room.has_method("claim_seat"):
				seat_pos = target_room.claim_seat(_guest_member.id)
			elif target_room.has_method("has_free_room_seat") and target_room.has_free_room_seat():
				seat_pos = target_room.room_claim_seat(_guest_member.id)
				
			if seat_pos != Vector2.INF and seat_pos != Vector2.ZERO:
				extra_pos = seat_pos
			elif target_room.has_method("get_free_walkable_pos"):
				var wander_pos = target_room.get_free_walkable_pos(_map_grid)
				if wander_pos != Vector2.INF:
					extra_pos = wander_pos
			
	_execute_walk(path_tiles, State.IN_POI, door_world, extra_pos, target_room)
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
		_map_grid._debug_paths.append({"path": path_tiles, "label": (str(_guest_member.get("name")) if _guest_member else "?")})

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
		_active_tween.tween_callback(func(): _change_state(finish_state))
		
	_active_tween.tween_callback(func(): 
		if _map_grid and "is_miniature" in _map_grid and not _map_grid.is_miniature:
			_map_grid._debug_paths = _map_grid._debug_paths.filter(func(e): return e["path"] != path_tiles)
	)

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
		# print("[GuestActor] %s tween finished. changing to next_state=%s (%d)" % [_guest_member.get("name") if _guest_member else "Unknown", get_state_name(next_state), next_state])
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
