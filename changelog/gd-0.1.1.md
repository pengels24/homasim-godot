## Version: 0.1.1
**Datum: 2026-04-14**

### Features & Verbesserungen
- **ANG-143** – `SessionManager` als eigener Autoload extrahiert: Cookie- und Username-Persistenz (`user://session.cfg`) aus `Api.gd` und `MainMenu.gd` herausgelöst. `check_session()` lebt jetzt zentral in `SessionManager`. Autoload-Reihenfolge: Api → SessionManager → GameState.
- **ANG-145** – 3-stufiger Registrierungs-Flow implementiert: Schritt 1 (Account-Formular) → Schritt 2 (E-Mail-Bestätigungscode) → Schritt 3 (Charakter-Creator mit Live-Avatar-Vorschau). Initialen, Hautfarbe und Name werden live im Avatar-Preview aktualisiert. Nach erfolgreicher Erstellung wird die Session geladen und zum Dashboard gewechselt.
- **MainMenu** – Login-Modal erhält "Noch kein Account? Jetzt registrieren"-Link (`BtnToRegister`), navigiert direkt zu `Register.tscn`.

### Bugfixes
- `Api.gd`: `extract_cookie` wurde nur bei `post_form` gesetzt, nicht bei `post_json`. Fix: Cookie wird jetzt aus allen Responses extrahiert. Ursache: Verify-Request nach Registrierung schickte keine Session mit → Netzwerkfehler.
- `Register.tscn`: Kommentarzeilen (`# ...`) zwischen `[node]`-Blöcken verhindern Godots .tscn-Parser das Laden der nachfolgenden Nodes. Alle Kommentare entfernt. Außerdem `load_steps` auf korrekten Wert (11) gesetzt.

### Technische Änderungen
- `autoload/SessionManager.gd` neu angelegt.
- `autoload/Api.gd`: `_handle_response` ohne `extract_cookie`-Parameter – Cookie wird immer gezogen.
- `autoload/GameState.gd`: `check_session()` entfernt (liegt jetzt in SessionManager), `logout()` ruft `SessionManager.clear()` auf.
- `scenes/register/Register.gd` + `Register.tscn` neu angelegt (3-Step-Flow).
- `translations/de.csv`: 38 neue Keys für Registrierung, Verifizierung und Charakter-Creator.
- `project.godot`: SessionManager als Autoload registriert.

### Bekannte Einschränkungen
- Charakter-Preview zeigt noch nicht alle Optionen visuell korrekt (kein Sprite-System, nur Initialen + Hautfarbe). Visuelles Polishing ist für später geplant.

### Offene Backlog-Issues
- **ANG-146** – Login/HotelSelect visuelles Overhaul (noch offen)
- **ANG-147** – Dashboard visuell verbessern (noch offen)
