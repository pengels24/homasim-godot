# Raum: Familienzimmer

## 1. Identifikation
*   **ID:** `bed_family`
*   **Kategorie:** Z1.2
*   **Grid-Size:** Groß

## 2. Spielmechanik
Familienzimmer mit Platz für bis zu 5 Personen. Relevant für Erholungsurlauber.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/bed_family/Bed_Family.tscn`
*   **Script:** `scenes/ingame/rooms/bed_family/BedFamily.gd`

### 3.1 Besonderheiten (Navigation & Interaktion)
Dieser Raum nutzt ein definiertes Set an Wegpunkten und Markern für das `RoomNavigator`-System:

**Wegpunkte (Waypoints/Interaktion):**
- `BedP, BedK1, BedK2, BedK3 - Einzelne Schlafplätze für Eltern und Kinder.`
- `Bathroom - Interaktionspunkt für Hygiene.`
- `Table1, Table2, Chair1, Chair2, Chair3, Couch1, Couch2, TV - Sitz- und Aufenthaltsbereiche für die Familie.`

**NavBlocker:**
- Der Raum nutzt `NavBlocker`-Nodes (z.B. `NavBlockerBed`, `NavBlockerTV`). Diese blockieren physische Möbelstücke für das Pathfinding, damit Agents nicht durch feste Objekte laufen.
