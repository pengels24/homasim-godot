extends Control

# ANG-150 – Credits Scroll-Abspann
# Inhalt: res://assets/credits.txt – editierbar ohne Code-Änderung

const SCROLL_SPEED := 55.0  # px/s

const BG_IMAGES := [
	"res://assets/images/home/home-background-001.png",
	"res://assets/images/home/home-background-002.png",
	"res://assets/images/home/home-background-003.png",
]
const SLIDE_INTERVAL := 5.0
const FADE_DURATION  := 1.2

const GOLD  := Color(0.918, 0.702, 0.031, 1)
const WHITE := Color(0.98, 0.98, 0.98, 1)
const GREY  := Color(0.55, 0.55, 0.55, 1)
const BG    := Color(0.059, 0.090, 0.165, 1)

const LEFT_W   := 640
const RIGHT_W  := 1280
const SCREEN_H := 1080
const CONTENT_W := 860

const SOCIAL_LINKS: Array = [
	{"label": "YT",  "name": "YouTube",   "url": "https://www.youtube.com/@Angelus2010",              "icon_path": "res://assets/icons/ic_youtube.png"},
	{"label": "DC",  "name": "Discord",   "url": "https://discord.gg/hYSvUqmhcw",                     "icon_path": "res://assets/icons/ic_discord.png"},
	{"label": "IG",  "name": "Instagram", "url": "https://www.instagram.com/homasim.dev/",            "icon_path": "res://assets/icons/ic_instagram.png"},
	{"label": "TIP", "name": "Tipeee",    "url": "https://www.tipeeestream.com/angelus2010/donation", "icon_path": "res://assets/icons/ic_tipeee.png"},
	{"label": "KO",  "name": "Ko-fi",     "url": "https://ko-fi.com/angelus2010",                     "icon_path": "res://assets/icons/ic_kofi.png"},
]

var _scroll_content: VBoxContainer
var _content_height: float
var _scrolling: bool = false
var _font_outfit: FontFile
var _font_inter:  FontFile
var _music_player: AudioStreamPlayer
var _audio_btn: Button
var _bg_nodes: Array = []
var _current_bg := 0
var _slide_timer := 0.0


func _ready() -> void:
	_font_outfit = load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	_font_inter  = load("res://assets/fonts/Inter_18pt-Regular.ttf") as FontFile
	_build_background()
	_build_left_panel()
	_build_divider_line()
	_build_right_area()
	_add_scroll_fade(0.0, true)
	_add_scroll_fade(SCREEN_H - 100.0, false)
	_start_scroll.call_deferred()
	_start_music()


func _process(delta: float) -> void:
	if _scrolling:
		_scroll_content.position.y -= SCROLL_SPEED * delta
		if _scroll_content.position.y + _content_height < 0:
			_scroll_content.position.y = SCREEN_H

	_slide_timer += delta
	if _slide_timer >= SLIDE_INTERVAL:
		_slide_timer = 0.0
		_next_slide()


func _start_scroll() -> void:
	_content_height = _scroll_content.get_combined_minimum_size().y
	_scroll_content.position = Vector2((RIGHT_W - CONTENT_W) / 2.0, SCREEN_H)
	_scrolling = true


# ─── Hintergrund-Slideshow ────────────────────────────────────────────────

func _build_background() -> void:
	for i in BG_IMAGES.size():
		var tr := TextureRect.new()
		tr.position = Vector2.ZERO
		tr.size = Vector2(1920, 1080)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		var tex := load(BG_IMAGES[i]) as Texture2D
		if tex:
			tr.texture = tex
		tr.modulate.a = 1.0 if i == 0 else 0.0
		add_child(tr)
		_bg_nodes.append(tr)
	var overlay := ColorRect.new()
	overlay.position = Vector2.ZERO
	overlay.size = Vector2(1920, 1080)
	overlay.color = Color(0, 0, 0, 0.68)
	add_child(overlay)
	# Linkes Drittel extra abdunkeln
	var left_dark := ColorRect.new()
	left_dark.position = Vector2.ZERO
	left_dark.size = Vector2(LEFT_W, SCREEN_H)
	left_dark.color = Color(0, 0, 0, 0.58)
	add_child(left_dark)


func _next_slide() -> void:
	var next := (_current_bg + 1) % _bg_nodes.size()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_bg_nodes[next], "modulate:a", 1.0, FADE_DURATION)
	tw.tween_property(_bg_nodes[_current_bg], "modulate:a", 0.0, FADE_DURATION)
	_current_bg = next


# ─── Linkes Panel (fixiert) ────────────────────────────────────────────────

