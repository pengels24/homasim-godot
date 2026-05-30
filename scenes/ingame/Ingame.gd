extends Node2D

## ANG-148 – Ingame-Grundgerüst (Orchestrator)
## ANG-170 – God-File aufgeteilt: HUD → IngameHud, Uhr → IngameClock, Bau → IngameBuild
## ANG-176 – PauseMenu + InGameSaveModal verdrahtet
## ANG-166 – SimBrowser (F7)

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var map_grid: Node2D = $MapGrid
@onready var hud_canvas: CanvasLayer = $HUD
@onready var top_bar: Control        = $HUD/TopBar
# @onready var bottom_bar = $HUD
@onready var bottom_bar = $HUD/BottomBarContainer/HUDBottom
@onready var standard_modal: StandardModal = $HUD/StandardModal

# ── Subsysteme ────────────────────────────────────────────────────────────────
var _hud:            IngameHud
var _clock:          IngameClock
var _build:          IngameBuild
var _autosave_timer: Timer
var _settings_modal: SettingsModal
var _dev_console:    DevConsole
var _pause_menu:     PauseMenu
#var _save_modal:     InGameSaveModal
var _quit_confirm:   ConfirmModal
var _sim_browser:    SimBrowser

var _guest_mgr:         GuestManager
var _rezeption:         Control   # RezeptionModal

var _pause_was_running: bool = false
var _came_from_pause:   bool = false

## Tagesablauf: Stundenbasierte Events. Neue Events hier eintragen – kein Code anfassen.
# todo - externe liste erstellen
const DAILY_SCHEDULE: Array[Dictionary] = [
	{"hour":  6, "event": "day_start"},
	{"hour":  7, "event": "reception_open"},
	{"hour": 10, "event": "guest_arrival"},
	{"hour": 15, "event": "guest_arrival"},
	{"hour": 22, "event": "reception_close"},
]

const SETTINGS_SCENE     := preload("res://scenes/shared/SettingsModal.tscn")
const CONFIRM_SCENE      := preload("res://scenes/shared/ConfirmModal.tscn")
const DEV_CONSOLE_SCENE  := preload("res://scenes/ingame/DevConsole.tscn")
#const SAVE_MODAL_SCENE   := preload("res://scenes/ingame/InGameSaveModal.tscn")
const SIM_BROWSER_SCENE    := preload("res://scenes/ingame/SimBrowser.tscn")

var _hotel: Dictionary = {}

# =============================================================================
func _ready() -> void:
	MusicManager.play_ingame()
	_hotel = _load_hotel()

	# print("--- SAVEGAME DEBUG: Was wurde geladen? ---")
	# print(_hotel)
	# print("------------------------------------------")

	GameState.select_hotel(_hotel)

	_start_map()
	_setup_subsystems()
	await get_tree().process_frame

	# reset-view-button verdrahten
	map_grid.view_saved_changed.connect(hud_canvas.reset_view.set_view_saved_state)
	standard_modal.visibility_changed.connect(_update_map_grid_mode)

	# NEU: Einmaligen Check für die Rezeption (und andere Buttons) beim Start ausführen!
	_restore_button_states()

	# Signale vom globalen InputHandler empfangen
	InputHandler.sig_hotkey_escape_pressed.connect(_on_exit_pressed) # Öffnet das Pausemenü
	InputHandler.sig_hotkey_quicksave_requested.connect(_quick_save)
	InputHandler.sig_hotkey_quickload_requested.connect(_quick_load)

# ── Map-Start ─────────────────────────────────────────────────────────────────

func _start_map() -> void:
	var built: Array = SaveManager.get_built_plots(_hotel.get("id", -1))
	if built.is_empty():
		built = [{ "x": 1, "y": 0, "is_built": true, "entrance_dir": "" }]
	var entry     := Vector2i(built[0]["x"], built[0]["y"])
	var enter_dir : String = built[0].get("entrance_dir", "")
	if enter_dir == "":
		enter_dir = _derive_direction(entry.x, entry.y)
	map_grid.build_map(built, entry, enter_dir)


func _load_hotel() -> Dictionary:
	if GameState.active_hotel_id >= 0:
		var h := SaveManager.get_hotel(GameState.active_hotel_id)
		if not h.is_empty():
			return h
	var hotels: Array = SaveManager.get_hotels(GameState.active_profile_id)
	if not hotels.is_empty():
		return hotels[0]
	return { "name": "Hotel", "day": 1, "money": 50000.0, "id": -1 }


func _derive_direction(px: int, py: int) -> String:
	if py == 0: return "top"
	if py == 4: return "bottom"
	if px == 0: return "left"
	return "right"


