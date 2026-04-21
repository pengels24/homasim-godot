## Version: 0.1.12
**Datum: 2026-04-21**

### Features & Verbesserungen

- **HUD – TopBar** – Logo entfernt (überflüssig wie bei Anno/Tropico), HBox-Separation auf 20 erhöht, flexibler Spacer zwischen StatsSection und TimeSection eingefügt → Zeit+Controls rechtsbündig, Stats linksbündig
- **HUD – BottomBar** – Hilfe-Button (F1) und Hauptmenü-Button (ESC) aus der BottomBar entfernt; ESC-Tastenkürzel bleibt aktiv (schließt Submenüs, geht ins Dashboard); Hotkeys um eine Stelle verschoben (Bauen jetzt F2 statt F3 etc.)
- **HUD – HintLabel** – Steuerungshinweis unten links entfernt (war zu klein zum Lesen, unnötig)
- **HUD – BottomBar Radial-Fächer** – komplettes Redesign: horizontale schwebende Bar ersetzt durch radialen Fächer aus der unteren linken Ecke. Viertelkreis-Hintergrund via StyleBoxFlat corner_radius_top_right, zwei konzentrische Button-Ringe (Ring 1: 3 Buttons – Bauen/Browser/Einstellungen, Ring 2: 4 Buttons – Rezeption/Personal/leer/Forschung), goldene Trennringe zwischen den Zonen, goldener Modus-Indikator-Kreis in der Ecke, Schlagschatten auf Buttons für 3D-Knopf-Effekt

### Technische Änderungen

- `Ingame.gd`: `_build_bottom_bar()` komplett neu – kein HBoxContainer mehr; Buttons per `cos/sin` auf Kreisbögen positioniert (`layout_mode = 0`); neue Helfer `_make_fan_btn()`, `_make_fan_stylebox()`, `_make_mode_indicator()`; alter `_make_icon_btn()` entfernt
- `Ingame.gd`: Neue Konstanten `BB_RING1_RADIUS`, `BB_RING2_RADIUS`, `BB_RING1_COUNT`, `BB_BTN_SIZE`, `BB_FAN_SIZE`, `BB_ANGLE_MIN/MAX` für alle Fan-Geometrie-Parameter
- `Ingame.gd`: Button-Reihenfolge in `_bb_btn_defs` geändert – Ring 1 = häufig genutzte Actions (Bauen, Browser, Einstellungen), Ring 2 = erweiterte/gesperrte Features
- `Ingame.gd`: Icons fix zentriert positioniert (layout_mode=0, explizite size+position) statt anchor-fill – verhindert ungewolltes Hochskalieren
- `Ingame.tscn`: `BottomBarAnchor` von zentriert-unten auf links-unten umgeankt (anchor_left/right=0.0), Größe auf 200×200px
- `Ingame.tscn`: `HintLabel` Node entfernt

### Offene Backlog-Issues

- **ANG-167** – BottomBar als eigene Szene (BottomBar.tscn) auslagern – nach Techdemo
- **ANG-158** – Lobby Door-Tiles bottom/left/right + `_apply_visuals()` in Lobby.gd
- **ANG-161** – Zimmer baubar (Standard-EZ + Standard-DZ)
- **ANG-162** – Gäste-System (Spawn, Walk-in, Check-in/out)
- **ANG-163** – Tagesabschluss-Report + Wirtschaft
- **ANG-164** – Techtree – Planungsbüro + Tier 1
- **ANG-165** – Michelin-Inspektor Event
- **ANG-166** – SimBrowser Shell home.sim
