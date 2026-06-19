# Changelog v0.1.27 – Staff-Core & Gäste-Loop

**Datum: 2026-06-19**

## Features & Verbesserungen

### Staff-System (StaffActor)
- **Pathfinding durch Zimmerwände gefixt:**
  - OCC-Grid-Logik korrigiert: Räume werden nun korrekt als massiver Block eingetragen. Das „Loch" an der Türkachel wurde entfernt – der MA betritt/verlässt Zimmer ausschließlich über die `e`-Kachel (Ausgang) vor der Tür, nicht durch die Wand.
  - Direktive `_occ_mark_clearance` für Türkacheln aus `mark_placement` entfernt; Eingang ist für AStar solid.
- **Task-Ziel-Bug behoben:**
  - `StaffActor._process_walking`: Raum-Referenz wurde aus `_current_task["room"]` gelesen, Schlüssel heißt aber `"target"`. Korrigiert → MA findet nach dem Job korrekt seinen nächsten Raum und kehrt dann in die Lobby zurück.
- **ProgressBar beim Arbeiten:**
  - `_work_timer_max` wird beim Job-Start gespeichert.
  - Während `_process_working` wird `RoomStatusIndicator.set_progress()` aufgerufen und füllt die goldene ProgressBar von 0 → 100 %.
  - Nach Abschluss wird die Bar via `hide_progress()` wieder ausgeblendet.
- **Debug-Cleanup:**
  - Rote Pfadlinie (`Line2D _debug_line`) aus `StaffActor` entfernt.
  - `[StaffActor] Pathing from …`, `_path.size()`, `Path size is 0!`-Prints entfernt.
- **Speed-Anpassung:** `SPEED` auf `40.0` px/s reduziert für realistischere Fortbewegung.

### Gäste-System (GuestActor)
- **Lobby als dynamischer POI korrekt eingebunden:**
  - `_get_open_pois()` iteriert nun auch über den Lobby-Node der Startparzelle (via `entry_parcel.get_lobby()`), da die Lobby nicht in `active_rooms` enthalten ist.
  - Lobby-Öffnungszeiten (`open_from: 420`, `open_to: 1320`) werden dadurch korrekt berücksichtigt.
  - Gäste schlendern nun in ihrer Freizeit dynamisch zwischen Zimmer, Lobby und anderen offenen POIs.
- **Pausenfüller (Gäste wandern) reaktiviert:**
  - Alte Logik (`_action_timer = 0.0` wenn keine POIs → Gast ruht ewig) wurde durch das korrekte Einbinden der Lobby als POI behoben.

### TaskManager
- **`clear_all_tasks()` hinzugefügt:**
  - Leert `_tasks`-Array und setzt `_next_task_id` zurück.
- **Aufruf beim Verlassen des Hotels:**
  - `IngameUIManager._on_quit_confirmed()` ruft `TaskManager.clear_all_tasks()` auf, bevor die Szene gewechselt wird.
  - Verhindert das Stapeln von veralteten Tickets über mehrere Spiel-Sessions.

### RoomStatusIndicator
- **`set_progress(value: float)`** – Zeigt den Indicator, macht ProgressBar sichtbar und setzt Wert (0.0–1.0 → 0–100 %).
- **`hide_progress()`** – Versteckt ProgressBar und resettet sie auf 0.

## Debug-Cleanup (allgemein)
- **OCC-Grid-Dump** aus `MapGrid.build_map()` entfernt (ASCII-Textblock nach Map-Aufbau).
- **OCC-Grid-Debug via Taste `P`** (`_unhandled_input`) aus `MapGrid` entfernt.
- **`_show_debug_grid`** in `MapGrid` auf `false` gesetzt → Rotes Gitter-Overlay und gelbe Pathfinding-Linien ausgeblendet.
- **Node-Baum-Print** in `Room._get_obstacle_layers_recursive()` entfernt (\"Prüfe Node: …\", \"→ FOUND TILEMAP: …\").
- **`[StaffActor] found task: …`**-Print bleibt erhalten (Schwarzes Brett Monitoring).

## Bekannte Todos / Nächste Schritte
- Staff-Skill „Bewegung/Laufgeschwindigkeit" in `StaffActor` einbauen (aus `skill_speed`-Property).
- Bar-Integration testen & ggf. Gast-Interaktionen (Konsumation, Verweildauer) vertiefen.
- `NewHotelModal` Textgröße-Anpassung (optisch nicht passend zum großen Dashboard).
