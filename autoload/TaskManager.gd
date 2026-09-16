extends Node
class_name TaskManagerAutoLoad

# =============================================================================
# TaskManager - "Schwarzes Brett"
# Speichert alle offenen Arbeitsaufträge (Tickets) für das Personal.
# =============================================================================

signal sig_task_added(task: Dictionary)
signal sig_task_completed(task: Dictionary)

signal sig_room_cleaned(room: Node2D)

var _tasks: Array[Dictionary] = []
var _next_task_id: int = 1

func _ready() -> void:
	GameState.sig_room_needs_cleaning.connect(_on_room_needs_cleaning)
	GameState.sig_room_needs_repair.connect(_on_room_needs_repair)


func add_task(type: String, target: Variant) -> Dictionary:
	var task = {
		"id": "T%04d" % _next_task_id,
		"type": type,
		"target": target,
		"status": "open",
		"assigned_to": null
	}
	_next_task_id += 1
	_tasks.append(task)

	sig_task_added.emit(task)
	return task


func complete_task(task_id: String) -> void:
	var task_idx := -1
	for i in range(_tasks.size()):
		if _tasks[i].id == task_id:
			task_idx = i
			break
			
	if task_idx != -1:
		var task = _tasks[task_idx]
		_tasks.remove_at(task_idx)

		sig_task_completed.emit(task)
		
		# Wenn es ein Raum war, den Raum auf "clean" setzen und wieder freigeben
		if task.type == "clean_room" and is_instance_valid(task.target):
			var room = task.target
			var old_level = room.get("cleanliness_level")
			
			if old_level != null and old_level < 90:
				GameState.add_exp(15)
				if EffectManager: EffectManager.spawn_exp_text(15, room.global_position + Vector2(64, 32))
				
			room.set("cleanliness_level", 100)
			room.set_service_requested(false)
			sig_room_cleaned.emit(room)
			
		elif task.type == "repair_room" and is_instance_valid(task.target):
			var room = task.target
			var old_level = room.get("maintenance_level")
			
			if old_level != null and old_level < 90:
				GameState.add_exp(25)
				if EffectManager: EffectManager.spawn_exp_text(25, room.global_position + Vector2(64, 32))
				
			room.set("maintenance_level", 100)
			room.set("is_repair_requested", false)
			# signal für repair existiert (noch) nicht, also nur update_indicator via property change
			if room.has_method("_update_indicator"):
				room.call("_update_indicator")
				
		elif task.type == "serve_meal":
			var room = task.target.get("room")
			var order_id = task.target.get("order_id")
			if is_instance_valid(room) and room.has_method("serve_order_to_seat"):
				room.call("serve_order_to_seat", order_id)
				GameState.add_exp(5)
				if EffectManager: EffectManager.spawn_exp_text(5, task.target.get("pos") + Vector2(0, -32))
				
		elif task.type == "clean_table":
			var room = task.target.get("room")
			if is_instance_valid(room) and room.has_method("clean_dirty_seat"):
				room.call("clean_dirty_seat")


func clear_all_tasks() -> void:
	_tasks.clear()
	_next_task_id = 1



func _on_room_needs_cleaning(room: Node2D) -> void:
	for task in _tasks:
		if task.type == "clean_room" and task.target == room:
			return
	add_task("clean_room", room)

func _on_room_needs_repair(room: Node2D) -> void:
	for task in _tasks:
		if task.type == "repair_room" and task.target == room:
			return
	add_task("repair_room", room)


# Debug-Methode für den manuellen Mausklick
func debug_complete_room_clean(room: Node2D) -> void:
	for task in _tasks:
		if task.type == "clean_room" and task.target == room:
			complete_task(task.id)
			return

func debug_complete_room_repair(room: Node2D) -> void:
	for task in _tasks:
		if task.type == "repair_room" and task.target == room:
			complete_task(task.id)
			return


# =============================================================================
# ANG-314: Persistenz-Methoden
# =============================================================================

## Hilfsfunktion: Extrahiert den serialisierbaren Room-Key aus einer Node-Referenz.
func _get_room_key(room: Node2D) -> String:
	if not is_instance_valid(room): return ""
	var rnum = str(room.get("room_number") if room.get("room_number") != null else "")
	if rnum != "" and rnum != "null":
		return rnum
	# Fallback: Koordinaten-Key
	return "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]


## Hilfsfunktion: Findet eine Room-Node anhand ihres Keys.
func _find_room_by_key(map_grid: Node, room_key: String) -> Node2D:
	if not is_instance_valid(map_grid) or room_key == "": return null
	for room in map_grid.active_rooms:
		if not is_instance_valid(room): continue
		var rnum = str(room.get("room_number") if room.get("room_number") != null else "")
		if rnum != "" and rnum != "null" and rnum == room_key:
			return room
		var coord_key = "%s_%d_%d" % [str(room.get("room_type_id")), int(room.get("x_pos")), int(room.get("y_pos"))]
		if coord_key == room_key:
			return room
	return null


## Serialisiert alle offenen/zugewiesenen Tasks (ohne Node-Referenzen).
func to_save_dict() -> Dictionary:
	var saved_tasks: Array = []
	for task in _tasks:
		# Nur Tasks die noch nicht erledigt sind
		if task.get("status", "open") == "done": continue
		var entry := {
			"id": task.get("id", ""),
			"type": task.get("type", ""),
			"status": "open",  # assigned/open → beim Laden als "open" wiederherstellen
			"assigned_to": null,
		}
		# Raum-Target als Key serialisieren
		var target = task.get("target", null)
		if target is Dictionary:
			# serve_meal / clean_table: target ist { room, order_id, pos }
			var room_node = target.get("room", null)
			entry["room_key"] = _get_room_key(room_node)
			entry["order_id"] = target.get("order_id", "")
		elif is_instance_valid(target):
			entry["room_key"] = _get_room_key(target)
		else:
			entry["room_key"] = ""
		saved_tasks.append(entry)
	return {"tasks": saved_tasks, "next_task_id": _next_task_id}


## Lädt Tasks aus dem Save-Dict und verbindet sie mit den Room-Nodes.
func load_from_dict(data: Dictionary, map_grid: Node) -> void:
	_tasks.clear()
	_next_task_id = int(data.get("next_task_id", 1))
	for entry in data.get("tasks", []):
		var task_type: String = entry.get("type", "")
		var room_key: String = entry.get("room_key", "")
		var room_node = _find_room_by_key(map_grid, room_key)
		if task_type in ["clean_room", "repair_room"]:
			if is_instance_valid(room_node):
				var task := {
					"id": entry.get("id", "T%04d" % _next_task_id),
					"type": task_type,
					"target": room_node,
					"status": "open",
					"assigned_to": null,
				}
				_tasks.append(task)
				sig_task_added.emit(task)
		elif task_type in ["serve_meal", "clean_table"]:
			# Gastro-Tasks: room_node + order_id
			if is_instance_valid(room_node):
				var task := {
					"id": entry.get("id", "T%04d" % _next_task_id),
					"type": task_type,
					"target": {
						"room": room_node,
						"order_id": entry.get("order_id", ""),
						"pos": room_node.global_position,
					},
					"status": "open",
					"assigned_to": null,
				}
				_tasks.append(task)
				sig_task_added.emit(task)
