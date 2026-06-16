import sys

file_path = r'd:\game-dev\homasim-godot\scenes\manager_select\ManagerSelect.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Card Panel
content = content.replace(
    'theme_override_styles/panel = SubResource("StyleBoxFlat_card")',
    'theme_override_styles/panel = ExtResource("13_modal")'
)

# 2. Add HSeparator after Header and fix Title/BtnClose styles
# We need to find the Header section and replace it.

old_header = """[node name="Title" type="Label" parent="Center/Card/Margin/VBox/Header" unique_id=469940153]
layout_mode = 2
size_flags_horizontal = 3
theme_override_colors/font_color = Color(0.918, 0.702, 0.031, 1)
theme_override_font_sizes/font_size = 32
text = "Manager wählen"
horizontal_alignment = 1

[node name="BtnClose" type="Button" parent="Center/Card/Margin/VBox/Header"]
layout_mode = 2
mouse_default_cursor_shape = 2
text = "✕"
theme_override_styles/normal = SubResource("StyleBoxFlat_close")
theme_override_styles/hover = SubResource("StyleBoxFlat_close_hover")
theme_override_styles/pressed = SubResource("StyleBoxFlat_close")
theme_override_styles/focus = SubResource("StyleBoxEmpty_1")
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.75, 0.75, 0.75, 1)

[node name="Slots" type="HBoxContainer" parent="Center/Card/Margin/VBox" unique_id=114644237]"""

new_header = """[node name="Title" type="Label" parent="Center/Card/Margin/VBox/Header" unique_id=469940153]
layout_mode = 2
size_flags_horizontal = 3
text = "Manager wählen"
theme_override_colors/font_color = Color(0.890196, 0.682353, 0.0313726, 1)
theme_override_colors/font_shadow_color = Color(0, 0, 0, 0.588235)
theme_override_font_sizes/font_size = 32

[node name="BtnClose" type="Button" parent="Center/Card/Margin/VBox/Header"]
layout_mode = 2
custom_minimum_size = Vector2(40, 40)
text = "X"
theme_override_styles/focus = SubResource("StyleBoxEmpty_1")
theme_override_styles/hover = ExtResource("21_red_h")
theme_override_styles/pressed = ExtResource("22_red_p")
theme_override_styles/normal = ExtResource("20_red")

[node name="HSeparator" type="HSeparator" parent="Center/Card/Margin/VBox"]
layout_mode = 2
theme_override_styles/separator = SubResource("StyleBoxLine_goldsep")

[node name="Slots" type="HBoxContainer" parent="Center/Card/Margin/VBox" unique_id=114644237]"""

content = content.replace(old_header, new_header)

# Inject StyleBoxLine_goldsep at the top
subres_goldsep = """[sub_resource type="StyleBoxLine" id="StyleBoxLine_goldsep"]
color = Color(0.890196, 0.682353, 0.0313726, 1)

[node name="ManagerSelectModal" type="Control" unique_id=2032322512]"""

content = content.replace('[node name="ManagerSelectModal" type="Control" unique_id=2032322512]', subres_goldsep)

# 3. Create Button styles (dark blue)
content = content.replace('theme_override_styles/normal = SubResource("StyleBoxFlat_create")', 'theme_override_styles/normal = ExtResource("14_blue")')
content = content.replace('theme_override_styles/pressed = SubResource("StyleBoxFlat_create")', 'theme_override_styles/pressed = ExtResource("16_blue_p")')
content = content.replace('theme_override_styles/hover = SubResource("StyleBoxFlat_create_hover")', 'theme_override_styles/hover = ExtResource("15_blue_h")')

# 4. Select Button styles (green)
content = content.replace('theme_override_styles/normal = SubResource("StyleBoxFlat_select")', 'theme_override_styles/normal = ExtResource("17_green")')
content = content.replace('theme_override_styles/pressed = SubResource("StyleBoxFlat_select")', 'theme_override_styles/pressed = ExtResource("19_green_p")')
content = content.replace('theme_override_styles/hover = SubResource("StyleBoxFlat_select_hover")', 'theme_override_styles/hover = ExtResource("18_green_h")')

# 5. Delete Button styles (red)
content = content.replace('theme_override_styles/normal = SubResource("StyleBoxFlat_delete")', 'theme_override_styles/normal = ExtResource("20_red")')
content = content.replace('theme_override_styles/pressed = SubResource("StyleBoxFlat_delete")', 'theme_override_styles/pressed = ExtResource("22_red_p")')
content = content.replace('theme_override_styles/hover = SubResource("StyleBoxFlat_delete_hover")', 'theme_override_styles/hover = ExtResource("21_red_h")')

# Optional: Make Slot background slightly translucent to fit the modal glow
# "StyleBoxFlat_slot"
# Wait, let's keep StyleBoxFlat_slot as is, it's defined locally at the top.

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
