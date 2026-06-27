import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update minimum size
content = content.replace('custom_minimum_size = Vector2(800, 450)', 'custom_minimum_size = Vector2(1000, 600)')

# 2. Add green button styles
if 'theme_override_styles/normal = ExtResource' not in content:
    # Need to add ext_resources at the top
    ext_resources = '''[ext_resource type="Script" uid="uid://ddisclaimer" path="res://scenes/main_menu/ModalContentDisclaimer.gd" id="1_script"]
[ext_resource type="StyleBox" uid="uid://dsvdf3ytd4a3e" path="res://assets/UI/menu_button_green.tres" id="2_green"]
[ext_resource type="StyleBox" uid="uid://cfeb4s3xkj78v" path="res://assets/UI/menu_button_green_hover.tres" id="3_green_hover"]
[ext_resource type="StyleBox" uid="uid://dqk3x3y6a2y8w" path="res://assets/UI/menu_button_green_pressed.tres" id="4_green_pressed"]
'''
    content = content.replace('[ext_resource type="Script" uid="uid://ddisclaimer" path="res://scenes/main_menu/ModalContentDisclaimer.gd" id="1_script"]', ext_resources)

    # Modify BtnOk
    old_btn = '''[node name="BtnOk" type="Button" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(150, 44)
text = "Verstanden!"'''
    new_btn = '''[node name="BtnOk" type="Button" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
custom_minimum_size = Vector2(200, 48)
theme_override_colors/font_color = Color(0.96, 0.96, 0.96, 1)
theme_override_font_sizes/font_size = 24
theme_override_styles/normal = ExtResource("2_green")
theme_override_styles/pressed = ExtResource("4_green_pressed")
theme_override_styles/hover = ExtResource("3_green_hover")
theme_override_styles/focus = ExtResource("2_green")
text = "Verstanden!"'''
    content = content.replace(old_btn, new_btn)

# 3. RichTextLabel font size
old_rtl = '''[node name="RichTextLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
bbcode_enabled = true
text = "Disclaimer Text"'''
new_rtl = '''[node name="RichTextLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
theme_override_font_sizes/normal_font_size = 22
theme_override_font_sizes/bold_font_size = 22
bbcode_enabled = true
text = "Disclaimer Text"'''
content = content.replace(old_rtl, new_rtl)

# 4. Checkbox cutoff fix
# This is usually due to the CheckBox expanding or not expanding properly, or being pushed by the button.
# Let's add size_flags_horizontal = 3 to the Spacer, which we already have. 
# Maybe text_overrun_behavior on the checkbox? Or just setting a custom_minimum_size
# Also, we can set theme_override_font_sizes/font_size = 20 to the CheckBox.
old_chk = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
text = "Nicht mehr anzeigen"'''
new_chk = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Nicht mehr anzeigen"'''
content = content.replace(old_chk, new_chk)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated Disclaimer scene")