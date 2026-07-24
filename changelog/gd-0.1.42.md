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
- Personal-Laufwege: Gast positioniert sich nun präziser links vom Automaten.

## Phase 3.1 & 3.1b: Personal-Management & Pausenraum
- Personal-Kapazität ist jetzt an die Anzahl gebauter Pausenräume gekoppelt (4 Mitarbeiter pro Raum). Ohne Pausenraum können keine weiteren Mitarbeiter eingestellt werden.
- Mitarbeiter spawnen direkt im Pausenraum (wenn vorhanden) und verbringen dort nach Schichtende ihren Feierabend.
- Sinkt die Moral ("energy" -> "Sättigung/Moral") unter einen dynamischen Schwellenwert, macht das Personal von selbst Pause und legt sich auf ein Bett / Sofa im Pausenraum.
- Personal nimmt während der Pause keine Jobs an, bis die Moral wieder ausreicht. Betten regenerieren Moral doppelt so schnell wie Sofas.
- Warn-System eingebaut: Ein Info-Modal warnt beim Spielstart, falls durch alte Savegames mehr Personal vorhanden ist, als Pausenräume gebaut wurden (Rückwärtskompatibilität gewahrt).
- Neue UI-Komponente "InfoModal" auf Basis des ConfirmModals etabliert.
