extends Node2D

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var map_grid: Node2D = $MapGrid
@onready var hud_canvas: CanvasLayer = $HUD
@onready var top_bar: Control        = $HUD/TopBar
@onready var bottom_bar = $HUD/ManagementContainer/HUDBottom
@onready var standard_modal: StandardModal = $HUD/StandardModal

# ── Subsysteme ────────────────────────────────────────────────────────────────
var _build:          IngameBuild
var _save_ctrl: IngameSaveController
var _ui_mgr: IngameUIManager
var _guest_mgr:        GuestManager
var _staff_controller: StaffController
var _guest_controller: GuestController

const SIM_BROWSER_SCENE    := preload("res://scenes/ingame/SimBrowser.tscn")

var _hotel: Dictionary = {}


# =============================================================================
func _ready() -> void:
	TaskManager.clear_all_tasks()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL

	MusicManager.play_ingame()
	_hotel = _load_hotel()

	GameState.select_hotel(_hotel)

	_start_map()
	_setup_subsystems()
	await get_tree().process_frame

	# Diese Kamera-Pin-Verbindung bleibt hier, da sie nicht zum Menü-System gehört


	# Einmaliger Aufruf zum Start, ob die Rezeption auf oder zu sein soll
	_restore_button_states()

	# DEBUG-Verbindung
	InputHandler.sig_debug_action_requested.connect(_on_debug_action_requested)

	if GameState.is_tutorial_mode:
		var tut_mgr = TutorialScenarioManager.new()
		tut_mgr.name = "TutorialScenarioManager"
		add_child(tut_mgr)
		tut_mgr.start_tutorial(hud_canvas, map_grid)
	else:
		_do_fade_in()

# ── Map-Start ─────────────────────────────────────────────────────────────────

# =============================================================================
func _do_fade_in() -> void:
	var fade_rect = ColorRect.new()
	fade_rect.color = Color.BLACK
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(fade_rect)
	
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(fade_rect.queue_free)
	tween.tween_callback(func(): TutorialManager.trigger("welcome"))
	tween.tween_callback(func():
		if StaffManager and StaffManager.hired_staff.size() > StaffManager.get_max_staff_capacity():
			_ui_mgr.show_info_modal(
				GameState.T("ui.info.staff_capacity.title", "Personal-Limit überschritten"),
				GameState.T("ui.info.staff_capacity.msg", "Du hast mehr Personal eingestellt, als Pausenräume zur Verfügung stehen. Das Spiel läuft normal weiter, aber du musst weitere Pausenräume bauen, bevor du neue Mitarbeiter einstellen kannst.")
			)
	)

# =============================================================================
func _start_map() -> void:
	var built: Array = SaveManager.get_built_plots(_hotel.get("id", -1))

	if built.is_empty():
		if GameState.is_tutorial_mode:
			built = [{ "x": 2, "y": 0, "is_built": true, "entrance_dir": "top" }]
		else:
			built = [{ "x": 1, "y": 0, "is_built": true, "entrance_dir": "" }]

	var entry     := Vector2i(built[0]["x"], built[0]["y"])
	var enter_dir : String = built[0].get("entrance_dir", "")

	if enter_dir == "":
		enter_dir = _derive_direction(entry.x, entry.y)

	map_grid.build_map(built, entry, enter_dir)


# =============================================================================
func _load_hotel() -> Dictionary:
	if GameState.is_tutorial_mode:
		var h = SaveManager.get_hotel(GameState.TUTORIAL_HOTEL_ID)
		if not h.is_empty():
			return h
		return { "name": "Tutorial Hotel", "day": 1, "money": 50000.0, "id": GameState.TUTORIAL_HOTEL_ID }

	if GameState.active_hotel_id >= 0:
		var h := SaveManager.get_hotel(GameState.active_hotel_id)

		if not h.is_empty():
			return h

	var hotels: Array = SaveManager.get_hotels(GameState.active_profile_id)

	if not hotels.is_empty():
		return hotels[0]

	return { "name": "Hotel", "day": 1, "money": 50000.0, "id": -1 }


# =============================================================================
func _derive_direction(px: int, py: int) -> String:
	if py == 0: return "top"
	if py == 4: return "bottom"
	if px == 0: return "left"
	return "right"


# =============================================================================
func get_total_guest_rooms() -> int:
	var count: int = 0
	# Wir nutzen die bereits existierende Funktion von MapGrid!
	for room in map_grid.get_placed_rooms():
		if not room.has_method("get_definition"):
			continue

		var def = room.get_definition()
		if def.get("max_beds", 0) > 0:
			count += 1
	return count


# ── Subsystem-Setup ───────────────────────────────────────────────────────────

