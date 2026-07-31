import csv
import io
import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Using csv module to read/write safely
f = io.StringIO(content)
reader = csv.reader(f, lineterminator='\n')
rows = list(reader)

for row in rows:
    if len(row) > 0 and row[0].startswith('tutorial.room_') and row[0].endswith('.desc'):
        for i in range(1, len(row)):
            # Replace single newlines with double newlines before keywords
            text = row[i]
            
            # Make sure we don't add multiple newlines if they already exist
            # First normalize by removing existing extra newlines before the keywords
            text = text.replace('\n\nFunktion:', '\nFunktion:')
            text = text.replace('\n\nReferenzen zu anderen Räumen:', '\nReferenzen zu anderen Räumen:')
            text = text.replace('\n\nKosten:', '\nKosten:')
            text = text.replace('\n\nVoraussetzungen:', '\nVoraussetzungen:')
            
            # Now replace \n with \n\n
            text = text.replace('\nFunktion:', '\n\nFunktion:')
            text = text.replace('\nReferenzen zu anderen Räumen:', '\n\nReferenzen zu anderen Räumen:')
            text = text.replace('\nKosten:', '\n\nKosten:')
            text = text.replace('\nVoraussetzungen:', '\n\nVoraussetzungen:')
            
            # Also catch cases where they might be on the same line separated by a space
            text = text.replace(' Funktion:', '\n\nFunktion:')
            text = text.replace(' Referenzen zu anderen Räumen:', '\n\nReferenzen zu anderen Räumen:')
            text = text.replace(' Kosten:', '\n\nKosten:')
            text = text.replace(' Voraussetzungen:', '\n\nVoraussetzungen:')
            
            row[i] = text

out_f = io.StringIO()
writer = csv.writer(out_f, lineterminator='\n')
writer.writerows(rows)

with open(path, 'w', encoding='utf-8') as f:
    f.write(out_f.getvalue())

print('Formatting added.')
