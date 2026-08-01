extends Node2D
class_name GuestActor

# --- Zustände ---
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
var _impatient_timer: float = 0.0
var _base_speed: float = 40.0

var _active_tween: Tween

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
		# Wenn mit Startraum gespawnt (z.B. nach Laden), setze Position auf die Zimmertür!
		_target_room = start_room
		_target_room = start_room
		var exit_tile = _get_room_exit_tile(start_room)
		var door_world = _map_grid.tile_to_world(exit_tile)
		_room_door_world = door_world  # sofort cachen!
		if start_room.has_method("get_room_entry_pos"):
			global_position = start_room.get_room_entry_pos(_map_grid)
		else:
			global_position = door_world
			
		_change_state(State.IN_ROOM)
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
		if avatar.visible and _guest_member.saturation <= 50:
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
		
	# Normaler Gast: POI schließt – zurück ins Zimmer
	if current_state == State.IN_POI and not _is_current_poi_open():
		send_back_to_room()
		return
		
	var speed = 1.0
	if TimeManager:
		if TimeManager.is_paused():
			return # NEU: Nicht ticken, wenn pausiert!
		speed = TimeManager.user_speed
		
	_action_timer -= delta * speed
	if _action_timer <= 0.0:
		if current_state == State.EATING:
			# Aufstehen: Tisch freigeben
			var poi_room_node = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(poi_room_node) and poi_room_node.has_method("leave_seat"):
				poi_room_node.leave_seat(_guest_member.id)
			
			# Der Weg aus dem POI wird nun sauber über local_path_out in _execute_walk animiert!
			if is_instance_valid(_target_room):
				_walk_to_room(_target_room, State.IN_ROOM)
			else:
				_change_state(State.IDLE)
				_action_timer = randf_range(5.0, 15.0)
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
		else:
			_decide_next_action()


# =============================================================================
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
		
		# Kinder dürfen nicht in adults_only POIs
		if def.get("adults_only", false) and _guest_member.is_child:
			continue
		
		var room_id: String = def.get("id", "")
		
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
		
		# min_staff Check: Nur geöffnet wenn genügend Personal zugewiesen ist
		var room_node_id = GuestManager._room_key(room)
		if not StaffManager.is_poi_staffed(def, room_node_id):
			continue
			
		if not open_pois.has(room_id):
			open_pois.append(room_id)
			
	# Vending Machine in Lobby (Level 2+)
	if GameState.get_level() >= 2:
		var can_afford = _guest_member.spending_budget >= 5
		var is_hungry = _guest_member.saturation < 30
		if (is_hungry and can_afford) or _current_poi_id == "vending_machine":
			open_pois.append("vending_machine")
	
	return open_pois


