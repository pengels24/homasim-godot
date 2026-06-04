extends CanvasLayer
class_name SimBrowser
## ANG-166 – SimBrowser Shell: F7 öffnet simulierten In-Game-Browser mit home.sim.

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _title_lbl:      Label         = $Center/Window/VBox/TitleBar/TitleLbl
@onready var _btn_close:      Button        = $Center/Window/VBox/TitleBar/BtnClose
@onready var _btn_back:       Button        = $Center/Window/VBox/NavBar/BtnBack
@onready var _btn_forward:    Button        = $Center/Window/VBox/NavBar/BtnForward
@onready var _btn_home:       Button        = $Center/Window/VBox/NavBar/BtnHome
@onready var _address_bar:    LineEdit      = $Center/Window/VBox/NavBar/AddressBar
@onready var _tab_lbl:        Label         = $Center/Window/VBox/TabStrip/TabHome/TabLbl
@onready var _content_vbox:   VBoxContainer = $Center/Window/VBox/ContentScroll/ContentVBox
@onready var _window:         PanelContainer = $Center/Window

# ── Konstanten ────────────────────────────────────────────────────────────────
const COL_BG        := Color(0.09, 0.10, 0.15, 1.0)
const COL_TITLEBAR  := Color(0.06, 0.07, 0.11, 1.0)
const COL_NAVBAR    := Color(0.11, 0.13, 0.19, 1.0)
const COL_TABSTRIP  := Color(0.07, 0.08, 0.13, 1.0)
const COL_TAB_ACT   := Color(0.09, 0.10, 0.15, 1.0)
const COL_CONTENT   := Color(0.07, 0.08, 0.13, 1.0)
const COL_TILE      := Color(0.12, 0.14, 0.21, 1.0)
const COL_TILE_HVR  := Color(0.16, 0.19, 0.28, 1.0)
const COL_GOLD      := Color(0.918, 0.702, 0.031, 1.0)
const COL_TEXT      := Color(0.90, 0.90, 0.92, 1.0)
const COL_MUTED     := Color(0.50, 0.52, 0.58, 1.0)

const SITES: Array[Dictionary] = [
	{ "abbr": "HC", "color": Color(0.18, 0.48, 0.82), "title": "HotelCheck",   "desc": "Bewertungsportal",    "url": "hotelcheck.sim"   },
	{ "abbr": "HB", "color": Color(0.16, 0.64, 0.38), "title": "HotelBooking", "desc": "Online-Buchungen",    "url": "hotelbooking.sim" },
	{ "abbr": "NE", "color": Color(0.82, 0.40, 0.16), "title": "SimNews",      "desc": "Welt-Nachrichten",    "url": "news.sim"         },
	{ "abbr": "LI", "color": Color(0.55, 0.28, 0.72), "title": "Lieferanten",  "desc": "Lieferanten-Katalog", "url": "lieferanten.sim"  },
	{ "abbr": "MI", "color": Color(0.85, 0.12, 0.12), "title": "Michelin",     "desc": "Stern-Fortschritt",   "url": "michelin.sim"     },
	{ "abbr": "A2", "color": Color(0.918,0.702,0.031),"title": "angelus2010",  "desc": "Entwickler-Portal",   "url": "angelus2010.sim",
		"easter": "Hallo Peter! Schoen dich hinter dem Vorhang zu treffen." },
	{ "abbr": "AI", "color": Color(0.72, 0.42, 0.95), "title": "Claude",       "desc": "KI-Assistent",        "url": "claude.sim",
		"easter": "Ich wusste, dass du hier klickst. Hallo vom anderen Ende der Leitung." },
]


# =============================================================================
func _ready() -> void:
	_apply_styles()
	_build_home_sim()
	_btn_close.pressed.connect(close)
	_btn_home.pressed.connect(func() -> void: _address_bar.text = "home.sim")


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
func open() -> void:
	visible = true


# =============================================================================
func close() -> void:
	visible = false


# ── Styles ────────────────────────────────────────────────────────────────────

