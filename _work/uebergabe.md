# Übergabeprotokoll – v0.1.61
> Erstellt: 19.09.2026 | Commit: 2c1baa9

---

## Letzter Stand

Der Luftlinien-Pathfinding-Bug nach Save/Load ist **weitgehend gefixt** (2 von 3 Reloads sauber mit altem Save, frische Saves laufen sauber). TG-Gäste sitzen nach Reload wieder in Restaurant/Bar und verlassen es erst wenn ihr Timer natürlich abläuft. Kein "Feueralarm"-Exodus mehr.

## Was wurde gearbeitet

### GuestActor.gd – Save/Load Fix (Luftlinie)
- `get_save_state()`: `STUDYING_MENU` → `IN_POI` (statt `IN_ROOM`). Erhält `_current_poi_id` im Save.
- `restore_save_state()` IN_POI/EATING: State bleibt `IN_POI`, Timer aus Save restored (min. 5s), `_restoring_from_save` Flag aktiv.
- `restore_save_state()` IN_ROOM (TG-Gäste): `_current_poi_id` nur setzen wenn saved position ein solid tile ist.
- `_snap_to_poi_exit_deferred()` entfernt (war veralteter Workaround).

### Warum es vorher nicht funktionierte
`_get_current_room_node()` prüft `_current_poi_id` ZUERST. War die ID leer → Phase 1 von `_execute_walk()` fand keinen Raum → kein lokaler Austrittspfad → Luftlinie. Die ID war leer weil STUDYING_MENU als IN_ROOM gespeichert wurde und der IN_ROOM-Restore-Branch die ID nicht setzte.

### Architektur-Notizen
- `wiki/_dev/ang364_nav_rework.md` angelegt: Peters Konzept für Post-Alpha Nav-Rework (einheitliches 4×4 Grid, Tile-IDs statt Welt-Koordinaten)
- `wiki/02_features/25_techdoku_guestactor.md`: Save/Load Sektion (Kapitel 11) hinzugefügt

---

## Offene Punkte (priorisiert)

1. **TG Pre-Trigger bei 13:20** (NEU): TG-Gäste kommen 7 Min zu spät zur Nachmittags-Session. `is_event_time` feuert erst bei 810 (13:30). Sollte bei ~800 (13:20) feuern damit Gäste um 13:30 ankommen.
   - Datei: `GuestActor.gd`, `_process_waiting()`, Zeile ~324
   - Trigger: `var is_pre_event_time = (current_time >= 455 and current_time < 465) or (current_time >= 800 and current_time < 810)`

2. **Conference POI ausblenden für normale Gäste** wenn Event läuft: `_get_open_pois()` zeigt Conference auch normalen Gästen.

3. **ANG-365:** Techtree/Level Alignment.

4. **Race-Condition (selten)**: ~1 von 3 Reloads zeigt noch einen Gast mit Luftlinie. Verschwindet nach neuem Save. Wahrscheinlich AStar nicht vollständig initialisiert beim ersten `_process_waiting` Tick.

---

## Sofortiger nächster Schritt

Pre-Trigger für TG-Nachmittags-Session in `_process_waiting()` einbauen. Einfache Änderung: Zeitbereich auf 800-810 für Pre-Event und Bewegung auslösen. Oder `is_event_time` Grenze auf 800 statt 810 für Nachmittag setzen.