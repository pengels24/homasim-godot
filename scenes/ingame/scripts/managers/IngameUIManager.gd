extends Node
class_name IngameUIManager

var _hud: CanvasLayer
var _bottom_bar: Control
var _map_grid: Node2D
var _standard_modal: StandardModal
var _sim_browser: SimBrowser
var _build: IngameBuild
var _schedule_mgr: IngameScheduleManager

var _guest_mgr: GuestManager
var _reception: Control
var _quit_confirm: Node
var _came_from_pause: bool = false
var _modal_is_pausing: bool = false

var _overlay_toolbar = null
var _current_overlay: String = "none"


# =============================================================================
func _set_modal_pausing(should_pause: bool) -> void:
	if should_pause and not _modal_is_pausing:
		TimeManager.add_system_pause()
		_modal_is_pausing = true
	elif not should_pause and _modal_is_pausing:
		TimeManager.remove_system_pause()
		_modal_is_pausing = false

const CONFIRM_SCENE := preload("res://scenes/shared/ConfirmModal.tscn")

# =============================================================================
func setup(hud: CanvasLayer, bottom: Control, map: Node2D, modal: StandardModal, browser: SimBrowser, build: IngameBuild, guest_mgr: GuestManager, schedule_mgr: IngameScheduleManager) -> void:
	_hud = hud
	_bottom_bar = bottom
	_map_grid = map
	_standard_modal = modal
	_sim_browser = browser
	if _sim_browser:
		_sim_browser.sig_closed.connect(close_sim_browser)
	_build = build
	_guest_mgr = guest_mgr
	_schedule_mgr = schedule_mgr # <--- NEUE ZEILE
	
	if _schedule_mgr and not _schedule_mgr.sig_next_event_updated.is_connected(_hud.set_next_event):
		_schedule_mgr.sig_next_event_updated.connect(_hud.set_next_event)
		_schedule_mgr._update_next_event_ui()

	_overlay_toolbar = _hud.get_node_or_null("OverlayToolbar")
	if _overlay_toolbar:
		_overlay_toolbar.overlay_changed.connect(_on_overlay_changed)


	if _guest_mgr and not _guest_mgr.parties_changed.is_connected(_update_overlays_if_active):
		_guest_mgr.parties_changed.connect(_update_overlays_if_active)
	if GameState and not GameState.sig_room_built.is_connected(_update_overlays_if_active):
		GameState.sig_room_built.connect(_update_overlays_if_active)
	if GameState and not GameState.sig_room_demolished.is_connected(_update_overlays_if_active):
		GameState.sig_room_demolished.connect(_update_overlays_if_active)

	if TimeManager and not TimeManager.sig_minute_passed.is_connected(_on_minute_passed):
		TimeManager.sig_minute_passed.connect(_on_minute_passed)


	if not is_instance_valid(_bottom_bar):
		return

	_bottom_bar.sig_reception_toggled.connect(open_reception)
	_bottom_bar.sig_sim_browser_toggled.connect(open_sim_browser)
	_bottom_bar.sig_staff_toggled.connect(open_staff)
	_bottom_bar.sig_tech_tree_toggled.connect(open_tech_tree)
	_bottom_bar.sig_quest_book_toggled.connect(open_quest_book)
	_bottom_bar.sig_guest_list_toggled.connect(open_guest_list)
	_bottom_bar.sig_room_list_toggled.connect(open_room_list)
	_bottom_bar.sig_tutorial_toggled.connect(open_tutorial_codex)

	_bottom_bar.sig_finances_toggled.connect(open_finances)

	_standard_modal.visibility_changed.connect(update_map_grid_mode)
	_standard_modal.hidden.connect(_on_standard_modal_hidden)

	# Hotkeys
	# ESC
	if not InputHandler.sig_hotkey_escape_pressed.is_connected(on_exit_pressed):
		InputHandler.sig_hotkey_escape_pressed.connect(on_exit_pressed)
	# buildmenu is no longer toggled via hotkey
	# reception
	if not InputHandler.sig_hotkey_reception_requested.is_connected(open_reception):
		InputHandler.sig_hotkey_reception_requested.connect(open_reception)
	# staff
	if not InputHandler.sig_hotkey_staff_requested.is_connected(open_staff):
		InputHandler.sig_hotkey_staff_requested.connect(open_staff)
	# techtree
	if not InputHandler.sig_hotkey_tech_tree_requested.is_connected(open_tech_tree):
		InputHandler.sig_hotkey_tech_tree_requested.connect(open_tech_tree)
	# simbrowser
	if not InputHandler.sig_hotkey_sim_browser_requested.is_connected(open_sim_browser):
		InputHandler.sig_hotkey_sim_browser_requested.connect(open_sim_browser)
	# questbook
	if not InputHandler.sig_hotkey_quest_book_requested.is_connected(open_quest_book):
		InputHandler.sig_hotkey_quest_book_requested.connect(open_quest_book)
	# codex/tutorial
	if not InputHandler.sig_hotkey_tutorial_requested.is_connected(open_tutorial_codex):
		InputHandler.sig_hotkey_tutorial_requested.connect(open_tutorial_codex)
	# guest list
	if not InputHandler.sig_hotkey_guest_list_requested.is_connected(open_guest_list):
		InputHandler.sig_hotkey_guest_list_requested.connect(open_guest_list)
	# room list
	if not InputHandler.sig_hotkey_room_list_requested.is_connected(open_room_list):
		InputHandler.sig_hotkey_room_list_requested.connect(open_room_list)
	# finances
	if not InputHandler.sig_hotkey_finances_requested.is_connected(open_finances):
		InputHandler.sig_hotkey_finances_requested.connect(open_finances)

	if OS.is_debug_build() and is_instance_valid(GlobalConsole):
		if not GlobalConsole.visibility_changed.is_connected(update_map_grid_mode):
			GlobalConsole.visibility_changed.connect(update_map_grid_mode)

	# Schedule-Events abfangen (Rezeption auf/zu)
	if not _schedule_mgr.sig_schedule_event.is_connected(_on_schedule_event):
		_schedule_mgr.sig_schedule_event.connect(_on_schedule_event)

	# Neues Kabel: UI lauscht auf Zeitsprünge
	if not TimeManager.has_signal("sig_time_jumped"):
		push_error("[UIManager] ❌ TimeManager braucht 'sig_time_jumped'!")

	elif not TimeManager.sig_time_jumped.is_connected(_on_time_jumped):
		TimeManager.sig_time_jumped.connect(_on_time_jumped)

	# Beim Laden des Spiels direkt prüfen, wie spät es ist, und den Button anpassen
	_sync_reception_lock_by_time()

	# NEU: Wir horchen auf den GuestManager und synchronisieren das UI sofort!
	if not _guest_mgr.parties_changed.is_connected(_sync_guest_ui):
		_guest_mgr.parties_changed.connect(_sync_guest_ui)

	# Initial einmal synchronisieren (wichtig für Spielstart & Savegame Load!)
	_sync_guest_ui()

	if not GameState.sig_techdemo_completed.is_connected(_on_techdemo_completed):
		GameState.sig_techdemo_completed.connect(_on_techdemo_completed)

	if not GameState.sig_open_codex_tech.is_connected(open_codex_at_tech):
		GameState.sig_open_codex_tech.connect(open_codex_at_tech)


