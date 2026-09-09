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

### 3.3 Vending Machine / Snack Flow
Der Getränke-/Snackautomat in der Lobby fungiert als Pseudo-POI (`id: "vending_machine"`), der von Gästen aufgesucht werden kann, wenn sie hungrig sind und kein anderer Gastro-POI geöffnet hat.

**Ablauf:**
1. Gast entscheidet sich für den Snackautomaten und läuft zum **`VendingTargetPoint`** (wichtig: dieser Point hat Priorität vor der generischen `has_free_room_seat` Logik, damit der Gast sich nicht vorher auf einen Lobby-Stuhl setzt).
2. Am Automat angekommen (`_on_poi_arrived`) triggert die Bezahl-Animation und das Abziehen des Budgets.
3. Danach sucht sich der Gast dynamisch über `get_snack_eating_target_world()` einen der `SnackPointX`-Marker oder nutzt als Fallback einen freien Sitzplatz (`SeatX`, `ChairX`) in der Lobby, um den Snack zu essen.
4. Nach Ablauf des Timers (`_action_timer`) verlässt der Gast die Lobby wieder.

### Snackomat (Vending Machine) Konfiguration
Die Sättigungsgrenze, ab der Gäste den Automaten aufsuchen, kann über die Konstante VENDING_MACHINE_HUNGER_THRESHOLD (Standard: 40) gesteuert werden, was ein Balancing unabhängig von generellen Restaurant-Besuchen ermöglicht.

### 3.4 TG-Gäste im Checkout-Flow (Spawn via ReceptionX)

Wenn Tagungsgäste nach 17:00 Uhr das Hotel verlassen, spawnen sie über `GuestController._on_party_checked_out_physically()` direkt in der Lobby – an den **ReceptionX-Waypoints** (via `lobby.get_checkout_wait_pos(member.party_id)`). Diese Spawn-Position ist identisch mit der Ankunfts-Position normaler Hotelgäste.

**Wichtig:** Der Actor muss mit `_current_poi_id = "lobby"` initialisiert werden, damit `_walk_to_exit()` → `_execute_walk()` → Phase 1 einen lokalen Pfad durch die Lobby zur Ausgangstür generiert. Ohne das wird kein lokaler Pfad erstellt → der Gast teleportiert sofort zur Exit-Tile → `queue_free()`.

### 3.5 Live Monitor: Gefilterte States

`Lobby.gd → get_live_details()` filtert folgende Actor-States aus der Anzeige aus:
- **`State.WALKING`** – Gäste die gerade durch die Lobby laufen (keine "Verweilenden")
- **`State.LEAVING`** – Abreisende Gäste (passieren die Lobby nur noch, verweilen nicht)

**Warum LEAVING filtern?** Abreisende TG-Gäste spawnen im LEAVING-State an den ReceptionX-Positionen. Ohne Filter: Lobby-Tooltip = 0 (keine geclaimten Interactions), Live Monitor = 12 (alle LEAVING-Actors sichtbar) → verwirrend für den Spieler. Mit Filter: beide Anzeigen konsistent auf 0.
