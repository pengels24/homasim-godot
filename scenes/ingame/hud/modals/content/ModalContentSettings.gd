extends TabContainer

# =============================================================================
# ── ONREADY UI-ELEMENTE ──────────────────────────────────────────────────────
# =============================================================================

# -- GAMEPLAY --
@onready var btn_autosave_left: Button  = %ButtonAutosaveLeft
@onready var btn_autosave_right: Button = %ButtonAutosaveRight
@onready var lbl_autosave: Label        = %ButtonAutosave # In deiner Szene ein Label

@onready var btn_ff_left: Button  = %ButtonFastForwardLeft
@onready var btn_ff_right: Button = %ButtonFastForwardRight
@onready var lbl_ff: Label        = %LabelFastForwardValue

# -- AUDIO --
@onready var slider_master: HSlider = %HSliderVolMaster
@onready var lbl_master: Label      = %LabelVolMasterValue
@onready var slider_bg: HSlider     = %HSliderVolBG
@onready var lbl_bg: Label          = %LabelVolBGValue
@onready var slider_menu: HSlider   = %HSliderVolMenu
@onready var lbl_menu: Label        = %LabelVolMenuValue
@onready var slider_sounds: HSlider = %HSliderVolSounds
@onready var lbl_sounds: Label      = %LabelVolSoundsValue

# -- OBERFLÄCHE --
@onready var btn_scale_left: Button  = %ButtonUIScaleLeft
@onready var btn_scale_right: Button = %ButtonUIScaleRight
@onready var lbl_scale: Label        = %LabelUIScaleValue

@onready var btn_toast_left: Button  = %ButtonToastPosLeft
@onready var btn_toast_right: Button = %ButtonToastPosRight
@onready var lbl_toast: Label        = %LabelToastPosValue

@onready var btn_hud_left: Button  = %ButtonPosHUDBottomLeft
@onready var btn_hud_right: Button = %ButtonPosHUDBottomRight
@onready var lbl_hud: Label        = %LabelPosHUDBottomValue

# Interne Speicherstruktur für die Left/Right-Logik
var _sel_data: Dictionary = {}

# =============================================================================
func _ready() -> void:
	_init_gameplay_tab()
	_init_audio_tab()
	_init_ui_tab()

	get_tree().root.content_scale_factor = SettingsManager.ui_scale


# =============================================================================
# ── INITIALISIERUNG DER TABS ─────────────────────────────────────────────────
# =============================================================================


# =============================================================================
func _init_gameplay_tab() -> void:
	var auto_val: int = SettingsManager.autosave_interval_minutes if SettingsManager.autosave_enabled else 0

	_setup_selector("autosave", btn_autosave_left, btn_autosave_right, lbl_autosave,
		SettingsManager.autosave_intervals_labels,
		SettingsManager.AUTOSAVE_INTERVALS,
		auto_val, _on_autosave_changed)

	_setup_selector("ff", btn_ff_left, btn_ff_right, lbl_ff,
		SettingsManager.FF_SPEEDS_LABELS,
		SettingsManager.FF_SPEEDS,
		SettingsManager.ff_speed, _on_ff_changed)


# =============================================================================
func _init_audio_tab() -> void:
	_setup_slider(slider_master, lbl_master, SettingsManager.master_volume, _on_master_vol_changed)
	_setup_slider(slider_bg,     lbl_bg,     SettingsManager.music_volume,  _on_bg_vol_changed)
	_setup_slider(slider_menu,   lbl_menu,   SettingsManager.menu_music_volume, _on_menu_vol_changed)
	_setup_slider(slider_sounds, lbl_sounds, SettingsManager.sound_volume,  _on_sounds_vol_changed)


