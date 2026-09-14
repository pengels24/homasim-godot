import os

# Append to changelog
changelog_path = "changelog/gd-0.1.53.md"
with open(changelog_path, "a", encoding="utf-8") as f:
    f.write("\n## 🐛 Bar / Restaurant Fixes (Gastro-Flow)\n\n")
    f.write("- **ANG-356 (Room-Tooltip Bug):** Ankommende Gäste (Walking) werden nicht mehr als anwesend gezählt. `Rect2.has_point` Logik hinzugefügt.\n")
    f.write("- **ANG-359 & ANG-360 (Bar Live-Monitor):** Status-Texte (Wartet auf Service, Wird serviert) gefixt.\n")
    f.write("- **Lobby Bugfix:** Tagungsgäste `(TG)` Tag wird nur noch gesetzt wenn das Event-POI existiert.\n")
    f.write("- **Scope Bugfix:** Godot 4 `for a in ...` Scope-Fehler in Bar.gd und RestaurantSmall.gd Live-Monitoren behoben.\n")
    f.write("- **Consumption Type Logic:** Gäste (`GuestActor.gd`) speichern nun ihren `consumption_type` (food oder drink) basierend auf dem Rezept oder ob es ein Solo-Drink war.\n")
    f.write("- **Trinken vs Essen Fix:** Live-Monitor in Bar und Restaurant unterscheidet nun via `consumption_type` korrekt zwischen `Isst gerade` und `Trinkt gerade`.\n")

# Update Alpha Backlog
backlog_path = "wiki/alpha_backlog.md"
with open(backlog_path, "r", encoding="utf-8") as f:
    backlog_lines = f.readlines()

new_backlog_lines = []
for line in backlog_lines:
    if line.startswith("## 🛠 Ungeplante Fixes & Features (Aktuelle Session)"):
        new_backlog_lines.append(line)
        new_backlog_lines.append("- [x] **ANG-356:** Room-Tooltip Bug (Walking Gäste nicht zählen)\n")
        new_backlog_lines.append("- [x] **ANG-359 & ANG-360:** Bar Live-Monitor Gastro-Flow (Wird serviert)\n")
        new_backlog_lines.append("- [x] **Bugfix:** GuestActor consumption_type (Essen vs Trinken) im Live-Monitor\n")
    else:
        new_backlog_lines.append(line)

with open(backlog_path, "w", encoding="utf-8") as f:
    f.writelines(new_backlog_lines)

print("Files updated successfully!")
