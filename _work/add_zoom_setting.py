import os

tscn_path = r'D:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentSettings.tscn'

with open(tscn_path, 'r', encoding='utf-8') as f:
    content = f.read()

injection = """
[node name="PanelZoom" type="HSeparator" parent="Gameplay/MarginContainer/VBoxContainer"]
layout_mode = 2

[node name="HBoxContainerZoom" type="HBoxContainer" parent="Gameplay/MarginContainer/VBoxContainer"]
custom_minimum_size = Vector2(0, 40)
layout_mode = 2

[node name="LabelZoomSens" type="Label" parent="Gameplay/MarginContainer/VBoxContainer/HBoxContainerZoom"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
text = "Zoom-Empfindlichkeit"

[node name="HBoxContainer" type="HBoxContainer" parent="Gameplay/MarginContainer/VBoxContainer/HBoxContainerZoom"]
layout_mode = 2
size_flags_horizontal = 3
alignment = 2

[node name="HSliderZoomSens" type="HSlider" parent="Gameplay/MarginContainer/VBoxContainer/HBoxContainerZoom/HBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(200, 0)
layout_mode = 2
size_flags_vertical = 4
min_value = 0.5
max_value = 3.0
step = 0.1
value = 1.0

[node name="LabelZoomSensValue" type="Label" parent="Gameplay/MarginContainer/VBoxContainer/HBoxContainerZoom/HBoxContainer"]
unique_name_in_owner = true
custom_minimum_size = Vector2(50, 0)
theme_type_variation = &"ValueLabel"
layout_mode = 2
text = "1.0x"
horizontal_alignment = 2
"""

# Insert before Audio node
target = '[node name="Audio" type="VBoxContainer" parent="." '
if target in content and "HSliderZoomSens" not in content:
    content = content.replace(target, injection + "\n" + target)
    with open(tscn_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Injected successfully.")
else:
    print("Target not found or already injected.")
