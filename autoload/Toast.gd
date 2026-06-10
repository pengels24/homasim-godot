# Toast

extends Node
## Toast – globaler Singleton für kurze UI-Benachrichtigungen.
## Aufruf: Toast.show("Meine Nachricht")
## Ein laufender Toast wird sofort durch den neuen ersetzt (kein Stapeln).

const TOAST_SCENE := preload("res://scenes/shared/ToastNotification.tscn")

var _active:  ToastNotification = null
var _pending: String = ""


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)


## Zeigt eine Benachrichtigung sofort an.
func show(message: String) -> void:
	if is_instance_valid(_active):
		_active.queue_free()
	_active = TOAST_SCENE.instantiate() as ToastNotification
	get_tree().get_root().add_child(_active)
	_active.play(message)
	_active.tree_exited.connect(func(): _active = null)


## Merkt eine Nachricht vor, die nach dem nächsten Szenenwechsel angezeigt wird.
## Nötig bei change_scene_to_file(), da Root-Children dabei entfernt werden.
func show_after_scene_change(message: String) -> void:
	_pending = message


func _on_node_added(node: Node) -> void:
	if _pending.is_empty():
		return
	if node.get_parent() == get_tree().get_root():
		var msg := _pending
		_pending = ""
		show(msg)
