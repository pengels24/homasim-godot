# Changelog v0.1.26 (Bugfix Session)

## Fixes & Verbesserungen
- **Savegame Zeitreise-Bug behoben:**
  - `GameState.selected_hotel` wird nun kurz vor dem Snapshot über `_on_hour_passed` aktualisiert. Dadurch wird die korrekte `game_time` in den Speicherstand geschrieben, bevor `SaveManager.save_auto()` den Dump macht.
- **Tagesabschluss (End-of-Day) Timing repariert:**
  - Der Trigger für das Modal wurde vom JSON-Fahrplan (23:59 Uhr) entkoppelt.
  - `Ingame.gd` reagiert nun auf das `sig_day_ended` Signal vom `TimeManager` (exakt um 24:00 Uhr). 
  - Die Mitternachts-Strafen (Rage-Quits) werden nun verarbeitet, **bevor** das Modal aufploppt, sodass die Zähler für Wut-Checkouts korrekt im Modal angezeigt werden, bevor sie am Morgen um 06:00 Uhr zurückgesetzt werden.
- **Toast-System überarbeitet (`Toast.gd`):**
  - Implementierung einer echten Warteschlange (`_toast_queue`). Wenn mehrere Toasts gleichzeitig feuern (z.B. "Hotelbetrieb endet" und "Gäste weggeschickt" um 22:00 Uhr), werden diese nun nacheinander abgespielt, anstatt sich gegenseitig zu überschreiben.
  - Den doppelten "Neuer Tag beginnt"-Toast aus `Ingame.gd` entfernt (da dies bereits durch die Cinematic abgedeckt ist).
  - Den überflüssigen, generischen "1 Gast haben nicht ausgecheckt"-Toast entfernt.
- **Kassenbuch-Logs / Legacy-Gäste-Bug analysiert:**
  - Die extrem niedrigen Zahlungen (1 €) von alten Gästen im Savegame wurden als Artefakt eines alten Datentyps identifiziert (Float 1.0 statt Int 100). Neue Gäste zahlen wieder voll.

- **Dashboard & UI Overhaul:**
  - Komplette Überarbeitung der Hotel-Auswahl (`DashboardHotelCard`): Die Kacheln haben nun ein einheitliches, abgerundetes Design (`corner_radius = 8`) mit Hover-Schatten und goldenem Rand.
  - Das "+"-Symbol zum Erstellen eines neuen Hotels ist nun als eigenständige, leere Karte ins Grid integriert und fügt sich nahtlos ins Layout ein.
  - **Pixel-Perfect Polishing**:
    - Abstände und Container-Offsets so angepasst, dass Thumbnails perfekt innerhalb der Ränder bleiben.
    - Die Höhe des Dashboard-Modals (`1700x970`) und die Container-Abstände so justiert, dass bei zwei Reihen kein unnötiger Scrollbar auftaucht.
  - **Scene Transitions & Root-Konflikte**:
    - Wenn nach dem Erstellen eines Managers oder dem Beenden des Spiels direkt das Dashboard aufgerufen wird, leitet die Logik nun ins `MainMenu.tscn` zurück. Dort wird das Dashboard über die Flag `GameState.open_dashboard_next` automatisch als sichtbares Modal (mit Hintergrund) eingeblendet, wodurch die "schwarzer Bildschirm"-Glitches der Vergangenheit angehören.
  - Interaktion komplett auf die Karten (`Button`) ausgelagert; dedizierter "Spielen"-Button wurde für ein aufgeräumteres Look & Feel entfernt.

## Übergabe für die nächste Session
- Dashboard ist "Feature Complete" und poliert.
- Als nächstes kann das `NewHotelModal` in der Textgröße leicht vergrößert werden (passt aktuell optisch nicht zum edlen großen Dashboard).
- Feature-Idee: Avatar im Dashboard nach links oben rücken und darunter Globale Statistiken (Spielzeit, Gesamteinnahmen, letztes Login) auflisten.
