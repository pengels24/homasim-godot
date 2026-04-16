extends Control

# ANG-150 – Credits Scroll-Abspann
# Inhalt: res://assets/credits.txt – editierbar ohne Code-Änderung
# Schritt 1: Layout & Technik | Schritt 2: SVG-Icons, Animationen, Musik

const SCROLL_SPEED := 55.0  # px/s

const GOLD  := Color(0.918, 0.702, 0.031, 1)
const WHITE := Color(0.98, 0.98, 0.98, 1)
const GREY  := Color(0.55, 0.55, 0.55, 1)

const LEFT_W   := 640
const RIGHT_W  := 1280
const SCREEN_H := 1080
const CONTENT_W := 860

# Schritt 2: icon_path mit SVG aus assets/icons/ befüllen
const SOCIAL_LINKS: Array = [
	{"label": "YT",  "name": "YouTube",   "url": "https://www.youtube.com/@Angelus2010"},
	{"label": "DC",  "name": "Discord",   "url": "https://discord.gg/hYSvUqmhcw"},
	{"label": "IG",  "name": "Instagram", "url": "https://www.instagram.com/homasim.dev/"},
	{"label": "TIP", "name": "Tipeee",    "url": "https://www.tipeeestream.com/angelus2010/donation"},
	{"label": "KO",  "name": "Ko-fi",     "url": "https://ko-fi.com/angelus2010"},
]

var _scroll_content: VBoxContainer
var _content_height: float
var _scrolling: bool = false
var _font_outfit: FontFile
var _font_inter:  FontFile


func _ready() -> void:
	_font_outfit = load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	_font_inter  = load("res://assets/fonts/Inter_18pt-Regular.ttf") as FontFile
	_build_left_panel()
	_build_divider_line()
	_build_right_area()
	_start_scroll.call_deferred()


func _start_scroll() -> void:
	_content_height = _scroll_content.get_combined_minimum_size().y
	_scroll_content.position = Vector2((RIGHT_W - CONTENT_W) / 2.0, SCREEN_H)
	_scrolling = true


func _process(delta: float) -> void:
	if not _scrolling:
		return
	_scroll_content.position.y -= SCROLL_SPEED * delta
	if _scroll_content.position.y + _content_height < 0:
		_scroll_content.position.y = SCREEN_H


# ─── Linkes Panel (fixiert) ────────────────────────────────────────────────

func _build_left_panel() -> void:
	var panel := Control.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(LEFT_W, SCREEN_H)
	add_child(panel)

	# Logo
	var logo_tex := load("res://assets/images/logo.png") as Texture2D
	if logo_tex:
		var logo := TextureRect.new()
		logo.texture = logo_tex
		logo.position = Vector2(80, 110)
		logo.size = Vector2(LEFT_W - 160, 100)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(logo)

	# "Folg uns" Label
	var follow_lbl := Label.new()
	follow_lbl.text = "FOLG UNS"
	follow_lbl.position = Vector2(0, 270)
	follow_lbl.size = Vector2(LEFT_W, 20)
	follow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	follow_lbl.add_theme_font_size_override("font_size", 11)
	follow_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 0.55))
	if _font_outfit:
		follow_lbl.add_theme_font_override("font", _font_outfit)
	panel.add_child(follow_lbl)

	# Social Buttons (Reihe 1: YT DC IG | Reihe 2: TIP KO)
	_build_social_buttons(panel, 302)

	# Zurück-Button
	var btn_back := _make_button(
		GameState.T("credits.btn.back"),
		Vector2(80, SCREEN_H - 108),
		Vector2(LEFT_W - 160, 52),
		Color(0.863, 0.149, 0.149, 1),
		Color(0.980, 0.220, 0.220, 1)
	)
	btn_back.pressed.connect(_on_back_pressed)
	panel.add_child(btn_back)


func _build_social_buttons(parent: Control, start_y: int) -> void:
	const BTN := 52
	const GAP := 14

	# Reihe 1: YT, DC, IG
	var row1: Array = [SOCIAL_LINKS[0], SOCIAL_LINKS[1], SOCIAL_LINKS[2]]
	var w1 := row1.size() * BTN + (row1.size() - 1) * GAP
	var x1 := (LEFT_W - w1) / 2
	for i in row1.size():
		var btn := _make_social_btn(row1[i], BTN)
		btn.position = Vector2(x1 + i * (BTN + GAP), start_y)
		parent.add_child(btn)

	# Reihe 2: TIP, KO
	var row2: Array = [SOCIAL_LINKS[3], SOCIAL_LINKS[4]]
	var w2 := row2.size() * BTN + (row2.size() - 1) * GAP
	var x2 := (LEFT_W - w2) / 2
	for i in row2.size():
		var btn := _make_social_btn(row2[i], BTN)
		btn.position = Vector2(x2 + i * (BTN + GAP), start_y + BTN + GAP)
		parent.add_child(btn)


func _make_social_btn(social: Dictionary, size: int) -> Button:
	var btn := Button.new()
	btn.text = social["label"]
	btn.tooltip_text = social["name"]
	btn.size = Vector2(size, size)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", GOLD)
	if _font_outfit:
		btn.add_theme_font_override("font", _font_outfit)

	var r := size / 2
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 1)
	sb.corner_radius_top_left    = r
	sb.corner_radius_top_right   = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_color = Color(0.918, 0.702, 0.031, 0.45)

	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.border_color = GOLD
	sb_hover.bg_color = Color(0.15, 0.18, 0.26, 1)

	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())

	var url: String = social["url"]
	btn.pressed.connect(func(): OS.shell_open(url))
	return btn


