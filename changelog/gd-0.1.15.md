## Version: 0.1.15
**Datum: 2026-04-23**

### Features & Verbesserungen

- **ANG-161** – Bau-Cursor (BuildCursor.gd) vollständig implementiert: Ghost folgt Maus im WorldRoot-Koordinatenraum, rastet auf 16px-Tile-Gitter, bleibt auf owned Parzellen beschränkt, weiß/rot Feedback via Tile-Belegungsprüfung. R/T rotiert/flippt Tür, ESC bricht ab, Linksklick platziert.
- **ANG-161** – Ghost-Zentrierung: Snap wird auf Maus-Position angewendet (nicht auf topleft), dann ROOM_HALF abgezogen – Ghost-Center rastet auf Tile-Mittelpunkt unter der Maus.
- **ANG-161** – ROOM_TILE_PX auf 32 korrigiert (2×2 Tiles à 16px = 32px visual in WorldRoot-local), ROOM_TILES auf 2 – behebt Ghost-Positionierung und Clamp-Grenzen rechts/unten.
- **ANG-169** – Außenwände als belegt markiert: `_ensure_walls_marked()` in Parzelle belegt Rand-Tiles (Zeile 0, Zeile 15, Spalte 0, Spalte 15) einmalig beim ersten spawn_room oder set_entrance – Ghost wird rot wenn er Wandtiles überlappt.

### Technische Änderungen

- **GameState.gd** – `snap_to_grid: bool = true` als Settings-Toggle für Baumodus-Snap hinzugefügt.
- **Parzelle.gd** – Tile-Belegungstracking via `Array[Rect2i] _occupied`: `is_area_free()`, `mark_occupied()`, `_ensure_walls_marked()`. `spawn_room()` nimmt jetzt tile_x/tile_y entgegen und positioniert den Raum korrekt.
- **MapGrid.gd** – `is_parcel_owned()`, `is_tile_free()`, `get_first_owned_parcel()` hinzugefügt. `place_room()` um tile_x/tile_y erweitert, ruft SaveManager/configure_walls nur bei neuer Parzelle auf.
- **Ingame.gd** – BuildCursor-Instanziierung, Signal-Verbindung `room_placed(px, py, tx, ty, dr, doff)`, `_on_room_placed()` Handler mit SCENE_PATHS-Lookup.
- **BuildCursor.gd** – Neue Datei: Ghost-Cursor-System für Raum-Platzierung im Tile-Grid.

### Offene Backlog-Issues

- **ANG-169** – 7 Bugs aus erstem Bau-Cursor-Test: Ghost-Zentrierung, Wand-Rot-Feedback, Rand-Clamp, Falsch-Rot, Tür-Wanderkennung – teilweise behoben, Collage-Test steht aus.
