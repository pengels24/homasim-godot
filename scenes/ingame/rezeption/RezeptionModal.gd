extends Control
## ANG-162 – Rezeptions-Modal: 4-Spalten Matching-UI.
## Bidirektionales Matching: Gast-first oder Zimmer-first.

const BUILD_PANEL_SCRIPT := preload("res://scenes/ingame/build/BuildPanel.gd")

signal closed()

# ── Farben ────────────────────────────────────────────────────────────────────
const C_NORMAL   := Color(0.08, 0.12, 0.20, 1.0)
const C_SELECTED := Color(0.918, 0.702, 0.031, 0.15)
const C_MATCH    := Color(0.20, 0.78, 0.35, 0.15)
const C_ASK      := Color(0.80, 0.55, 0.05, 0.15)
const C_BORDER   := Color(0.20, 0.24, 0.35, 0.80)
const C_GOLD     := Color(0.918, 0.702, 0.031, 1.0)
const C_GREEN    := Color(0.20, 0.78, 0.35, 1.0)
const C_RED      := Color(0.90, 0.20, 0.20, 1.0)

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _list_waiting:  VBoxContainer = $Panel/Margin/VBox/Columns/ColWaiting/Scroll/List
@onready var _list_rooms:    VBoxContainer = $Panel/Margin/VBox/Columns/ColRooms/Scroll/List
@onready var _list_active:   VBoxContainer = $Panel/Margin/VBox/Columns/ColActive/Scroll/List
@onready var _list_checkout: VBoxContainer = $Panel/Margin/VBox/Columns/ColCheckout/Scroll/List
@onready var _action_info:   Label         = $Panel/Margin/VBox/ActionBar/ActionInfo
@onready var _action_btn:    Button        = $Panel/Margin/VBox/ActionBar/ActionBtn
@onready var _reject_btn:    Button        = $Panel/Margin/VBox/ActionBar/RejectBtn
@onready var _close_btn:     Button        = $Panel/Margin/VBox/Header/CloseBtn

# ── Zustand ───────────────────────────────────────────────────────────────────
var _guest_mgr:       GuestManager
var _clock:           IngameClock

var _sel_party:       GuestParty = null
var _sel_room:        Node2D     = null
var _match_type:      String     = ""   # "perfect"|"ask_price"|"ask_requirements"
var _asked:           bool       = false
var _ask_accepted:    bool       = false

# Mapping: panel_node → GuestParty or Room (für Klick-Handling)
var _party_nodes:     Dictionary = {}   # PanelContainer → GuestParty
var _room_nodes:      Dictionary = {}   # PanelContainer → Room


# ── Setup ─────────────────────────────────────────────────────────────────────

func configure(guest_mgr: GuestManager, clock: IngameClock) -> void:
	_guest_mgr = guest_mgr
	_clock     = clock
	_guest_mgr.parties_changed.connect(_on_parties_changed)


func _ready() -> void:
	_close_btn.pressed.connect(func() -> void: closed.emit())
	_action_btn.pressed.connect(_on_action_btn_pressed)
	_reject_btn.pressed.connect(_on_reject_btn_pressed)
	$Background.gui_input.connect(_on_bg_input)
	_apply_panel_style()
	_apply_title_style()
	_apply_col_header_style()
	_apply_close_btn_style()
	_apply_action_btns_style()


func refresh() -> void:
	_clear_selection()
	_rebuild_all()


# ── Aufbau ────────────────────────────────────────────────────────────────────

func _rebuild_all() -> void:
	_party_nodes.clear()
	_room_nodes.clear()
	_clear_list(_list_waiting)
	_clear_list(_list_rooms)
	_clear_list(_list_active)
	_clear_list(_list_checkout)

	for party: GuestParty in _guest_mgr.get_waiting():
		var card := _make_party_card(party, false)
		_list_waiting.add_child(card)
		_party_nodes[card] = party

	for room: Node2D in _guest_mgr.get_free_rooms():
		var entry := _make_room_entry(room, false)
		_list_rooms.add_child(entry)
		_room_nodes[entry] = room

	for party: GuestParty in _guest_mgr.get_active():
		_list_active.add_child(_make_active_card(party))

	for party: GuestParty in _guest_mgr.get_checkout():
		var card := _make_checkout_card(party)
		_list_checkout.add_child(card)


func _clear_list(list: VBoxContainer) -> void:
	for child in list.get_children():
		child.queue_free()


