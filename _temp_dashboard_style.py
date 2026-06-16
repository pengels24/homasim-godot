import os
import re

# 1. Update DashboardHotelCard.tscn
path1 = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(path1, 'r', encoding='utf-8') as f:
    text1 = f.read()

card_style = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_card"]
bg_color = Color(0.12, 0.12, 0.15, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.35, 0.35, 0.35, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
"""

text1 = text1.replace('theme_override_styles/panel = ExtResource("1_glow")', 'theme_override_styles/panel = SubResource("StyleBoxFlat_card")')
if 'StyleBoxFlat_card' not in text1.split('[node')[0]:
    text1 = re.sub(r'(\[node name="DashboardHotelCard" type="PanelContainer"\])', card_style + r'\n\1', text1)

with open(path1, 'w', encoding='utf-8') as f:
    f.write(text1)


# 2. Update Dashboard.tscn
path2 = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(path2, 'r', encoding='utf-8') as f:
    text2 = f.read()

if 'Center/Card/MainArea' not in text2:
    # Fix parents
    text2 = re.sub(r'parent="MainArea', 'parent="Center/Card/MainArea', text2)
    
    # Wrap MainArea
    center_wrap = """[node name="Center" type="CenterContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2

[node name="Card" type="PanelContainer" parent="Center"]
layout_mode = 2
theme_override_styles/panel = ExtResource("3_glow")

[node name="MainArea" type="HBoxContainer" parent="Center/Card"]"""

    text2 = text2.replace('[node name="MainArea" type="HBoxContainer" parent="Center/Card/."]', center_wrap)
    
    # Remove layout lines from old MainArea
    text2 = re.sub(r'\[node name="MainArea" type="HBoxContainer" parent="Center/Card"\]\nlayout_mode = 1\nanchors_preset = 15\nanchor_right = 1\.0\nanchor_bottom = 1\.0\ngrow_horizontal = 2\ngrow_vertical = 2', '[node name="MainArea" type="HBoxContainer" parent="Center/Card"]', text2)

    # Update NewHotelCard
    text2 = text2.replace('[node name="NewHotelCard" type="PanelContainer" parent="Center/Card/MainArea/HotelSection/Scroll/HotelContainer"]\nunique_name_in_owner = true\ncustom_minimum_size = Vector2(360, 420)\nlayout_mode = 2\ntheme_override_styles/panel = ExtResource("3_glow")',
                          '[node name="NewHotelCard" type="PanelContainer" parent="Center/Card/MainArea/HotelSection/Scroll/HotelContainer"]\nunique_name_in_owner = true\ncustom_minimum_size = Vector2(360, 420)\nlayout_mode = 2\ntheme_override_styles/panel = SubResource("StyleBoxFlat_card")')
                          
    if 'StyleBoxFlat_card' not in text2.split('[node')[0]:
        text2 = re.sub(r'(\[node name="Dashboard" type="Control"\])', card_style + r'\n\1', text2)

with open(path2, 'w', encoding='utf-8') as f:
    f.write(text2)

print("Styles and layouts updated!")