# =============================================================================
func _is_current_poi_open() -> bool:
	if _current_poi_id == "":
		return true # Im Zimmer oder sonst wo, gilt als immer offen
		
	return _get_open_pois().has(_current_poi_id)


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
			_wander_in_room(_target_room, true) # true = force sleep
			return
		else:
			_walk_to_room(_target_room, State.IN_ROOM)
			return
	
	# Kein offener POI? Gast wartet etwas und probiert es später wieder
	if open_pois.is_empty():
		if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING:
			_wander_in_room(_target_room)
			return
		elif current_state != State.WALKING and current_state != State.IDLE:
			_walk_to_room(_target_room, State.IN_ROOM)
			return
		else:
			_action_timer = randf_range(15.0, 45.0)
			return
	
	# Mögliche Ziele: Zimmer + alle offenen POIs
	var possible_targets: Array[String] = ["room"]
	possible_targets.append_array(open_pois)
		
	var chosen: String = possible_targets.pick_random()
	
	# Vermeide, dass der Gast ans selbe Ziel geht wie er schon ist
	if chosen == "room" and (current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING):
		if not open_pois.is_empty() and randf() > 0.3:
			chosen = open_pois.pick_random()
		else:
			_wander_in_room(_target_room)
			return
	elif (current_state == State.IN_POI or current_state == State.EATING) and chosen == _current_poi_id:
		chosen = "room"
	

	
	if chosen == "room" and is_instance_valid(_target_room):
		_walk_to_room(_target_room, State.IN_ROOM)
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
	
	if old_state == State.SITTING or old_state == State.SLEEPING:
		if is_instance_valid(_target_room):
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
			_action_timer = randf_range(15.0, 30.0)
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.IN_POI:
			_action_timer = randf_range(45.0, 120.0)
			avatar.visible = false
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = false
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
				r_name = GameState.T(r.get("name", ""))
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
		if GameState.has_techtree_unlocked("G1.4") and party:
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
				_guest_member.saturation = min(100, _guest_member.saturation + lobby.VENDING_MACHINE_SATURATION)
				
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
	
	var poi_room = _get_poi_room_node(_current_poi_id)
	var party := _get_my_party()
	
	if is_instance_valid(party):
		var bonus = 0
		if income > 0:
			bonus += 2 # Base bonus (war vorher 5, reduziert für Balancing)
			
		if is_instance_valid(poi_room) and poi_room.has_method("has_trait"):
			if poi_room.has_trait("wlan"): bonus += 1
			if poi_room.has_trait("klima"): bonus += 1
			
		if bonus > 0:
			party.modify_satisfaction(bonus)

	# Einnahmen buchen (falls Eintritt/Basis-Kosten existieren)
	if income > 0:
		# Budget abziehen (per Member – jeder hat seinen eigenen Geldbeutel)
		_guest_member.spending_budget = max(0, _guest_member.spending_budget - income)
		
		# Einnahme buchen
		# Einnahme buchen
		FinanceManager.add_transaction(
			income, "gastro",
			"tx.poi_income|" + _guest_member.name + "|" + GameState.T(poi_def.get("name", _current_poi_id))
		)
		
		# FloatingValue Signal senden
		var spawn_pos = global_position
		if is_instance_valid(poi_room):
			var sz = poi_room.call("get_tile_size") if poi_room.has_method("get_tile_size") else Vector2i(1, 1)
			spawn_pos = poi_room.global_position + Vector2(sz.x * 16.0, sz.y * 16.0)
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

	# Nach dem Bezahlen prüfen ob der Raum Sitzplätze hat (Restaurant, Bar etc.)
	var room_node = _get_poi_room_node(_current_poi_id)
	if is_instance_valid(room_node) and room_node.has_method("claim_seat"):
		var seat_pos = room_node.claim_seat(_guest_member.id)
		if seat_pos != Vector2.ZERO:
			# Der Gast "teleportiert" sich auf den Stuhl
			global_position = seat_pos
			_change_state(State.STUDYING_MENU)
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
		
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
		print("[GuestActor] Checkout failed for ", _guest_member.id, ". Path empty from ", start_tile, " to ", exit_tile, ". current_state=", current_state)
		queue_free()
		return
		
	_current_poi_id = "lobby"
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	# Hole Warteposition für den Checkout (lokal in der Lobby)
	var wait_pos = Vector2.INF
	if lobby.has_method("get_checkout_wait_pos"):
		wait_pos = lobby.get_checkout_wait_pos()
		
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
	if current_state == State.IN_POI:
		_walk_to_room(_target_room, State.IN_ROOM)



# =============================================================================
func start_waiting_in_lobby(spawn_pos: Vector2, delay: float) -> void:
	global_position = spawn_pos
	_change_state(State.WALKING)
	
	if delay > 0.0:
		var wait_time = delay
		if TimeManager and not TimeManager.is_paused():
			wait_time = delay / max(1.0, TimeManager.user_speed)
		await get_tree().create_timer(wait_time).timeout
		
	var lobby = _get_lobby_room()
	if is_instance_valid(lobby) and lobby.has_method("get_checkout_wait_pos"):
		var target_world = lobby.get_checkout_wait_pos()
		var offset = Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
		_walk_to_world_pos(target_world + offset, State.WAITING_IN_LINE)

