import os
import re

path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Change Bg from TextureRect to ColorRect
text = re.sub(r'\[node name="Bg" type="TextureRect" parent="."\]\nlayout_mode = 0\noffset_right = 1920.0\noffset_bottom = 1080.0\ntexture = ExtResource\("2_bg"\)\nmodulate = Color\(0.3, 0.3, 0.35, 1\)',
              '[node name="Bg" type="ColorRect" parent="."]\nlayout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2\ncolor = Color(0, 0, 0, 0.85)', text)

# Add ext_resource for red button if not exists
if 'menu_button_red_pressed.tres' not in text:
    # insert it after glow
    text = text.replace('res://assets/UI/modal_panel_glow.tres" id="3_glow"]', 'res://assets/UI/modal_panel_glow.tres" id="3_glow"]\n[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red_pressed.tres" id="5_red"]')

# Change BtnMainMenu to BtnCloseModal and style it
# Original:
# [node name="BtnMainMenu" type="Button" parent="MainArea/HotelSection/Header"]
# layout_mode = 2
# text = "Hauptmenü"

btn_pattern = r'\[node name="BtnMainMenu" type="Button" parent="MainArea/HotelSection/Header"\]\nlayout_mode = 2\ntext = "Hauptmenü"'
btn_replacement = '''[node name="BtnCloseModal" type="Button" parent="MainArea/HotelSection/Header"]
custom_minimum_size = Vector2(44, 44)
layout_mode = 2
theme_override_styles/normal = ExtResource("5_red")
theme_override_styles/hover = ExtResource("5_red")
theme_override_styles/pressed = ExtResource("5_red")
theme_override_font_sizes/font_size = 24
text = "X"
mouse_default_cursor_shape = 2'''

text = re.sub(btn_pattern, btn_replacement, text)

# Set top-level layout_mode and anchors for Dashboard
if 'layout_mode = 3' in text:
    text = text.replace('layout_mode = 3', 'layout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("Dashboard.tscn modified!")