# =============================================================================
func _setup_subsystems() -> void:
	TimeManager.setup(_hotel)

	# UI-Updates via Signal abonnieren
	TimeManager.sig_time_updated.connect(func(t: String): if is_instance_valid(hud_canvas.label_time): hud_canvas.label_time.text = t)
	TimeManager.sig_day_updated.connect(func(d: String): if is_instance_valid(hud_canvas.label_day): hud_canvas.label_day.text = d)

	# Buttons verbinden
	hud_canvas.btn_pause.pressed.connect(TimeManager.user_pause)
	hud_canvas.btn_play.pressed.connect(TimeManager.resume)
	hud_canvas.btn_ff.pressed.connect(func(): TimeManager.fast_forward(SettingsManager.ff_speed))
	# --- Rückkanal: Wenn die Zeit per Code geändert wird, HUD visuell anpassen ---
	if not TimeManager.sig_speed_changed.is_connected(_on_time_speed_changed):
		TimeManager.sig_speed_changed.connect(_on_time_speed_changed)

	# GuestManager
	_guest_mgr = GuestManager.new()
	_guest_mgr.name = "GuestManager"
	_guest_mgr.add_to_group("guest_manager")
	add_child(_guest_mgr)
	_guest_mgr.configure(_hotel, map_grid)
	map_grid.guest_manager = _guest_mgr
	
	_guest_controller = GuestController.new()
	add_child(_guest_controller)
	_guest_controller.setup(_guest_mgr, map_grid)
	
	if StaffManager:
		if _hotel.has("staff"):
			StaffManager.load_state(_hotel["staff"])
		else:
			StaffManager.load_state({})
			
	# StaffController
	_staff_controller = StaffController.new()
	add_child(_staff_controller)
	_staff_controller.configure(map_grid)

	for room in map_grid.get_placed_rooms():
		if room.has_method("configure"):
			room.configure({"guest_manager": _guest_mgr})

	if _hotel.has("guest_data"):
		_guest_mgr.load_from_dict(_hotel["guest_data"])
		
	# Jetzt, wo die Daten da sind, können wir die Gäste spawnen
	if _guest_controller:
		_guest_controller.spawn_active_guests()

	_guest_mgr.parties_changed.connect(_on_parties_changed)

	# Bausystem
	_build = IngameBuild.new()
	add_child(_build)
	_build.configure(_hotel, map_grid, $HUD/ManagementContainer/HUDBottom, $HUD)
	_build.sig_room_built.connect(_on_room_built)
	$HUD/BottomBarContainer/BuildMenu.sig_room_selected.connect(_build.start_building)
	$HUD/BottomBarContainer/BuildMenu.sig_tool_selected.connect(_build._on_tool_selected)
	$HUD/BottomBarContainer/BuildMenu.sig_build_cancelled.connect(_build.close_all)
	_build.sig_build_ended.connect($HUD/BottomBarContainer/BuildMenu.clear_active_button)
	$HUD/BottomBarContainer/BuildMenu.sig_build_mode_requested.connect(func(active: bool):
		if active:
			_ui_mgr.open_build_menu()
		else:
			_ui_mgr.close_build_menu()
	)

	# Signale vom TimeManager fangen
	TimeManager.sig_hour_passed.connect(_guest_mgr.on_hour_passed)
	TimeManager.sig_day_ended.connect(_on_event_day_end)

	var sim_browser = SIM_BROWSER_SCENE.instantiate() as SimBrowser
	add_child(sim_browser)

	# Tagesplan-Manager (Wecker)
	var schedule_mgr := IngameScheduleManager.new()
	schedule_mgr.name = "IngameScheduleManager"
	add_child(schedule_mgr)
	schedule_mgr.setup()
	schedule_mgr.sig_schedule_event.connect(_on_schedule_event)

	# Save-Controller (Archivar)
	_save_ctrl = IngameSaveController.new()
	add_child(_save_ctrl)
	_save_ctrl.setup(_hotel, _guest_mgr, map_grid)

	# UI-Manager (Zeremonienmeister)
	_ui_mgr = IngameUIManager.new()
	add_child(_ui_mgr)
	_ui_mgr.setup(hud_canvas, bottom_bar, map_grid, standard_modal, sim_browser, _build, _guest_mgr, schedule_mgr)



# ── Signal-Handler ────────────────────────────────────────────────────────────


# =============================================================================
func _on_parties_changed() -> void:
	var waiting_count := _guest_mgr.get_waiting().size()
	var checkout_count := _guest_mgr.get_checkout().size()
	hud_canvas.set_reception_alert((waiting_count + checkout_count) > 0)


# =============================================================================
func _on_schedule_event(event_id: String) -> void:
	match event_id:
		"day_start":       _on_event_day_start()
		"reception_open":  _on_event_reception_open()
		"guest_arrival":   _on_event_guest_arrival()
		"reception_last_call": _on_event_reception_last_call()
		"reception_close": _on_event_reception_close()


