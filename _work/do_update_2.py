import os

changelog_path = "changelog/gd-0.1.53.md"
with open(changelog_path, "a", encoding="utf-8") as f:
    f.write("\n## ?? Gästeverhalten & Lobby Fixes (Session 2)\n\n")
    f.write("- **ANG-361 (Zwangspause):** Komplette Überarbeitung der Ruhepausen-Logik in `GuestActor.gd`. Die Zwangspause triggert nun direkt beim Verlassen eines POIs (inkl. Lobby). Wenn Gäste sich einen POI nicht leisten können, gehen sie nun zwingend auf ihr Zimmer, statt in einem Endlos-Loop zu verharren.\n")
    f.write("- **Feature (Guest Definitions):** `min_poi_rest_time` und `max_poi_rest_time` in `GuestDefinitions.ALL` als einstellbare Properties ausgelagert, statt sie im Code hart zu verdrahten.\n")
    f.write("- **Bugfix (Tooltip):** `State.SITTING` zu den zählbaren States in `CustomTooltip.gd` hinzugefügt, sodass sitzende Gäste (z.B. auf dem Sofa in der Lobby) endlich korrekt als anwesend gezählt werden.\n")

backlog_path = "wiki/alpha_backlog.md"
with open(backlog_path, "r", encoding="utf-8") as f:
    backlog_lines = f.readlines()

new_backlog_lines = []
for line in backlog_lines:
    if line.startswith("## ?? Ungeplante Fixes & Features (Aktuelle Session)"):
        new_backlog_lines.append(line)
        new_backlog_lines.append("- [x] **ANG-361:** Zwangspause nach POI-Besuch komplettiert & Budget-Endlosschleife gefixt\n")
        new_backlog_lines.append("- [x] **Bugfix:** Tooltip Gästezählung (Sofa-Sitzer in Lobby)\n")
        new_backlog_lines.append("- [x] **Refactoring:** Pausenzeiten in GuestDefinitions ausgelagert\n")
    else:
        new_backlog_lines.append(line)

with open(backlog_path, "w", encoding="utf-8") as f:
    f.writelines(new_backlog_lines)

print("Files updated successfully!")
