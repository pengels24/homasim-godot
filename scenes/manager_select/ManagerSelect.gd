extends Control
## ANG-172 – Manager-Auswahl: bis zu 3 lokale Spielerprofile.
## Belegter Slot: Name + Hotel-Anzahl + Auswählen.
## Leerer Slot: Neu erstellen → CharacterEdit → Dashboard.

const MAX_SLOTS := 3


func _ready() -> void:
	_build_ui()


# ── UI-Aufbau ─────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.06, 0.10, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 48)
	center.add_child(vbox)

	var title := Label.new()
	title.text                 = GameState.T("manager_select.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031))
	vbox.add_child(title)

	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 32)
	vbox.add_child(slots_row)

	var profiles: Array = SaveManager.get_profiles()
	for i in MAX_SLOTS:
		var profile: Dictionary = profiles[i] if i < profiles.size() else {}
		slots_row.add_child(_make_slot(profile))

	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	var btn_back := Button.new()
	btn_back.text = GameState.T("menu.btn.back")
	btn_back.custom_minimum_size = Vector2(240, 52)
	btn_back.add_theme_font_size_override("font_size", 18)
	btn_back.add_theme_color_override("font_color", Color(0.96, 0.96, 0.96))
	_apply_btn_style(btn_back, Color(0.55, 0.10, 0.10), Color(0.75, 0.15, 0.15))
	btn_back.pressed.connect(_on_back_pressed)
	btn_row.add_child(btn_back)


func _make_slot(profile: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 340)

	var sb := StyleBoxFlat.new()
	sb.corner_radius_top_left     = 12
	sb.corner_radius_top_right    = 12
	sb.corner_radius_bottom_left  = 12
	sb.corner_radius_bottom_right = 12
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.content_margin_left        = 28.0
	sb.content_margin_right       = 28.0
	sb.content_margin_top         = 36.0
	sb.content_margin_bottom      = 36.0
	if profile.is_empty():
		sb.bg_color    = Color(0.06, 0.08, 0.13, 1.0)
		sb.border_color = Color(0.22, 0.26, 0.36, 0.70)
	else:
		sb.bg_color    = Color(0.08, 0.11, 0.18, 1.0)
		sb.border_color = Color(0.918, 0.702, 0.031, 0.30)
	card.add_theme_stylebox_override("panel", sb)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	card.add_child(vbox)

	if profile.is_empty():
		_build_empty_slot(vbox)
	else:
		_build_filled_slot(vbox, profile)

	return card


func _build_empty_slot(vbox: VBoxContainer) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var plus := Label.new()
	plus.text                 = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_font_size_override("font_size", 56)
	plus.add_theme_color_override("font_color", Color(0.30, 0.36, 0.48))
	vbox.add_child(plus)

	var hint := Label.new()
	hint.text                 = GameState.T("manager_select.empty_slot")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(0.40, 0.46, 0.58))
	vbox.add_child(hint)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	var btn := Button.new()
	btn.text = GameState.T("manager_select.btn.create")
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	_apply_btn_style(btn, Color(0.12, 0.16, 0.26), Color(0.18, 0.24, 0.38))
	btn.pressed.connect(_on_create_slot)
	vbox.add_child(btn)


func _build_filled_slot(vbox: VBoxContainer, profile: Dictionary) -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var name_lbl := Label.new()
	name_lbl.text                 = profile.get("name", "?")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	vbox.add_child(name_lbl)

	var role_lbl := Label.new()
	role_lbl.text                 = "MANAGER · LEVEL 1"
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_lbl.add_theme_font_size_override("font_size", 13)
	role_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 0.80))
	vbox.add_child(role_lbl)

	var profile_id: int    = profile.get("id", -1)
	var hotel_count: int   = SaveManager.get_hotels(profile_id).size()
	var hotels_lbl         := Label.new()
	hotels_lbl.text                 = "%d Hotel%s" % [hotel_count, "s" if hotel_count != 1 else ""]
	hotels_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotels_lbl.add_theme_font_size_override("font_size", 15)
	hotels_lbl.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	vbox.add_child(hotels_lbl)

	var spacer2 := Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer2)

	var btn := Button.new()
	btn.text = GameState.T("manager_select.btn.select")
	btn.custom_minimum_size = Vector2(0, 48)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.08, 0.06, 0.01))
	_apply_btn_style(btn, Color(0.918, 0.702, 0.031), Color(0.97, 0.80, 0.15))
	btn.pressed.connect(_on_select.bind(profile))
	vbox.add_child(btn)


# ── Handler ───────────────────────────────────────────────────────────────────

func _on_select(profile: Dictionary) -> void:
	GameState.select_profile(profile)
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _on_create_slot() -> void:
	get_tree().change_scene_to_file("res://scenes/character/CharacterEdit.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# ── Hilfsfunktionen ───────────────────────────────────────────────────────────

func _apply_btn_style(btn: Button, normal: Color, hover: Color) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = normal
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left        = 20.0
	s.content_margin_right       = 20.0
	s.content_margin_top         = 10.0
	s.content_margin_bottom      = 10.0
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = hover
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
