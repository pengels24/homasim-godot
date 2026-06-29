import os

tscn_content = """[gd_scene format=3 uid="uid://dfinances001"]

[ext_resource type="Script" path="res://scenes/ingame/hud/modals/content/ModalContentFinances.gd" id="1_scpt"]
[ext_resource type="StyleBox" uid="uid://byn5sg5pqc4ux" path="res://assets/UI/menu_button_blue.tres" id="2_btn"]
[ext_resource type="StyleBox" uid="uid://bxdxryd4oglat" path="res://assets/UI/menu_button_blue_pressed.tres" id="3_btn_p"]
[ext_resource type="StyleBox" uid="uid://bc0pipuhgp5c7" path="res://assets/UI/menu_button_blue_hover.tres" id="4_btn_h"]

[node name="ModalContentFinances" type="VBoxContainer"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 20
script = ExtResource("1_scpt")

[node name="Label" type="Label" parent="."]
layout_mode = 2
theme_type_variation = &"HeaderLarge"
text = "Kassenbuch"
horizontal_alignment = 1

[node name="SummaryHBox" type="HBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 20
alignment = 1

[node name="IncomeBox" type="PanelContainer" parent="SummaryHBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_type_variation = &"InnerPanel"

[node name="VBox" type="VBoxContainer" parent="SummaryHBox/IncomeBox"]
layout_mode = 2
theme_override_constants/separation = 5
alignment = 1

[node name="Title" type="Label" parent="SummaryHBox/IncomeBox/VBox"]
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Einnahmen Heute"
horizontal_alignment = 1

[node name="LblIncome" type="Label" parent="SummaryHBox/IncomeBox/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"ValueLabel"
theme_override_colors/font_color = Color(0.211765, 0.431373, 0.301961, 1)
text = "+0 €"
horizontal_alignment = 1

[node name="ExpenseBox" type="PanelContainer" parent="SummaryHBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_type_variation = &"InnerPanel"

[node name="VBox" type="VBoxContainer" parent="SummaryHBox/ExpenseBox"]
layout_mode = 2
theme_override_constants/separation = 5
alignment = 1

[node name="Title" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Ausgaben Heute"
horizontal_alignment = 1

[node name="LblExpense" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"ValueLabel"
theme_override_colors/font_color = Color(0.690196, 0.180392, 0.231373, 1)
text = "-0 €"
horizontal_alignment = 1

[node name="TotalBox" type="PanelContainer" parent="SummaryHBox"]
layout_mode = 2
size_flags_horizontal = 3
theme_type_variation = &"InnerPanel"

[node name="VBox" type="VBoxContainer" parent="SummaryHBox/TotalBox"]
layout_mode = 2
theme_override_constants/separation = 5
alignment = 1

[node name="Title" type="Label" parent="SummaryHBox/TotalBox/VBox"]
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Saldo Heute"
horizontal_alignment = 1

[node name="LblTotal" type="Label" parent="SummaryHBox/TotalBox/VBox"]
unique_name_in_owner = true
layout_mode = 2
theme_type_variation = &"ValueLabel"
text = "0 €"
horizontal_alignment = 1


[node name="FiltersHBox" type="HBoxContainer" parent="."]
layout_mode = 2
theme_override_constants/separation = 40
alignment = 1

[node name="TimeFilter" type="HBoxContainer" parent="FiltersHBox"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="BtnTimeLeft" type="Button" parent="FiltersHBox/TimeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = "<"

[node name="LblTime" type="Label" parent="FiltersHBox/TimeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(180, 0)
layout_mode = 2
theme_type_variation = &"ValueLabel"
text = "Heute"
horizontal_alignment = 1
vertical_alignment = 1

[node name="BtnTimeRight" type="Button" parent="FiltersHBox/TimeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = ">"

[node name="CatFilter" type="HBoxContainer" parent="FiltersHBox"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="BtnCatLeft" type="Button" parent="FiltersHBox/CatFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = "<"

[node name="LblCat" type="Label" parent="FiltersHBox/CatFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(200, 0)
layout_mode = 2
theme_type_variation = &"ValueLabel"
text = "Alle"
horizontal_alignment = 1
vertical_alignment = 1

[node name="BtnCatRight" type="Button" parent="FiltersHBox/CatFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = ">"

[node name="Panel" type="PanelContainer" parent="."]
layout_mode = 2
size_flags_vertical = 3
theme_type_variation = &"InnerPanel"

[node name="Margin" type="MarginContainer" parent="Panel"]
layout_mode = 2
theme_override_constants/margin_left = 10
theme_override_constants/margin_top = 10
theme_override_constants/margin_right = 10
theme_override_constants/margin_bottom = 10

[node name="VBox" type="VBoxContainer" parent="Panel/Margin"]
layout_mode = 2

[node name="Header" type="HBoxContainer" parent="Panel/Margin/VBox"]
layout_mode = 2

[node name="LblDay" type="Label" parent="Panel/Margin/VBox/Header"]
custom_minimum_size = Vector2(100, 0)
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Zeitpunkt"

[node name="LblCat" type="Label" parent="Panel/Margin/VBox/Header"]
custom_minimum_size = Vector2(180, 0)
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Kategorie"

[node name="LblDesc" type="Label" parent="Panel/Margin/VBox/Header"]
size_flags_horizontal = 3
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Beschreibung"

[node name="LblAmount" type="Label" parent="Panel/Margin/VBox/Header"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
theme_type_variation = &"DescLabel"
text = "Betrag"
horizontal_alignment = 2

[node name="HSeparator" type="HSeparator" parent="Panel/Margin/VBox"]
layout_mode = 2
theme_override_constants/separation = 10

[node name="Scroll" type="ScrollContainer" parent="Panel/Margin/VBox"]
layout_mode = 2
size_flags_vertical = 3
horizontal_scroll_mode = 0

[node name="ListContainer" type="VBoxContainer" parent="Panel/Margin/VBox/Scroll"]
unique_name_in_owner = true
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 8

"""

with open("d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentFinances.tscn", "w", encoding="utf-8") as f:
    f.write(tscn_content)
print("done")
