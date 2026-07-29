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
