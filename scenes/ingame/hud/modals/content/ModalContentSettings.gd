extends TabContainer

const KEYBINDING_ROW = preload("res://scenes/ingame/hud/modals/content/KeybindingRow.tscn")

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

@onready var btn_tutorial_left: Button  = %ButtonTutorialTipsLeft
@onready var btn_tutorial_right: Button = %ButtonTutorialTipsRight
@onready var lbl_tutorial: Label        = %LabelTutorialTipsValue

@onready var slider_zoom: HSlider   = %HSliderZoomSens
@onready var lbl_zoom: Label        = %LabelZoomSensValue
@onready var lbl_zoom_title: Label  = %LabelZoomSens

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

@onready var btn_tech_left: Button  = %ButtonTechInfoLeft
@onready var btn_tech_right: Button = %ButtonTechInfoRight
@onready var lbl_tech: Label        = %LabelTechInfoValue

@onready var btn_lang_left: Button  = %ButtonLanguageLeft
@onready var btn_lang_right: Button = %ButtonLanguageRight
@onready var lbl_lang: Label        = %LabelLanguageValue

# Interne Speicherstruktur für die Left/Right-Logik
var _sel_data: Dictionary = {}

# =============================================================================
func _ready() -> void:
	_init_gameplay_tab()
	_init_audio_tab()
	_init_ui_tab()
	_init_keybindings_tab()

	get_tree().root.content_scale_factor = SettingsManager.ui_scale

	# Alle Labels initial einmal in der aktuellen Sprache befüllen
	_refresh_translated_labels()


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

	_setup_selector("tutorial", btn_tutorial_left, btn_tutorial_right, lbl_tutorial,
		[GameState.T("label.off"), GameState.T("label.on")], [false, true],
		SettingsManager.tutorial_tips, _on_tutorial_tips_changed)

	if is_instance_valid(slider_zoom):
		slider_zoom.value = SettingsManager.scroll_zoom_sensitivity
		lbl_zoom.text = "%.1fx" % slider_zoom.value
		slider_zoom.value_changed.connect(func(val: float):
			lbl_zoom.text = "%.1fx" % val
			SettingsManager.scroll_zoom_sensitivity = val
			SettingsManager.save()
		)


# =============================================================================
func _init_audio_tab() -> void:
	_setup_slider(slider_master, lbl_master, SettingsManager.master_volume, _on_master_vol_changed)
	_setup_slider(slider_bg,     lbl_bg,     SettingsManager.music_volume,  _on_bg_vol_changed)
	_setup_slider(slider_menu,   lbl_menu,   SettingsManager.menu_music_volume, _on_menu_vol_changed)
	_setup_slider(slider_sounds, lbl_sounds, SettingsManager.sound_volume,  _on_sounds_vol_changed)


# =============================================================================
func _init_ui_tab() -> void:
	_init_keybindings_tab()
	_setup_selector("scale", btn_scale_left, btn_scale_right, lbl_scale,
		SettingsManager.UI_SCALES_LABELS,
		SettingsManager.UI_SCALES,
		SettingsManager.ui_scale, _on_scale_changed)

	_setup_selector("toast", btn_toast_left, btn_toast_right, lbl_toast, 
			SettingsManager.ui_toast_pos_labels, SettingsManager.UI_TOAST_POS, 
			SettingsManager.toast_position, _on_toast_changed)
			
	_setup_selector("hud", btn_hud_left, btn_hud_right, lbl_hud, 
			SettingsManager.ui_hudbottom_pos_labels, SettingsManager.UI_HUDBOTTOM_POS, 
			SettingsManager.hud_side, _on_hud_changed)
			
	_setup_selector("tech", btn_tech_left, btn_tech_right, lbl_tech,
			[GameState.T("label.off"), GameState.T("label.on")], [false, true],
			SettingsManager.show_tech_info, _on_tech_info_changed)

	_setup_selector("lang", btn_lang_left, btn_lang_right, lbl_lang,
			SettingsManager.LANGUAGES_LABELS, SettingsManager.LANGUAGES,
			SettingsManager.language, _on_language_changed)

	# Sprache nur im Hauptmenü änderbar
	var ingame := GameState.active_hotel_id != -1
	btn_lang_left.disabled  = ingame
	btn_lang_right.disabled = ingame
	if ingame:
		lbl_lang.text = lbl_lang.text + "  ·  " + GameState.T("settings.language.main_menu_only")


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
func _on_tutorial_tips_changed(val: bool) -> void:
	SettingsManager.tutorial_tips = val
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

