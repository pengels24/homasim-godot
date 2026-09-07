extends Node
class_name TutorialScenarioManager

var step_index: int = 1
var is_active: bool = false

# Referenzen
var hud: CanvasLayer
var map: Node2D
var assistant_ui: Node

const ASSISTANT_SCENE := preload("res://scenes/shared/TutorialAssistant.tscn")

var _req_cam_moved: bool = false
var _req_cam_zoomed: bool = false

# Ghost-Target-Prüfung
var _target_room: String = "bed_standard"
var _target_parcel: Vector2i = Vector2i(2, 0)
var _target_tile: Vector2i
var _target_rot: int
var _has_checked_in: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
	if step_index in [7, 13]:
		if InputHandler.current_mode != InputHandler.InputMode.BUILD:
			advance_step()

func start_tutorial(hud_ref: CanvasLayer, map_ref: Node2D) -> void:
	is_active = true
	hud = hud_ref
	map = map_ref
	
	var h := SaveManager.get_hotel(GameState.TUTORIAL_HOTEL_ID)
	if not h.is_empty():
		step_index = h.get("tutorial_step", 1)
	
	_spawn_assistant()
	_lock_ui()
	_run_step()

func _spawn_assistant() -> void:
	assistant_ui = ASSISTANT_SCENE.instantiate()
	hud.add_child(assistant_ui)
	if assistant_ui.has_signal("sig_next_clicked"):
		assistant_ui.sig_next_clicked.connect(_on_next_clicked)

func _lock_ui() -> void:
	var bottom = _get_bottom_bar()
	var build = _get_build_menu()
	if bottom:
		bottom.reception.disabled = true
		bottom.staff.disabled = true
		bottom.tech_tree.disabled = true
		bottom.sim_browser.disabled = true
		bottom.quest_book.disabled = true
		bottom.guest_list.disabled = true
		bottom.room_list.disabled = true
		bottom.tutorial.disabled = true
		bottom.finances.disabled = true
		
	if build:
		build.set_locked(true)
		
	# UI elemente basierend auf Tutorial-Fortschritt wieder freischalten
	if step_index >= 4 and build:
		build.set_locked(false)
	if step_index >= 15 and bottom:
		bottom.reception.disabled = false
	if step_index >= 20 and bottom:
		bottom.staff.disabled = false

func _get_bottom_bar() -> Control:
	if hud and hud.has_node("%HUDBottom"):
		return hud.get_node("%HUDBottom")
	return null

func _get_build_menu() -> Control:
	if hud and hud.has_node("BottomBarContainer/BuildMenu"):
		return hud.get_node("BottomBarContainer/BuildMenu")
	return null

