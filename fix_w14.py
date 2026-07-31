import os

path = 'd:/game-dev/homasim-godot/translations/language.csv'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if line.startswith('techtree.wellness.w14.desc'):
        new_lines.append('techtree.wellness.w14.desc,"Schaltet den kleinen Fitnessraum frei und erweitert die Öffnungszeiten für das Hallenbad. Ermöglicht später zudem lukrative All-Inclusive Wellness-Buchungen über das Online-Portal.","Unlocks the small fitness room and extends the opening hours for the indoor pool. Also enables lucrative all-inclusive wellness bookings via the online portal later."\n')
    else:
        new_lines.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
