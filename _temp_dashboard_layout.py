import os
import re

# --- DashboardHotelCard.tscn ---
card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

card_text = card_text.replace('custom_minimum_size = Vector2(360, 420)', 'clip_contents = true\ncustom_minimum_size = Vector2(360, 340)')

vbox_old = r'\[node name="VBox" type="VBoxContainer" parent="."\]\nmouse_filter = 2\nlayout_mode = 2'
vbox_new = r'[node name="VBox" type="VBoxContainer" parent="."]\nmouse_filter = 2\nlayout_mode = 1\nanchors_preset = 15\nanchor_right = 1.0\nanchor_bottom = 1.0\ngrow_horizontal = 2\ngrow_vertical = 2'
card_text = re.sub(vbox_old, vbox_new, card_text)

card_text = re.sub(r'\[node name="Spacer" type="Control" parent="VBox"\].*?size_flags_vertical = 3\n\n', '', card_text, flags=re.DOTALL)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)


# --- Dashboard.tscn ---
dash_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(dash_path, 'r', encoding='utf-8') as f:
    dash_text = f.read()

dash_text = dash_text.replace('custom_minimum_size = Vector2(360, 420)', 'custom_minimum_size = Vector2(360, 340)')

if 'HotelMargin' not in dash_text:
    hotel_cont_old = r'(\[node name="HotelContainer" type="GridContainer" parent="Center/Card/VBox/MainArea/HotelSection/Scroll"[^\]]*\])'
    hotel_margin = r"""[node name="HotelMargin" type="MarginContainer" parent="Center/Card/VBox/MainArea/HotelSection/Scroll"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_constants/margin_left = 4
theme_override_constants/margin_top = 4
theme_override_constants/margin_right = 4
theme_override_constants/margin_bottom = 4

\1"""
    dash_text = re.sub(hotel_cont_old, hotel_margin, dash_text)

    # Now carefully replace the parent ONLY for HotelContainer
    target = r'\[node name="HotelContainer" type="GridContainer" parent="Center/Card/VBox/MainArea/HotelSection/Scroll"'
    replacement = r'[node name="HotelContainer" type="GridContainer" parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelMargin"'
    dash_text = dash_text.replace(target, replacement)

    # Children of HotelContainer parent changes:
    old_child_parent = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelContainer"'
    new_child_parent = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelMargin/HotelContainer"'
    dash_text = dash_text.replace(old_child_parent, new_child_parent)

    # Also fix the Center and Label children of BtnNewHotelCard
    old_btn_child = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelContainer/BtnNewHotelCard"'
    new_btn_child = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelMargin/HotelContainer/BtnNewHotelCard"'
    dash_text = dash_text.replace(old_btn_child, new_btn_child)

    old_label_child = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelContainer/BtnNewHotelCard/Center"'
    new_label_child = 'parent="Center/Card/VBox/MainArea/HotelSection/Scroll/HotelMargin/HotelContainer/BtnNewHotelCard/Center"'
    dash_text = dash_text.replace(old_label_child, new_label_child)

with open(dash_path, 'w', encoding='utf-8') as f:
    f.write(dash_text)

print("Layouts updated safely!")
