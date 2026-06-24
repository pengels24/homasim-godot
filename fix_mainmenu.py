import re

with open(r'd:\game-dev\homasim-godot\scenes\main_menu\MainMenu.tscn', 'r', encoding='utf8') as f:
    content = f.read()

buttons = ["BtnPlay", "BtnSettings", "BtnLogin", "BtnManager", "BtnTutorial", "BtnCredits", "BtnQuit"]
for btn in buttons:
    pattern = r'(\[node name="' + btn + r'".*?\n(?:.*?\n)*?)(text = ".*?")'
    content = re.sub(pattern, r'theme_override_font_sizes/font_size = 56\n\2', content)

labels = ["VersionLbl", "MadeWithLbl", "CopyrightLbl"]
for lbl in labels:
    pattern = r'(\[node name="' + lbl + r'".*?\n(?:.*?\n)*?)(text = ".*?")'
    content = re.sub(pattern, r'theme_override_font_sizes/font_size = 24\n\2', content)

with open(r'd:\game-dev\homasim-godot\scenes\main_menu\MainMenu.tscn', 'w', encoding='utf8') as f:
    f.write(content)