func _run_step() -> void:
	if not is_active:
		return
	
	match step_index:
		1:
			_show_text(GameState.T("tutorial.step.1"), true)
		2:
			_show_text(GameState.T("tutorial.step.2"), false)
			_req_cam_moved = false
			if not InputHandler.sig_camera_pan_requested.is_connected(_on_cam_moved):
				InputHandler.sig_camera_pan_requested.connect(_on_cam_moved)
			if not InputHandler.sig_camera_drag_moved.is_connected(_on_cam_drag_moved):
				InputHandler.sig_camera_drag_moved.connect(_on_cam_drag_moved)
		3:
			_show_text(GameState.T("tutorial.step.3"), false)
			_req_cam_zoomed = false
			if not InputHandler.sig_camera_zoom_requested.is_connected(_on_cam_zoomed):
				InputHandler.sig_camera_zoom_requested.connect(_on_cam_zoomed)
		4:
			_show_text(GameState.T("tutorial.step.4"), false)
			var build = _get_build_menu()
			if build:
				build.set_locked(false)
				var btn = build.get_category_button("zimmer")
				_pulse_bottom_button(btn)
				if not build.sig_build_mode_requested.is_connected(_on_build_opened):
					build.sig_build_mode_requested.connect(_on_build_opened)
		5:
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(8, 5)
			_target_rot = 2
			_target_room = "bed_standard"
			_show_text(GameState.T("tutorial.step.5"), false)
			var build = _get_build_menu()
			if build: build.set_locked(false)
			_slide_assistant(true)
			_pulse_room_button("bed_standard")
			# Ghost-Zwang anwerfen
			GameState.sig_room_built.connect(_on_room_built)
			# Blueprint anzeigen
			_draw_blueprint()
		6:
			_show_text(GameState.T("tutorial.step.6"), false)
			var build = _get_build_menu()
			if build: build.set_locked(false)
			_target_room = "bed_standard"
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(6, 5)
			_target_rot = 0
			_pulse_room_button("bed_standard")
			GameState.sig_room_built.connect(_on_room_built)
			_draw_blueprint()
		7:
			_show_text(GameState.T("tutorial.step.7"), false)
		8:
			_slide_assistant(false)
			_show_text(GameState.T("tutorial.step.8"), true)
		9:
			_show_text(GameState.T("tutorial.step.9"), false)
			if hud and "btn_ff" in hud:
				hud.btn_ff.disabled = true
			_pulse_play_button()
			if not TimeManager.sig_speed_changed.is_connected(_on_time_resumed):
				TimeManager.sig_speed_changed.connect(_on_time_resumed)
		10:
			if TimeManager.get_hour() >= 7:
				advance_step()
			else:
				_show_text(GameState.T("tutorial.step.10_wait"), false)
				if not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
					TimeManager.sig_hour_passed.connect(_on_hour_passed)
		11:
			_show_text(GameState.T("tutorial.step.11"), true)
			_pulse_exp_bar()
		12:
			_show_text(GameState.T("tutorial.step.12"), false)
			var build = _get_build_menu()
			if build: build.set_locked(false)
			_slide_assistant(true)
			_target_room = "bed_double"
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(2, 5)
			_target_rot = 2
			_pulse_room_button("bed_double")
			GameState.sig_room_built.connect(_on_room_built)
			_draw_blueprint()
		13:
			_show_text(GameState.T("tutorial.step.13"), false)
		14:
			_slide_assistant(false)
			if TimeManager.get_hour() >= 8:
				advance_step()
			else:
				_show_text(GameState.T("tutorial.step.14_wait"), false)
				if not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
					TimeManager.sig_hour_passed.connect(_on_hour_passed)
		15:
			_show_text(GameState.T("tutorial.step.15"), false)
			var bottom = _get_bottom_bar()
			if bottom:
				bottom.reception.disabled = false
				_pulse_bottom_button(bottom.reception)
				if not bottom.sig_reception_toggled.is_connected(_on_reception_opened):
					bottom.sig_reception_toggled.connect(_on_reception_opened)
		16:
			_slide_assistant(true)
			_show_text(GameState.T("tutorial.step.16"), true)
		17:
			_has_checked_in = false
			_show_text(GameState.T("tutorial.step.17"), false)
			var guest_mgr = get_parent().get("_guest_mgr")
			if guest_mgr and not guest_mgr.sig_party_checked_in.is_connected(_on_party_checked_in):
				guest_mgr.sig_party_checked_in.connect(_on_party_checked_in)
				
			if hud and hud.has_node("StandardModal"):
				var modal = hud.get_node("StandardModal")
				if not modal.closed.is_connected(_on_reception_closed):
					modal.closed.connect(_on_reception_closed)
		18:
			_slide_assistant(false)
			_show_text(GameState.T("tutorial.step.18"), true)
			var bottom = _get_bottom_bar()
			if bottom:
				_stop_bottom_button_pulse(bottom.reception)
		19:
			_show_text(GameState.T("tutorial.step.19"), true)
		20:
			_show_text(GameState.T("tutorial.step.20"), false)
			var bottom = _get_bottom_bar()
			if bottom:
				_stop_bottom_button_pulse(bottom.reception)
				bottom.staff.disabled = false
				_pulse_bottom_button(bottom.staff)
				if not bottom.sig_staff_toggled.is_connected(_on_staff_opened):
					bottom.sig_staff_toggled.connect(_on_staff_opened)
		21:
			_slide_assistant(false)
			var staff_modal = null
			var std = hud.get_node_or_null("StandardModal")
			if std: staff_modal = std.get_node_or_null("%ContentAnchor/ModalContentStaff")
			
			if is_instance_valid(staff_modal):
				_setup_step_21_modal(staff_modal)
			else:
				_show_text(GameState.T("tutorial.step.21_alt"), false)
				var bottom = _get_bottom_bar()
				if bottom:
					bottom.staff.disabled = false
					_pulse_bottom_button(bottom.staff)
					if not bottom.sig_staff_toggled.is_connected(_on_step_21_staff_opened):
						bottom.sig_staff_toggled.connect(_on_step_21_staff_opened)
		22:
			_show_text(GameState.T("tutorial.step.22"), true)
		23:
			_show_text(GameState.T("tutorial.step.23"), true)
		24:
			_show_text(GameState.T("tutorial.step.24"), false)
			if StaffManager and not StaffManager.sig_staff_hired.is_connected(_on_staff_hired):
				StaffManager.sig_staff_hired.connect(_on_staff_hired)
			_check_hired_staff()
		25:
			_show_text(GameState.T("tutorial.step.25"), false)
			if hud and hud.has_node("StandardModal"):
				var modal = hud.get_node("StandardModal")
				if not modal.closed.is_connected(_on_staff_closed):
					modal.closed.connect(_on_staff_closed)
		26:
			if hud and hud.has_node("StandardModal"):
				var modal = hud.get_node("StandardModal")
				modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentTutorialEnd.tscn")
				modal.open(GameState.T("tutorial.end.title"))
			_end_tutorial()
		_:
			_end_tutorial()

