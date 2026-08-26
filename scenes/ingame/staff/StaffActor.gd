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
var _path: Array = []
var _world_path: Array[Vector2] = []
var _target_world_pos: Vector2 = Vector2.ZERO
var _room_entry_pos: Vector2 = Vector2.INF
var _extra_target_pos: Vector2 = Vector2.INF
var _look_at_pos: Vector2 = Vector2.ZERO
var _resting_timer: float = 0.0
var _current_room: Node2D = null
var _arriving_room: Node2D = null
var _debug_line: Line2D

var _base_speed := 10.0 # Zeitlupe für Debug


const SHOW_DEBUG_PATHS := false

func _ready() -> void:
	add_to_group("staff_actors")
	z_index = 100
	
	if SHOW_DEBUG_PATHS:
		_debug_line = Line2D.new()
		_debug_line.width = 2.0
		_debug_line.z_index = 100
		add_child(_debug_line)
	
	_work_audio = AudioStreamPlayer.new()
	_work_audio.bus = "Sound"
	add_child(_work_audio)
	_sprite.scale = Vector2.ONE
	
	if has_node("ClickArea"):
		var ca = get_node("ClickArea")
		ca.z_index = 10
		if not ca.input_event.is_connected(_on_click_area_input_event):
			ca.input_event.connect(_on_click_area_input_event)
			
	if TimeManager and not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
		TimeManager.sig_hour_passed.connect(_on_hour_passed)

func _on_hour_passed(_hour: int) -> void:
	if _state == "idle" and StaffManager:
		StaffManager.add_morale(get_staff_id(), 5, 50)

func _on_click_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		get_viewport().set_input_as_handled()
		GameState.sig_staff_clicked.emit(self)

func configure(staff_data: Dictionary, map_grid: Node2D, controller: Node, spawn_room: Node2D = null) -> void:
	_staff_data = staff_data
	_map_grid = map_grid
	_controller = controller
	_current_room = spawn_room
	
	# Leicht variierende Laufgeschwindigkeit (+/- 10%)
	_base_speed = 40.0 * randf_range(0.9, 1.1)
	
	_update_visuals()


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
	if not ResourceLoader.exists(texture_path):
		texture_path = "res://assets/staff/staff_avatar_%s_maintenance.aseprite" % [gender]
		
	if ResourceLoader.exists(texture_path):
		var tex = load(texture_path)
		if tex and tex is Texture2D:
			_sprite.texture = tex
	else:
		push_warning("[StaffActor] Aseprite %s nicht gefunden!" % texture_path)
	
	# MA spawnt sofort sichtbar

func _set_state(new_state: String) -> void:
	_state = new_state
	var staff_name = "Unknown"
	if _staff_data:
		var first = _staff_data.get("first_name", "")
		var last = _staff_data.get("last_name", "")
		if first != "" or last != "":
			staff_name = (first + " " + last).strip_edges()
	var role = get_job_type()
	print("[StaffActor] " + staff_name + " (" + role + ") changing to next_state=" + new_state)

func get_staff_id() -> String:
	return str(_staff_data.get("id", ""))

func get_job_type() -> String:
	return _staff_data.get("role", "housekeeping")

func _get_assigned_room() -> Node2D:
	var room_id = StaffManager.room_assignments.get(get_staff_id(), "")
	if room_id == "": return null
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for room in _map_grid.get_placed_rooms():
			if GuestManager._room_key(room) == room_id:
				return room
	return null

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
	
	var tech_bonus = 0.0
	if TechtreeManager.is_tech_unlocked("Z1.1"): tech_bonus += 0.05
	if TechtreeManager.is_tech_unlocked("M1.3"): tech_bonus += 0.15
	
	var actual_speed = _base_speed * speed_mult * (1.0 + tech_bonus)
	
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
		"returning", "walking_to_break":
			_process_walking(delta, actual_speed)
		"resting":
			_process_resting(delta, speed_mult)

