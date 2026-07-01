import re

file_path = r'd:\game-dev\homasim-godot\scenes\ingame\scripts\managers\TutorialScenarioManager.gd'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

replacements = {
    r'_show_text\("Hallo! Ich bin Angelus2010, der Entwickler von HO·MA·SIM.\nIch helfe dir bei deinen ersten Schritten.", true\)': r'_show_text(GameState.T("tutorial.step.1"), true)',
    r'_show_text\("Zuerst müssen wir uns umsehen können.\\nBewege die Karte mit der rechten Maustaste \(halten & ziehen\) oder mit WASD.\\n\\n\[ \] Karte bewegt", false\)': r'_show_text(GameState.T("tutorial.step.2"), false)',
    r'_show_text\("Zuerst müssen wir uns umsehen können.\\nBewege die Karte mit der rechten Maustaste \(halten & ziehen\) oder mit WASD.\\n\\n\[x\] Karte bewegt", true\)': r'_show_text(GameState.T("tutorial.step.2_done"), true)',
    r'_show_text\("Gut gemacht!\\nNutze nun das Mausrad oder die \+/- Tasten auf dem Numpad, um rein- und rauszuzoomen.\\n\\n\[ \] Gezoomt", false\)': r'_show_text(GameState.T("tutorial.step.3"), false)',
    r'_show_text\("Gut gemacht!\\nNutze nun das Mausrad oder die \+/- Tasten auf dem Numpad, um rein- und rauszuzoomen.\\n\\n\[x\] Gezoomt", true\)': r'_show_text(GameState.T("tutorial.step.3_done"), true)',
    r'_show_text\("Beginnen wir mit dem Wichtigsten: Zimmern!\\nÖffne unten im Menü den Bau-Modus \(oder drücke F2\).", false\)': r'_show_text(GameState.T("tutorial.step.4"), false)',
    r'_show_text\("Wähle ein Einzelzimmer und platziere es. Nutze \[R\] zum Rotieren, bis es passt!", false\)': r'_show_text(GameState.T("tutorial.step.5"), false)',
    r'_show_text\("Super! Wir brauchen aber mehr als ein Zimmer. Baue noch ein weiteres Einzelzimmer daneben.", false\)': r'_show_text(GameState.T("tutorial.step.6"), false)',
    r'_show_text\("Super! Schließe nun das Baumenü \(z.B. mit Rechtsklick oder ESC\).", false\)': r'_show_text(GameState.T("tutorial.step.7"), false)',
    r'_show_text\("Die Rezeption hat, wie auch andere POI \(Points of Interest\), Öffnungszeiten. Sie öffnet um 7 Uhr und schließt um 22 Uhr.\\nWährend dieser Zeit kommen neue Gäste an und bestehende Gäste nutzen diese POI für ihren Tagesablauf.", true\)': r'_show_text(GameState.T("tutorial.step.8"), true)',
    r'_show_text\("Starte nun die Zeit \(oben rechts im Menü oder mit der Leertaste\), um das Hotel zum Leben zu erwecken!", false\)': r'_show_text(GameState.T("tutorial.step.9"), false)',
    r'_show_text\("Warte nun, bis die Rezeption um 7 Uhr öffnet.", false\)': r'_show_text(GameState.T("tutorial.step.10_wait"), false)',
    r'_show_text\("Um neue Räume und Funktionen freizuschalten, musst du das Level des Hotels erhöhen.\\nHierfür benötigst du EXP. Diese bekommst du für den jeweils ersten Bau eines neuen Zimmertyps und für Ereignisse im Hotelbetrieb \(Check-In, Check-Out, u.a.\).", true\)': r'_show_text(GameState.T("tutorial.step.11"), true)',
    r'_show_text\("Baue nun, um noch einmal extra EXP zu bekommen, ein erstes Doppelzimmer.", false\)': r'_show_text(GameState.T("tutorial.step.12"), false)',
    r'_show_text\("Klasse! Schließe das Baumenü wieder.", false\)': r'_show_text(GameState.T("tutorial.step.13"), false)',
    r'_show_text\("Die Rezeption ist nun geöffnet. Um 8 Uhr treffen die ersten Gäste ein!\\nStarte die Zeit \(falls pausiert\) und warte auf ihre Ankunft.", false\)': r'_show_text(GameState.T("tutorial.step.14_wait"), false)',
    r'_show_text\("Schau, da kommen die ersten Gäste!\\nÖffne nun die Rezeption unten im Menü \(oder drücke F3\).", false\)': r'_show_text(GameState.T("tutorial.step.15"), false)',
    r'_show_text\("Links siehst du die neuen Gäste mit pulsierendem Rahmen. Sie warten nun darauf, von dir ein Zimmer zu bekommen.", true\)': r'_show_text(GameState.T("tutorial.step.16"), true)',
    r'_show_text\("Klicke einen Gast an und wähle eins der passenden Zimmer...\\nChecke die Gäste ein und schließe danach die Rezeption, um fortzufahren.", false\)': r'_show_text(GameState.T("tutorial.step.17"), false)',
    r'_show_text\("Du hast noch keinen Gast eingecheckt!\\nÖffne die Rezeption erneut und weise den Gästen Zimmer zu.", false\)': r'_show_text(GameState.T("tutorial.step.17_error"), false)',
    r'_show_text\("Wie du bestimmt gemerkt hast, konntest du während des Gäste-Checkins weitere EXP sammeln und du hattest dein erstes Levelup.", true\)': r'_show_text(GameState.T("tutorial.step.18"), true)',
    r'_show_text\("Da du nun Level 2 bist, kannst du die Personal-Agentur besuchen. Dort findest du deine Angestellten, neue Bewerber und den Bereich um deine Leute den POI zuzuweisen.", true\)': r'_show_text(GameState.T("tutorial.step.19"), true)',
    r'_show_text\("Öffne nun die Personal-Agentur unten im Menü \(oder drücke F4\).", false\)': r'_show_text(GameState.T("tutorial.step.20"), false)',
    r'_show_text\("Wechsle nun bitte auf den Reiter mit den Bewerbern.", false\)': r'_show_text(GameState.T("tutorial.step.21"), false)',
    r'_show_text\("Öffne die Personal-Agentur und wechsle auf den Reiter mit den Bewerbern.", false\)': r'_show_text(GameState.T("tutorial.step.21_alt"), false)',
    r'_show_text\("Du kannst hier Leute einstellen. Klicke dazu auf einen passenden Listeneintrag und dann rechts im Detailfenster auf einstellen.", true\)': r'_show_text(GameState.T("tutorial.step.22"), true)',
    r'_show_text\("Du benötigst zu Beginn je 1x Personal für Reinigung und 1x Personal für den Hausmeisterbereich.", true\)': r'_show_text(GameState.T("tutorial.step.23"), true)',
    r'_show_text\("Stelle nun je eine Person für die Reinigung und die Haustechnik ein.", false\)': r'_show_text(GameState.T("tutorial.step.24"), false)',
    r'_show_text\("Hervorragend! Schließe nun die Personalverwaltung wieder. Ab sofort werden automatisch für diese beiden Bereiche Tickets erstellt und abgearbeitet.", false\)': r'_show_text(GameState.T("tutorial.step.25"), false)'
}

for pattern, repl in replacements.items():
    content = re.sub(pattern, repl, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done replacing.")
