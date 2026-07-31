## Version: 0.1.9
**Datum: 2026-04-17**

### Features & Verbesserungen

- **ANG-153** – `MapGrid.tscn` + `MapGrid.gd` neu erstellt: Map-Logik und Kamera vollständig aus `Ingame.gd` extrahiert. `MapGrid.gd` übernimmt TileSet-Konstanten, Grid-Konfiguration, `build_map()` + `center_on_entry()` Public API sowie WASD/Zoom/RMB-Kamera-Steuerung.
- **ANG-153** – TileSet mit 6 AtlasSources (ground_base, ground_walking, ground_floor, ground_brick, ground_lobby, main_door) als Sub-Resource in `MapGrid.tscn` definiert – nicht mehr im Code gebaut.
- **ANG-153** – Statisches Basis-Grid (86×86 Tiles: ground_walking-Ring + ground_base-Interior) vom User im Godot-Editor vorgemalt und in `.tscn` eingebacken; `_fill_base_layer()` + `_fill_walking_ring()` aus Runtime-Code entfernt.
- **ANG-153** – `Ingame.gd` von ~963 auf ~700 Zeilen reduziert: alle TileSet-, Map- und Kamera-Variablen/Funktionen entfernt, `$MapGrid`-Referenz ergänzt, `_start_map()` als sauberer Einstiegspunkt.
- **ANG-153** – `CLAUDE.md` um Code-Qualitäts-Direktive ergänzt: Senior Game Developer Standard, Abschnitt-Header, statische Typisierung, Ressourcen in `.tscn`.

### Bugfixes

- **ANG-153** – `FloorLayer.position` war auf `Vector2(1, -1091)` gesetzt (Node wurde beim Tile-Malen im Editor versehentlich verschoben). Alle Tiles wurden dadurch 2182 World-Pixel zu hoch gerendert. Reset auf `Vector2(0, 0)`.
- **ANG-153** – WASD W/S-Bewegung funktionierte nicht: `is_action_pressed("ui_up/down")` interferierte mit `is_key_pressed`. Auf reines `is_key_pressed(KEY_W/A/S/D)` umgestellt.

### Technische Änderungen

- `Ingame.tscn`: WorldRoot + FloorLayer + WallLayer + Camera2D ersetzt durch `MapGrid`-Instanz (`MapGrid.tscn`).
- `MapGrid.gd`: Klare Abschnitts-Struktur mit `# ── Name ──` Headern: Nodes, Tile Source-IDs, Grid-Konfiguration, Kamera-Konfiguration, Public API, Map-Aufbau (privat), Kamera (privat).

### Offen / Nächste Session

- **ANG-153** – RMB-Drag-Freeze: Kamera friert nach mehrmaligem Bewegen ein; `_input` vs. `_unhandled_input` wird weiter untersucht. Aktuell zurück auf `_unhandled_input`.

### Offene Backlog-Issues

- **ANG-153** – RMB-Drag-Steuerung (Freeze-Bug)
- **ANG-154** – Scene-Architektur HUD/Dashboard/Credits
- **ANG-155** – Security / Server-seitige Validierung
- **ANG-156** – Export-Targets Steam
- **ANG-152** – Settings-Screen (ALT+S)