func _walk_to_world_pos(target_pos: Vector2, finish_state: State) -> void:
	if not is_instance_valid(_map_grid):
		return
	_change_state(State.WALKING)
	var start_tile = _get_logical_start_tile()
	var exit_tile = _map_grid.world_to_tile(target_pos)
	var path_tiles: Array[Vector2i] = _map_grid.get_path_between_tiles(start_tile, exit_tile)
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
	var exit_tile = room.get_target_tile(_map_grid)
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
# 		push_warning("[GuestActor] Check-In Pfad nicht gefunden! Start: %s Exit: %s" % [str(start_tile), str(exit_tile)])
		# Notfall-Teleport zur Tür, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(exit_tile)
		_change_state(finish_state)
		return
		
	_change_state(State.WALKING)
		
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
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
# 		push_warning("[GuestActor] Pfad zu POI '%s' nicht gefunden!" % poi_id)
		_action_timer = 5.0
		return
	
	_change_state(State.WALKING)
	_current_poi_id = poi_id
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	var extra_pos = Vector2.INF
	if poi_id == "vending_machine" and target_room.has_method("get_vending_target_world"):
		extra_pos = target_room.get_vending_target_world()
		
	_execute_walk(path_tiles, State.IN_POI, door_world, extra_pos, target_room)



# =============================================================================
func _walk_to_exit() -> void:
	var lobby = _get_lobby_room()
	if not is_instance_valid(lobby):
		queue_free()
		return
		
	var exit_tile = lobby.get_street_tile(_map_grid)
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	# _execute_walk wird automatisch den local_path_out der Lobby nutzen,
	# da der Gast sich im Status AWAITING_CHECKOUT befindet!
	_execute_walk([] as Array[Vector2i], State.LEAVING, door_world, Vector2.INF, lobby)


