import os
import datetime

# 1. Update Changelog
changelog_path = "d:/game-dev/homasim-godot/changelog/gd-0.1.50.md"
with open(changelog_path, "a", encoding="utf-8") as f:
    f.write("\n\n### 23.08.2026 - Pathfinding Fixes (End of Session)\n")
    f.write("- **Bugfix:** GuestActor teleportiert bei fehlendem Pfad zur Zimmertür.\n")
    f.write("- **Bugfix:** Room.gd ersetzt bei INF-Zielen das Ziel durch einen gültigen AStar Punkt im Raum, um Gäste-Wand-Clipping in der Lobby zu verhindern.\n")
    f.write("- **Logs:** `push_warning` für Pfad-Fehlschläge zu regulärem `print` geändert.\n")
    f.write("- **Logs:** GuestActor loggt nun reguläre Status-Wechsel (`_change_state`) analog zum StaffActor.\n")
    f.write("- **Debug:** MapGrid gibt nun bei AStar-Fehlschlägen auf derselben X-Achse die Tile-Solidity für jedes Tile auf der Achse aus.\n")
    f.write("- **Translation:** Fehlender Key `roomdef.name.long.lobby` in `language.csv` ergänzt.\n")

# 2. Update Alpha Backlog
backlog_path = "d:/game-dev/homasim-godot/wiki/alpha_backlog.md"
try:
    with open(backlog_path, "r", encoding="utf-8") as f:
        backlog_content = f.read()
    
    # Simple replace for completed items if they exist, otherwise append.
    if "- [ ] Lobby: Guest clipping / standing in walls" in backlog_content:
        backlog_content = backlog_content.replace("- [ ] Lobby: Guest clipping / standing in walls", "- [x] Lobby: Guest clipping / standing in walls (Fixed via INF valid point replacement)")
    elif "### Bugfixes & Polish" in backlog_content:
        backlog_content = backlog_content.replace("### Bugfixes & Polish\n", "### Bugfixes & Polish\n- [x] Lobby: Guest clipping / standing in walls (Fixed via INF valid point replacement)\n- [x] MapGrid: Pathfinding debug output for straight-line corridor failures\n- [x] GuestActor: Standardized State-Change Logging\n")
    else:
        backlog_content += "\n### Session Bugfixes\n- [x] Lobby: Guest clipping / standing in walls\n- [x] MapGrid: Pathfinding debug output for straight-line corridor failures\n"
        
    with open(backlog_path, "w", encoding="utf-8") as f:
        f.write(backlog_content)
except Exception as e:
    print("Backlog error:", e)

# 3. Write Uebergabe
uebergabe_path = "d:/game-dev/homasim-godot/_work/uebergabe.md"
uebergabe_content = """# Übergabeprotokoll (23.08.2026)

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
"""
with open(uebergabe_path, "w", encoding="utf-8") as f:
    f.write(uebergabe_content)
    
print("Doku updated successfully.")
