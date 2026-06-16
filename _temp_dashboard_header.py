import os
import re

path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add visible = false to root
if 'visible = false' not in text.split('[node name="Bg"')[0]:
    text = re.sub(r'(\[node name="Dashboard" type="Control"\]\n)', r'\1visible = false\n', text)

# 2. Add ExtResources for buttons
ext_resources = []
if 'menu_button_red.tres' not in text:
    ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red.tres" id="red_normal"]')
if 'menu_button_red_hover.tres' not in text:
    ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red_hover.tres" id="red_hover"]')
if 'menu_button_red_pressed.tres' not in text:
    ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red_pressed.tres" id="red_pressed"]')

if ext_resources:
    # insert after the last ext_resource
    last_ext_idx = text.rfind('[ext_resource')
    if last_ext_idx != -1:
        end_idx = text.find('\n', last_ext_idx)
        text = text[:end_idx+1] + '\n'.join(ext_resources) + '\n' + text[end_idx+1:]

# 3. Modify TitleLabel
title_regex = r'(\[node name="TitleLabel" type="Label" parent="Center/Card/VBox/Header"\]\nlayout_mode = 2\nsize_flags_horizontal = 3\nsize_flags_vertical = 4\n)theme_override_font_sizes/font_size = 40\ntheme_override_colors/font_color = Color\(0.98, 0.98, 0.98, 1\)'
new_title = r'\1theme_override_colors/font_color = Color(0.8901961, 0.68235296, 0.03137255, 1)\ntheme_override_colors/font_shadow_color = Color(0, 0, 0, 0.5882353)\ntheme_override_font_sizes/font_size = 32'
text = re.sub(title_regex, new_title, text)

# 4. Modify Close Button
btn_regex = r'(\[node name="BtnCloseModal" type="Button" parent="Center/Card/VBox/Header"\]\ncustom_minimum_size = Vector2\(44, 44\)\nlayout_mode = 2\n)theme_override_styles/normal = ExtResource\("5_red"\)\ntheme_override_styles/hover = ExtResource\("5_red"\)\ntheme_override_styles/pressed = ExtResource\("5_red"\)'
new_btn = r'\1theme_override_styles/normal = ExtResource("red_normal")\ntheme_override_styles/hover = ExtResource("red_hover")\ntheme_override_styles/pressed = ExtResource("red_pressed")'
text = re.sub(btn_regex, new_btn, text)

# 5. Add Separator below Header
sep_style = """[sub_resource type="StyleBoxLine" id="StyleBoxLine_3uw2v"]
content_margin_left = 4.0
content_margin_top = 0.0
content_margin_right = 4.0
content_margin_bottom = 0.0
color = Color(0.8901961, 0.68235296, 0.03137255, 1)

"""

if 'StyleBoxLine_3uw2v' not in text:
    text = re.sub(r'(\[node name="Dashboard" type="Control"\])', sep_style + r'\1', text)

sep_node = """
[node name="HSeparator" type="HSeparator" parent="Center/Card/VBox"]
layout_mode = 2
theme_override_styles/separator = SubResource("StyleBoxLine_3uw2v")
"""
if '[node name="HSeparator" type="HSeparator" parent="Center/Card/VBox"]' not in text:
    text = text.replace('[node name="MainArea" type="HBoxContainer" parent="Center/Card/VBox"]', sep_node[1:] + '\n[node name="MainArea" type="HBoxContainer" parent="Center/Card/VBox"]')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Dashboard header updated and visibility fixed.")
