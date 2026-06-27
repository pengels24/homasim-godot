import os

file_path = r'd:\game-dev\homasim-godot\changelog\gd-0.1.29.md'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

features = '''- **Vollstndige Ingame-Lokalisierung'''
new_features = '''- **Erklärbär-Popup (Disclaimer)**: Beim Start des Spiels wird nun ein Popup eingeblendet, das den Spieler darüber aufklärt, dass es sich um eine frühe Tech-Demo handelt (Bugs, fehlendes Balancing, Platzhalter etc. zu erwarten). Eine "Nicht mehr anzeigen"-Option speichert die Entscheidung dauerhaft im Profil.
- **TechDemo-Wasserzeichen**: Das Hauptmenü zeigt nun ein rotierendes, halbtransparentes "TECHDEMO"-Wasserzeichen unten rechts an.
- **Vollstndige Ingame-Lokalisierung'''

content = content.replace(features, new_features)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated gd-0.1.29.md")