# ── Subsystem-Setup ───────────────────────────────────────────────────────────

func _setup_subsystems() -> void:

	# ingame-clock init
	_clock = IngameClock.new()
	add_child(_clock)
	_clock.configure(
		_hotel,
		hud_canvas.label_time,
		hud_canvas.btn_pause,
		hud_canvas.btn_play,
		hud_canvas.btn_ff,
		hud_canvas.label_time,
		hud_canvas.label_day
	)

	# Bausystem
	_build = IngameBuild.new()
	add_child(_build)
	# _build.configure(_hotel, map_grid, top_bar, bottom_bar)
	_build.configure(_hotel, map_grid, $HUD/BottomBarContainer/HUDBottom, $HUD)
	_build.room_built.connect(_on_room_built)

	# NEU: Wir verknüpfen das neue Menü direkt mit dem Bausystem
	$HUD/BottomBarContainer/HUDBottom/BuildMenu.sig_room_selected.connect(_build.start_building)

	# 2. GuestManager (bleibt unverändert)
	_guest_mgr = GuestManager.new()
	add_child(_guest_mgr)
	_guest_mgr.configure(_hotel, _clock, map_grid)
	_guest_mgr.parties_changed.connect(_on_parties_changed)
	_guest_mgr.checkout_forgotten.connect(_on_checkout_forgotten)

	_clock.day_ended.connect(_on_day_ended)
	_clock.save_requested.connect(_save_progress)
	_clock.hour_passed.connect(_guest_mgr.on_hour_passed)
	_clock.hour_passed.connect(_on_hour_passed)
	_setup_autosave_timer()

	# _pause_menu = PAUSE_MENU_SCENE.instantiate() as PauseMenu
	# add_child(_pause_menu)
	# _pause_menu.resume_requested.connect(_on_pause_resume)
	# _pause_menu.save_requested.connect(_on_pause_save)
	# _pause_menu.load_requested.connect(_on_pause_load)
	# _pause_menu.settings_requested.connect(_on_pause_settings)
	# _pause_menu.quit_requested.connect(_on_pause_quit)

	# _save_modal = SAVE_MODAL_SCENE.instantiate() as InGameSaveModal
	# add_child(_save_modal)
	# _save_modal.save_completed.connect(_on_save_modal_completed)
	# _save_modal.load_completed.connect(_on_save_modal_loaded)
	# _save_modal.back_requested.connect(_on_save_modal_back)

	_sim_browser = SIM_BROWSER_SCENE.instantiate() as SimBrowser
	add_child(_sim_browser)

	# 4. Dev-Console (bekommt das Control top_bar übergeben)
	if OS.is_debug_build():
		_dev_console = DEV_CONSOLE_SCENE.instantiate() as DevConsole
		add_child(_dev_console)
		_dev_console.configure(_hotel, top_bar, _clock)
		_dev_console.visibility_changed.connect(_on_dev_console_visibility_changed)


# ── Signal-Handler ────────────────────────────────────────────────────────────

func _on_day_ended(new_day: int) -> void:
	_hud.update_day(new_day)
	_guest_mgr.on_day_ended(new_day)
	SaveManager.save_auto(_hotel.get("id", -1))


func _on_parties_changed() -> void:
	# Die UI-Zahlen aktualisieren sich dank GameState-Signalen ganz von alleine!
	# Wir kümmern uns hier NUR noch um den Rezeptions-Indikator (die rote Ampel).
	var waiting_count := _guest_mgr.get_waiting().size()
	hud_canvas.set_reception_alert(waiting_count > 0)


# func _on_parties_changed() -> void:
# 	_hud.update_guest_stats(
# 		_guest_mgr.get_waiting().size(),
# 		_guest_mgr.get_active().size(),
# 		_guest_mgr.get_checkout().size(),
# 	)
# 	_hud.update_money(_hotel.get("money", 0.0))


func _on_checkout_forgotten(count: int) -> void:
	Toast.show("⚠ %d Gast/Gäste haben noch nicht ausgecheckt!" % count)


func _on_hour_passed(hour: int) -> void:
	for entry: Dictionary in DAILY_SCHEDULE:
		if entry["hour"] == hour:
			_dispatch_daily_event(entry["event"])


func _dispatch_daily_event(event_id: String) -> void:
	match event_id:
		"day_start":       _on_event_day_start()
		"reception_open":  _on_event_reception_open()
		"guest_arrival":   _on_event_guest_arrival()
		"reception_close": _on_event_reception_close()


func _on_event_day_start() -> void:
	Toast.show(GameState.T("toast.event.day_start"))