# =============================================================================
func _init_ui_tab() -> void:
	_setup_selector("scale", btn_scale_left, btn_scale_right, lbl_scale,
		SettingsManager.UI_SCALES_LABELS,
		SettingsManager.UI_SCALES,
		SettingsManager.ui_scale, _on_scale_changed)

	_setup_selector("toast", btn_toast_left, btn_toast_right, lbl_toast,
		SettingsManager.ui_toast_pos_labels,
	SettingsManager.UI_TOAST_POS,
		SettingsManager.toast_position, _on_toast_changed)

	_setup_selector("hud", btn_hud_left, btn_hud_right, lbl_hud,
		SettingsManager.ui_hudbottom_pos_labels,
		SettingsManager.UI_HUDBOTTOM_POS,
		SettingsManager.hud_side, _on_hud_changed)


# =============================================================================
# ── HELPER-FUNKTIONEN (Magie unter der Haube) ────────────────────────────────
# =============================================================================


# =============================================================================
## Erstellt automatisch einen funktionierenden Left/Right-Selektor
func _setup_selector(id: String, btn_left: Button, btn_right: Button, label: Label, texts: Array, vals: Array, current_val: Variant, callback: Callable) -> void:
	# Index des aktuellen Werts finden
	var idx: int = vals.find(current_val)
	if idx == -1: idx = 0

	# Datenstrukturen für diesen Selektor speichern
	_sel_data[id] = {
		"texts": texts,
		"vals": vals,
		"idx": idx,
		"label": label,
		"callback": callback
	}

	# Initialen Text ins Label schreiben
	label.text = texts[idx]

	# Button-Klicks verdrahten
	btn_left.pressed.connect(func(): _shift_selector(id, -1))
	btn_right.pressed.connect(func(): _shift_selector(id, 1))


# =============================================================================
func _shift_selector(id: String, direction: int) -> void:
	var data: Dictionary = _sel_data[id]
	data.idx += direction

	# Zyklisches Durchschalten (Loop)
	if data.idx < 0:
		data.idx = data.vals.size() - 1
	elif data.idx >= data.vals.size():
		data.idx = 0

	# UI und Logik updaten
	data.label.text = data.texts[data.idx]
	data.callback.call(data.vals[data.idx])


# =============================================================================
## Erstellt automatisch einen funktionierenden Audio-Slider (0-100% UI, 0.0-1.0 Backend)
func _setup_slider(slider: HSlider, label: Label, current_val: float, callback: Callable) -> void:
	slider.value = current_val * 100.0
	label.text = str(int(slider.value)) + " %"

	slider.value_changed.connect(func(val: float):
		label.text = str(int(val)) + " %"
		callback.call(val / 100.0)
	)

# =============================================================================
# ── CALLBACKS (Werte an SettingsManager senden) ──────────────────────────────
# =============================================================================


# =============================================================================
func _on_autosave_changed(val: int) -> void:
	SettingsManager.autosave_enabled = (val > 0)
	if val > 0:
		SettingsManager.autosave_interval_minutes = val
	SettingsManager.save()


# =============================================================================
func _on_ff_changed(val: float) -> void:
	SettingsManager.ff_speed = val
	SettingsManager.save()


# =============================================================================
func _on_master_vol_changed(val: float) -> void:
	SettingsManager.master_volume = val
	SettingsManager.save()


# =============================================================================
func _on_bg_vol_changed(val: float) -> void:
	SettingsManager.music_volume = val
	SettingsManager.save()


# =============================================================================
func _on_menu_vol_changed(val: float) -> void:
	SettingsManager.menu_music_volume = val
	SettingsManager.save()


# =============================================================================
func _on_sounds_vol_changed(val: float) -> void:
	SettingsManager.sound_volume = val
	SettingsManager.save()


# =============================================================================
func _on_toast_changed(val: String) -> void:
	SettingsManager.toast_position = val
	SettingsManager.save()


# =============================================================================
func _on_hud_changed(val: String) -> void:
	SettingsManager.hud_side = val
	SettingsManager.save()


# =============================================================================
func _on_scale_changed(val: float) -> void:
	SettingsManager.ui_scale = val
	SettingsManager.save()
	get_tree().root.content_scale_factor = val
