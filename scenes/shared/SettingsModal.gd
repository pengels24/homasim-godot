extends Control
class_name SettingsModal
## ANG-152 – Einstellungs-Modal mit 4 Tabs (Gameplay / Audio / Oberfläche / Steuerung).
## Aufruf: settings_modal.open()  |  Alt+S in Ingame und MainMenu

signal closed

@onready var _title_lbl:     Label         = $Overlay/Center/Card/VBox/Header/TitleLbl
@onready var _btn_close:     Button        = $Overlay/Center/Card/VBox/Header/BtnClose
var _tab_buttons: Array[Button] = []
@onready var _tab_gameplay:  VBoxContainer = $Overlay/Center/Card/VBox/ContentArea/GameplayPanel
@onready var _tab_audio:     VBoxContainer = $Overlay/Center/Card/VBox/ContentArea/AudioPanel
@onready var _tab_oberflaeche: VBoxContainer = $Overlay/Center/Card/VBox/ContentArea/OberflaeechePanel
@onready var _tab_steuerung: VBoxContainer = $Overlay/Center/Card/VBox/ContentArea/SteuerungPanel
@onready var _btn_save:      Button        = $Overlay/Center/Card/VBox/SaveRow/BtnSave
@onready var _tab_bar:       HBoxContainer = $Overlay/Center/Card/VBox/TabBar

var _active_tab: int = 0


func open() -> void:
	visible = true
	_switch_tab(0)


# ── Lifecycle ─────────────────────────────────────────────────────────────────

func _ready() -> void:
	_title_lbl.text = GameState.T("settings.title")
	_btn_save.text  = GameState.T("settings.btn.save")
	_btn_close.pressed.connect(_on_close)
	_btn_save.pressed.connect(_on_save)
	_setup_tab_buttons()
	_build_gameplay_tab()
	_build_audio_tab()
	_build_oberflaeche_tab()
	_build_steuerung_tab()


# ── Tabs ──────────────────────────────────────────────────────────────────────

func _setup_tab_buttons() -> void:
	var labels := [
		GameState.T("settings.tab.gameplay"),
		GameState.T("settings.tab.audio"),
		GameState.T("settings.tab.ui"),
		GameState.T("settings.tab.controls"),
	]
	for i in labels.size():
		var btn := _tab_bar.get_child(i) as Button
		btn.text = labels[i]
		btn.pressed.connect(_switch_tab.bind(i))
		_tab_buttons.append(btn)


func _switch_tab(idx: int) -> void:
	_active_tab = idx
	var panels := [_tab_gameplay, _tab_audio, _tab_oberflaeche, _tab_steuerung]
	for i in panels.size():
		panels[i].visible = (i == idx)
	_update_tab_styles()


func _update_tab_styles() -> void:
	for i in _tab_buttons.size():
		var btn := _tab_buttons[i]
		if i == _active_tab:
			btn.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031))
			btn.add_theme_stylebox_override("normal", _tab_active_style())
			btn.add_theme_stylebox_override("hover",  _tab_active_style())
		else:
			btn.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
			btn.add_theme_stylebox_override("normal", _tab_inactive_style())
			btn.add_theme_stylebox_override("hover",  _tab_hover_style())


func _tab_active_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color           = Color(0, 0, 0, 0)
	s.border_width_bottom = 2
	s.border_color        = Color(0.918, 0.702, 0.031)
	s.content_margin_left = 0; s.content_margin_right = 0
	s.content_margin_top  = 8; s.content_margin_bottom = 10
	return s


func _tab_inactive_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color            = Color(0, 0, 0, 0)
	s.content_margin_left = 0; s.content_margin_right = 0
	s.content_margin_top  = 8; s.content_margin_bottom = 10
	return s


func _tab_hover_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color            = Color(1, 1, 1, 0.05)
	s.content_margin_left = 0; s.content_margin_right = 0
	s.content_margin_top  = 8; s.content_margin_bottom = 10
	return s


# ── Gameplay-Tab ──────────────────────────────────────────────────────────────

func _build_gameplay_tab() -> void:
	var panel := _tab_gameplay

	# Autosave an/aus
	var autosave_row := _make_toggle_row(
		GameState.T("settings.gameplay.autosave"),
		SettingsManager.autosave_enabled,
	)
	var autosave_toggle := autosave_row.get_node("Toggle") as CheckButton
	panel.add_child(autosave_row)

	# Autosave-Intervall (nur sichtbar wenn autosave aktiv)
	var interval_labels := PackedStringArray()
	for m in SettingsManager.AUTOSAVE_INTERVALS:
		interval_labels.append("%d %s" % [m, GameState.T("settings.unit.min")])
	var interval_idx: int = SettingsManager.AUTOSAVE_INTERVALS.find(SettingsManager.autosave_interval_minutes)
	var interval_row := _make_slider_row(
		GameState.T("settings.gameplay.autosave_interval"),
		interval_labels,
		maxi(0, interval_idx),
	)
	interval_row.visible = SettingsManager.autosave_enabled
	panel.add_child(interval_row)

	autosave_toggle.toggled.connect(func(on: bool) -> void:
		SettingsManager.autosave_enabled = on
		interval_row.visible = on
	)
	(interval_row.find_child("Slider", true, false) as HSlider).value_changed.connect(func(v: float) -> void:
		SettingsManager.autosave_interval_minutes = SettingsManager.AUTOSAVE_INTERVALS[int(v)]
	)

	panel.add_child(_make_separator())

	# Schnellvorlauf
	var ff_labels  := PackedStringArray(["x5", "x10", "x20"])
	var ff_idx: int = SettingsManager.FF_SPEEDS.find(SettingsManager.ff_speed)
	var ff_row := _make_slider_row(
		GameState.T("settings.gameplay.ff_speed"),
		ff_labels,
		maxi(0, ff_idx),
	)
	panel.add_child(ff_row)
	(ff_row.find_child("Slider", true, false) as HSlider).value_changed.connect(func(v: float) -> void:
		SettingsManager.ff_speed = SettingsManager.FF_SPEEDS[int(v)]
	)


