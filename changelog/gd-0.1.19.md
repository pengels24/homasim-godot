## Version: 0.1.19
**Datum: 2026-04-28**

### Features & Verbesserungen

- **ANG-179** – `NewHotelModal` als eigenständiges Modal (`scenes/shared/`) extrahiert. Zweispaltiges Layout: Formular (Name-Feld, Eingangsseite-Info, Error) links, 5×5-Parzellenraster rechts. API: `open()` + Signale `confirmed(hotel_id)` / `cancelled`. Richtungsanzeige auf Deutsch ("Eingangsseite: Oben/Unten/Links/Rechts"). Dashboard lazy-instantiiert das Modal; gesamter Inline-Dialog-Code und alle zugehörigen Sub-Resources aus `Dashboard.tscn/.gd` entfernt.

- **Toast-Position in Einstellungen** – `SettingsManager.toast_position` (Werte: `"top"` / `"middle"` / `"bottom"`, Default `"bottom"`) persistiert in `settings.cfg [ui]`. `ToastNotification._apply_position()` setzt Y-Offset vor jedem `play()`. `SettingsModal` Oberfläche-Tab: Button-Gruppe "Oben / Mitte / Unten" mit Gold-Aktiv-Stil; in Dirty-Snapshot integriert.

- **ANG-184** – `SaveManager` von Einzel-Binärdatei auf Einzeldateien umgestellt. `user://profiles.cfg` (ConfigFile, human-readable), `user://hotels/hotel_{id}.cfg` (ConfigFile pro Hotel) und `user://saves/hotel_{id}_*.sav` (binäre Snapshots per Slot). Snapshots sind self-contained (inkl. `hotel_name`, `profile_id`, `grid_cols`, `grid_rows`) → Backup einzelner `.sav`-Dateien ist möglich wie bei Transport Fever 2. Autosave-Rotation per Dateiumbenennung (max. 10 Slots, neueste = `auto_0`). API-Oberfläche unverändert.

- **ANG-183** – Dashboard: Hotel löschen mit zweistufigem `ConfirmModal`. Erster Klick auf "Löschen" öffnet Modal mit Ack-Toggle; Bestätigen-Button bleibt deaktiviert bis "Wirklich löschen?" aktiviert. `SaveManager.delete_hotel()` löscht `hotel_{id}.cfg` + alle `hotel_{id}_*.sav` vom Disk. Gleicher Ack-Toggle-Flow in `ManagerSelect` (Manager löschen) nachgezogen.

- **Exit-Autosave (Ingame)** – Beim Verlassen des Hotels über den Beenden-Dialog wird automatisch ein Autosave-Slot erstellt (`save_auto()`). Sichert Fortschritt auch ohne manuelles Speichern.

- **ConfirmModal – Ack-Toggle** – `ask()` um optionalen Parameter `checkbox_label: String = ""` erweitert. Wenn gesetzt: Toggle-Button (Godot `Button` mit `toggle_mode=true`) erscheint mit eigenem StyleBoxFlat (unchecked: grauer Rand, checked: grüner Rand). Rückwärtskompatibel – bestehende Aufrufe ohne fünften Parameter verhalten sich unverändert.

- **`/update-doku` Parameter** – `-v`/`+v` (Version erhöhen) und `-p`/`+p` (Push nach Commit) ergänzt. Defaults: kein Bump, kein Push. Proaktiv mit Defaults OK, `+v` und `+p` nur auf Peters explizite Anfrage.

### Bugfixes / Design-Fixes

- **Grüner Button – Schriftfarbe** – Alle grünen Buttons projektübergreifend von weißer auf dunkle Schrift (`Color(0.05, 0.20, 0.08)`) umgestellt (wie Gold-Buttons). Betrifft: Dashboard, NewHotelModal, SettingsModal, CharacterEdit, Register (3 Buttons), MainMenu, ManagerSelect (3 Buttons).

- **Hover-State Schriftfarbe** – `font_hover_color` + `font_pressed_color` auf allen grün/gold Buttons gesetzt; fehlten bisher → Godot-Default weiß wurde auf Hover angezeigt.

- **Hover-Feedback global** – Gold-Umrandung (`border_width=2`, `Color(0.918, 0.702, 0.031, 0.85)`) auf alle grün/gold Hover-StyleBoxes in 12 `.tscn`-Dateien per PowerShell-Batch eingefügt.

- **Pointer-Cursor global** – `mouse_default_cursor_shape = 2` (Pointing Hand) auf alle Button-Nodes in 12 `.tscn`-Dateien gesetzt.

- **NewHotelModal UX** – Trennlinie unter Titel entfernt. `NameLabel` und `GridLabel` auf gleicher Höhe. `EntranceLbl` Farbe von Gold auf Grau. Placeholder von "Hotelname" auf "bitte Namen eingeben".

- **SettingsModal – Speichern-Button** – Von Gold auf Grün geändert (Bestätigen-Konvention).

### Technische Änderungen

- `autoload/SaveManager.gd`: Vollständiger Umbau auf Einzeldateien (ConfigFile + binäre Snapshots); API identisch zu vorher
- `scenes/shared/ConfirmModal.gd` + `.tscn`: `AckCheck` (Button, toggle_mode) ergänzt; `ask()` um `checkbox_label`-Parameter erweitert
- `scenes/dashboard/Dashboard.gd` + `.tscn`: `ConfirmModal`-Node als Kind; `_delete_hotel()` + `_on_delete_confirmed()`-Pattern
- `scenes/manager_select/ManagerSelect.gd`: `ask()`-Aufruf um Ack-Text erweitert
- `scenes/ingame/Ingame.gd`: `_on_quit_confirmed()` ruft `save_auto()` vor Szenenwechsel
- `autoload/SettingsManager.gd`: `toast_position: String = "bottom"` + save/load in `[ui]`-Sektion
- `scenes/shared/NewHotelModal.gd` + `.tscn`: neu angelegt
- `translations/de.csv`: 14 neue Keys (NewHotelModal, Toast-Position, Hotel-löschen, Manager-löschen-Ack)
- `.claude/commands/update-doku.md`: `-v`/`+v`/`-p`/`+p`-Parameter ergänzt
