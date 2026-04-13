## Version: 0.1.0
**Datum: 2026-04-13**

### Features & Verbesserungen
- **Hauptmenü** – Vollständig gestaltetes Hauptmenü mit 3-Bild-Hintergrund-Slideshow (5s Intervall, 1.2s Fade), Logo, Hero-Text und 2×2 Gold-Button-Grid. Feste Auflösung 1920×1080.
- **Login-Modal** – Login als Modal über dem Hauptmenü (Hintergrund verdunkelt, nichts klickbar). Styled mit dark Card, Gold-Input-Focus-Border, Schlagschatten. Kein Szenenwechsel.
- **Session-Persistenz** – Cookie wird in `user://session.cfg` gespeichert. Auto-Login via `GET /api/auth/me` beim App-Start. Username wird für nächsten Start vorausgefüllt. Logout über Hauptmenü-Button.
- **ANG-144** – Dashboard-Szene: Zeigt Hotelliste mit Name, Level und Goldstand. Neues Hotel anlegen (Dialog), Hotel löschen (`POST /api/hotel/delete`), Hotel spielen (Doppelklick oder Button). Abmelden und Hauptmenü-Navigation.
- **Translation-System** – 412 Übersetzungs-Keys aus PHP-Quelle (`homasim_de.php`) via PowerShell generiert. `GameState.T("key")` als zentraler Helper. Alle UI-Strings lokalisiert.
- **Api-Singleton** – `post_form()`, `post_json()`, `get_json()` mit Cookie-Auth. Session-Cookie via Setter automatisch in `user://session.cfg` persistiert.
- **GameState-Singleton** – `login()`, `logout()`, `check_session()`, `select_hotel()`, `T()` Translation-Helper.

### Bugfixes
- `tr()` in `static func` nicht verfügbar → `TranslationServer.translate()` genutzt
- `replacen()` akzeptiert in Godot 4 kein drittes Count-Argument → `replace()` genutzt
- `BtnPlay` hatte alle Styles auf `gold_disabled` gesetzt → normal/hover/pressed auf `gold` korrigiert
- `money`-Feld von API kommt als String → `int()` Cast in Dashboard
- Translation-Referenz in `project.godot` zeigte auf CSV statt kompilierte `.translation`-Datei

### Technische Änderungen
- `.gitignore` erweitert: `_dev/`, `*.translation`, `*.import`, OS/IDE-Files
- `CLAUDE.md` angelegt mit Projektdirektiven, API-Konventionen, Design-System
- Linear-Projekt **HO·MA·SIM Godot** angelegt (Team Angelus2010)
- Skill `/update-doku` angelegt unter `.claude/commands/update-doku.md`

### Offene Backlog-Issues
- **ANG-143** – SessionManager: Session-Logik aus `Api.gd` und `Login.gd` in eigenen Autoload auslagern
- **ANG-145** – Registrierung mit Charakter-Erstellung
- **ANG-146** – Login- und HotelSelect-Szene visuell überarbeiten (HotelSelect obsolet nach Dashboard)