# ── Zeit-Steuerung (Veraltet, direkt TimeManager nutzen) ───────────────


# =============================================================================
# NEU: Reagiert auf die DevConsole
func _on_time_jumped(_new_time: int) -> void:
	_sync_reception_lock_by_time()


# ── State & Map ───────────────────────────────────────────────────────────────

# =============================================================================
func cleanup_current_states(keep_modal: bool = false) -> void:
	if InputHandler.current_mode == InputHandler.InputMode.BUILD:
		close_build_menu()
	if is_instance_valid(_sim_browser) and _sim_browser.visible:
		_sim_browser.close()
	if not keep_modal and is_instance_valid(_standard_modal) and _standard_modal.visible:
		_standard_modal.close()
		
	if is_instance_valid(_standard_modal):
		_standard_modal.back_action = Callable()

	update_map_grid_mode()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("")


# =============================================================================
func _on_techdemo_completed() -> void:
	cleanup_current_states()
	_set_modal_pausing(true)
	var content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentTechDemoEnd.tscn")
	if content and content.has_signal("sig_close_requested"):
		content.sig_close_requested.connect(_standard_modal.close)
	_standard_modal.open(GameState.T("ui.modal.techdemo_end.title", "TechDemo Abgeschlossen"))


# =============================================================================
func update_map_grid_mode() -> void:
	pass # Removed: Changing process_mode to DISABLED removes Area2Ds from the physics space.
	# If the game is paused, they are never added back until unpaused.
	# Input is safely blocked by InputHandler.current_mode checks instead.