func _show_text(text: String, show_next_btn: bool = false) -> void:
	if is_instance_valid(assistant_ui) and assistant_ui.has_method("set_text"):
		assistant_ui.set_text(text, show_next_btn)

func _slide_assistant(to_right: bool) -> void:
	if not is_instance_valid(assistant_ui): return
	var target_x = 1020.0 if to_right else 560.0
	var tween = create_tween()
	tween.tween_property(assistant_ui, "position:x", target_x, 0.5).set_trans(Tween.TRANS_SINE)

func _on_next_clicked() -> void:
	if step_index in [1, 2, 3, 8, 11, 16, 18, 19, 22, 23]:
		advance_step()

func advance_step() -> void:
	step_index += 1
	SaveManager.update_hotel(GameState.TUTORIAL_HOTEL_ID, {
		"tutorial_step": step_index
	})
	
	# Trigger volles Savegame (inkl. Gäste, Geld, EXP, Räume)
	TimeManager.sig_save_requested.emit(TimeManager.get_game_time())
	
	_run_step()

# --- STEP 2: Kamera Bewegung ---
func _on_cam_moved(_dir: Vector2) -> void:
	if step_index == 2 and not _req_cam_moved:
		_req_cam_moved = true
		_show_text(GameState.T("tutorial.step.2_done"), true)
		InputHandler.sig_camera_pan_requested.disconnect(_on_cam_moved)
		InputHandler.sig_camera_drag_moved.disconnect(_on_cam_drag_moved)

func _on_cam_drag_moved(_pos: Vector2) -> void:
	if step_index == 2 and not _req_cam_moved:
		_req_cam_moved = true
		_show_text(GameState.T("tutorial.step.2_done"), true)
		InputHandler.sig_camera_pan_requested.disconnect(_on_cam_moved)
		InputHandler.sig_camera_drag_moved.disconnect(_on_cam_drag_moved)

# --- STEP 3: Kamera Zoom ---
func _on_cam_zoomed(_dir: float) -> void:
	if step_index == 3 and not _req_cam_zoomed:
		_req_cam_zoomed = true
		_show_text(GameState.T("tutorial.step.3_done"), true)
		InputHandler.sig_camera_zoom_requested.disconnect(_on_cam_zoomed)

