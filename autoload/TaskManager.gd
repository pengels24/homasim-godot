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
	print("[TaskManager] Ticket an schwarzes Brett gepinnt: %s (%s)" % [task.id, type])
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
		print("[TaskManager] Ticket erledigt und entfernt: %s" % task.id)
		sig_task_completed.emit(task)
		
		# Wenn es ein Raum war, den Raum auf "clean" setzen und wieder freigeben
		if task.type == "clean_room" and is_instance_valid(task.target):
			var room = task.target
			room.set("cleanliness_level", 100)
			room.set_service_requested(false)
			sig_room_cleaned.emit(room)
			
		elif task.type == "repair_room" and is_instance_valid(task.target):
			var room = task.target
			room.set("maintenance_level", 100)
			room.set("is_repair_requested", false)
			# signal für repair existiert (noch) nicht, also nur update_indicator via property change
			if room.has_method("_update_indicator"):
				room.call("_update_indicator")


func _on_room_needs_cleaning(room: Node2D) -> void:
	add_task("clean_room", room)

func _on_room_needs_repair(room: Node2D) -> void:
	add_task("repair_room", room)


# Debug-Methode für den manuellen Mausklick
func debug_complete_room_clean(room: Node2D) -> void:
	for task in _tasks:
		if task.type == "clean_room" and task.target == room:
			complete_task(task.id)
			return
	print("[TaskManager] Warnung: Kein Clean-Ticket für diesen Raum gefunden!")