# ── Input Handling ────────────────────────────────────────────────────────────


# =============================================================================
func on_exit_pressed() -> void:
	if InputHandler.current_mode == InputHandler.InputMode.BUILD:
		if is_instance_valid(_build) and _build.has_active_cursor():
			_build.close_all() # First close the ghost
		else:
			close_build_menu() # Then exit build mode completely
		return
	if is_instance_valid(_sim_browser) and _sim_browser.visible:
		close_sim_browser()
		return
	if is_instance_valid(_standard_modal) and _standard_modal.visible:
		_standard_modal.close()
		return
	open_pause_menu()

# =============================================================================
func open_tutorial_codex() -> void:
	cleanup_current_states(true)
	var codex = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentTutorials.tscn")
	if not is_instance_valid(codex): return

	_set_modal_pausing(true)
	_bottom_bar.sync_button_state("tutorial")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.tutorial.title"))
	else:
		_standard_modal.open(GameState.T("modal.tutorial.title"))

	update_map_grid_mode()

# =============================================================================
func open_codex_at_tech(tech_id: String) -> void:
	cleanup_current_states(true)
	var codex = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentTutorials.tscn")
	if not is_instance_valid(codex): return

	_set_modal_pausing(true)
	_bottom_bar.sync_button_state("tutorial")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.tutorial.title"))
	else:
		_standard_modal.open(GameState.T("modal.tutorial.title"))
		
	_standard_modal.back_action = Callable(self, "open_tech_tree")
		
	if codex.has_method("open_tech"):
		codex.open_tech(tech_id)

	update_map_grid_mode()


# ── Build Menü ────────────────────────────────────────────────────────────────


# =============================================================================
func toggle_build_menu() -> void:
	if InputHandler.current_mode == InputHandler.InputMode.NORMAL:
		open_build_menu()
	elif InputHandler.current_mode == InputHandler.InputMode.BUILD:
		close_build_menu()


# =============================================================================
func open_build_menu() -> void:
	if InputHandler.current_mode != InputHandler.InputMode.BUILD:
		TimeManager.add_system_pause()
		InputHandler.current_mode = InputHandler.InputMode.BUILD
		if is_instance_valid(_bottom_bar):
			_bottom_bar.sync_button_state("build")
			
		if is_instance_valid(_hud) and _hud.has_method("set_build_mode_visuals"):
			_hud.set_build_mode_visuals(true)
		
		if TutorialManager:
			TutorialManager.trigger("build_mode")


# =============================================================================
func close_build_menu() -> void:
	if _build:
		_build.close_all()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL
	TimeManager.remove_system_pause()
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("")
	
	if is_instance_valid(_hud):
		if _hud.has_method("set_build_mode_visuals"):
			_hud.set_build_mode_visuals(false)
		var build_menu = _hud.get_node_or_null("BottomBarContainer/BuildMenu")
		if build_menu and build_menu.has_method("close_build_menu"):
			build_menu.close_build_menu()


# ── Rezeption ─────────────────────────────────────────────────────────────────


