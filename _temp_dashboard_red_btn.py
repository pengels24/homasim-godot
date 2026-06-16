import os
import re

path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

ext_resources = []
if 'menu_button_red.tres' not in text:
    ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red.tres" id="red_normal"]')
if 'menu_button_red_hover.tres' not in text:
    ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red_hover.tres" id="red_hover"]')
if 'menu_button_red_pressed.tres' not in text:
    # "3_red" is already menu_button_red_pressed.tres! Let's check
    pass

if ext_resources:
    last_ext_idx = text.rfind('[ext_resource')
    if last_ext_idx != -1:
        end_idx = text.find('\n', last_ext_idx)
        text = text[:end_idx+1] + '\n'.join(ext_resources) + '\n' + text[end_idx+1:]

# Find the ID for menu_button_red_pressed.tres
match = re.search(r'\[ext_resource type="StyleBox" path="res://assets/UI/menu_button_red_pressed.tres" id="([^"]+)"\]', text)
red_pressed_id = match.group(1) if match else "3_red"

btn_delete_regex = r'(\[node name="BtnDelete" type="Button".*?\n.*?theme_override_styles/normal = ExtResource\()"[^"]+"(\)\ntheme_override_styles/hover = ExtResource\()"[^"]+"(\)\ntheme_override_styles/pressed = ExtResource\()"[^"]+"(\))'
text = re.sub(btn_delete_regex, r'\1"red_normal"\2"red_hover"\3"' + red_pressed_id + r'"\4', text, flags=re.DOTALL)

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)

print("Red button styles updated in card!")
