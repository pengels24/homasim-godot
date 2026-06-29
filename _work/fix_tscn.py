import os
import re

# Fix SimBrowserTile.tscn
with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.tscn', 'r', encoding='utf-8') as f:
    tile = f.read()

# Remove the broken ExtResource 2
tile = re.sub(r'\[ext_resource type="StyleBox".*?id="2_style"\]\n', '', tile)
# Remove the style overrides that used ExtResource 2
tile = re.sub(r'theme_override_styles/\w+ = ExtResource\("2_style"\)\n', '', tile)
# Add theme_type_variation to Button
tile = tile.replace('[node name="SimBrowserTile" type="Button"]', '[node name="SimBrowserTile" type="Button"]\ntheme_type_variation = &"InnerPanel"')

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowserTile.tscn', 'w', encoding='utf-8') as f:
    f.write(tile)

# Fix SimBrowser.tscn
with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.tscn', 'r', encoding='utf-8') as f:
    browser = f.read()

# Remove broken ExtResource 2
browser = re.sub(r'\[ext_resource type="StyleBox".*?id="2_modal"\]\n', '', browser)
# Replace panel with theme variation
browser = browser.replace('theme_override_styles/panel = ExtResource("2_modal")', 'theme_type_variation = &"ModalPanel"')

with open('d:/game-dev/homasim-godot/scenes/ingame/SimBrowser.tscn', 'w', encoding='utf-8') as f:
    f.write(browser)

print("Fixed scenes")
