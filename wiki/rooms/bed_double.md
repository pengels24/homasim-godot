# Raum: Doppelzimmer

## 1. Identifikation
*   **ID:** `bed_double`
*   **Kategorie:** Basis-Raum
*   **Grid-Size:** Standard

## 2. Spielmechanik
Größeres Zimmer mit Doppelbett für Paare.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/bed_double/Bed_Double.tscn`
*   **Script:** `scenes/ingame/rooms/bed_double/BedDouble.gd`

### 3.1 Besonderheiten (Navigation & Interaktion)
Dieser Raum nutzt ein definiertes Set an Wegpunkten und Markern für das `SmartRoom`-System:

**Wegpunkte (Waypoints/Interaktion):**
- `Bed1 - Interaktionspunkt zum Schlafen (Doppelbett).`
- `Bathroom - Interaktionspunkt für Hygiene.`
- `Table, Chair1, Chair2, Chair3, TV, Desk - Weitere Ziele für die Gäste-KI.`

> **Info:** Dieser Raum ist vollständig auf die generische **Smart-Room API** (`get_available_interactions`, `claim_interaction`, `release_interaction`) in `Room.gd` migriert. Die Möbel (Betten, Stühle) werden dynamisch aus dem `Furniture`-Container gescannt und von der `GuestActor`-KI belegt, wodurch Hardcoding von Navigations-Routinen entfällt.

**NavBlocker:**
- Der Raum nutzt `NavBlocker`-Nodes (z.B. `NavBlockerBed`, `NavBlockerTV`). Diese blockieren physische Möbelstücke für das Pathfinding, damit Agents nicht durch feste Objekte laufen.
