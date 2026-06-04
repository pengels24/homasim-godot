extends CanvasLayer
class_name InGameSaveModal
## ANG-176 – In-Game Speichern/Laden Modal.
## Einheitliches Modal für beide Modi: save=true → 5 Manuelle Slots,
## save=false → 5 Manuelle + bis zu 5 Autosaves.

signal save_completed
signal load_completed(hotel_id: int)
signal back_requested

@onready var _title_lbl:           Label         = $Overlay/Panel/Margin/VBox/Header/TitleLbl
@onready var _slot_container:      VBoxContainer = $Overlay/Panel/Margin/VBox/SlotContainer
@onready var _auto_sep:            Panel         = $Overlay/Panel/Margin/VBox/AutoSep
@onready var _auto_lbl:            Label         = $Overlay/Panel/Margin/VBox/AutoLbl
@onready var _auto_slot_container: VBoxContainer = $Overlay/Panel/Margin/VBox/AutoSlotContainer
@onready var _name_row:            HBoxContainer = $Overlay/Panel/Margin/VBox/NameRow
@onready var _name_input:          LineEdit      = $Overlay/Panel/Margin/VBox/NameRow/NameInput
@onready var _btn_action:          Button        = $Overlay/Panel/Margin/VBox/BtnRow/BtnAction
@onready var _close_btn:           Button        = $Overlay/Panel/Margin/VBox/Header/CloseBtn
@onready var _panel:               PanelContainer = $Overlay/Panel

const SLOT_COUNT       := 5
const PANEL_W          := 720.0
const PANEL_H_SAVE     := 530.0
const PANEL_H_LOAD     := 760.0
const CLR_SLOT_NORMAL  := Color(0.08, 0.09, 0.12, 1.0)
const CLR_SLOT_SEL     := Color(0.10, 0.28, 0.12, 1.0)

var _hotel_id:      int        = -1
var _is_save:       bool       = true
var _selected_slot: int        = -1
var _selected_auto: bool       = false
var _slots:         Dictionary = {}


# =============================================================================
func _ready() -> void:
	_btn_action.pressed.connect(_on_action_pressed)
	_close_btn.pressed.connect(func(): back_requested.emit())


# =============================================================================
func open(hotel_id: int, is_save: bool) -> void:
	_hotel_id      = hotel_id
	_is_save       = is_save
	_selected_slot = -1
	_selected_auto = false
	_slots         = SaveManager.get_save_slots(hotel_id)

	_title_lbl.text          = GameState.T("saveslots.save.title") if is_save else GameState.T("saveslots.load.title")
	_auto_sep.visible        = not is_save
	_auto_lbl.visible        = not is_save
	_auto_slot_container.visible = not is_save
	_name_row.visible        = is_save
	_btn_action.text         = GameState.T("saveslots.save.btn.save") if is_save else GameState.T("saveslots.load.btn.load")
	_btn_action.disabled                  = true
	_btn_action.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_name_input.text         = ""
	_name_input.editable     = false
	_name_input.focus_mode   = Control.FOCUS_NONE

	_populate_slots()
	_reposition_panel()
	visible = true


# =============================================================================
func close() -> void:
	visible = false


# ── Layout ────────────────────────────────────────────────────────────────────

# =============================================================================
func _reposition_panel() -> void:
	var h := PANEL_H_SAVE if _is_save else PANEL_H_LOAD
	_panel.offset_left   = (1920.0 - PANEL_W) * 0.5
	_panel.offset_right  = _panel.offset_left + PANEL_W
	_panel.offset_top    = (1080.0 - h) * 0.5
	_panel.offset_bottom = _panel.offset_top + h


# ── Slot-Aufbau ───────────────────────────────────────────────────────────────

# =============================================================================
func _populate_slots() -> void:
	for c in _slot_container.get_children():
		c.queue_free()
	for c in _auto_slot_container.get_children():
		c.queue_free()

	var manual: Array = _slots.get("manual", [])
	for i in SLOT_COUNT:
		var snap: Variant = manual[i] if i < manual.size() else null
		_slot_container.add_child(_build_slot_row(i, snap, false))

	if not _is_save:
		var autos: Array = _slots.get("auto", [])
		if autos.is_empty():
			var empty_lbl := Label.new()
			empty_lbl.text = GameState.T("saveslots.auto.empty")
			empty_lbl.add_theme_font_size_override("font_size", 14)
			empty_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.45))
			_auto_slot_container.add_child(empty_lbl)
		else:
			for i in mini(autos.size(), SLOT_COUNT):
				_auto_slot_container.add_child(_build_slot_row(i, autos[i], true))


