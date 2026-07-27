extends Node2D
class_name GuestActor

# --- Zustände ---
enum State { IDLE, WALKING, IN_ROOM, IN_POI, AWAITING_CHECKOUT, LEAVING, STUDYING_MENU, WAITING_FOR_FOOD, EATING, SITTING, SLEEPING }

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
	if has_node("HungryIcon"):
		if avatar.visible and _guest_member.saturation <= 50:
			$HungryIcon.visible = true
		else:
			$HungryIcon.visible = false

	match current_state:
		State.IN_ROOM, State.IN_POI, State.STUDYING_MENU, State.EATING, State.IDLE, State.SITTING, State.SLEEPING:
			_process_waiting(delta)
		State.WAITING_FOR_FOOD, State.AWAITING_CHECKOUT:
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
			
			# Gast steht mitten im Restaurant → zuerst auf das Exit-Tile des POI setzen,
			# damit AStar einen gültigen Startpunkt hat (wie beim Verlassen des Zimmers)
			if is_instance_valid(poi_room_node) and poi_room_node.has_method("get_target_tile"):
				var poi_exit_tile = poi_room_node.get_target_tile(_map_grid)
				global_position = _map_grid.tile_to_world(poi_exit_tile)
			
			_current_poi_id = "" # POI verlassen, bevor der Walk startet
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
	elif current_state == State.IN_POI and chosen == _current_poi_id:
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
	
	if current_state == State.LEAVING or current_state == State.AWAITING_CHECKOUT:
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
	
	if old_state == State.IN_ROOM and (current_state == State.WALKING or current_state == State.LEAVING):
		SoundManager.play("door_close")
	elif current_state == State.IN_ROOM and (old_state == State.WALKING or old_state == State.IDLE):
		SoundManager.play("door_close")
	
	# POI-Ankunft: Einnahmen & Boost verarbeiten
	if new_state == State.IN_POI:
		_on_poi_arrived()
	
	match current_state:
		State.IN_ROOM:
			_wander_in_room(_target_room, false, true) # sofort loslaufen, aber Initial-Timer setzen
			avatar.visible = true
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = true
		State.IN_POI:
			_action_timer = randf_range(45.0, 120.0)
			avatar.visible = false
			if has_node("ClickArea"): get_node("ClickArea").input_pickable = false
		State.AWAITING_CHECKOUT:
			# Unsichtbar am Schalter warten – kein Timer, Spieler löst aus
			_action_timer = 0.0
			avatar.visible = false
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
				var start_tile = _get_current_tile()
				var end_tile = _map_grid.world_to_tile(target_pos)
				var path = _map_grid.get_path_between_tiles(start_tile, end_tile)
				
				if path.is_empty():
					# Fallback: Nur lokaler Schritt
					var local_step = Vector2(randf_range(-5.0, -1.0), randf_range(-25.0, -10.0))
					target_pos = global_position + local_step.rotated(avatar.rotation)
					_change_state(State.EATING)
					if _active_tween and _active_tween.is_valid():
						_active_tween.kill()
					_active_tween = create_tween()
					_active_tween.tween_property(self, "global_position", target_pos, 0.5)
				else:
					_change_state(State.WALKING)
					_execute_walk(path, State.EATING, target_pos, target_pos)
				
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
	_change_state(State.WALKING)  # sichtbar machen
	
	# Startposition: immer von der Zimmertür (nie aus SOLID-Tile)
	if _room_door_world != Vector2.INF:
		global_position = _room_door_world
	elif is_instance_valid(_target_room):
		var exit_tile = _get_room_exit_tile(_target_room)
		_room_door_world = _map_grid.tile_to_world(exit_tile)
		global_position = _room_door_world
	
	# Lobby-Rezeption bereits offen? → direkt zum Ausgang
	var reception_open = false
	var lobby_def = _get_poi_def("lobby")
	if not lobby_def.is_empty():
		var time = GameState.get_time_in_minutes()
		var r_from = lobby_def.get("reception_open_from", 420)
		var r_to = lobby_def.get("reception_open_to", 1320)
		if time >= r_from and time < r_to:
			reception_open = true

	if reception_open:
		_walk_to_exit()
	else:
		# Zur Lobby laufen – dort unsichtbar auf Spieler-Checkout warten
		var start_tile = _get_current_tile()
		var lobby_tile = _get_lobby_tile()
		var path_tiles = _map_grid.get_path_between_tiles(start_tile, lobby_tile)
		if path_tiles.is_empty():
