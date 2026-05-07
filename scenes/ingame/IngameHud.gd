extends Node2D
class_name IngameHud
## ANG-170 – TopBar + BottomBar UI-Aufbau, Tooltip, Reputation.
## Erhält alle nötigen Node-Referenzen via configure(). Keine @onready.

signal bottom_button_pressed(idx: int)
signal view_reset_requested()

# ── HUD-Fontgrößen ────────────────────────────────────────────────────────────
const HF_XS   := 10
const HF_SM   := 12
const HF_MD   := 14
const HF_LG   := 16
const HF_XL   := 18
const HF_TIME := 22
const HF_LOGO := 22

# ── BottomBar Konstanten ──────────────────────────────────────────────────────
const BB_BTN_SIZE  := 46.0
const BB_BTN_GAP   := 8.0
const BB_PADDING_X := 14.0
const BB_PADDING_Y := 12.0
const BB_MARGIN    := 8.0

# ── Node-Referenzen (gesetzt via configure) ───────────────────────────────────
var _hotel:              Dictionary
var _hud_canvas:         CanvasLayer

var _hotel_name_lbl:     Label
var _level_lbl:          Label
var _stat_day_val:       Label
var _stat_money_val:     Label
var _stat_guests_wait:   Label
var _stat_guests_active: Label
var _stat_guests_out:    Label
var _stat_ap_val:        Label
var _stat_exp_bar:       Control
var _stat_exp_lbl:       Label
var _exp_fill:           ColorRect
var _stat_ruf_root:      Control
var _stat_ruf_lbl:       Label
var _stat_fp_val:        Label
var _bottom_anchor:      Control
var _context_bar:        HBoxContainer

# ── Zustand ───────────────────────────────────────────────────────────────────
var _ruf_indicator:         ColorRect
var _fan_mode_btn:          Button
var _mode_icon_center:      Label
var _mode_icon_back:        TextureRect
var _bottom_buttons:        Array[Button]     = []
var _active_btn_idx:  int               = -1
var _bb_sb_normal:    StyleBoxFlat
var _bb_sb_hover:     StyleBoxFlat
var _bb_sb_active:    StyleBoxFlat
var _tooltip_panel:   PanelContainer
var _tooltip_lbl:     Label
var _bb_btn_defs:     Array[Dictionary] = []
var _bar_w:           float = 0.0
var _bar_h:           float = 0.0


func configure(hotel: Dictionary, refs: Dictionary, hud_canvas: CanvasLayer) -> void:
	_hotel              = hotel
	_hud_canvas         = hud_canvas
	_hotel_name_lbl     = refs["hotel_name_lbl"]
	_level_lbl          = refs["level_lbl"]
	_stat_day_val       = refs["stat_day_val"]
	_stat_money_val     = refs["stat_money_val"]
	_stat_guests_wait   = refs["stat_guests_wait"]
	_stat_guests_active = refs["stat_guests_active"]
	_stat_guests_out    = refs["stat_guests_out"]
	_stat_ap_val        = refs["stat_ap_val"]
	_stat_exp_bar       = refs["stat_exp_bar"]
	_stat_exp_lbl       = refs["stat_exp_lbl"]
	_stat_ruf_root      = refs["stat_ruf_root"]
	_stat_ruf_lbl       = refs["stat_ruf_lbl"]
	_stat_fp_val        = refs["stat_fp_val"]
	_bottom_anchor      = refs["bottom_anchor"]
	_context_bar          = refs["context_bar"]
	_context_bar.z_index  = 10
	SettingsManager.hud_side_changed.connect(reposition_hud)
	_setup_hud()
	_build_exp_bar(0, 100)
	_build_ruf_bar()
	_build_bottom_bar()
	_build_context_bar()


# ── Public API ────────────────────────────────────────────────────────────────

