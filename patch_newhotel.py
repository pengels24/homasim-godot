import re

file_path = r"d:\game-dev\homasim-godot\scenes\shared\NewHotelModal.tscn"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add ExtResources
ext_resources = """[ext_resource type="StyleBox" uid="uid://dwal8kaocxhoh" path="res://assets/UI/menu_button_red_hover.tres" id="7_red_h"]
[ext_resource type="Texture2D" uid="uid://dd62aim03wf0t" path="res://assets/icons/Modals/arrow-left.svg" id="8_arrow_l"]
[ext_resource type="StyleBox" uid="uid://byn5sg5pqc4ux" path="res://assets/UI/menu_button_blue.tres" id="9_blue"]
[ext_resource type="StyleBox" uid="uid://bxdxryd4oglat" path="res://assets/UI/menu_button_blue_pressed.tres" id="10_blue_p"]
[ext_resource type="Texture2D" uid="uid://c4qeeryni0rp6" path="res://assets/icons/Modals/arrow-right.svg" id="11_arrow_r"]
[ext_resource type="StyleBox" uid="uid://bc0pipuhgp5c7" path="res://assets/UI/menu_button_blue_hover.tres" id="12_blue_h"]"""
content = content.replace('[ext_resource type="StyleBox" uid="uid://dwal8kaocxhoh" path="res://assets/UI/menu_button_red_hover.tres" id="7_red_h"]', ext_resources)

# 2. Values -> ValueLabel
content = re.sub(
    r'(\[node name="ValueLbl" type="Label"[^\]]*\]\nlayout_mode = 2\n)',
    r'\1theme_type_variation = &"ValueLabel"\n',
    content
)

# 3. GridLabel -> HeaderMedium
content = content.replace(
    '[node name="GridLabel" type="Label" parent="Content/Right"]\nlayout_mode = 2\ntext = "Startparzelle"',
    '[node name="GridLabel" type="Label" parent="Content/Right"]\ntheme_type_variation = &"HeaderMedium"\nlayout_mode = 2\ntext = "Startparzelle"'
)

# 4. Buttons (LeftBtn, RightBtn)
left_btn_repl = """layout_mode = 2
theme_override_styles/normal = ExtResource("9_blue")
theme_override_styles/pressed = ExtResource("10_blue_p")
theme_override_styles/hover = ExtResource("12_blue_h")
icon = ExtResource("8_arrow_l")"""

right_btn_repl = """layout_mode = 2
theme_override_styles/normal = ExtResource("9_blue")
theme_override_styles/pressed = ExtResource("10_blue_p")
theme_override_styles/hover = ExtResource("12_blue_h")
icon = ExtResource("11_arrow_r")"""

# Remove text=" ◀ " and replace layout_mode
content = re.sub(
    r'layout_mode = 2\n(?:disabled = true\n)?text = " ◀ "',
    lambda m: left_btn_repl if 'disabled' not in m.group(0) else "disabled = true\n" + left_btn_repl,
    content
)

content = re.sub(
    r'layout_mode = 2\n(?:disabled = true\n)?text = " ▶ "',
    lambda m: right_btn_repl if 'disabled' not in m.group(0) else "disabled = true\n" + right_btn_repl,
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Patched NewHotelModal.tscn")