# ── Karten-Builder ────────────────────────────────────────────────────────────

func _make_party_card(party: GuestParty, highlight: bool) -> PanelContainer:
	var card := _make_card_base(highlight)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	# Primär-Gast: Name + Typ
	var name_row := HBoxContainer.new()
	var name_lbl := _make_lbl("%s" % party.get_display_name(), 15, Color(0.95, 0.95, 0.95))
	var type_lbl := _make_lbl(party.get_type_name(), 13, Color(0.60, 0.60, 0.70))
	name_row.add_child(name_lbl)
	name_row.add_child(_make_spacer())
	name_row.add_child(type_lbl)
	vbox.add_child(name_row)

	# Mitglieder (außer Primary)
	for m: GuestMember in party.members:
		if m.is_primary():
			continue
		var role_str := "Begleitperson" if m.role == "partner" else "Kind"
		var sub := _make_lbl("  └ %s (%s)" % [m.name, role_str], 13, Color(0.50, 0.55, 0.65))
		vbox.add_child(sub)

	# Infos: Aufenthalt + Preis + Patience
	var info_row := HBoxContainer.new()
	info_row.add_theme_constant_override("separation", 8)
	info_row.add_child(_make_lbl("%d Nächte" % party.stay_days, 13, Color(0.65, 0.65, 0.75)))
	info_row.add_child(_make_lbl("%.0f € /Nacht" % party.base_price, 13, Color(0.65, 0.75, 0.55)))
	vbox.add_child(info_row)

	# Patience-Balken
	var patience_bar := _make_patience_bar(party.patience)
	vbox.add_child(patience_bar)

	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_party_clicked(card)
	)
	return card


func _make_room_entry(room: Node2D, highlight: bool) -> PanelContainer:
	var card := _make_card_base(highlight)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var type_id: String = str(room.get("room_type_id"))
	var def := BUILD_PANEL_SCRIPT.find_definition(type_id)
	var label_str:  String = def.get("label", "?")
	var name_str:   String = def.get("name", type_id)
	var price:      int    = def.get("nightly_price", 0)
	var room_num:   String = str(room.get("room_number"))

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	card.add_child(vbox)

	var row1 := HBoxContainer.new()
	row1.add_theme_constant_override("separation", 6)
	var lbl_type := _make_lbl(label_str, 16, C_GOLD)
	row1.add_child(lbl_type)
	if room_num != "" and room_num != "null":
		row1.add_child(_make_spacer())
		row1.add_child(_make_lbl(room_num, 15, Color(0.65, 0.65, 0.75)))
	vbox.add_child(row1)

	var price_str := "%s | %d € / Nacht" % [name_str, price] if price > 0 else name_str
	vbox.add_child(_make_lbl(price_str, 14, Color(0.60, 0.65, 0.75)))

	card.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			_on_room_clicked(card)
	)
	return card


func _make_active_card(party: GuestParty) -> PanelContainer:
	var card := _make_card_base(false)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var name_row := HBoxContainer.new()
	name_row.add_child(_make_lbl(party.get_display_name(), 15, Color(0.95, 0.95, 0.95)))
	name_row.add_child(_make_spacer())
	name_row.add_child(_make_lbl("🔴 %s" % party.room_id, 13, Color(0.70, 0.40, 0.40)))
	vbox.add_child(name_row)

	var days_lbl := _make_lbl("Noch %d Nacht(e)" % party.stay_days, 13, Color(0.55, 0.65, 0.75))
	vbox.add_child(days_lbl)

	return card


func _make_checkout_card(party: GuestParty) -> PanelContainer:
	var card := _make_card_base(false)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var name_row := HBoxContainer.new()
	name_row.add_child(_make_lbl(party.get_display_name(), 15, Color(0.95, 0.95, 0.95)))
	name_row.add_child(_make_spacer())
	name_row.add_child(_make_lbl("🟠 %s" % party.room_id, 13, Color(0.85, 0.60, 0.20)))
	vbox.add_child(name_row)

	var price := party.base_price * float(party.stay_days) * party.satisfaction
	var info  := _make_lbl("%.0f €  · Zufriedenheit %.0f%%" % [price, party.satisfaction * 100.0], 13, Color(0.60, 0.75, 0.50))
	vbox.add_child(info)

	var btn := Button.new()
	btn.text                       = "Checkout"
	btn.custom_minimum_size        = Vector2(90, 28)
	btn.focus_mode                 = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_stylebox_override("normal",  _make_action_sb(Color(0.086, 0.639, 0.290, 1.0), Color.TRANSPARENT))
	btn.add_theme_stylebox_override("hover",   _make_action_sb(Color(0.15, 0.78, 0.38, 1.0), Color(0.918, 0.702, 0.031, 0.70)))
	btn.add_theme_stylebox_override("pressed", _make_action_sb(Color(0.15, 0.78, 0.38, 1.0), Color(0.918, 0.702, 0.031, 0.70)))
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.05, 0.20, 0.08, 1.0))
	btn.pressed.connect(func() -> void: _do_checkout(party))
	vbox.add_child(btn)

	return card


