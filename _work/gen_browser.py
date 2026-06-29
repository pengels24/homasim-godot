import os

# --- SimBrowserTile.tscn ---
tile_tscn = """[gd_scene load_steps=3 format=3 uid="uid://tile_sim_123"]

[ext_resource type="Script" path="res://scenes/ingame/SimBrowserTile.gd" id="1_script"]
[ext_resource type="StyleBox" uid="uid://dhmvve3jymdnl" path="res://scenes/shared/styles/PanelInnerDark.tres" id="2_style"]

[node name="SimBrowserTile" type="Button"]
custom_minimum_size = Vector2(350, 150)
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
size_flags_horizontal = 3
size_flags_vertical = 3
mouse_default_cursor_shape = 2
theme_override_styles/normal = ExtResource("2_style")
theme_override_styles/hover = ExtResource("2_style")
theme_override_styles/pressed = ExtResource("2_style")
theme_override_styles/focus = ExtResource("2_style")
script = ExtResource("1_script")

[node name="Margin" type="MarginContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 20
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 20
mouse_filter = 2

[node name="HBox" type="HBoxContainer" parent="Margin"]
layout_mode = 2
theme_override_constants/separation = 20
mouse_filter = 2

[node name="ColorIcon" type="ColorRect" parent="Margin/HBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(80, 80)
layout_mode = 2
size_flags_vertical = 4
mouse_filter = 2
color = Color(0.180392, 0.478431, 0.819608, 1)

[node name="LblAbbr" type="Label" parent="Margin/HBox/ColorIcon"]
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

[node name="VBox" type="VBoxContainer" parent="Margin/HBox"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
theme_override_constants/separation = 5
mouse_filter = 2

[node name="LblTitle" type="Label" parent="Margin/HBox/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"HeaderLarge"
text = "HotelCheck"

[node name="LblDesc" type="Label" parent="Margin/HBox/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"DescLabelLarge"
text = "Bewertungsportal"
autowrap_mode = 3
"""

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.tscn', 'w', encoding='utf-8') as f:
    f.write(tile_tscn)

tile_gd = """extends Button
class_name SimBrowserTile

@onready var color_icon: ColorRect = %ColorIcon
@onready var lbl_abbr: Label = %LblAbbr
@onready var lbl_title: Label = %LblTitle
@onready var lbl_desc: Label = %LblDesc

var site_data: Dictionary = {}

func setup(data: Dictionary) -> void:
\tsite_data = data
\tlbl_abbr.text = data.get("abbr", "")
\tlbl_title.text = data.get("title", "")
\tlbl_desc.text = data.get("desc", "")
\t
\tvar col_str = data.get("color", "333333")
\tcolor_icon.color = Color(col_str)
"""

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.gd', 'w', encoding='utf-8') as f:
    f.write(tile_gd)

# --- SimBrowser.tscn ---
browser_tscn = """[gd_scene load_steps=3 format=3 uid="uid://bsim0br0wser1"]

[ext_resource type="Script" path="res://scenes/ingame/SimBrowser.gd" id="1_sim01"]
[ext_resource type="StyleBox" uid="uid://bgd80jndy5xnj" path="res://scenes/shared/styles/PanelModal.tres" id="2_modal"]

[node name="SimBrowser" type="CanvasLayer"]
layer = 80
visible = false
script = ExtResource("1_sim01")

[node name="Overlay" type="ColorRect" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0, 0, 0, 0.65)

[node name="Margin" type="MarginContainer" parent="."]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 60
theme_override_constants/margin_top = 60
theme_override_constants/margin_right = 60
theme_override_constants/margin_bottom = 60

[node name="Window" type="PanelContainer" parent="Margin"]
layout_mode = 2
theme_override_styles/panel = ExtResource("2_modal")

[node name="VBox" type="VBoxContainer" parent="Margin/Window"]
layout_mode = 2
theme_override_constants/separation = 0

[node name="NavBar" type="ColorRect" parent="Margin/Window/VBox"]
custom_minimum_size = Vector2(0, 70)
layout_mode = 2
color = Color(0.109804, 0.129412, 0.188235, 1)

[node name="Margin" type="MarginContainer" parent="Margin/Window/VBox/NavBar"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 20
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 20
theme_override_constants/margin_bottom = 10

[node name="HBox" type="HBoxContainer" parent="Margin/Window/VBox/NavBar/Margin"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="BtnBack" type="Button" parent="Margin/Window/VBox/NavBar/Margin/HBox"]
custom_minimum_size = Vector2(50, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "<"

[node name="BtnForward" type="Button" parent="Margin/Window/VBox/NavBar/Margin/HBox"]
custom_minimum_size = Vector2(50, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = ">"

[node name="BtnHome" type="Button" parent="Margin/Window/VBox/NavBar/Margin/HBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(50, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 24
text = "~"

[node name="AddressBar" type="LineEdit" parent="Margin/Window/VBox/NavBar/Margin/HBox"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 24
text = "home.sim"
editable = false

[node name="BtnClose" type="Button" parent="Margin/Window/VBox/NavBar/Margin/HBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(50, 0)
layout_mode = 2
theme_override_colors/font_color = Color(0.9, 0.2, 0.2, 1)
theme_override_font_sizes/font_size = 24
text = "X"

[node name="ContentBg" type="ColorRect" parent="Margin/Window/VBox"]
layout_mode = 2
size_flags_vertical = 3
color = Color(0.0705882, 0.0784314, 0.129412, 1)

[node name="Margin" type="MarginContainer" parent="Margin/Window/VBox/ContentBg"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 60
theme_override_constants/margin_top = 40
theme_override_constants/margin_right = 60
theme_override_constants/margin_bottom = 40

[node name="Scroll" type="ScrollContainer" parent="Margin/Window/VBox/ContentBg/Margin"]
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="Margin/Window/VBox/ContentBg/Margin/Scroll"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/separation = 40

[node name="HeaderBox" type="VBoxContainer" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox"]
layout_mode = 2

[node name="LblHome" type="Label" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox/HeaderBox"]
layout_mode = 2
theme_override_colors/font_color = Color(0.917647, 0.701961, 0.0313726, 1)
theme_override_font_sizes/font_size = 48
text = "home.sim"

[node name="LblSub" type="Label" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox/HeaderBox"]
layout_mode = 2
theme_type_variation = &"DescLabelLarge"
text = "Ihr persönlicher Simulations-Browser"

[node name="HSeparator" type="HSeparator" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox/HeaderBox"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="Grid" type="GridContainer" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_constants/h_separation = 30
theme_override_constants/v_separation = 30
columns = 3

[node name="LblTip" type="Label" parent="Margin/Window/VBox/ContentBg/Margin/Scroll/VBox"]
layout_mode = 2
theme_type_variation = &"DescLabelLarge"
text = "Tipp: Gib eine URL in die Adressleiste ein und drücke Enter."
horizontal_alignment = 1
"""

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.tscn', 'w', encoding='utf-8') as f:
    f.write(browser_tscn)

print("Scenes created.")
