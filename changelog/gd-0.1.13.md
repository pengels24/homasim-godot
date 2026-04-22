## Version: 0.1.13
**Datum: 2026-04-22**

### Features & Verbesserungen

- **ANG-158** – Room-System verdrahtet: Lobby in Unterverzeichnis verschoben, `_apply_visuals()` implementiert – steuert sichtbare Door-Layer (Eingang + gegenüberliegende Innentür als Paar) sowie die Wand-Layer (nur Eingangsseite sichtbar, Gegenseite offen für Korridore)
- **ANG-161** – BedStandard als eigene Scene angelegt (`scenes/ingame/rooms/bed_standard/`) mit 8 Türvarianten (4 Seiten × 2 Positionen); `BedStandard.gd` erstellt mit `_apply_visuals()` – mappt `door_rotation` × `door_offset` auf korrekten Door-Layer-Node

### Technische Änderungen

- `scenes/ingame/map/Parzelle.gd`: preload-Pfad auf Lobby korrigiert (`rooms/Lobby.tscn` → `rooms/lobby/Lobby.tscn`)
- `scenes/ingame/rooms/lobby/Lobby.gd`: Neu – `@onready _door_container: Node2D`, `_apply_visuals()` zeigt nur passende Door/*-Layer und nur die Eingangs-Wand (`Ground/Top|Right|Left|Bottom`)
- `scenes/ingame/rooms/bed_standard/BedStandard.gd`: Neu – erbt von `Room.gd`, `_door_node_name()` mit 4×2 Lookup-Tabelle
- `scenes/ingame/rooms/bed_standard/Bed_Standard.tscn`: Script-Referenz auf `BedStandard.gd` eingetragen
- Neue Tile-Assets: `assets/tiles/floor_lobby_door_*.png` (8 Lobby-Tür-Tiles), `assets/tiles/Rooms/` (Zimmer-Tiles + 8 room_standard_door_*.png)

### Offene Backlog-Issues

- **ANG-168** – Kreismenü Baumodus (Build Circle Menu) – neues Issue angelegt
- **ANG-161** – Zimmer baubar (Standard-EZ + Standard-DZ) – wartet auf ANG-168
- **ANG-162** – Gäste-System (Spawn, Walk-in, Check-in/out)
- **ANG-163** – Tagesabschluss-Report + Wirtschaft
- **ANG-164** – Techtree – Planungsbüro + Tier 1
- **ANG-165** – Michelin-Inspektor Event
- **ANG-166** – SimBrowser Shell home.sim
- **ANG-167** – BottomBar als eigene Szene auslagern – nach Techdemo
