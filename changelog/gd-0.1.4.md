## Version: 0.1.4
**Datum: 2026-04-16**

### Features & Verbesserungen
- **ANG-148** – Ingame-Grundgerüst vollständig implementiert:
  - **TileMap**: Programmatischer TileSet-Aufbau aus Kenney-Einzeltiles (STREET, GRASS, FLOOR, LOBBY, WALL). `_build_tileset()` registriert jeden Tile als eigene TileSetAtlasSource.
  - **Grid**: 5×5 Parzellen à 16×16 Tiles, 3-Tile-Straßenrand, Scale ×2 → 32px/Tile sichtbar. Parzellenfläche = TILE_FLOOR als neutraler Untergrund.
  - **Lobby**: Generische `_place_room()`-Funktion platziert einen 4×4-Raum (2×2 Boden + 1-Tile-Wandring) zentriert an der straßenseitigen Parzellenecke. Türöffnung (2 Tiles) auf Eingangsseite. Wiederverwendbar für alle künftigen Raumtypen (Zimmer, Büros usw.).
  - **Kamera**: WASD-Pan, Scrollrad/+−-Zoom (ZOOM_MIN=0.5, ZOOM_MAX=4.0), RMB-Drag. Clamp-Grenzen auf Map-Bounds. Startposition über Lobby-Parzelle.
  - **HUD TopBar**: Alle API-Felder angebunden – `day_counter`, `money`, `xp`/`xp_needed` (ProgressBar), `reputation` (ProgressBar 0–1000), `research_points`. Hotel-Name und Level aus `selected_hotel`.
  - **Spielzeit**: Lokale Uhr (`SECONDS_PER_GAME_MINUTE = 2.0`), Pause/Play/FF (×10). Startet immer pausiert. Sync an `/api/hotel/sync-time` beim Verlassen und bei `NOTIFICATION_PREDELETE`.
  - **BottomBar**: Schwebendes Panel (F2–F7 + ESC), programmatisch gebaut. Submenü-Platzhalter ("kommt mit dem Feature"). Hotkeys F2–F7 + ESC verdrahtet.
  - **ContextBar**: R/T/Z-Shortcuts für Baumodus, standardmäßig versteckt.
  - **Spielsteuerung**: Pause/Play/FF-Buttons im TopBar mit Gold-Highlight für aktiven Modus.

- **HUD-Design**: TopBar-Höhe 68px (Margins 9px t/b). Logo als PNG (235×50px, transparent, `expand_mode=0`). Schriften angehoben: Key-Labels 11px, Stat-Values 16px, Hotel-Name 20px, Spielzeit 22px. HF_*-Konstanten für spätere ANG-152-Skalierung vorbereitet. GoldAccent entfernt (redundant zu Logo-Brackets).

- **ANG-152 angelegt** – Settings-Screen (ALT+S): Gameplay, Audio, Oberfläche (drei Tabs mit Slidern), noch nicht implementiert.

### Bugfixes
- **FF-Button-Highlight**: `_update_speed_buttons()` prüfte `_game_speed == 3.0` statt `10.0` → FF-Button blieb grau. Fix: `10.0`.

### Technische Änderungen
- `project.godot`: `window/stretch/mode="canvas_items"` + `aspect="expand"` für Viewport-Skalierung ergänzt.
- `translations/de.csv`: Ingame-Keys hinzugefügt (`ingame.btn.*`, `ingame.ctx.*`, `ingame.submenu.coming_soon`).
- `assets/tiles/`: Kenney-Tiles (outside_street, outside_grass, floor_hotel, floor_lobby, wall_brick) für TileSet-Aufbau.
- `assets/images/logo-transparent-50.png`: Neues Logo-PNG (235×50px, transparenter Hintergrund).
- `scenes/ingame/Ingame.gd` + `Ingame.tscn`: Neu, vollständig (ANG-148).

### Offene Backlog-Issues
- **ANG-149** – Tutorial-Szene implementieren
- **ANG-150** – Credits + Social Links
- **ANG-151** – Button-Font-Polishing
- **ANG-152** – Settings-Screen (ALT+S): Gameplay, Audio, Oberfläche
