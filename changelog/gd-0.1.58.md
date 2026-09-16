# Changelog – v0.1.58
> Branch: dev | Datum: 16.09.2026 | Session: ANG-314 Save/Load Actor-State Bugfixes

---

## 🐛 Bugfixes

### ANG-314: Actor-State-Serialisierung (Save/Load)

**GuestActor – Wegfindung nach Load:**
- IN_ROOM Hotel-Gaeste: Position nicht mehr restored – setup() platziert korrekt an Zimmertuer
- IN_ROOM TG-Gaeste (kein _target_room): gespeicherte Position restored
- IN_POI / EATING: gespeicherte Position restored (kein Solid-Tile-Problem)
- _get_logical_start_tile(): is-on-solid Check verhindert falschen room_door Start-Tile

**StaffActor – Wegfindung nach Load:**
- restore_save_state: Position wird NICHT restored – configure() in StaffController platziert Staff im P-Raum mit richtigem _current_room
- _work_timer auf 0 gesetzt – kein sofortiger Break-Trigger nach Load
- _start_path_to_room(): Solid-Tile-Korrektur fuer start_tile (8-directional search)
- _start_path_to_room(): Early-Return wenn start_tile == end_tile

**StaffController – Spawn-Reihenfolge:**
- _spawn_actor(): global_position wird IMMER vor restore_save_state gesetzt (Fix: Staff war bei 0,0 = off-screen)

### POI Doppel-Payment Bug (Exploit-Fix)
- Gaeste zahlten beim Load erneut visit_income + EXP (missbrauchbar durch Speichern/Laden in POI)
- Fix: _restoring_from_save Flag in GuestActor eingeführt
- _on_poi_arrived(): Income und EXP werden beim Restore uebersprungen
- _has_claimed_seat = true beim Restore – kein erneuter Sitz-Claim

---

## 🏗️ Technisch

- ANG-364 angelegt: Pathfinding-Ueberarbeitung (Post-Alpha) in Linear
- Debug-Flags zurueckgesetzt: _show_debug_grid = false, SHOW_DEBUG_PATHS = false
- PATH FAILED Debug-Log in _start_path_to_room() fuer weitere Tests aktiv gelassen

---

## ⚠️ Bekannte Einschraenkungen (Pre-Alpha)

- Staff spawnt nach Load immer im P-Raum (nicht an gespeicherter POI-Position) – bewusste Entscheidung bis ANG-364
