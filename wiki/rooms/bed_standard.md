# Raum: Einzelzimmer

## 1. Identifikation
*   **ID:** `bed_standard`
*   **Kategorie:** Basis-Raum
*   **Grid-Size:** Kompakt

## 2. Spielmechanik
Basis-Zimmer für Budget/Singles/Business. Beinhaltet ein Bett. Keine Zufriedenheitsboni.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/bed_standard/Bed_Standard.tscn`
*   **Script:** `scenes/ingame/rooms/bed_standard/BedStandard.gd`

### 3.1 Besonderheiten (Navigation & Interaktion)
Dieser Raum nutzt ein definiertes Set an Wegpunkten und Markern für das `RoomNavigator`-System:

**Wegpunkte (Waypoints/Interaktion):**
- `Bed1 - Interaktionspunkt zum Schlafen.`
- `Bathroom - Interaktionspunkt für Hygiene.`
- `Table, Chair1, TV, Plant - Weitere potenzielle Interaktions-/Navigationsziele für den Raum-State.`

**NavBlocker:**
- Der Raum nutzt `NavBlocker`-Nodes (z.B. `NavBlockerBed`, `NavBlockerTV`). Diese blockieren physische Möbelstücke für das Pathfinding, damit Agents nicht durch feste Objekte laufen.
