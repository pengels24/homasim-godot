## Version: 0.1.3
**Datum: 2026-04-15**

### Features & Verbesserungen
- **Button-Farbkonzept** – Verbindliches Farbschema für alle Buttons eingeführt und in allen bestehenden Szenen durchgesetzt: Gold (`#EAB308`) = Navigation/Menü, Grün (`#16a34a`) = Bestätigen/Speichern/Anlegen, Rot (`#dc2626`) = Abbrechen/Löschen, Blau (`#2563eb`) = Info/Details. StyleBoxFlat normal/hover pro Typ, 6px Radius. Betrifft: MainMenu, Register, CharacterEdit, Dashboard.
- **Dashboard – Spielen-Button → Grün** – `_apply_green_style()` als neue Hilfsfunktion in Dashboard.gd. "Spielen"-Button auf Grün umgestellt (Bestätigen-Semantik). Weißer Font statt dunkler.

### Bugfixes
- **Dashboard – CharacterDisplay bei Frischlogin** – `_setup_manager_panel()` wurde in `_ready()` sofort aufgerufen bevor `/api/auth/me` `current_manager` befüllt hatte. Fix: `has_manager()` prüfen; falls leer → `SessionManager.check_session()` nachholen, dann Panel aufbauen. `_load_hotels()` läuft parallel weiter.
- **Dashboard – Button-Margins inkonsistent** – `_apply_gold_style()` und `_apply_danger_style()` nutzten 16/8px Margins statt 20/10px wie die .tscn-Buttons. Angeglichen.

### Technische Änderungen
- `CLAUDE.md`: Button-Farbkonzept-Tabelle als verbindliche Direktive ergänzt.
- `.gitignore`: `external-assets/` eingetragen (Kenney-Tileset-Packs, nicht ins Repo).
- `scenes/dashboard/Dashboard.gd`: `_apply_green_style()` hinzugefügt; `_ready()` mit bedingtem `check_session()`-Fallback.
- `scenes/main_menu/MainMenu.tscn` + `MainMenu.gd`: Tutorial-Button (Platzhalter, `pass`), Button-Farben.
- `scenes/register/Register.tscn`: Button-Farben (StyleBoxFlat grün/rot).
- `scenes/character/CharacterEdit.tscn`: Button-Farben (Speichern → grün, Zurück → rot).

### Offene Backlog-Issues
- **ANG-148** – Ingame-Grundgerüst (TileMap, Kamera, Lobby-Platzierung) – nächster großer Schritt
- **ANG-150** – Tutorial-Szene implementieren (Platzhalter-Button vorhanden)
- **ANG-151** – Button-Font-Polishing Hauptmenü (Tutorial, CharacterEdit)
