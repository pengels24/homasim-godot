extends Node2D

## ANG-148 – Ingame-Grundgerüst (Orchestrator)
## ANG-170 – God-File aufgeteilt: HUD → IngameHud, Uhr → IngameClock, Bau → IngameBuild

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var map_grid: Node2D = $MapGrid

@onready var hotel_name_lbl:      Label        = $HUD/TopBar/HBox/NameSection/Value
@onready var level_lbl:           Label        = $HUD/TopBar/HBox/LevelSection/Value
@onready var stat_day_val:        Label        = $HUD/TopBar/HBox/TimeSection/TagBox/Value
@onready var stat_money_val:      Label        = $HUD/TopBar/HBox/StatsSection/StatMoney/Value
@onready var stat_guests_wait:    Label        = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/WaitLbl
@onready var stat_guests_active:  Label        = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/ActiveLbl
@onready var stat_guests_out:     Label        = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/OutLbl
@onready var stat_ap_val:         Label        = $HUD/TopBar/HBox/StatsSection/StatAP/Value
@onready var stat_exp_bar:        ProgressBar  = $HUD/TopBar/HBox/StatsSection/StatEXP/Bar
@onready var stat_exp_lbl:        Label        = $HUD/TopBar/HBox/StatsSection/StatEXP/ValueLbl
@onready var stat_ruf_root:       Control      = $HUD/TopBar/HBox/StatsSection/StatRUF/RufBarRoot
@onready var stat_ruf_lbl:        Label        = $HUD/TopBar/HBox/StatsSection/StatRUF/RufValueLbl
@onready var stat_fp_val:         Label        = $HUD/TopBar/HBox/StatsSection/StatFP/Value
@onready var time_lbl:            Label        = $HUD/TopBar/HBox/TimeSection/TimeLbl
@onready var btn_pause:           Button       = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPause
@onready var btn_play:            Button       = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPlay
@onready var btn_ff:              Button       = $HUD/TopBar/HBox/TimeSection/GameControls/BtnFF
@onready var bottom_anchor:       Control      = $HUD/BottomBarAnchor
@onready var context_bar:         HBoxContainer = $HUD/ContextBar

# ── Subsysteme ────────────────────────────────────────────────────────────────
var _hud:            IngameHud
var _clock:          IngameClock
var _build:          IngameBuild
var _autosave_timer: Timer
var _settings_modal: SettingsModal

const SETTINGS_SCENE := preload("res://scenes/shared/SettingsModal.tscn")
const CONFIRM_SCENE  := preload("res://scenes/shared/ConfirmModal.tscn")

var _hotel:        Dictionary = {}
var _quit_confirm: ConfirmModal = null


func _ready() -> void:
	_hotel = _load_hotel()
	var api_name: String = GameState.selected_hotel.get("name", "")
	if api_name != "":
		_hotel["name"] = api_name
	_start_map()
	_setup_subsystems()


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
	var hud_canvas := $HUD as CanvasLayer

	_hud = IngameHud.new()
	add_child(_hud)
	_hud.configure(_hotel, {
		"hotel_name_lbl":     hotel_name_lbl,
		"level_lbl":          level_lbl,
		"stat_day_val":       stat_day_val,
		"stat_money_val":     stat_money_val,
		"stat_guests_wait":   stat_guests_wait,
		"stat_guests_active": stat_guests_active,
		"stat_guests_out":    stat_guests_out,
		"stat_ap_val":        stat_ap_val,
		"stat_exp_bar":       stat_exp_bar,
		"stat_exp_lbl":       stat_exp_lbl,
		"stat_ruf_root":      stat_ruf_root,
		"stat_ruf_lbl":       stat_ruf_lbl,
		"stat_fp_val":        stat_fp_val,
		"bottom_anchor":      bottom_anchor,
		"context_bar":        context_bar,
	}, hud_canvas)

	_clock = IngameClock.new()
	add_child(_clock)
	_clock.configure(_hotel, time_lbl, btn_pause, btn_play, btn_ff)

	_build = IngameBuild.new()
	add_child(_build)
	_build.configure(_hotel, map_grid, _hud, hud_canvas)

	_hud.bottom_button_pressed.connect(_build.on_button_pressed)
	_hud.view_reset_requested.connect(map_grid.reset_view)
	map_grid.view_saved_changed.connect(_hud.set_mode_btn_saved)
	_clock.day_ended.connect(_on_day_ended)
	_clock.save_requested.connect(_save_progress)
	_setup_autosave_timer()


# ── Signal-Handler ────────────────────────────────────────────────────────────

func _on_day_ended(new_day: int) -> void:
	_hud.update_day(new_day)
	SaveManager.save_auto(_hotel.get("id", -1))


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if is_instance_valid(_settings_modal) and _settings_modal.visible:
				return
			if ke.keycode == KEY_S and ke.alt_pressed:
				_open_settings()
			else:
				_handle_hotkey(ke.keycode)


func _handle_hotkey(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE: _on_exit_pressed()
		KEY_F2:     _hud.trigger_button(0)
		KEY_F3:     _hud.trigger_button(1)
		KEY_F4:     _hud.trigger_button(2)
		KEY_F5:     _quick_save()
		KEY_F6:     _hud.trigger_button(4)
		KEY_F7:     _hud.trigger_button(5)
		KEY_F9:     _quick_load()


func _on_exit_pressed() -> void:
	if _build.close_all():
		return
	if not is_instance_valid(_quit_confirm):
		_quit_confirm = CONFIRM_SCENE.instantiate() as ConfirmModal
		$HUD.add_child(_quit_confirm)
		_quit_confirm.confirmed.connect(_on_quit_confirmed)
	_quit_confirm.ask(
		GameState.T("ingame.quit.title"),
		GameState.T("ingame.quit.message"),
		GameState.T("ingame.quit.confirm"),
		GameState.T("ingame.quit.cancel"),
	)


func _on_quit_confirmed() -> void:
	_save_progress(_clock.get_game_time())
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


# ── Persistenz ────────────────────────────────────────────────────────────────

func _save_progress(game_time_min: int) -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	SaveManager.update_hotel(hotel_id, {
		"day":       _hotel.get("day", 1),
		"money":     _hotel.get("money", 0),
		"game_time": game_time_min,
	})


func _open_settings() -> void:
	if not is_instance_valid(_settings_modal):
		_settings_modal = SETTINGS_SCENE.instantiate() as SettingsModal
		$HUD.add_child(_settings_modal)
		_settings_modal.closed.connect(_on_settings_closed)
	map_grid.process_mode = Node.PROCESS_MODE_DISABLED
	_settings_modal.open()


func _on_settings_closed() -> void:
	map_grid.process_mode = Node.PROCESS_MODE_INHERIT


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


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		if is_instance_valid(_clock):
			_save_progress(_clock.get_game_time())
