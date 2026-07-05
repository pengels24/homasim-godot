# Toast

extends Node
## Toast – globaler Singleton für kurze UI-Benachrichtigungen.
## Aufruf: Toast.show("Meine Nachricht")
## Ein laufender Toast wird sofort durch den neuen ersetzt (kein Stapeln).

const TOAST_SCENE := preload("res://scenes/shared/ToastNotification.tscn")

var _active: ToastNotification = null
var _pending: String = ""
var _pending_cat: String = "info"
var _pending_log_it: bool = true
var _toast_queue: Array[Dictionary] = []


func _ready() -> void:
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_node_added)


## Fügt eine Benachrichtigung zur Warteschlange hinzu und zeigt sie an, sobald Platz ist.
func show(message: String, category: String = "info", log_it: bool = true) -> void:
	_toast_queue.append({"msg": message, "cat": category, "log": log_it})
	
	if log_it and ActivityLog and GameState.selected_hotel and not GameState.selected_hotel.is_empty():
		ActivityLog.add(
			category,
			message,
			GameState.selected_hotel.get("day", 1),
			TimeManager.get_game_time()
		)
		
	_process_queue()

func _process_queue() -> void:
	if is_instance_valid(_active) or _toast_queue.is_empty():
		return
		
	var next_toast: Dictionary = _toast_queue.pop_front()
	_active = TOAST_SCENE.instantiate() as ToastNotification
	
	# Verwende call_deferred für add_child, da sonst "busy setting up children" auftritt
	get_tree().get_root().call_deferred("add_child", _active)
	
	# Da call_deferred das Hinzufügen verzögert, müssen wir auch das Aufrufen von play verzögern,
	# damit @onready Variablen innerhalb des Toasts bereits initialisiert wurden!
	_active.call_deferred("play", next_toast)
	
	# Wenn der Toast fertig ist, das nächste Element aus der Queue holen
	_active.tree_exited.connect(func():
		_active = null
		_process_queue()
	)


## Merkt eine Nachricht vor, die nach dem nächsten Szenenwechsel angezeigt wird.
## Nötig bei change_scene_to_file(), da Root-Children dabei entfernt werden.
func show_after_scene_change(message: String, category: String = "info", log_it: bool = true) -> void:
	_pending = message
	_pending_cat = category
	_pending_log_it = log_it
	
	if log_it and ActivityLog and GameState.selected_hotel and not GameState.selected_hotel.is_empty():
		ActivityLog.add(
			category,
			message,
			GameState.selected_hotel.get("day", 1),
			TimeManager.get_game_time()
		)


func _on_node_added(node: Node) -> void:
	if _pending.is_empty():
		return
	if node.get_parent() == get_tree().get_root():
		if _pending != "":
			show(_pending, _pending_cat, _pending_log_it)
			_pending = ""
			return
