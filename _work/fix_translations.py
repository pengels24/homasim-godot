"""ANG-230: Transaction-Beschreibungen als Keys + neue Kategorien"""
csv_path = r'D:\game-dev\homasim-godot\translations\language.csv'

with open(csv_path, encoding='utf-8') as f:
    content = f.read()

new_keys = [
    # Transaction description keys (format: "Prefix: %s" or "Prefix: %s (%s)")
    '"tx.build","Bau: %s","Build: %s"',
    '"tx.auto_demolish","Auto-Abriss: %s","Auto-Demolish: %s"',
    '"tx.demolish","Abriss: %s","Demolish: %s"',
    '"tx.checkout","Checkout: %s","Checkout: %s"',
    '"tx.supply","Warenverbrauch: %s (%s Besuche)","Supply costs: %s (%s visits)"',
    '"tx.poi_income","%s - Besuch: %s","%s - Visit: %s"',
    '"tx.level_up_bonus","Level-Up Bonus","Level-Up Bonus"',
    '"tx.hire","Einstellungsgebuehr: %s (%s)","Hire fee: %s (%s)"',
    '"tx.daily_wages","Tagesgehaelter","Daily wages"',
    '"tx.research","Forschung: %s","Research: %s"',
    # Category label for "betrieb"
    '"finances.cat.label.betrieb","Betrieb/POI","Operations/POI"',
]

added = []
for key_line in new_keys:
    key = key_line.split(',')[0].strip('"')
    if '"' + key + '"' not in content:
        added.append(key_line)

content = content.rstrip('\r\n') + '\r\n\r\n' + '\r\n'.join(added) + '\r\n'
with open(csv_path, 'w', encoding='utf-8', newline='') as f:
    f.write(content)

print(f'{len(added)} keys added:')
for k in added:
    print('  +', k.split(',')[0])
