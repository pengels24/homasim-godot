import os

file_path = r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentTechtree.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# I need to add @onready var fp_icon: Label = /FPContainer/Margin/HBox/FPIcon or just change the text on ready.
# Wait, let's see if there is a _ready() function.