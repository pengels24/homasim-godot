extends Node2D
class_name StaffActor

@onready var _sprite: Sprite2D = $Sprite2D

var _staff_data: Dictionary
var _map_grid: Node2D
var _controller: Node

var _current_task: Dictionary = {}
var _state: String = "idle" # idle, walking, working, returning
var _work_timer: float = 0.0
var _work_timer_max: float = 20.0
var _think_timer: float = 0.0

var _path: Array[Vector2i] = []
var _target_world_pos: Vector2 = Vector2.ZERO
var _room_entry_pos: Vector2 = Vector2.INF
var _current_room: Node2D = null

var _debug_line: Line2D

const SPEED := 40.0

func _ready() -> void:
	pass
	#_debug_line = Line2D.new()
	#_debug_line.top_level = true
	#_debug_line.width = 4.0
	#_debug_line.default_color = Color(1, 0, 0, 0.5)
	#_debug_line.z_index = 100
	#add_child(_debug_line)

func configure(staff_data: Dictionary, map_grid: Node2D, controller: Node) -> void:
	_staff_data = staff_data
	_map_grid = map_grid
	_controller = controller
	
	# Grafiken setzen basierend auf Beruf und Geschlecht
	var job = _staff_data.get("role", "housekeeping")
	var gender = _staff_data.get("gender", "female")
	
	var texture_path = "res://assets/staff/staff_avatar_%s_%s.aseprite" % [gender, job]
	if ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		if tex and tex is Texture2D:
			_sprite.texture = tex
	else:
		print("[StaffActor] Warnung: Aseprite %s nicht gefunden!" % texture_path)
	
	# Solange kein Personalraum, warten MA unsichtbar in der Lobby
	_sprite.visible = false

func get_staff_id() -> String:
	return str(_staff_data.get("id", ""))

func get_job_type() -> String:
	return str(_staff_data.get("role", "housekeeping"))

func despawn() -> void:
	if not _current_task.is_empty():
		# Ticket zurückgeben ans Schwarze Brett
		_current_task["status"] = "open"
		_current_task["assigned_to"] = null
		print("[StaffActor] %s hat Ticket %s abgebrochen wegen Kündigung." % [_staff_data.get("name"), _current_task.get("id")])
	queue_free()

func _physics_process(delta: float) -> void:
	if TimeManager.is_paused():
		return
		
	var speed_mult = TimeManager._game_speed
	var actual_speed = SPEED * speed_mult
	
	# Denkpause
	if _think_timer > 0.0:
		_think_timer -= delta * speed_mult
		if _think_timer > 0.0:
			return
	
	match _state:
		"idle":
			_process_idle()
		"walking":
			_process_walking(delta, actual_speed)
		"working":
			_process_working(delta, speed_mult)
		"returning":
			_process_walking(delta, actual_speed)

func _process_idle() -> void:
	if is_instance_valid(_debug_line): _debug_line.points = []
	if not _current_task.is_empty():
		return # Mache schon was
		
	var my_job = get_job_type()
	var tasks = TaskManager._tasks
	
	for t in tasks:
		if t.status == "open":
			var is_match = false
			if my_job == "housekeeping" and t.type == "clean_room": is_match = true
			if my_job == "maintenance" and t.type == "repair_room": is_match = true
			
			if is_match:
				print("[StaffActor ", name, "] found task: ", t.id)
				t.status = "assigned"
				t.assigned_to = get_staff_id()
				_current_task = t
				
				# Ziel setzen
				if is_instance_valid(t.target) and t.target is Node2D:
					_start_path_to_room(t.target)
					if _path.size() > 0:
						_state = "walking"
						_sprite.visible = true  # MA wird sichtbar wenn er losläuft
						_think_timer = 1.0 # Denkt kurz nach, bevor er losrennt
					else:
						# Kein Weg?
						_current_task = {}
						t.status = "open"
				else:
					_current_task = {}
					t.status = "open"
				break

func _start_path_to_room(room: Node2D) -> void:
	var start_tile: Vector2i
	if is_instance_valid(_current_room):
		start_tile = _current_room.get_target_tile(_map_grid)
	else:
		start_tile = _map_grid.call("world_to_tile", global_position)
		
	var end_tile = room.get_target_tile(_map_grid)
	
	if room.has_method("get_room_entry_pos"):
		_room_entry_pos = room.get_room_entry_pos(_map_grid)
	else:
		_room_entry_pos = Vector2.INF
	
	_path = _map_grid.call("get_path_between_tiles", start_tile, end_tile)
	if _path.size() > 0:
		if is_instance_valid(_current_room):
			# First step: walk to the door of the current room
			_target_world_pos = _map_grid.call("tile_to_world", start_tile)
			_current_room = null # Left the room
		else:
			if _path[0] == start_tile:
				_path.pop_front()
			if _path.size() > 0:
				_target_world_pos = _map_grid.call("tile_to_world", _path[0])
			else:
				_target_world_pos = global_position

