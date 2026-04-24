## Version: 0.1.18
**Datum: 2026-04-24**

### Features & Verbesserungen

- **ANG-172 Refactor** – ManagerSelect von eigenständiger Vollbild-Szene zu Modal über dem MainMenu umgebaut.
  - `ManagerSelect.tscn`: vollständiger Node-Baum mit 3 Slots (je `Empty`/`Filled`-Gruppe) – keine Code-generierte UI mehr, komplett im Godot-Editor bearbeitbar
  - `ManagerSelect.gd`: schlankes Script – befüllt nur Daten per `get_node()`-Pfaden, emittiert `closed()`-Signal; kein `VBoxContainer.new()` o.ä. mehr
  - `MainMenu.tscn`: instanziert `ManagerSelect.tscn` als Kind-Node `ManagerModal` (letzter Child → rendert über allem)
  - `MainMenu.gd`: `_on_manager_pressed()` ruft `_manager_modal.open()` statt `change_scene_to_file`; `_on_manager_modal_closed()` zeigt `btn_quit` wieder
  - Gold-Glow-Border am Modal-Card (StyleBoxFlat: 1px gold border + gold shadow, subtil)
  - ESC schließt das Modal (`_unhandled_input` → `ui_cancel`)
  - `btn_quit` (Beenden) wird beim Öffnen des Modals ausgeblendet und beim Schließen wiederhergestellt

- **MainMenu** – Login-Button umbenannt zu "Kontobindung", dauerhaft disabled (API optional, Cloud-Sync kommt später); Translation-Key `menu.btn.account_bind` ergänzt

### Bugfixes

- `_update_login_state()` in `MainMenu._on_login_pressed()` → `_update_manager_state()` (Parse Error beim Start behoben)
- Kompilierte `.translation`-Binärdateien nach CSV-Edit neu erzeugt (Bucket-Size-Error behoben)

### Technische Änderungen

- **UI-Direktive etabliert**: UI-Struktur gehört in `.tscn`, Scripts befüllen nur Daten – keine `Node.new()`-UI-Bauten mehr. Gilt für alle zukünftigen Szenen.
- `ManagerSelect.gd.uid` hinzugefügt (Godot-generiert)

### Offene Backlog-Issues

- **ANG-174** – Dev-Konsole Ingame (besprochen, noch nicht implementiert)
