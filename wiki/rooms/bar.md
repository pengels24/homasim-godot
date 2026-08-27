# Raum: Bar / Lounge

## 1. Identifikation
*   **ID:** `bar`
*   **Kategorie:** G1.1
*   **Grid-Size:** Mittel

## 2. Spielmechanik
Getränke-Ausgabe. Braucht Barkeeper. Kann kleine Speisen (A la carte) anbieten, wenn eine Küche + Kellner vorhanden ist. Öffnungszeiten: 12:00 - 23:30.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/bar/Bar.tscn`
*   **Script:** `scenes/ingame/rooms/bar/Bar.gd`

### 3.1 Besonderheiten & Pathfinding
*   **Kapazität (`max_guests`):** Limitiert auf exakt **8** Gäste (`Chair1` bis `Chair8`). Physisch wie programmatisch (seit `v0.1.50` auch als Property im Dictionary verankert). Findet ein Gast keinen freien `Chair` via `claim_seat()`, bricht er den Besuch ab.
*   **Bedienung & Küche:** Die Bar hängt sich an den Restaurant-Loop. Falls im Hotel eine Küche und Kellner aktiv sind, können Gäste neben Getränken (Basis-Einnahme) auch kleinere Snacks bestellen.
*   **Wegfindung (Gäste):** Folgen dem internen AStar-Netz direkt zu den Hockern.
*   **Wegfindung (Barkeeper):** Der Barkeeper (Personal) nutzt nun ebenfalls das *lokale* AStar-Raumnetz (`get_local_path()`), um seinen Arbeitsplatz (`WorkArea`) hinter dem Tresen zu erreichen. 
    *   *Wichtig für Map-Design:* Die `NavBlocker` der Tresen und Wände müssen einen Spalt von **mindestens 4 Pixeln** aufweisen, damit der Barkeeper-Knoten den Bereich betreten kann.
*   **Rotation:** Die Mittelpunkt-Fallbacks in `Bar.gd` nutzen rotierendes `to_global()`, damit der Barkeeper bei Drehung (R-Taste) der Bar nicht in die Wand läuft oder den Raum verlässt.

## Solo-Modus
Wenn die Küche schließt (_has_active_kitchen() == false), geht die Bar in den Solo-Modus über, d.h. Gäste bezahlen ihre Getränke direkt beim Betreten und warten nicht auf Essen.
