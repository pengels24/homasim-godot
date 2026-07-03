"""ANG-209: Neue Translations für Loadgame Confirm"""
csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

with open(csv_path, encoding='utf-8') as f:
    content = f.read()

new_keys = [
    '"modal.load.confirm.title","Spielstand laden?","Load Save Game?"',
    '"modal.load.confirm.message","Möchtest du diesen Spielstand wirklich laden? Nicht gespeicherter Fortschritt geht verloren.","Do you really want to load this save game? Unsaved progress will be lost."',
    '"btn.load.confirm","Spiel laden","Load Game"',
]

added = []
for key_line in new_keys:
    key = key_line.split(',')[0].strip('"')
    if '"' + key + '"' not in content:
        added.append(key_line)

if added:
    content = content.rstrip('\r\n') + '\r\n\r\n' + '\r\n'.join(added) + '\r\n'
    with open(csv_path, 'w', encoding='utf-8', newline='') as f:
        f.write(content)

print(f'{len(added)} keys added.')
