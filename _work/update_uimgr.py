import re

with open('d:/game-dev/homasim-godot/scenes/ingame/scripts/managers/IngameUIManager.gd', 'r', encoding='utf-8') as f:
    text = f.read()

old_str = '''func close_build_menu() -> void:
	if _build:
		_build.close_all()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL'''

new_str = '''func close_build_menu() -> void:
	if _build:
		_build.close_all()
	if is_instance_valid(_map_grid):
		_map_grid.exit_buy_mode()
	InputHandler.current_mode = InputHandler.InputMode.NORMAL'''

text = text.replace(old_str, new_str)

with open('d:/game-dev/homasim-godot/scenes/ingame/scripts/managers/IngameUIManager.gd', 'w', encoding='utf-8', newline='\n') as f:
    f.write(text)
