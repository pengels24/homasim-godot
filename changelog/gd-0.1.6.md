## Version: 0.1.6
**Datum: 2026-04-16**

### Features & Verbesserungen

- **ANG-148 (Fortsetzung)** – Map/Grid-System komplett neu gebaut:
  - Dunkler Hintergrund `#292929` via `RenderingServer.set_default_clear_color()`
  - Semantische Tile-Dateinamen (feste Namen im Code, Art via PNG-Austausch tauschbar):
    - `ground_base.png` – Basisboden (Außenbereich)
    - `ground_walking.png` – 3-Tile-Gehweg-Ring um das Grundstücksraster
    - `ground_floor.png` – Boden eigener Parzellen
    - `ground_brick.png` – Außenwände eigener Parzellen
    - `ground_lobby.png` – 2×2 Lobby-Fläche am Eingang
    - `main_door.png` – Tür-Tile am Parcel-Eingang
  - Smart Wall-Algorithmus (`_is_outer_wall()`): Wände nur an Parcel-Grenzen zu Nicht-Eigenem – keine Wände zwischen benachbarten eigenen Parzellen
  - Lobby-Platzierung (`_place_lobby()`): 2×2 zentriert an der Eingangsseite, Tür-Tile ersetzt Wandtile
  - Camera-Limits mit Viewport-Half-Padding: äußere Tiles vollständig scrollbar
  - `PAN_SPEED`: 100 → 400 (WASD/Pfeiltasten spürbar schneller)

- **ANG-150** – Credits-Seite gebaut (Schritt 1: Layout & Technik):
  - Split-Layout: Links 1/3 (640px fixiert), Rechts 2/3 (1280px Auto-Scroll)
  - Linke Spalte: Logo, „FOLG UNS"-Label, 5 Social-Buttons (3+2 Grid, rund), Zurück-Button
  - Social-Links (YouTube, Discord, Instagram, Tipeee, Ko-fi) via `OS.shell_open()` im Browser
  - Goldene vertikale Trennlinie zwischen Links- und Rechts-Bereich
  - Rechte Spalte: VBoxContainer mit `clip_contents=true`, scrollt automatisch von unten nach oben
  - Inhalt extern in `res://assets/credits.txt` – Format `## Section / = Name / Detailzeilen`
  - Version wird live aus `version.txt` gelesen
  - Credits-Button im Hauptmenü ergänzt
  - `SCROLL_SPEED`-Konstante für einfache Anpassung

### Bugfixes

- **Exit-Crash (await-Guard)**: `_show_tooltip()` und `_on_bottom_button()` hatten `await get_tree().process_frame` ohne Validity-Check. Bei Szenenwechsel während des Awaits wurden freigegebene Nodes zugegriffen. Fix: `is_instance_valid()` Guards nach jedem await eingefügt.
- **Exit-Crash (Typ-Fehler)**: `_sync_time_to_api()` verglich `hotel_id` (float aus API) mit `""` (String) → `Invalid operands 'float' and 'String'`. Fix: Default-Wert `null`, Vergleich `== null`.
- **Exit-Crash (Lambda-Signatur)**: Callback in `_sync_time_to_api()` hatte 4 Parameter (altes HTTPRequest-Format), aber `Api.gd` ruft `callback.call(bool, dict)` auf. Fix: Signatur auf `func(_ok: bool, _data: Dictionary): pass` korrigiert.

### Technische Änderungen

- `scenes/ingame/Ingame.gd`: Map-Konstanten `TILE_BASE/WALK/FLOOR/BRICK/LOBBY/DOOR`, `WALK_W` (ehem. `STREET_W`), `_build_map()`, `_is_outer_wall()`, `_place_lobby()` neu/überarbeitet
- `assets/tiles/`: 6 neue semantische Tile-PNGs (Kenney-Assets umbenannt/kopiert)
- `scenes/credits/Credits.gd` + `Credits.tscn`: neue Szene, vollständig per Code gebaut
- `assets/credits.txt`: externer Credits-Inhalt (editierbar ohne Codeänderung)
- `scenes/main_menu/MainMenu.tscn` + `MainMenu.gd`: `BtnCredits` ergänzt
- `translations/de.csv`: 7 neue Keys für Credits (`credits.title`, Sections, `credits.btn.back`)

### Offene Backlog-Issues

- **ANG-149** – Tutorial-Szene
- **ANG-150** – Credits Schritt 2: Social-Icons (Lucide SVGs), Gradient-Fades, Hintergrundanimation, Musik, Logo-Größe anpassen
- **ANG-151** – Button-Font-Polishing
- **ANG-152** – Settings-Screen (ALT+S)
- **ANG-153** – Lucide-Icons für verbleibende BottomBar-Buttons