# --- STEP 4: Baumenü öffnen ---
func _on_build_opened(active: bool) -> void:
	if step_index == 4 and active:
		var build = _get_build_menu()
		if build:
			build.sig_build_mode_requested.disconnect(_on_build_opened)
			var btn = build.get_category_button("zimmer")
			_stop_bottom_button_pulse(btn)
		advance_step()

# --- STEP 5 & 6 & 11: Zimmer bauen ---
func _draw_blueprint() -> void:
	for child in map.get_world_root().get_children():
		if child.name.begins_with("TutorialBlueprint"):
			child.name = child.name + "_deleted"
			child.queue_free()

	var scene_path = GameState.get_room_scene_path(_target_room)
	if scene_path.is_empty():
		return
		
	var room_scene = load(scene_path) as PackedScene
	if not room_scene:
		return
		
	var bp = room_scene.instantiate()
	bp.name = "TutorialBlueprint"
	
	var px = _target_parcel.x * 256 + _target_tile.x * 16 + 48
	var py = _target_parcel.y * 256 + _target_tile.y * 16 + 48
	bp.position = Vector2(px, py)
	map.get_world_root().add_child(bp)

	if bp.has_method("configure"):
		bp.configure({"door_rotation": _target_rot, "door_offset": 0, "room_rotation": _target_rot})
	bp.room_rotation = _target_rot
	bp._ready()
	if bp.has_method("_apply_visuals"):
		bp._apply_visuals()

	bp.modulate = Color(0.2, 0.5, 1.0, 0.7)
	bp.z_index = 9

func _on_room_built(room_id: String) -> void:
	if step_index in [5, 6, 12]:
		if room_id == _target_room:
			GameState.sig_room_built.disconnect(_on_room_built)
			for child in map.get_world_root().get_children():
				if child.name.begins_with("TutorialBlueprint"):
					child.name = child.name + "_deleted"
					child.queue_free()
			_stop_room_button_pulse(_target_room)
			
			advance_step()

# --- STEP 9: Zeit starten ---
func _on_time_resumed(is_paused: bool, _speed: float) -> void:
	if step_index == 9 and not is_paused:
		TimeManager.sig_speed_changed.disconnect(_on_time_resumed)
		_stop_play_button_pulse()
		if hud and "btn_ff" in hud:
			hud.btn_ff.disabled = false
		advance_step()

# --- STEP 10 & 14: Uhrzeit ---
func _on_hour_passed(hour: int) -> void:
	if step_index == 10 and hour >= 7:
		TimeManager.sig_hour_passed.disconnect(_on_hour_passed)
		TimeManager.user_pause()
		advance_step()
	elif step_index == 14 and hour >= 8:
		TimeManager.sig_hour_passed.disconnect(_on_hour_passed)
		TimeManager.user_pause()
		advance_step()

# --- STEP 15: Rezeption öffnen ---
func _on_reception_opened() -> void:
	if step_index == 15:
		var bottom = _get_bottom_bar()
		if bottom:
			bottom.sig_reception_toggled.disconnect(_on_reception_opened)
			_stop_bottom_button_pulse(bottom.reception)
		advance_step()

# --- STEP 17: Check-In ---
func _on_party_checked_in(_party, _room) -> void:
	if step_index == 17:
		_has_checked_in = true

func _on_reception_closed() -> void:
	if step_index == 17:
		if _has_checked_in:
			var guest_mgr = get_parent().get("_guest_mgr")
			if guest_mgr and guest_mgr.sig_party_checked_in.is_connected(_on_party_checked_in):
				guest_mgr.sig_party_checked_in.disconnect(_on_party_checked_in)
				
			if hud and hud.has_node("StandardModal"):
				var modal = hud.get_node("StandardModal")
				if modal.closed.is_connected(_on_reception_closed):
					modal.closed.disconnect(_on_reception_closed)
			
			advance_step()
		else:
			_show_text(GameState.T("tutorial.step.17_error"), false)
			_pulse_bottom_button(_get_bottom_bar().reception)