# =============================================================================
func _build_slot_row(idx: int, snap: Variant, is_auto: bool) -> Control:
	var row   := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color                   = CLR_SLOT_NORMAL
	style.corner_radius_top_left     = 4
	style.corner_radius_top_right    = 4
	style.corner_radius_bottom_left  = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left        = 14.0
	style.content_margin_right       = 14.0
	style.content_margin_top         = 9.0
	style.content_margin_bottom      = 9.0
	row.add_theme_stylebox_override("panel", style)
	row.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	row.add_child(hbox)

	var num_lbl := Label.new()
	num_lbl.text = "%d" % (idx + 1)
	num_lbl.custom_minimum_size = Vector2(22, 0)
	num_lbl.add_theme_font_size_override("font_size", 15)
	num_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.50))
	num_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(num_lbl)

	var name_lbl := Label.new()
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 18)
	name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(name_lbl)

	var date_lbl := Label.new()
	date_lbl.add_theme_font_size_override("font_size", 15)
	date_lbl.add_theme_color_override("font_color", Color(0.42, 0.42, 0.52))
	date_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(date_lbl)

	if snap != null and snap is Dictionary:
		name_lbl.text = snap.get("name", "Spielstand %d" % (idx + 1))
		name_lbl.add_theme_color_override("font_color", Color(0.90, 0.90, 0.90))
		var ts: int = snap.get("timestamp", 0)
		if ts > 0:
			var dt := Time.get_datetime_dict_from_unix_time(ts)
			date_lbl.text = "%02d.%02d.%d %02d:%02d" % [
				dt["day"], dt["month"], dt["year"], dt["hour"], dt["minute"]]
	else:
		name_lbl.text = GameState.T("saveslots.slot.empty")
		name_lbl.add_theme_color_override("font_color", Color(0.32, 0.32, 0.38))
		if _is_save:
			date_lbl.text = GameState.T("saveslots.slot.new")
			date_lbl.add_theme_color_override("font_color", Color(0.28, 0.52, 0.28))

	row.gui_input.connect(_on_slot_input.bind(idx, is_auto, row, style, snap))
	return row


# ── Slot-Auswahl ──────────────────────────────────────────────────────────────

# =============================================================================
func _on_slot_input(event: InputEvent, idx: int, is_auto: bool,
		row: PanelContainer, style: StyleBoxFlat, snap: Variant) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_select_slot(idx, is_auto, row, style, snap)


# =============================================================================
func _select_slot(idx: int, is_auto: bool, row: PanelContainer,
		style: StyleBoxFlat, snap: Variant) -> void:
	_deselect_all()
	_selected_slot = idx
	_selected_auto = is_auto
	style.bg_color = CLR_SLOT_SEL
	row.add_theme_stylebox_override("panel", style)

	if _is_save:
		var existing: String = snap.get("name", "") if snap is Dictionary else ""
		_name_input.editable   = true
		_name_input.focus_mode = Control.FOCUS_ALL
		_name_input.text = existing
		_name_input.grab_focus()
		_btn_action.disabled                  = false
		_btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		var can_load := snap != null and snap is Dictionary
		_btn_action.disabled                  = not can_load
		_btn_action.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if can_load else Control.CURSOR_ARROW


# =============================================================================
func _deselect_all() -> void:
	_reset_container_styles(_slot_container)
	_reset_container_styles(_auto_slot_container)


# =============================================================================
func _reset_container_styles(container: VBoxContainer) -> void:
	for child in container.get_children():
		if child is PanelContainer:
			var s := child.get_theme_stylebox("panel") as StyleBoxFlat
			if is_instance_valid(s):
				s.bg_color = CLR_SLOT_NORMAL


# ── Aktion ────────────────────────────────────────────────────────────────────

# =============================================================================
func _on_action_pressed() -> void:
	if _selected_slot < 0:
		return
	if _is_save:
		var save_name := _name_input.text.strip_edges()
		if save_name.is_empty():
			save_name = "Slot %d" % (_selected_slot + 1)
		SaveManager.save_manual(_hotel_id, _selected_slot, save_name)
		Toast.show(GameState.T("toast.manualsave"))
		close()
		save_completed.emit()
	else:
		var ok: bool
		if _selected_auto:
			ok = SaveManager.load_auto(_hotel_id, _selected_slot)
		else:
			ok = SaveManager.load_manual(_hotel_id, _selected_slot)
		if ok:
			Toast.show_after_scene_change(GameState.T("toast.manualload.ok"))
			close()
			load_completed.emit(_hotel_id)
		else:
			Toast.show(GameState.T("toast.manualload.empty"))


# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			back_requested.emit()