func _on_tech_info_changed(val: bool) -> void:
	SettingsManager.set_tech_info(val)


# =============================================================================
func _on_language_changed(val: String) -> void:
	SettingsManager.language = val
	TranslationServer.set_locale(val)
	SettingsManager.save()
	SettingsManager.sig_language_changed.emit(val)
	# Nur im Hauptmenü → Szene neu laden damit alle Labels sofort übersetzt sind
	if GameState.active_hotel_id == -1:
		get_tree().reload_current_scene()
	else:
		_refresh_translated_labels()


## Aktualisiert alle Labels im Modal die über GameState.T() befüllt wurden.
func _refresh_translated_labels() -> void:
	# Tab-Namen
	set_tab_title(0, GameState.T("settings.tab.gameplay"))
	set_tab_title(1, GameState.T("settings.tab.audio"))
	set_tab_title(2, GameState.T("settings.tab.ui"))
	set_tab_title(3, GameState.T("settings.tab.controls"))
	
	# Zeilen-Labels im Gameplay-Tab
	if is_instance_valid(%LabelAutosave):
		%LabelAutosave.text = GameState.T("settings.gameplay.autosave")
	if is_instance_valid(%LabelFastForward):
		%LabelFastForward.text = GameState.T("settings.gameplay.ff_speed")
	if is_instance_valid(%LabelTutorialTips):
		%LabelTutorialTips.text = GameState.T("settings.gameplay.tutorial_tips")
	if is_instance_valid(%LabelZoomSens):
		%LabelZoomSens.text = GameState.T("settings.gameplay.zoom_sens")
		
	# Zeilen-Labels im Audio-Tab
	if is_instance_valid(%LabelVolMaster):
		%LabelVolMaster.text = GameState.T("settings.audio.master")
	if is_instance_valid(%LabelVolBG):
		%LabelVolBG.text = GameState.T("settings.audio.music")
	if is_instance_valid(%LabelVolMenu):
		%LabelVolMenu.text = GameState.T("settings.audio.menu_music")
	if is_instance_valid(%LabelVolSounds):
		%LabelVolSounds.text = GameState.T("settings.audio.sound")

	# Zeilen-Labels im Oberfläche-Tab
	if is_instance_valid(%LabelLanguage):
		%LabelLanguage.text = GameState.T("settings.ui.language")
	if is_instance_valid(%LabelUIScale):
		%LabelUIScale.text = GameState.T("settings.ui.scale")
	if is_instance_valid(%LabelToastPos):
		%LabelToastPos.text = GameState.T("settings.ui.toast_position")
	if is_instance_valid(%LabelPosHUDBottom):
		%LabelPosHUDBottom.text = GameState.T("settings.ui.hud_side")
	if is_instance_valid(%LabelTechInfo):
		%LabelTechInfo.text = GameState.T("settings.ui.tech_info")



# =============================================================================
# ── TASTATURBELEGUNG ─────────────────────────────────────────────────────────
# =============================================================================

@onready var kb_container: VBoxContainer = %KeybindingsContainer
@onready var btn_reset_all_keys: Button = %ButtonResetAllKeys

func _init_keybindings_tab() -> void:
	if not is_instance_valid(kb_container):
		return
	
	if not btn_reset_all_keys.pressed.is_connected(_on_reset_all_keys_pressed):
		btn_reset_all_keys.pressed.connect(_on_reset_all_keys_pressed)
	
	btn_reset_all_keys.text = GameState.T("settings.controls.reset_all")
	_build_keybindings_ui()


