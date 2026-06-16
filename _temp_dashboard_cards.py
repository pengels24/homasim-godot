import os
import re

hover_style = """
[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_card_hover"]
bg_color = Color(0.15, 0.15, 0.18, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.918, 0.702, 0.031, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
shadow_color = Color(0.918, 0.702, 0.031, 0.2)
shadow_size = 10

[sub_resource type="StyleBoxEmpty" id="StyleBoxEmpty_focus"]
"""

# --- DashboardHotelCard.tscn ---
card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# Replace root type
card_text = re.sub(r'\[node name="DashboardHotelCard" type="PanelContainer"\]', r'[node name="DashboardHotelCard" type="Button"]', card_text)

# Add subresources
if 'StyleBoxFlat_card_hover' not in card_text:
    card_text = re.sub(r'(\[node name="DashboardHotelCard" type="Button"\])', hover_style + r'\n\1', card_text)

# Change theme overrides
panel_styles = r'theme_override_styles/panel = SubResource\("StyleBoxFlat_card"\)'
button_styles = """mouse_default_cursor_shape = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_card")
theme_override_styles/hover = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/focus = SubResource("StyleBoxEmpty_focus")"""
card_text = card_text.replace(panel_styles, button_styles)

# Set child containers to ignore mouse
card_text = card_text.replace(r'[node name="VBox" type="VBoxContainer" parent="."]', r'[node name="VBox" type="VBoxContainer" parent="."]\nmouse_filter = 2')
card_text = card_text.replace(r'[node name="StatsGrid" type="GridContainer" parent="VBox/CenterStats"]', r'[node name="StatsGrid" type="GridContainer" parent="VBox/CenterStats"]\nmouse_filter = 2')
card_text = card_text.replace(r'[node name="TopRight" type="Control" parent="VBox/ThumbContainer"]\nlayout_mode = 2\nmouse_filter = 2', r'[node name="TopRight" type="Control" parent="VBox/ThumbContainer"]\nlayout_mode = 2\nmouse_filter = 2\nz_index = 5')

# Remove BtnPlay entirely. Since its structure might vary, let's just regex remove it.
# It starts at [node name="BtnPlay" and goes until the end of file (since it's the last node).
card_text = re.sub(r'\[node name="BtnPlay".*$', '', card_text, flags=re.DOTALL)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

# --- DashboardHotelCard.gd ---
gd_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.gd'
with open(gd_path, 'r', encoding='utf-8') as f:
    gd_text = f.read()

gd_text = gd_text.replace('extends PanelContainer', 'extends Button')
gd_text = re.sub(r'@onready var btn_play: Button = %BtnPlay\n', '', gd_text)
gd_text = gd_text.replace('btn_play.pressed.connect(func(): sig_play_requested.emit(hotel_id))', 'self.pressed.connect(func(): sig_play_requested.emit(hotel_id))')
gd_text = re.sub(r'\s*btn_play\.text = GameState\.T\("dashboard\.btn\.play_hotel"\)', '', gd_text)

with open(gd_path, 'w', encoding='utf-8') as f:
    f.write(gd_text)

# --- Dashboard.tscn ---
dash_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(dash_path, 'r', encoding='utf-8') as f:
    dash_text = f.read()

if 'StyleBoxFlat_card_hover' not in dash_text:
    dash_text = re.sub(r'(\[node name="Dashboard" type="Control")', hover_style + r'\n\1', dash_text)

# We need to replace NewHotelCard block
# Find the start of NewHotelCard
start_str = '[node name="NewHotelCard" type="PanelContainer"'
start_idx = dash_text.find(start_str)

if start_idx != -1:
    # Find the end of it, which is the start of ConfirmModal
    end_str = '[node name="ConfirmModal"'
    end_idx = dash_text.find(end_str)
    
    if end_idx != -1:
        # Extract the parent path dynamically
        match = re.search(r'parent="([^"]+)"', dash_text[start_idx:start_idx+100])
        parent_path = match.group(1) if match else "Center/Card/VBox/MainArea/HotelSection/Scroll/HotelContainer"
        
        new_hotel_node = f"""[node name="BtnNewHotelCard" type="Button" parent="{parent_path}"]
unique_name_in_owner = true
custom_minimum_size = Vector2(360, 420)
layout_mode = 2
mouse_default_cursor_shape = 2
theme_override_styles/normal = SubResource("StyleBoxFlat_card")
theme_override_styles/hover = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_card_hover")
theme_override_styles/focus = SubResource("StyleBoxEmpty_focus")

[node name="Center" type="CenterContainer" parent="{parent_path}/BtnNewHotelCard"]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2

[node name="Label" type="Label" parent="{parent_path}/BtnNewHotelCard/Center"]
layout_mode = 2
theme_override_font_sizes/font_size = 120
theme_override_colors/font_color = Color(0.8, 0.8, 0.8, 1)
text = "+"

"""
        dash_text = dash_text[:start_idx] + new_hotel_node + dash_text[end_idx:]

with open(dash_path, 'w', encoding='utf-8') as f:
    f.write(dash_text)

print("Cards changed to buttons!")
