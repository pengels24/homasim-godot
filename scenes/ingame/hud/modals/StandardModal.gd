extends Control
class_name StandardModal

var _previous_input_mode = null
var modal_input_mode = InputHandler.InputMode.MODAL


# =============================================================================
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


# =============================================================================
func set_content(content_node_or_path) -> Node: # <--- WICHTIG: -> Node statt -> void
	for child in %ContentAnchor.get_children():
		child.queue_free()

	var content: Node = null
	if content_node_or_path is String:
		var scene = load(content_node_or_path)
		if scene:
			content = scene.instantiate()
	elif content_node_or_path is Node:
		content = content_node_or_path

	if content:
		%ContentAnchor.add_child(content)
		return content

	return null


# =============================================================================
# ── ÖFFNEN & SCHLIESSEN ──────────────────────────────────────────────────────
func open(title_text: String = "") -> void:
	# Verhindert, dass der Modus überschrieben wird, wenn es schon offen ist!
	if visible:
		return

	set_title(title_text)
	_previous_input_mode = InputHandler.current_mode
	InputHandler.current_mode = modal_input_mode
	visible = true
	$AnimationPlayer.play("fade_in")


# =============================================================================
func close() -> void:
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	visible = false

	# Input wiederherstellen
	if _previous_input_mode != null:
		InputHandler.current_mode = _previous_input_mode
	else:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL


# =============================================================================
func _on_close_button_pressed() -> void:
	close()


# =============================================================================
func set_close_button_visible(is_visible: bool) -> void:
	var btn = find_child("CloseButton", true, false)
	if btn:
		btn.visible = is_visible


# =============================================================================
func set_title(new_title: String) -> void:
	if new_title != "":
		%ModalTitel.text = new_title
		%ModalTitel.visible = true
	else:
		%ModalTitel.visible = false
