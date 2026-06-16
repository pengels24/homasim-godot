import os
import re

# --- DashboardHotelCard.tscn ---
card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# 1. Remove clip_contents = true
card_text = card_text.replace('clip_contents = true\n', '')

# 2. Define StyleBoxFlat_thumb
thumb_style = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_thumb"]
bg_color = Color(1, 1, 1, 1)
corner_radius_top_left = 6
corner_radius_top_right = 6

"""
# insert right before DashboardHotelCard node
card_text = card_text.replace('[node name="DashboardHotelCard" type="Button"]', thumb_style + '[node name="DashboardHotelCard" type="Button"]')

# 3. Replace VBox with CardMargin > VBox
old_vbox = """[node name="VBox" type="VBoxContainer" parent="."]
mouse_filter = 2
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 12"""

new_vbox = """[node name="CardMargin" type="MarginContainer" parent="."]
mouse_filter = 2
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/margin_left = 2
theme_override_constants/margin_top = 2
theme_override_constants/margin_right = 2
theme_override_constants/margin_bottom = 12

[node name="VBox" type="VBoxContainer" parent="CardMargin"]
mouse_filter = 2
layout_mode = 2
theme_override_constants/separation = 12"""

card_text = card_text.replace(old_vbox, new_vbox)

# Now we must fix the parent of all immediate children of VBox
card_text = card_text.replace('parent="VBox"', 'parent="CardMargin/VBox"')
# (This includes ThumbContainer, LabelName, CenterStats)

# 4. Update ThumbContainer to PanelContainer and add clip_children
old_thumb = """[node name="ThumbContainer" type="MarginContainer" parent="CardMargin/VBox"]
custom_minimum_size = Vector2(0, 200)
layout_mode = 2"""

new_thumb = """[node name="ThumbContainer" type="PanelContainer" parent="CardMargin/VBox"]
clip_children = 1
custom_minimum_size = Vector2(0, 200)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_thumb")"""

card_text = card_text.replace(old_thumb, new_thumb)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

# --- Dashboard.tscn ---
dash_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(dash_path, 'r', encoding='utf-8') as f:
    dash_text = f.read()

# Change HotelMargin margins from 4 to 16
dash_text = dash_text.replace('theme_override_constants/margin_left = 4', 'theme_override_constants/margin_left = 16')
dash_text = dash_text.replace('theme_override_constants/margin_top = 4', 'theme_override_constants/margin_top = 16')
dash_text = dash_text.replace('theme_override_constants/margin_right = 4', 'theme_override_constants/margin_right = 16')
dash_text = dash_text.replace('theme_override_constants/margin_bottom = 4', 'theme_override_constants/margin_bottom = 16')

with open(dash_path, 'w', encoding='utf-8') as f:
    f.write(dash_text)

print("Card visual perfection achieved!")
