extends Node
class_name IngameUIManager

var _hud: CanvasLayer
var _bottom_bar: Control
var _map_grid: Node2D
var _standard_modal: StandardModal
var _sim_browser: SimBrowser
var _build: IngameBuild
var _guest_mgr: GuestManager
var _schedule_mgr: IngameScheduleManager # <--- NEUE ZEILE

var _reception: Control
var _quit_confirm: Node
var _pause_was_running: bool = false
var _came_from_pause: bool = false

const CONFIRM_SCENE := preload("res://scenes/shared/ConfirmModal.tscn")

# =============================================================================
func setup(hud: CanvasLayer, bottom: Control, map: Node2D, modal: StandardModal, browser: SimBrowser, build: IngameBuild, guest_mgr: GuestManager, schedule_mgr: IngameScheduleManager) -> void:
	_hud = hud
	_bottom_bar = bottom
	_map_grid = map
	_standard_modal = modal
	_sim_browser = browser
	_build = build
	_guest_mgr = guest_mgr
	_schedule_mgr = schedule_mgr # <--- NEUE ZEILE

	# UI Signale
	_bottom_bar.sig_build_menu_toggled.connect(toggle_build_menu)
	_bottom_bar.sig_reception_toggled.connect(open_reception)
	_bottom_bar.sig_sim_browser_toggled.connect(open_sim_browser)

	_standard_modal.visibility_changed.connect(update_map_grid_mode)
	_standard_modal.hidden.connect(_on_standard_modal_hidden)

	# Hotkeys
	# ESC
	if not InputHandler.sig_hotkey_escape_pressed.is_connected(on_exit_pressed):
		InputHandler.sig_hotkey_escape_pressed.connect(on_exit_pressed)
	# buildmenu
	if not InputHandler.sig_hotkey_build_menu_requested.is_connected(toggle_build_menu):
		InputHandler.sig_hotkey_build_menu_requested.connect(toggle_build_menu)
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


# ── Zeit-Steuerung ────────────────────────────────────────────────────────────

# =============================================================================
func _pause_time_for_ui() -> void:
	if InputHandler.current_mode == InputHandler.InputMode.NORMAL:
		_pause_was_running = not TimeManager.is_paused()
	TimeManager.pause()


# =============================================================================
func _resume_time_after_ui() -> void:
	if _pause_was_running:
		TimeManager.resume()


# =============================================================================
# NEU: Reagiert auf die DevConsole
func _on_time_jumped(_new_time: int) -> void:
	_sync_reception_lock_by_time()


# ── State & Map ───────────────────────────────────────────────────────────────

# =============================================================================
func cleanup_current_states() -> void:
	if InputHandler.current_mode == InputHandler.InputMode.BUILD:
		close_build_menu()
	if is_instance_valid(_sim_browser) and _sim_browser.visible:
		_sim_browser.close()
	if is_instance_valid(_standard_modal) and _standard_modal.visible:
		_standard_modal.close()

	update_map_grid_mode()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("")


# =============================================================================
func update_map_grid_mode() -> void:
	var c_vis = GlobalConsole.visible if is_instance_valid(GlobalConsole) else false
	var m_vis = _standard_modal.is_visible_in_tree() if is_instance_valid(_standard_modal) else false
	var s_vis = _sim_browser.visible if is_instance_valid(_sim_browser) else false
	var r_vis = _reception.is_visible_in_tree() if is_instance_valid(_reception) else false

	var blocked: bool = c_vis or m_vis or s_vis or r_vis
	_map_grid.process_mode = Node.PROCESS_MODE_DISABLED if blocked else Node.PROCESS_MODE_INHERIT


# ── Input Handling ────────────────────────────────────────────────────────────


# =============================================================================
func on_exit_pressed() -> void:
	if InputHandler.current_mode == InputHandler.InputMode.BUILD:
		close_build_menu()
		return
	if is_instance_valid(_sim_browser) and _sim_browser.visible:
		close_sim_browser()
		return
	if is_instance_valid(_standard_modal) and _standard_modal.visible:
		_standard_modal.close()
		return
	open_pause_menu()


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
		InputHandler.current_mode = InputHandler.InputMode.BUILD
		if is_instance_valid(_bottom_bar):
			_bottom_bar.update_build_menu_position()
			_bottom_bar.sync_button_state("build")
			_bottom_bar.get_node("BuildMenu").show()


