# Changelog: gd-0.1.47

## Neue Features & Inhaltspflege
- **Exploit-Fix Personal (ANG-324):** Pausenräume können nicht mehr abgerissen werden (weder per Cursor noch über Kontextmenü), wenn dadurch das Kapazitätslimit unter die Anzahl des aktuell eingestellten Personals sinkt.
- **Codex & Tutorial (Räume):** Der Reiter "Räume" wurde in den Ingame-Codex integriert. Spieler können dort jederzeit das Angebot der verfügbaren Räume als Bau-Katalog einsehen (ANG-320).
- **Räume Wiki:** Ausführliche Dokumentationen für Lobby, Einzelzimmer, Doppelzimmer, Familienzimmer, Superior-Zimmer, Bar, Küche und Restaurant im Ordner `wiki/rooms/` angelegt.
- **Nav-Points Dokumentiert:** `WayPoints` und `NavBlocker` der fertigen Basisräume (Lobby, Einzelzimmer, Doppelzimmer, Familienzimmer, Superior-Zimmer) in deren Wiki-Files referenziert.
- **Dev-Befehl:** `unlock-all-tutorials` zur DevConsole hinzugefügt, um alle Tutorial-Einträge ohne Spielfortschritt testen zu können.

## Code & System
- `TutorialManager.gd` um `get_all_data_for_category()` ergänzt, um im Codex alle Räume dauerhaft freizuschalten, während die regulären Tutorial-Popups weiterhin auf Trigger warten.
- `ModalContentTutorials.gd` auf 5 Tabs erweitert und Logik angepasst.

## Nächste Schritte (Backlog)
- Weitere Räume für den RoomNavigator finalisieren und deren NavBlocker eintragen.
- Laufende Linear-Issues (ANG-331, ANG-330, ANG-329) für den Techtree abarbeiten.
