import json
import os
import re

# 1. Update tutorials.json
tut_path = 'd:/game-dev/homasim-godot/config/tutorials.json'
with open(tut_path, 'r', encoding='utf-8') as f:
    tut_data = json.load(f)

# check if codex_poi already exists
exists = False
for item in tut_data.get('tutorials', []):
    if item.get('id') == 'codex_poi':
        exists = True

if not exists:
    tut_data['tutorials'].append({
        'id': 'codex_poi',
        'category': 'real_codex',
        'title_key': 'codex.poi.title',
        'desc_key': 'codex.poi.desc',
        'image': 'res://assets/icons/guests/map-pin.svg'
    })
    with open(tut_path, 'w', encoding='utf-8') as f:
        json.dump(tut_data, f, indent=4)


# 2. Update language.csv
lang_path = 'd:/game-dev/homasim-godot/translations/language.csv'
with open(lang_path, 'r', encoding='utf-8') as f:
    lang_content = f.read()

if 'codex.poi.title' not in lang_content:
    with open(lang_path, 'a', encoding='utf-8') as f:
        f.write('codex.poi.title,Point of Interest (POI),Point of Interest (POI)\n')
        f.write('codex.poi.desc,\"Ein Point of Interest (POI) ist ein öffentlicher Bereich im Hotel, der für alle Gäste zugänglich ist, wie zum Beispiel die Lobby, Flure oder Aufenthaltsbereiche. Im Gegensatz zu Gästezimmern, die exklusiv gebucht werden, können POIs durch Upgrades (wie z.B. WLAN oder Klimaanlagen) aufgewertet werden, um die allgemeine Zufriedenheit aller Gäste im Hotel zu steigern.\",\"A Point of Interest (POI) is a public area in the hotel accessible to all guests, such as the lobby, corridors, or lounge areas. Unlike guest rooms, which are booked exclusively, POIs can be upgraded (e.g., with Wi-Fi or air conditioning) to increase the overall satisfaction of all guests in the hotel.\"\n')


# 3. Update ModalContentTutorials.gd
gd_path = 'd:/game-dev/homasim-godot/scenes/ingame/hud/modals/content/ModalContentTutorials.gd'
with open(gd_path, 'r', encoding='utf-8') as f:
    gd_content = f.read()

gd_content = gd_content.replace(
    'elif _current_tab == "real_codex":\n\t\t\t_tutorials = [] # Empty for now',
    'elif _current_tab == "real_codex":\n\t\t\t_tutorials = TutorialManager.get_all_data_for_category(_current_tab)'
)

# Remove the real_codex block if it exists
gd_content = re.sub(r'\n\telif _current_tab == "real_codex":\n\t\t_clear_display\(\)\n\t\ttitle_label\.text = GameState\.T\("ui\.tutorial\.tab\.codex", "Codex"\)\n\t\tdesc_label\.text = GameState\.T\("ui\.tutorial\.codex\.intro", "[^"]+"\)\n\t\ttexture_rect\.texture = preload\("res://assets/icons/HUDBottom/flask-conical\.svg"\)\n\t\ttexture_rect\.show\(\)', '', gd_content)

with open(gd_path, 'w', encoding='utf-8') as f:
    f.write(gd_content)

print('POI Codex Entry Added.')