# --- STEP 20: Personal öffnen ---
func _on_staff_opened() -> void:
	if step_index == 20:
		var bottom = _get_bottom_bar()
		if bottom:
			bottom.sig_staff_toggled.disconnect(_on_staff_opened)
			_stop_bottom_button_pulse(bottom.staff)
		# Damit das Modal Zeit hat zu spawnen, bevor Step 21 es sucht
		call_deferred("advance_step")

# --- STEP 21: Staff Tab gewechselt ---
func _setup_step_21_modal(modal: Node) -> void:
	_show_text(GameState.T("tutorial.step.21"), false)
	if modal.tab_hbox and modal.tab_hbox.get_child_count() > 1:
		var btn = modal.tab_hbox.get_child(1)
		_pulse_bottom_button(btn)
	if not modal.sig_tab_changed.is_connected(_on_staff_tab_changed):
		modal.sig_tab_changed.connect(_on_staff_tab_changed)

func _on_step_21_staff_opened() -> void:
	if step_index == 21:
		var bottom = _get_bottom_bar()
		if bottom:
			bottom.sig_staff_toggled.disconnect(_on_step_21_staff_opened)
			_stop_bottom_button_pulse(bottom.staff)
		call_deferred("_delayed_step_21_setup")

func _delayed_step_21_setup() -> void:
	if step_index == 21:
		var staff_modal = null
		var std = hud.get_node_or_null("StandardModal")
		if std: staff_modal = std.get_node_or_null("%ContentAnchor/ModalContentStaff")
		if is_instance_valid(staff_modal):
			_setup_step_21_modal(staff_modal)

func _on_staff_tab_changed(tab: int) -> void:
	if step_index == 21 and tab == 1:
		var staff_modal = null
		var std = hud.get_node_or_null("StandardModal")
		if std: staff_modal = std.get_node_or_null("%ContentAnchor/ModalContentStaff")
		
		if is_instance_valid(staff_modal):
			if staff_modal.sig_tab_changed.is_connected(_on_staff_tab_changed):
				staff_modal.sig_tab_changed.disconnect(_on_staff_tab_changed)
			if staff_modal.tab_hbox and staff_modal.tab_hbox.get_child_count() > 1:
				var btn = staff_modal.tab_hbox.get_child(1)
				_stop_bottom_button_pulse(btn)
		advance_step()

# --- STEP 24: Staff checken ---
func _on_staff_hired(_staff) -> void:
	if step_index == 24:
		_check_hired_staff()

func _check_hired_staff() -> void:
	var team = StaffManager.hired_staff.values()
	var has_cleaner = false
	var has_maintenance = false
	for s in team:
		if s.role == "housekeeping": has_cleaner = true
		if s.role == "maintenance": has_maintenance = true
	
	if has_cleaner and has_maintenance:
		if StaffManager.sig_staff_hired.is_connected(_on_staff_hired):
			StaffManager.sig_staff_hired.disconnect(_on_staff_hired)
		advance_step()

# --- STEP 25: Staff Fenster zu ---
func _on_staff_closed() -> void:
	if step_index == 25:
		if hud and hud.has_node("StandardModal"):
			var modal = hud.get_node("StandardModal")
			if modal.closed.is_connected(_on_staff_closed):
				modal.closed.disconnect(_on_staff_closed)
		advance_step()

# --- STEP 10: EXP Pulse ---
func _pulse_exp_bar() -> void:
	if hud and hud.has_node("%EXP"):
		var exp_bar = hud.get_node("%EXP")
		var tween = create_tween().set_loops(4)
		tween.tween_property(exp_bar, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.5)
		tween.tween_property(exp_bar, "modulate", Color(1, 1, 1, 1), 0.5)