func set_btn_active(idx: int) -> void:
	for i in _bottom_buttons.size():
		var b: Button = _bottom_buttons[i]
		if i == idx:
			b.add_theme_stylebox_override("normal", _bb_sb_active)
			b.add_theme_stylebox_override("hover",  _bb_sb_active)
		else:
			b.add_theme_stylebox_override("normal", _bb_sb_normal)
			b.add_theme_stylebox_override("hover",  _bb_sb_hover)
	_active_btn_idx = idx


func show_context_bar(shown: bool) -> void:
	_context_bar.visible = shown


func update_day(day: int) -> void:
	_stat_day_val.text = str(day)


func update_money(amount: float) -> void:
	_stat_money_val.text = "€ " + _format_money(int(amount))


func update_exp(xp: int) -> void:
	_stat_exp_lbl.text = "%d XP" % xp


func set_mode_btn_saved(saved: bool) -> void:
	_mode_icon_center.visible = not saved
	_mode_icon_back.visible   = saved


func get_stat_money_node() -> Control:
	return _stat_money_val


func get_stat_exp_node() -> Control:
	return _stat_exp_lbl


func get_stat_fp_node() -> Control:
	return _stat_fp_val


func get_bottom_button(idx: int) -> Button:
	if idx < 0 or idx >= _bottom_buttons.size():
		return null
	return _bottom_buttons[idx]


## Locked-Check + Signal-Emission – gleiche Logik wie physischer Button-Klick.
func trigger_button(idx: int) -> void:
	if idx < _bb_btn_defs.size() and _bb_btn_defs[idx].get("locked", false):
		return
	bottom_button_pressed.emit(idx)


# ── HUD-Setup ─────────────────────────────────────────────────────────────────

func _setup_hud() -> void:
	_hotel_name_lbl.text     = _hotel.get("name", "Hotel")
	_level_lbl.text          = "LVL 1"
	_stat_day_val.text       = str(int(_hotel.get("day", 1)))
	_stat_money_val.text     = "€ " + _format_money(int(_hotel.get("money", 0)))
	_stat_guests_wait.text   = "0"
	_stat_guests_active.text = "0"
	_stat_guests_out.text    = "0"
	_stat_ap_val.text        = "0 / 100"
	var initial_xp: int = _hotel.get("xp", 0)
	_stat_exp_lbl.text = "%d XP" % initial_xp
	_build_exp_bar(initial_xp, 100)
	_stat_fp_val.text        = "0"
	_update_ruf_display(500)
	_apply_value_box(_stat_money_val)
	_apply_value_box(_stat_ap_val)
	_apply_value_box(_stat_fp_val)
	_apply_value_box(_stat_day_val)
	_apply_guest_badge(_stat_guests_wait,   Color(0.20, 0.78, 0.35))
	_apply_guest_badge(_stat_guests_active, Color(0.918, 0.702, 0.031))
	_apply_guest_badge(_stat_guests_out,    Color(0.85, 0.20, 0.20))


func _apply_value_box(lbl: Label) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.11, 0.15, 0.21, 1.0)
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = Color(0.28, 0.30, 0.38, 0.65)
	sb.corner_radius_top_left     = 3
	sb.corner_radius_top_right    = 3
	sb.corner_radius_bottom_left  = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left        = 8.0
	sb.content_margin_right       = 8.0
	sb.content_margin_top         = 3.0
	sb.content_margin_bottom      = 3.0
	lbl.add_theme_stylebox_override("normal", sb)