func _build_keybindings_ui() -> void:
	# Clear existing
	for child in kb_container.get_children():
		child.queue_free()
	
	var config = SettingsManager.keybindings_config
	
	# Sort groups by order
	var groups = config.keys()
	groups.sort_custom(func(a, b): return config[a].get("order", 99) < config[b].get("order", 99))
	
	for group_id in groups:
		var group = config[group_id]
		
		# Group Header
		var header = Label.new()
		header.text = GameState.T(group.get("label", group_id))
		header.theme_type_variation = &"HeaderMedium"
		kb_container.add_child(header)
		
		# Sort actions by order
		var actions = group.get("actions", {})
		var action_keys = actions.keys()
		action_keys.sort_custom(func(a, b): return actions[a].get("order", 99) < actions[b].get("order", 99))
		
		for action_id in action_keys:
			var action_data = actions[action_id]
			
			var row = KEYBINDING_ROW.instantiate() as KeybindingRow
			kb_container.add_child(row)
			
			row.lbl_action.text = GameState.T(action_data.get("label", action_id))
			
			# Current bindings
			var _p_str = action_data.get("default", "")
			var primary = OS.find_keycode_from_string(_p_str) if _p_str != "" else KEY_NONE
			var _a_str = action_data.get("default_alt", "")
			var alt = OS.find_keycode_from_string(_a_str) if _a_str != "" else KEY_NONE
			if SettingsManager.custom_keybindings.has(action_id):
				var custom = SettingsManager.custom_keybindings[action_id]
				primary = int(custom[0]) as Key
				alt = int(custom[1]) as Key
				
			row.btn_primary.text = _keycode_to_string(primary as Key) if primary != KEY_NONE else "-"
			if primary == KEY_NONE:
				row.btn_primary.add_theme_color_override("font_color", Color.RED)
			row.btn_primary.pressed.connect(func(): _capture_key(action_id, 0))
			
			row.btn_alt.text = _keycode_to_string(alt as Key) if alt != KEY_NONE else "-"
			row.btn_alt.pressed.connect(func(): _capture_key(action_id, 1))
			
			row.btn_delete.pressed.connect(func():
				SettingsManager.reset_keybinding(action_id)
				_build_keybindings_ui()
			)


func _on_reset_all_keys_pressed() -> void:
	SettingsManager.reset_all_keybindings()
	_build_keybindings_ui()


func _capture_key(action_id: String, slot_idx: int) -> void:
	# Add overlay in a CanvasLayer so it covers everything and anchors work
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var group_id = ""
	for g in SettingsManager.keybindings_config:
		if SettingsManager.keybindings_config[g].get("actions", {}).has(action_id):
			group_id = g
			break
			
	var lbl_text = action_id
	if group_id != "":
		lbl_text = SettingsManager.keybindings_config[group_id]["actions"][action_id].get("label", action_id)
	
	var confirm = preload("res://scenes/shared/ConfirmModal.tscn").instantiate()
	
	# Zuerst in den Baum einhängen, damit die @onready Variablen von ConfirmModal initialisiert werden!
	canvas.add_child(confirm)
	get_tree().root.add_child(canvas)
	
	confirm.ask("Taste belegen", "Bitte drücke jetzt eine Taste für:\n" + GameState.T(lbl_text) + "\n\n(ESC zum Abbrechen)")
	confirm.visible = true
	# Verstecke die Buttons, da wir ja auf einen beliebigen Tastendruck warten
	confirm.get_node("Center/Card/Margin/VBox/Buttons").hide()
	
	# Block input handling temporarily
	var handler = Node.new()
	handler.name = "KeyCaptureHandler"
	handler.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Create local script dynamically to handle unhandled key input
	var script = GDScript.new()
	script.source_code = """
extends Node
var action_id: String
var slot_idx: int
var modal_ref: Node
var callback: Callable

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		get_viewport().set_input_as_handled()
		callback.call(event.physical_keycode)
		modal_ref.queue_free()
"""
	script.reload()
	handler.set_script(script)
	handler.set("action_id", action_id)
	handler.set("slot_idx", slot_idx)
	handler.set("modal_ref", canvas)
	handler.set("callback", Callable(self, "_on_key_captured").bind(action_id, slot_idx))
	
	# Explicitly enable input processing since the script was attached dynamically
	handler.set_process_input(true)
	
	canvas.add_child(handler)


