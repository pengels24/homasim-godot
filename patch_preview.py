import re

file_path = r"d:\game-dev\homasim-godot\scenes\character\CharacterEdit.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add SubResource
sub_res = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_input_focus"]
content_margin_left = 16.0
content_margin_top = 12.0
content_margin_right = 16.0
content_margin_bottom = 12.0
bg_color = Color(0.13, 0.13, 0.16, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.918, 0.702, 0.031, 0.8)
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_right = 6
corner_radius_bottom_left = 6

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_preview_bg"]
bg_color = Color(0.18, 0.2, 0.25, 1)
corner_radius_top_left = 8
corner_radius_top_right = 8
corner_radius_bottom_right = 8
corner_radius_bottom_left = 8
content_margin_left = 16.0
content_margin_top = 16.0
content_margin_right = 16.0
content_margin_bottom = 16.0"""

content = re.sub(
    r'\[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_input_focus"\].*?corner_radius_bottom_left = 6',
    sub_res,
    content,
    flags=re.DOTALL
)

# Wrap CharacterDisplay
wrapper = """[node name="PreviewBg" type="PanelContainer" parent="Center/Card/Margin/VBox/HBox/Preview"]
layout_mode = 2
size_flags_horizontal = 4
theme_override_styles/panel = SubResource("StyleBoxFlat_preview_bg")

[node name="CharacterDisplay" parent="Center/Card/Margin/VBox/HBox/Preview/PreviewBg" unique_id=671905130 instance=ExtResource("2_chardisplay")]
layout_mode = 2
size_flags_horizontal = 4"""

content = re.sub(
    r'\[node name="CharacterDisplay" parent="Center/Card/Margin/VBox/HBox/Preview" unique_id=671905130 instance=ExtResource\("2_chardisplay"\)\]\nlayout_mode = 2\nsize_flags_horizontal = 4',
    wrapper,
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched CharacterEdit.tscn")
