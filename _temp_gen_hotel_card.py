import os

tscn_content = """[gd_scene load_steps=5 format=3 uid="uid://cx4dashboardhotelcard"]

[ext_resource type="StyleBox" uid="uid://cg2q7w0wqska8" path="res://assets/UI/modal_panel_glow.tres" id="1_glow"]
[ext_resource type="Script" path="res://scenes/dashboard/DashboardHotelCard.gd" id="2_script"]
[ext_resource type="StyleBox" uid="uid://efh4spsvdija" path="res://assets/UI/menu_button_red_pressed.tres" id="3_red"]
[ext_resource type="StyleBox" uid="uid://b12l4w11sxh13" path="res://assets/UI/menu_button_green.tres" id="4_green"]

[node name="DashboardHotelCard" type="PanelContainer"]
custom_minimum_size = Vector2(360, 420)
theme_override_styles/panel = ExtResource("1_glow")
script = ExtResource("2_script")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 12

[node name="ThumbContainer" type="MarginContainer" parent="VBox"]
custom_minimum_size = Vector2(0, 200)
layout_mode = 2

[node name="TextureRect" type="TextureRect" parent="VBox/ThumbContainer"]
unique_name_in_owner = true
layout_mode = 2
expand_mode = 1
stretch_mode = 6

[node name="TopRight" type="Control" parent="VBox/ThumbContainer"]
layout_mode = 2
mouse_filter = 2

[node name="BtnDelete" type="Button" parent="VBox/ThumbContainer/TopRight"]
unique_name_in_owner = true
layout_mode = 1
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -44.0
offset_top = 8.0
offset_right = -8.0
offset_bottom = 44.0
grow_horizontal = 0
theme_override_styles/normal = ExtResource("3_red")
theme_override_styles/hover = ExtResource("3_red")
theme_override_styles/pressed = ExtResource("3_red")
text = "X"
mouse_default_cursor_shape = 2

[node name="LabelName" type="Label" parent="VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_override_font_sizes/font_size = 28
text = "Hotel Name"
horizontal_alignment = 1

[node name="CenterStats" type="CenterContainer" parent="VBox"]
layout_mode = 2

[node name="StatsGrid" type="GridContainer" parent="VBox/CenterStats"]
layout_mode = 2
theme_override_constants/h_separation = 32
theme_override_constants/v_separation = 8
columns = 2

[node name="Lbl1" type="Label" parent="VBox/CenterStats/StatsGrid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.65, 0.65, 1)
text = "LEVEL"

[node name="LabelLevel" type="Label" parent="VBox/CenterStats/StatsGrid"]
unique_name_in_owner = true
layout_mode = 2
text = "1"

[node name="Lbl2" type="Label" parent="VBox/CenterStats/StatsGrid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.65, 0.65, 1)
text = "TAG"

[node name="LabelDay" type="Label" parent="VBox/CenterStats/StatsGrid"]
unique_name_in_owner = true
layout_mode = 2
text = "1"

[node name="Lbl3" type="Label" parent="VBox/CenterStats/StatsGrid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.65, 0.65, 1)
text = "GÄSTE"

[node name="LabelGuests" type="Label" parent="VBox/CenterStats/StatsGrid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="Lbl4" type="Label" parent="VBox/CenterStats/StatsGrid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.65, 0.65, 1)
text = "RUF"

[node name="LabelRep" type="Label" parent="VBox/CenterStats/StatsGrid"]
unique_name_in_owner = true
layout_mode = 2
text = "0"

[node name="Lbl5" type="Label" parent="VBox/CenterStats/StatsGrid"]
layout_mode = 2
theme_override_colors/font_color = Color(0.65, 0.65, 0.65, 1)
text = "KAPITAL"

[node name="LabelMoney" type="Label" parent="VBox/CenterStats/StatsGrid"]
unique_name_in_owner = true
layout_mode = 2
theme_override_colors/font_color = Color(0.92, 0.7, 0.03, 1)
text = "€ 50.000"

[node name="Spacer" type="Control" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="BtnPlay" type="Button" parent="VBox"]
unique_name_in_owner = true
custom_minimum_size = Vector2(0, 44)
layout_mode = 2
theme_override_styles/normal = ExtResource("4_green")
theme_override_styles/hover = ExtResource("4_green")
theme_override_styles/pressed = ExtResource("4_green")
text = "Spielen"
mouse_default_cursor_shape = 2
"""

path = r'd:\game-dev\homasim-godot\scenes\dashboard\DashboardHotelCard.tscn'
with open(path, 'w', encoding='utf-8') as f:
    f.write(tscn_content)
print("DashboardHotelCard.tscn generated successfully!")
