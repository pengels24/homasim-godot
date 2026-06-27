import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    '[node name="ModalContentDisclaimer" type="VBoxContainer"]',
    '[node name="ModalContentDisclaimer" type="VBoxContainer"]\ncustom_minimum_size = Vector2(800, 450)'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Added minimum size")