import re

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentFinances.tscn', 'r', encoding='utf-8') as f:
    tscn = f.read()

tscn = tscn.replace('name="LblIncome" type="Label" parent="SummaryHBox/IncomeBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabel"', 
                    'name="LblIncome" type="Label" parent="SummaryHBox/IncomeBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabelLarge"')

tscn = tscn.replace('name="LblExpense" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabel"', 
                    'name="LblExpense" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabelLarge"')

tscn = tscn.replace('name="LblTotal" type="Label" parent="SummaryHBox/TotalBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabel"', 
                    'name="LblTotal" type="Label" parent="SummaryHBox/TotalBox/VBox"]\nunique_name_in_owner = true\nlayout_mode = 2\ntheme_type_variation = &"ValueLabelLarge"')

tscn = tscn.replace('[node name="Title" type="Label" parent="SummaryHBox/IncomeBox/VBox"]', '[node name="TitleIncome" type="Label" parent="SummaryHBox/IncomeBox/VBox"]\nunique_name_in_owner = true')
tscn = tscn.replace('[node name="Title" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]', '[node name="TitleExpense" type="Label" parent="SummaryHBox/ExpenseBox/VBox"]\nunique_name_in_owner = true')
tscn = tscn.replace('[node name="Title" type="Label" parent="SummaryHBox/TotalBox/VBox"]', '[node name="TitleTotal" type="Label" parent="SummaryHBox/TotalBox/VBox"]\nunique_name_in_owner = true')

new_filter = """
[node name="TypeFilter" type="HBoxContainer" parent="FiltersHBox"]
layout_mode = 2
theme_override_constants/separation = 15

[node name="BtnTypeLeft" type="Button" parent="FiltersHBox/TypeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = "<"

[node name="LblType" type="Label" parent="FiltersHBox/TypeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(180, 0)
layout_mode = 2
theme_type_variation = &"ValueLabel"
text = "Alle"
horizontal_alignment = 1
vertical_alignment = 1

[node name="BtnTypeRight" type="Button" parent="FiltersHBox/TypeFilter"]
unique_name_in_owner = true
custom_minimum_size = Vector2(40, 40)
layout_mode = 2
theme_override_font_sizes/font_size = 24
theme_override_styles/hover = ExtResource("4_btn_h")
theme_override_styles/pressed = ExtResource("3_btn_p")
theme_override_styles/normal = ExtResource("2_btn")
text = ">"
"""

tscn = tscn.replace('[node name="Panel" type="PanelContainer" parent="."]', new_filter + '\n[node name="Panel" type="PanelContainer" parent="."]')

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentFinances.tscn', 'w', encoding='utf-8') as f:
    f.write(tscn)
print("done")