# =============================================================================
func _execute_walk(path_tiles: Array[Vector2i], finish_state: State, face_pos: Vector2, extra_target_pos: Vector2 = Vector2.INF, target_room: Node2D = null) -> void:
	var world_path: Array[Vector2] = []
	
	# NEU: Animierter "Walk out of Room", statt Teleportation
	# Nur nach draußen laufen, wenn wir auch wirklich den Raum verlassen (path_tiles > 0) ODER das Hotel verlassen
	if path_tiles.size() > 0 or finish_state == State.LEAVING:
		if (previous_state == State.IN_ROOM or previous_state == State.SITTING or previous_state == State.SLEEPING) and is_instance_valid(_target_room):
			if _target_room.has_method("get_local_path") and _target_room.has_method("get_room_entry_pos"):
				var entry_pos = _target_room.get_room_entry_pos(_map_grid)
				var local_path_out = _target_room.get_local_path(global_position, entry_pos)
				world_path.append_array(local_path_out)
		elif (previous_state == State.IN_POI or previous_state == State.AWAITING_CHECKOUT or previous_state == State.EATING) and not _current_poi_id.is_empty():
			var poi_room = _get_poi_room_node(_current_poi_id)
			if is_instance_valid(poi_room) and poi_room.has_method("get_local_path") and poi_room.has_method("get_room_entry_pos"):
				var entry_pos = poi_room.get_room_entry_pos(_map_grid)
				
				# Wenn wir das Hotel verlassen, gehen wir zum Haupteingang statt zur Innentür!
				if finish_state == State.LEAVING and _current_poi_id == "lobby":
					entry_pos = face_pos
					
				var local_path_out = poi_room.get_local_path(global_position, entry_pos)
				world_path.append_array(local_path_out)
				print("[GuestActor] Generated local_path_out from POI: ", local_path_out.size(), " points. poi_id=", _current_poi_id)
			else:
				print("[GuestActor] POI Room invalid or missing methods! poi_id=", _current_poi_id)
		else:
			print("[GuestActor] Skipped local_path_out. prev_state=", previous_state, " poi_id=", _current_poi_id)
			
	if _map_grid and "is_miniature" in _map_grid and not _map_grid.is_miniature:
		_map_grid._debug_paths.append(path_tiles)
			
	var door_index_out := -1
	if world_path.size() > 0:
		door_index_out = world_path.size() - 1

	for tile in path_tiles:
		world_path.append(_map_grid.tile_to_world(tile))
		
	var door_index_in := -1
	if extra_target_pos != Vector2.INF:
		door_index_in = world_path.size() - 1
		if is_instance_valid(target_room) and target_room.has_method("get_local_path"):
			var local_path = target_room.get_local_path(face_pos, extra_target_pos)
			world_path.append_array(local_path)
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
			_map_grid._debug_paths.erase(path_tiles)
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
	if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING or current_state == State.IDLE:
		if _room_door_world != Vector2.INF:
			return _map_grid.world_to_tile(_room_door_world)
		elif is_instance_valid(_target_room):
			var t_exit_tile = _get_room_exit_tile(_target_room)
			_room_door_world = _map_grid.tile_to_world(t_exit_tile)
			return t_exit_tile
	elif (current_state == State.IN_POI or current_state == State.EATING) and not _current_poi_id.is_empty():
		var poi_room = _get_poi_room_node(_current_poi_id)
		if is_instance_valid(poi_room) and poi_room.has_method("get_target_tile"):
			return poi_room.get_target_tile(_map_grid)
	
	return _get_current_tile()

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
	if not is_instance_valid(room):
		_action_timer = 5.0
		return
		
	var target = Vector2.INF
	var next_state = State.IN_ROOM
	
	if force_sleep:
		if room.has_method("has_free_room_bed") and room.has_free_room_bed():
			target = room.room_claim_bed(_guest_member.id)
			next_state = State.SLEEPING
	else:
		var r = randf()
		if r < 0.1 and room.has_method("has_free_room_bed") and room.has_free_room_bed():
			target = room.room_claim_bed(_guest_member.id)
			next_state = State.SLEEPING
		elif r < 0.5 and room.has_method("has_free_room_seat") and room.has_free_room_seat():
			target = room.room_claim_seat(_guest_member.id)
			next_state = State.SITTING
			
	if target == Vector2.INF and room.has_method("get_random_walkable_local_pos"):
		target = room.get_random_walkable_local_pos()
		next_state = State.IN_ROOM
		
	if target == Vector2.INF:
		_action_timer = randf_range(10.0, 30.0)
		return
		
	var local_path = []
	if room.has_method("get_local_path"):
		local_path = room.get_local_path(global_position, target)
		
	if local_path.is_empty():
		local_path.append(target)
		
	_change_state(State.WALKING)
	
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	_active_tween = create_tween()
	
	if TimeManager:
		if not TimeManager.is_paused():
			_active_tween.set_speed_scale(TimeManager.user_speed)
		else:
			_active_tween.set_speed_scale(0.0)
			
	var current_pos = global_position
	_active_tween.tween_interval(1.0)
	
	for point in local_path:
		var dist = current_pos.distance_to(point)
		var duration = dist / _base_speed
		_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(point))
		_active_tween.tween_property(self, "global_position", point, duration)
		current_pos = point
		
	_active_tween.tween_callback(func(): 
		if next_state == State.SLEEPING or next_state == State.SITTING:
			avatar.rotation = 0
			if next_state == State.SITTING and is_instance_valid(_target_room):
				# Table suchen
				var table = _target_room.get_node_or_null("%Table")
				if not table:
					table = _target_room.get_node_or_null("Interior/Furniture/Table")
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
