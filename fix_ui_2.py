import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Update text font sizes
old_rtl = '''[node name="RichTextLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
theme_override_font_sizes/normal_font_size = 22
theme_override_font_sizes/bold_font_size = 22
bbcode_enabled = true'''
new_rtl = '''[node name="RichTextLabel" type="RichTextLabel" parent="."]
unique_name_in_owner = true
layout_mode = 2
size_flags_vertical = 3
theme_override_font_sizes/normal_font_size = 24
theme_override_font_sizes/bold_font_size = 24
bbcode_enabled = true'''
content = content.replace(old_rtl, new_rtl)

# 2. Add custom minimum size to checkbox
old_chk = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text_overrun_behavior = 0
clip_text = false'''
new_chk = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(300, 0)
layout_mode = 2
theme_override_font_sizes/font_size = 20
text_overrun_behavior = 0
clip_text = false'''
content = content.replace(old_chk, new_chk)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Applied tweaks")