# =============================================================================
func open_reception() -> void:
	# 1. HÄRTESTER CHECK: Gibt es überhaupt ECHTE Gästezimmer (Betten > 0)?
	var total_rooms: int = 0
	if is_instance_valid(_map_grid) and _map_grid.has_method("get_placed_rooms"):
		for room in _map_grid.get_placed_rooms():
			if room.has_method("get_definition") and room.get_definition().get("max_beds", 0) > 0:
				total_rooms += 1

	if total_rooms == 0:
		Toast.show(GameState.T("toast.reception.no_rooms"), "guest", false)
		return

	# 2. ZEIT-CHECK: Es gibt Räume, aber hat die Rezeption schon auf?
	if TimeManager.get_hour() < 7 or TimeManager.get_hour() >= 22:
		Toast.show(GameState.T("toast.reception.too_early"), "guest", false)
		return

	# 3. VERFÜGBARKEITS-CHECK: Hat das Hotel ZIMMER FREI für NEUE Gäste?
	# Optional: Diesen Toast könntest du weglassen, wenn der Spieler die
	# Rezeption trotzdem öffnen darf, um z.B. nur Check-Outs zu bearbeiten.
	if not _guest_mgr.has_bookable_rooms() and _guest_mgr.get_checkout().size() == 0:
		Toast.show(GameState.T("toast.reception.no_rooms"), "guest", false)
		return

	# --- AB HIER: Alles gut, mach das Ding auf! ---
	cleanup_current_states(true)
	_reception = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentReception.tscn")
	if not is_instance_valid(_reception): return

	_reception.configure(_guest_mgr)
	_reception.refresh()
	_set_modal_pausing(true)

	if TutorialManager:
		TutorialManager.trigger("reception")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.reception.title"))
	else:
		_standard_modal.open(GameState.T("modal.reception.title"))

	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("reception")
	update_map_grid_mode()


# =============================================================================
func close_reception() -> void:
	if is_instance_valid(_reception):
		_reception.visible = false
	update_map_grid_mode()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL


# =============================================================================
## Wird von außen (z.B. vom Baumodus oder Tag/Nacht-Zyklus) aufgerufen,
## um zu prüfen, ob der Button klickbar sein darf.
func update_reception_button_state() -> void:
	if not is_instance_valid(_bottom_bar): return

	var total_rooms = SaveManager.get_built_plots(GameState.active_hotel_id).size()
	var has_rooms: bool = (total_rooms > 0)

	# Hier gehen wir davon aus, dass deine _bottom_bar eine Methode hat,
	# um den Button zu enablen/disablen. (Name ggf. anpassen!)
	if _bottom_bar.has_method("set_reception_disabled"):
		_bottom_bar.set_reception_disabled(not has_rooms)


# =============================================================================
func show_end_of_day(guest_mgr: GuestManager) -> void:
	cleanup_current_states()
	_set_modal_pausing(true)
	_standard_modal.modal_input_mode = InputHandler.InputMode.PAUSE
	
	var eod_scene = load("res://scenes/ingame/hud/modals/content/ModalContentEndOfDay.tscn")
	var eod_content = eod_scene.instantiate()
	eod_content._guest_mgr = guest_mgr
	
	# Wichtig: Zuerst Signal verbinden, dann ins Modal setzen
	eod_content.sig_continue_requested.connect(_on_end_of_day_continue)
	
	_standard_modal.set_content(eod_content)
	
	# Verstecke den Schließen-Button, damit man den Tag nicht abbrechen kann!
	_standard_modal.set_close_button_visible(false)
		
	var title = "Tagesabschluss - Tag %d abgeschlossen" % GameState.selected_hotel.get("day", 1)
	if _standard_modal.visible:
		_standard_modal.set_title(title)
	else:
		_standard_modal.open(title)


# =============================================================================
func _on_end_of_day_continue() -> void:
	# 1. Modal zu
	if is_instance_valid(_standard_modal):
		# Close-Button wieder einblenden für zukünftige Modals
		_standard_modal.set_close_button_visible(true)
		_standard_modal.close()
		
	# 2. Cinematic spawnen
	var transition_scene = load("res://scenes/ingame/hud/modals/DayTransitionModal.tscn")
	var transition = transition_scene.instantiate()
	_hud.add_child(transition)
	
	# 3. Wenn Cinematic dunkel ist, Backend triggern
	transition.sig_midnight_hidden.connect(func():
		var current_day: int = GameState.selected_hotel.get("day", 1)
		
		# Setze Zeit offiziell auf 24:00 für Logs etc.
		TimeManager.set_game_time(24 * 60)
		
		# Strafen austeilen
		if is_instance_valid(_guest_mgr):
			_guest_mgr.process_midnight_penalties(current_day)
			_guest_mgr.demolish_pending_rooms(true)
			
		# Nächsten Tag starten (Zeit wird intern auf 06:00 gesetzt)
		TimeManager.start_next_day()
	)


