## Version: 0.1.20b
**Datum: 2026-05-06**

### Features & Verbesserungen

- **ANG-192 Phase 3** – Floor-Neighbor-Extension: `BedStandard` erkennt benachbarte Räume und dehnt den Interior-Floor um 1px in Richtung des Nachbars aus. Reduziert die sichtbare Trennwand zwischen 1:1-angrenzenden Zimmern von 4px auf 2px. Rotations-aware: `room_rotation` wird berücksichtigt, damit die Ausdehnung in Welt-Koordinaten korrekt bleibt.
- **room_rotation System**: Neues `room_rotation`-Feld in `Room.gd` (0–3). R-Taste dreht den gesamten Raum (Interior + Tür) 90° im Uhrzeigersinn; .-Taste wechselt nur die Tür-Wand; ,-Taste wechselt die Tür-Position. Altes Z/T-Schema abgelöst.
- **Raum an Parzellenrand**: `is_placement_valid()` erlaubt jetzt tile_x/y = 0 (Raum darf direkt an Parzellenrand). Neue Funktion `_exit_outside_parcel()` verhindert, dass die Tür die Parzelle verlässt.
- **BedStandard visuelles Redesign**: Wandsprites auf GradientTexture1D umgestellt (ersetzt PNG-Assets). Gleiche Optik, kein externer Texture-Asset-Import mehr nötig.

### Technische Änderungen

- **`Room.gd`** – `room_rotation: int` Variable; virtuelle Methode `set_floor_neighbors(top, right, bottom, left)` (no-op Basis).
- **`BedStandard.gd`** – `set_floor_neighbors()` Override mit Rotations-Mapping; `INTERIOR_TRANSFORMS` Dictionary für Interior-Node-Transform je room_rotation; `FLOOR_BASE_SIZE` + `FLOOR_TEX_W` Konstanten.
- **`MapGrid.gd`** – `_occ_has_room_body()` prüft Occupancy-Grid-Bereich auf Wert 1; `_update_all_floor_neighbors()` iteriert alle sichtbaren Parzellen und ruft `set_floor_neighbors()` auf jedem Raum auf; Aufruf nach `place_room()` und `_restore_rooms()`; `_occ_free_for_room()` (ex `_occ_is_free`) erlaubt Platzierung auf Wand-Tiles (Wert 3); `place_room()` + `_restore_rooms()` um `room_rot` Parameter erweitert; `_exit_outside_parcel()` neu.
- **`BuildCursor.gd`** – `_room_rotation` Variable; `_advance_room_rotation()` synchronisiert room_rotation + door_rotation; `_update_valid_combos()` übersetzt raumrelative Tür-Kombos in Weltkoordinaten; Signal `room_placed` um `room_rotation: int` erweitert.
- **`IngameBuild.gd`** – `rrot` Parameter in `_on_room_placed()` + `place_room()` durchgeschleift.
- **`Parzelle.gd`** – `spawn_room()` + `restore_room()` übergeben `room_rot` an `room.configure()`.
- **`Bed_Standard.tscn`** – Komplettes Wand-Redesign: GradientTexture1D statt PNG-Assets für alle 4 Wandseiten + BaseFloor.
- **`Bed_Double.tscn`**, **`Lobby.tscn`** – Entsprechende Asset-Anpassungen.

### Offene Backlog-Issues

- **ANG-192** – Versatz-Fall (Räume nicht 1:1 ausgerichtet) noch nicht gelöst; Möbel-Artefakt an erweiterter Wandseite vorhanden
- **ANG-193** – Wall-System Refactor: TileMap-basierte Außenkontur + Trennwände (Backlog, mittelfristig)
- **ANG-191** – Abreiß-Funktion, Zimmernummern, XP-Level-Kurve, FP-Quellen
