"""ANG-222: Neue Translations für Gast-Ablehnung"""
csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

with open(csv_path, encoding='utf-8') as f:
    content = f.read()

new_keys = [
    '"reception.decline.title","Gast abweisen?","Decline Guest?"',
    '"reception.decline.message","Möchtest du %s wirklich abweisen?\n\nDas kostet dich %s Ruf.","Do you really want to decline %s?\n\nThis will cost you %s reputation."',
    '"btn.decline","Abweisen","Decline"',
    '"btn.cancel","Abbrechen","Cancel"',
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