func _on_event_reception_open() -> void:
	if not _guest_mgr.has_bookable_rooms():
		Toast.show(GameState.T("toast.rezeption.no_rooms"))
		return

	hud_canvas.set_reception_locked(false)
	Toast.show(GameState.T("toast.rezeption.open"))


func _on_event_guest_arrival() -> void:
	var count := _guest_mgr.spawn_guests()
	if count > 0:
		Toast.show(GameState.T("toast.guest.arrival").replace("###", str(count)))


func _on_event_reception_close() -> void:
	if is_instance_valid(_rezeption) and _rezeption.visible:
		_close_rezeption()
	hud_canvas.set_reception_locked(true)
	Toast.show(GameState.T("toast.event.day_soft_end"))


## Sofort nach dem Bau prüfen ob Rezeption freischaltbar ist (Zeit 07-22 + Zimmer vorhanden).
func _on_room_built(_room_type_id: String) -> void:
	var hour: int = _clock.get_hour()
	if hour >= 7 and hour < 22 and _guest_mgr.has_bookable_rooms():
		hud_canvas.set_reception_locked(false)


## Button-States nach dem Laden eines Spielstands wiederherstellen.
func _restore_button_states() -> void:
	var hour: int = _clock.get_hour()
	var reception_should_be_open := hour >= 7 and hour < 22 and _guest_mgr.has_bookable_rooms()
	hud_canvas.set_reception_locked(not reception_should_be_open) # NEU


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			# Schutzschild: Wenn Modals offen sind, blockieren wir hier lokal
			if is_instance_valid(_settings_modal) and _settings_modal.visible: return
			if is_instance_valid(_pause_menu) and _pause_menu.visible: return
			# if is_instance_valid(_save_modal) and _save_modal.visible: return


func _on_bottom_button_pressed(idx: int) -> void:
	match idx:
		1: _open_sim_browser()
		2: _open_settings()
		3: _open_rezeption()
		_: _build.on_button_pressed(idx)


func _on_exit_pressed() -> void:
	# 1. Haben wir gerade ein Zimmer an der Maus? -> Abbrechen!
	if _build.close_all():
		return

	# 2. Ist das Baumenü noch offen? -> Schließen und Modus zurücksetzen!
	if InputHandler.current_mode == InputHandler.InputMode.BUILD:
		hud_canvas.toggle_build_menu()
		return

	# 3. Sonst -> Normales Pausemenü öffnen/schließen
	if standard_modal.visible:
		_close_pause()
	else:
		_open_pause_menu()


# func _on_exit_pressed() -> void:
# 	if _build.close_all():
# 		return

# 	if standard_modal.visible:
# 		_close_pause()
# 	else:
# 		_open_pause_menu()


# ── Pause-Menü ────────────────────────────────────────────────────────────────

# func _open_pause_menu() -> void:
# 	_pause_was_running = not _clock.is_paused()
# 	_clock.pause()
# 	_pause_menu.open()
# 	_update_map_grid_mode()


func _open_pause_menu() -> void:
	_pause_was_running = not _clock.is_paused()
	_clock.pause()

	standard_modal.modal_input_mode = InputHandler.InputMode.PAUSE

	# Hier fangen wir das Inlay auf! (PFAD ANPASSEN)
	var pause_content = standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentPause.tscn")

	# Und hier verbinden wir deine sauberen sig_ Signale
	if pause_content:
		pause_content.sig_resume_requested.connect(_on_pause_resume)
		pause_content.sig_save_requested.connect(_on_pause_save)
		pause_content.sig_load_requested.connect(_on_pause_load)
		pause_content.sig_settings_requested.connect(_on_pause_settings)
		pause_content.sig_quit_requested.connect(_on_pause_quit)

	standard_modal.open(GameState.T("modal.pause.title")) # Oder fester String "PAUSE"
	_update_map_grid_mode()


# func _open_pause_menu() -> void:
# 	# Die alte, funktionierende Zeit-Logik
# 	_pause_was_running = not _clock.is_paused()
# 	_clock.pause()

# 	# neues Modal befeuern
# 	standard_modal.modal_input_mode = InputHandler.InputMode.PAUSE

# 	# WICHTIG: Trage hier den korrekten Pfad zu deiner Pause-Szene ein!
# 	standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentPause.tscn")

# 	standard_modal.open("Pause")

# 	# altes Grid-Update
# 	_update_map_grid_mode()


func _close_pause() -> void:
	standard_modal.close()
	if _pause_was_running:
		_clock.resume()
	_update_map_grid_mode()


