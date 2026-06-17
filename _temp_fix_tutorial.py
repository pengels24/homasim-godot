import os
import re

tut_path = r'd:\game-dev\homasim-godot\scenes\ingame\hud\TutorialPopup.tscn'
with open(tut_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix ScrollContainer
# From:
# [node name="ScrollContainer" type="ScrollContainer" parent="..."]
# custom_minimum_size = Vector2(0, 50)
# layout_mode = 2
# To:
# [node name="ScrollContainer" type="ScrollContainer" parent="..."]
# custom_minimum_size = Vector2(0, 150)
# layout_mode = 2
# size_flags_vertical = 3

text = text.replace('custom_minimum_size = Vector2(0, 50)', 'custom_minimum_size = Vector2(0, 150)')

if 'size_flags_vertical = 3' not in text.split('[node name="Desc"')[0]:
    text = text.replace(
        '[node name="ScrollContainer" type="ScrollContainer" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer" unique_id=1418119967]\ncustom_minimum_size = Vector2(0, 150)\nlayout_mode = 2\n',
        '[node name="ScrollContainer" type="ScrollContainer" parent="CenterContainer/PanelContainer/MarginContainer/VBoxContainer" unique_id=1418119967]\ncustom_minimum_size = Vector2(0, 150)\nlayout_mode = 2\nsize_flags_vertical = 3\n'
    )

# Fix Desc (RichTextLabel)
# Ensure it has size_flags_horizontal = 3

desc_idx = text.find('[node name="Desc"')
close_btn_idx = text.find('[node name="CloseBtn"')

desc_block = text[desc_idx:close_btn_idx]
if 'size_flags_horizontal = 3' not in desc_block:
    new_desc_block = desc_block.replace('size_flags_vertical = 3', 'size_flags_horizontal = 3\nsize_flags_vertical = 3')
    text = text[:desc_idx] + new_desc_block + text[close_btn_idx:]

with open(tut_path, 'w', encoding='utf-8') as f:
    f.write(text)

print("TutorialPopup fixed!")
