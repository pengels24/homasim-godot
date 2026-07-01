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
var _target_tile: Vector2i = Vector2i(8, 5)
var _target_rot: int = 2

func _ready() -> void:
	pass

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
	if bottom:
		bottom.build_menu.disabled = true
		bottom.reception.disabled = true
		bottom.staff.disabled = true
		bottom.tech_tree.disabled = true
		bottom.sim_browser.disabled = true
		bottom.quest_book.disabled = true
		bottom.guest_list.disabled = true
		bottom.room_list.disabled = true
		bottom.tutorials.disabled = true
		bottom.finances.disabled = true

func _get_bottom_bar() -> Node:
	if hud and hud.has_node("BottomBarContainer/HUDBottom"):
		return hud.get_node("BottomBarContainer/HUDBottom")
	return null

func _run_step() -> void:
	if not is_active:
		return
	
	match step_index:
		1:
			_show_text("Hallo! Ich bin Angelus2010, der Entwickler von HO·MA·SIM.\nIch helfe dir bei deinen ersten Schritten.", true)
		2:
			_show_text("Zuerst müssen wir uns umsehen können.\nBewege die Karte mit der rechten Maustaste (halten & ziehen) oder mit WASD.\n\n[ ] Karte bewegt", false)
			_req_cam_moved = false
			if not InputHandler.sig_camera_pan_requested.is_connected(_on_cam_moved):
				InputHandler.sig_camera_pan_requested.connect(_on_cam_moved)
			if not InputHandler.sig_camera_drag_moved.is_connected(_on_cam_drag_moved):
				InputHandler.sig_camera_drag_moved.connect(_on_cam_drag_moved)
		3:
			_show_text("Gut gemacht!\nNutze nun das Mausrad oder die +/- Tasten auf dem Numpad, um rein- und rauszuzoomen.\n\n[ ] Gezoomt", false)
			_req_cam_zoomed = false
			if not InputHandler.sig_camera_zoom_requested.is_connected(_on_cam_zoomed):
				InputHandler.sig_camera_zoom_requested.connect(_on_cam_zoomed)
		4:
			_show_text("Klasse! Um Gäste zu empfangen, brauchst du ein Zimmer, damit die Rezeption öffnen kann.\nÖffne hierzu das Baumenü (Button unten links oder F2).", false)
			var bottom = _get_bottom_bar()
			if bottom:
				bottom.build_menu.disabled = false
				
				# Pulsieren einbauen (Wechsel zwischen normalem Style und Gold-Pressed)
				var orig_style = bottom.build_menu.get_theme_stylebox("normal")
				var gold_style = load("res://assets/UI/menu_button_golden_pressed.tres")
				bottom.build_menu.set_meta("tut_orig_style", orig_style)
				
				var tween = create_tween().set_loops()
				tween.tween_callback(func(): bottom.build_menu.add_theme_stylebox_override("normal", gold_style))
				tween.tween_interval(0.4)
				tween.tween_callback(func(): bottom.build_menu.add_theme_stylebox_override("normal", orig_style))
				tween.tween_interval(0.4)
				bottom.build_menu.set_meta("tut_tween", tween)
				
				if not bottom.sig_build_menu_toggled.is_connected(_on_build_opened):
					bottom.sig_build_menu_toggled.connect(_on_build_opened)
		5:
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(8, 5)
			_target_rot = 2
			_target_room = "bed_standard"
			_show_text("Wähle ein Einzelzimmer und platziere es. Nutze [R] zum Rotieren, bis es passt!", false)
			var bottom = _get_bottom_bar()
			if bottom: bottom.build_menu.disabled = false
			_slide_assistant(true)
			_pulse_room_button("bed_standard")
			# Ghost-Zwang anwerfen
			GameState.sig_room_built.connect(_on_room_built)
			# Blueprint anzeigen
			_draw_blueprint()
		6:
			_show_text("Super! Wir brauchen aber mehr als ein Zimmer. Baue noch ein weiteres Einzelzimmer daneben.", false)
			var bottom = _get_bottom_bar()
			if bottom: bottom.build_menu.disabled = false
			_target_room = "bed_standard"
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(6, 5)
			_target_rot = 0
			_pulse_room_button("bed_standard")
			GameState.sig_room_built.connect(_on_room_built)
			_draw_blueprint()
		7:
			_slide_assistant(false)
			_show_text("Die Rezeption hat, wie auch andere POI (Points of Interest), Öffnungszeiten. Sie öffnet um 7 Uhr und schließt um 22 Uhr.\nWährend dieser Zeit kommen neue Gäste an und bestehende Gäste nutzen diese POI für ihren Tagesablauf.", true)
		8:
			_show_text("Starte nun die Zeit (oben rechts im Menü oder mit der Leertaste), um das Hotel zum Leben zu erwecken!", false)
			if not TimeManager.sig_speed_changed.is_connected(_on_time_resumed):
				TimeManager.sig_speed_changed.connect(_on_time_resumed)
		9:
			if TimeManager.get_hour() >= 7:
				advance_step()
			else:
				_show_text("Warte nun, bis die Rezeption um 7 Uhr öffnet.", false)
				if not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
					TimeManager.sig_hour_passed.connect(_on_hour_passed)
		10:
			_show_text("Um neue Räume und Funktionen freizuschalten, musst du das Level des Hotels erhöhen.\nHierfür benötigst du EXP. Diese bekommst du für den jeweils ersten Bau eines neuen Zimmertyps und für Ereignisse im Hotelbetrieb (Check-In, Check-Out, u.a.).", true)
			_pulse_exp_bar()
		11:
			_show_text("Baue nun, um noch einmal extra EXP zu bekommen, ein erstes Doppelzimmer.", false)
			var bottom = _get_bottom_bar()
			if bottom: bottom.build_menu.disabled = false
			_slide_assistant(true)
			_target_room = "bed_double"
			_target_parcel = Vector2i(2, 0)
			_target_tile = Vector2i(2, 5)
			_target_rot = 2
			_pulse_room_button("bed_double")
			GameState.sig_room_built.connect(_on_room_built)
			_draw_blueprint()
		12:
			_slide_assistant(false)
			if TimeManager.get_hour() >= 8:
				advance_step()
			else:
				_show_text("Die Rezeption ist nun geöffnet. Um 8 Uhr treffen die ersten Gäste ein!\nStarte die Zeit (falls pausiert) und warte auf ihre Ankunft.", false)
				if not TimeManager.sig_hour_passed.is_connected(_on_hour_passed):
					TimeManager.sig_hour_passed.connect(_on_hour_passed)
		_:
			_end_tutorial()

