import os
import re

path = r'd:\game-dev\homasim-godot\scenes\main_menu\MainMenu.tscn'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# Add ext_resource if not exists
if 'Dashboard.tscn' not in text:
    lines = text.split('\n')
    idx = 0
    for i, line in enumerate(lines):
        if line.startswith('[ext_resource'):
            idx = i
    lines.insert(idx + 1, '[ext_resource type="PackedScene" path="res://scenes/dashboard/Dashboard.tscn" id="99_dashboard"]')
    text = '\n'.join(lines)

# Add node at the end if not exists
if 'DashboardModal' not in text:
    text += '\n[node name="DashboardModal" parent="." instance=ExtResource("99_dashboard")]\nvisible = false\nlayout_mode = 1\n'

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print("MainMenu.tscn modified!")
