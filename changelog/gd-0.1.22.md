## Version: 0.1.22
**Datum: 2026-05-07**

### Features & Verbesserungen

- **HUD-Mitte-Position** – BottomBar kann jetzt auf drei Positionen gesetzt werden: Links / Mitte / Rechts. `_apply_bar_anchor()` nutzt `match` statt `if/else` und setzt bei "center" `anchor = 0.5` mit `offset ±bar_w/2`. Bei "center" wandert der Sprung-Button in die freie linke Ecke, MusicControls bleiben rechts. SettingsModal bekommt dritten Button "Mitte" (Button-Breite 110→80px für drei Optionen).
- **assets/UI/ – BottomBar-Grafiken** – `hud_bottom.aseprite` (400×70px NinePatchRect-Hintergrund) und `hud_button_round.aseprite` (55×52px StyleBoxTexture) von Peter in Aseprite erstellt und ins Projekt integriert.

### Technische Änderungen

- **`IngameHud.gd`** – `_apply_bar_anchor()` und `_position_mode_btn()` unterstützen `hud_side == "center"`.
- **`SettingsModal.gd`** – `_make_hud_side_row()` mit drei Werten `["left", "center", "right"]`.
- **`MusicControls.gd`** – Kommentar: bei "center" verhält sich Reposition wie "left" (Audio-Controls bleiben rechts).
- **`translations/de.csv`** – `settings.ui.hud_side.center` = "Mitte" hinzugefügt.
- **Asset-Cleanup** – Alle ungenutzten Tiles nach `_temp/tiles/` verschoben: komplettes `assets/tiles/Rooms/`-Verzeichnis (52 PNGs), root-level `tile_XXXX.png`-Dateien (8 Stück), `floor_hotel.png`, `floor_lobby.png`, `outside_grass.png`, `outside_street.png`, `wall_brick.png`. Aktiv genutzte Assets bleiben in `assets/tiles/`.

### Offene Backlog-Issues

- **ANG-192** – Versatz-Fall + Möbel-Artefakt an erweiterter Wandseite
- **ANG-193** – Wall-System Refactor (TileMap-Außenkontur + Trennwände, mittelfristig)
- **ANG-191** – Abreiß-Funktion, Zimmernummern, XP-Level-Kurve, FP-Quellen