func _apply_guest_badge(lbl: Label, tint: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(tint.r, tint.g, tint.b, 0.12)
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = Color(tint.r, tint.g, tint.b, 0.35)
	sb.corner_radius_top_left     = 3
	sb.corner_radius_top_right    = 3
	sb.corner_radius_bottom_left  = 3
	sb.corner_radius_bottom_right = 3
	sb.content_margin_left        = 5.0
	sb.content_margin_right       = 5.0
	sb.content_margin_top         = 2.0
	sb.content_margin_bottom      = 2.0
	lbl.add_theme_stylebox_override("normal", sb)


# ── RUF-Bar ───────────────────────────────────────────────────────────────────

func _build_ruf_bar() -> void:
	var colors: Array[Color] = [
		Color(0.82, 0.15, 0.15),
		Color(0.88, 0.48, 0.08),
		Color(0.84, 0.74, 0.08),
		Color(0.30, 0.74, 0.22),
		Color(0.08, 0.50, 0.12),
	]
	var bar_w  := 130.0
	var bar_h  := 10.0
	var seg_w  := bar_w / colors.size()

	for i in colors.size():
		var seg := ColorRect.new()
		seg.color    = colors[i]
		seg.position = Vector2(i * seg_w, 2.0)
		seg.size     = Vector2(seg_w, bar_h)
		_stat_ruf_root.add_child(seg)

	_ruf_indicator          = ColorRect.new()
	_ruf_indicator.color    = Color(1, 1, 1, 0.90)
	_ruf_indicator.size     = Vector2(2, 14)
	_ruf_indicator.position = Vector2(0, 0)
	_stat_ruf_root.add_child(_ruf_indicator)

	await get_tree().process_frame
	_update_ruf_display(500)


# ── EXP-Bar ───────────────────────────────────────────────────────────────────

func _build_exp_bar(value: int, max_val: int) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.16, 0.22, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stat_exp_bar.add_child(bg)

	_exp_fill          = ColorRect.new()
	_exp_fill.color    = Color(0.20, 0.48, 0.85, 1.0)
	_exp_fill.position = Vector2.ZERO
	_exp_fill.size     = Vector2.ZERO
	_stat_exp_bar.add_child(_exp_fill)

	await get_tree().process_frame
	_update_exp_fill(value, max_val)


func _update_exp_fill(value: int, max_val: int) -> void:
	if not is_instance_valid(_exp_fill):
		return
	var bar_w := _stat_exp_bar.size.x
	var bar_h := _stat_exp_bar.size.y
	if bar_w == 0:
		bar_w = 120.0
	if bar_h == 0:
		bar_h = 10.0
	_exp_fill.size = Vector2(
		clampf((float(value) / float(max(max_val, 1))) * bar_w, 0.0, bar_w),
		bar_h
	)


func _update_ruf_display(rep: int) -> void:
	_stat_ruf_lbl.text = "%d / 1000" % rep
	if not is_instance_valid(_ruf_indicator):
		return
	var bar_w := _stat_ruf_root.size.x
	if bar_w == 0:
		bar_w = 130.0
	_ruf_indicator.position.x = clampf((rep / 1000.0) * bar_w - 1.0, 0.0, bar_w - 2.0)


# ── BottomBar ─────────────────────────────────────────────────────────────────

func _build_bottom_bar() -> void:
	_bb_btn_defs = [
		{"icon": "+", "icon_path": "res://assets/icons/ic_buildmode.svg",  "label": GameState.T("ingame.btn.build"),      "key": "F2",    "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "★", "icon_path": "res://assets/icons/ic_browser.svg",    "label": GameState.T("ingame.btn.simbrowser"), "key": "F7",    "locked": false, "dot_color": Color(0.20, 0.78, 0.35, 1.0)},
		{"icon": "⚙", "icon_path": "res://assets/icons/ic_settings.svg",   "label": GameState.T("ingame.btn.settings"),   "key": "ALT+S", "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "R", "icon_path": "res://assets/icons/ic_reception.svg",  "label": GameState.T("ingame.btn.reception"),  "key": "F3",    "locked": false, "dot_color": Color(0.20, 0.78, 0.35, 1.0)},
		{"icon": "P", "icon_path": "res://assets/icons/ic_staff.svg",      "label": GameState.T("ingame.btn.staff"),      "key": "F4",    "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "–", "icon_path": "",                                       "label": GameState.T("ingame.btn.empty"),      "key": "",      "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "★", "icon_path": "res://assets/icons/ic_techtree.svg",   "label": GameState.T("ingame.btn.research"),   "key": "F6",    "locked": true,  "dot_color": Color.TRANSPARENT},
	]

	_bb_sb_normal = _make_btn_stylebox(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55))
	_bb_sb_hover  = _make_btn_stylebox(Color(0.10, 0.16, 0.26, 0.96), Color(0.918, 0.702, 0.031, 0.70))
	_bb_sb_active = _make_btn_stylebox(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0))

	var btn_count := _bb_btn_defs.size()
	_bar_w = BB_PADDING_X * 2.0 + btn_count * BB_BTN_SIZE + (btn_count - 1) * BB_BTN_GAP
	_bar_h = BB_PADDING_Y * 2.0 + BB_BTN_SIZE
	_apply_bar_anchor()

	# Hintergrund
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color                   = Color(0.03, 0.06, 0.12, 0.93)
	sb_bg.corner_radius_top_left     = 12
	sb_bg.corner_radius_top_right    = 12
	sb_bg.corner_radius_bottom_left  = 6
	sb_bg.corner_radius_bottom_right = 6
	sb_bg.border_width_top           = 1
	sb_bg.border_width_left          = 1
	sb_bg.border_width_right         = 1
	sb_bg.border_width_bottom        = 1
	sb_bg.border_color               = Color(0.918, 0.702, 0.031, 0.38)
	var bg_panel := Panel.new()
	bg_panel.add_theme_stylebox_override("panel", sb_bg)
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_anchor.add_child(bg_panel)

	# Buttons horizontal
	for i in btn_count:
		var btn := _make_bar_btn(i)
		btn.position = Vector2(BB_PADDING_X + i * (BB_BTN_SIZE + BB_BTN_GAP), BB_PADDING_Y)
		_bottom_anchor.add_child(btn)
		_bottom_buttons.append(btn)

	# Tooltip (immer auf hud_canvas)
	_build_tooltip()

	# Sprung-Button: fix unten-links, unabhängig von Bar-Seite
	_fan_mode_btn = _make_mode_indicator()
	_fan_mode_btn.pressed.connect(func(): view_reset_requested.emit())
	_fan_mode_btn.mouse_entered.connect(func(): _show_tooltip("HOME · " + GameState.T("ingame.btn.reset_view")))
	_fan_mode_btn.mouse_exited.connect(func():  _hide_tooltip())
	_hud_canvas.add_child(_fan_mode_btn)
	await get_tree().process_frame
	_position_mode_btn()


func _apply_bar_anchor() -> void:
	_bottom_anchor.anchor_top    = 1.0
	_bottom_anchor.anchor_bottom = 1.0
	if SettingsManager.hud_side == "right":
		_bottom_anchor.anchor_left  = 1.0
		_bottom_anchor.anchor_right = 1.0
		_bottom_anchor.offset_left  = -(BB_MARGIN + _bar_w)
		_bottom_anchor.offset_right = -BB_MARGIN
	else:
		_bottom_anchor.anchor_left  = 0.0
		_bottom_anchor.anchor_right = 0.0
		_bottom_anchor.offset_left  = BB_MARGIN
		_bottom_anchor.offset_right = BB_MARGIN + _bar_w
	_bottom_anchor.offset_top    = -(BB_MARGIN + _bar_h)
	_bottom_anchor.offset_bottom = -BB_MARGIN
	# ContextBar direkt über der Bar positionieren
	_context_bar.anchor_top    = 1.0
	_context_bar.anchor_bottom = 1.0
	if SettingsManager.hud_side == "right":
		_context_bar.anchor_left  = 1.0
		_context_bar.anchor_right = 1.0
		_context_bar.offset_left  = -(BB_MARGIN + _bar_w)
		_context_bar.offset_right = -BB_MARGIN
	else:
		_context_bar.anchor_left  = 0.0
		_context_bar.anchor_right = 0.0
		_context_bar.offset_left  = BB_MARGIN
		_context_bar.offset_right = BB_MARGIN + _bar_w
	_context_bar.offset_bottom = -(BB_MARGIN + _bar_h + 6.0)
	_context_bar.offset_top    = _context_bar.offset_bottom - 32.0


func _position_mode_btn() -> void:
	if not is_instance_valid(_fan_mode_btn):
		return
	var vw := float(get_viewport().get_visible_rect().size.x)
	var vh := float(get_viewport().get_visible_rect().size.y)
	_fan_mode_btn.position = Vector2((vw - BB_BTN_SIZE) * 0.5, vh - BB_MARGIN - BB_BTN_SIZE)


func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	_tooltip_panel.z_index = 100
	var sb_tip := StyleBoxFlat.new()
	sb_tip.bg_color                   = Color(0.04, 0.06, 0.10, 0.96)
	sb_tip.corner_radius_top_left     = 6
	sb_tip.corner_radius_top_right    = 6
	sb_tip.corner_radius_bottom_left  = 6
	sb_tip.corner_radius_bottom_right = 6
	sb_tip.border_width_top           = 1
	sb_tip.border_color               = Color(0.918, 0.702, 0.031, 0.30)
	sb_tip.content_margin_left        = 14.0
	sb_tip.content_margin_right       = 14.0
	sb_tip.content_margin_top         = 8.0
	sb_tip.content_margin_bottom      = 8.0
	_tooltip_panel.add_theme_stylebox_override("panel", sb_tip)
	_tooltip_lbl = Label.new()
	_tooltip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip_lbl.add_theme_font_size_override("font_size", 14)
	_tooltip_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	_tooltip_panel.add_child(_tooltip_lbl)
	_hud_canvas.add_child(_tooltip_panel)


## Gibt die globale Rect der BottomBar zurück (für BuildPanel-Positionierung).
func get_bottom_bar_global_rect() -> Rect2:
	return Rect2(_bottom_anchor.global_position, _bottom_anchor.size)


## Repositioniert Bar + Sprung-Button nach Seitenwechsel in den Settings.
func reposition_hud() -> void:
	_apply_bar_anchor()
	_position_mode_btn()


func _make_btn_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.corner_radius_top_left     = 23
	sb.corner_radius_top_right    = 23
	sb.corner_radius_bottom_left  = 23
	sb.corner_radius_bottom_right = 23
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = border
	sb.shadow_color               = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size                = 4
	sb.shadow_offset              = Vector2(0.0, 2.0)
	return sb


func _make_bar_btn(idx: int) -> Button:
	var def := _bb_btn_defs[idx]

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(BB_BTN_SIZE, BB_BTN_SIZE)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal",   _bb_sb_normal)
	btn.add_theme_stylebox_override("hover",    _bb_sb_hover)
	btn.add_theme_stylebox_override("pressed",  _bb_sb_active)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", _bb_sb_normal)

	const ICON_D   := 22.0
	const ICON_OFF := (BB_BTN_SIZE - ICON_D) * 0.5
	var icon_node: Control
	var icon_path: String = def.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex := TextureRect.new()
		tex.texture          = load(icon_path)
		tex.expand_mode      = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode     = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size             = Vector2(ICON_D, ICON_D)
		tex.position         = Vector2(ICON_OFF, ICON_OFF)
		tex.mouse_filter     = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)
		icon_node = tex
	else:
		var lbl := Label.new()
		lbl.text                 = def.get("icon", "?")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		lbl.size         = Vector2(BB_BTN_SIZE, BB_BTN_SIZE)
		lbl.position     = Vector2(0, 0)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)
		icon_node = lbl

	var dot_color: Color = def.get("dot_color", Color.TRANSPARENT)
	if dot_color.a > 0.0:
		var dot_sb := StyleBoxFlat.new()
		dot_sb.bg_color                   = dot_color
		dot_sb.corner_radius_top_left     = 4
		dot_sb.corner_radius_top_right    = 4
		dot_sb.corner_radius_bottom_left  = 4
		dot_sb.corner_radius_bottom_right = 4
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", dot_sb)
		dot.custom_minimum_size = Vector2(8, 8)
		dot.anchor_left   = 1.0
		dot.anchor_right  = 1.0
		dot.offset_left   = -12.0
		dot.offset_right  = -4.0
		dot.offset_top    = 4.0
		dot.offset_bottom = 12.0
		dot.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		btn.add_child(dot)

	if def.get("locked", false):
		btn.disabled       = true
		icon_node.modulate = Color(1, 1, 1, 0.35)

	btn.pressed.connect(func(): _on_btn_pressed(idx))
	btn.mouse_entered.connect(func(): _show_tooltip(("%s · " % def["key"] if def["key"] != "" else "") + def["label"]))
	btn.mouse_exited.connect(func():  _hide_tooltip())
	return btn


