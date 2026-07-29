# Raum: Superior-Zimmer

## 1. Identifikation
*   **ID:** `bed_superior`
*   **Kategorie:** Z1.3
*   **Grid-Size:** Groß

## 2. Spielmechanik
Luxuszimmer, 2 Betten. Gibt einen Bonus auf Zufriedenheit. Wichtig für Business und VIPs.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/bed_superior/Bed_Superior.tscn`
*   **Script:** `scenes/ingame/rooms/bed_superior/BedSuperior.gd`

### 3.1 Besonderheiten (Navigation & Interaktion)
Dieser Raum nutzt ein definiertes Set an Wegpunkten und Markern für das `RoomNavigator`-System:

**Wegpunkte (Waypoints/Interaktion):**
- `BedP - Interaktionspunkt zum Schlafen (Luxusbett).`
- `Bathroom - Interaktionspunkt für Hygiene.`
- `Table1, Chair1, Chair2, Couch1, Couch2, Desk, TV - Gehobene Interaktionspunkte für anspruchsvolle Gäste.`

**NavBlocker:**
- Der Raum nutzt `NavBlocker`-Nodes (z.B. `NavBlockerBed`, `NavBlockerTV`). Diese blockieren physische Möbelstücke für das Pathfinding, damit Agents nicht durch feste Objekte laufen.
