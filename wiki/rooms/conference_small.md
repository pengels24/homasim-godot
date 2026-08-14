# Conference Small (Tagungsraum)
**ID:** `conference_small`
**Kategorie:** Prestige

## Funktionsweise
Der Tagungsraum (Conference Small) bietet Platz für bis zu 12 Personen (11 Zuhörer, 1 Redner). Gäste besuchen den Raum während ihrer Freizeit (`IN_POI` State) und interagieren auf einzigartige Weise mit der Bestuhlung:
- **Rednerpult (`Chair12`):** Dies ist der designierte Sitz für den aktuellen Redner. Er befindet sich vor dem U-förmigen Konferenztisch.
- **Zuhörer (`Chair1` bis `Chair11`):** Gäste suchen sich einen freien Zuhörerplatz.
- **Rotation:** Wenn das Pult frei ist, kann ein Gast als Redner ans Pult wechseln (für ca. 10-15 Ingame-Minuten). Danach tritt der Gast zurück auf einen normalen Stuhl und erhält einen Cooldown (10-15 Ingame-Minuten), bevor er wieder versucht, das Pult zu übernehmen.

## Navigation & Wegfindung
- Die Navigation innerhalb des Raumes nutzt einen lokalen `AStar2D` Graph (`Room.get_local_path()`), um Gäste exakt um die Stühle und den Tisch zu navigieren.
- Der Wechsel zwischen Stühlen und Pult wird mit einem animierten Tween (`_execute_poi_move()`) in `GuestActor.gd` durchgeführt.
- **NavBlocker:** Das U des Tisches wird von `NavBlocker`-Nodes blockiert, sodass Gäste nicht in den inneren Bereich des U laufen. Das Pult (`Chair12`) liegt außerhalb dieser Blocker und ist regulär angebunden.

## Stats & Limitierungen
- Kapazität: max 12 Gäste (`max_guests = 12`)
- Raumgröße: 3x2 (Landscape 48x32)
- Erholungswerte (`need_restoration`): Standard POI Logik
