tscn_path = r'D:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentSettings.tscn'

with open(tscn_path, 'r', encoding='utf-8-sig') as f:
    content = f.read()

if 'HBoxContainerScreen' in content:
    print("Already injected.")
    exit()

injection = """
[node name="PanelScreen" type="HSeparator" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 20)
layout_mode = 2

[node name="HBoxContainerScreen" type="HBoxContainer" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2

[node name="LabelScreen" type="Label" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer/HBoxContainerScreen"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
text = "Monitor"

[node name="HBoxContainer" type="HBoxContainer" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer/HBoxContainerScreen"]
layout_mode = 2

[node name="ButtonScreenLeft" type="Button" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer/HBoxContainerScreen/HBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_styles/normal = ExtResource("2_jjod7")
theme_override_styles/pressed = ExtResource("3_d0jvy")
theme_override_styles/hover = ExtResource("4_v1l06")
icon = ExtResource("2_j758h")

[node name="LabelScreenValue" type="Label" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer/HBoxContainerScreen/HBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(250, 0)
theme_type_variation = &"ValueLabel"
layout_mode = 2
size_flags_horizontal = 10
text = "Monitor 1"
horizontal_alignment = 1

[node name="ButtonScreenRight" type="Button" parent="Oberfl\u00e4che/MarginContainer/VBoxContainer/HBoxContainerScreen/HBoxContainer"]
unique_name_in_owner = true
layout_mode = 2
theme_override_styles/normal = ExtResource("2_jjod7")
theme_override_styles/pressed = ExtResource("3_d0jvy")
theme_override_styles/hover = ExtResource("4_v1l06")
icon = ExtResource("3_xeut1")
"""

# Insert before Tastaturbelegung node
target = '[node name="Tastaturbelegung" type="VBoxContainer" parent="."'
if target in content:
    content = content.replace(target, injection + "\n" + target)
    with open(tscn_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Injected successfully.")
else:
    print("Target not found.")
