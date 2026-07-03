"""ANG-209: Neue Translations für Savegame Overwrite"""
csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

with open(csv_path, encoding='utf-8') as f:
    content = f.read()

new_keys = [
    '"modal.save.overwrite.title","Spielstand überschreiben?","Overwrite Save Game?"',
    '"modal.save.overwrite.message","Möchtest du den Spielstand wirklich überschreiben?","Do you really want to overwrite this save game?"',
    '"btn.save.overwrite","Überschreiben","Overwrite"',
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
