extends Node
## Persistente Spieleinstellungen via ConfigFile (user://settings.cfg).

const SETTINGS_PATH := "user://settings.cfg"

# ── Gameplay ──────────────────────────────────────────────────────────────────
var autosave_enabled:          bool  = true
var autosave_interval_minutes: int   = 10    # Echtzeit-Minuten
var ff_speed:                  float = 10.0  # Schnellvorlauf-Faktor
var demolition_refund_rate:    float = 0.5   # Kapital-Rückgabe beim Abreißen (0.0–1.0)

# ── Audio ─────────────────────────────────────────────────────────────────────
var master_volume:     float = 1.0  # 0.0 – 1.0
var music_volume:      float = 0.2  # 0.0 – 1.0
var menu_music_volume: float = 0.2  # 0.0 – 1.0
var sound_volume:      float = 0.5  # 0.0 – 1.0

# ── Oberfläche ────────────────────────────────────────────────────────────────
var ui_scale:       float  = 1.0       # 0.75 / 1.0 / 1.25 / 1.5
var toast_position: String = "bottom"  # "top" / "middle" / "bottom"

# ── Session ───────────────────────────────────────────────────────────────────
var last_profile_id: int = -1   # Zuletzt gewählter Manager – für Auto-Restore

# ── Werte-Listen (für Slider-Positionen) ──────────────────────────────────────
const AUTOSAVE_INTERVALS: Array[int]   = [5, 10, 15, 30]
const FF_SPEEDS:           Array[float] = [5.0, 10.0, 20.0]
const UI_SCALES:           Array[float] = [0.75, 1.0, 1.25, 1.5]


func _ready() -> void:
	_load()
	_apply_audio()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", "autosave_enabled",          autosave_enabled)
	cfg.set_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	cfg.set_value("gameplay", "ff_speed",                  ff_speed)
	cfg.set_value("gameplay", "demolition_refund_rate",    demolition_refund_rate)
	cfg.set_value("audio",    "master_volume",             master_volume)
	cfg.set_value("audio",    "music_volume",              music_volume)
	cfg.set_value("audio",    "menu_music_volume",         menu_music_volume)
	cfg.set_value("audio",    "sound_volume",              sound_volume)
	cfg.set_value("ui",       "scale",          ui_scale)
	cfg.set_value("ui",       "toast_position", toast_position)
	cfg.set_value("session",  "last_profile_id",           last_profile_id)
	cfg.save(SETTINGS_PATH)
	_apply_audio()


## Lädt Einstellungen vom Disk neu und wendet sie an (z.B. nach Verwerfen).
func reload() -> void:
	_load()
	_apply_audio()


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	autosave_enabled          = cfg.get_value("gameplay", "autosave_enabled",          autosave_enabled)
	autosave_interval_minutes = cfg.get_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	ff_speed                  = cfg.get_value("gameplay", "ff_speed",                  ff_speed)
	demolition_refund_rate    = cfg.get_value("gameplay", "demolition_refund_rate",    demolition_refund_rate)
	master_volume             = cfg.get_value("audio",    "master_volume",             master_volume)
	music_volume              = cfg.get_value("audio",    "music_volume",              music_volume)
	menu_music_volume         = cfg.get_value("audio",    "menu_music_volume",         menu_music_volume)
	sound_volume              = cfg.get_value("audio",    "sound_volume",              sound_volume)
	ui_scale                  = cfg.get_value("ui",       "scale",          ui_scale)
	toast_position            = cfg.get_value("ui",       "toast_position", toast_position)
	last_profile_id           = cfg.get_value("session",  "last_profile_id",           last_profile_id)


func _apply_audio() -> void:
	_ensure_bus("Music")
	_ensure_bus("Menu Music")
	_ensure_bus("Sound")
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),      linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Menu Music"), linear_to_db(menu_music_volume))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound"),      linear_to_db(sound_volume))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")
