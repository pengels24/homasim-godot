import os
import re

path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace MainArea with VBox > Header and MainArea
mainarea_replacement = """[node name="VBox" type="VBoxContainer" parent="Center/Card"]
layout_mode = 2
theme_override_constants/separation = 20

[node name="Header" type="HBoxContainer" parent="Center/Card/VBox"]
layout_mode = 2
custom_minimum_size = Vector2(0, 50)
theme_override_constants/separation = 16

[node name="TitleLabel" type="Label" parent="Center/Card/VBox/Header"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 4
theme_override_font_sizes/font_size = 40
theme_override_colors/font_color = Color(0.98, 0.98, 0.98, 1)

[node name="BtnCloseModal" type="Button" parent="Center/Card/VBox/Header"]
custom_minimum_size = Vector2(44, 44)
layout_mode = 2
theme_override_styles/normal = ExtResource("5_red")
theme_override_styles/hover = ExtResource("5_red")
theme_override_styles/pressed = ExtResource("5_red")
theme_override_font_sizes/font_size = 24
text = "X"
mouse_default_cursor_shape = 2

[node name="MainArea" type="HBoxContainer" parent="Center/Card/VBox"]
layout_mode = 2
size_flags_vertical = 3"""

text = text.replace('[node name="MainArea" type="HBoxContainer" parent="Center/Card"]', mainarea_replacement)

# 2. Fix paths of children inside MainArea
text = text.replace('parent="Center/Card/MainArea"', 'parent="Center/Card/VBox/MainArea"')
text = text.replace('parent="Center/Card/MainArea/ManagerPanel', 'parent="Center/Card/VBox/MainArea/ManagerPanel')
text = text.replace('parent="Center/Card/MainArea/HotelSection', 'parent="Center/Card/VBox/MainArea/HotelSection')

# 3. Remove Header from HotelSection
header_regex = r'\[node name="Header" type="HBoxContainer" parent="Center/Card/VBox/MainArea/HotelSection"\].*?mouse_default_cursor_shape = 2\n\n'
text = re.sub(header_regex, '', text, flags=re.DOTALL)

# 4. Remove glow from ManagerPanel
text = text.replace('[node name="ManagerPanel" type="PanelContainer" parent="Center/Card/VBox/MainArea"]\nlayout_mode = 2\ntheme_override_styles/panel = ExtResource("3_glow")',
                    '[node name="ManagerPanel" type="PanelContainer" parent="Center/Card/VBox/MainArea"]\nlayout_mode = 2\ntheme_override_styles/panel = SubResource("StyleBoxFlat_card")')

# 5. Fix Dashboard Card StyleBox
# Use a custom modal style similar to SettingsModal so it has padding.
modal_style = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_dashboard_modal"]
content_margin_left = 40.0
content_margin_top = 40.0
content_margin_right = 40.0
content_margin_bottom = 40.0
bg_color = Color(0.07, 0.07, 0.09, 0.97)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.918, 0.702, 0.031, 0.4)
corner_radius_top_left = 16
corner_radius_top_right = 16
corner_radius_bottom_right = 16
corner_radius_bottom_left = 16
shadow_color = Color(0.918, 0.702, 0.031, 0.15)
shadow_size = 12
"""

if 'StyleBoxFlat_dashboard_modal' not in text:
    text = re.sub(r'(\[node name="Dashboard" type="Control"\])', modal_style + r'\n\1', text)

text = text.replace('theme_override_styles/panel = ExtResource("3_glow")', 'theme_override_styles/panel = SubResource("StyleBoxFlat_dashboard_modal")', 1)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

# Also update Dashboard.gd
gd_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.gd'
with open(gd_path, 'r', encoding='utf-8') as f:
    gd_text = f.read()

gd_text = gd_text.replace('$Center/Card/MainArea/ManagerPanel/PanelVBox/CharacterDisplay', '$Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/CharacterDisplay')
gd_text = gd_text.replace('$Center/Card/MainArea/ManagerPanel/PanelVBox/ManagerName', '$Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/ManagerName')
gd_text = gd_text.replace('$Center/Card/MainArea/ManagerPanel/PanelVBox/ManagerRole', '$Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/ManagerRole')
gd_text = gd_text.replace('$Center/Card/MainArea/ManagerPanel/PanelVBox/HotelCount', '$Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/HotelCount')

gd_text = gd_text.replace('$Center/Card/MainArea/HotelSection/Header/TitleLabel', '$Center/Card/VBox/Header/TitleLabel')
gd_text = gd_text.replace('$Center/Card/MainArea/HotelSection/Header/BtnCloseModal', '$Center/Card/VBox/Header/BtnCloseModal')

gd_text = gd_text.replace('$Center/Card/MainArea/HotelSection/StatusLabel', '$Center/Card/VBox/MainArea/HotelSection/StatusLabel')
gd_text = gd_text.replace('$Center/Card/MainArea/HotelSection/Scroll/HotelContainer', '$Center/Card/VBox/MainArea/HotelSection/Scroll/HotelContainer')

with open(gd_path, 'w', encoding='utf-8') as f:
    f.write(gd_text)

print("Dashboard restructured!")