# func _update_map_grid_mode() -> void:
# 	var blocked: bool = \
# 			(is_instance_valid(_dev_console)    and _dev_console.visible)    \
# 			or (is_instance_valid(_pause_menu)     and _pause_menu.visible)     \
# #			or (is_instance_valid(_save_modal)     and _save_modal.visible)     \
# 			or (is_instance_valid(_settings_modal) and _settings_modal.visible) \
# 			or (is_instance_valid(_sim_browser)    and _sim_browser.visible)    \
# 			or (is_instance_valid(_rezeption)      and _rezeption.visible)
# 	map_grid.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT


func _update_map_grid_mode() -> void:
	var blocked: bool = \
			(is_instance_valid(_dev_console)    and _dev_console.visible)    \
			or (is_instance_valid(standard_modal) and standard_modal.visible) \
			or (is_instance_valid(_settings_modal) and _settings_modal.visible) \
			or (is_instance_valid(_sim_browser)    and _sim_browser.visible)    \
			or (is_instance_valid(_rezeption)      and _rezeption.visible)

	map_grid.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT


func _on_pause_resume() -> void:
	_close_pause()


# func _on_pause_resume() -> void:
# 	_close_pause()


# ── SimBrowser ────────────────────────────────────────────────────────────────

func _open_sim_browser() -> void:
	_clock.pause()
	_sim_browser.open()
	_update_map_grid_mode()


func _close_sim_browser() -> void:
	_sim_browser.close()
	_clock.resume()
	_update_map_grid_mode()


# ── Rezeption ─────────────────────────────────────────────────────────────────

func _open_rezeption() -> void:
	if not _guest_mgr.has_bookable_rooms():
		Toast.show(GameState.T("toast.rezeption.no_rooms"))
		return
	if not is_instance_valid(_rezeption):
		var scene := load("res://scenes/ingame/rezeption/RezeptionModal.tscn") as PackedScene
		if scene == null:
			return
		_rezeption = scene.instantiate()
		$HUD.add_child(_rezeption)
		_rezeption.closed.connect(_close_rezeption)
		_rezeption.configure(_guest_mgr, _clock)
	_clock.pause()
	_rezeption.visible = true
	_rezeption.refresh()
	_update_map_grid_mode()


func _close_rezeption() -> void:
	if is_instance_valid(_rezeption):
		_rezeption.visible = false
	_update_map_grid_mode()


func _on_pause_save() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0: return

	# Lade den neuen Content dynamisch in den Anchor
	standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSave.tscn")
	standard_modal.set_title(GameState.T("modal.save.title"))

	_update_map_grid_mode()


# func _on_pause_save() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0: return

# 	# Wir tauschen einfach den Inhalt im bereits offenen StandardModal aus
# 	standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSave.tscn")
# 	_update_map_grid_mode()

# func _on_pause_save() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0: return
# 	_close_pause()
# 	_save_modal.open(hotel_id, true)
# 	_update_map_grid_mode()


# func _on_pause_save() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0:
# 		return
# 	_pause_menu.close()
# 	_save_modal.open(hotel_id, true)
# 	_update_map_grid_mode()


func _on_pause_load() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0: return

	# Inhalt für das Laden setzen und die Referenz abgreifen
	var load_content = standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentLoad.tscn")
	standard_modal.set_title(GameState.T("modal.load.title"))

	# Unser neues Signal mit der bestehenden Reload-Funktion verbinden
	if load_content:
		load_content.sig_load_completed.connect(_on_save_modal_loaded)

	_update_map_grid_mode()


# func _on_pause_load() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0: return

# 	# Inhalt für das Laden setzen und die Referenz abgreifen
# 	var load_content = standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentLoad.tscn")

# 	# Unser neues Signal mit der bestehenden Reload-Funktion verbinden
# 	if load_content:
# 		load_content.sig_load_completed.connect(_on_save_modal_loaded)
# 	_update_map_grid_mode()


# func _on_pause_load() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0: return
# 	_close_pause()
# 	_save_modal.open(hotel_id, false)
# 	_update_map_grid_mode()


# func _on_pause_load() -> void:
# 	var hotel_id: int = _hotel.get("id", -1)
# 	if hotel_id < 0:
# 		return
# 	_pause_menu.close()
# 	_save_modal.open(hotel_id, false)
# 	_update_map_grid_mode()


func _on_pause_settings() -> void:
	_came_from_pause = true
	_close_pause()
	_open_settings()


# func _on_pause_settings() -> void:
# 	_came_from_pause = true
# 	_pause_menu.close()
# 	_open_settings()


