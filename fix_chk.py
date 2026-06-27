import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

chk_old = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "Nicht mehr anzeigen"'''

chk_new = '''[node name="CheckDontShow" type="CheckBox" parent="HBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 20
text_overrun_behavior = 0
clip_text = false
text = "Nicht mehr anzeigen"'''

content = content.replace(chk_old, chk_new)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated CheckBox properties")