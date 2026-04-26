extends Node
## Persistente Spieleinstellungen via ConfigFile (user://settings.cfg).

const SETTINGS_PATH := "user://settings.cfg"

# ── Gameplay ──────────────────────────────────────────────────────────────────
var autosave_enabled:          bool  = true
var autosave_interval_minutes: int   = 10    # Echtzeit-Minuten
var ff_speed:                  float = 10.0  # Schnellvorlauf-Faktor

# ── Audio ─────────────────────────────────────────────────────────────────────
var music_volume: float = 0.5   # 0.0 – 1.0
var sound_volume: float = 0.5   # 0.0 – 1.0

# ── Oberfläche ────────────────────────────────────────────────────────────────
var ui_scale: float = 1.0       # 0.75 / 1.0 / 1.25 / 1.5

# ── Werte-Listen (für Slider-Positionen) ──────────────────────────────────────
const AUTOSAVE_INTERVALS: Array[int]   = [5, 10, 15, 30]
const FF_SPEEDS:           Array[float] = [5.0, 10.0, 20.0]
const UI_SCALES:           Array[float] = [0.75, 1.0, 1.25, 1.5]


func _ready() -> void:
	_load()


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("gameplay", "autosave_enabled",          autosave_enabled)
	cfg.set_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	cfg.set_value("gameplay", "ff_speed",                  ff_speed)
	cfg.set_value("audio",    "music_volume",              music_volume)
	cfg.set_value("audio",    "sound_volume",              sound_volume)
	cfg.set_value("ui",       "scale",                     ui_scale)
	cfg.save(SETTINGS_PATH)


func _load() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	autosave_enabled          = cfg.get_value("gameplay", "autosave_enabled",          autosave_enabled)
	autosave_interval_minutes = cfg.get_value("gameplay", "autosave_interval_minutes", autosave_interval_minutes)
	ff_speed                  = cfg.get_value("gameplay", "ff_speed",                  ff_speed)
	music_volume              = cfg.get_value("audio",    "music_volume",              music_volume)
	sound_volume              = cfg.get_value("audio",    "sound_volume",              sound_volume)
	ui_scale                  = cfg.get_value("ui",       "scale",                     ui_scale)
