import os
import re

files_to_fix = [
    r'd:\game-dev\homasim-godot\scenes\ingame\IngameBuild.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\build\DemolishCursor.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\guest\GuestActor.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\CustomTooltip.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\RoomContextMenu.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\cards\RoomCardAvailable.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\map\MapGrid.gd',
    r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentRoomList.gd'
]

for file_path in files_to_fix:
    if not os.path.exists(file_path):
        continue
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match def.get("name", "...") and wrap it with GameState.T()
    # Be careful not to wrap if it's already wrapped
    # Actually, let's just replace all occurrences of def.get("name", ...) that are not preceded by GameState.T(
    
    # regex: (?<!GameState\.T\()\b(r_def|def|poi_def)\.get\(\"name\"(?:,\s*[^)]+)?\)
    
    new_content = re.sub(r'(?<!GameState\.T\()\b(r_def|def|poi_def)\.get\(\"name\"(?:,\s*[^)]+)?\)', r'GameState.T(\g<0>)', content)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {os.path.basename(file_path)}")

print('Finished wrapping def.get(\"name\")')