func _show_text(text: String, show_next_btn: bool = false) -> void:
	if is_instance_valid(assistant_ui) and assistant_ui.has_method("set_text"):
		assistant_ui.set_text(text, show_next_btn)

func _slide_assistant(to_right: bool) -> void:
	if not is_instance_valid(assistant_ui): return
	var target_x = 900.0 if to_right else 560.0
	var tween = create_tween()
	tween.tween_property(assistant_ui, "position:x", target_x, 0.5).set_trans(Tween.TRANS_SINE)

func _on_next_clicked() -> void:
	if step_index in [1, 2, 3, 7, 10]:
		advance_step()

func advance_step() -> void:
	step_index += 1
	SaveManager.update_hotel(GameState.TUTORIAL_HOTEL_ID, {"tutorial_step": step_index})
	if is_instance_valid(map) and map.has_method("save_all_rooms_to_db"):
		map.save_all_rooms_to_db(GameState.TUTORIAL_HOTEL_ID)
	_run_step()

# --- STEP 2: Kamera Bewegung ---
func _on_cam_moved(_dir: Vector2) -> void:
	if step_index == 2 and not _req_cam_moved:
		_req_cam_moved = true
		_show_text("Zuerst müssen wir uns umsehen können.\nBewege die Karte mit der rechten Maustaste (halten & ziehen) oder mit WASD.\n\n[x] Karte bewegt", true)
		InputHandler.sig_camera_pan_requested.disconnect(_on_cam_moved)
		InputHandler.sig_camera_drag_moved.disconnect(_on_cam_drag_moved)

