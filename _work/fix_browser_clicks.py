import re

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.tscn', 'r', encoding='utf-8') as f:
    browser = f.read()

# Add process_mode = 3 (Always) to root node so clicks work while paused
if 'process_mode = 3' not in browser:
    browser = browser.replace('visible = false\n', 'visible = false\nprocess_mode = 3\n')

# Define SubResource
sub_resource = """[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_sim"]
bg_color = Color(0.0705882, 0.0784314, 0.129412, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.917647, 0.701961, 0.0313726, 1)

"""

# Insert SubResource after the first script ExtResource
if 'StyleBoxFlat_sim' not in browser:
    browser = re.sub(r'(\[ext_resource.*?\]\n)', r'\1\n' + sub_resource, browser, count=1)

# Replace theme_type_variation with theme_override_styles/panel
browser = re.sub(r'theme_type_variation = &"ModalPanel"\n', 'theme_override_styles/panel = SubResource("StyleBoxFlat_sim")\n', browser)

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.tscn', 'w', encoding='utf-8') as f:
    f.write(browser)

print("Fixed process_mode and style correctly")
