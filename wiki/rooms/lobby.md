# Raum: Lobby (Rezeption)

## 1. Identifikation
*   **ID:** `lobby`
*   **Kategorie:** Basis-Raum
*   **Grid-Size:** Variable (wird vom System generiert)

## 2. Spielmechanik
Die Rezeption. Generiert Gäste und lässt sie einchecken. Automatisch gebaut, kein manuelles Bauen möglich. Besitzt Nav-Points für das Anstellen.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/lobby/Lobby.tscn`
*   **Script:** `scenes/ingame/rooms/lobby/Lobby.gd`

### 3.1 Besonderheiten (Navigation & Interaktion)
Dieser Raum nutzt ein definiertes Set an Wegpunkten und Markern für das `RoomNavigator`-System:

**Wegpunkte (Waypoints/Interaktion):**
- `Reception1, Reception2, Reception3, Reception4 (Marker2D unter WayPoints) - Zeigen an, wo Gäste zum Einchecken stehen.`
- `SnackPoint1, SnackPoint2, SnackPoint3, SnackPoint4 (Node2D) - Interaktionspunkte für Automaten.`
- `VendingTargetPoint - Zielpunkt für Automaten-Nutzung.`
- `Seat1 bis Seat12 (Node2D/Sprite2D) - Sitzplätze für wartende Gäste.`

**NavBlocker:**
- Der Raum nutzt `NavBlocker`-Nodes (z.B. `NavBlockerBed`, `NavBlockerTV`). Diese blockieren physische Möbelstücke für das Pathfinding, damit Agents nicht durch feste Objekte laufen.

### 3.2 Gast-Spawn & Check-In Flow
> **Wichtig:** Reception-Waypoints liegen physisch ausserhalb der Lobby-Clearance und sind im globalen AStar als **solid** markiert. Der globale AStar kann diese Tiles daher nicht als Pfadziel nutzen.

**Spawn (Gäste-Ankunft):**
1. `GuestActor.start_waiting_in_lobby()` platziert neue Gäste per Direktzuweisung (`global_position`) an einem zufälligen Reception-Waypoint – kein Walk-Pfad nötig (Rezeptions-Modal verdeckt die Szene).
2. `_current_poi_id = "lobby"` wird gesetzt, damit `_execute_walk` beim Check-in den lokalen Lobby-Pfad triggert.
3. Gäste sind **sofort sichtbar** in der Lobby (verbesserter Wusel-Effekt).

**Check-In (nach Bestätigung im Modal):**
1. `_walk_to_room()` erkennt `previous_state == WAITING_IN_LINE` und nutzt `lobby.get_target_tile()` als Startpunkt für den globalen AStar (statt des solid Waypoint-Tiles).
2. `_execute_walk()` prepended automatisch den lokalen Lobby-Pfad (NavMesh) vom Waypoint zur Lobby-Innentür.
3. Dann globaler AStar-Pfad durch den Hotelkorridor zum Zimmertür-Exit-Tile.
4. Lokale Zimmer-Navigation führt den Gast ins Zimmer-Innere.

**Checkout (Abreise):**
- `_walk_to_exit()` nutzt `lobby.get_street_tile()` und ein leeres `path_tiles=[]`.
- `_execute_walk()` navigiert per LOCAL Lobby-Pfad direkt zur Außentür → Despawn.