# =============================================================================
func _on_schedule_event(event_id: String) -> void:
	match event_id:
		"reception_close":
			_lock_reception()
		"reception_open":
			_unlock_reception()


# =============================================================================
func _lock_reception() -> void:
	# 1. Button im HUD visuell sperren (Nutzt deine bestehende Funktion!)
	if is_instance_valid(_bottom_bar):
		_bottom_bar.set_reception_locked(true)
		_bottom_bar.reception.tooltip_text = GameState.T("hud.bottom.reception_closed_tt", "bis 07:00 Uhr")

	# 2. Hard-Lock: Wenn das Rezeptions-Modal gerade offen ist -> ZWANGSSCHLIESSEN!
	# Wir werfen den Spieler einfach aus dem Modal, als hätte er ESC gedrückt
	if is_instance_valid(_standard_modal) and _standard_modal.visible:
		# Nur schließen, wenn wir wirklich das Rezeptions-Fenster offen haben
		if is_instance_valid(_reception) and _reception.is_visible_in_tree():
			_standard_modal.close()
			Toast.show(GameState.T("toast.reception.force_close"), "guest", false)


# =============================================================================
func _unlock_reception() -> void:
	# 1. Button wieder freigeben
	if is_instance_valid(_bottom_bar):
		_bottom_bar.set_reception_locked(false)
		_bottom_bar.reception.tooltip_text = GameState.T("hud.bottom.reception_tt", _bottom_bar._get_action_key_string("ui_reception"))
		
		# 2. Prüfen, ob schon Leute warten
		if is_instance_valid(_guest_mgr) and is_instance_valid(_hud):
			var w = _guest_mgr.get_waiting().size()
			var c = _guest_mgr.get_checkout().size()
			if _hud.has_method("set_reception_alert"):
				_hud.set_reception_alert(w > 0 or c > 0)


# =============================================================================
# ANGEPASST: Nutzt jetzt deinen GameState!
func _sync_reception_lock_by_time() -> void:
	if _hud == null:
		return

	# Raum-Definition der Lobby aus der neuen Architektur holen
	# WICHTIG: Stelle sicher, dass "lobby" in deiner RoomDefinitions / Rooms-Liste existiert!
	# Falls du es woanders gespeichert hast, passe den Pfad an (z.B. RoomDefinitions.ALL.get("lobby", {}))
	var lobby_def: Dictionary = {"open_from": 420, "open_to": 1320} # <--- HIER: Temporärer Platzhalter, bis du mir sagst, woher die Definition genau kommt!

	if GameState.is_facility_open(lobby_def):
		_unlock_reception()
	else:
		_lock_reception()


# ── Pause Menü ────────────────────────────────────────────────────────────────

# =============================================================================
func open_pause_menu() -> void:
	if is_instance_valid(_hud):
		SaveManager.capture_thumbnail(_hud.get_viewport())
		
	_set_modal_pausing(true)
	_standard_modal.modal_input_mode = InputHandler.InputMode.PAUSE
	var pause_content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentPause.tscn")

	if pause_content:
		pause_content.sig_resume_requested.connect(func(): _standard_modal.close(); TimeManager.remove_system_pause(); update_map_grid_mode())
		pause_content.sig_save_requested.connect(_on_pause_save)
		pause_content.sig_load_requested.connect(_on_pause_load)
		pause_content.sig_settings_requested.connect(func(): _came_from_pause = true; _open_settings())
		pause_content.sig_quit_requested.connect(_on_pause_quit)

	_standard_modal.open(GameState.T("modal.pause.title"))
	update_map_grid_mode()


# =============================================================================
func _on_pause_save() -> void:
	var save_content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSave.tscn")
	_standard_modal.set_title(GameState.T("modal.save.title"))
	if save_content and save_content.has_signal("sig_save_completed"):
		save_content.sig_save_completed.connect(func(): _standard_modal.close(); TimeManager.remove_system_pause(); update_map_grid_mode())
	update_map_grid_mode()