# ─── Trennlinie ────────────────────────────────────────────────────────────

func _build_divider_line() -> void:
	var line := Panel.new()
	line.position = Vector2(LEFT_W, 0)
	line.size = Vector2(1, SCREEN_H)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.918, 0.702, 0.031, 0.22)
	line.add_theme_stylebox_override("panel", sb)
	add_child(line)


# ─── Rechter Scroll-Bereich ────────────────────────────────────────────────

func _build_right_area() -> void:
	var clip := Control.new()
	clip.position = Vector2(LEFT_W, 0)
	clip.size = Vector2(RIGHT_W, SCREEN_H)
	clip.clip_contents = true
	add_child(clip)

	_scroll_content = VBoxContainer.new()
	_scroll_content.custom_minimum_size = Vector2(CONTENT_W, 0)
	_scroll_content.add_theme_constant_override("separation", 0)
	clip.add_child(_scroll_content)

	_build_scroll_content()


func _build_scroll_content() -> void:
	_add_scroll_intro()

	var raw := FileAccess.get_file_as_string("res://assets/credits.txt")
	if raw.is_empty():
		_add_error_label("credits.txt nicht gefunden!")
		_add_scroll_outro()
		return

	for line in raw.split("\n"):
		var l := line.strip_edges()
		if l.begins_with("## "):
			_add_section_header(l.substr(3))
		elif l.begins_with("= "):
			_add_name_label(l.substr(2))
		elif l.is_empty():
			_add_spacer(16)
		else:
			_add_detail_label(l)

	_add_scroll_outro()


# ─── Scroll-Inhalt Bausteine ───────────────────────────────────────────────

func _add_scroll_intro() -> void:
	_add_spacer(60)

	var title := Label.new()
	title.text = GameState.T("game.textlogo")
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		title.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(title)

	var version := FileAccess.get_file_as_string("res://version.txt").strip_edges()
	var ver_lbl := Label.new()
	ver_lbl.text = version if not version.is_empty() else "gd-0.1.x"
	ver_lbl.add_theme_font_size_override("font_size", 14)
	ver_lbl.add_theme_color_override("font_color", GREY)
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver_lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_inter:
		ver_lbl.add_theme_font_override("font", _font_inter)
	_scroll_content.add_child(ver_lbl)

	_add_spacer(12)

	var copy_lbl := Label.new()
	copy_lbl.text = "© 2026 Peter Engels"
	copy_lbl.add_theme_font_size_override("font_size", 13)
	copy_lbl.add_theme_color_override("font_color", GREY)
	copy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	copy_lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_inter:
		copy_lbl.add_theme_font_override("font", _font_inter)
	_scroll_content.add_child(copy_lbl)

	_add_spacer(60)
	_add_hr()
	_add_spacer(60)


func _add_scroll_outro() -> void:
	_add_spacer(80)
	_add_hr()
	_add_spacer(60)

	var lbl := Label.new()
	lbl.text = "Danke fürs Spielen!  ♥"
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		lbl.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(lbl)

	_add_spacer(200)


func _add_section_header(text: String) -> void:
	_add_spacer(40)
	var lbl := Label.new()
	lbl.text = text.to_upper()
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", GOLD)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		lbl.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(lbl)
	_add_spacer(16)


func _add_name_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.add_theme_color_override("font_color", WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		lbl.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(lbl)


func _add_detail_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", GREY)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_inter:
		lbl.add_theme_font_override("font", _font_inter)
	_scroll_content.add_child(lbl)


func _add_error_label(msg: String) -> void:
	var lbl := Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	_scroll_content.add_child(lbl)


func _add_hr() -> void:
	var center := CenterContainer.new()
	center.custom_minimum_size = Vector2(CONTENT_W, 0)
	var line := Panel.new()
	line.custom_minimum_size = Vector2(CONTENT_W - 200, 1)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.918, 0.702, 0.031, 0.22)
	line.add_theme_stylebox_override("panel", sb)
	center.add_child(line)
	_scroll_content.add_child(center)


func _add_spacer(h: int) -> void:
	var s := Control.new()
	s.custom_minimum_size = Vector2(CONTENT_W, h)
	_scroll_content.add_child(s)


# ─── Hilfsfunktionen ──────────────────────────────────────────────────────

func _make_button(label: String, pos: Vector2, min_size: Vector2, col: Color, col_hover: Color) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.position = pos
	btn.custom_minimum_size = min_size
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", WHITE)
	btn.focus_mode = Control.FOCUS_NONE
	if _font_outfit:
		btn.add_theme_font_override("font", _font_outfit)
	for sn: String in ["normal", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.corner_radius_top_left    = 6
		sb.corner_radius_top_right   = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.content_margin_left   = 24.0
		sb.content_margin_right  = 24.0
		sb.content_margin_top    = 14.0
		sb.content_margin_bottom = 14.0
		btn.add_theme_stylebox_override(sn, sb)
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = col_hover
	sb_hover.corner_radius_top_left    = 6
	sb_hover.corner_radius_top_right   = 6
	sb_hover.corner_radius_bottom_left = 6
	sb_hover.corner_radius_bottom_right = 6
	sb_hover.content_margin_left   = 24.0
	sb_hover.content_margin_right  = 24.0
	sb_hover.content_margin_top    = 14.0
	sb_hover.content_margin_bottom = 14.0
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
