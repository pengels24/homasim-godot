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

## Übergabe für die nächste Session
- Die Logik für Rezeption, Check-in, Check-out und die Strafen funktioniert nun lückenlos und sauber getaktet.
- Als nächstes kann der Tagesablauf der Gäste im Hotel (z.B. Restaurant, Wegfindung tagsüber) weiter ausgebaut werden.