func _on_key_captured(keycode: Key, action_id: String, slot_idx: int) -> void:
	if keycode == KEY_ESCAPE:
		return # Cancel
		
	# Check for collisions
	var collision_action = ""
	for group_key in SettingsManager.keybindings_config:
		var actions = SettingsManager.keybindings_config[group_key].get("actions", {})
		for a_id in actions:
			if a_id == action_id and slot_idx == 0: continue # Same action, same slot is fine
			
			var _p_str = actions[a_id].get("default", "")
			var p = OS.find_keycode_from_string(_p_str) if _p_str != "" else KEY_NONE
			var _a_str = actions[a_id].get("default_alt", "")
			var a = OS.find_keycode_from_string(_a_str) if _a_str != "" else KEY_NONE
			if SettingsManager.custom_keybindings.has(a_id):
				p = int(SettingsManager.custom_keybindings[a_id][0]) as Key
				a = int(SettingsManager.custom_keybindings[a_id][1]) as Key
				
			if p == keycode or a == keycode:
				collision_action = a_id
				break
		if collision_action != "": break
	
	if collision_action != "":
		# Use ConfirmModal
		var confirm = preload("res://scenes/shared/ConfirmModal.tscn").instantiate()
		get_tree().root.add_child(confirm)
		confirm.ask("Taste bereits belegt", "Die Taste ist bereits für '" + collision_action + "' belegt. Überschreiben?", "Ja", "Nein")
		confirm.confirmed.connect(func():
			_save_key(action_id, slot_idx, keycode)
			# Unbind from old action
			_unbind_key(collision_action, keycode)
			confirm.queue_free()
		)
		confirm.cancelled.connect(func(): confirm.queue_free())
	else:
		_save_key(action_id, slot_idx, keycode)

func _save_key(action_id: String, slot_idx: int, keycode: Key) -> void:
	var p = KEY_NONE
	var a = KEY_NONE
	
	var actions = {}
	for g in SettingsManager.keybindings_config.values():
		actions.merge(g.get("actions", {}))
		
	if SettingsManager.custom_keybindings.has(action_id):
		p = int(SettingsManager.custom_keybindings[action_id][0]) as Key
		a = int(SettingsManager.custom_keybindings[action_id][1]) as Key
	elif actions.has(action_id):
		var _p_str = actions[action_id].get("default", "")
		var _a_str = actions[action_id].get("default_alt", "")
		p = OS.find_keycode_from_string(_p_str) if _p_str != "" else KEY_NONE
		a = OS.find_keycode_from_string(_a_str) if _a_str != "" else KEY_NONE
		
	if slot_idx == 0:
		p = keycode
	else:
		a = keycode
		
	SettingsManager.update_keybinding(action_id, p, a)
	_build_keybindings_ui()

func _unbind_key(action_id: String, keycode: Key) -> void:
	var p = KEY_NONE
	var a = KEY_NONE
	
	var actions = {}
	for g in SettingsManager.keybindings_config.values():
		actions.merge(g.get("actions", {}))
		
	if SettingsManager.custom_keybindings.has(action_id):
		p = int(SettingsManager.custom_keybindings[action_id][0]) as Key
		a = int(SettingsManager.custom_keybindings[action_id][1]) as Key
	elif actions.has(action_id):
		var _p_str = actions[action_id].get("default", "")
		var _a_str = actions[action_id].get("default_alt", "")
		p = OS.find_keycode_from_string(_p_str) if _p_str != "" else KEY_NONE
		a = OS.find_keycode_from_string(_a_str) if _a_str != "" else KEY_NONE
		
	if p == keycode: p = KEY_NONE
	if a == keycode: a = KEY_NONE
	
	SettingsManager.update_keybinding(action_id, p, a)
	_build_keybindings_ui()

func _exit_tree() -> void:
	var missing_primary = false
	for group in SettingsManager.keybindings_config.values():
		var actions = group.get("actions", {})
		for action_id in actions:
			var _p_str = actions[action_id].get("default", "")
			var primary = OS.find_keycode_from_string(_p_str) if _p_str != "" else KEY_NONE
			if SettingsManager.custom_keybindings.has(action_id):
				primary = int(SettingsManager.custom_keybindings[action_id][0]) as Key
			if primary == KEY_NONE:
				missing_primary = true
				break
		if missing_primary: break
	
	if missing_primary:
		Toast.show(GameState.T("toast.settings.missing_keybind"))

# =============================================================================
func _translate_key(key_str: String) -> String:
	var t_key = "key." + key_str.to_lower().replace(" ", "_")
	var translated = GameState.T(t_key)
	if translated == t_key:
		return key_str
	return translated

func _keycode_to_string(keycode: Key) -> String:
	if keycode == KEY_NONE: return "---"
	return _translate_key(OS.get_keycode_string(keycode))
