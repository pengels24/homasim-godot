## Version: 0.1.14
**Datum: 2026-04-22**

### Features & Verbesserungen

- **ANG-168** – BuildMenu: Radiales Kreismenü für den Baumodus implementiert. Öffnet sich per F2 rechts am Bildschirmrand (24px Abstand). Ring 1: 4 Kategorien (Zimmer, Gastro, Service, Management) mit Lucide-Icons. Ring 2: Räume je Kategorie, dynamisch beim Kategorie-Klick befüllt. Tooltips auf allen Buttons (Kategorie-Label bzw. Raum-Name + Kosten). Äußerer Trennring nur sichtbar wenn Ring 2 aktiv. Gradient-Hintergrund: 3 gestapelte Kreise (außen dunkel → innen heller). Kategorie-Persistenz: letzte gewählte Kategorie wird in `Ingame.gd` gespeichert und beim Neuöffnen direkt wiederhergestellt.

### Bugfixes

- `ROOM_ITEMS` bereinigt: `corridor` entfernt (kein Eintrag in RoomDefinitions.php), `management`-ID korrigiert auf `pl_office`, `hr_office` + `pl_office` auf `locked: true`, `hr_office` aus Service-Kategorie entfernt (nur Management)

### Technische Änderungen

- `scenes/ingame/build/BuildMenu.gd` – Neu: CanvasLayer-basiertes Kreismenü; Signals `room_selected(room_type_id)` und `category_changed(cat_id)`; `initial_category` Property für Persistenz; `_sep_ring2: Panel` für togglbaren Außenring
- `scenes/ingame/build/BuildMenu.tscn` – Neu: Minimale Scene (CanvasLayer + Script-Referenz)
- `scenes/ingame/Ingame.gd` – BuildMenu-Integration: `_toggle_build_menu()`, `_last_build_category` State, `category_changed`-Signal verbunden
- `assets/icons/` – 16 neue Lucide-SVGs (stroke=white): bath, bed, bed-single, bed-double, briefcase, brush-cleaning, chef-hat, cooking-pot, dumbbell, laptop-minimal, presentation, star, users, users-round, utensils, wine

### Offene Backlog-Issues

- **ANG-161** – Zimmer baubar (Standard-EZ + Standard-DZ) – wartet auf Bau-Cursor (nächster Schritt nach ANG-168)
- **ANG-162** – Gäste-System (Spawn, Walk-in, Check-in/out)
- **ANG-163** – Tagesabschluss-Report + Wirtschaft
- **ANG-164** – Techtree – Planungsbüro + Tier 1
- **ANG-165** – Michelin-Inspektor Event
- **ANG-166** – SimBrowser Shell home.sim
- **ANG-167** – BottomBar als eigene Szene auslagern – nach Techdemo
