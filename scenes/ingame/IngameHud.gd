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
var _bottom_anchor:      Control
var _context_bar:        HBoxContainer

# ── Zustand ───────────────────────────────────────────────────────────────────
var _fan_mode_btn:          Button
var _mode_icon_center:      Label
var _mode_icon_back:        TextureRect
var _bottom_buttons:        Array[Button]     = []
var _active_btn_idx:  int               = -1
var _bb_sb_normal:    StyleBox
var _bb_sb_hover:     StyleBox
var _bb_sb_active:    StyleBox
var _tooltip_panel:   PanelContainer
var _tooltip_lbl:     Label
var _bb_btn_defs:     Array[Dictionary] = []
var _bar_w:           float = 0.0
var _bar_h:           float = 0.0


# =============================================================================
func configure(hotel: Dictionary, refs: Dictionary, hud_canvas: CanvasLayer) -> void:
	_hotel              = hotel
	_hud_canvas         = hud_canvas
	_hotel_name_lbl     = refs["hotel_name_lbl"]
	_level_lbl          = refs["level_lbl"]
	_stat_day_val       = refs["stat_day_val"]
	_stat_money_val     = refs["stat_money_val"]
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

# =============================================================================
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


# =============================================================================
func show_context_bar(shown: bool) -> void:
	_context_bar.visible = shown


# =============================================================================
func update_day(day: int) -> void:
	_stat_day_val.text = str(day)


# =============================================================================
func update_money(amount: float) -> void:
	_stat_money_val.text = "€ " + _format_money(int(amount))


# =============================================================================
func update_guest_stats(_waiting: int, _active: int, _checkout: int) -> void:
	# _stat_guests_wait.text   = str(waiting)
	# _stat_guests_active.text = str(active)
	# _stat_guests_out.text    = str(checkout)
	pass


# =============================================================================
func update_exp(_xp: int) -> void:
	# _stat_exp_lbl.text = "%d XP" % xp
	pass


# =============================================================================
func set_mode_btn_saved(saved: bool) -> void:
	_mode_icon_center.visible = not saved
	_mode_icon_back.visible   = saved


# =============================================================================
func get_stat_money_node() -> Control:
	return _stat_money_val


# =============================================================================
func get_stat_exp_node() -> Control:
	# return _stat_exp_lbl
	return


# =============================================================================
func get_stat_fp_node() -> Control:
	# return _stat_fp_val
	return


# =============================================================================
func get_bottom_button(idx: int) -> Button:
	if idx < 0 or idx >= _bottom_buttons.size():
		return null
	return _bottom_buttons[idx]


# =============================================================================
func set_btn_locked(idx: int, locked: bool) -> void:
	if idx < 0 or idx >= _bottom_buttons.size():
		return
	_bb_btn_defs[idx]["locked"] = locked
	var btn: Button = _bottom_buttons[idx]
	btn.disabled = locked
	if btn.get_child_count() > 0:
		btn.get_child(0).modulate = Color(1.0, 1.0, 1.0, 0.35 if locked else 1.0)


# =============================================================================
## Locked-Check + Signal-Emission – gleiche Logik wie physischer Button-Klick.
func trigger_button(idx: int) -> void:
	if idx < _bb_btn_defs.size() and _bb_btn_defs[idx].get("locked", false):
		return
	bottom_button_pressed.emit(idx)


# ── HUD-Setup ─────────────────────────────────────────────────────────────────

# =============================================================================
func _setup_hud() -> void:
	pass


# =============================================================================
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


# =============================================================================
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

# =============================================================================
func _build_ruf_bar() -> void:
	pass


# ── EXP-Bar ───────────────────────────────────────────────────────────────────

# =============================================================================
func _build_exp_bar(_value: int, _max_val: int) -> void:
	pass


# =============================================================================
func _update_exp_fill(_value: int, _max_val: int) -> void:
	pass


# =============================================================================
func _update_ruf_display(_rep: int) -> void:
	pass


# ── BottomBar ─────────────────────────────────────────────────────────────────

