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
- **Gym/Pool/Spa:** Der Gast behält sein Sprite (sichtbar).
- **Gastro/Bar:** Der Gast tween't sichtbar zum Platz, setzt sich und wechselt dann auf `STUDYING_MENU` oder `WAITING_FOR_FOOD`.

## Check-in & Lobby
- Beim Spawn werden Gäste (aufgrund der überlappenden UI) sofort auf die Rezeptions-Slots gesetzt (ohne Animation).
- Nach dem Check-in führt `_execute_walk` einen lokalen Pfad zur Lobby-Innentür aus, bevor der globale Pfad zum Zimmer generiert wird.
