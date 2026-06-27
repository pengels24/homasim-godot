import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\MainMenu.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''func _check_disclaimer() -> void:
\tvar config = SaveManager.load_global_config()
\tif not config.get("dont_show_disclaimer", false):
\t\t_disclaimer_modal.set_content("res://scenes/main_menu/ModalContentDisclaimer.tscn")
\t\t_disclaimer_modal.open(GameState.T("ui.disclaimer.title"))'''

new_code = '''func _check_disclaimer() -> void:
\tif not SettingsManager.dont_show_disclaimer:
\t\t_disclaimer_modal.set_content("res://scenes/main_menu/ModalContentDisclaimer.tscn")
\t\t_disclaimer_modal.open(GameState.T("ui.disclaimer.title"))'''

content = content.replace(old_code, new_code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed MainMenu.gd disclaimer logic")