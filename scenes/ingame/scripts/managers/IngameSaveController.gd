extends Node
class_name IngameSaveController

var _hotel: Dictionary
var _guest_mgr: GuestManager

# =============================================================================
func setup(hotel: Dictionary, guest_mgr: GuestManager) -> void:
	_hotel = hotel
	_guest_mgr = guest_mgr

	_setup_autosave_timer()

	# Signale direkt abonnieren
	if not TimeManager.sig_save_requested.is_connected(save_progress):
		TimeManager.sig_save_requested.connect(save_progress)

	if not TimeManager.sig_day_ended.is_connected(_on_day_ended):
		TimeManager.sig_day_ended.connect(_on_day_ended)

	if not InputHandler.sig_hotkey_quicksave_requested.is_connected(quick_save):
		InputHandler.sig_hotkey_quicksave_requested.connect(quick_save)

	if not InputHandler.sig_hotkey_quickload_requested.is_connected(quick_load):
		InputHandler.sig_hotkey_quickload_requested.connect(quick_load)


# =============================================================================
func save_progress(game_time_min: int) -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return

	var save_data := {
		"day": _hotel.get("day", 1),
		"money": _hotel.get("money", 0),
		"xp": _hotel.get("xp", 0),
		"game_time": game_time_min,
		"guest_data": _guest_mgr.to_save_dict()
	}

	for key: String in _hotel:
		if key.begins_with("next_") and key.ends_with("_id"):
			save_data[key] = _hotel[key]

	SaveManager.update_hotel(hotel_id, save_data)


# =============================================================================
func _setup_autosave_timer() -> void:
	if not SettingsManager.autosave_enabled:
		return

	var autosave_timer := Timer.new()
	autosave_timer.wait_time = SettingsManager.autosave_interval_minutes * 60.0
	autosave_timer.one_shot  = false
	autosave_timer.timeout.connect(_on_timed_autosave)
	add_child(autosave_timer)
	autosave_timer.start()


# =============================================================================
func _on_timed_autosave() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return

	save_progress(TimeManager.get_game_time())
	SaveManager.save_auto(hotel_id)
	Toast.show(GameState.T("toast.system.autosave"))


# =============================================================================
func _on_day_ended(_new_day: int) -> void:
	# Wenn der Tag endet, machen wir automatisch einen Save
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id >= 0:
		SaveManager.save_auto(hotel_id)


# =============================================================================
func quick_save() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return

	save_progress(TimeManager.get_game_time())
	SaveManager.save_quick(hotel_id)
	Toast.show(GameState.T("toast.quicksave"))


# =============================================================================
func quick_load() -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return

	if SaveManager.load_quick(hotel_id):
		Toast.show_after_scene_change(GameState.T("toast.quickload.ok"))
		get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")
	else:
		Toast.show(GameState.T("toast.quickload.empty"))


# =============================================================================
# Nodes fangen Window-Close-Requests automatisch ab!
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if not _hotel.is_empty():
			save_progress(TimeManager.get_game_time())