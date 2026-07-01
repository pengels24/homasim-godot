# Changelog gd-0.1.31c

Datum: 2026-07-01

## Features & Verbesserungen
- **Tutorial überarbeitet:** Das Ingame-Tutorial wurde in seiner Ablauflogik deutlich robuster gestaltet, um Spielern einen flüssigen, fehlerfreien Start zu ermöglichen.
- **Tutorial UI-Hinweise:** Der Play-Button pulsiert nun golden als visueller Hinweis, wenn der Spieler die Zeit starten soll. Der Fast-Forward-Button wird in diesem Moment sicherheitshalber temporär blockiert.

## Bugfixes
- Fix: Das Schließen des Baumenüs im Tutorial wird nun korrekt und verzögerungsfrei als "Erledigt" registriert, ohne lästige Geister-Cursor an der Maus zu hinterlassen.
- Fix: Verwaiste blaue Blueprint-Geister (Markierungen für den Raum-Bau) werden nun sicher und aktiv gelöscht, anstatt sich mit Godots interner Auto-Namensgebung (`@TutorialBlueprint@2`) in die Quere zu kommen.
- Fix: Die Zeit pausiert im Tutorial nun zwingend um 7:00 Uhr morgens. Das verhindert, dass der Spieler ungewollt die 8-Uhr-Ereignisse auslöst, bevor er in Ruhe sein erstes Doppelzimmer bauen konnte.
- Fix: Das Verlassen des Tutorials speichert nun den gesamten Fortschritt (Kontostand, EXP, Uhrzeit) fehlerfrei mit ab. Zuvor wurde die Tutorial-Hotel-ID vom Speichersystem ignoriert, was zu einem Zeit-Reset beim Neuladen führte.

## Technische Änderungen
- `TutorialScenarioManager.gd` nutzt nun explizit einen durchlaufenden `_process`-Check für das Verlassen des Bau-Modus.
- `IngameSaveController.gd` erlaubt nun explizit das Speichern negativer IDs, sofern es sich um die Konstante `GameState.TUTORIAL_HOTEL_ID` (-2) handelt.
- Expliziter Aufruf von `TimeManager.pause()` beim Start von Step 11 eingefügt.
