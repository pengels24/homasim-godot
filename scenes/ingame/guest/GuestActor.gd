extends Node2D
class_name GuestActor

# --- Zustände ---
enum State { IDLE, WALKING, IN_ROOM, IN_POI, AWAITING_CHECKOUT, LEAVING }

var current_state: State = State.IDLE
var _guest_member: GuestMember
var _map_grid: Node # MapGrid Referenz
var _guest_manager: GuestManager = null  # Referenz für Budget & POI-Tracking
var _target_room: Node2D = null

var _room_door_world: Vector2 = Vector2.INF

## Verhindert, dass wake_up() den Checkout-Lauf überschreibt
var _is_checkout_walk: bool = false

## Welcher POI aktuell besucht wird (z.B. "lobby", "bar", "spa")
var _current_poi_id: String = ""

# Interner Timer für Aufenthaltsdauer
var _action_timer: float = 0.0
var _base_speed: float = 40.0

var _active_tween: Tween

signal sig_poi_income(amount: int, world_pos: Vector2)

@onready var avatar: Node2D = $GuestAvatar

# =============================================================================
func setup(member: GuestMember, map_grid: Node, start_room: Node2D = null, guest_manager: GuestManager = null) -> void:
	_guest_member = member
	_map_grid = map_grid
	_guest_manager = guest_manager
	
	avatar.setup(member)
	_base_speed = max(10.0, 40.0 + member.speed_offset)
	
	if start_room != null:
		# Wenn mit Startraum gespawnt (z.B. nach Laden), setze Position auf die Zimmertür!
		_target_room = start_room
		var exit_tile = _get_room_exit_tile(start_room)
		var door_world = _map_grid.tile_to_world(exit_tile)
		global_position = door_world
		_room_door_world = door_world  # sofort cachen!
		_change_state(State.IN_ROOM)
	else:
		_change_state(State.IDLE)
		
	TimeManager.sig_speed_changed.connect(_on_time_speed_changed)
	TimeManager.sig_morning_struck.connect(wake_up)
	
	if has_node("ClickArea"):
		var ca = get_node("ClickArea")
		ca.process_mode = Node.PROCESS_MODE_ALWAYS
		if not ca.input_event.is_connected(_on_click_area_input_event):
			ca.input_event.connect(_on_click_area_input_event)

# =============================================================================
func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameState.sig_guest_clicked.emit(self)


# =============================================================================
func _process(delta: float) -> void:
	match current_state:
		State.IN_ROOM, State.IN_POI:
			_process_waiting(delta)


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
		speed = TimeManager._game_speed
		
	_action_timer -= delta * speed
	if _action_timer <= 0.0:
		_decide_next_action()


# =============================================================================
func _get_open_pois() -> Array[String]:
	## Gibt alle POI-Typen zurück, die aktuell geöffnet haben.
	## Nutzt open_from / open_to aus der Raumdefinition (Minuten seit Mitternacht).
	var open_pois: Array[String] = []
	var now := TimeManager.get_game_time() if TimeManager else 600
	
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
		
		# Kinder dürfen nicht in adults_only POIs
		if def.get("adults_only", false) and _guest_member.is_child:
			continue
		
		var from: int = def.get("open_from", 0)
		var to: int = def.get("open_to", 0)
		var room_id: String = def.get("id", "")
		
		# Geöffnungszeiten prüfen
		if not (now >= from and now < to):
			continue
		
		# min_staff Check: Nur geöffnet wenn genügend Personal zugewiesen ist
		var room_node_id = GuestManager._room_key(room)
		if not StaffManager.is_poi_staffed(def, room_node_id):
			continue
			
		if not open_pois.has(room_id):
			open_pois.append(room_id)
	
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
	
	var open_pois := _get_open_pois()
	
	# Kein offener POI? Gast wartet etwas und probiert es später wieder
	if open_pois.is_empty():
		_action_timer = randf_range(15.0, 45.0)
		return
	
	# Mögliche Ziele: Zimmer + alle offenen POIs
	var possible_targets: Array[String] = ["room"]
	possible_targets.append_array(open_pois)
		
	var chosen: String = possible_targets.pick_random()
	
	# Vermeide, dass der Gast ans selbe Ziel geht wie er schon ist
	if chosen == "room" and current_state == State.IN_ROOM:
		chosen = open_pois.pick_random() if not open_pois.is_empty() else "room"
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
	current_state = new_state
	
	if old_state == State.IN_ROOM and (current_state == State.WALKING or current_state == State.LEAVING):
		SoundManager.play("door_close")
	elif current_state == State.IN_ROOM and (old_state == State.WALKING or old_state == State.IDLE):
		SoundManager.play("door_close")
	
	# POI-Ankunft: Einnahmen & Boost verarbeiten
	if new_state == State.IN_POI:
		_on_poi_arrived()
	
	match current_state:
		State.IN_ROOM, State.IN_POI:
			_action_timer = randf_range(45.0, 120.0)
			avatar.visible = false
		State.AWAITING_CHECKOUT:
			# Unsichtbar am Schalter warten – kein Timer, Spieler löst aus
			_action_timer = 0.0
			avatar.visible = false
		State.WALKING, State.LEAVING:
			avatar.visible = true


