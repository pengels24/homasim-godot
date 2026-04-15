## Version: 0.1.2
**Datum: 2026-04-15**

### Features & Verbesserungen
- **ANG-148** – `CharacterEdit`-Szene als eigenständiger Charakter-Editor implementiert (Create + Update-Modus). Erkennt automatisch ob ein Manager existiert (`GameState.has_manager()`). Prefüllt alle Felder im Update-Modus. `static var return_scene` erlaubt kontextabhängige Zurück-Navigation. Nach Speichern wird Session neu geladen, dann zu `return_scene` navigiert.
- **ANG-149** – `CharacterDisplay`-Control als geometrischer Pixel-Art-Charakter via `_draw()`. Reagiert auf Gender (m/w/d), Hautfarbe, Haarfarbe und Outfit-Farbe in Echtzeit via `update_appearance()`. Wird in CharacterEdit (Preview) und Dashboard (ManagerPanel) eingesetzt.
- **ANG-147** – Dashboard komplett überarbeitet: TopBar entfernt, stattdessen `MainArea` (HBoxContainer fullscreen). Linkes `ManagerPanel` (280px) mit CharacterDisplay-Instanz, Managername, Rolle und Hotelzahl. Rechte `HotelSection` mit dynamisch erzeugten Hotel-Kacheln (`PanelContainer` via GDScript), Spielen- und Löschen-Button pro Kachel. "Hauptmenü"-Button im Header.
- **ANG-146** – Login-Modal: "Benutzername merken"-Checkbox hinzugefügt. Login-Erfolg bleibt auf MainMenu (kein Redirect zum Dashboard). "Noch kein Account?"-Link navigiert zu Registrierung.
- **MainMenu** – Tutorial-Button als Platzhalter angelegt (`_on_tutorial_pressed` → `pass`). [DEBUG] Charakter-Button zeigt CharacterEdit aus dem Hauptmenü.

### Bugfixes
- `GameState.login()` extrahierte `manager` nicht aus `user_data` → CharacterEdit zeigte im Update-Modus leere Felder. Fix: Manager wird in `login()` und `SessionManager.check_session()` direkt in `GameState.current_manager` gesetzt.
- `CharacterEdit.return_scene` war standardmäßig auf Dashboard gesetzt → Zurück-Button landete falsch. Fix: Default ist `MainMenu.tscn`, Dashboard setzt es nicht mehr um.
- Dashboard.gd: `var skin := m.get(...)` inferierte `Variant` statt `String` → Parse Error (Warning as Error). Fix: explizite Typangabe `String`.

### Technische Änderungen
- `autoload/GameState.gd`: `current_manager: Dictionary`, `has_manager() -> bool`, Manager-Extraktion in `login()` und `logout()`.
- `autoload/SessionManager.gd`: `check_session()` setzt `GameState.current_manager` aus `/api/auth/me`-Response.
- `scenes/character/CharacterDisplay.gd` + `CharacterDisplay.tscn` neu (Control, 180×240, geometrisch via `_draw()`).
- `scenes/character/CharacterEdit.gd` + `CharacterEdit.tscn` neu (1920×1080, Bg + Overlay + Card).
- `scenes/dashboard/Dashboard.gd` + `Dashboard.tscn` komplett neu (kein ItemList, keine TopBar, dynamische Kacheln).
- `translations/de.csv`: `character.edit.title`, `character.edit.btn.save` hinzugefügt.

### Bekannte Einschränkungen
- Schriftart (Outfit-Bold) bei Tutorial- und CharacterEdit-Button im Hauptmenü noch nicht gesetzt – polishing folgt.

### Offene Backlog-Issues
- **ANG-150** – Tutorial-Szene implementieren (Platzhalter-Button vorhanden)
- **ANG-151** – Button-Font-Polishing Hauptmenü (Tutorial, CharacterEdit)
