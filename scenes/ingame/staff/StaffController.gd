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
	actor.configure(staff_data, _map_grid, self)
	_actors.append(actor)
	
	# Spawn-Punkt: Personalraum (Fallback Lobby)
	var spawn_pos = _get_staff_room_spawn_pos()
	if spawn_pos == Vector2.INF:
		spawn_pos = _get_lobby_spawn_pos()
		
	spawn_pos += Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	actor.global_position = spawn_pos
	
func _get_staff_room_spawn_pos() -> Vector2:
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		var candidates = []
		for r in _map_grid.get_placed_rooms():
			if r.has_method("get_definition") and r.get_definition().get("id") == "staff_small":
				candidates.append(r)
		
		if candidates.size() > 0:
			var room = candidates[randi() % candidates.size()]
			var interior = room.get_node_or_null("Interior")
			if interior:
				return interior.global_position
			return room.global_position
	return Vector2.INF

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
