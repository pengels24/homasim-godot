import os

csv_path = r'd:\game-dev\homasim-godot\translations\language.csv'

de_text = '''Schön, dass du dabei bist! Bevor du dein erstes Hotel baust, ein kleiner Hinweis vorab: Du spielst hier eine frühe Tech-Demo (also vom Entwicklungsstand noch weit vor einer ersten Alpha-Version). Das bedeutet, das Fundament steht, aber der Putz trocknet noch.\n\nBitte behalte während des Spielens folgende Dinge im Hinterkopf:\n\n[b]Ecken und Kanten:[/b] Du wirst mit Sicherheit auf Bugs, Glitches oder noch nicht ganz ausbalancierte Mechaniken stoßen.\n\n[b]Work in Progress:[/b] Viele Grafiken, Animationen und UI-Elemente sind noch Platzhalter und spiegeln nicht die finale Qualität wider.\n\n[b]Dein Feedback ist Gold wert:[/b] Auf der rechten Bildschirmseite findest du einen \"Bug melden\"-Button. Bitte nutze ihn ausgiebig! Egal ob du einen Fehler gefunden hast, Kritik äußern möchtest oder eine coole Idee für ein Feature hast – lass es mich wissen.\n\nVielen Dank, dass du meine Solo-Entwicklung spielst und dieses Projekt mit deiner Zeit und deinem Feedback unterstützt. Viel Spaß beim Bauen!'''

en_text = '''Great to have you here! Before you build your first hotel, a quick heads-up: You are playing an early tech demo (which means the development state is still well before a first Alpha version). This means the foundation is laid, but the paint is still drying.\n\nPlease keep the following things in mind while playing:\n\n[b]Rough Edges:[/b] You will definitely encounter bugs, glitches, or mechanics that are not fully balanced yet.\n\n[b]Work in Progress:[/b] Many graphics, animations, and UI elements are still placeholders and do not reflect the final quality.\n\n[b]Your Feedback is Gold:[/b] On the right side of the screen, you will find a \"Report Bug\" button. Please use it extensively! Whether you've found a bug, have some constructive criticism, or a cool idea for a feature – let me know.\n\nThank you so much for playing my solo-developed game and supporting this project with your time and feedback. Have fun building!'''

# Replace newlines with \n for the CSV (we can use \n in the string if we want, Godot handles it)
# Wait, Godot CSV requires actual newlines to be inside quotes, OR escaped.
# Actually, the best way is to keep it inside double quotes. But since Godot's TranslationServer parses standard CSV:
# "key","value","value" -> newlines inside quotes are parsed as actual newlines.
de_csv = de_text.replace('\n', '\\n').replace('\"', '\"\"')
en_csv = en_text.replace('\n', '\\n').replace('\"', '\"\"')

lines = [
    '\n"ui.disclaimer.title","Willkommen bei der HO·MA·SIM Tech-Demo!","Welcome to the HO·MA·SIM Tech Demo!"',
    f'"ui.disclaimer.text","{de_csv}","{en_csv}"',
    '"ui.disclaimer.dont_show","Beim nächsten Mal nicht mehr anzeigen","Do not show this again"',
    '"ui.disclaimer.ok","Verstanden!","Got it!"'
]

with open(csv_path, 'a', encoding='utf-8') as f:
    f.write('\n'.join(lines))
    f.write('\n')

print("Added to CSV")