# =============================================================================
## Verarbeitet die Ankunft in einem POI: Einnahmen buchen, Budget abziehen, Zufriedenheit boosten.
func _on_poi_arrived() -> void:
	if _current_poi_id.is_empty() or _current_poi_id == "lobby":
		return
	
	var poi_def = _get_poi_def(_current_poi_id)
	var income: int = poi_def.get("visit_income", 0)
	if income <= 0:
		return
	
	# Budget abziehen (per Member – jeder hat seinen eigenen Geldbeutel)
	_guest_member.spending_budget = max(0, _guest_member.spending_budget - income)
	# Zufriedenheits-Boost für diesen Member
	var party := _get_my_party()
	if is_instance_valid(party):
		party.satisfaction = min(100, party.satisfaction + 5)
	
	# Einnahme buchen
	var room_id = _get_poi_room_id(_current_poi_id)
	FinanceManager.add_transaction(
		income, "gastro",
		"%s – Besuch: %s" % [GameState.T(poi_def.get("name", _current_poi_id)), _guest_member.name]
	)
	
	# FloatingValue Signal senden (GuestController leitet weiter)
	sig_poi_income.emit(income, global_position)
	
	# GuestManager über Besuch informieren (für Warenverbrauch-Tracking)
	if is_instance_valid(_guest_manager):
		_guest_manager.on_poi_visited(room_id)


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
	
	# Lobby bereits offen? → direkt zum Ausgang
	if _get_open_pois().has("lobby"):
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
		if TimeManager and not TimeManager._game_paused:
			wait_time = delay / max(1.0, TimeManager._game_speed)
		await get_tree().create_timer(wait_time).timeout
	
	_walk_to_room(room, State.IN_ROOM)


# =============================================================================
func _walk_to_room(room: Node2D, finish_state: State) -> void:
	if not is_instance_valid(room):
		_decide_next_action()
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
		
	_execute_walk(path_tiles, finish_state, door_world, extra_pos)


## Generischer Walk zu einem beliebigen POI (Bar, Spa, Restaurant, Lobby ...)
## poi_id muss mit der "id" in der Raumdefinition übereinstimmen (oder "lobby")
func _walk_to_poi(poi_id: String) -> void:
	# Budget-Check: Hat der Gast genügend Taschengeld für diesen Besuch?
	if poi_id != "lobby":
		var poi_def = _get_poi_def(poi_id)
		var income: int = poi_def.get("visit_income", 0)
		if income > 0 and _guest_member.spending_budget < income:
			# Kein Geld mehr für diesen POI – andere Aktion wählen
			_decide_next_action()
			return
	
	var exit_tile: Vector2i
	
	if poi_id == "lobby":
		exit_tile = _get_lobby_tile()
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
			_decide_next_action()
			return
			
		exit_tile = poi_room.get_target_tile(_map_grid)
	
	# Start-Tile berechnen (gecachte Türposition verwenden!)
	var start_tile: Vector2i
	if current_state == State.IN_ROOM:
		if _room_door_world != Vector2.INF:
			global_position = _room_door_world
			start_tile = _get_current_tile()
		elif is_instance_valid(_target_room):
			var t_exit_tile = _get_room_exit_tile(_target_room)
			_room_door_world = _map_grid.tile_to_world(t_exit_tile)
			global_position = _room_door_world
			start_tile = t_exit_tile
		else:
			start_tile = _get_current_tile()
	else:
		start_tile = _get_current_tile()
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
# 		push_warning("[GuestActor] Pfad zu POI '%s' nicht gefunden!" % poi_id)
		_decide_next_action()
		return
	
	_change_state(State.WALKING)
	_current_poi_id = poi_id
	var door_world = _map_grid.tile_to_world(exit_tile)
	_execute_walk(path_tiles, State.IN_POI, door_world)



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
	
	# Nur aus dem Zimmer heraus die gecachte Türposition setzen.
	# Bei complete_checkout() ist der Gast bereits an der Lobby – NICHT überschreiben!
	if current_state != State.LEAVING and _room_door_world != Vector2.INF:
		global_position = _room_door_world
	
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
func _execute_walk(path_tiles: Array[Vector2i], finish_state: State, face_pos: Vector2, extra_target_pos: Vector2 = Vector2.INF) -> void:
	var world_path: Array[Vector2] = []
	for tile in path_tiles:
		world_path.append(_map_grid.tile_to_world(tile))
		
	if extra_target_pos != Vector2.INF:
		world_path.append(extra_target_pos)
		
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	_active_tween = create_tween()
	
	if TimeManager:
		if not TimeManager._game_paused:
			_active_tween.set_speed_scale(TimeManager._game_speed)
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

func _get_room_exit_tile(room: Node2D) -> Vector2i:
	var sz: Vector2i = room.get_tile_size()
	var rot: int = room.get("door_rotation")
	var off: int = room.get("door_offset")
	var tx: int = int(room.position.x / _map_grid.TILE_PX)
	var ty: int = int(room.position.y / _map_grid.TILE_PX)
	var px: int = int(room.get_parent().name.split("_")[1])
	var py: int = int(room.get_parent().name.split("_")[2])
	return _map_grid._exit_global(px, py, tx, ty, sz.x, sz.y, rot, off)