func _on_pause_quit() -> void:
	standard_modal.visible = false # Versteckt den Rahmen für die Abfrage

	if not is_instance_valid(_quit_confirm):
		_quit_confirm = CONFIRM_SCENE.instantiate() as ConfirmModal
		$HUD.add_child(_quit_confirm)
		_quit_confirm.confirmed.connect(_on_quit_confirmed)
		_quit_confirm.cancelled.connect(func(): standard_modal.visible = true) # Bei Abbruch wieder zeigen

	_quit_confirm.ask(
		GameState.T("ingame.quit.title"),
		GameState.T("ingame.quit.message"),
		GameState.T("ingame.quit.confirm"),
		GameState.T("ingame.quit.cancel")
	)


# func _on_pause_quit() -> void:
# 	_pause_menu.visible = false
# 	if not is_instance_valid(_quit_confirm):
# 		_quit_confirm = CONFIRM_SCENE.instantiate() as ConfirmModal
# 		$HUD.add_child(_quit_confirm)
# 		_quit_confirm.confirmed.connect(_on_quit_confirmed)
# 		_quit_confirm.cancelled.connect(func(): _pause_menu.visible = true)
# 	_quit_confirm.ask(
# 		GameState.T("ingame.quit.title"),
# 		GameState.T("ingame.quit.message"),
# 		GameState.T("ingame.quit.confirm"),
# 		GameState.T("ingame.quit.cancel"),
# 	)


func _on_quit_confirmed() -> void:
	_save_progress(_clock.get_game_time())
	SaveManager.save_auto(_hotel.get("id", -1))
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


# ── Save-Modal ────────────────────────────────────────────────────────────────

# func _on_save_modal_completed() -> void:
# 	_save_modal.close()
# 	_close_pause()


func _on_save_modal_loaded(hotel_id_loaded: int) -> void:
	GameState.active_hotel_id = hotel_id_loaded
	Toast.show_after_scene_change(GameState.T("toast.quickload.ok"))
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")


# func _on_save_modal_back() -> void:
# 	_save_modal.close()
# 	# _pause_menu.open()
# 	_open_pause_menu()
# 	_update_map_grid_mode()


# ── Persistenz ────────────────────────────────────────────────────────────────

func _save_progress(game_time_min: int) -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	var save_data := {
		"day":       _hotel.get("day", 1),
		"money":     _hotel.get("money", 0),
		"xp":        _hotel.get("xp", 0),
		"game_time": game_time_min,
	}
	for key: String in _hotel:
		if key.begins_with("next_") and key.ends_with("_id"):
			save_data[key] = _hotel[key]
	SaveManager.update_hotel(hotel_id, save_data)


func _open_settings() -> void:
	if not is_instance_valid(_settings_modal):
		_settings_modal = SETTINGS_SCENE.instantiate() as SettingsModal
		$HUD.add_child(_settings_modal)
		_settings_modal.closed.connect(_on_settings_closed)
	_settings_modal.open()
	_update_map_grid_mode()


func _on_settings_closed() -> void:
	if _came_from_pause:
		_came_from_pause = false
		# _pause_menu.open()
		_open_pause_menu()
	_update_map_grid_mode()


func _on_dev_console_visibility_changed() -> void:
	_update_map_grid_mode()


func _setup_autosave_timer() -> void:
	if not SettingsManager.autosave_enabled:
		return
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = SettingsManager.autosave_interval_minutes * 60.0
	_autosave_timer.one_shot  = false
	_autosave_timer.timeout.connect(_on_timed_autosave)
	add_child(_autosave_timer)
	_autosave_timer.start()


func _on_timed_autosave() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	_save_progress(_clock.get_game_time())
	SaveManager.save_auto(hotel_id)
	Toast.show(GameState.T("toast.system.autosave"))


func _quick_save() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	_save_progress(_clock.get_game_time())
	SaveManager.save_quick(hotel_id)
	Toast.show(GameState.T("toast.quicksave"))


func _quick_load() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	if SaveManager.load_quick(hotel_id):
		Toast.show_after_scene_change(GameState.T("toast.quickload.ok"))
		get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")
	else:
		Toast.show(GameState.T("toast.quickload.empty"))


# func _notification(what: int) -> void:
# 	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
# 		if is_instance_valid(_clock):
# 			_save_progress(_clock.get_game_time())


func _notification(what: int) -> void:
	# NOTIFICATION_PREDELETE wurde entfernt! Es hat bei JEDEM Szenenwechsel
	# (auch beim Laden) die aktuelle Uhrzeit über den Spielstand drübergepatched.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if is_instance_valid(_clock):
			_save_progress(_clock.get_game_time())