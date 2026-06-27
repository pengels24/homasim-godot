import os

file_path = r'd:\game-dev\homasim-godot\scenes\main_menu\ModalContentDisclaimer.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''    if check_dont_show.button_pressed:
        var config = SaveManager.load_global_config()
        config["dont_show_disclaimer"] = true
        SaveManager.save_global_config(config)'''
        
new_code = '''    if check_dont_show.button_pressed:
        SettingsManager.dont_show_disclaimer = true
        SettingsManager.save()'''

content = content.replace(old_code, new_code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Fixed ModalContentDisclaimer.gd")