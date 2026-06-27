import os

file_path = r'd:\game-dev\homasim-godot\translations\language.csv'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace *** with ### in the specific reception tooltips
content = content.replace('"Gruppe: *** Person(en)","Group: *** Person(s)"', '"Gruppe: ### Person(en)","Group: ### Person(s)"')
content = content.replace('"Noch *** Nacht(e)","*** Night(s) left"', '"Noch ### Nacht(e)","### Night(s) left"')
content = content.replace('"Zufriedenheit: ***%","Satisfaction: ***%"', '"Zufriedenheit: ###%","Satisfaction: ###%"')

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed placeholders in language.csv')