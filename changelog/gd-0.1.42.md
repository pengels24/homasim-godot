# Homasim Godot Changelog v0.1.42

## Features & Verbesserungen
- Snack-Automat in der Lobby hinzugefügt (wird ab Level 2 sichtbar).
- Gäste mit Hunger und Budget nutzen den Automaten (kauft Snack für 5€, bringt 3 EXP, +20% Sättigung).
- Die Level 3 EXP-Hürde kann jetzt für das Balancing beibehalten werden, da hungrige Gäste frühzeitig am Automaten versorgt werden.
- Text im Level-Up (Level 2) um Hinweis auf den Snack-Automaten ergänzt.

## Bugfixes
- Absturz bei der Gäste-Tagesablauf-Routinesteuerung behoben (fehlerhafte Abfrage auf "energy").
- Crash durch falschen Aufruf im TimeManager korrigiert.
- Lobby Tooltip reaktiviert, der durch fehlerhaft überschriebene `_ready` Funktion kaputtgegangen war.
- Vending-Machine Sichtbarkeit unabhängig vom Spiel-Pausen-Modus gemacht.