func _start_path_to_lobby() -> void:
	var start_tile: Vector2i
	if is_instance_valid(_current_room):
		start_tile = _current_room.get_target_tile(_map_grid)
	else:
		start_tile = _map_grid.call("world_to_tile", global_position)
		
	var spawn_pos = _controller._get_lobby_spawn_pos()
	var end_tile = _map_grid.call("world_to_tile", spawn_pos)
	
	_path = _map_grid.call("get_path_between_tiles", start_tile, end_tile)
	if _path.size() > 0:
		if is_instance_valid(_current_room):
			_target_world_pos = _map_grid.call("tile_to_world", start_tile)
			_current_room = null
		else:
			if _path[0] == start_tile:
				_path.pop_front()
			if _path.size() > 0:
				_target_world_pos = _map_grid.call("tile_to_world", _path[0])
			else:
				_target_world_pos = global_position

func _process_walking(delta: float, speed: float) -> void:
	var current_pos: Vector2 = global_position
	var dist_to_target = current_pos.distance_to(_target_world_pos)
	
	if dist_to_target < 5.0:
		# Next tile
		if _path.size() > 0:
			_path.pop_front()
			if _path.size() > 0:
				_target_world_pos = _map_grid.call("tile_to_world", _path[0])
			else:
				if _room_entry_pos != Vector2.INF:
					_target_world_pos = _room_entry_pos
					_room_entry_pos = Vector2.INF
				else:
					_target_world_pos = global_position
		
		# Update dist for new target
		dist_to_target = current_pos.distance_to(_target_world_pos)
		
		if _path.is_empty() and dist_to_target < 5.0:
			if _state == "walking":
				_state = "working"
				_work_timer = 20.0
				_work_timer_max = _work_timer
				if _current_task.has("target"):
					_current_room = _current_task["target"]
			elif _state == "returning":
				_state = "idle"
				_sprite.visible = false  # Wieder unsichtbar in der Lobby
			return

	var move_dist = speed * delta
	var direction = current_pos.direction_to(_target_world_pos)
	
	if move_dist >= dist_to_target:
		global_position = _target_world_pos
	else:
		global_position += direction * move_dist
	
	if direction.length_squared() > 0.1:
		# Da die Sprites von unten nach oben schauen (Up = 0 Rotation)
		# müssen wir PI/2 addieren, da angle() 0 für Rechts liefert.
		_sprite.rotation = direction.angle() + PI / 2.0
		_sprite.flip_h = false

	_update_debug_line()

func _update_debug_line() -> void:
	if not is_instance_valid(_debug_line): return
	var pts: PackedVector2Array = []
	pts.append(global_position)
	if _target_world_pos != Vector2.ZERO and _target_world_pos != global_position:
		pts.append(_target_world_pos)
	for p in _path:
		pts.append(_map_grid.call("tile_to_world", p))
	_debug_line.points = pts

func _process_working(delta: float, speed_mult: float) -> void:
	if is_instance_valid(_debug_line): _debug_line.points = []
	_work_timer -= delta * speed_mult
	
	# Fortschrittsbalken im Raum aktualisieren
	if is_instance_valid(_current_room) and _current_room.has_node("RoomStatusIndicator"):
		var indicator = _current_room.get_node("RoomStatusIndicator")
		var progress = 1.0 - (_work_timer / _work_timer_max)
		indicator.set_progress(progress)
	
	# Simples visuelles Feedback fürs Arbeiten (Wackeln)
	_sprite.scale.y = 1.0 + sin(_work_timer * 10.0) * 0.1
	_sprite.scale.x = 1.0 + cos(_work_timer * 10.0) * 0.05
	
	if _work_timer <= 0.0:
		_sprite.scale = Vector2.ONE
		# Fortschrittsbalken wieder verstecken
		if is_instance_valid(_current_room) and _current_room.has_node("RoomStatusIndicator"):
			_current_room.get_node("RoomStatusIndicator").hide_progress()
		TaskManager.complete_task(_current_task.id)
		_current_task = {}
		
		# Prüfen ob es direkt noch einen weiteren Job gibt
		_state = "idle"
		_process_idle()
		
		# Wenn er keinen neuen Job gefunden hat (state ist immer noch idle), geht er in die Lobby zurück
		if _state == "idle":
			_start_path_to_lobby()
			_state = "returning"
			_think_timer = 1.0 # Nach der Arbeit kurz durchatmen
