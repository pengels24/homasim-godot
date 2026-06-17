extends Node2D
class_name GuestActor

# --- Zustände ---
enum State { IDLE, WALKING, IN_ROOM, IN_LOBBY, IN_BAR, LEAVING }

var current_state: State = State.IDLE
var _guest_member: GuestMember
var _map_grid: Node # MapGrid Referenz
var _target_room: Node2D = null

# Interner Timer für Aufenthaltsdauer
var _action_timer: float = 0.0
var _base_speed: float = 40.0
var _current_path: Array[Vector2i] = []
var _active_tween: Tween

@onready var avatar: Node2D = $GuestAvatar

# =============================================================================
func setup(member: GuestMember, map_grid: Node, start_room: Node2D = null) -> void:
	_guest_member = member
	_map_grid = map_grid
	
	avatar.setup(member)
	_base_speed = max(10.0, 40.0 + member.speed_offset)
	
	if start_room != null:
		# Wenn mit Startraum gespawnt (z.B. nach Laden), setze Position auf die Zimmertür!
		_target_room = start_room
		var exit_tile = _get_room_exit_tile(start_room)
		global_position = _map_grid.tile_to_world(exit_tile)
		_change_state(State.IN_ROOM)
	else:
		_change_state(State.IDLE)
		
	TimeManager.sig_speed_changed.connect(_on_time_speed_changed)


# =============================================================================
func _process(delta: float) -> void:
	match current_state:
		State.IN_ROOM, State.IN_LOBBY, State.IN_BAR:
			_process_waiting(delta)


# =============================================================================
func _process_waiting(delta: float) -> void:
	var speed = 1.0
	if TimeManager and not TimeManager._game_paused:
		speed = TimeManager._game_speed
		
	_action_timer -= delta * speed
	if _action_timer <= 0.0:
		_decide_next_action()


# =============================================================================
func _decide_next_action() -> void:
	if current_state == State.LEAVING:
		return
		
	var possible_targets = ["room", "lobby"]
	var chosen = possible_targets.pick_random()
	
	if chosen == "room" and current_state == State.IN_ROOM:
		chosen = "lobby"
	elif chosen == "lobby" and current_state == State.IN_LOBBY:
		chosen = "room"
		
	print("[GuestActor] Action Timer abgelaufen! Wähle neues Ziel: ", chosen, " (Aktueller Zustand: ", current_state, ")")
		
	if chosen == "room" and is_instance_valid(_target_room):
		_walk_to_room(_target_room, State.IN_ROOM)
	elif chosen == "lobby":
		_walk_to_lobby()


# =============================================================================
func _change_state(new_state: State) -> void:
	current_state = new_state
	match current_state:
		State.IN_ROOM, State.IN_LOBBY, State.IN_BAR:
			# Aufenthaltsdauer
			_action_timer = randf_range(45.0, 120.0)
			avatar.visible = false # In den Räumen/Lobby unsichtbar
		State.WALKING, State.LEAVING:
			avatar.visible = true


# =============================================================================
func start_checkout() -> void:
	_change_state(State.LEAVING)
	_walk_to_exit()


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
	var exit_tile = _get_room_exit_tile(room)
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, exit_tile)
	if path_tiles.is_empty():
		print("GuestActor: Check-In Pfad nicht gefunden! Start: ", start_tile, " Exit: ", exit_tile)
		# Notfall-Teleport zur Tür, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(exit_tile)
		_change_state(finish_state)
		return
		
	_change_state(State.WALKING)
	var door_world = _map_grid.tile_to_world(exit_tile)
	_execute_walk(path_tiles, finish_state, door_world)


# =============================================================================
func _walk_to_lobby() -> void:
	var start_tile = _get_current_tile()
	var lobby_tile = _get_lobby_tile()
	
	var path_tiles = _map_grid.get_path_between_tiles(start_tile, lobby_tile)
	if path_tiles.is_empty():
		print("GuestActor: Pfad zur Lobby nicht gefunden! Start: ", start_tile, " Lobby: ", lobby_tile)
		# Notfall-Teleport zur Lobby, damit der nächste Pfad-Versuch funktioniert
		global_position = _map_grid.tile_to_world(lobby_tile)
		_change_state(State.IN_LOBBY)
		return
		
	_change_state(State.WALKING)
	var door_world = _map_grid.tile_to_world(lobby_tile)
	_execute_walk(path_tiles, State.IN_LOBBY, door_world)


# =============================================================================
func _walk_to_exit() -> void:
	var lt = _get_lobby_tile()
	var entry_parcel: Node2D = _map_grid._grid[_map_grid._entry_plot.y][_map_grid._entry_plot.x]
	
	var exit_x: int = lt.x
	var exit_y: int = lt.y
	var way_1 := Vector2i(lt.x, lt.y)
	var way_2 := Vector2i(lt.x, lt.y)
	
	match entry_parcel.entrance_dir:
		"top":
			exit_y = _map_grid._entry_plot.y * _map_grid.PARCEL_SZ
			way_1 = Vector2i(lt.x - 2, lt.y)
			way_2 = Vector2i(lt.x - 2, exit_y + 1)
		"bottom":
			exit_y = (_map_grid._entry_plot.y + 1) * _map_grid.PARCEL_SZ - 1
			way_1 = Vector2i(lt.x - 2, lt.y)
			way_2 = Vector2i(lt.x - 2, exit_y - 1)
		"left":
			exit_x = _map_grid._entry_plot.x * _map_grid.PARCEL_SZ
			way_1 = Vector2i(lt.x, lt.y - 2)
			way_2 = Vector2i(exit_x + 1, lt.y - 2)
		"right":
			exit_x = (_map_grid._entry_plot.x + 1) * _map_grid.PARCEL_SZ - 1
			way_1 = Vector2i(lt.x, lt.y - 2)
			way_2 = Vector2i(exit_x - 1, lt.y - 2)
			
	var exit_tile := Vector2i(exit_x, exit_y)
	
	var path_tiles = _map_grid.get_path_between_tiles(_get_current_tile(), lt)
	if path_tiles.is_empty():
		# Falls kein Weg zur Lobby gefunden wird, verschwinden sie einfach sofort
		queue_free()
		return
		
	# Füge die manuellen Wegpunkte zum Verlassen der Lobby an
	path_tiles.append(way_1)
	path_tiles.append(way_2)
	path_tiles.append(exit_tile)
		
	var door_world = _map_grid.tile_to_world(exit_tile)
	_execute_walk(path_tiles, State.LEAVING, door_world)


# =============================================================================
func _execute_walk(path_tiles: Array[Vector2i], finish_state: State, face_pos: Vector2) -> void:
	var world_path: Array[Vector2] = []
	for tile in path_tiles:
		world_path.append(_map_grid.tile_to_world(tile))
		
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
		
	_active_tween = create_tween()
	
	if TimeManager and not TimeManager._game_paused:
		_active_tween.set_speed_scale(TimeManager._game_speed)
		
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


