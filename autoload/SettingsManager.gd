extends Node
## Persistente Spieleinstellungen via ConfigFile (user://settings.cfg).

signal sig_tech_info_toggled(is_visible: bool)

signal sig_hud_side_changed

@warning_ignore("unused_signal")
signal sig_language_changed(locale: String)

signal sig_ff_speed_changed(new_speed: float)

const SETTINGS_PATH := "user://settings.cfg"

# ── Gameplay ──────────────────────────────────────────────────────────────────
var autosave_enabled: bool  = true
var autosave_interval_minutes: int   = 10    # Echtzeit-Minuten
var ff_speed: float = 10.0  # Schnellvorlauf-Faktor
var demolition_refund_rate: float = 0.5   # Kapital-Rückgabe beim Abreißen (0.0–1.0)
var scroll_zoom_sensitivity: float = 1.0  # Mausrad-Zoom Empfindlichkeit

# ── Audio ─────────────────────────────────────────────────────────────────────
var master_volume: float = 1.0  # 0.0 – 1.0
var music_volume: float = 0.2  # 0.0 – 1.0
var menu_music_volume: float = 0.2  # 0.0 – 1.0
var sound_volume: float = 0.5  # 0.0 – 1.0

# ── Oberfläche ────────────────────────────────────────────────────────────────
var ui_scale: float  = 1.0       # 0.75 / 1.0 / 1.25 / 1.5
var toast_position: String = "bottom"  # "top" / "middle" / "bottom"
var hud_side: String = "center"    # "left" / "center" / "right"
var show_tech_info: bool = false   # Ingame Performance Overlay
var tutorial_tips: bool = true     # Tutorial-Tipps im Spiel anzeigen
var language: String = "de"        # "de" / "en" (erweiterbar)
var dont_show_disclaimer: bool = false
var window_mode: String = "fullscreen"  # "fullscreen" / "borderless"

# ── Session ───────────────────────────────────────────────────────────────────
var last_profile_id: int = -1   # Zuletzt gewählter Manager – für Auto-Restore

# ── Tastaturbelegung ──────────────────────────────────────────────────────────
var custom_keybindings: Dictionary = {} # Speichert [primary_keycode, alt_keycode] pro Action

func set_tech_info(visible: bool) -> void:
	if show_tech_info != visible:
		show_tech_info = visible
		save()
		sig_tech_info_toggled.emit(show_tech_info)

var keybindings_config: Dictionary = {}
const KEYBINDINGS_CONFIG_PATH := "res://config/keybindings.json"

# ── Werte-Listen (für Slider-Positionen) ──────────────────────────────────────
const AUTOSAVE_INTERVALS: Array[int]   = [5, 10, 15, 30]
var autosave_intervals_labels: Array[String]:
	get:
		return [GameState.T("settings.gameplay.autosave_interval.off"), GameState.T("settings.gameplay.autosave_interval.on", 5), GameState.T("settings.gameplay.autosave_interval.on", 10), GameState.T("settings.gameplay.autosave_interval.on", 15), GameState.T("settings.gameplay.autosave_interval.on", 30)]

const FF_SPEEDS: Array[float] = [5.0, 10.0, 20.0, 30.0, 50.0]
const FF_SPEEDS_LABELS: Array[String] = ["x5", "x10", "x20", "x30", "x50"]

const UI_SCALES: Array[float] = [0.8, 0.9, 1.0, 1.1, 1.2, 1.3]
const UI_SCALES_LABELS: Array[String] = ["80 %", "90 %", "100 %", "110 %", "120 %", "130 %"]

const UI_TOAST_POS: Array[String] =	["top", "middle", "bottom"]
var ui_toast_pos_labels: Array[String]:
	get:
		return [GameState.T("settings.ui.toast.top"), GameState.T("settings.ui.toast.middle"), GameState.T("settings.ui.toast.bottom")]

const UI_HUDBOTTOM_POS: Array[String] = ["left", "center", "right"]
var ui_hudbottom_pos_labels: Array[String]:
	get:
		return [GameState.T("settings.ui.hud_side.left"), GameState.T("settings.ui.hud_side.center"), GameState.T("settings.ui.hud_side.right")]

const LANGUAGES: Array[String] = ["de", "en"]
const LANGUAGES_LABELS: Array[String] = ["Deutsch", "English"]


# ── Monitor-Auswahl ───────────────────────────────────────────────────────────
var preferred_screen: int = 0  # Index des gewünschten Monitors (0 = primär)

# =============================================================================
func _ready() -> void:
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_keybindings_config()
	_load()
	_apply_audio()
	_apply_keybindings()
	call_deferred("_apply_startup_scale")
	# Fenster-Einstellungen erst im nächsten Frame anwenden – Godot muss
	# die eigene Initialisierung (project.godot-Mode) erst abschliessen.
	call_deferred("_apply_startup_window")


# =============================================================================
func _apply_startup_scale() -> void:
	get_tree().root.content_scale_factor = ui_scale