# =============================================================================
func _on_pause_load() -> void:
	var load_content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentLoad.tscn")
	_standard_modal.set_title(GameState.T("modal.load.title"))
	if load_content:
		load_content.sig_load_completed.connect(_on_save_modal_loaded)
	update_map_grid_mode()


# =============================================================================
func _on_pause_quit() -> void:
	_standard_modal.visible = false
	if not is_instance_valid(_quit_confirm):
		_quit_confirm = CONFIRM_SCENE.instantiate()
		_hud.add_child(_quit_confirm)
		_quit_confirm.confirmed.connect(_on_quit_confirmed)
		_quit_confirm.cancelled.connect(func(): _standard_modal.visible = true)

	_quit_confirm.ask(
		GameState.T("ingame.quit.title"), GameState.T("ingame.quit.message"),
		GameState.T("ingame.quit.confirm"), GameState.T("ingame.quit.cancel"),
		"", true
	)


# =============================================================================
func _on_quit_confirmed() -> void:
	TimeManager.sig_save_requested.emit(TimeManager.get_game_time())
	var hotel_id: int = GameState.active_hotel_id
	if hotel_id >= 0:
		SaveManager.save_auto(hotel_id)

	# Alle offenen Tickets löschen – beim nächsten Start wird neu geprüft
	TaskManager.clear_all_tasks()

	get_tree().paused = false

	GameState.open_dashboard_next = true
	GameState.active_hotel_id = -1 # <-- Reset, damit Settings nicht "ingame" denken
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# =============================================================================
func _on_save_modal_loaded(hotel_id_loaded: int) -> void:
	GameState.active_hotel_id = hotel_id_loaded
	Toast.show_after_scene_change(GameState.T("toast.quickload.ok"), "system", false)
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")


# ── Settings & Modal Core ─────────────────────────────────────────────────────

# =============================================================================
func _open_settings() -> void:
	_standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSettings.tscn")
	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.settings.title"))
	else:
		_standard_modal.open(GameState.T("modal.settings.title"))
	update_map_grid_mode()


# =============================================================================
func _on_standard_modal_hidden() -> void:
	if is_instance_valid(_reception):
		_reception.hide()

	if _came_from_pause:
		_came_from_pause = false
		call_deferred("open_pause_menu")
	else:
		_set_modal_pausing(false)
		InputHandler.current_mode = InputHandler.InputMode.NORMAL
		if is_instance_valid(_bottom_bar):
			_bottom_bar.sync_button_state("")
		update_map_grid_mode()


# ── Gäste ────────────────────────────────────────────────────────────────

# =============================================================================
func _sync_guest_ui() -> void:
	# 1. Das Top-HUD (über den GameState Briefkasten) updaten
	var waiting_count = 0
	for p in _guest_mgr.get_waiting(): waiting_count += p.members.size()
	
	var active_count = 0
	for p in _guest_mgr.get_active(): active_count += p.members.size()
	
	var checkout_count = 0
	for p in _guest_mgr.get_checkout(): checkout_count += p.members.size()

	if GameState.has_signal("sig_hotel_guests_checkin_changed"):
		GameState.sig_hotel_guests_checkin_changed.emit(waiting_count)
	if GameState.has_signal("sig_hotel_guests_active_changed"):
		GameState.sig_hotel_guests_active_changed.emit(active_count)
	if GameState.has_signal("sig_hotel_guests_checkout_changed"):
		GameState.sig_hotel_guests_checkout_changed.emit(checkout_count)

	# 2. Den Ampel-Indikator steuern
	# Alarm (True) wenn Gäste warten ODER abreisen wollen
	var needs_attention: bool = (waiting_count > 0) or (checkout_count > 0)

	if is_instance_valid(_hud) and _hud.has_method("set_reception_alert"):
		_hud.set_reception_alert(needs_attention)


# ── Personal (F4) ─────────────────────────────────────────────────────────────

# =============================================================================
func open_staff() -> void:
	var level = GameState.selected_hotel.get("level", 1)
	
	if level < GameState.UNLOCK_LEVELS.staff:
		Toast.show(GameState.T("toast.hr.locked") % GameState.UNLOCK_LEVELS.staff, "staff", false)
		return
		
	if TutorialManager:
		TutorialManager.trigger("staff")
		
	cleanup_current_states(true)
	var staff_modal = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentStaff.tscn")
	if not is_instance_valid(staff_modal): return

	_set_modal_pausing(true)

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.staff.title"))
	else:
		_standard_modal.open(GameState.T("modal.staff.title"))


