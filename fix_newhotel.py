import re

file_path = r"d:\game-dev\homasim-godot\scenes\shared\NewHotelModal.gd"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_func = """func _set_difficulty(level: int) -> void:
	_btn_easy.modulate = Color(1, 1, 1)
	_btn_normal.modulate = Color(1, 1, 1)
	_btn_hard.modulate = Color(1, 1, 1)
	_btn_custom.modulate = Color(1, 1, 1)
	
	_btn_easy.add_theme_stylebox_override("normal", _golden_pressed if level == 0 else _dark_normal)
	_btn_normal.add_theme_stylebox_override("normal", _golden_pressed if level == 1 else _dark_normal)
	_btn_hard.add_theme_stylebox_override("normal", _golden_pressed if level == 2 else _dark_normal)
	_btn_custom.add_theme_stylebox_override("normal", _golden_pressed if level == 3 else _dark_normal)
	
	# Inputs nur in "Angepasst" aktivieren
	_btn_money_l.disabled = (level != 3)
	_btn_money_r.disabled = (level != 3)
	
	match level:"""

content = re.sub(r'func _set_difficulty\(level: int\) -> void:.*?match level:', new_func, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