# 			push_warning("[GuestActor] Kein Pfad zur Lobby für Checkout!")
			queue_free()
			return
		var lobby_world = _map_grid.tile_to_world(lobby_tile)
		_current_poi_id = "lobby"
		_execute_walk(path_tiles, State.AWAITING_CHECKOUT, lobby_world)


# =============================================================================
## Spieler hat Checkout bestätigt: Gast erscheint an der Lobby und läuft raus.
func complete_checkout(spawn_pos: Vector2) -> void:
	global_position = spawn_pos  # vor Lobby-Eingang erscheinen
	_change_state(State.LEAVING)  # sichtbar
	_walk_to_exit()


# =============================================================================
## Wird um 22:00 Uhr aufgerufen: Gast kehrt aus POI ins Zimmer zurück
func send_back_to_room() -> void:
	if current_state == State.IN_POI:
		_walk_to_room(_target_room, State.IN_ROOM)



# =============================================================================
func start_checkin(room: Node2D, spawn_pos: Vector2, delay: float) -> void:
	_target_room = room
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
		
	var start_tile = _get_current_tile()
	var exit_tile = room.get_target_tile(_map_grid)
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
# 		push_warning("[GuestActor] Check-In Pfad nicht gefunden! Start: %s Exit: %s" % [str(start_tile), str(exit_tile)])
		# Notfall-Teleport zur Tür, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(exit_tile)
		_change_state(finish_state)
		return
		
	_change_state(State.WALKING)
	if finish_state == State.IN_ROOM:
		_current_poi_id = "" # Ziel ist das Zimmer, nicht mehr der alte POI
		
	var door_world = _map_grid.tile_to_world(exit_tile)
	# Tür-Position fürs Zielzimmer cachen (erstmalig oder bei Zimmerwechsel)
	if finish_state == State.IN_ROOM:
		_room_door_world = door_world
		
	var extra_pos = Vector2.INF
	if room.has_method("get_room_entry_pos"):
		extra_pos = room.get_room_entry_pos(_map_grid)
		
	_execute_walk(path_tiles, finish_state, door_world, extra_pos, room)


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
	
	var exit_tile: Vector2i
	
	if poi_id == "lobby":
		exit_tile = _get_lobby_tile()
	elif poi_id == "vending_machine":
		exit_tile = _get_vending_tile()
	else:
		var poi_room: Node2D = null
		for room in _map_grid.active_rooms:
			if not is_instance_valid(room): continue
			var def = room.call("get_definition")
			if def.get("id", "") == poi_id:
				poi_room = room
				break
		
		if not is_instance_valid(poi_room):
# 			push_warning("[GuestActor] POI '%s' nicht gefunden!" % poi_id)
			_action_timer = 5.0
			return
			
		exit_tile = poi_room.get_target_tile(_map_grid)
	
	# Start-Tile berechnen (gecachte Türposition verwenden!)
	var start_tile: Vector2i
	if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING:
		if _room_door_world != Vector2.INF:
			start_tile = _map_grid.world_to_tile(_room_door_world)
		elif is_instance_valid(_target_room):
			var t_exit_tile = _get_room_exit_tile(_target_room)
			_room_door_world = _map_grid.tile_to_world(t_exit_tile)
			start_tile = t_exit_tile
		else:
			start_tile = _get_current_tile()
	else:
		start_tile = _get_current_tile()
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
# 		push_warning("[GuestActor] Pfad zu POI '%s' nicht gefunden!" % poi_id)
		_action_timer = 5.0
		return
	
	_change_state(State.WALKING)
	_current_poi_id = poi_id
	var door_world = _map_grid.tile_to_world(exit_tile)
	
	var target_room = null
	if poi_id == "lobby" or poi_id == "vending_machine":
		target_room = _get_lobby_room()
	else:
		for r in _map_grid.active_rooms:
			if is_instance_valid(r) and r.call("get_definition").get("id", "") == poi_id:
				target_room = r
				break
				
	_execute_walk(path_tiles, State.IN_POI, door_world, Vector2.INF, target_room)



