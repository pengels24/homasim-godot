import json

csv_path = r"d:\game-dev\homasim-godot\translations\language.csv"

# 1. Update CSV
with open(csv_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if line.startswith("tutorial.welcome.desc"):
        skip = True
        de_text = "Willkommen in deinem neuen Hotel - hier ein kurzer Überblick:\\nOben: Deine wichtigsten Laufdaten wie Finanzen und Gäste, sowie die Zeitsteuerung.\\nUnten mittig: Die zentralen Hauptmenüs (Bauen, Management, Forschung, etc.).\\nLinks: Overlays für zusätzliche Hotel-Daten (Personal, Gäste, Zimmer, Finanzen).\\nKamera-Steuerung: Mit WASD bewegst du die Kamera und mit dem Mausrad steuerst du den Zoom."
        en_text = "Welcome to your new hotel - here is a brief overview:\\nTop: Your most important running data like finances and guests, as well as time control.\\nBottom center: The main core menus (Building, Management, Research, etc.).\\nLeft edge: Overlays for additional hotel data (Staff, Guests, Rooms, Finances).\\nCamera control: Use WASD to move the camera and the mouse wheel to control the zoom."
        new_lines.append(f'tutorial.welcome.desc,"{de_text}","{en_text}"\n')
    elif skip and not line.startswith("tutorial.") and not line.startswith("ui.") and not line.startswith("codex.") and not line.startswith("quest.") and not line.startswith("roomdef."):
        # Skip the continuation lines of the old multiline tutorial.welcome.desc
        continue
    else:
        skip = False
        new_lines.append(line)

# Add new keys
new_lines.append('tutorial.hotel_overview.title,Hotel-Übersicht,Hotel Overview\n')
new_lines.append('tutorial.hotel_overview.desc,"Die Hotel-Übersicht (F9) ist dein zentrales Dashboard.\\n\\nHier siehst du alle wichtigen Statistiken deines Hotels auf einen Blick. Dazu gehören die aktuelle Zufriedenheit deiner Gäste, die Sauberkeit, Einnahmen und Ausgaben, sowie eine Zusammenfassung deines Personals und der Zimmer.\\nNutze diese Ansicht regelmäßig, um Probleme frühzeitig zu erkennen.","The Hotel Overview (F9) is your central dashboard.\\n\\nHere you can see all important statistics of your hotel at a glance. This includes current guest satisfaction, cleanliness, income and expenses, as well as a summary of your staff and rooms.\\nUse this view regularly to spot problems early."\n')

new_lines.append('tutorial.overlays.title,Daten-Overlays,Data Overlays\n')
new_lines.append('tutorial.overlays.desc,"Am linken Bildschirmrand findest du die Overlay-Leiste.\\n\\nMit diesen Schaltern kannst du dir wertvolle Informationen direkt in der Spielwelt einblenden lassen.\\nLass dir beispielsweise anzeigen, welche Gäste aktuell unzufrieden sind, wo dein Personal gerade arbeitet, welche Räume dreckig sind oder wo sich Schmutz ansammelt. Die Overlays sind ein wichtiges Analyse-Werkzeug!","On the left edge of the screen you will find the Overlay bar.\\n\\nThese switches allow you to display valuable information directly in the game world.\\nFor example, you can see which guests are currently dissatisfied, where your staff is working, which rooms are dirty or where dirt is accumulating. The overlays are an important analysis tool!"\n')

with open(csv_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)


# 2. Update JSON
json_path = r"d:\game-dev\homasim-godot\config\tutorials.json"
with open(json_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

# Insert after sim_browser
insert_idx = 0
for i, item in enumerate(data["tutorials"]):
    if item.get("id") == "sim_browser":
        insert_idx = i + 1
        break

hotel_overview_entry = {
    "id": "hotel_overview",
    "title_key": "tutorial.hotel_overview.title",
    "desc_key": "tutorial.hotel_overview.desc",
    "image": "res://assets/images/tutorials/tutorial_finances.png"
}
overlays_entry = {
    "id": "overlays",
    "title_key": "tutorial.overlays.title",
    "desc_key": "tutorial.overlays.desc",
    "image": "res://assets/images/tutorials/tutorial_build_mode.png"
}

data["tutorials"].insert(insert_idx, overlays_entry)
data["tutorials"].insert(insert_idx, hotel_overview_entry)

with open(json_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=4)

print("HUD tutorials updated in CSV and JSON!")
