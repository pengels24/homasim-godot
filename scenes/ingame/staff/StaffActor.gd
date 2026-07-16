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
var _work_audio: AudioStreamPlayer

var _path: Array[Vector2i] = []
var _target_world_pos: Vector2 = Vector2.ZERO
var _room_entry_pos: Vector2 = Vector2.INF
var _extra_target_pos: Vector2 = Vector2.INF
var _current_room: Node2D = null

var _debug_line: Line2D

const SPEED := 40.0

func _ready() -> void:
	_work_audio = AudioStreamPlayer.new()
	_work_audio.bus = "Sound"
	add_child(_work_audio)
	
	if has_node("ClickArea"):
		var ca = get_node("ClickArea")
		if not ca.input_event.is_connected(_on_click_area_input_event):
			ca.input_event.connect(_on_click_area_input_event)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		GameState.sig_staff_clicked.emit(self)

func configure(staff_data: Dictionary, map_grid: Node2D, controller: Node) -> void:
	_staff_data = staff_data
	_map_grid = map_grid
	_controller = controller
	_update_visuals()
	_sprite.visible = false
	


	var job = get_job_type()
	if job == "housekeeping":
		_work_audio.stream = load("res://assets/sounds/broom.mp3")
	elif job == "maintenance":
		_work_audio.stream = load("res://assets/sounds/wrench.mp3")

func _update_visuals() -> void:
	# Grafiken setzen basierend auf Beruf und Geschlecht
	var job = _staff_data.get("role", "housekeeping")
	var gender = _staff_data.get("gender", "female")
	
	var texture_path = "res://assets/staff/staff_avatar_%s_%s.aseprite" % [gender, job]
	if ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		if tex and tex is Texture2D:
			_sprite.texture = tex
	else:
		pass
# 		push_warning("[StaffActor] Aseprite %s nicht gefunden!" % texture_path)
	
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

	queue_free()

func _physics_process(delta: float) -> void:
	if TimeManager.is_paused():
		return
		
	var speed_mult = TimeManager.user_speed
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
		
	var current_hour = TimeManager.get_hour()
	var is_night = current_hour >= 22 or current_hour < 7
	
	if is_night:
		# Feierabend: Keine neuen Tasks annehmen, ab in die Lobby
		var spawn_pos = _controller._get_lobby_spawn_pos()
		if global_position.distance_to(spawn_pos) > 10.0:
			_start_path_to_lobby()
			_state = "returning"
			_think_timer = 1.0
		return
		
	var my_job = get_job_type()
	var tasks = TaskManager._tasks
	
	for t in tasks:
		if t.status == "open":
			var is_match = false
			if my_job == "housekeeping" and t.type == "clean_room": is_match = true
			if my_job == "maintenance" and t.type == "repair_room": is_match = true
			
			if my_job == "waiter" and t.type in ["serve_meal", "clean_table"]:
				if typeof(t.target) == TYPE_DICTIONARY and t.target.get("room") == _current_room:
					is_match = true
			
			if is_match:

				t.status = "assigned"
				t.assigned_to = get_staff_id()
				_current_task = t
				
				# Ziel setzen
				var target_room: Node2D = null
				var extra_pos: Vector2 = Vector2.INF
				
				if typeof(t.target) == TYPE_DICTIONARY:
					target_room = t.target.get("room")
					extra_pos = t.target.get("pos", Vector2.INF)
				elif is_instance_valid(t.target) and t.target is Node2D:
					target_room = t.target
					
				if is_instance_valid(target_room):
					_start_path_to_room(target_room, extra_pos)
					if _path.size() > 0:
						_state = "walking"
						_sprite.visible = true  # MA wird sichtbar wenn er losläuft
						_think_timer = 1.0 # Denkt kurz nach, bevor er losrennt
					else:
						# Kein Weg?
						_current_task = {}
						t.status = "open"
						# ANG-Fix: Move unreachable task to the back of the queue so he doesn't loop infinitely on it!
						var t_idx = TaskManager._tasks.find(t)
						if t_idx != -1:
							TaskManager._tasks.remove_at(t_idx)
							TaskManager._tasks.append(t)
				else:
					_current_task = {}
					t.status = "open"
				break

func _start_path_to_room(room: Node2D, extra_pos: Vector2 = Vector2.INF) -> void:
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
		
	# Speichere extra_pos für den allerletzten Schritt (z.B. Tisch im Restaurant)
	_extra_target_pos = extra_pos
	
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
	
	_room_entry_pos = spawn_pos
	_extra_target_pos = Vector2.INF
	
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
				elif _extra_target_pos != Vector2.INF:
					_target_world_pos = _extra_target_pos
					_extra_target_pos = Vector2.INF
				else:
					_target_world_pos = global_position
		
		# Update dist for new target
		dist_to_target = current_pos.distance_to(_target_world_pos)
		
		if _path.is_empty() and dist_to_target < 5.0:
			if _state == "walking":
				_state = "working"
				# Zufälliger Versatz, damit sich überlappende Mitarbeiter optisch trennen
				global_position += Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0))
				var morale = _staff_data.get("morale", 100)
				var penalty = 0.0
				if morale < 50:
					penalty = 0.3 * (float(50 - morale) / 50.0) # Bis zu +30% Arbeitszeit
					
				_work_timer = 20.0 * (1.0 + penalty)
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
	pts.append(Vector2.ZERO) # Actor-Position = lokal (0,0)
	if _target_world_pos != Vector2.ZERO and _target_world_pos != global_position:
		pts.append(to_local(_target_world_pos))
	for p in _path:
		pts.append(to_local(_map_grid.call("tile_to_world", p)))
	_debug_line.points = pts

func _process_working(delta: float, speed_mult: float) -> void:
	if is_instance_valid(_debug_line): _debug_line.points = []
	_work_timer -= delta * speed_mult
	
	if _work_audio.stream != null:
		var cam = get_viewport().get_camera_2d()
		if cam and cam.zoom.x < 1.4:
			_work_audio.volume_db = -80.0
		else:
			_work_audio.volume_db = 0.0
			
		if not _work_audio.playing:
			_work_audio.play()
		_work_audio.pitch_scale = max(0.5, speed_mult) # Bei Fast-Forward schneller hämmern!
	
	# Fortschrittsbalken im Raum aktualisieren
	if is_instance_valid(_current_room) and _current_room.has_node("RoomStatusIndicator"):
		var indicator = _current_room.get_node("RoomStatusIndicator")
		var progress = 1.0 - (_work_timer / _work_timer_max)
		indicator.set_progress(get_staff_id(), progress)
	
	# Simples visuelles Feedback fürs Arbeiten (Wackeln)
	_sprite.scale.y = 1.0 + sin(_work_timer * 10.0) * 0.1
	_sprite.scale.x = 1.0 + cos(_work_timer * 10.0) * 0.05
	
	if _work_timer <= 0.0:
		_work_audio.stop()
		_sprite.scale = Vector2.ONE
		# Fortschrittsbalken wieder verstecken
		if is_instance_valid(_current_room) and _current_room.has_node("RoomStatusIndicator"):
			_current_room.get_node("RoomStatusIndicator").hide_progress(get_staff_id())
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
