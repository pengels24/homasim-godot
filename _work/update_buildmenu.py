import re

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/BuildMenu.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

pattern = re.compile(r'\[node name=\"BreadcrumbLabel\" type=\"Label\" parent=\"MarginContainer/VBoxContainer\" unique_id=\d+\]\nlayout_mode = 2\ntheme_override_styles/normal = SubResource\(\"StyleBoxFlat_Breadcrumb\"\)\nhorizontal_alignment = 1')

new_text = '''[node name=\"BreadcrumbHBox\" type=\"HBoxContainer\" parent=\"MarginContainer/VBoxContainer\"]
layout_mode = 2
alignment = 1
theme_override_constants/separation = 10

[node name=\"BreadcrumbLabel\" type=\"Label\" parent=\"MarginContainer/VBoxContainer/BreadcrumbHBox\"]
layout_mode = 2
theme_override_styles/normal = SubResource(\"StyleBoxFlat_Breadcrumb\")
horizontal_alignment = 1

[node name=\"CloseButton\" type=\"Button\" parent=\"MarginContainer/VBoxContainer/BreadcrumbHBox\"]
layout_mode = 2
text = \" X \"'''

text = pattern.sub(new_text, text)

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/BuildMenu.tscn', 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)