func _process_resting(delta: float, speed_mult: float) -> void:
	_resting_timer += delta * speed_mult
	if _resting_timer >= 2.0: # Alle 2 Sekunden ein Morale-Tick
		_resting_timer = 0.0
		var bonus = 1
		if is_instance_valid(_current_room) and _current_room.has_method("has_free_seat"):
			var seats = _current_room.get("_room_seats")
			if seats:
				for seat in seats:
					if seat.get("occupied_by") == get_staff_id():
						bonus = 1
						break
			var beds = _current_room.get("_room_beds")
			if beds:
				for bed in beds:
					if bed.get("occupied_by") == get_staff_id():
						bonus = 2
						break
						
		# Beine vertreten (wenn auf Stuhl)
		if bonus == 1 and randf() < 0.10: # 10% Chance alle 2 Sekunden -> gelegentliches Aufstehen
			if is_instance_valid(_current_room) and _current_room.has_method("leave_seat"):
				_current_room.leave_seat(get_staff_id())
			_set_state("walking")
			var target = global_position
			if _current_room.has_method("get_waypoints"):
				var wps = _current_room.get_waypoints()
				if wps.size() > 0:
					target = wps[randi() % wps.size()] + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
			else:
				target = global_position + Vector2(randf_range(-16.0, 16.0), randf_range(-16.0, 16.0))
			_target_world_pos = target
			_path = [_target_world_pos]
			_think_timer = 1.0
			return
						
		var morale = _staff_data.get("morale", 100)
		if morale < 100:
			StaffManager.add_morale(get_staff_id(), 2 * bonus, 100)
			morale = _staff_data.get("morale", 100)
			
		if morale >= 100:
			if not _is_shift_over():
				var has_workplace = _get_assigned_room() != null
				if has_workplace:
					if is_instance_valid(_current_room) and _current_room.has_method("leave_seat"):
						_current_room.leave_seat(get_staff_id())
					_set_state("idle")
					_sprite.rotation = 0
					_think_timer = 1.0

	if _state == "resting":
		var thresholds = StaffManager.get_break_thresholds(get_staff_id()) if StaffManager and StaffManager.has_method("get_break_thresholds") else {}
		var accept_t = thresholds.get("task_accept_threshold", 50)
		if _staff_data.get("morale", 100) >= accept_t:
			_check_for_tasks()

func _check_for_tasks() -> bool:
	var my_job = get_job_type()
	var tasks = TaskManager._tasks
	
	for t in tasks:
		if t.status == "open":
			var is_match = false
			if my_job == "housekeeping" and t.type == "clean_room": is_match = true
			if my_job == "maintenance" and t.type == "repair_room": is_match = true
			
			if my_job == "waiter" and t.type in ["serve_meal", "clean_table"]:
				var assigned_room_id = StaffManager.room_assignments.get(get_staff_id(), "")
				var target_room_id = ""
				if typeof(t.target) == TYPE_DICTIONARY and is_instance_valid(t.target.get("room")):
					target_room_id = GuestManager._room_key(t.target.get("room"))
				if assigned_room_id == target_room_id:
					is_match = true
			
			if is_match:
				t.status = "assigned"
				t.assigned_to = get_staff_id()
				_current_task = t
				
				# Ziel setzen
				var target_room: Node2D = null
				var extra_pos: Vector2 = Vector2.INF
				
				if t.type == "serve_meal":
					var order_id = t.target.get("order_id")
					var kitchen_id = GastroManager.active_orders.get(order_id, {}).get("kitchen_id", "")
					if _map_grid and _map_grid.has_method("get_placed_rooms"):
						for room in _map_grid.get_placed_rooms():
							if is_instance_valid(room) and GuestManager._room_key(room) == kitchen_id:
								target_room = room
								if target_room.has_method("get_service_position"):
									extra_pos = target_room.get_service_position()
								break
					if not is_instance_valid(target_room):
						target_room = t.target.get("room") # Fallback directly to restaurant
						extra_pos = t.target.get("pos", Vector2.INF)
				elif typeof(t.target) == TYPE_DICTIONARY:
					target_room = t.target.get("room")
					extra_pos = t.target.get("pos", Vector2.INF)
				elif is_instance_valid(t.target) and t.target is Node2D:
					target_room = t.target
					if target_room.has_method("get_service_position"):
						extra_pos = target_room.get_service_position()
					
				if is_instance_valid(target_room):
					# Wenn er gerade Pause gemacht hat, Sitz aufgeben!
					if _state == "resting":
						if is_instance_valid(_current_room) and _current_room.has_method("leave_seat"):
							_current_room.leave_seat(get_staff_id())
						_sprite.rotation = 0
						
					_start_path_to_room(target_room, extra_pos)
					if _path.size() > 0:
						_set_state("walking")
						_sprite.visible = true  # MA wird sichtbar wenn er losläuft
						_think_timer = 1.0 # Denkt kurz nach, bevor er losrennt
					else:
						print("[StaffActor] Path failed to target_room: ", target_room.name, " from current_room: ", _current_room.name if _current_room else "none")
						_current_task = {}
						t.status = "open"
						var t_idx = TaskManager._tasks.find(t)
						if t_idx != -1:
							TaskManager._tasks.remove_at(t_idx)
							TaskManager._tasks.append(t)
				else:
					print("[StaffActor] Target room invalid for task: ", t.type)
					_current_task = {}
					t.status = "open"
				return true
	return false

