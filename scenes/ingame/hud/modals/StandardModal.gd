extends Control
class_name StandardModal

var _previous_input_mode = null
var modal_input_mode = InputHandler.InputMode.MODAL

signal closed

var back_action: Callable


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
	
	SoundManager.play("modal_open")
	_previous_input_mode = InputHandler.current_mode
	InputHandler.current_mode = modal_input_mode
	visible = true
	$AnimationPlayer.play("fade_in")


# =============================================================================
func close() -> void:
	SoundManager.play("modal_close")
	$AnimationPlayer.play("fade_out")
	await $AnimationPlayer.animation_finished
	visible = false
	closed.emit()

	# Input wiederherstellen
	if _previous_input_mode != null:
		InputHandler.current_mode = _previous_input_mode
	else:
		InputHandler.current_mode = InputHandler.InputMode.NORMAL

func trigger_close_or_back() -> void:
	if back_action.is_valid():
		back_action.call()
	else:
		close()


# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		# Check if there is an active ConfirmModal blocking us
		# If any child is a visible ConfirmModal, do not close the parent modal.
		# (StandardModal typically doesn't spawn ConfirmModals directly, 
		# but if it does or its content does, we might want to be careful. 
		# Actually, ui_cancel closing generic modals is standard.)
		get_viewport().set_input_as_handled()
		trigger_close_or_back()

# =============================================================================
func _on_close_button_pressed() -> void:
	trigger_close_or_back()


# =============================================================================
func set_close_button_visible(show_btn: bool) -> void:
	var btn = find_child("CloseButton", true, false)
	if btn:
		btn.visible = show_btn


# =============================================================================
func set_title(new_title: String) -> void:
	if new_title != "":
		%ModalTitel.text = new_title
		%ModalTitel.visible = true
	else:
		%ModalTitel.visible = false
