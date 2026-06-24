import re

file_path = r"d:\game-dev\homasim-godot\scenes\shared\NewHotelModal.gd"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

new_update_grid = """	var door_icon = preload("res://assets/icons/door-open.svg")
	for py in GRID_ROWS:
		for px in GRID_COLS:
			var btn := _click_grid.get_child(_cell_index(px, py)) as Button
			
			if px == _selected_x and py == _selected_y:
				btn.text = ""
				btn.icon = door_icon
				btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
				btn.expand_icon = true
				
				btn.add_theme_color_override("icon_normal_color", Color(0.9, 0.7, 0.1))
				btn.add_theme_color_override("icon_pressed_color", Color(0.9, 0.7, 0.1))
				btn.add_theme_color_override("icon_hover_color", Color(0.9, 0.7, 0.1))
				btn.add_theme_color_override("icon_disabled_color", Color(0.9, 0.7, 0.1))
				btn.add_theme_color_override("icon_focus_color", Color(0.9, 0.7, 0.1))
			else:
				btn.text = ""
				btn.icon = null"""

content = re.sub(
    r'\tfor py in GRID_ROWS:\n\t\tfor px in GRID_COLS:\n\t\t\tvar btn := _click_grid\.get_child\(_cell_index\(px, py\)\) as Button\n\t\t\t\n\t\t\tif px == _selected_x and py == _selected_y:\n\t\t\t\tbtn\.text = _get_arrow_for_dir\(dir\)\n\t\t\t\tbtn\.add_theme_font_size_override\("font_size", 48\)\n\t\t\t\tbtn\.add_theme_color_override\("font_color", Color\(0\.9, 0\.7, 0\.1\)\) # Gelb\n\t\t\telse:\n\t\t\t\tbtn\.text = ""',
    new_update_grid,
    content
)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
