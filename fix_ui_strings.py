import os

csv_path = r'd:\game-dev\homasim-godot\translations\language.csv'
with open(csv_path, 'a', encoding='utf-8') as f:
    f.write('\n"ui.techtree.current_fp","Aktuelle FP","Current RP"')
    f.write('\n"settings.language.main_menu_only","(nur im Hauptmenü)","(Main Menu only)"')

file1 = r'd:\game-dev\homasim-godot\scenes\shared\SettingsModal.gd'
with open(file1, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
    'lbl.text = lbl.text + "  ·  (nur im Hauptmenü)"',
    'lbl.text = lbl.text + "  ·  " + GameState.T("settings.language.main_menu_only")'
)
with open(file1, 'w', encoding='utf-8') as f:
    f.write(content)

file2 = r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentSettings.gd'
with open(file2, 'r', encoding='utf-8') as f:
    content = f.read()
content = content.replace(
    'lbl_lang.text = lbl_lang.text + "  ·  (nur im Hauptmenü)"',
    'lbl_lang.text = lbl_lang.text + "  ·  " + GameState.T("settings.language.main_menu_only")'
)
with open(file2, 'w', encoding='utf-8') as f:
    f.write(content)

file3 = r'd:\game-dev\homasim-godot\scenes\ingame\hud\modals\content\ModalContentTechtree.gd'
with open(file3, 'r', encoding='utf-8') as f:
    content = f.read()
new_func = '''func _on_fp_changed(new_fp: int) -> void:
\tif fp_label:
\t\tvar icon_lbl = fp_label.get_parent().get_node_or_null("FPIcon")
\t\tif icon_lbl:
\t\t\ticon_lbl.text = GameState.T("ui.techtree.current_fp") + ": "
\t\tfp_label.text = str(new_fp)
\tupdate_button_states()'''
content = content.replace(
'''func _on_fp_changed(new_fp: int) -> void:
\tif fp_label:
\t\tfp_label.text = str(new_fp)
\tupdate_button_states()''',
new_func)
with open(file3, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed UI strings!')