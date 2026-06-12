# InputHandler

extends Node

# Die verschiedenen Zustände des Spiels
enum InputMode {
	NORMAL,      # Kamera bewegen, UI klicken
	BUILD,       # Bau-Modus aktiv
  MODAL,       # Modal offen (Rezeption, Settings, Techtree) - hintergrund blockiert!
	PAUSE,       # Pause-Menü offen
	CONSOLE      # Dev-Konsole offen
}

var current_mode: InputMode = InputMode.NORMAL
var is_view_saved: bool = false
var _reset_frame_lock: int = -1

# ── SIGNALE ────────────────────────────────────────────────
# camera
signal sig_camera_pan_requested(direction: Vector2) # WASD
signal sig_camera_zoom_requested(direction: float)  # ZOOM
signal sig_camera_save_view_requested()
signal sig_camera_restore_view_requested()
# camera right-click map-moving
signal sig_camera_drag_started(start_position: Vector2)
signal sig_camera_drag_moved(current_position: Vector2)
signal sig_camera_drag_ended()
signal sig_kill_reset_pin_requested() # Feuert, wenn eine Aktion den Pin killen soll
# ── UI HOTKEYS ─────────────────────────────────────────────
signal sig_hotkey_build_menu_requested
signal sig_hotkey_reception_requested
signal sig_hotkey_staff_requested
signal sig_hotkey_tech_tree_requested
signal sig_hotkey_sim_browser_requested
signal sig_hotkey_escape_pressed
signal sig_hotkey_quicksave_requested
signal sig_hotkey_quickload_requested


# =============================================================================
func _ready() -> void:
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS


# =============================================================================
func _process(delta: float) -> void:
	# Wenn Pause, ein Modal oder die Konsole offen ist, blockieren wir jegliche Tastatur-Bewegung
	if current_mode in [InputMode.PAUSE, InputMode.MODAL, InputMode.CONSOLE]:
		return

	# WASD-KAMERABEWEGUNG (Erlaubt im Normal- und im Bau-Modus!)
	if current_mode == InputMode.NORMAL or current_mode == InputMode.BUILD:
		var dir := Vector2.ZERO
		if Input.is_key_pressed(KEY_D): dir.x += 1.0
		if Input.is_key_pressed(KEY_A): dir.x -= 1.0
		if Input.is_key_pressed(KEY_S): dir.y += 1.0
		if Input.is_key_pressed(KEY_W): dir.y -= 1.0

		if dir != Vector2.ZERO:
			sig_camera_pan_requested.emit(dir.normalized() * delta)
			sig_kill_reset_pin_requested.emit() # WASD killt den Pin

	# TASTATUR-ZOOM (Numpad - gilt für Normal und Bauen)
	var zoom_dir := 0.0
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		zoom_dir = 1.0
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		zoom_dir = -1.0

	if zoom_dir != 0.0:
		sig_camera_zoom_requested.emit(zoom_dir * delta * 10.0)
		if current_mode == InputMode.NORMAL:
			sig_kill_reset_pin_requested.emit() # Tastatur-Zoom im Normalmodus killt den Pin


# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
# ── TÜRSTEHER FÜR MODAL, PAUSE & CONSOLE ────────────────────────────────
	if current_mode in [InputMode.PAUSE, InputMode.MODAL, InputMode.CONSOLE]:

		# Wenn wir in PAUSE oder MODAL sind, darf NUR die ESC-Taste durch!
		if current_mode in [InputMode.PAUSE, InputMode.MODAL] and event.is_action_pressed("ui_escape"):
			get_viewport().set_input_as_handled()
			sig_hotkey_escape_pressed.emit()
		return

	# POS1-TASTE (Zentraler Reset - Nur im Normal-Modus)
	if event.is_action_pressed("map_reset_camera_view") and not event.is_echo() and current_mode == InputMode.NORMAL:
		# Die Frame-Sperre bleibt als Sicherheit drin
		if _reset_frame_lock == Engine.get_frames_drawn():
			return
		_reset_frame_lock = Engine.get_frames_drawn()

		get_viewport().set_input_as_handled()

		# HIER PASSIERT JETZT DIE EXAKTE TRENNUNG:
		if not is_view_saved:
			sig_camera_save_view_requested.emit()
		else:
			sig_camera_restore_view_requested.emit()
		return

	# ── ALLGEMEINE HOTKEYS (Über InputMap) ──────────────────────────────────────
	# Hier können Tasten in jedem Modus reagieren (z.B. zum Schließen von Menüs)

	if event.is_action_pressed("ui_escape"):
		get_viewport().set_input_as_handled()
		sig_hotkey_escape_pressed.emit()
		return

	if event.is_action_pressed("ui_build_menu"):
		get_viewport().set_input_as_handled()
		sig_hotkey_build_menu_requested.emit()
		return

	if event.is_action_pressed("ui_reception"):
		get_viewport().set_input_as_handled()
		sig_hotkey_reception_requested.emit()
		return

	if event.is_action_pressed("ui_staff"):
		get_viewport().set_input_as_handled()
		sig_hotkey_staff_requested.emit()
		return

	if event.is_action_pressed("ui_quicksave"):
		get_viewport().set_input_as_handled()
		sig_hotkey_quicksave_requested.emit()
		return

	if event.is_action_pressed("ui_tech_tree"):
		get_viewport().set_input_as_handled()
		sig_hotkey_tech_tree_requested.emit()
		return

	if event.is_action_pressed("ui_sim_browser"):
		get_viewport().set_input_as_handled()
		sig_hotkey_sim_browser_requested.emit()
		return

	if event.is_action_pressed("ui_quickload"):
		get_viewport().set_input_as_handled()
		sig_hotkey_quickload_requested.emit()
		return

	# ── MODUS: NORMAL-MODUS EINGABEN ──────────────────────────────────────────
	if current_mode in [InputMode.NORMAL, InputMode.BUILD]:
	#if current_mode == InputMode.NORMAL:
		# Mausrad-Zoom (Darf laut Regel den Pin NIE killen!)
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				sig_camera_zoom_requested.emit(1.0)
				return
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				sig_camera_zoom_requested.emit(-1.0)
				return

		# Linksklick auf die Karte (Killt den Pin)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			sig_kill_reset_pin_requested.emit()
			return

		# Rechte Maustaste: Karte ziehen (Drag)
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				sig_camera_drag_started.emit(event.position)
			else:
				sig_camera_drag_ended.emit()
			return

		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			sig_camera_drag_moved.emit(event.position)
			return

		# Jede andere "echte" Taste im Normalmodus killt den Pin
		if event is InputEventKey and event.pressed:
			sig_kill_reset_pin_requested.emit()