# ── Matching & Selektion ──────────────────────────────────────────────────────

func _on_party_clicked(card: PanelContainer) -> void:
	var party: GuestParty = _party_nodes.get(card)
	if party == null:
		return
	if _sel_party == party:
		_clear_selection()
		return
	_sel_party  = party
	_sel_room   = null
	_asked      = false
	_ask_accepted = false
	_refresh_selection()


func _on_room_clicked(card: PanelContainer) -> void:
	var room: Node2D = _room_nodes.get(card)
	if room == null:
		return
	if _sel_room == room:
		_clear_selection()
		return
	_sel_room   = room
	_sel_party  = null
	_asked      = false
	_ask_accepted = false
	_refresh_selection()


func _refresh_selection() -> void:
	# Karten-Farben zurücksetzen
	for node: PanelContainer in _party_nodes:
		_set_card_color(node, C_NORMAL)
	for node: PanelContainer in _room_nodes:
		_set_card_color(node, C_NORMAL)

	_action_btn.visible  = false
	_reject_btn.visible  = false
	_action_info.text    = ""
	_match_type          = ""

	if _sel_party != null:
		_refresh_party_first()
	elif _sel_room != null:
		_refresh_room_first()


func _refresh_party_first() -> void:
	# Gewählte Party hervorheben
	for node: PanelContainer in _party_nodes:
		if _party_nodes[node] == _sel_party:
			_set_card_color(node, C_SELECTED)
			break

	# Zimmer sortieren und einfärben
	var rooms: Array = _guest_mgr.get_free_rooms()
	var preferred: Array = []
	var allowed:   Array = []
	var disabled:  Array = []

	for room: Node2D in rooms:
		var mt := _guest_mgr.get_match_type(_sel_party, room)
		match mt:
			"perfect":          preferred.append(room)
			"ask_price", "ask_requirements": allowed.append(room)
			_:                  disabled.append(room)

	# Zimmer-Liste neu aufbauen (preferred → allowed → disabled)
	_clear_list(_list_rooms)
	_room_nodes.clear()
	for room: Node2D in preferred + allowed + disabled:
		var mt      := _guest_mgr.get_match_type(_sel_party, room)
		var is_dis  := mt == "disabled"
		var entry   := _make_room_entry(room, false)
		var col     := C_MATCH if mt == "perfect" else (C_ASK if mt != "disabled" else C_NORMAL)
		_set_card_color(entry, col)
		if is_dis:
			entry.modulate = Color(0.5, 0.5, 0.5, 0.6)
			entry.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list_rooms.add_child(entry)
		_room_nodes[entry] = room

	# Wenn Zimmer bereits gewählt → Match prüfen
	if _sel_room != null:
		_evaluate_match()

	_reject_btn.visible = true
	_action_info.text   = "Gast gewählt: %s" % _sel_party.get_display_name()


func _refresh_room_first() -> void:
	# Gewähltes Zimmer hervorheben
	for node: PanelContainer in _room_nodes:
		if _room_nodes[node] == _sel_room:
			_set_card_color(node, C_SELECTED)
			break

	# Gäste deaktivieren die nicht passen
	_clear_list(_list_waiting)
	_party_nodes.clear()
	for party: GuestParty in _guest_mgr.get_waiting():
		var mt    := _guest_mgr.get_match_type(party, _sel_room)
		var card  := _make_party_card(party, false)
		if mt == "disabled":
			card.modulate  = Color(0.5, 0.5, 0.5, 0.6)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_list_waiting.add_child(card)
		_party_nodes[card] = party

	_action_info.text = "Zimmer gewählt: %s" % str(_sel_room.get("room_number"))