func _build_left_panel() -> void:
	var panel := Control.new()
	panel.position = Vector2.ZERO
	panel.size = Vector2(LEFT_W, SCREEN_H)
	add_child(panel)

	# Logo (80px Höhe)
	var logo_tex := load("res://assets/images/logo-transparent-80.png") as Texture2D
	if not logo_tex:
		logo_tex = load("res://assets/images/logo-transparent-50.png") as Texture2D
	if logo_tex:
		var logo := TextureRect.new()
		logo.texture = logo_tex
		logo.position = Vector2(40, 60)
		logo.size = Vector2(LEFT_W - 80, 80)
		logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		panel.add_child(logo)

	# Social-Block vertikal zentriert zwischen Logo-Unterkante und Zurück-Button
	# Logo bottom ≈ 140, back button top = SCREEN_H-88=992 → mitte bei 566
	# Block: label(20) + gap(22) + 5×62-10=300 = 342px → start bei 566-171=395
	var follow_lbl := Label.new()
	follow_lbl.text = "FOLG UNS"
	follow_lbl.position = Vector2(0, 395)
	follow_lbl.size = Vector2(LEFT_W, 20)
	follow_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	follow_lbl.add_theme_font_size_override("font_size", 15)
	follow_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 0.55))
	if _font_outfit:
		follow_lbl.add_theme_font_override("font", _font_outfit)
	panel.add_child(follow_lbl)

	# Social Buttons (Zickzack-Spalte)
	_build_social_buttons(panel, 425)

	# Zurück-Button (content-sized, zentriert)
	var btn_back := _make_button(
		GameState.T("credits.btn.back"),
		Vector2(0, SCREEN_H - 88),
		Vector2(0, 44),
		Color(0.863, 0.149, 0.149, 1),
		Color(0.980, 0.220, 0.220, 1)
	)
	btn_back.pressed.connect(_on_back_pressed)
	panel.add_child(btn_back)

	# Audio-Button rechts neben Zurück
	_audio_btn = _make_audio_btn()
	_audio_btn.position = Vector2(0, SCREEN_H - 88 + 4)
	panel.add_child(_audio_btn)
	(func():
		btn_back.position.x = (LEFT_W - btn_back.size.x - 48) / 2.0
		_audio_btn.position.x = btn_back.position.x + btn_back.size.x + 12
	).call_deferred()

	_animate_entrance(panel)


func _build_social_buttons(parent: Control, start_y: int) -> void:
	const BTN    := 52
	const Y_STEP := 62
	# Zwei x-Positionen für Zickzack, zentriert in LEFT_W
	var x_left  := (LEFT_W / 2) - BTN - 8
	var x_right := (LEFT_W / 2) + 8
	var xs := [x_left, x_right, x_left, x_right, x_left]
	for i in SOCIAL_LINKS.size():
		var btn := _make_social_btn(SOCIAL_LINKS[i], BTN)
		btn.position = Vector2(xs[i], start_y + i * Y_STEP)
		parent.add_child(btn)


func _make_social_btn(social: Dictionary, size: int) -> Button:
	var btn := Button.new()
	btn.tooltip_text = social["name"]
	btn.size = Vector2(size, size)
	btn.focus_mode = Control.FOCUS_NONE

	var r := 10
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

	var icon_path: String = social.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		btn.text = ""
		var cc := CenterContainer.new()
		cc.set_anchor(SIDE_RIGHT, 1)
		cc.set_anchor(SIDE_BOTTOM, 1)
		cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var icon := TextureRect.new()
		icon.texture = load(icon_path)
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cc.add_child(icon)
		btn.add_child(cc)
	else:
		btn.text = social["label"]
		btn.add_theme_font_size_override("font_size", 12)
		btn.add_theme_color_override("font_color", GOLD)
		if _font_outfit:
			btn.add_theme_font_override("font", _font_outfit)

	var url: String = social["url"]
	btn.pressed.connect(func(): OS.shell_open(url))
	return btn