func _is_shift_over() -> bool:
	var is_night = false
	var assigned_room = _get_assigned_room()
	
	if is_instance_valid(assigned_room) and assigned_room.has_method("get_definition"):
		var def = assigned_room.get_definition()
		var is_open = GameState.is_facility_open(def)
		
		# 10 Ingame-Minuten Vorlauf für das Personal, damit sie pünktlich da sind
		if not is_open:
			var current_time = TimeManager.get_game_time()
			var future_time = (current_time + 10) % 1440
			var open_from = def.get("open_from", 0)
			var open_to = def.get("open_to", 0)
			if open_from != 0 or open_to != 0:
				if open_from < open_to:
					is_open = future_time >= open_from and future_time < open_to
				else:
					is_open = future_time >= open_from or future_time < open_to
					
		if not is_open:
			is_night = true # Raum ist geschlossen
			
			# Überstunden-Check: Gibt es noch was zu tun?
			var room_id = GuestManager._room_key(assigned_room)
			if GastroManager and GastroManager.has_active_orders_for_room(room_id):
				is_night = false # Bleibt, bis alle versorgt sind
	else:
		# Fallback für Personal ohne feste Raum-Öffnungszeiten (Housekeeping, Maintenance)
		var current_time = TimeManager.get_game_time()
		# Schicht ist von 07:00 (420) bis 22:00 (1320). Vorlauf 10 Minuten: Start um 06:50 (410).
		is_night = current_time >= 1320 or current_time < 410
		
	return is_night