# =============================================================================
func _on_event_day_end(_day: int) -> void:
	# Wird nun via TimeManager.sig_day_ended aufgerufen (24:00 Uhr)
	_ui_mgr.show_end_of_day(_guest_mgr)

func _on_event_day_start() -> void:
	# Toast entfernt, da die Cinematic bereits "Ein neuer Tag beginnt" anzeigt.
	ActivityLog.add(
		"system", 
		"Tag %d beginnt" % _hotel.get("day", 1), 
		_hotel.get("day", 1), 
		TimeManager.get_game_time()
	)


# =============================================================================
func _on_event_reception_open() -> void:
	if get_total_guest_rooms() == 0:
		# Wenn es 07:00 Uhr wird, der Spieler aber noch kein Zimmer hat,
		# lassen wir die Rezeption zu und sparen uns nervige Toasts.
		return

	hud_canvas.set_reception_locked(false)
	Toast.show(GameState.T("toast.reception.open"), "guest", false)
	
	# Quality of Life: Auto-Pause, wenn Gäste warten oder auschecken wollen
	if _guest_mgr.get_waiting().size() > 0 or _guest_mgr.get_checkout().size() > 0:
		if not TimeManager.is_paused():
			TimeManager.trigger_auto_pause()
			Toast.show(GameState.T("toast.reception.auto_pause", "Auto-Pause: Gäste an der Rezeption!"), "guest", false)


# =============================================================================
func _on_event_guest_arrival() -> void:
	print("[Ingame] _on_event_guest_arrival triggered!")
	var count := _guest_mgr.spawn_guests()
	print("[Ingame] _guest_mgr.spawn_guests returned: ", count)

	if count == 1:
		TimeManager.trigger_auto_pause()
		Toast.show(GameState.T("toast.guest.arrival.single"), "guest")
	elif count > 1:
		TimeManager.trigger_auto_pause()
		Toast.show(GameState.T("toast.guest.arrival.multi").replace("###", str(count)), "guest")


# =============================================================================
# ANGEPASST: Der harte Cut um 22:00 Uhr
func _on_event_reception_close() -> void:
	_ui_mgr.close_reception()
	hud_canvas.set_reception_locked(true)
	Toast.show(GameState.T("toast.event.day_soft_end"))

	# Alle Gäste in Lobby/Bar zurück ins Zimmer schicken
	if _guest_controller:
		_guest_controller.send_lobby_guests_to_rooms()

	# HIER feuert jetzt zentral die Strafe für alle, die noch draußen standen
	_guest_mgr.clear_waiting_guests_with_penalty()


# =============================================================================
func _on_room_built(_room_type_id: String) -> void:
	var hour: int = TimeManager.get_hour()
	# Wenn ein Raum gebaut wird, schauen wir: Ist es Tag UND haben wir Gästezimmer?
	if hour >= 7 and hour < 22 and get_total_guest_rooms() > 0:
		hud_canvas.set_reception_locked(false)
		
	# Wir aktualisieren den Tagesplan, damit sofort Gäste spawnen können (falls es das erste Zimmer war)
	var schedule_mgr = get_node_or_null("IngameScheduleManager")
	if schedule_mgr and schedule_mgr.has_method("recalculate_guest_spawns"):
		schedule_mgr.recalculate_guest_spawns()


# =============================================================================
func _restore_button_states() -> void:
	var hour: int = TimeManager.get_hour()
	var reception_should_be_open := hour >= 7 and hour < 22 and get_total_guest_rooms() > 0
	hud_canvas.set_reception_locked(not reception_should_be_open)


# =============================================================================
func _on_time_speed_changed(is_paused: bool, speed: float) -> void:
	if not is_instance_valid(hud_canvas):
		return

	if is_paused:
		# Spiel ist pausiert -> Pause-Button eindrücken
		hud_canvas.btn_pause.set_pressed_no_signal(true)
	elif speed > 1.0:
		# Spiel läuft schneller -> FF-Button eindrücken
		# (Passe die 1.0 an, falls deine Normalgeschwindigkeit ein anderer Wert ist)
		hud_canvas.btn_ff.set_pressed_no_signal(true)
	else:
		# Spiel läuft normal -> Play-Button eindrücken
		hud_canvas.btn_play.set_pressed_no_signal(true)

	if hud_canvas.has_method("set_pause_visuals"):
		hud_canvas.set_pause_visuals(is_paused)


# =============================================================================
# NEU: Die Vorwarnung um 21:30 Uhr
func _on_event_reception_last_call() -> void:
	# Wenn gar niemand wartet, stören wir den Spieler auch nicht
	if _guest_mgr.get_waiting().size() > 0:
		TimeManager.trigger_auto_pause()
		Toast.show(GameState.T("toast.checkin.last_call"), "guest")


# =============================================================================
# (Veraltete Debug-Action entfernt)
# =============================================================================
func _on_debug_action_requested() -> void:
	pass
