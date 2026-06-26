## Version: 0.1.29
**Datum: 2026-06-27**

### Features & Verbesserungen

- **Mehrsprachigkeit eingeführt**: `de.csv` (1009 Zeilen, aufgebläht, voller Duplikate) ersetzt durch saubere `language.csv` mit 400 Zeilen – Spalten `keys | de | en`.
- **Vollständige Englisch-Übersetzung**: Alle in-game sichtbaren Strings wurden ins Englische übersetzt. Spätere Sprachen (ES, FR …) kommen einfach als neue Spalte dazu.
- **Sprachumschalter in den Settings** (Oberfläche-Tab, erste Zeile): Deutsch | English – wie alle anderen Toggles mit ← → Pfeiltasten.
- **Sprachwechsel im Hauptmenü** lädt die Szene sofort neu → alles ist direkt in der neuen Sprache sichtbar.
- **In-Game ist der Sprachumschalter gesperrt** (mit Hinweis „nur im Hauptmenü") – sauber und branchenüblich.
- **Dashboard-Hotelkarten**: Beschriftungen `LEVEL`, `TAG`, `GÄSTE`, `RUF`, `KAPITAL` werden jetzt übersetzt statt hardcoded.

### Bugfixes

- **Typo behoben**: `"Bitte whlen..."` → `"Bitte wählen..."` (fehlte das `ä`).
- **Doppelter Block entfernt**: Zeilen 785–893 der alten `de.csv` waren ein exakter Klon von Zeilen 554–698 – jetzt weg.
- **Malformed CSV-Zeilen gefixt**: `room.lobby.name` und `room.lobby.desc` hatten keine dritte Spalte.
- **7 fehlende Translation-Keys ergänzt**: u.a. `guest.state.waiting`, `hud.bottom.reception_closed_tt`, `tooltip.surcharge`, `tt.build.room.locked_both`.
- **`home.hero.*` → `menu.hero.*`**: Keys im Hauptmenü semantisch korrekt benannt (war Überbleibsel der alten Web-Codebase).

### Technische Änderungen

- `translations/de.csv` gelöscht, ersetzt durch `translations/language.csv`
- `project.godot`: beide Locales `de` + `en` registriert (`language.de.translation`, `language.en.translation`)
- `SettingsManager.gd`: neues Feld `language: String = "de"`, `TranslationServer.set_locale()` beim Laden, Signal `sig_language_changed`
- `SettingsModal.gd` (Hauptmenü): Sprach-Toggle via `_make_language_row()` (für spätere Nutzung)
- `ModalContentSettings.gd` + `.tscn`: Sprach-Toggle als erste Zeile im Oberfläche-Tab; in-game deaktiviert, Hauptmenü lädt Szene neu
- `DashboardHotelCard.gd`: Header-Labels über `GameState.T()` statt hardcoded Strings
