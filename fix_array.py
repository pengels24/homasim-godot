import re

with open(r'd:\game-dev\homasim-godot\scenes\ingame\staff\StaffActor.gd', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('_path = _map_grid.call("get_path_between_tiles", start_tile, end_tile)',
                          '_path.assign(_map_grid.call("get_path_between_tiles", start_tile, end_tile))')

with open(r'd:\game-dev\homasim-godot\scenes\ingame\staff\StaffActor.gd', 'w', encoding='utf-8') as f:
    f.write(content)
print("Replaced successfully!")
