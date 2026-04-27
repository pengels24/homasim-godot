## Version: 0.1.19
**Datum: 2026-04-27**

### Features & Verbesserungen

- **ANG-179** – `NewHotelModal` als eigenständiges Modal (`scenes/shared/`) extrahiert. Zweispaltiges Layout: Formular (Name-Feld, Eingangsseite-Info, Error) links, 5×5-Parzellenraster rechts. API: `open()` + Signale `confirmed(hotel_id)` / `cancelled`. Richtungsanzeige auf Deutsch ("Eingangsseite: Oben/Unten/Links/Rechts"). Dashboard lazy-instantiiert das Modal; gesamter Inline-Dialog-Code und alle zugehörigen Sub-Resources aus `Dashboard.tscn/.gd` entfernt.

- **Toast-Position in Einstellungen** – `SettingsManager.toast_position` (Werte: `"top"` / `"middle"` / `"bottom"`, Default `"bottom"`) persistiert in `settings.cfg [ui]`. `ToastNotification._apply_position()` setzt Y-Offset vor jedem `play()`. `SettingsModal` Oberfläche-Tab: Button-Gruppe "Oben / Mitte / Unten" mit Gold-Aktiv-Stil; in Dirty-Snapshot integriert.

### Bugfixes / Design-Fixes

- **Grüner Button – Schriftfarbe** – Alle grünen Buttons projektübergreifend von weißer auf dunkle Schrift (`Color(0.05, 0.20, 0.08)`) umgestellt (wie Gold-Buttons). Betrifft: Dashboard, NewHotelModal, SettingsModal, CharacterEdit, Register (3 Buttons), MainMenu, ManagerSelect (3 Buttons).

- **Hover-State Schriftfarbe** – `font_hover_color` + `font_pressed_color` auf allen grün/gold Buttons gesetzt; fehlten bisher → Godot-Default weiß wurde auf Hover angezeigt.

- **Hover-Feedback global** – Gold-Umrandung (`border_width=2`, `Color(0.918, 0.702, 0.031, 0.85)`) auf alle grün/gold Hover-StyleBoxes in 12 `.tscn`-Dateien per PowerShell-Batch eingefügt. Gibt klares visuelles Feedback ohne zu grelle Hintergrundänderung.

- **Pointer-Cursor global** – `mouse_default_cursor_shape = 2` (Pointing Hand) auf alle Button-Nodes in 12 `.tscn`-Dateien gesetzt, die ihn noch nicht hatten (CharacterEdit-Optionen, Dashboard, Login, Register, Settings, etc.). Code-seitig in `_apply_gold_style()`, `_apply_green_style()`, `_setup_tab_buttons()` ergänzt.

- **NewHotelModal UX** – Trennlinie unter Titel entfernt (inkonsistent mit anderen Modals). `NameLabel` und `GridLabel` auf gleicher Höhe (GridTopSpacer entfernt). `EntranceLbl` Farbe von Gold auf Grau. Placeholder von "Hotelname" auf "bitte Namen eingeben".

- **SettingsModal – Speichern-Button** – Von Gold auf Grün geändert (Bestätigen-Konvention). `SaveSpacer` (16px) für Abstand zur Trennlinie ergänzt.

### Technische Änderungen

- `autoload/SettingsManager.gd`: `toast_position: String = "bottom"` + save/load in `[ui]`-Sektion
- `scenes/shared/NewHotelModal.gd` + `.tscn`: neu angelegt
- `scenes/shared/ToastNotification.gd`: Positionskonstanten + `_apply_position()`
- `scenes/shared/SettingsModal.gd`: `_make_toast_position_row()`, `_style_pos_btn()`, Snapshot um `toast_position` erweitert; Tab-Button-Cursor per Code
- `translations/de.csv`: 9 neue Keys (`dashboard.new_hotel.name.label`, `.grid.section`, `.grid.label`, `.dir.*` ×4, `settings.ui.toast_position`, `settings.ui.toast.*` ×3)

### Offene Backlog-Issues

- **ANG-183** – Dashboard: Hotel löschen ohne Bestätigungsdialog (angelegt, noch offen)
