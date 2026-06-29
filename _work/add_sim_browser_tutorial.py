import json

# 1. Update tutorials.json
config_path = 'd:/game-dev/homasim-godot/config/tutorials.json'
with open(config_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# check if sim_browser already exists
exists = any(t['id'] == 'sim_browser' for t in data['tutorials'])
if not exists:
    data['tutorials'].insert(9, {
        "id": "sim_browser",
        "title_key": "tutorial.sim_browser.title",
        "desc_key": "tutorial.sim_browser.desc",
        "image": "res://assets/images/tutorials/tutorial_build_mode.png"
    })
    
with open(config_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4, ensure_ascii=False)


# 2. Append to de.csv
csv_path = 'd:/game-dev/homasim-godot/translations/de.csv'
with open(csv_path, 'a', encoding='utf-8') as f:
    f.write('''"tutorial.sim_browser.title","SimBrowser",""
"tutorial.sim_browser.desc","Dein persönliches In-Game Web-Portal. Hier findest du Bewertungen, Statistiken und Lieferanten. Tipp: Achte auf versteckte URLs!",""\n''')

print("Added sim_browser to tutorials.json and de.csv")
