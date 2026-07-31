path = 'd:/game-dev/homasim-godot/translations/language.csv'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if 'ber die Pip-Cam' in line or 'Using the Pip-Cam' in line or 'tutorial.room_list.' in line:
        pass # Drop the bad lines
    elif 'tutorial.guest_list.desc' in line:
        pass # Drop the old one
    else:
        new_lines.append(line)

new_lines.append('tutorial.guest_list.desc,"Dies ist die Übersicht aller aktiven Gäste. Hier siehst du unter anderem die Zufriedenheit, den Aufenthaltsort und das Budget auf einen Blick.\\nÜber die Pip-Cam kannst du jeden aktiven Gast verfolgen und auch zu ihm springen.","This is the overview of all active guests. Here you can see, among other things, their satisfaction, location, and budget at a glance.\\nUsing the Pip-Cam, you can view the room and also jump directly to it."\n')
new_lines.append('tutorial.room_list.title,Die Raumliste,The Room List\n')
new_lines.append('tutorial.room_list.desc,"Diese Liste zeigt den Status aller Zimmer: Sauberkeit, Belegung und Zustand.\\nMit der Pip-Cam kannst du den Raum sehen und auch zu ihm springen.","This list shows the status of all rooms: cleanliness, occupancy, and condition.\\nUsing the Pip-Cam, you can view the room and also jump directly to it."\n')

with open(path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)