func _on_cam_drag_moved(_pos: Vector2) -> void:
	if step_index == 2 and not _req_cam_moved:
		_req_cam_moved = true
		_show_text("Zuerst müssen wir uns umsehen können.\nBewege die Karte mit der rechten Maustaste (halten & ziehen) oder mit WASD.\n\n[x] Karte bewegt", true)
		InputHandler.sig_camera_pan_requested.disconnect(_on_cam_moved)
		InputHandler.sig_camera_drag_moved.disconnect(_on_cam_drag_moved)

# --- STEP 3: Kamera Zoom ---
func _on_cam_zoomed(_dir: float) -> void:
	if step_index == 3 and not _req_cam_zoomed:
		_req_cam_zoomed = true
		_show_text("Gut gemacht!\nNutze nun das Mausrad oder die +/- Tasten auf dem Numpad, um rein- und rauszuzoomen.\n\n[x] Gezoomt", true)
		InputHandler.sig_camera_zoom_requested.disconnect(_on_cam_zoomed)

# --- STEP 4: Baumenü öffnen ---
func _on_build_opened() -> void:
	if step_index == 4:
		var bottom = _get_bottom_bar()
		if bottom:
			bottom.sig_build_menu_toggled.disconnect(_on_build_opened)
			if bottom.build_menu.has_meta("tut_tween"):
				var tween: Tween = bottom.build_menu.get_meta("tut_tween")
				if tween:
					tween.kill()
			if bottom.build_menu.has_meta("tut_orig_style"):
				var orig_style = bottom.build_menu.get_meta("tut_orig_style")
				if orig_style:
					bottom.build_menu.add_theme_stylebox_override("normal", orig_style)
				bottom.build_menu.remove_meta("tut_orig_style")
		advance_step()

# --- STEP 5 & 6 & 11: Zimmer bauen ---
func _draw_blueprint() -> void:
	var old_bp = map.get_world_root().get_node_or_null("TutorialBlueprint")
	if old_bp:
		old_bp.queue_free()

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

	bp.modulate = Color(0.2, 0.5, 1.0, 0.7)
	bp.z_index = 9

func _on_room_built(room_id: String) -> void:
	if step_index in [5, 6, 11]:
		if room_id == _target_room:
			GameState.sig_room_built.disconnect(_on_room_built)
			var bp = map.get_world_root().get_node_or_null("TutorialBlueprint")
			if bp:
				bp.queue_free()
			_stop_room_button_pulse(_target_room)
			
			if get_parent() and get_parent().get("_ui_mgr"):
				get_parent()._ui_mgr.close_build_menu()
			
			advance_step()

# --- STEP 8: Zeit starten ---
func _on_time_resumed(is_paused: bool, _speed: float) -> void:
	if step_index == 8 and not is_paused:
		TimeManager.sig_speed_changed.disconnect(_on_time_resumed)
		advance_step()

# --- STEP 9 & 12: Uhrzeit ---
func _on_hour_passed(hour: int) -> void:
	if step_index == 9 and hour >= 7:
		TimeManager.sig_hour_passed.disconnect(_on_hour_passed)
		advance_step()
	elif step_index == 12 and hour >= 8:
		TimeManager.sig_hour_passed.disconnect(_on_hour_passed)
		advance_step()

# --- STEP 10: EXP Pulse ---
func _pulse_exp_bar() -> void:
	if hud and hud.has_node("%EXP"):
		var exp_bar = hud.get_node("%EXP")
		var tween = create_tween().set_loops(4)
		tween.tween_property(exp_bar, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.5)
		tween.tween_property(exp_bar, "modulate", Color(1, 1, 1, 1), 0.5)

func _pulse_room_button(room_id: String) -> void:
	if not hud: return
	var btn: Button = null
	var build_menu = null
	# Versuche mehrfach den Button zu finden
	for i in range(20):
		if not is_instance_valid(hud): return
		var bottom = _get_bottom_bar()
		if bottom:
			build_menu = bottom.get_node_or_null("BuildMenu")
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
	var bottom = _get_bottom_bar()
	if not bottom: return
	var build_menu = bottom.get_node_or_null("BuildMenu")
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
	Toast.show("Tutorial abgeschlossen (Vorschau)!")