# =============================================================================
## Wird deferred aufgerufen – nach Godots eigener Fenster-Initialisierung.
## Zwei Frames warten damit Windows/Godot die Initialisierung vollständig abschliesst.
func _apply_startup_window() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	# Rahmenlos: apply_window_mode() positioniert bereits über preferred_screen.
	# apply_screen() wäre hier kontraproduktiv (geht durch Fullscreen → Windows
	# verschiebt das Fenster beim Verlassen von Fullscreen zurück auf Monitor 1).
	if window_mode == "fullscreen":
		apply_screen()
		await get_tree().process_frame
	apply_window_mode()


# =============================================================================
## Bewegt das Fenster auf den gewählten Monitor.
## Bei Fullscreen: kurz in Windowed, verschieben, zurück in Fullscreen.
## Das kurze Flackern ist unter Windows unvermeidbar bei Monitor-Wechsel im Fullscreen.
func apply_screen() -> void:
	var count := DisplayServer.get_screen_count()
	var screen := clampi(preferred_screen, 0, count - 1)

	var current_mode := DisplayServer.window_get_mode()
	var in_fullscreen := current_mode in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	]

	if in_fullscreen:
		# Fullscreen kann nicht direkt verschoben werden – kurz Windowed schalten
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_current_screen(screen)
		# Position muss gesetzt werden damit das Fenster wirklich auf dem neuen Monitor ist
		var screen_pos := DisplayServer.screen_get_position(screen)
		DisplayServer.window_set_position(screen_pos + Vector2i(100, 100))
		# Dann wieder Fullscreen auf dem neuen Monitor
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_current_screen(screen)
		if window_mode == "borderless":
			# Rahmenlos: Fenster muss auf dem neuen Monitor auch die richtige Größe/Position haben
			var screen_size := DisplayServer.screen_get_size(screen)
			var screen_pos  := DisplayServer.screen_get_position(screen)
			DisplayServer.window_set_size(screen_size)
			DisplayServer.window_set_position(screen_pos)



# =============================================================================
## Setzt den Fenstermodus. Bei "borderless" wird die Monitorauflösung geprüft –
## ist sie kleiner als 1920×1080, bleibt Fullscreen und ein Toast wird angezeigt.
func apply_window_mode(show_toast_on_fail: bool = false) -> void:
	if window_mode == "borderless":
		var screen := clampi(preferred_screen, 0, DisplayServer.get_screen_count() - 1)
		var screen_size := DisplayServer.screen_get_size(screen)
		var screen_pos  := DisplayServer.screen_get_position(screen)
		if screen_size.x < 1920 or screen_size.y < 1080:
			# Sicherheits-Fallback: Monitor zu klein → zurück auf Fullscreen
			window_mode = "fullscreen"
			if show_toast_on_fail:
				call_deferred("_toast_resolution_warning")
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			return
		# Schritt 1: sofort in Windowed wechseln (Windows snappt das Fenster auf Mon. 1)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Schritt 2: Position, Größe, Borderless-Flag DEFERRED setzen –
		# window_set_position im selben Frame wie window_set_mode wird von Windows ignoriert.
		_bl_screen      = screen
		_bl_screen_size = screen_size
		_bl_screen_pos  = screen_pos
		call_deferred("_apply_borderless_deferred")
	else:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

# ── Borderless deferred helper ────────────────────────────────────────────────
var _bl_screen: int = 0
var _bl_screen_size: Vector2i = Vector2i(1920, 1080)
var _bl_screen_pos:  Vector2i = Vector2i.ZERO

func _apply_borderless_deferred() -> void:
	DisplayServer.window_set_current_screen(_bl_screen)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(_bl_screen_size)
	DisplayServer.window_set_position(_bl_screen_pos)


func _toast_resolution_warning() -> void:
	var toast := get_node_or_null("/root/ToastManager")
	if toast:
		toast.warning(GameState.T("settings.ui.window_mode.too_small"))


# =============================================================================
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", "autosave_enabled", autosave_enabled)
	cfg.set_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	cfg.set_value("gameplay", "ff_speed", ff_speed)
	cfg.set_value("gameplay", "demolition_refund_rate", demolition_refund_rate)
	cfg.set_value("gameplay", "scroll_zoom_sensitivity", scroll_zoom_sensitivity)
	
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("audio", "music_volume", music_volume)
	cfg.set_value("audio", "menu_music_volume", menu_music_volume)
	cfg.set_value("audio", "sound_volume", sound_volume)
	cfg.set_value("ui", "scale", ui_scale)
	cfg.set_value("ui", "toast_position", toast_position)
	cfg.set_value("ui", "hud_side", hud_side)
	cfg.set_value("ui", "show_tech_info", show_tech_info)
	cfg.set_value("ui", "tutorial_tips", tutorial_tips)
	cfg.set_value("ui", "language", language)
	cfg.set_value("ui", "dont_show_disclaimer", dont_show_disclaimer)
	cfg.set_value("ui", "window_mode", window_mode)
	cfg.set_value("session", "last_profile_id", last_profile_id)
	cfg.set_value("ui", "preferred_screen", preferred_screen)
	
	for action in custom_keybindings:
		cfg.set_value("input", action, custom_keybindings[action])
		
	cfg.save(SETTINGS_PATH)
	_apply_audio()
	sig_hud_side_changed.emit()


