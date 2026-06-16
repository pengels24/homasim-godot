import re

file_path = r'd:\game-dev\homasim-godot\scenes\character\CharacterEdit.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add ExtResources
ext_resources = """[ext_resource type="StyleBox" uid="uid://cg2q7w0wqska8" path="res://assets/UI/modal_panel_glow.tres" id="3_modal"]
[ext_resource type="StyleBox" uid="uid://cna2b35jrscs7" path="res://assets/UI/menu_button_darkblue.tres" id="4_blue"]
[ext_resource type="StyleBox" uid="uid://ctu17tayaclq4" path="res://assets/UI/menu_button_darkblue_hover.tres" id="5_blue_h"]
[ext_resource type="StyleBox" uid="uid://b0jlf6ry834tk" path="res://assets/UI/menu_button_darkblue_pressed.tres" id="6_blue_p"]
[ext_resource type="StyleBox" uid="uid://b75w4v5ow6m8j" path="res://assets/UI/menu_button_golden.tres" id="7_gold"]
[ext_resource type="StyleBox" uid="uid://0d8a1qfs35qv" path="res://assets/UI/menu_button_golden_hover.tres" id="8_gold_h"]
[ext_resource type="StyleBox" uid="uid://babqxaejnbxnp" path="res://assets/UI/menu_button_golden_pressed.tres" id="9_gold_p"]
[ext_resource type="StyleBox" uid="uid://cxh0s5seikuc5" path="res://assets/UI/menu_button_green.tres" id="10_green"]
[ext_resource type="StyleBox" uid="uid://b802q2dq055uh" path="res://assets/UI/menu_button_green_hover.tres" id="11_green_h"]
[ext_resource type="StyleBox" uid="uid://2rxcfg77t4wa" path="res://assets/UI/menu_button_green_pressed.tres" id="12_green_p"]
[ext_resource type="StyleBox" uid="uid://cth7xo3seiusw" path="res://assets/UI/menu_button_red.tres" id="13_red"]
[ext_resource type="StyleBox" uid="uid://dwal8kaocxhoh" path="res://assets/UI/menu_button_red_hover.tres" id="14_red_h"]
[ext_resource type="StyleBox" uid="uid://efh4spsvdija" path="res://assets/UI/menu_button_red_pressed.tres" id="15_red_p"]
[ext_resource type="Texture2D" uid="uid://dxxxxxxx" path="res://assets/images/icons/x.svg" id="16_x"]
"""

# Godot 4 requires ext_resources right after the initial gd_scene and other ext_resources.
# We'll inject them after the last ext_resource.
parts = content.split('\n\n', 1)
lines = parts[0].split('\n')
ext_lines = [l for l in lines if l.startswith('[ext_resource')]
other_lines = [l for l in lines if not l.startswith('[ext_resource')]

new_header = '\n'.join(other_lines) + '\n' + '\n'.join(ext_lines) + '\n' + ext_resources.strip()

# Replace Option Buttons
content = content.replace('SubResource("StyleBoxFlat_option")', 'ExtResource("4_blue")')
content = content.replace('SubResource("StyleBoxFlat_option_active")', 'ExtResource("7_gold")')

# Replace Save Button
content = content.replace('SubResource("StyleBoxFlat_green")', 'ExtResource("10_green")')
content = content.replace('SubResource("StyleBoxFlat_green_hover")', 'ExtResource("11_green_h")')
content = content.replace('SubResource("StyleBoxFlat_green_disabled")', 'ExtResource("10_green")')

# Replace Back Button styles
content = content.replace('SubResource("StyleBoxFlat_red")', 'ExtResource("13_red")')
content = content.replace('SubResource("StyleBoxFlat_red_hover")', 'ExtResource("14_red_h")')
content = content.replace('SubResource("StyleBoxFlat_red_pressed")', 'ExtResource("15_red_p")')

# Replace Card style
content = content.replace('SubResource("StyleBoxFlat_card")', 'ExtResource("3_modal")')

