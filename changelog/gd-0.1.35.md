# Changelog

## Version: v0.1.35gd-td
**Datum:** 2026-07-04

### Features & Verbesserungen
- **Zeitsteuerung überarbeitet:** Das Pausieren und Fortsetzen der Spielzeit wurde intuitiver und verlässlicher gestaltet.
- **Neue Hotkeys:** Tasten `1` (Normaler Speed) und `2` (Vorlauf-Speed) für schnellen Wechsel der Spielgeschwindigkeit eingebaut.
- **Settings erweitert:** Hotkeys für Play und Forward sind nun in den Einstellungen (Controls) anpassbar.

### Bugfixes
- **Pausen-Status bei Modals gefixt:** Modals und Baumenü merken sich nun verlässlich den vorherigen Status und setzen das Spiel nach dem Schließen nur dann fort, wenn es vorher lief.
- **Tutorial-Button gefixt:** Der Button leuchtet nun korrekt auf, wenn das Tutorial offen ist und resettet sich danach fehlerfrei.
- **UI-Pause Hotkey:** Die Leertaste pausiert und setzt das Spiel nun wieder korrekt im Toggle-Modus fort.

### Technische Änderungen
- Logik in `IngameUIManager` (`_pause_time_for_ui`) drastisch vereinfacht, um Fehler bei kombinierten Pausen-Zuständen (User-Pause vs. System-Pause) zu verhindern.
- `keybindings.json` und `language.csv` um neue Gameplay-Steuerungsaktionen erweitert.
