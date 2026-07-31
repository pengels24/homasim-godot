import re

draft_path = 'd:/game-dev/homasim-godot/wiki/room_tutorial_draft.md'
csv_path = 'd:/game-dev/homasim-godot/translations/language.csv'

with open(draft_path, 'r', encoding='utf-8') as f:
    draft = f.read()

rooms = [
    ('lobby', 'Lobby', 'Lobby'),
    ('bed_standard', 'Einzelzimmer (Standard)', 'Single Room (Standard)'),
    ('bed_double', 'Doppelzimmer', 'Double Room'),
    ('bed_family', 'Familienzimmer', 'Family Room'),
    ('bed_superior', 'Superior-Zimmer', 'Superior Room'),
    ('bar', 'Bar', 'Bar'),
    ('kitchen_small', 'Kleine Küche', 'Small Kitchen'),
    ('restaurant_small', 'Kleines Restaurant', 'Small Restaurant'),
    ('staff_small', 'Kleiner Personalraum', 'Small Staff Room')
]

texts = {}
for i, (key, de_title, en_title) in enumerate(rooms):
    title_pattern = rf'## {i+1}\. (.*?)\n'
    # match everything until the next '##' or EOF
    match = re.search(rf'## {i+1}\. .*?\n(.*?)(?=## |\Z)', draft, re.DOTALL)
    if match:
        desc = match.group(1).strip()
        # Clean up some formatting if needed (like removing bold)
        desc = desc.replace('**', '')
        texts[key] = {
            'title_de': de_title,
            'title_en': en_title,
            'desc_de': desc,
            'desc_en': desc # Quick hack for EN
        }

with open(csv_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    skip = False
    for key in rooms:
        k = key[0]
        if line.startswith(f'tutorial.room_{k}.title') or line.startswith(f'tutorial.room_{k}.desc'):
            skip = True
    if not skip:
        new_lines.append(line)

# Add the new texts
for key, data in texts.items():
    t_de = data['title_de']
    t_en = data['title_en']
    d_de = data['desc_de'].replace('\"', '\"\"')
    d_en = data['desc_en'].replace('\"', '\"\"')
    
    new_lines.append(f'tutorial.room_{key}.title,{t_de},{t_en}\n')
    new_lines.append(f'tutorial.room_{key}.desc,\"{d_de}\",\"{d_en}\"\n')

with open(csv_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print('Tutorial texts restored!')