# =============================================================================
func _apply_styles() -> void:
	_style_panel(_window, COL_BG, Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.25), 1, 8)

	var title_bar := _window.get_node("VBox/TitleBar") as HBoxContainer
	title_bar.add_theme_constant_override("separation", 0)
	_style_bg(title_bar, COL_TITLEBAR)

	_title_lbl.add_theme_font_size_override("font_size", 14)
	_title_lbl.add_theme_color_override("font_color", COL_MUTED)
	_title_lbl.add_theme_constant_override("margin_left", 16)

	_style_nav_btn(_btn_close)
	_btn_close.custom_minimum_size = Vector2(28, 28)
	_btn_close.add_theme_font_size_override("font_size", 13)
	_btn_close.add_theme_color_override("font_color", COL_MUTED)

	var nav_bar := _window.get_node("VBox/NavBar") as HBoxContainer
	nav_bar.add_theme_constant_override("separation", 4)
	_style_bg(nav_bar, COL_NAVBAR)
	nav_bar.add_theme_constant_override("margin_left", 8)
	nav_bar.add_theme_constant_override("margin_right", 8)

	for btn in [_btn_back, _btn_forward, _btn_home]:
		_style_nav_btn(btn)
		btn.custom_minimum_size = Vector2(38, 32)
		btn.add_theme_font_size_override("font_size", 15)
		btn.add_theme_color_override("font_color", COL_TEXT)

	_btn_back.add_theme_color_override("font_color", COL_MUTED)
	_btn_forward.add_theme_color_override("font_color", COL_MUTED)

	var addr_style := StyleBoxFlat.new()
	addr_style.bg_color = Color(0.05, 0.06, 0.09)
	addr_style.corner_radius_top_left    = 14
	addr_style.corner_radius_top_right   = 14
	addr_style.corner_radius_bottom_left = 14
	addr_style.corner_radius_bottom_right = 14
	addr_style.content_margin_left  = 12.0
	addr_style.content_margin_right = 12.0
	_address_bar.add_theme_stylebox_override("normal", addr_style)
	_address_bar.add_theme_stylebox_override("focus",  addr_style)
	_address_bar.add_theme_color_override("font_color", COL_TEXT)
	_address_bar.add_theme_font_size_override("font_size", 13)
	_address_bar.custom_minimum_size = Vector2(0, 32)
	_address_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	var tab_strip := _window.get_node("VBox/TabStrip") as HBoxContainer
	_style_bg(tab_strip, COL_TABSTRIP)

	var tab_home := _window.get_node("VBox/TabStrip/TabHome") as PanelContainer
	_style_panel(tab_home, COL_TAB_ACT, Color.TRANSPARENT, 0, 0)
	tab_home.add_theme_constant_override("margin_left",  12)
	tab_home.add_theme_constant_override("margin_right", 12)
	tab_home.add_theme_constant_override("margin_top",    4)
	tab_home.add_theme_constant_override("margin_bottom", 0)
	_tab_lbl.add_theme_font_size_override("font_size", 13)
	_tab_lbl.add_theme_color_override("font_color", COL_TEXT)

	var scroll := _window.get_node("VBox/ContentScroll") as ScrollContainer
	var scroll_style := StyleBoxFlat.new()
	scroll_style.bg_color = COL_CONTENT
	scroll.add_theme_stylebox_override("panel", scroll_style)


# =============================================================================
func _style_panel(node: Control, bg: Color, border: Color, bw: int, radius: int) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.border_width_top = bw; s.border_width_left = bw
	s.border_width_right = bw; s.border_width_bottom = bw
	s.corner_radius_top_left    = radius
	s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	node.add_theme_stylebox_override("panel", s)


# =============================================================================
func _style_bg(_node: Control, _color: Color) -> void:
	pass  # HBoxContainer hat kein "panel"-Override; Hintergrundfarbe kommt vom Parent-Panel


