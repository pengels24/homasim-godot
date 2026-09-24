import re

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/BuildMenu.tscn', 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add ext_resources
ext_resources = '''[ext_resource type="PackedScene" uid="uid://cxi5q33hphmqv" path="res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn" id="3_rd224"]
[ext_resource type="StyleBox" uid="uid://cth7xo3seiusw" path="res://assets/UI/menu_button_red.tres" id="StyleBox_RedNormal"]
[ext_resource type="StyleBox" uid="uid://efh4spsvdija" path="res://assets/UI/menu_button_red_pressed.tres" id="StyleBox_RedPressed"]
[ext_resource type="StyleBox" uid="uid://dwal8kaocxhoh" path="res://assets/UI/menu_button_red_hover.tres" id="StyleBox_RedHover"]'''

text = text.replace('[ext_resource type="PackedScene" uid="uid://cxi5q33hphmqv" path="res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn" id="3_rd224"]', ext_resources)

# 2. Update CloseButton
old_btn = '''[node name="CloseButton" type="Button" parent="MarginContainer/VBoxContainer/BreadcrumbHBox"]
layout_mode = 2
text = " X "'''

new_btn = '''[node name="CloseButton" type="Button" parent="MarginContainer/VBoxContainer/BreadcrumbHBox"]
layout_mode = 2
theme_override_styles/normal = ExtResource("StyleBox_RedNormal")
theme_override_styles/pressed = ExtResource("StyleBox_RedPressed")
theme_override_styles/hover = ExtResource("StyleBox_RedHover")
text = " X "'''

text = text.replace(old_btn, new_btn)

with open('d:/game-dev/homasim-godot/scenes/ingame/hud/BuildMenu.tscn', 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)
