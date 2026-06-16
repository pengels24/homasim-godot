import os
import re

def add_green_resources(text):
    ext_resources = []
    if 'menu_button_green_hover.tres' not in text:
        ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_green_hover.tres" id="green_hover"]')
    if 'menu_button_green_pressed.tres' not in text:
        ext_resources.append('[ext_resource type="StyleBox" path="res://assets/UI/menu_button_green_pressed.tres" id="green_pressed"]')
    
    if ext_resources:
        last_ext_idx = text.rfind('[ext_resource')
        if last_ext_idx != -1:
            end_idx = text.find('\n', last_ext_idx)
            text = text[:end_idx+1] + '\n'.join(ext_resources) + '\n' + text[end_idx+1:]
    return text

def fix_buttons(text, green_normal_id):
    text = re.sub(
        r'theme_override_styles/normal = ExtResource\("([^"]+)"\)\ntheme_override_styles/hover = ExtResource\("\1"\)\ntheme_override_styles/pressed = ExtResource\("\1"\)',
        rf'theme_override_styles/normal = ExtResource("{green_normal_id}")\ntheme_override_styles/hover = ExtResource("green_hover")\ntheme_override_styles/pressed = ExtResource("green_pressed")',
        text
    )
    return text

# --- DashboardHotelCard.tscn ---
card_path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(card_path, 'r', encoding='utf-8') as f:
    card_text = f.read()

# Change columns from 2 to 4
card_text = re.sub(r'(\[node name="StatsGrid".*?\n.*?columns = )2', r'\g<1>4', card_text, flags=re.DOTALL)

# Find ID of green normal
match = re.search(r'\[ext_resource type="StyleBox" path="res://assets/UI/menu_button_green.tres" id="([^"]+)"\]', card_text)
green_normal_id = match.group(1) if match else "4_green"

card_text = add_green_resources(card_text)
card_text = fix_buttons(card_text, green_normal_id)

with open(card_path, 'w', encoding='utf-8') as f:
    f.write(card_text)

# --- Dashboard.tscn ---
dash_path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(dash_path, 'r', encoding='utf-8') as f:
    dash_text = f.read()

match = re.search(r'\[ext_resource type="StyleBox" path="res://assets/UI/menu_button_green.tres" id="([^"]+)"\]', dash_text)
green_normal_id_dash = match.group(1) if match else "4_green"

dash_text = add_green_resources(dash_text)
# We only want to replace the green button (BtnNewHotelCard)
dash_text = re.sub(
    rf'theme_override_styles/normal = ExtResource\("{green_normal_id_dash}"\)\ntheme_override_styles/hover = ExtResource\("{green_normal_id_dash}"\)\ntheme_override_styles/pressed = ExtResource\("{green_normal_id_dash}"\)',
    rf'theme_override_styles/normal = ExtResource("{green_normal_id_dash}")\ntheme_override_styles/hover = ExtResource("green_hover")\ntheme_override_styles/pressed = ExtResource("green_pressed")',
    dash_text
)

with open(dash_path, 'w', encoding='utf-8') as f:
    f.write(dash_text)

print("Card columns and buttons fixed!")