func _evaluate_match() -> void:
	if _sel_party == null or _sel_room == null:
		return
	_match_type = _guest_mgr.get_match_type(_sel_party, _sel_room)
	match _match_type:
		"perfect":
			_action_btn.text    = "Checkin bestätigen"
			_action_btn.visible = true
			_action_info.text   = "✅ %s → %s" % [_sel_party.get_display_name(), str(_sel_room.get("room_number"))]
		"ask_price":
			if _asked and _ask_accepted:
				_action_btn.text    = "Checkin bestätigen"
				_action_btn.visible = true
			else:
				_action_btn.text    = "Gast fragen – Aufpreis"
				_action_btn.visible = true
			_action_info.text = "❓ Aufpreis nötig: %s" % _sel_party.get_display_name()
		"ask_requirements":
			if _asked and _ask_accepted:
				_action_btn.text    = "Checkin bestätigen"
				_action_btn.visible = true
			else:
				_action_btn.text    = "Gast fragen – Ausstattung"
				_action_btn.visible = true
			_action_info.text = "❓ Ausstattung fehlt: %s" % _sel_party.get_display_name()
		_:
			_action_btn.visible = false
			_action_info.text   = "🚫 Kein Match möglich"


func _on_action_btn_pressed() -> void:
	if _sel_party == null or _sel_room == null:
		return
	match _match_type:
		"perfect":
			_do_checkin()
		"ask_price", "ask_requirements":
			if _asked and _ask_accepted:
				_do_checkin()
			else:
				_asked = true
				var accepted := _guest_mgr.roll_ask(_sel_party, _sel_room)
				if accepted:
					_ask_accepted = true
					_action_btn.text  = "Checkin bestätigen"
					_action_info.text = "✅ Gast hat zugestimmt!"
				else:
					_action_btn.visible  = false
					_reject_btn.visible  = true
					_action_info.text    = "❌ Gast hat abgelehnt."


func _on_reject_btn_pressed() -> void:
	if _sel_party == null:
		return
	_guest_mgr.reject_party(_sel_party)
	_clear_selection()


func _do_checkin() -> void:
	if _sel_party == null or _sel_room == null:
		return
	_guest_mgr.do_checkin(_sel_party, _sel_room)
	_clear_selection()


func _do_checkout(party: GuestParty) -> void:
	var payout := _guest_mgr.do_checkout(party)
	Toast.show("Checkout: %s – %.0f € erhalten" % [party.get_display_name(), payout])


func _clear_selection() -> void:
	_sel_party    = null
	_sel_room     = null
	_match_type   = ""
	_asked        = false
	_ask_accepted = false
	_rebuild_all()
	_action_btn.visible  = false
	_reject_btn.visible  = false
	_action_info.text    = ""


# ── Hilfsmethoden ─────────────────────────────────────────────────────────────

func _on_parties_changed() -> void:
	if visible:
		_clear_selection()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		closed.emit()


func _on_bg_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton:
		get_viewport().set_input_as_handled()


func _make_card_base(highlight: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = C_SELECTED if highlight else C_NORMAL
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = C_BORDER
	sb.content_margin_left        = 10.0
	sb.content_margin_right       = 10.0
	sb.content_margin_top         = 8.0
	sb.content_margin_bottom      = 8.0
	card.add_theme_stylebox_override("panel", sb)
	return card


func _set_card_color(card: PanelContainer, color: Color) -> void:
	var sb := card.get_theme_stylebox("panel") as StyleBoxFlat
	if sb != null:
		sb.bg_color = color


func _make_patience_bar(patience: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value           = 0.0
	bar.max_value           = 1.0
	bar.value               = patience
	bar.show_percentage     = false
	bar.custom_minimum_size = Vector2(0, 6)
	bar.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	bar.mouse_filter        = Control.MOUSE_FILTER_IGNORE
	var col := Color(0.20, 0.78, 0.35) if patience > 0.6 else \
			   Color(0.88, 0.60, 0.10) if patience > 0.45 else \
			   Color(0.90, 0.20, 0.20)
	var sb_fill := StyleBoxFlat.new()
	sb_fill.bg_color = col
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color   = Color(0.15, 0.15, 0.20)
	bar.add_theme_stylebox_override("fill", sb_fill)
	bar.add_theme_stylebox_override("background", sb_bg)
	return bar


func _make_lbl(text: String, font_sz: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_color", color)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _make_spacer() -> Control:
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_FILL | Control.SIZE_EXPAND
	sp.mouse_filter          = Control.MOUSE_FILTER_IGNORE
	return sp


func _apply_panel_style() -> void:
	var panel := $Panel as PanelContainer
	var sb    := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.07, 0.07, 0.09, 0.97)
	sb.corner_radius_top_left     = 16
	sb.corner_radius_top_right    = 16
	sb.corner_radius_bottom_left  = 16
	sb.corner_radius_bottom_right = 16
	sb.border_width_top           = 1
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_bottom        = 1
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.40)
	sb.shadow_color               = Color(0.918, 0.702, 0.031, 0.15)
	sb.shadow_size                = 12
	panel.add_theme_stylebox_override("panel", sb)


func _apply_title_style() -> void:
	var title := $Panel/Margin/VBox/Header/Title as Label
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 1.0))


