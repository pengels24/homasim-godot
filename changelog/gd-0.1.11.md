## Version: 0.1.11
**Datum: 2026-04-20**

### Features & Verbesserungen

- **GDD** – `_dev/GDD.md` erstellt und freigegeben: vollständiges Game Design Document für HO·MA·SIM (14 Sections). Abdeckung: Kernmechaniken, Parzellen/Spielfeld, Raumtypen, Gäste-System (inkl. zweistufiger Geduld + 2 Flows), Wirtschaft, Progression (Ruf ad hoc, Spieler-Level/XP, Michelin 1–5 Sterne), Technologiebaum (4 Tiers × 5 Äste, Tier-Gates via FP + Spieler-Level + Michelin + Min-Items), SimBrowser (.sim-Seiten + Easter Eggs), UI/UX (Glassmorphism, Rajdhani/Outfit/Inter, Gold-Blau-Silber), Technische Grundlagen (Local-first + optionale Konto-Bindung), Personal-System (Stub), Tutorial (halbfertiges Hotel + Trigger-Stops). Dokument eingefroren bis Techdemo-Release.
- **ANG-158** – Lobby Tile-Art: Wand-Eck- und Abschluss-Tiles überarbeitet (floor_lobby_wall_*). Eingangs-Pfad-Tiles (`tile_0687.png`, `tile_0688.png`) neu hinzugefügt und in `Lobby.tscn` als TileSetAtlasSources (source/0, /1, /11) eingebunden. Ground-Layer tile_map_data erweitert um Pfad-Tiles an den Eingangspositionen.

### Technische Änderungen

- `Lobby.tscn`: 3 neue TileSetAtlasSources (ground_floor, tile_0687, tile_0688) als Sub-Resources ergänzt; tile_map_data des Ground-Layers um Eingangs-Pfad-Tiles erweitert
- `assets/tiles/`: 10 bestehende Lobby-Tiles aktualisiert + 2 neue Tiles (`tile_0687.png`, `tile_0688.png`) hinzugefügt

### Offene Backlog-Issues

- **ANG-158** – Lobby Door-Tiles für Richtungen bottom/left/right noch ausstehend; `_apply_visuals()` in `Lobby.gd` noch zu implementieren
- **ANG-159** – Login optional: „Spielen" lokal + „Konto verbinden"
- **ANG-153** – RMB-Drag-Freeze-Bug
- **ANG-154** – Scene-Architektur HUD/Dashboard/Credits
- **ANG-155** – Security / Server-seitige Validierung
- **ANG-156** – Export-Targets Steam/GOG
- **ANG-152** – Settings-Screen (Tastenbelegung, UI-Scaling)
- **ANG-149** – Tutorial-Szene