# =============================================================================
func _build_bottom_bar() -> void:
	_bb_btn_defs = [
		{"icon": "+", "icon_path": "res://assets/icons/ic_buildmode.svg",  "label": GameState.T("ingame.btn.build"),      "key": "F2",    "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "★", "icon_path": "res://assets/icons/ic_browser.svg",    "label": GameState.T("ingame.btn.simbrowser"), "key": "F7",    "locked": false, "dot_color": Color(0.20, 0.78, 0.35, 1.0)},
		{"icon": "⚙", "icon_path": "res://assets/icons/ic_settings.svg",   "label": GameState.T("ingame.btn.settings"),   "key": "ALT+S", "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "R", "icon_path": "res://assets/icons/ic_reception.svg",  "label": GameState.T("ingame.btn.reception"),  "key": "F3",    "locked": true,  "dot_color": Color(0.20, 0.78, 0.35, 1.0)},
		{"icon": "P", "icon_path": "res://assets/icons/ic_staff.svg",      "label": GameState.T("ingame.btn.staff"),      "key": "F4",    "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "–", "icon_path": "",                                       "label": GameState.T("ingame.btn.empty"),      "key": "",      "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "★", "icon_path": "res://assets/icons/ic_techtree.svg",   "label": GameState.T("ingame.btn.research"),   "key": "F6",    "locked": true,  "dot_color": Color.TRANSPARENT},
	]

	var btn_tex := load("res://assets/UI/hud_button_round.aseprite") as Texture2D
	if btn_tex != null:
		var sb_base := StyleBoxTexture.new()
		sb_base.texture              = btn_tex
		sb_base.expand_margin_left   = 4.0
		sb_base.expand_margin_right  = 5.0
		sb_base.expand_margin_top    = 3.0
		sb_base.expand_margin_bottom = 3.0
		_bb_sb_normal = sb_base
		var sb_h := sb_base.duplicate() as StyleBoxTexture
		sb_h.modulate_color = Color(1.2, 1.2, 1.35)
		_bb_sb_hover  = sb_h
		var sb_a := sb_base.duplicate() as StyleBoxTexture
		sb_a.modulate_color = Color(1.4, 1.05, 0.35)
		_bb_sb_active = sb_a
	else:
		_bb_sb_normal = _make_btn_stylebox(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55))
		_bb_sb_hover  = _make_btn_stylebox(Color(0.10, 0.16, 0.26, 0.96), Color(0.918, 0.702, 0.031, 0.70))
		_bb_sb_active = _make_btn_stylebox(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0))

	var btn_count := _bb_btn_defs.size()
	_bar_w = BB_PADDING_X * 2.0 + btn_count * BB_BTN_SIZE + (btn_count - 1) * BB_BTN_GAP
	_bar_h = BB_PADDING_Y * 2.0 + BB_BTN_SIZE
	_apply_bar_anchor()

	# Hintergrund: explizite Größe – kein PRESET_FULL_RECT-Timing-Problem
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
	bg_panel.position    = Vector2.ZERO
	bg_panel.size        = Vector2(_bar_w, _bar_h)
	bg_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bottom_anchor.add_child(bg_panel)
	# Optionale Textur on top
	var bar_tex := load("res://assets/UI/hud_bottom.aseprite") as Texture2D
	if bar_tex != null:
		var bg := NinePatchRect.new()
		bg.texture              = bar_tex
		bg.patch_margin_left   = 15
		bg.patch_margin_right  = 15
		bg.patch_margin_top    = 15
		bg.patch_margin_bottom = 15
		bg.position            = Vector2.ZERO
		bg.size                = Vector2(_bar_w, _bar_h)
		bg.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		_bottom_anchor.add_child(bg)

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


# =============================================================================
func _apply_bar_anchor() -> void:
	_bottom_anchor.anchor_top    = 1.0
	_bottom_anchor.anchor_bottom = 1.0
	match SettingsManager.hud_side:
		"right":
			_bottom_anchor.anchor_left  = 1.0
			_bottom_anchor.anchor_right = 1.0
			_bottom_anchor.offset_left  = -(BB_MARGIN + _bar_w)
			_bottom_anchor.offset_right = -BB_MARGIN
		"center":
			_bottom_anchor.anchor_left  = 0.5
			_bottom_anchor.anchor_right = 0.5
			_bottom_anchor.offset_left  = -_bar_w * 0.5
			_bottom_anchor.offset_right =  _bar_w * 0.5
		_: # left
			_bottom_anchor.anchor_left  = 0.0
			_bottom_anchor.anchor_right = 0.0
			_bottom_anchor.offset_left  = BB_MARGIN
			_bottom_anchor.offset_right = BB_MARGIN + _bar_w
	_bottom_anchor.offset_top    = -(BB_MARGIN + _bar_h)
	_bottom_anchor.offset_bottom = -BB_MARGIN
	# ContextBar direkt über der Bar positionieren
	_context_bar.anchor_top    = 1.0
	_context_bar.anchor_bottom = 1.0
	match SettingsManager.hud_side:
		"right":
			_context_bar.anchor_left  = 1.0
			_context_bar.anchor_right = 1.0
			_context_bar.offset_left  = -(BB_MARGIN + _bar_w)
			_context_bar.offset_right = -BB_MARGIN
		"center":
			_context_bar.anchor_left  = 0.5
			_context_bar.anchor_right = 0.5
			_context_bar.offset_left  = -_bar_w * 0.5
			_context_bar.offset_right =  _bar_w * 0.5
		_: # left
			_context_bar.anchor_left  = 0.0
			_context_bar.anchor_right = 0.0
			_context_bar.offset_left  = BB_MARGIN
			_context_bar.offset_right = BB_MARGIN + _bar_w
	_context_bar.offset_bottom = -(BB_MARGIN + _bar_h + 6.0)
	_context_bar.offset_top    = _context_bar.offset_bottom - 32.0


# =============================================================================
func _position_mode_btn() -> void:
	pass


# =============================================================================
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


# =============================================================================
## Gibt die globale Rect der BottomBar zurück (für BuildPanel-Positionierung).
func get_bottom_bar_global_rect() -> Rect2:
	return Rect2(_bottom_anchor.global_position, _bottom_anchor.size)


# =============================================================================
## Repositioniert Bar + Sprung-Button nach Seitenwechsel in den Settings.
func reposition_hud() -> void:
	_apply_bar_anchor()
	_position_mode_btn()


# =============================================================================
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


# =============================================================================
func _make_bar_btn(idx: int) -> Button:
	var def := _bb_btn_defs[idx]
	var btn := Button.new()
	btn.custom_minimum_size      = Vector2(BB_BTN_SIZE, BB_BTN_SIZE)
	btn.focus_mode               = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
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


# =============================================================================
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


# =============================================================================
func _on_btn_pressed(idx: int) -> void:
	if _bb_btn_defs[idx].get("locked", false):
		return
	bottom_button_pressed.emit(idx)


# =============================================================================
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


# =============================================================================
func _hide_tooltip() -> void:
	_tooltip_panel.visible = false


# ── ContextBar ────────────────────────────────────────────────────────────────

# =============================================================================
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

# =============================================================================
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