# ── Forschung & Techtree (F6) ──────────────────────────────────────────────────

# =============================================================================
func open_tech_tree() -> void:
	if GameState.selected_hotel.get("level", 1) < GameState.UNLOCK_LEVELS.techtree:
		Toast.show(GameState.T("toast.techtree.locked") % GameState.UNLOCK_LEVELS.techtree, "research", false)
		return

	cleanup_current_states(true)
	var content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentTechtree.tscn")
	if not is_instance_valid(content): return

	_set_modal_pausing(true)

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.techtree.title"))
	else:
		_standard_modal.open(GameState.T("modal.techtree.title"))

	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("tech_tree")
	update_map_grid_mode()
	
	if TutorialManager:
		TutorialManager.trigger("tech_tree")




# ── Sim Browser (F7) ──────────────────────────────────────────────────────────

# =============================================================================
func open_sim_browser() -> void:
	if not TechtreeManager.is_tech_unlocked("M1.1"):
		Toast.show(GameState.T("toast.simbrowser.locked"), "research", false)
		return

	if TutorialManager:
		TutorialManager.trigger("sim_browser")

	cleanup_current_states()
	
	if _sim_browser:
		_sim_browser.open()
		if is_instance_valid(_bottom_bar):
			_bottom_bar.sync_button_state("sim_browser")
		TimeManager.add_system_pause()
		InputHandler.current_mode = InputHandler.InputMode.MODAL
		update_map_grid_mode()

# =============================================================================
func close_sim_browser() -> void:
	if _sim_browser and _sim_browser.visible:
		_sim_browser.close()
	TimeManager.remove_system_pause()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("")
	update_map_grid_mode()

# ── Aufgabenbuch ──────────────────────────────────────────────────────────────

# =============================================================================
func open_quest_book() -> void:
	if _standard_modal.visible and _standard_modal.get_title() == GameState.T("modal.questbook.title"):
		_standard_modal.close()
		return
	
	cleanup_current_states(true)
	var qbook = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentQuestbook.tscn")
	if not is_instance_valid(qbook): return
	
	if TutorialManager:
		TutorialManager.trigger("quest_book")

	_set_modal_pausing(true)
	
	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.questbook.title"))
	else:
		_standard_modal.open(GameState.T("modal.questbook.title"))
		
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("quest_book")
	update_map_grid_mode()


func open_guest_list() -> void:
	if _standard_modal.visible and _standard_modal.get_title() == GameState.T("modal.guestlist.title"):
		_standard_modal.close()
		return
		
	cleanup_current_states(true)
	var content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentGuestList.tscn")
	if not is_instance_valid(content): return
	
	_set_modal_pausing(false)

	if TutorialManager:
		TutorialManager.trigger("guest_list")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.guestlist.title"))
	else:
		_standard_modal.open(GameState.T("modal.guestlist.title"))

func open_room_list() -> void:
	if _standard_modal.visible and _standard_modal.get_title() == GameState.T("modal.roomlist.title"):
		_standard_modal.close()
		return
		
	cleanup_current_states(true)
	var content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentRoomList.tscn")
	if not is_instance_valid(content): return
	
	_set_modal_pausing(false)

	if TutorialManager:
		TutorialManager.trigger("room_list")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.roomlist.title"))
	else:
		_standard_modal.open(GameState.T("modal.roomlist.title"))
# =============================================================================
func open_finances() -> void:
	if _standard_modal.visible and _standard_modal.get_title() == GameState.T("modal.finances.title"):
		_standard_modal.close()
		return
		
	cleanup_current_states(true)
	var content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentFinances.tscn")
	if not is_instance_valid(content): return
	
	_set_modal_pausing(true)
	
	_bottom_bar.sync_button_state("finances")

	if TutorialManager:
		TutorialManager.trigger("finances")

	if _standard_modal.visible:
		_standard_modal.set_title(GameState.T("modal.finances.title"))
	else:
		_standard_modal.open(GameState.T("modal.finances.title"))