func _make_audio_btn() -> Button:
	var btn := Button.new()
	btn.text = "■"
	btn.size = Vector2(36, 36)
	btn.focus_mode = Control.FOCUS_NONE
	btn.tooltip_text = "Musik an/aus"
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", GOLD)
	if _font_outfit:
		btn.add_theme_font_override("font", _font_outfit)
	var r := 18
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.12, 0.18, 0.7)
	sb.corner_radius_top_left    = r
	sb.corner_radius_top_right   = r
	sb.corner_radius_bottom_left = r
	sb.corner_radius_bottom_right = r
	sb.border_width_top    = 1; sb.border_width_bottom = 1
	sb.border_width_left   = 1; sb.border_width_right  = 1
	sb.border_color = Color(0.918, 0.702, 0.031, 0.3)
	var sb_hover := sb.duplicate() as StyleBoxFlat
	sb_hover.border_color = GOLD
	btn.add_theme_stylebox_override("normal",  sb)
	btn.add_theme_stylebox_override("hover",   sb_hover)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus",   StyleBoxEmpty.new())
	btn.pressed.connect(_toggle_music)
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
	# Schlagschatten nach rechts
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.55))
	g.set_color(1, Color(0, 0, 0, 0.0))
	var grad := GradientTexture2D.new()
	grad.gradient = g
	var shadow := TextureRect.new()
	shadow.texture = grad
	shadow.position = Vector2(LEFT_W + 1, 0)
	shadow.size = Vector2(40, SCREEN_H)
	shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	shadow.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(shadow)


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
	title.add_theme_font_size_override("font_size", 42)
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		title.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(title)

	var version := FileAccess.get_file_as_string("res://version.txt").strip_edges()
	var ver_lbl := Label.new()
	ver_lbl.text = version if not version.is_empty() else "gd-0.1.x"
	ver_lbl.add_theme_font_size_override("font_size", 19)
	ver_lbl.add_theme_color_override("font_color", GREY)
	ver_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver_lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_inter:
		ver_lbl.add_theme_font_override("font", _font_inter)
	_scroll_content.add_child(ver_lbl)

	_add_spacer(12)

	var copy_lbl := Label.new()
	copy_lbl.text = "© 2026 Peter Engels"
	copy_lbl.add_theme_font_size_override("font_size", 17)
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
	lbl.add_theme_font_size_override("font_size", 36)
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
	lbl.add_theme_font_size_override("font_size", 15)
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
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(CONTENT_W, 0)
	if _font_outfit:
		lbl.add_theme_font_override("font", _font_outfit)
	_scroll_content.add_child(lbl)


func _add_detail_label(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 18)
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


# ─── Scroll-Gradient-Fades ────────────────────────────────────────────────

func _add_scroll_fade(pos_y: float, top_to_bottom: bool) -> void:
	var g := Gradient.new()
	if top_to_bottom:
		g.set_color(0, Color(0, 0, 0, 0.85))
		g.set_color(1, Color(0, 0, 0, 0.0))
	else:
		g.set_color(0, Color(0, 0, 0, 0.0))
		g.set_color(1, Color(0, 0, 0, 0.85))
	var grad := GradientTexture2D.new()
	grad.gradient = g
	var fade := TextureRect.new()
	fade.texture = grad
	fade.position = Vector2(LEFT_W, pos_y)
	fade.size = Vector2(RIGHT_W, 100)
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	add_child(fade)


# ─── Eingangs-Animation ───────────────────────────────────────────────────

func _animate_entrance(panel: Control) -> void:
	panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(panel, "modulate:a", 1.0, 0.8)


# ─── Musik ────────────────────────────────────────────────────────────────

func _start_music() -> void:
	const PATHS := [
		"res://assets/audio/credits_music.ogg",
		"res://assets/audio/credits_music.mp3",
		"res://assets/audio/credits_music.wav",
	]
	for path in PATHS:
		if ResourceLoader.exists(path):
			_music_player = AudioStreamPlayer.new()
			_music_player.stream = load(path)
			_music_player.bus = "Music"
			_music_player.volume_db = -6.0
			add_child(_music_player)
			_music_player.play()
			return


func _toggle_music() -> void:
	if not is_instance_valid(_music_player):
		return
	if _music_player.playing:
		_music_player.stop()
		_audio_btn.text = "▶"
		_audio_btn.add_theme_color_override("font_color", GREY)
	else:
		_music_player.play()
		_audio_btn.text = "■"
		_audio_btn.add_theme_color_override("font_color", GOLD)


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
		sb.content_margin_top    = 12.0
		sb.content_margin_bottom = 12.0
		btn.add_theme_stylebox_override(sn, sb)
	var sb_hover := StyleBoxFlat.new()
	sb_hover.bg_color = col_hover
	sb_hover.corner_radius_top_left    = 6
	sb_hover.corner_radius_top_right   = 6
	sb_hover.corner_radius_bottom_left = 6
	sb_hover.corner_radius_bottom_right = 6
	sb_hover.content_margin_left   = 24.0
	sb_hover.content_margin_right  = 24.0
	sb_hover.content_margin_top    = 12.0
	sb_hover.content_margin_bottom = 12.0
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	return btn


func _on_back_pressed() -> void:
	if is_instance_valid(_music_player):
		_music_player.stop()
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