# Now restructure the Tree
# We need to wrap VBox inside MarginContainer and add Header.
# It's actually easier to just inject the nodes.

# Let's find:
# [node name="Card" type="PanelContainer" parent="Center"]
# layout_mode = 2
# custom_minimum_size = Vector2(800, 0)
# theme_override_styles/panel = ExtResource("3_modal")
#
# [node name="Margin" type="MarginContainer" parent="Center/Card"]
# layout_mode = 2
# theme_override_constants/margin_left = 32
# theme_override_constants/margin_top = 32
# theme_override_constants/margin_right = 32
# theme_override_constants/margin_bottom = 32
#
# [node name="VBox" type="VBoxContainer" parent="Center/Card/Margin"]

content = content.replace(
"""[node name="VBox" type="VBoxContainer" parent="Center/Card"]
layout_mode = 2
theme_override_constants/separation = 20""",
"""[node name="Margin" type="MarginContainer" parent="Center/Card"]
layout_mode = 2
theme_override_constants/margin_left = 32
theme_override_constants/margin_top = 32
theme_override_constants/margin_right = 32
theme_override_constants/margin_bottom = 32

[node name="VBox" type="VBoxContainer" parent="Center/Card/Margin"]
layout_mode = 2
theme_override_constants/separation = 20"""
)

# Rename all "Center/Card/VBox..." to "Center/Card/Margin/VBox..."
content = content.replace('parent="Center/Card/VBox', 'parent="Center/Card/Margin/VBox')

# Replace Title node with Header
old_title = """[node name="Title" type="Label" parent="Center/Card/Margin/VBox"]
layout_mode = 2
text = "Charakter erstellen"
theme_override_font_sizes/font_size = 28
theme_override_colors/font_color = Color(0.95, 0.95, 0.95, 1)
horizontal_alignment = 1"""

new_title = """[node name="Header" type="HBoxContainer" parent="Center/Card/Margin/VBox"]
layout_mode = 2

[node name="Title" type="Label" parent="Center/Card/Margin/VBox/Header"]
layout_mode = 2
size_flags_horizontal = 3
text = "Charakter erstellen"
theme_override_colors/font_color = Color(0.890196, 0.682353, 0.0313726, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.588235)
theme_override_font_sizes/font_size = 32

[node name="BtnBack" type="Button" parent="Center/Card/Margin/VBox/Header"]
layout_mode = 2
custom_minimum_size = Vector2(40, 40)
text = "X"
theme_override_styles/focus = SubResource("StyleBoxEmpty_link")
theme_override_styles/hover = ExtResource("14_red_h")
theme_override_styles/pressed = ExtResource("15_red_p")
theme_override_styles/normal = ExtResource("13_red")

[sub_resource type="StyleBoxLine" id="StyleBoxLine_goldsep"]
color = Color(0.890196, 0.682353, 0.0313726, 1)

[node name="HSeparator" type="HSeparator" parent="Center/Card/Margin/VBox"]
layout_mode = 2
theme_override_styles/separator = SubResource("StyleBoxLine_goldsep")"""

content = content.replace(old_title, new_title)

# Remove the old BtnBack
old_btnback = """[node name="BtnBack" type="Button" parent="Center/Card/Margin/VBox"]
layout_mode = 2
mouse_default_cursor_shape = 2
custom_minimum_size = Vector2(0, 44)
text = "Zurück"
theme_override_font_sizes/font_size = 15
theme_override_colors/font_color = Color(0.96, 0.96, 0.96, 1)
theme_override_styles/normal = ExtResource("13_red")
theme_override_styles/hover = ExtResource("14_red_h")
theme_override_styles/pressed = ExtResource("13_red")
theme_override_styles/focus = SubResource("StyleBoxEmpty_link")"""

content = content.replace(old_btnback, "")

# Write the final file
final_content = new_header + '\n\n' + parts[1]

# Apply to file
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content) # Wait, final_content is not quite right because the replacements were on content!
