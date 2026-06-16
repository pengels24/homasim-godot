import sys

file_path = r'd:\game-dev\homasim-godot\scenes\character\CharacterEdit.tscn'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('parent="Center/Card/VBox', 'parent="Center/Card/Margin/VBox')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
