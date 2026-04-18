## Version: 0.1.10
**Datum: 2026-04-18**

### Features & Verbesserungen

- **ANG-157** – `SaveManager.gd` (Autoload): lokales Save-System via `FileAccess.store_var()` (Godot Binary Format). Tabellen-Struktur: profiles, hotels (mit `game_time`-Feld), plots. Public API: `get_hotels()`, `create_hotel()`, `get_built_plots()`, `set_plot_built()`, `update_hotel()`.
- **ANG-158** – Statisches 5×5 Parzellen-Grid: alle 25 `Parzelle`-Instanzen (P_0_0…P_4_4) fix in `MapGrid.tscn` platziert. `_grid[y][x]`-Array in `_ready()` einmalig verdrahtet – kein Laufzeit-Spawn, kein Name-Lookup. Unsichtbar by default, `build_map()` setzt sichtbare Parzellen.
- **ANG-158** – `Parzelle.gd`: `configure(neighbors)` steuert WallN/S/W/E Sichtbarkeit. `set_entrance(dir)` spawnt `Lobby.tscn` zentriert mit 1-Tile Inset zur Außenmauer. Lobby-Position nach Eingangsrichtung (`top`/`bottom`/`left`/`right`).
- **ANG-158** – Room-System Grundgerüst: `Room.gd` Basisklasse (room_type_id, level, condition, cleanliness, room_rotation, door_rotation, door_offset, configure/to_dict API). `Lobby.gd` erbt davon – kein R/T/Z (Türrichtung kommt aus `entrance_dir` des Plots, nicht per Player-Input).
- **ANG-158** – `Lobby.tscn`: Ground-TileMapLayer (4×4 Lobby-Boden), Door-TileMapLayer (Türgrafik, 4 Richtungen × 2 Tiles). Pixel-Art Rendering: Default Texture Filter auf **Nearest** gestellt.
- `Ingame.gd` von PHP-API-Dependencies befreit: `_start_map()` liest aus `SaveManager` statt `GameState.selected_hotel`. `_load_hotel()`, `_save_progress()`, `_notification()` für Auto-Save bei Close. `game_time` wird geladen (Tagesstart 6:00 Uhr = 360 Minuten).
- `GameState.gd`: `active_hotel_id: int = -1` als neues Feld für Local-first Hotel-Referenz.

### Bugfixes

- `Room.gd`: `var rotation` kollidierte mit `Node2D.rotation: float` → umbenannt auf `room_rotation`. Gleicher Fix für `var floor` (Built-in-Funktion) → `floor_num`.
- `SaveManager.gd`: Parameter `name` shadowte `Node.name` (Zeilen 24/41) → umbenannt auf `profile_name` / `hotel_name`.
- `MapGrid.gd`: `_enter_dir` (ignoriert) → `enter_dir`, wird jetzt via `set_entrance()` an Parzelle übergeben.
- `Ingame.gd`: Verbleibender Call auf `_sync_time_to_api()` in `_on_exit_pressed()` entfernt → `_save_progress()`.

### Technische Änderungen

- `scenes/ingame/rooms/` neu angelegt: `Room.gd`, `Lobby.gd`, `Lobby.tscn`
- `autoload/SaveManager.gd` neu (ersetzt künftig PHP-API für lokale Daten)
- `scenes/ingame/map/Parzelle.gd` + `Parzelle.tscn` neu
- `MapGrid.tscn`: `ParcelsRoot` mit 25 Parzellen-Instanzen ergänzt

### Offene Backlog-Issues

- **ANG-158** – Lobby Door-Tiles: Grafiken für alle 4 Richtungen noch offen; Eingangs-Pfad-Tile (dunkler Boden am Mauer-Eingang) noch offen
- **ANG-159** – Login optional: „Spielen" lokal + „Konto verbinden" (noch nicht umgesetzt)
- **ANG-153** – RMB-Drag-Freeze-Bug
- **ANG-154** – Scene-Architektur HUD/Dashboard/Credits
- **ANG-155** – Security / Server-seitige Validierung
- **ANG-156** – Export-Targets Steam
- **ANG-152** – Settings-Screen (ALT+S)
- **ANG-149** – Tutorial-Szene