func _make_mode_indicator() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(46, 46)
	btn.focus_mode          = Control.FOCUS_NONE

	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.07, 0.13, 0.96)
	sb.corner_radius_top_left     = 23
	sb.corner_radius_top_right    = 23
	sb.corner_radius_bottom_left  = 23
	sb.corner_radius_bottom_right = 23
	sb.border_width_left          = 2
	sb.border_width_right         = 2
	sb.border_width_top           = 2
	sb.border_width_bottom        = 2
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.85)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.border_color = Color(0.918, 0.702, 0.031, 1.0)
	sb_hover.bg_color     = Color(0.10, 0.13, 0.20, 0.96)
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	_mode_icon_center                      = Label.new()
	_mode_icon_center.text                 = "◆"
	_mode_icon_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_icon_center.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_mode_icon_center.add_theme_font_size_override("font_size", 14)
	_mode_icon_center.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 0.75))
	_mode_icon_center.anchor_right         = 1.0
	_mode_icon_center.anchor_bottom        = 1.0
	_mode_icon_center.mouse_filter         = Control.MOUSE_FILTER_IGNORE
	btn.add_child(_mode_icon_center)

	const ICON_D   := 22.0
	const ICON_OFF := (BB_BTN_SIZE - ICON_D) * 0.5
	_mode_icon_back              = TextureRect.new()
	_mode_icon_back.texture      = load("res://assets/icons/ic_rotate_ccw.svg")
	_mode_icon_back.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
	_mode_icon_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_mode_icon_back.size         = Vector2(ICON_D, ICON_D)
	_mode_icon_back.position     = Vector2(ICON_OFF, ICON_OFF)
	_mode_icon_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mode_icon_back.visible      = false
	btn.add_child(_mode_icon_back)

	return btn


