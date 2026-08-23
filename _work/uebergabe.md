# Übergabeprotokoll (23.08.2026)

## Status
Der User hat die Session beendet. Wir haben das Problem behoben, dass Gäste (insbesondere in der Lobby) in der Wand stehen, indem wir `Vector2.INF` als Ziel in `Room.gd` (`get_local_path`) durch einen validen AStar-Punkt im Raum (`_local_astar`) ersetzen.
Außerdem gab es einen Fehler, bei dem `MapGrid` keinen Pfad zwischen zwei Corridor-Tiles (z.B. `(0, 38)` und `(0, 35)`) fand, was zu einem Notfall-Teleport in `GuestActor.gd` führte.

## Änderungen
- **GuestActor.gd**: `push_warning` bei Pfad-Fehlern in normales `print` geändert. Standard State-Change Log (`[GuestActor] %s changed state: %s -> %s`) in `_change_state` eingebaut. Die alten Debug-Logs (`[DEBUG]`) bleiben weiterhin sauber auskommentiert.
- **Room.gd**: Bei `Vector2.INF`-Target wird nun ein valider Random-Punkt aus dem `_local_astar` gesucht, anstatt die rohe Tür-Koordinate zu nutzen, was das "Steht in der Wand"-Clipping bei der Lobby behoben hat.
- **MapGrid.gd**: Deep-Debug Log in `get_path_between_tiles` eingebaut. Wenn ein Pfad fehlschlägt und Start/Ende auf der gleichen X-Achse liegen (Corridor), werden nun alle Tiles dazwischen samt `is_point_solid` und `_occ`-Wert ins Log geschrieben.
- **language.csv**: Fehlender Key `roomdef.name.long.lobby` hinzugefügt.

## Nächste Schritte (für den nächsten Agenten)
- Sobald das Spiel das nächste Mal läuft, falls der Teleport-Fehler (z.B. von Bar zum Zimmer) auftritt, das Log studieren. Der neue Debug-Output in `MapGrid.gd` wird präzise ausgeben, *welches* Tile zwischen `(0, 38)` und `(0, 35)` im Corridor auf `solid = true` steht oder welchen falschen `_occ` Wert es hat.
- Tokens wurden gespart, die nächste Session startet morgen nach dem regulären Job des Users.
