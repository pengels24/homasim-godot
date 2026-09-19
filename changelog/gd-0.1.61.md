# Changelog – v0.1.61
> Session: 19.09.2026 | Branch: `dev`

## 🐛 Bugfixes

### Luftlinien-Pathfinding nach Save/Load (ANG-314 Folge-Fix)
**Root-Cause:** Mehrschichtiges Problem in `GuestActor.restore_save_state()` und `get_save_state()`:
1. `STUDYING_MENU`-State wurde als `IN_ROOM` gespeichert → nach Reload war `_current_poi_id = ""` → `_get_current_room_node()` fand den POI-Raum nicht → Phase 1 von `_execute_walk()` (lokaler Austrittspfad) generierte kein `world_path` → erster Tween-Schritt sprang direkt zu einem globalen Pfadpunkt (Luftlinie durch Wände).
2. `IN_POI`/`EATING`-State wurde nach Restore fälschlicherweise als `IN_ROOM` gesetzt → alle Gäste verließen gleichzeitig ihre POIs nach 3–7s ("Feueralarm"-Effekt).
3. `IN_ROOM`-Branch (für Rückwärtskompatibilität) setzte `_current_poi_id` für alle Gäste → Regression bei Hotel-Gästen die beim Speichern `WALKING` waren (falsche Raum-ID für Phase 1).

**Fix (GuestActor.gd):**
- `get_save_state()`: `STUDYING_MENU` → mapped nun auf `IN_POI` (statt `IN_ROOM`), damit `_current_poi_id` erhalten bleibt.
- `restore_save_state()` IN_POI/EATING-Branch: State bleibt `IN_POI` (kein vorzeitiger Wechsel zu `IN_ROOM`). Timer wird aus Save-Data restored (min. 5s). Gäste bleiben sichtbar an ihrem Platz.
- `restore_save_state()` IN_ROOM-Branch (TG-Gäste): `_current_poi_id` wird nur gesetzt wenn der Gast auf einem **solid tile** gespeichert wurde (= wirklich innerhalb eines POI-Raums). Hotel-Gäste bleiben unberührt.
- `_snap_to_poi_exit_deferred()` entfernt (war temporärer Workaround, nicht mehr nötig).

**Ergebnis:** Gäste spawnen nach Reload an ihren gespeicherten Plätzen (Restaurant, Bar etc.), bleiben dort bis ihr Timer natürlich abläuft, und verlassen den Raum dann korrekt ohne Luftlinie.

## 📝 Architektur-Dokumentation

### ANG-364 Tech-Note angelegt
- `wiki/_dev/ang364_nav_rework.md` neu erstellt
- Dokumentiert die beiden Root-Causes des Pathfinding-Problems (zwei Nav-Systeme, berechnete Positionen)
- Enthält Peters Konzept für den Post-Alpha Nav-Rework: einheitliches 4×4 Tile-System, Tile-IDs statt Welt-Koordinaten, variable Gangbreiten als Spieler-Feature

## ⚠️ Bekannte Einschränkungen (aus dieser Session)
- TG-Gäste erreichen die Konferenz ~7 Minuten zu spät (13:37 statt 13:30) – Pre-Trigger bei 13:20 fehlt noch (separates Ticket)
- ~1 von 3 Reloads kann noch einen Gast mit Luftlinie zeigen (Race-Condition beim Map-Init, verschwindet nach neuem Save)
