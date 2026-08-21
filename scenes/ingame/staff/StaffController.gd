extends Node
class_name StaffController

const STAFF_ACTOR_SCENE = preload("res://scenes/ingame/staff/StaffActor.tscn")

var _map_grid: Node2D
var _actors: Array = []

func configure(map_grid: Node2D) -> void:
	_map_grid = map_grid
	_spawn_all_staff()
	
	if not StaffManager.sig_staff_hired.is_connected(_on_staff_hired):
		StaffManager.sig_staff_hired.connect(_on_staff_hired)
	if not StaffManager.sig_staff_fired.is_connected(_on_staff_fired):
		StaffManager.sig_staff_fired.connect(_on_staff_fired)
	if not StaffManager.sig_staff_training_started.is_connected(_on_staff_training_started):
		StaffManager.sig_staff_training_started.connect(_on_staff_training_started)
	if not StaffManager.sig_staff_training_ended.is_connected(_on_staff_training_ended):
		StaffManager.sig_staff_training_ended.connect(_on_staff_training_ended)

func _spawn_all_staff() -> void:
	for staff in StaffManager.hired_staff.values():
		if staff.get("training_state", "none") != "in_training":
			_spawn_actor(staff)

func _spawn_actor(staff_data: Dictionary) -> void:
	var actor = STAFF_ACTOR_SCENE.instantiate()
	actor.name = "StaffActor_" + str(staff_data.get("id", ""))
	_map_grid.add_child(actor)
	
	var spawn_room = _get_staff_room(staff_data)
	actor.configure(staff_data, _map_grid, self, spawn_room)
	_actors.append(actor)
	
	# Spawn-Punkt: Personalraum mit freier Kapazität -> Lobby
	var spawn_pos = Vector2.INF
	if is_instance_valid(spawn_room):
		if spawn_room.has_method("get_service_position"):
			spawn_pos = spawn_room.get_service_position()
		else:
			var interior = spawn_room.get_node_or_null("Interior")
			spawn_pos = interior.global_position if interior else spawn_room.global_position
			
	if spawn_pos == Vector2.INF:
		spawn_pos = _get_lobby_spawn_pos()
		
	# Nur noch ein sehr kleiner Scatter, damit sie nicht exakt 100% clippen
	spawn_pos += Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
	actor.global_position = spawn_pos

func _get_staff_room(staff_data: Dictionary) -> Node2D:
	if not is_instance_valid(_map_grid) or not _map_grid.has_method("get_placed_rooms"):
		return null
		
	var staff_rooms = []
	var all_staff_rooms = []
	var workplace_pos = Vector2.INF
	
	# Finde alle Personalräume und den Arbeitsplatz des Mitarbeiters
	var assigned_room_id = ""
	if StaffManager and "room_assignments" in StaffManager:
		assigned_room_id = StaffManager.room_assignments.get(str(staff_data.get("id", "")), "")
		
	for r in _map_grid.get_placed_rooms():
		if r.has_method("get_definition"):
			var def = r.get_definition()
			if def.get("id") == "staff_small":
				all_staff_rooms.append(r)
				if r.has_method("has_free_seat") and r.has_free_seat():
					staff_rooms.append(r)
				
		if assigned_room_id != "":
			if GuestManager._room_key(r) == assigned_room_id:
				workplace_pos = r.global_position
				
	if staff_rooms.size() == 0:
		staff_rooms = all_staff_rooms
		
	if staff_rooms.size() == 0:
		return null
		
	var best_room = staff_rooms[randi() % staff_rooms.size()]
	
	# Wenn wir einen Arbeitsplatz haben, nimm den nächsten Personalraum
	if workplace_pos != Vector2.INF:
		var best_dist = INF
		for r in staff_rooms:
			var d = r.global_position.distance_to(workplace_pos)
			if d < best_dist:
				best_dist = d
				best_room = r
				
	return best_room

func _on_staff_hired(staff_data: Dictionary) -> void:
	_spawn_actor(staff_data)

func _on_staff_fired(staff_id: String) -> void:
	for i in range(_actors.size() - 1, -1, -1):
		var actor = _actors[i]
		if actor.get_staff_id() == staff_id:
			actor.despawn()
			_actors.remove_at(i)
			break

func _on_staff_training_started(staff_id: String) -> void:
	# Same as fired: remove the actor from the map
	_on_staff_fired(staff_id)

func _on_staff_training_ended(staff_data: Dictionary) -> void:
	_spawn_actor(staff_data)

func _get_lobby_spawn_pos() -> Vector2:
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_lobby_spawn_pos_world"):
		return _map_grid.call("get_lobby_spawn_pos_world")
	return Vector2.ZERO
