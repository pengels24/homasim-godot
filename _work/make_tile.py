import os

tscn = """[gd_scene load_steps=5 format=3 uid="uid://tile_sim_123"]

[ext_resource type="Script" path="res://scenes/ingame/SimBrowserTile.gd" id="1_script"]

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_avatar"]
bg_color = Color(0.18, 0.48, 0.82, 1)
corner_radius_top_left = 50
corner_radius_top_right = 50
corner_radius_bottom_right = 50
corner_radius_bottom_left = 50

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_cta"]
bg_color = Color(0.1, 0.12, 0.15, 1)
border_width_top = 1
border_color = Color(0.2, 0.25, 0.3, 1)
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_card"]
bg_color = Color(0.12, 0.14, 0.18, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.2, 0.25, 0.3, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8

[node name="SimBrowserTile" type="Button"]
custom_minimum_size = Vector2(260, 360)
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_default_cursor_shape = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_card")
theme_override_styles/hover = SubResource("StyleBoxFlat_card")
theme_override_styles/pressed = SubResource("StyleBoxFlat_card")
theme_override_styles/disabled = SubResource("StyleBoxFlat_card")
script = ExtResource("1_script")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 0
mouse_filter = 2

[node name="ContentMargin" type="MarginContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 30
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 10
mouse_filter = 2

[node name="VBox" type="VBoxContainer" parent="VBox/ContentMargin"]
layout_mode = 2
theme_override_constants/separation = 15
mouse_filter = 2

[node name="CenterAvatar" type="CenterContainer" parent="VBox/ContentMargin/VBox"]
layout_mode = 2
mouse_filter = 2

[node name="AvatarPanel" type="Panel" parent="VBox/ContentMargin/VBox/CenterAvatar"]
unique_name_in_owner = true
custom_minimum_size = Vector2(100, 100)
layout_mode = 2
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_avatar")

[node name="LblAbbr" type="Label" parent="VBox/ContentMargin/VBox/CenterAvatar/AvatarPanel"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_type_variation = &"HeaderLarge"
text = "HC"
horizontal_alignment = 1
vertical_alignment = 1

[node name="VBoxText" type="VBoxContainer" parent="VBox/ContentMargin/VBox"]
layout_mode = 2
theme_override_constants/separation = 5
mouse_filter = 2

[node name="LblTitle" type="Label" parent="VBox/ContentMargin/VBox/VBoxText"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"HeaderLarge"
text = "HotelCheck"
horizontal_alignment = 1

[node name="LblDesc" type="Label" parent="VBox/ContentMargin/VBox/VBoxText"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.6, 0.65, 0.7, 1)
theme_override_font_sizes/font_size = 14
text = "Bewertungsportal"
horizontal_alignment = 1
autowrap_mode = 3

[node name="LblStatus" type="Label" parent="VBox/ContentMargin/VBox/VBoxText"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.2, 0.8, 0.3, 1)
theme_override_font_sizes/font_size = 14
text = "Verfügbar"
horizontal_alignment = 1

[node name="CTAPanel" type="PanelContainer" parent="VBox"]
layout_mode = 2
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_cta")

[node name="Margin" type="MarginContainer" parent="VBox/CTAPanel"]
layout_mode = 2
theme_override_constants/margin_top = 15
theme_override_constants/margin_bottom = 15
mouse_filter = 2

[node name="HBox" type="HBoxContainer" parent="VBox/CTAPanel/Margin"]
layout_mode = 2
alignment = 1
mouse_filter = 2
theme_override_constants/separation = 10

[node name="LblCTA" type="Label" parent="VBox/CTAPanel/Margin/HBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.9, 0.9, 0.9, 1)
theme_override_font_sizes/font_size = 16
text = "? App öffnen"
"""

gd = """extends Button
class_name SimBrowserTile

@onready var avatar_panel: Panel = %AvatarPanel
@onready var lbl_abbr: Label = %LblAbbr
@onready var lbl_title: Label = %LblTitle
@onready var lbl_desc: Label = %LblDesc
@onready var lbl_status: Label = %LblStatus
@onready var lbl_cta: Label = %LblCTA

var site_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	site_data = data
	lbl_abbr.text = data.get("abbr", "")
	lbl_title.text = GameState.T(data.get("title", ""))
	lbl_desc.text = GameState.T(data.get("desc", ""))
	
	var col_str = data.get("color", "333333")
	var style = avatar_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = Color(col_str)
	avatar_panel.add_theme_stylebox_override("panel", style)
	
	lbl_cta.text = "? " + data.get("url", "app.sim")
	
	# Hover effekt
	mouse_entered.connect(func():
		modulate = Color(1.2, 1.2, 1.2)
	)
	mouse_exited.connect(func():
		modulate = Color(1.0, 1.0, 1.0)
	)

func set_locked(locked: bool) -> void:
	disabled = locked
	if locked:
		lbl_status.text = "Gesperrt"
		lbl_status.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		lbl_cta.text = "Zugriff verweigert"
		modulate = Color(0.5, 0.5, 0.5)
	else:
		lbl_status.text = "Verfügbar"
		lbl_status.add_theme_color_override("font_color", Color(0.2, 0.8, 0.3))
		modulate = Color(1.0, 1.0, 1.0)
"""

with open("d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.tscn", "w", encoding="utf-8") as f:
    f.write(tscn)

with open("d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.gd", "w", encoding="utf-8") as f:
    f.write(gd)