# ── Audio-Tab ─────────────────────────────────────────────────────────────────

func _build_audio_tab() -> void:
	var panel := _tab_audio

	var music_row := _make_volume_row(
		GameState.T("settings.audio.music"),
		SettingsManager.music_volume,
	)
	panel.add_child(music_row)
	(music_row.get_node("Slider") as HSlider).value_changed.connect(func(v: float) -> void:
		SettingsManager.music_volume = v / 100.0
		(music_row.get_node("ValueLbl") as Label).text = "%d%%" % int(v)
	)

	var sound_row := _make_volume_row(
		GameState.T("settings.audio.sound"),
		SettingsManager.sound_volume,
	)
	panel.add_child(sound_row)
	(sound_row.get_node("Slider") as HSlider).value_changed.connect(func(v: float) -> void:
		SettingsManager.sound_volume = v / 100.0
		(sound_row.get_node("ValueLbl") as Label).text = "%d%%" % int(v)
	)


# ── Oberfläche-Tab ────────────────────────────────────────────────────────────

func _build_oberflaeche_tab() -> void:
	var panel := _tab_oberflaeche

	var scale_labels := PackedStringArray(["75%", "100%", "125%", "150%"])
	var scale_idx: int = SettingsManager.UI_SCALES.find(SettingsManager.ui_scale)
	var scale_row := _make_slider_row(
		GameState.T("settings.ui.scale"),
		scale_labels,
		maxi(0, scale_idx),
	)
	panel.add_child(scale_row)
	(scale_row.find_child("Slider", true, false) as HSlider).value_changed.connect(func(v: float) -> void:
		SettingsManager.ui_scale = SettingsManager.UI_SCALES[int(v)]
	)


# ── Steuerung-Tab (Platzhalter) ───────────────────────────────────────────────

func _build_steuerung_tab() -> void:
	var lbl := Label.new()
	lbl.text = GameState.T("settings.controls.coming_soon")
	lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	lbl.add_theme_font_size_override("font_size", 15)
	_tab_steuerung.add_child(lbl)


# ── Row-Builder ───────────────────────────────────────────────────────────────

## Slider-Zeile mit festen Positionen (z.B. 5/10/15/30 Min. oder x5/x10/x20).
## Gibt einen VBoxContainer mit children "Slider" (HSlider) und "TickRow" zurück.
func _make_slider_row(label_text: String, tick_labels: PackedStringArray, start_idx: int) -> VBoxContainer:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var lbl := Label.new()
	lbl.text                    = label_text
	lbl.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(lbl)

	var slider_wrap := VBoxContainer.new()
	slider_wrap.custom_minimum_size = Vector2(500, 0)
	slider_wrap.add_theme_constant_override("separation", 4)
	hbox.add_child(slider_wrap)

	var slider := HSlider.new()
	slider.name        = "Slider"
	slider.min_value   = 0
	slider.max_value   = tick_labels.size() - 1
	slider.step        = 1
	slider.value       = start_idx
	slider.tick_count  = tick_labels.size()
	slider.ticks_on_borders = true
	slider.custom_minimum_size = Vector2(0, 28)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_wrap.add_child(slider)

	var tick_row := HBoxContainer.new()
	tick_row.name = "TickRow"
	tick_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider_wrap.add_child(tick_row)

	for i in tick_labels.size():
		var tick_lbl := Label.new()
		tick_lbl.text = tick_labels[i]
		tick_lbl.add_theme_font_size_override("font_size", 12)
		tick_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.50))
		if i == 0:
			tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		elif i == tick_labels.size() - 1:
			tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		else:
			tick_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tick_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tick_row.add_child(tick_lbl)

	return vbox


## Lautstärke-Slider mit % Anzeige rechts (0–100 kontinuierlich).
func _make_volume_row(label_text: String, current_0_1: float) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var lbl := Label.new()
	lbl.text                    = label_text
	lbl.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(lbl)

	var slider := HSlider.new()
	slider.name        = "Slider"
	slider.min_value   = 0
	slider.max_value   = 100
	slider.step        = 1
	slider.value       = current_0_1 * 100.0
	slider.custom_minimum_size      = Vector2(480, 28)
	slider.size_flags_horizontal    = Control.SIZE_EXPAND_FILL
	hbox.add_child(slider)

	var val_lbl := Label.new()
	val_lbl.name                  = "ValueLbl"
	val_lbl.text                  = "%d%%" % int(current_0_1 * 100.0)
	val_lbl.custom_minimum_size   = Vector2(52, 0)
	val_lbl.horizontal_alignment  = HORIZONTAL_ALIGNMENT_RIGHT
	val_lbl.add_theme_font_size_override("font_size", 15)
	val_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031))
	hbox.add_child(val_lbl)

	return hbox


## An/Aus-Zeile mit CheckButton rechts.
func _make_toggle_row(label_text: String, current: bool) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)

	var lbl := Label.new()
	lbl.text                    = label_text
	lbl.size_flags_horizontal   = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	hbox.add_child(lbl)

	var toggle := CheckButton.new()
	toggle.name           = "Toggle"
	toggle.button_pressed = current
	hbox.add_child(toggle)

	return hbox


func _make_separator() -> HSeparator:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.08)
	return sep


# ── Speichern / Schließen ─────────────────────────────────────────────────────

func _on_save() -> void:
	SettingsManager.save()
	_on_close()


func _on_close() -> void:
	visible = false
	closed.emit()