func _on_btn_pressed(idx: int) -> void:
	if _bb_btn_defs[idx].get("locked", false):
		return
	bottom_button_pressed.emit(idx)


func _show_tooltip(text: String) -> void:
	_tooltip_lbl.text       = text
	_tooltip_panel.modulate = Color(1, 1, 1, 0)
	_tooltip_panel.visible  = true
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(_tooltip_panel) or not _tooltip_panel.visible:
		return
	var bar_rect := _bottom_anchor.get_global_rect()
	_tooltip_panel.position = Vector2(
		bar_rect.position.x + 10.0,
		bar_rect.position.y - _tooltip_panel.size.y - 8.0
	)
	_tooltip_panel.modulate = Color(1, 1, 1, 1)


func _hide_tooltip() -> void:
	_tooltip_panel.visible = false


# ── ContextBar ────────────────────────────────────────────────────────────────

func _build_context_bar() -> void:
	var hints: Array[Dictionary] = [
		{"key": "R", "label": GameState.T("ingame.ctx.rotate_door")},
		{"key": "T", "label": GameState.T("ingame.ctx.move_door")},
		{"key": "Z", "label": GameState.T("ingame.ctx.flip_room")},
	]

	for hint in hints:
		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % hint["key"]
		key_lbl.add_theme_font_size_override("font_size", HF_MD)
		key_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 1))

		var desc_lbl := Label.new()
		desc_lbl.text = hint["label"]
		desc_lbl.add_theme_font_size_override("font_size", HF_MD)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))

		_context_bar.add_child(key_lbl)
		_context_bar.add_child(desc_lbl)

		if hint != hints.back():
			var sep := Label.new()
			sep.text = "·"
			sep.add_theme_font_size_override("font_size", HF_MD)
			sep.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 1))
			_context_bar.add_child(sep)


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

func _format_money(amount: int) -> String:
	var s      := str(amount)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