func _pulse_play_button() -> void:
	if not hud or not "btn_play" in hud: return
	var btn: Button = hud.btn_play
	if not btn: return
	
	var gold_style = load("res://assets/UI/menu_button_golden_pressed.tres")
	
	var tween = create_tween().set_loops().bind_node(btn)
	tween.tween_callback(func(): 
		btn.add_theme_stylebox_override("normal", gold_style)
		btn.add_theme_stylebox_override("hover", gold_style)
	)
	tween.tween_property(btn, "self_modulate", Color(1.5, 1.5, 0.8), 0.4)
	tween.tween_callback(func(): 
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
	)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.4)
	btn.set_meta("tut_tween", tween)

func _stop_play_button_pulse() -> void:
	if not hud or not "btn_play" in hud: return
	var btn: Button = hud.btn_play
	if not btn: return
	
	var tw = btn.get_meta("tut_tween") if btn.has_meta("tut_tween") else null
	if is_instance_valid(tw):
		tw.kill()
	btn.remove_theme_stylebox_override("normal")
	btn.remove_theme_stylebox_override("hover")
	btn.self_modulate = Color.WHITE
	if btn.has_meta("tut_tween"):
		btn.remove_meta("tut_tween")

func _pulse_bottom_button(btn: Button) -> void:
	if not is_instance_valid(btn): return
	
	var orig_style = btn.get_theme_stylebox("normal")
	var gold_style = load("res://assets/UI/menu_button_golden_pressed.tres")
	btn.set_meta("tut_orig_style", orig_style)
	
	var tween = create_tween().set_loops()
	tween.tween_callback(func(): btn.add_theme_stylebox_override("normal", gold_style))
	tween.tween_interval(0.4)
	tween.tween_callback(func(): btn.add_theme_stylebox_override("normal", orig_style))
	tween.tween_interval(0.4)
	btn.set_meta("tut_tween", tween)

func _stop_bottom_button_pulse(btn: Button) -> void:
	if not is_instance_valid(btn): return
	
	if btn.has_meta("tut_tween"):
		var tween: Tween = btn.get_meta("tut_tween")
		if is_instance_valid(tween):
			tween.kill()
		btn.remove_meta("tut_tween")
	
	if btn.has_meta("tut_orig_style"):
		var orig_style = btn.get_meta("tut_orig_style")
		if orig_style:
			btn.add_theme_stylebox_override("normal", orig_style)
		btn.remove_meta("tut_orig_style")

func _pulse_room_button(room_id: String) -> void:
	if not hud: return
	var btn: Button = null
	var build_menu = null
	# Versuche mehrfach den Button zu finden
	for i in range(20):
		if not is_instance_valid(hud): return
		build_menu = _get_build_menu()
		if build_menu and build_menu.visible and build_menu.has_method("get_room_button"):
				btn = build_menu.get_room_button(room_id)
				if btn: break
		await get_tree().create_timer(0.05).timeout
			
	if not is_instance_valid(btn): return
	var gold_style = load("res://assets/UI/menu_button_golden_pressed.tres")
	
	var tween = create_tween().set_loops().bind_node(btn)
	tween.tween_callback(func(): 
		btn.add_theme_stylebox_override("normal", gold_style)
		btn.add_theme_stylebox_override("hover", gold_style)
	)
	tween.tween_property(btn, "self_modulate", Color(1.5, 1.5, 0.8), 0.4)
	tween.tween_callback(func(): 
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
	)
	tween.tween_property(btn, "self_modulate", Color.WHITE, 0.4)
	btn.set_meta("tut_tween", tween)

func _stop_room_button_pulse(room_id: String) -> void:
	if not hud: return
	var build_menu = _get_build_menu()
	if build_menu and build_menu.has_method("get_room_button"):
		var btn = build_menu.get_room_button(room_id)
		if btn:
			var tw = btn.get_meta("tut_tween") if btn.has_meta("tut_tween") else null
			if is_instance_valid(tw):
				tw.kill()
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_stylebox_override("hover")
			btn.self_modulate = Color.WHITE
			if btn.has_meta("tut_tween"):
				btn.remove_meta("tut_tween")

func _end_tutorial() -> void:
	is_active = false
	if is_instance_valid(assistant_ui):
		assistant_ui.queue_free()
