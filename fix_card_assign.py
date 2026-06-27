import os

file_path = r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\cards\CardAssignRoom.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    'lbl_status.text = "Kein Personal (%d/%d MitarbeiterInnen)" % [current, max_staff]',
    'lbl_status.text = GameState.T("ui.staff.assign.status.empty", current, max_staff)'
)
content = content.replace(
    'lbl_status.text = "Teilbesetzt (%d/%d MitarbeiterInnen)" % [current, max_staff]',
    'lbl_status.text = GameState.T("ui.staff.assign.status.partial", current, max_staff)'
)
content = content.replace(
    'lbl_status.text = "Vollbesetzt (%d MitarbeiterInnen)" % [current]',
    'lbl_status.text = GameState.T("ui.staff.assign.status.full", current)'
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed CardAssignRoom.gd translations')