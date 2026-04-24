## Version: 0.1.16
**Datum: 2026-04-24**

### Features & Verbesserungen

- **ANG-169** – Tür-Validierung erweitert: Ghost wird rot wenn Tür in belegte Zimmerwand zeigt (`_door_is_blocked` prüft 1-Tile-Streifen in Türrichtung via `is_tile_free`).
- **ANG-169** – Lobby-Clearance-Schutz: 1-Tile-Streifen direkt vor der Lobby-Innentür wird als gesperrte Zone gewertet – Räume die diesen Streifen überdecken sind ungültig (`_lobby_clearance_blocked` + `get_lobby_clearance_rect` in Parzelle/MapGrid).
- **ANG-169** – Tür-Rotation invalidiert Ghost sofort: `_refresh_ghost()` berechnet Validity nach jedem R/T-Tastendruck neu.
- **ANG-169** – `external-assets/.gdignore` hinzugefügt: Godot scannt das Verzeichnis nicht mehr → UID-Duplikat-Warnungen verschwunden.

### Bugfixes

- **ANG-169** – `_door_faces_boundary` → `_door_is_blocked` umbenannt und um adjacent-tile-Belegungscheck erweitert.
- `HotelSelect.tscn`: ungültiges `layout_mode = 1` entfernt (Godot 4.6 kennt diesen Enum-Wert nicht mehr).
- `BuildCursor.gd`: Variable `snapped` in `_try_place()` → `snap_pos` (Namenskonflikt mit Built-in).
- `Parzelle.gd`: Integer-Division in `get_lobby_clearance_rect` auf Float-Division mit `int()`-Cast umgestellt.
- `BuildCursor.gd`: Falscher Kommentar `# = 32` auf `ROOM_HALF` korrigiert (korrekt: `# = 16`).

### Technische Änderungen

- **`Parzelle.gd`** – `get_lobby_clearance_rect() -> Rect2i`: gibt 1-Tile-Streifen vor Lobby-Innentür zurück; nur aktiv wenn `has_entrance`.
- **`MapGrid.gd`** – `get_lobby_clearance_rect(px, py) -> Rect2i` als Delegat zu Parzelle.
- **`BuildCursor.gd`** – `_door_is_blocked()`: prüft Außenwand (Schnellcheck) + Tile-Belegung in Türrichtung. `_lobby_clearance_blocked()`: prüft Rect-Schnitt mit Lobby-Clearance.
- **`BuildCursor.gd`** – `PARCEL_TILES := PARCEL_PX / TILE_PX` als Konstante ergänzt.