func _process_idle() -> void:
	if is_instance_valid(_debug_line): _debug_line.points = []
	if not _current_task.is_empty():
		return # Mache schon was
		
	var is_night = _is_shift_over()
	
	if is_night:
		if _state == "resting":
			return # Schon im Feierabend / sitzt im Pausenraum
			
			
		if _state != "walking_to_break":
			var break_room = null
			if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
				var best_dist = INF
				for room in _map_grid.get_placed_rooms():
					if room.has_method("get_definition") and room.get_definition().get("id") == "staff_small":
						if room.has_method("has_free_seat") and room.has_free_seat():
							var d = global_position.distance_to(room.global_position)
							if d < best_dist:
								best_dist = d
								break_room = room
			
			if is_instance_valid(break_room):
				var seat_info = break_room.call("claim_seat", get_staff_id(), true) # prefer_bed = true (Nacht = Schlafen)
				if not seat_info.is_empty():
					var pos = seat_info.get("pos", Vector2.INF)
					_look_at_pos = seat_info.get("look_at", Vector2.ZERO)
					_arriving_room = break_room
					if _current_room == break_room:
						if break_room.has_method("get_local_path"):
							_world_path = break_room.get_local_path(global_position, pos)
						else:
							_world_path = [global_position, pos]
						if _world_path.size() > 0:
							_target_world_pos = _world_path[0]
						_set_state("walking_to_break")
						_sprite.visible = true
					else:
						_start_path_to_room(break_room, pos)
						if _world_path.size() > 0:
							_set_state("walking_to_break")
							_sprite.visible = true
						else:
							_sprite.visible = false
					_think_timer = 1.0
					return
					
			# Fallback zur Lobby wenn alle Personalräume voll sind
			if _extra_target_pos == Vector2.INF:
				_extra_target_pos = _controller._get_lobby_spawn_pos()
				
			if global_position.distance_to(_extra_target_pos) > 10.0:
				if _state != "returning":
					_start_path_to_lobby()
					_room_entry_pos = _extra_target_pos
					_set_state("returning")
				_think_timer = 1.0
			else:
				_sprite.visible = false
				_think_timer = 1.0
				_extra_target_pos = Vector2.INF
		return
		
	var found_task = _check_for_tasks()
	if found_task:
		return
		
	# Wenn er keinen neuen Job gefunden hat (state ist immer noch idle), geht er an seinen Arbeitsplatz oder in die Pause
	if _state == "idle":
		var morale = _staff_data.get("morale", 100)
		var thresholds = StaffManager.get_break_thresholds(get_staff_id()) if StaffManager and StaffManager.has_method("get_break_thresholds") else {}
		var break_start_t = thresholds.get("break_start_threshold", 40)
		var bed_t = thresholds.get("bed_preference_threshold", 20)
		
		# Pause einlegen?
		if morale < break_start_t and not is_night:
			var break_room = null
			if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
				for room in _map_grid.get_placed_rooms():
					if room.has_method("get_definition") and room.get_definition().get("id") == "staff_small":
						if room.has_method("has_free_seat") and room.has_free_seat():
							break_room = room
							break
			
			if is_instance_valid(break_room):
				var want_bed = morale < bed_t
				var seat_info = break_room.call("claim_seat", get_staff_id(), want_bed)
				if not seat_info.is_empty():
					var pos = seat_info.get("pos", Vector2.INF)
					_look_at_pos = seat_info.get("look_at", Vector2.ZERO)
					_arriving_room = break_room
					if _current_room == break_room:
						if break_room.has_method("get_local_path"):
							_world_path = break_room.get_local_path(global_position, pos)
						else:
							_world_path = [global_position, pos]
						if _world_path.size() > 0:
							_target_world_pos = _world_path[0]
						_set_state("walking_to_break")
						_sprite.visible = true
						return
					else:
						_start_path_to_room(break_room, pos)
						if _world_path.size() > 0:
							_set_state("walking_to_break")
							_sprite.visible = true
							_think_timer = 1.0
							return
		
		# Kein Job, keine Pause -> Arbeitsplatz oder Chillen
		var room = _get_assigned_room()
		
		if room != null and not is_night:
			if _current_room != room:
				_start_path_to_room(room)
				if _path.size() > 0:
					_set_state("returning")
					_sprite.visible = true
				_think_timer = 1.0
			else:
				_sprite.visible = true
				
				# Hat der Raum einen festen Arbeitsplatz für diese Rolle?
				if is_instance_valid(_current_room) and _current_room.has_method("get_work_position"):
					var work_pos = _current_room.get_work_position(get_staff_id())
					if work_pos != Vector2.INF:
						if global_position.distance_to(work_pos) > 6.0:
							if _current_room.has_method("get_local_path"):
								var lp = _current_room.get_local_path(global_position, work_pos)
								if lp.size() > 0:
									_world_path = lp
									_target_world_pos = _world_path[0]
									_set_state("walking")
									_path = []
							else:
								_target_world_pos = work_pos
								_set_state("walking")
								_path = [_target_world_pos]
						else:
							# Steht am Platz
							if get_job_type() == "waiter" and randf() < 0.2:
								if _current_room.has_method("get_available_interactions"):
									var avail = _current_room.get_available_interactions(null)
									if avail.size() > 0:
										var seat = avail[randi() % avail.size()]
										var target = seat["target_pos"]
										if _current_room.has_method("get_local_path"):
											var lp = _current_room.get_local_path(global_position, target)
											if lp.size() > 0:
												_world_path = lp
												_target_world_pos = _world_path[0]
												_set_state("walking")
												_path = []
												_current_task = {
													"id": "dummy_clean",
													"type": "clean_table",
													"status": "assigned"
												}
												return
												
							if _current_room.has_method("get_work_look_dir"):
								var dir = _current_room.get_work_look_dir(get_staff_id())
								_sprite.rotation = dir.angle() + PI / 2.0
						_think_timer = 2.0
						return
				
				# Barkeeper: immer am Tresen stehen bleiben
				if get_job_type() == "bartender" and is_instance_valid(_current_room) and _current_room.has_method("get_bartender_stand_pos"):
					var stand_pos = _current_room.get_bartender_stand_pos()
					if global_position.distance_to(stand_pos) > 6.0:
						if _current_room.has_method("get_local_path"):
							var lp = _current_room.get_local_path(global_position, stand_pos)
							if lp.size() > 0:
								_world_path = lp
								_target_world_pos = _world_path[0]
								_set_state("walking")
								_path = []
						else:
							# Fallback
							_target_world_pos = stand_pos
							_set_state("walking")
							_path = [_target_world_pos]
					else:
						# Steht am Platz -> Rotiere in die gewünschte Richtung
						if _current_room.has_method("get_bartender_look_dir"):
							var dir = _current_room.get_bartender_look_dir()
							_sprite.rotation = dir.angle() + PI / 2.0
					_think_timer = 2.0
				elif get_job_type() == "lifeguard" and is_instance_valid(_current_room) and _current_room.has_method("get_lifeguard_stand_pos"):
					# 70% Zeit auf Hochsitz sitzen, 30% Patrouille
					if randf() < 0.7 and _current_room.has_method("is_lifeguard_chair_free") and _current_room.call("is_lifeguard_chair_free", get_staff_id()):
						var chair_pos = _current_room.get_lifeguard_stand_pos()
						if global_position.distance_to(chair_pos) > 6.0:
							# Zum Hochsitz gehen
							if _current_room.has_method("get_local_path"):
								var lp = _current_room.get_local_path(global_position, chair_pos)
								if lp.size() > 0:
									_current_room.call("claim_lifeguard_chair", get_staff_id())
									_world_path = lp
									_target_world_pos = _world_path[0]
									_set_state("walking")
									_path = []
						else:
							# Sitzt schon dort — claim sicherstellen, leicht drehen
							_current_room.call("claim_lifeguard_chair", get_staff_id())
							if _current_room.has_method("get_lifeguard_look_dir"):
								_sprite.rotation = _current_room.get_lifeguard_look_dir()
							else:
								_sprite.rotation = PI
							_think_timer = 3.0 + randf() * 4.0
					else:
						# Patrouille um den Pool
						if _current_room.has_method("leave_lifeguard_chair"):
							_current_room.call("leave_lifeguard_chair", get_staff_id())
						if _current_room.has_method("get_local_path"):
							var patrol_target = Vector2.ZERO
							if _current_room.has_method("get_patrol_target"):
								patrol_target = _current_room.get_patrol_target()
							else:
								var sz = _current_room.get_tile_size() * 32.0
								patrol_target = _current_room.global_position + Vector2(
									randf_range(8.0, sz.x - 8.0),
									randf_range(8.0, sz.y - 8.0))
							var lp = _current_room.get_local_path(global_position, patrol_target)
							if lp.size() > 0:
								_world_path = lp
								_target_world_pos = _world_path[0]
								_set_state("walking")
								_path = []
								_think_timer = 3.0 + randf() * 4.0
				elif randf() < 0.3:
					# Andere Rollen: im Raum umherwandern (Chill-Verhalten)
					var wander_center = global_position
					var max_radius = 16.0
					
					if get_job_type() == "waiter" and is_instance_valid(_current_room) and _current_room.has_method("get_waiter_stand_pos"):
						wander_center = _current_room.get_waiter_stand_pos()
						max_radius = 12.0
					
					var offset = Vector2(randf_range(-max_radius, max_radius), randf_range(-max_radius, max_radius))
					var target = wander_center + offset
					
					# Sicherstellen, dass das Ziel auch begehbar ist
					if is_instance_valid(_current_room) and _current_room.has_method("get_random_walkable_local_pos"):
						for i in range(5): # Maximal 5 Versuche für einen Punkt in der Nähe
							var wp_global = _current_room.get_random_walkable_local_pos()
							if wp_global != Vector2.INF:
								if wp_global.distance_to(wander_center) <= max_radius:
									target = wp_global
									break
					
					if is_instance_valid(_current_room) and _current_room.has_method("get_local_path"):
						# NavBlocker-respektierender Pfad
						var local_path = _current_room.get_local_path(global_position, target)
						if local_path.size() > 0:
							_world_path = local_path
							_target_world_pos = _world_path[0]
							_set_state("walking")
							_path = []
					elif is_instance_valid(_current_room) and _current_room.has_method("get_tile_size"):
						# Fallback: direkter Weg wenn kein local_nav vorhanden
						var sz = _current_room.get_tile_size() * 16.0
						var r_rect = Rect2(_current_room.global_position + Vector2(4.0, 4.0), Vector2(sz.x * _current_room.global_scale.x - 8.0, sz.y * _current_room.global_scale.y - 8.0))
						if r_rect.has_point(target):
							_target_world_pos = target
							_set_state("walking")
							_path = [_target_world_pos]
					_think_timer = 2.0 + randf() * 2.0


		else:
			var break_room = null
			if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
				for r in _map_grid.get_placed_rooms():
					if r.has_method("get_definition") and r.get_definition().get("id") == "staff_small":
						break_room = r
						break
			
			if is_instance_valid(break_room):
				# Sitzplatz im Pausenraum suchen (Hausmeister/Reinigung immer setzen, wenn sie auf Jobs warten)
				var seat_info = break_room.call("claim_seat", get_staff_id(), false)
				if not seat_info.is_empty():
					var pos = seat_info.get("pos", Vector2.INF)
					_look_at_pos = seat_info.get("look_at", Vector2.ZERO)
					_arriving_room = break_room
					if _current_room == break_room:
						if break_room.has_method("get_local_path"):
							_world_path = break_room.get_local_path(global_position, pos)
						else:
							_world_path = [global_position, pos]
						if _world_path.size() > 0:
							_target_world_pos = _world_path[0]
						_set_state("walking_to_break")
						_sprite.visible = true
					else:
						_start_path_to_room(break_room, pos)
						if _world_path.size() > 0:
							_set_state("walking_to_break")
							_sprite.visible = true
					_think_timer = 1.0
				else:
					if _current_room != break_room:
						_arriving_room = break_room
						var extra_pos = Vector2.INF
						if break_room.has_method("get_waypoints"):
							var wps = break_room.get_waypoints()
							if wps.size() > 0:
								extra_pos = wps[0] # wp1
						_start_path_to_room(break_room, extra_pos)
						if _world_path.size() > 0:
							_set_state("returning")
							_sprite.visible = true
						_think_timer = 1.0
					else:
						_sprite.visible = true
						if randf() < 0.1:
							if break_room.has_method("get_waypoints"):
								var wps = break_room.get_waypoints()
								if wps.size() > 0:
									var wp = wps[randi() % wps.size()]
									if break_room.has_method("get_local_path"):
										_world_path = break_room.get_local_path(global_position, wp + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0)))
									else:
										_world_path = [global_position, wp + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))]
									if _world_path.size() > 0:
										_target_world_pos = _world_path[0]
									_set_state("walking")
							else:
								var sz = break_room.get_tile_size() * 16.0 if break_room.has_method("get_tile_size") else Vector2(48.0, 48.0)
								var r_rect = Rect2(break_room.global_position + Vector2(4.0, 4.0), Vector2(sz.x * break_room.global_scale.x - 8.0, sz.y * break_room.global_scale.y - 8.0))
								var target = break_room.global_position + Vector2(randf_range(8.0, sz.x - 8.0), randf_range(8.0, sz.y - 8.0))
								if r_rect.has_point(target):
									if break_room.has_method("get_local_path"):
										_world_path = break_room.get_local_path(global_position, target)
									else:
										_world_path = [global_position, target]
									if _world_path.size() > 0:
										_target_world_pos = _world_path[0]
									_set_state("walking")
						_think_timer = 5.0 + randf() * 5.0
			else:
				if _room_entry_pos == Vector2.INF and _extra_target_pos == Vector2.INF and _target_world_pos == Vector2.ZERO:
					pass
				if not _sprite.visible:
					return
				if _extra_target_pos == Vector2.INF:
					_extra_target_pos = _controller._get_lobby_spawn_pos()
					
				if global_position.distance_to(_extra_target_pos) > 10.0:
					if _state != "returning":
						_start_path_to_lobby()
						_room_entry_pos = _extra_target_pos
						_set_state("returning")
					_think_timer = 1.0
				else:
					_sprite.visible = false
					_think_timer = 1.0
				_extra_target_pos = Vector2.INF