# =============================================================================
func close_build_menu() -> void:
	if _build:
		_build.close_all()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL
	if is_instance_valid(_bottom_bar):
		_bottom_bar.sync_button_state("")
		_bottom_bar.get_node("BuildMenu").hide()


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
		Toast.show(GameState.T("toast.reception.no_rooms"))
		return

	# 2. ZEIT-CHECK: Es gibt Räume, aber hat die Rezeption schon auf?
	if TimeManager.get_hour() < 7 or TimeManager.get_hour() >= 22:
		Toast.show(GameState.T("toast.reception.too_early"))
		return

	# 3. VERFÜGBARKEITS-CHECK: Hat das Hotel ZIMMER FREI für NEUE Gäste?
	# Optional: Diesen Toast könntest du weglassen, wenn der Spieler die
	# Rezeption trotzdem öffnen darf, um z.B. nur Check-Outs zu bearbeiten.
	if not _guest_mgr.has_bookable_rooms() and _guest_mgr.get_checkout().size() == 0:
		Toast.show(GameState.T("toast.reception.no_rooms"))
		return

	# --- AB HIER: Alles gut, mach das Ding auf! ---
	cleanup_current_states()
	_reception = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentReception.tscn")
	if not is_instance_valid(_reception): return

	_reception.configure(_guest_mgr)
	_reception.refresh()
	_pause_time_for_ui()

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
func _on_schedule_event(event_id: String) -> void:
	match event_id:
		"reception_close":
			_lock_reception()
			_guest_mgr.clear_waiting_guests_with_penalty()
		"reception_open":
			_unlock_reception()


# =============================================================================
func _lock_reception() -> void:
	# 1. Button im HUD visuell sperren (Nutzt deine bestehende Funktion!)
	if is_instance_valid(_bottom_bar):
		_bottom_bar.set_reception_locked(true)
		_bottom_bar.reception.tooltip_text = GameState.T("hud.bottom.reception_closed_tt", "Geschlossen bis 07:00 Uhr")

	# 2. Hard-Lock: Wenn das Rezeptions-Modal gerade offen ist -> ZWANGSSCHLIESSEN!
	# Wir werfen den Spieler einfach aus dem Modal, als hätte er ESC gedrückt
	if is_instance_valid(_standard_modal) and _standard_modal.visible:
		# Nur schließen, wenn wir wirklich das Rezeptions-Fenster offen haben
		if is_instance_valid(_reception) and _reception.is_visible_in_tree():
			_standard_modal.close()
			Toast.show(GameState.T("toast.reception.force_close"))


# =============================================================================
func _unlock_reception() -> void:
	# 1. Button wieder freigeben
	if is_instance_valid(_bottom_bar):
		_bottom_bar.set_reception_locked(false)
		_bottom_bar.reception.tooltip_text = GameState.T("hud.bottom.reception_tt", "F3")


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
	_pause_time_for_ui()
	_standard_modal.modal_input_mode = InputHandler.InputMode.PAUSE
	var pause_content = _standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentPause.tscn")

	if pause_content:
		pause_content.sig_resume_requested.connect(func(): _standard_modal.close(); _resume_time_after_ui(); update_map_grid_mode())
		pause_content.sig_save_requested.connect(_on_pause_save)
		pause_content.sig_load_requested.connect(_on_pause_load)
		pause_content.sig_settings_requested.connect(func(): _came_from_pause = true; _open_settings())
		pause_content.sig_quit_requested.connect(_on_pause_quit)

	_standard_modal.open(GameState.T("modal.pause.title"))
	update_map_grid_mode()


# =============================================================================
func _on_pause_save() -> void:
	_standard_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSave.tscn")
	_standard_modal.set_title(GameState.T("modal.save.title"))
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
		GameState.T("ingame.quit.confirm"), GameState.T("ingame.quit.cancel")
	)


# =============================================================================
func _on_quit_confirmed() -> void:
	TimeManager.sig_save_requested.emit(TimeManager.get_game_time())
	var hotel_id: int = GameState.active_hotel_id
	if hotel_id >= 0:
		SaveManager.save_auto(hotel_id)
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


# =============================================================================
func _on_save_modal_loaded(hotel_id_loaded: int) -> void:
	GameState.active_hotel_id = hotel_id_loaded
	Toast.show_after_scene_change(GameState.T("toast.quickload.ok"))
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
		_resume_time_after_ui()
		InputHandler.current_mode = InputHandler.InputMode.NORMAL
		if is_instance_valid(_bottom_bar):
			_bottom_bar.sync_button_state("")
		update_map_grid_mode()


# ── Gäste ────────────────────────────────────────────────────────────────

# =============================================================================
func _sync_guest_ui() -> void:
	# 1. Das Top-HUD (über den GameState Briefkasten) updaten
	var waiting_count = _guest_mgr.get_waiting().size()
	var active_count = _guest_mgr.get_active().size()
	var checkout_count = _guest_mgr.get_checkout().size()

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
	# Später kommt hier ein Check rein, ob "hr_office" gebaut wurde.
	# Fürs Erste blocken wir hart ab:
	Toast.show("Personalverwaltung: Bald verfügbar! (Benötigt Personalbüro)")
	return


# ── Forschung / Tech-Tree (F6) ────────────────────────────────────────────────

# =============================================================================
func open_tech_tree() -> void:
	Toast.show("Forschung: Coming soon!")
	return


# ── Sim Browser (F7) ──────────────────────────────────────────────────────────

# =============================================================================
func open_sim_browser() -> void:
	Toast.show("Sim-Browser: Coming soon!")
	return


# =============================================================================
func close_sim_browser() -> void:
	return
