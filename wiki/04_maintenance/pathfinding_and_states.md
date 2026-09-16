# Guest Navigation & State Machine

## Übersicht
Gäste (GuestActor) nutzen eine State-Machine (`current_state`), um ihren Tagesablauf zu steuern. Die Navigation im Hotel ist zweigeteilt in **globale Wegfindung** (zwischen Räumen/Fluren) und **lokale Wegfindung** (innerhalb eines Raumes).

## Lokale vs Globale Pfadfindung
- **Globaler AStar (`MapGrid.gd`)**: Kennt nur die Flure (Parzellen). Alle Raum-Kacheln (Tiles, auf denen ein Zimmer/POI gebaut wurde) sind im globalen AStar als `SOLID` (blockiert) markiert.
- **Lokaler AStar (`Room.gd` / `POI.gd`)**: Jeder Raum besitzt ein eigenes Navigations-Grid. Es verbindet die Innenseite der Raumtür (Entry Pos) mit den Interaktionspunkten (Betten, Hocker, Trainingsgeräte).

## Der "Logical Start Tile"
Wenn ein Gast entscheidet, den aktuellen Raum zu verlassen, muss die globale Wegfindung gestartet werden. Da der Gast sich physisch oft tief *im* Raum befindet (z. B. auf einem Barhocker), würde ein Start der globalen Wegfindung an seiner Pixel-Position fehlschlagen, da diese Kachel im globalen Grid `SOLID` ist.

Hier greift `_get_logical_start_tile()`:
```gdscript
func _get_logical_start_tile() -> Vector2i:
	if current_state == State.IN_ROOM or current_state == State.SITTING or current_state == State.SLEEPING or current_state == State.IDLE:
        # Gast ist in seinem eigenen Hotelzimmer -> Nutze die Zimmertür
        # ...
	elif not _current_poi_id.is_empty() and current_state != State.WALKING and current_state != State.LEAVING:
        # Gast ist tief in einem POI (Restaurant, Gym, Lobby)
        # -> Nutze das Target-Tile (Kachel vor der Tür) des POIs
        # ...
	
	# Fallback (Gast ist auf dem Flur / am Laufen)
	return _get_current_tile()
```
**Wichtig:** Es ist essenziell, nicht auf hardcodierte POI-Zustände (wie `EATING`, `WAITING_FOR_FOOD`) zu prüfen, sondern generisch über `_current_poi_id` zu gehen, da unvorhergesehene Statuswechsel (z. B. durch 23:00 Uhr Nachtruhe) sonst unweigerlich zu `Path failed: SOLID`-Crashes und Notfall-Teleports führen.

## Statuswechsel am POI
- **Betreten:** Der Tween (`_active_tween`) steuert den Gast von der Tür zum POI-Objekt.
- **Smart-Rooms (Gym/Pool/Spa/Conference):** Der Gast wechselt in `IN_POI`. Der Action-Timer läuft dort ab. Sobald der Timer auf 0 ist, sucht sich der Gast eine neue Interaktion im Raum (`release_interaction` -> `claim_interaction`), bis die Gesamt-Aufenthaltsdauer abgelaufen ist. 
- **Gastro-Rooms (Restaurant/Bar):** Diese Räume umgehen den `IN_POI` Loop! Sobald der Gast an seinem Tisch ankommt, wechselt er sofort in den Status `STUDYING_MENU`. Dies verhindert ständige Sitzplatzwechsel, während er auf den Kellner wartet.

## Check-in & Lobby
- Beim Spawn werden Gäste (aufgrund der überlappenden UI) sofort auf die Rezeptions-Slots gesetzt (ohne Animation).
- Nach dem Check-in führt `_execute_walk` einen lokalen Pfad zur Lobby-Innentür aus, bevor der globale Pfad zum Zimmer generiert wird.

## Save/Load Verhalten (ANG-314, v0.1.58)

### GuestActor restore_save_state
- **IN_ROOM (Hotel-Gast):** Position wird **nicht** restored – setup() platziert den Gast korrekt an der Zimmertür. Direkte Positions-Zuweisung aus dem Save würde oft auf Solid-Tiles landen (Gast war mid-Tween beim Speichern).
- **IN_ROOM (TG ohne _target_room):** gespeicherte Position wird restored, da kein Zimmer als Referenz vorhanden.
- **IN_POI / EATING:** gespeicherte Position wird restored. _restoring_from_save = true verhindert doppeltes Payment und EXP in _on_poi_arrived(). _has_claimed_seat = true verhindert erneuten Sitz-Claim.
- **AWAITING_CHECKOUT:** Position restored (Lobby = walkable Tiles, kein Problem).

### StaffActor restore_save_state
- **Position:** Wird **nicht** restored. StaffController._spawn_actor() setzt die Position vor 
estore_save_state() auf die Staff-Raum-Service-Position. Damit startet Staff immer im P-Raum nach einem Load.
- **_work_timer:** Wird auf 0 gesetzt – verhindert sofortigen Break-Trigger wenn gespeicherter Timer hoch war.
- **State/Task:** Wird korrekt restored (working → Task re-attached, sonst idle).
- **Grund für kein Position-Restore:** configure() setzt _current_room = spawn_room (P-Raum). Würde Position auf POI-Inneres (Solid-Tile) gesetzt, widerspricht dies dem gesetzten _current_room → kaputtes Pathfinding.

### Bekannte Einschränkung (ANG-364)
Das 1-Layer-AStar-System unterscheidet nicht klar zwischen globalem Korridor-Netz und lokalem POI-Inneren. Akteure die innerhalb von Räumen (Solid-Tiles im globalen AStar) navigieren müssen, lösen Emergency-Fallbacks aus. **Lösung:** ANG-364 (Post-Alpha Pathfinding-Rework).