# =============================================================================
# Overlay Logic
# =============================================================================

func _on_overlay_changed(type: String) -> void:
	_current_overlay = type
	_update_overlays()
	if is_instance_valid(_hud) and _hud.has_method("set_overlay_legend_visuals"):
		_hud.set_overlay_legend_visuals(type)


func _update_overlays_if_active(_room_id: String = "", _unique_id: String = "") -> void:
	if _current_overlay != "none":
		_update_overlays()

func _on_minute_passed(time: int) -> void:
	# Update overlays every 15 minutes
	if _current_overlay != "none" and time % 15 == 0:
		_update_overlays()

func _update_overlays() -> void:
	if not is_instance_valid(_map_grid):
		return
		
	var rooms = _map_grid.get_placed_rooms()
	
	if _current_overlay == "none":
		for room in rooms:
			if room.has_method("set_overlay_color"):
				room.set_overlay_color(Color(0, 0, 0, 0))
		return
		
	for room in rooms:
		if not room.has_method("set_overlay_color"):
			continue
			
		var color := Color(0, 0, 0, 0)
		var def = {}
		if room.has_method("get_definition"):
			def = room.get_definition()
		
		match _current_overlay:
			"dirt":
				var clean = room.get("cleanliness_level")
				if clean != null:
					# 100 = transparent, 0 = red (0.75 alpha)
					var factor = clampf((100.0 - clean) / 100.0, 0.0, 1.0)
					color = Color(1.0, 0.0, 0.0, factor * 0.75)
					
			"maintenance":
				var maint = room.get("maintenance_level")
				if maint != null:
					var factor = clampf((100.0 - maint) / 100.0, 0.0, 1.0)
					color = Color(1.0, 0.0, 0.0, factor * 0.75)
					
			"occupancy":
				var is_poi = def.get("is_poi", false)
				if is_poi:
					# POIs sind dauerhaft grau
					color = Color(0.5, 0.5, 0.5, 0.75)
				else:
					var rid = room.get("room_number")
					if rid != null and _guest_mgr and _guest_mgr._room_assign.has(rid):
						var status = _guest_mgr._room_assign[rid]
						if typeof(status) == TYPE_STRING:
							if status == "DIRTY":
								color = Color(1.0, 0.5, 0.0, 0.75) # Orange for dirty/checkout
							elif status.begins_with("RSV_"):
								color = Color(0.0, 0.0, 1.0, 0.75) # Blue for reserved
							else:
								var party = _guest_mgr.get_party(status)
								if party and party.get("state") == "checkout":
									color = Color(1.0, 0.5, 0.0, 0.75) # Orange if leaving
								else:
									color = Color(1.0, 0.0, 0.0, 0.75) # Red for occupied
						else:
							color = Color(1.0, 0.0, 0.0, 0.75)
					else:
						# Free
						color = Color(0.0, 1.0, 0.0, 0.75)
						
			"category":
				var cat = def.get("category", "")
				match cat:
					"zimmer": color = Color(0.0, 0.5, 1.0, 0.75)
					"gastro": color = Color(1.0, 0.5, 0.0, 0.75)
					"infrastruktur": color = Color(0.6, 0.4, 0.2, 0.75)
					"service": color = Color(0.5, 0.5, 0.5, 0.75)
					_: color = Color(1.0, 1.0, 1.0, 0.75)
					
			"value":
				var price = def.get("nightly_price", 0)
				var cat = def.get("category", "")
				if price > 0:
					# Besserer Kontrast: Basis-Preis ~40 bis ~250
					var factor = clampf((price - 40.0) / 200.0, 0.0, 1.0)
					# Lerp von dunklem, matten Grün zu extrem leuchtendem Hellgrün
					color = Color(0.1, 0.3, 0.1, 0.75).lerp(Color(0.2, 1.0, 0.2, 0.75), factor)
				elif cat == "gastro":
					# Gastro-Betriebe (Bar etc.) bringen ebenfalls viel Geld
					color = Color(0.6, 0.9, 0.1, 0.75)
				else:
					# Keine direkte Einnahmequelle (Lobby, Infrastruktur)
					color = Color(0.6, 0.6, 0.6, 0.75)

		room.set_overlay_color(color)