func _start_path_to_room(room: Node2D, extra_pos: Vector2 = Vector2.INF) -> void:
	_arriving_room = room
	if not is_instance_valid(_current_room) and is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for r in _map_grid.get_placed_rooms():
			if is_instance_valid(r):
				var sz = r.get_tile_size() * 16
				var r_rect = Rect2(r.global_position, Vector2(sz.x * r.global_scale.x, sz.y * r.global_scale.y))
				if r_rect.has_point(global_position):
					_current_room = r
					break

	var local_path_out: Array[Vector2] = []
	var start_tile: Vector2i
	if is_instance_valid(_current_room):
		start_tile = _current_room.get_target_tile(_map_grid)
		if _current_room.has_method("get_room_entry_pos") and _current_room.has_method("get_local_path"):
			var entry_pos = _current_room.get_room_entry_pos(_map_grid)
			local_path_out = _current_room.get_local_path(global_position, entry_pos)
	else:
		start_tile = _map_grid.call("world_to_tile", global_position)
		
	var end_tile = room.get_target_tile(_map_grid)
	
	if room.has_method("get_room_entry_pos"):
		_room_entry_pos = room.get_room_entry_pos(_map_grid)
	else:
		_room_entry_pos = Vector2.INF
		
	# Speichere extra_pos für den allerletzten Schritt (z.B. Tisch im Restaurant)
	_extra_target_pos = extra_pos
	
	_path.assign(_map_grid.call("get_path_between_tiles", start_tile, end_tile))
	_world_path.clear()
	
	if local_path_out.size() > 0:
		_world_path.append_array(local_path_out)
	
	if _path.size() > 0:
		for t in _path:
			_world_path.append(_map_grid.call("tile_to_world", t))
			
		if is_instance_valid(_current_room):
			_current_room = null # Left the room
		else:
			if _path.size() > 1 and _path[0] == start_tile:
				_world_path.pop_front()
				
		if _world_path.size() > 0:
			var door_world = _world_path[_world_path.size() - 1]
			if extra_pos != Vector2.INF:
				if is_instance_valid(room) and room.has_method("get_local_path"):
					var local_path = room.get_local_path(door_world, extra_pos)
					_world_path.append_array(local_path)
				else:
					_world_path.append(extra_pos)
			_target_world_pos = _world_path[0]
			
			# The local path is now fully integrated into _world_path.
			# Clear the fallback targets so _process_walking doesn't loop back to them!
			_room_entry_pos = Vector2.INF
			_extra_target_pos = Vector2.INF
		else:
			_target_world_pos = global_position
	else:
		var astar = _map_grid.get("astar") if _map_grid else null
		# var s_solid = astar.is_point_solid(start_tile) if astar else false
		# var e_solid = astar.is_point_solid(end_tile) if astar else false
		# print("[StaffActor] _start_path_to_room FAILED: start=", start_tile, " (solid:", s_solid, ") end=", end_tile, " (solid:", e_solid, ") room=", room.name if room else "null")
		if is_instance_valid(_debug_line):
			_debug_line.default_color = Color.RED
			var e_world = _map_grid.call("tile_to_world", end_tile)
			_debug_line.points = [Vector2.ZERO, e_world - global_position]
			
		# EMERGENCY FALLBACK: Wenn der Mitarbeiter auf einem Solid-Tile steht (z.B. durch NavBlocker),
		# setzen wir ihn minimal um auf den ServicePoint des Raumes (oder Lobby) und berechnen den Pfad neu!
		var unstuck_pos = global_position
		if is_instance_valid(_current_room) and _current_room.has_method("get_service_position"):
			unstuck_pos = _current_room.get_service_position()
		elif is_instance_valid(_map_grid):
			unstuck_pos = _controller._get_lobby_spawn_pos()
			
		global_position = unstuck_pos
		start_tile = _map_grid.call("world_to_tile", unstuck_pos) if is_instance_valid(_map_grid) else start_tile
		
		if is_instance_valid(_map_grid):
			_path.assign(_map_grid.call("get_path_between_tiles", start_tile, end_tile))
			
		if _path.size() > 0:
			_world_path.clear()
			if local_path_out.size() > 0:
				_world_path.append_array(local_path_out)
			for t in _path:
				_world_path.append(_map_grid.call("tile_to_world", t))
			
			if _path.size() > 1 and _path[0] == start_tile:
				_world_path.pop_front()
				
			if _world_path.size() > 0:
				var door_world = _world_path[_world_path.size() - 1]
				if extra_pos != Vector2.INF:
					if is_instance_valid(room) and room.has_method("get_local_path"):
						var local_path = room.get_local_path(door_world, extra_pos)
						_world_path.append_array(local_path)
					else:
						_world_path.append(extra_pos)
				_target_world_pos = _world_path[0]
				_room_entry_pos = Vector2.INF
				_extra_target_pos = Vector2.INF
			else:
				_target_world_pos = global_position
		else:
			# Absoluter Mega-Notfall: Geht wirklich nicht (z.B. Ziel ist eingemauert) -> Teleport, um FPS zu retten
			global_position = _map_grid.call("tile_to_world", end_tile) if is_instance_valid(_map_grid) else end_tile * 16
			_target_world_pos = global_position
			if extra_pos != Vector2.INF:
				_extra_target_pos = extra_pos
			_set_state("walking") 
			_path = [end_tile]
		return