func _apply_col_header_style() -> void:
	for path: String in [
		"Panel/Margin/VBox/Columns/ColWaiting/ColHeader",
		"Panel/Margin/VBox/Columns/ColRooms/ColHeader",
		"Panel/Margin/VBox/Columns/ColActive/ColHeader",
		"Panel/Margin/VBox/Columns/ColCheckout/ColHeader",
	]:
		var lbl := get_node_or_null(path) as Label
		if lbl == null:
			continue
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.55, 1.0))


func _apply_close_btn_style() -> void:
	var sb_n := StyleBoxFlat.new()
	sb_n.bg_color                   = Color(0.14, 0.14, 0.18, 1.0)
	sb_n.corner_radius_top_left     = 6
	sb_n.corner_radius_top_right    = 6
	sb_n.corner_radius_bottom_left  = 6
	sb_n.corner_radius_bottom_right = 6
	sb_n.content_margin_left        = 12.0
	sb_n.content_margin_right       = 12.0
	sb_n.content_margin_top         = 6.0
	sb_n.content_margin_bottom      = 6.0
	var sb_h := sb_n.duplicate() as StyleBoxFlat
	sb_h.bg_color = Color(0.24, 0.24, 0.30, 1.0)
	_close_btn.add_theme_stylebox_override("normal",  sb_n)
	_close_btn.add_theme_stylebox_override("hover",   sb_h)
	_close_btn.add_theme_stylebox_override("pressed", sb_h)
	_close_btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	_close_btn.add_theme_font_size_override("font_size", 16)
	_close_btn.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1.0))
	_close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_action_btns_style() -> void:
	var sb_g_n := _make_action_sb(Color(0.086, 0.639, 0.290, 1.0), Color.TRANSPARENT)
	var sb_g_h := _make_action_sb(Color(0.15,  0.78,  0.38,  1.0), Color(0.918, 0.702, 0.031, 0.70))
	var sb_g_d := _make_action_sb(Color(0.086, 0.639, 0.290, 0.18), Color(0.086, 0.639, 0.290, 0.35))
	_action_btn.add_theme_stylebox_override("normal",   sb_g_n)
	_action_btn.add_theme_stylebox_override("hover",    sb_g_h)
	_action_btn.add_theme_stylebox_override("pressed",  sb_g_h)
	_action_btn.add_theme_stylebox_override("disabled", sb_g_d)
	_action_btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	_action_btn.add_theme_font_size_override("font_size", 15)
	_action_btn.add_theme_color_override("font_color", Color(0.05, 0.20, 0.08, 1.0))
	_action_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var sb_r_n := _make_action_sb(Color(0.863, 0.149, 0.149, 1.0), Color.TRANSPARENT)
	var sb_r_h := _make_action_sb(Color(0.980, 0.220, 0.220, 1.0), Color(0.918, 0.702, 0.031, 0.70))
	_reject_btn.add_theme_stylebox_override("normal",   sb_r_n)
	_reject_btn.add_theme_stylebox_override("hover",    sb_r_h)
	_reject_btn.add_theme_stylebox_override("pressed",  sb_r_h)
	_reject_btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	_reject_btn.add_theme_font_size_override("font_size", 15)
	_reject_btn.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96, 1.0))
	_reject_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _make_action_sb(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	if border.a > 0.0:
		sb.border_width_left   = 1
		sb.border_width_right  = 1
		sb.border_width_top    = 1
		sb.border_width_bottom = 1
		sb.border_color        = border
	sb.content_margin_left   = 20.0
	sb.content_margin_right  = 20.0
	sb.content_margin_top    = 10.0
	sb.content_margin_bottom = 10.0
	return sb
