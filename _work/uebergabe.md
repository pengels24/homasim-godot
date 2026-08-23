# Übergabeprotokoll (Session vom 2026-08-22)

## Letzter Stand
- Wir waren dabei, schwerwiegende Pathing-Bugs (Gäste laufen "Luftlinie durch die Wand" beim Verlassen von Räumen) in `GuestActor` und `Room` zu untersuchen und zu fixen.
- Ein Fix für `path_tiles.size() > 0` in `_execute_walk` wurde eingebaut, damit Gäste beim Verlassen in Richtung nahegelegener Zimmer korrekt den lokalen Pfad aus dem aktuellen Raum nehmen.
- Nach diesem Fix (bzw. während des Tests) hat der User bemerkt, dass es nun scheinbar schlimmer geworden ist:
  - Gäste laufen nun wieder hinter den Tresen in der Bar (Workfloor-Bereich).
  - Es tauchten "path failed" Logs vom alten System auf.
  - Gäste nutzen die Lobby nun zum Sitzen UND verlassen diese dann durch die Wand, oder sie stehen an Positionen, wo sie theoretisch gar nicht hinkönnen sollten.
- Der Test wurde hier unterbrochen ("mit Blick auf die Uhr... machen mit dem Testen morgen weiter").

## Bearbeitete Systeme
- **GuestActor.gd**: `_execute_walk` wurde modifiziert, um Phase 1 (Local Path Out) robuster zu erzwingen, selbst wenn der globale Pfad leer ist (z.B. wenn Start-Tile == End-Tile). Argument `actor_id` an `get_local_path` durchgereicht.
- **Room.gd**: `get_local_path` hat nun einen optionalen dritten Parameter `actor_id` und gibt einen Debug-Print (`[AStar Bug]`) aus, falls ein lokaler Pfad über AStar2D nicht gefunden wird, obwohl Start und Ziel valide sind.
- **Bar.gd**: Rotation für Barkeeper hinzugefügt (`get_work_look_dir`).

## Nächste Schritte (Startpunkt für den neuen Chat)
1. **Dringend:** Evaluierung der Nebenwirkungen des letzten Fixes in `GuestActor._execute_walk`. Warum verlassen Gäste nun die Lobby nach dem Besuch durch Wände? Der Weg in die Lobby ist funktional.
2. **Workfloor-Barriere:** Gäste laufen in der Bar in den braunen "Workfloor"-Bereich hinter den Tresen (würde theoretisch nicht passieren wenn die Gäste keinen zusätzlichen Aufenthalt im POI buchen - also nur eintreten - bestellen - essen - verlassen). Hier muss geklärt werden, wie man den Workfloor explizit für Gäste sperrt, OHNE das grüne AStar2D-Gitter zu unterbrechen (Vorschlag: NavigationLayers, Point-Weights oder eigene AStar-Instanz für Staff).
3. **Path Failed Analyse:** Die erwähnten "path failed" Meldungen des Users müssen im nächsten Chat untersucht werden, um zu verstehen, welche Pfade nun fehlschlagen.
4. Geduldig und besonnen mit dem User weitertesten, er ist etwas frustriert vom Bar-Bug. Keine voreiligen Schlüsse ziehen, immer die Logs und Screenshots anfordern! Grund ist das ein vorheriger Agent durch Halluzination das bereits laufende System zerstört hat.