# =============================================================================
## Lädt Einstellungen vom Disk neu und wendet sie an (z.B. nach Verwerfen).
func reload() -> void:
	_load()
	_apply_audio()


# =============================================================================
func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	autosave_enabled = cfg.get_value("gameplay", "autosave_enabled",          autosave_enabled)
	autosave_interval_minutes = cfg.get_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	ff_speed = cfg.get_value("gameplay", "ff_speed",                  ff_speed)
	demolition_refund_rate = cfg.get_value("gameplay", "demolition_refund_rate",    demolition_refund_rate)
	scroll_zoom_sensitivity = cfg.get_value("gameplay", "scroll_zoom_sensitivity", scroll_zoom_sensitivity)
	master_volume = cfg.get_value("audio",    "master_volume",             master_volume)
	music_volume = cfg.get_value("audio",    "music_volume",              music_volume)
	menu_music_volume = cfg.get_value("audio",    "menu_music_volume",         menu_music_volume)
	sound_volume = cfg.get_value("audio",    "sound_volume",              sound_volume)
	ui_scale = cfg.get_value("ui",       "scale",          ui_scale)
	toast_position = cfg.get_value("ui", "toast_position", "bottom")
	hud_side = cfg.get_value("ui", "hud_side", "center")
	show_tech_info = cfg.get_value("ui", "show_tech_info", false)
	tutorial_tips = cfg.get_value("ui", "tutorial_tips", true)
	language = cfg.get_value("ui", "language", "de")
	TranslationServer.set_locale(language)
	dont_show_disclaimer = cfg.get_value("ui", "dont_show_disclaimer", false)
	window_mode = cfg.get_value("ui", "window_mode", "fullscreen")
	preferred_screen = cfg.get_value("ui", "preferred_screen", 0)
	# Nicht sofort apply_screen/apply_window_mode aufrufen –
	# das passiert deferred in _apply_startup_window() nach der Godot-Initialisierung.
	last_profile_id = cfg.get_value("session",  "last_profile_id",           last_profile_id)
	
	custom_keybindings.clear()
	if cfg.has_section("input"):
		for action in cfg.get_section_keys("input"):
			custom_keybindings[action] = cfg.get_value("input", action)


# =============================================================================
func _apply_audio() -> void:
	_ensure_bus("Music")
	_ensure_bus("Menu Music")
	_ensure_bus("Sound")
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),      linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Menu Music"), linear_to_db(menu_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"),      linear_to_db(sound_volume))


# =============================================================================
func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")

# =============================================================================
func _load_keybindings_config() -> void:
	if FileAccess.file_exists(KEYBINDINGS_CONFIG_PATH):
		var text := FileAccess.get_file_as_string(KEYBINDINGS_CONFIG_PATH)
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			keybindings_config = parsed

# =============================================================================
func _apply_keybindings() -> void:
	for group_key in keybindings_config:
		var group: Dictionary = keybindings_config[group_key]
		var actions: Dictionary = group.get("actions", {})
		for action in actions:
			var default_primary_str: String = actions[action].get("default", "")
			var default_alt_str: String = actions[action].get("default_alt", "")
			var default_primary: Key = OS.find_keycode_from_string(default_primary_str) if default_primary_str != "" else KEY_NONE
			var default_alt: Key = OS.find_keycode_from_string(default_alt_str) if default_alt_str != "" else KEY_NONE
			
			var current_primary: Key = default_primary
			var current_alt: Key = default_alt
			
			if custom_keybindings.has(action):
				var custom_arr = custom_keybindings[action]
				if custom_arr is Array and custom_arr.size() >= 2:
					current_primary = int(custom_arr[0]) as Key
					current_alt = int(custom_arr[1]) as Key
			
			if not InputMap.has_action(action):
				InputMap.add_action(action)
			
			InputMap.action_erase_events(action)
			
			if current_primary != KEY_NONE:
				var ev_pri := InputEventKey.new()
				ev_pri.physical_keycode = current_primary as Key
				InputMap.action_add_event(action, ev_pri)
			
			if current_alt != KEY_NONE:
				var ev_alt := InputEventKey.new()
				ev_alt.physical_keycode = current_alt as Key
				InputMap.action_add_event(action, ev_alt)

# =============================================================================
func update_keybinding(action: String, primary: Key, alt: Key) -> void:
	custom_keybindings[action] = [primary, alt]
	save()
	_apply_keybindings()

func reset_keybinding(action: String) -> void:
	if custom_keybindings.has(action):
		custom_keybindings.erase(action)
		save()
		_apply_keybindings()

func reset_all_keybindings() -> void:
	custom_keybindings.clear()
	save()
	_apply_keybindings()
