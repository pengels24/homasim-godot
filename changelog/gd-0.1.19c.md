## Version: 0.1.19c
**Datum: 2026-04-29**

### Features & Verbesserungen

- **ANG-180** – MainMenu Footer implementiert: dezente Leiste (font_size=17, alpha=0.90) mit Godot-Icon (alpha=0.55→0.80) + Versionsstring links, „© 2026 – Angelus2010" als separate absolut-positionierte Label (1920×28, CENTER) in der Mitte.
- **BedDouble (DZ)** – Neuer Raumtyp vollständig integriert: 4×2 Tiles (Landscape) / 2×4 Tiles (Portrait), Z-Taste schaltet Orientierung um. Szene `Bed_Double.tscn` mit Landscape- und Portrait-Subtree (je 8 Türpositionen). Registriert in BuildCursor, IngameBuild, MapGrid.
- **Dynamische Raumgröße im BuildCursor** – `_room_w`/`_room_h` werden per `get_tile_size()` vom Ghost abgefragt statt hardcodiert. Jede Raumgröße funktioniert ohne Codeänderung am Cursor.

### Bugfixes

- **Ghost-Farbe nach R/T/Z falsch** – `_refresh_ghost()` fehlte der `would_block_door`-Check. Nach Tastendruck konnte Ghost grün zeigen obwohl Nachbarraum-Tür blockiert war. Alle vier Validierungschecks laufen jetzt bei jedem Aufruf von `_refresh_ghost()`.
- **Portrait-Ghost mit Landscape-Dimensionen** – Bei Z-Taste wurde `get_tile_size()` vor `configure()` aufgerufen, las also noch den alten `room_flip`. Fix: Größe wird in `_refresh_ghost()` nach `configure()` abgefragt; KEY_Z-Handler ruft nur noch `_refresh_ghost()` auf.
- **`_door_is_blocked` zu breite Prüfung** – Prüfte die gesamte Wandbreite/-höhe statt nur das exakte Exit-Tile. Führte bei BedDouble (4 Tiles breit) zu falschen Rot-Anzeigen wenn mittlere Tiles besetzt waren. Fix: `door_offset * (dim - 1)` liefert exakt das eine Exit-Tile, egal ob Raum 2×2, 4×2 oder 2×4.
- **`_door_exit_tile` falsches Offset** – Verwendete `door_offset` direkt als Tile-Abstand (TopRight = x+1 statt x+3 bei 4-breitem Raum). Gleiche `door_offset * (sz - 1)`-Formel angewendet – korrekt für alle Raumgrößen.
- **Dashboard „Laden"-Button Crash** – Button entfernt (war redundant: Laden ist über PauseMenu im Spiel erreichbar). Toten Code (`_open_load_screen`, `_on_save_loaded`, `LOAD_SCREEN_SCENE`) mitentfernt.

### Technische Änderungen

- `Room.gd` – `room_rotation` entfernt, `room_flip` ist jetzt der korrekte Name für Landscape/Portrait-Umschalten; Kommentare zu R/T/Z-Tasten korrigiert
- `BedDouble.gd` + `Bed_Double.tscn` – neu angelegt
- `BuildCursor.gd` – `ROOM_TILES`/`ROOM_TILE_PX`/`ROOM_HALF` entfernt; `_room_w`/`_room_h` dynamisch; `_door_is_blocked` mit exakter Exit-Tile-Formel
- `Parzelle.gd` – `would_block_any_door()` + `_door_exit_tile()` neu (prüft ob Ghost-Footprint Exit-Tiles bestehender Räume blockiert); `_door_exit_tile` mit korrekter `door_offset * (sz-1)`-Formel
- `MapGrid.gd` / `IngameBuild.gd` – `bed_double` in SCENE_PATHS/ROOM_SCENES registriert
- `Dashboard.gd` – „Laden"-Button + zugehörige Funktionen entfernt

### Offene Backlog-Issues

- **ANG-186** – Occupancy Grid: Globales `grid_cols*PARCEL_SZ × grid_rows*PARCEL_SZ` Bool-Array ersetzt `_occupied: Array[Rect2i]` + alle Tür-Formeln; unterstützt variable Kartengrößen und parzellenübergreifende Räume