func _start_path_to_lobby() -> void:
	if not is_instance_valid(_current_room) and is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for r in _map_grid.get_placed_rooms():
			if is_instance_valid(r):
				var sz = r.get_tile_size() * 16
				var r_rect = Rect2(r.global_position, Vector2(sz.x * r.global_scale.x, sz.y * r.global_scale.y))
				if r_rect.has_point(global_position):
					_current_room = r
					break

	var start_tile: Vector2i
	var local_path_out: Array[Vector2] = []
	if is_instance_valid(_current_room):
		start_tile = _current_room.get_target_tile(_map_grid)
		if _current_room.has_method("get_room_entry_pos") and _current_room.has_method("get_local_path"):
			var entry_pos = _current_room.get_room_entry_pos(_map_grid)
			local_path_out = _current_room.get_local_path(global_position, entry_pos)
	else:
		start_tile = _map_grid.call("world_to_tile", global_position)
		
	var spawn_pos = _controller._get_lobby_spawn_pos()
	var end_tile = _map_grid.call("world_to_tile", spawn_pos)
	
	_room_entry_pos = spawn_pos
	_extra_target_pos = Vector2.INF
	
	_path.assign(_map_grid.call("get_path_between_tiles", start_tile, end_tile))
	_world_path.clear()
	
	if local_path_out.size() > 0:
		_world_path.append_array(local_path_out)
		
	if _path.size() > 0:
		for t in _path:
			_world_path.append(_map_grid.call("tile_to_world", t))
			
		if is_instance_valid(_current_room):
			_current_room = null
		else:
			if _path.size() > 1 and _path[0] == start_tile:
				_world_path.pop_front()
				
		if _world_path.size() > 0:
			_target_world_pos = _world_path[0]
			# The entry path is now fully integrated into _world_path.
			# Clear the fallback targets so _process_walking doesn't loop back to them!
			_room_entry_pos = Vector2.INF
			_extra_target_pos = Vector2.INF
		else:
			_target_world_pos = global_position
	else:
		# EMERGENCY FALLBACK: Wenn der Mitarbeiter feststeckt
		var unstuck_pos = global_position
		if is_instance_valid(_current_room) and _current_room.has_method("get_service_position"):
			unstuck_pos = _current_room.get_service_position()
		elif is_instance_valid(_map_grid):
			unstuck_pos = _controller._get_lobby_spawn_pos()
			
		global_position = unstuck_pos
		start_tile = _map_grid.call("world_to_tile", unstuck_pos) if is_instance_valid(_map_grid) else start_tile
		
		if is_instance_valid(_map_grid):
			_path.assign(_map_grid.call("get_path_between_tiles", start_tile, end_tile))
			
		if _path.size() > 0:
			_world_path.clear()
			if local_path_out.size() > 0:
				_world_path.append_array(local_path_out)
			for t in _path:
				_world_path.append(_map_grid.call("tile_to_world", t))
			
			if _path.size() > 1 and _path[0] == start_tile:
				_world_path.pop_front()
				
			if _world_path.size() > 0:
				_target_world_pos = _world_path[0]
				_room_entry_pos = Vector2.INF
				_extra_target_pos = Vector2.INF
			else:
				_target_world_pos = global_position
		else:
			# Mega-Notfall
			global_position = spawn_pos
			_target_world_pos = spawn_pos
			_room_entry_pos = Vector2.INF
			_extra_target_pos = Vector2.INF
			_set_state("returning")
			_path = [_map_grid.call("world_to_tile", spawn_pos)] if is_instance_valid(_map_grid) else [Vector2i.ZERO]

