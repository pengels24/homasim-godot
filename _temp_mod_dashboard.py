import os

path = r'd:\game-dev\homasim-godot\scenes\dashboard\Dashboard.tscn'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if '[node name="Dashboard" type="Control"]' in line:
        new_lines.append(line)
        new_lines.append('theme = ExtResource("1_theme")\n')
    elif '[ext_resource type="Script"' in line and 'Dashboard.gd' in line:
        new_lines.append('[ext_resource type="Theme" uid="uid://m7vvlxrl4xfq" path="res://assets/UI/default_theme.tres" id="1_theme"]\n')
        new_lines.append('[ext_resource type="Texture2D" uid="uid://c6c3p2xw4kqj0" path="res://assets/images/home/home-background-001.png" id="2_bg"]\n')
        new_lines.append('[ext_resource type="StyleBox" uid="uid://cg2q7w0wqska8" path="res://assets/UI/modal_panel_glow.tres" id="3_glow"]\n')
        new_lines.append('[ext_resource type="StyleBox" uid="uid://b12l4w11sxh13" path="res://assets/UI/menu_button_green.tres" id="4_green"]\n')
        new_lines.append(line)
    elif '[node name="Bg" type="ColorRect" parent="."]' in line:
        new_lines.append('[node name="Bg" type="TextureRect" parent="."]\n')
        new_lines.append('layout_mode = 0\n')
        new_lines.append('offset_right = 1920.0\n')
        new_lines.append('offset_bottom = 1080.0\n')
        new_lines.append('texture = ExtResource("2_bg")\n')
        new_lines.append('modulate = Color(0.3, 0.3, 0.35, 1)\n')
    elif 'color = Color(0.08, 0.08, 0.10, 1)' in line:
        pass # removed
    elif 'theme_override_styles/panel = SubResource("StyleBoxFlat_manager")' in line:
        new_lines.append('theme_override_styles/panel = ExtResource("3_glow")\n')
        new_lines.append('custom_minimum_size = Vector2(300, 0)\n')
        new_lines.append('size_flags_vertical = 4\n')
    elif 'custom_minimum_size = Vector2(280, 0)' in line:
        pass
    elif '[node name="BtnNewHotel" type="Button" parent="MainArea/HotelSection/Header"]' in line:
        # We will remove BtnNewHotel from header
        pass
    elif '[node name="HotelContainer" type="VBoxContainer"' in line:
        new_lines.append('[node name="HotelContainer" type="GridContainer" parent="MainArea/HotelSection/Scroll"]\n')
        new_lines.append('layout_mode = 2\n')
        new_lines.append('size_flags_horizontal = 3\n')
        new_lines.append('theme_override_constants/h_separation = 32\n')
        new_lines.append('theme_override_constants/v_separation = 32\n')
        new_lines.append('columns = 3\n')
        new_lines.append('\n')
        new_lines.append('[node name="NewHotelCard" type="PanelContainer" parent="MainArea/HotelSection/Scroll/HotelContainer"]\n')
        new_lines.append('unique_name_in_owner = true\n')
        new_lines.append('custom_minimum_size = Vector2(360, 420)\n')
        new_lines.append('layout_mode = 2\n')
        new_lines.append('theme_override_styles/panel = ExtResource("3_glow")\n')
        new_lines.append('\n')
        new_lines.append('[node name="VBox" type="VBoxContainer" parent="MainArea/HotelSection/Scroll/HotelContainer/NewHotelCard"]\n')
        new_lines.append('layout_mode = 2\n')
        new_lines.append('alignment = 1\n')
        new_lines.append('theme_override_constants/separation = 20\n')
        new_lines.append('\n')
        new_lines.append('[node name="Label" type="Label" parent="MainArea/HotelSection/Scroll/HotelContainer/NewHotelCard/VBox"]\n')
        new_lines.append('layout_mode = 2\n')
        new_lines.append('theme_override_font_sizes/font_size = 28\n')
        new_lines.append('text = "Neues Hotel bauen"\n')
        new_lines.append('horizontal_alignment = 1\n')
        new_lines.append('\n')
        new_lines.append('[node name="BtnNewHotelCard" type="Button" parent="MainArea/HotelSection/Scroll/HotelContainer/NewHotelCard/VBox"]\n')
        new_lines.append('unique_name_in_owner = true\n')
        new_lines.append('custom_minimum_size = Vector2(200, 60)\n')
        new_lines.append('layout_mode = 2\n')
        new_lines.append('size_flags_horizontal = 4\n')
        new_lines.append('theme_override_styles/normal = ExtResource("4_green")\n')
        new_lines.append('theme_override_styles/hover = ExtResource("4_green")\n')
        new_lines.append('theme_override_styles/pressed = ExtResource("4_green")\n')
        new_lines.append('theme_override_font_sizes/font_size = 24\n')
        new_lines.append('text = "➕"\n')
        new_lines.append('mouse_default_cursor_shape = 2\n')
    elif 'theme_override_constants/separation = 16' in line and '[node name="HotelContainer" type="VBoxContainer"' in lines[lines.index(line)-2]:
        pass
    else:
        # We need to skip lines belonging to BtnNewHotel
        if 'BtnNewHotel' in line and 'Header' in line:
            continue
        new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
print("Dashboard.tscn modified successfully!")
