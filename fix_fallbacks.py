import os
import re

files_to_fix = [
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentGuestList.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentRoomList.gd',
]

for file_path in files_to_fix:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = re.sub(r'GameState\.T\(\"([^\"]+)\"\s*,\s*\"[^\"]+\"\)', r'GameState.T(\"\1\")', content)
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

print('Replaced fallbacks in GuestList and RoomList')