## Version: 0.1.20c
**Datum: 2026-05-07**

### Features & Verbesserungen

- **Tür-Slot-System (T1-5/R1-5/B1-5/L1-5)** – Benannte Tür-Slots ersetzen hardcodierte Pixel-Koordinaten-Dictionaries. Räume deklarieren nur noch welche Slots sie verwenden (`get_valid_door_slots()`); `Room.gd` berechnet alle Pixel-Positionen automatisch aus Raumgröße + Slot-Nummer. Konvention: T/R zählen vorwärts (links→rechts / oben→unten), L/B zählen rückwärts (unten→oben / rechts→links) – Uhrzeiger-Perimeter.
- **BedDouble alle 4 Rotationen** – R-Taste dreht DZ durch alle 4 Positionen: Landscape (0°), Portrait (90°), Landscape 180° (180°), Portrait 180° (270°). `room_rotation` steuert Orientierung + Interior-Drehung; `room_flip` vollständig entfernt. Interior-Transform für 180°-Lagen: Landscape rot 2 → pos (48,32) + rot PI; Portrait rot 3 → pos (32,48) + rot PI.
- **Tür-Kombo-Navigation vereinfacht** – `.`-Taste wechselt durch ALLE gültigen (door_rotation, door_offset)-Kombos in einem Zyklus. `,`-Taste und `F`-Taste freigegeben.

### Bugfixes

- **Snap-Bug bei ungerader Raumbreite** – Ghost rastete auf halben Tiles ein (z.B. 3×2 DZ zeigte 8px-Versatz). Fix: Maus-Offset (halbe Raumbreite) wird vor dem `snappedf()` abgezogen, nicht danach. Gilt für `_process()` und `_try_place()`.
- **Tür hinter Möbeln nach R-Taste** – Nach Raumrotation zeigte die Tür manchmal auf einen ungültigen Slot (z.B. hinter Bett). Fix: `_snap_to_valid_combo()` + zweites `configure()` werden in `_refresh_ghost()` nach `_update_valid_combos()` aufgerufen.
- **BedDouble Floor-Größe** – Portrait-Abschnitt in `Bed_Double.tscn` war noch auf alte 32×64px-Abmessungen; komplett auf 32×48px (2×3 Tiles) aktualisiert.

### Technische Änderungen

- **`Room.gd`** – `TILE_PX` Konstante; `const DOOR_SLOTS: Array[Array]` (4×5 Namen-Matrix); `get_valid_door_slots() -> Array[String]` (virtuell, leer = alle); `get_valid_door_combos()` berechnet nun auto aus Tile-Größe × Slot-Deklaration; `_calc_door_transform(rot, off) -> Dictionary` für Pixel-Positionen; `room_flip` Variable + `flip_room()` entfernt.
- **`BedStandard.gd`** – `DOOR_CONFIGS` Dict + `get_valid_door_combos()` Override entfernt; `get_valid_door_slots()` deklariert `["L1","L2"]`; `_apply_visuals()` nutzt `_calc_door_transform()`.
- **`BedDouble.gd`** – `get_tile_size()` via `room_rotation % 2` (landscape=3×2, portrait=2×3); `get_valid_door_slots()` deklariert `["L1","L2","T1","B2"]`; `set_floor_neighbors()` rotation-aware wie BedStandard; `_apply_visuals()` mit Interior-Transform für alle 4 Lagen; `room_flip` entfernt.
- **`BuildCursor.gd`** – `_room_flip` + `KEY_F` Logik entfernt; `_advance_door_combo()` ersetzt `_advance_rotation()` + `_advance_offset()` + Hilfsmethoden; Signal `room_placed` ohne `room_flip`-Parameter; Snap-Formel korrigiert.
- **`IngameBuild.gd`**, **`MapGrid.gd`**, **`Parzelle.gd`** – `rflip`-Parameter aus `place_room()` / `spawn_room()` / Signal-Handler entfernt.
- **`Bed_Double.tscn`** – Portrait-Sektion vollständig auf 32×48px aktualisiert; Peter ergänzte Landscape-Möbel (Bett, Tisch, Stühle, TV, Pflanzen, Schreibtisch, Bad).
- **`_dev/howto/neuen-raum-hinzufuegen.md`** – Schritt 3 komplett auf Slot-System umgeschrieben.
- **Neue Assets** – `assets/tiles/Doors/`, `assets/tiles/Furniture/`, `assets/tiles/Grounds/`, neue Wall-PNGs (wall_bottom/left/right/top).

### Offene Backlog-Issues

- **ANG-192** – Versatz-Fall (Räume nicht 1:1 ausgerichtet) noch offen; Möbel-Artefakt an erweiterter Wandseite vorhanden
- **ANG-193** – Wall-System Refactor: TileMap-basierte Außenkontur + Trennwände (Backlog, mittelfristig)
- **ANG-191** – Abreiß-Funktion, Zimmernummern, XP-Level-Kurve, FP-Quellen