# =============================================================================
func _walk_to_exit() -> void:
	var lt = _get_lobby_tile()
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	
	var exit_x: int = lt.x - 1
	var exit_y: int = lt.y
	
	match entry_parcel.entrance_dir:
		"top":
			exit_y = _map_grid._entry_plot.y * _map_grid.PARCEL_SZ
		"bottom":
			exit_y = (_map_grid._entry_plot.y + 1) * _map_grid.PARCEL_SZ - 1
		"left":
			exit_x = _map_grid._entry_plot.x * _map_grid.PARCEL_SZ
			exit_y = lt.y - 1
		"right":
			exit_x = (_map_grid._entry_plot.x + 1) * _map_grid.PARCEL_SZ - 1
			exit_y = lt.y - 1
			
	var exit_tile := Vector2i(exit_x, exit_y)
	
	# Da die Lobby nun ins AStar-Grid eingebunden ist (Clearance = 4, Hindernisse = 1),
	# findet get_path_between_tiles selbstständig einen Weg um Tische herum.
	var path_tiles = _map_grid.get_path_between_tiles(_get_current_tile(), exit_tile)
	if path_tiles.is_empty():
		# Falls kein Weg gefunden wird, verschwinden sie einfach sofort
		queue_free()
		return
		
	var door_world = _map_grid.tile_to_world(exit_tile)
	_execute_walk(path_tiles, State.LEAVING, door_world)


# =============================================================================
func _execute_walk(path_tiles: Array[Vector2i], finish_state: State, face_pos: Vector2, extra_target_pos: Vector2 = Vector2.INF, target_room: Node2D = null) -> void:
	var world_path: Array[Vector2] = []
	
	# NEU: Animierter "Walk out of Room", statt Teleportation
	# Wenn wir aktuell (oder kurz davor) im Zimmer (oder an einem Sitzplatz) sind, berechnen wir zuerst den lokalen Pfad zur Tür!
	if (previous_state == State.IN_ROOM or previous_state == State.SITTING or previous_state == State.SLEEPING) and is_instance_valid(_target_room):
		if _target_room.has_method("get_local_path") and _target_room.has_method("get_room_entry_pos"):
			var entry_pos = _target_room.get_room_entry_pos(_map_grid)
			var local_path_out = _target_room.get_local_path(global_position, entry_pos)
			world_path.append_array(local_path_out)
			
	for tile in path_tiles:
		world_path.append(_map_grid.tile_to_world(tile))
		
	if extra_target_pos != Vector2.INF:
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
	
	for point in world_path:
		var dist = current_pos.distance_to(point)
		var duration = dist / _base_speed
		
		_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(point))
		_active_tween.tween_property(self, "global_position", point, duration)
		current_pos = point
		
	_active_tween.tween_callback(func(): avatar.rotation = global_position.angle_to_point(face_pos))
	_active_tween.tween_interval(0.3)
	
	if finish_state == State.LEAVING:
		_active_tween.tween_property(self, "modulate:a", 0.0, 0.4)
		_active_tween.tween_callback(queue_free)
	else:
		_active_tween.tween_callback(func(): _change_state(finish_state))


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

func _get_current_tile() -> Vector2i:
	return _map_grid.world_to_tile(global_position)

func _get_lobby_tile() -> Vector2i:
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	var clearance: Rect2i = entry_parcel.get_lobby_clearance_rect()
	var lx: int = int(_map_grid._entry_plot.x * _map_grid.PARCEL_SZ) + clearance.position.x + int(clearance.size.x / 2.0)
	var ly: int = int(_map_grid._entry_plot.y * _map_grid.PARCEL_SZ) + clearance.position.y + int(clearance.size.y / 2.0)
	return Vector2i(lx, ly)

func _get_vending_tile() -> Vector2i:
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	if entry_parcel and entry_parcel.has_method("get_lobby"):
		var lobby = entry_parcel.get_lobby()
		if is_instance_valid(lobby) and lobby.has_method("get_vending_target"):
			return lobby.get_vending_target(_map_grid)
	return _get_lobby_tile()

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