# =============================================================================
func _style_nav_btn(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color = Color.TRANSPARENT
	s.corner_radius_top_left = 6; s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6; s.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(1, 1, 1, 0.08)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


# ── home.sim ──────────────────────────────────────────────────────────────────

# =============================================================================
func _build_home_sim() -> void:
	_content_vbox.add_theme_constant_override("separation", 20)

	_content_vbox.add_child(_make_header())

	var grid_wrap := MarginContainer.new()
	grid_wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_wrap.add_theme_constant_override("margin_left",  32)
	grid_wrap.add_theme_constant_override("margin_right", 32)
	_content_vbox.add_child(grid_wrap)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid_wrap.add_child(grid)

	for site in SITES:
		grid.add_child(_make_tile(site))

	var tip_wrap := MarginContainer.new()
	tip_wrap.add_theme_constant_override("margin_bottom", 20)
	_content_vbox.add_child(tip_wrap)

	var tip := Label.new()
	tip.text = "Tipp: Gib eine URL in die Adressleiste ein und druecke Enter."
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size", 12)
	tip.add_theme_color_override("font_color", COL_MUTED)
	tip_wrap.add_child(tip)


# =============================================================================
func _make_header() -> Control:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_top",    40)
	margin.add_theme_constant_override("margin_left",   32)
	margin.add_theme_constant_override("margin_right",  32)
	margin.add_theme_constant_override("margin_bottom",  0)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "home.sim"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", COL_GOLD)
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "Ihr persoenlicher Simulations-Browser"
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", COL_MUTED)
	vbox.add_child(sub)

	var sep := HSeparator.new()
	sep.add_theme_color_override("color", Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.20))
	vbox.add_child(sep)

	return margin


# =============================================================================
func _make_tile(site: Dictionary) -> Control:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var s := StyleBoxFlat.new()
	s.bg_color = COL_TILE
	s.corner_radius_top_left    = 8; s.corner_radius_top_right   = 8
	s.corner_radius_bottom_left = 8; s.corner_radius_bottom_right = 8
	s.border_color = Color(0.25, 0.28, 0.38, 1.0)
	s.border_width_top = 1; s.border_width_left = 1
	s.border_width_right = 1; s.border_width_bottom = 1
	btn.add_theme_stylebox_override("normal", s)
	var hov := s.duplicate() as StyleBoxFlat
	hov.bg_color = COL_TILE_HVR
	hov.border_color = Color(COL_GOLD.r, COL_GOLD.g, COL_GOLD.b, 0.50)
	btn.add_theme_stylebox_override("hover", hov)
	btn.add_theme_stylebox_override("pressed", s)

	# Innen-Padding via MarginContainer
	var pad := MarginContainer.new()
	pad.set_anchors_preset(Control.PRESET_FULL_RECT)
	pad.add_theme_constant_override("margin_left",  16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top",    0)
	pad.add_theme_constant_override("margin_bottom", 0)
	btn.add_child(pad)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	pad.add_child(hbox)

	# Icon links
	var icon_center := CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(52, 0)
	icon_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var icon_rect := PanelContainer.new()
	icon_rect.custom_minimum_size = Vector2(44, 44)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = site["color"]
	icon_style.corner_radius_top_left    = 10; icon_style.corner_radius_top_right   = 10
	icon_style.corner_radius_bottom_left = 10; icon_style.corner_radius_bottom_right = 10
	icon_rect.add_theme_stylebox_override("panel", icon_style)
	var abbr_center := CenterContainer.new()
	var abbr_lbl := Label.new()
	abbr_lbl.text = site["abbr"]
	abbr_lbl.add_theme_font_size_override("font_size", 14)
	abbr_lbl.add_theme_color_override("font_color", Color.WHITE)
	abbr_center.add_child(abbr_lbl)
	icon_rect.add_child(abbr_center)
	icon_center.add_child(icon_rect)
	hbox.add_child(icon_center)

	# Text mitte
	var text_vbox := VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.size_flags_vertical   = Control.SIZE_SHRINK_CENTER
	text_vbox.add_theme_constant_override("separation", 3)
	hbox.add_child(text_vbox)

	var name_lbl := Label.new()
	name_lbl.text = site["title"]
	name_lbl.add_theme_font_size_override("font_size", 14)
	name_lbl.add_theme_color_override("font_color", COL_TEXT)
	text_vbox.add_child(name_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = site["desc"]
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", COL_MUTED)
	text_vbox.add_child(desc_lbl)

	# Schloss rechts
	var lock_lbl := Label.new()
	lock_lbl.text = "🔒"
	lock_lbl.add_theme_font_size_override("font_size", 14)
	lock_lbl.add_theme_color_override("font_color", Color(0.50, 0.32, 0.32, 1.0))
	lock_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(lock_lbl)

	btn.pressed.connect(func() -> void: _on_tile_pressed(site))
	return btn


# =============================================================================
func _on_tile_pressed(site: Dictionary) -> void:
	if site.has("easter"):
		Toast.show(site["easter"])
	else:
		Toast.show(site["url"] + " – Diese Seite ist noch nicht verfuegbar.")