func _process_walking(delta: float, speed: float) -> void:
	var current_pos: Vector2 = global_position
	var dist_to_target = current_pos.distance_to(_target_world_pos)
	
	if dist_to_target < 5.0:
		# Next tile
		if _world_path.size() > 1:
			_world_path.pop_front()
			_target_world_pos = _world_path[0]
		elif _world_path.size() == 1:
			# Das ist der ALLERLETZTE Punkt auf dem Pfad!
			# Wenn wir ihn wirklich (fast) berühren (dist < 1.0) poppen wir ihn!
			# Dann greift der Snap Block unten!
			if dist_to_target < 1.0:
				_world_path.pop_front()
		else:
			if _room_entry_pos != Vector2.INF:
				_target_world_pos = _room_entry_pos
				_room_entry_pos = Vector2.INF
			elif _extra_target_pos != Vector2.INF:
				# GANZ WICHTIG: Wenn _path.size() == 0 war, sind wir hier OHNE EINEN GLOBULÄREN PFAD hingekommen!
				# In dem Fall DÜRFEN WIR NICHT durch Wände gleiten!
				if _path.size() > 0 or current_pos.distance_to(_extra_target_pos) < 32.0:
					_target_world_pos = _extra_target_pos
				_extra_target_pos = Vector2.INF
		
		# Update dist for new target
		dist_to_target = current_pos.distance_to(_target_world_pos)
		
		if _world_path.is_empty() and dist_to_target < 5.0:
			global_position = _target_world_pos # Snap exactly to target (e.g. seat or table)
			if _state == "walking":
				if not _current_task.is_empty() and _current_task.type == "serve_meal" and not _current_task.has("fetched"):
					_set_state("working")
					_work_timer = 1.0 # 1 Sekunde in der Küche abholen
					_current_task["fetched"] = true
				elif not _current_task.is_empty():
					_set_state("working")
					var morale = _staff_data.get("morale", 100)
					var penalty = 0.0
					if morale < 50:
						penalty = 0.3 * (float(50 - morale) / 50.0) # Bis zu +30% Arbeitszeit
						
					var base_time = 20.0
					if _current_task.type == "serve_meal": base_time = 2.0
					elif _current_task.type == "clean_table": base_time = 3.0
					
					var tech_bonus = 0.0
					if TechtreeManager.is_tech_unlocked("Z1.1"): tech_bonus += 0.05
					if TechtreeManager.is_tech_unlocked("M1.3"): tech_bonus += 0.15
						
					_work_timer = base_time * (1.0 + penalty) * (1.0 - tech_bonus)
					_work_timer_max = _work_timer
					if is_instance_valid(_arriving_room):
						_current_room = _arriving_room
						_arriving_room = null
				else:
					# Nur herumspaziert (chilling), kein Task vorhanden
					_set_state("idle")
					_think_timer = 1.0
					if is_instance_valid(_arriving_room):
						_current_room = _arriving_room
						_arriving_room = null
			elif _state == "returning":
				_set_state("idle")
				if is_instance_valid(_arriving_room):
					_current_room = _arriving_room
					_arriving_room = null
				else:
					_current_room = _get_assigned_room()
			elif _state == "walking_to_break":
				_set_state("resting")
				if is_instance_valid(_arriving_room):
					_current_room = _arriving_room
					_arriving_room = null
				if _look_at_pos != Vector2.ZERO:
					_sprite.rotation = _sprite.global_position.angle_to_point(_look_at_pos) + PI / 2.0
				else:
					_sprite.rotation = PI / 2.0 # Default auf rechts drehen wenn man sitzt
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
	if is_instance_valid(_debug_line) and _path.size() > 0:
		_debug_line.default_color = Color.GREEN
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
		var is_dummy = _current_task.get("id") == "dummy_clean" if not _current_task.is_empty() else false
		indicator.set_progress(get_staff_id(), progress, is_dummy)
	
	# Simples visuelles Feedback fürs Arbeiten (Wackeln)
	_sprite.scale.y = 1.0 + sin(_work_timer * 10.0) * 0.1
	_sprite.scale.x = 1.0 + cos(_work_timer * 10.0) * 0.05
	
	if _work_timer <= 0.0:
		_work_audio.stop()
		_sprite.scale = Vector2.ONE
		# Fortschrittsbalken wieder verstecken
		if is_instance_valid(_current_room) and _current_room.has_node("RoomStatusIndicator"):
			_current_room.get_node("RoomStatusIndicator").hide_progress(get_staff_id())
			
		if not _current_task.is_empty() and _current_task.type == "serve_meal" and _current_task.get("fetched") == true and not _current_task.has("served"):
			# Essen ist abgeholt -> ab zum Tisch!
			_current_task["served"] = true
			var target_room = _current_task.target.get("room")
			var extra_pos = _current_task.target.get("pos")
			_start_path_to_room(target_room, extra_pos)
			if _path.size() > 0:
				_set_state("walking")
			else:
				_set_state("working") # Fallback falls schon da
				_work_timer = 1.0
			return
			
		if not _current_task.is_empty() and _current_task.get("type") == "serve_meal" and typeof(_current_task.get("target")) == TYPE_DICTIONARY:
			var target_room = _current_task.target.get("room")
			if is_instance_valid(target_room) and target_room.has_method("serve_order_to_seat"):
				target_room.serve_order_to_seat(_current_task.target.get("order_id"))
		
		if not _current_task.is_empty():
			TaskManager.complete_task(_current_task.id)
			_current_task = {}
		
		# Prüfen ob es direkt noch einen weiteren Job gibt
		_set_state("idle")
		_process_idle()

