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
