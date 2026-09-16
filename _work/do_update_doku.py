import os

changelog_path = r"d:\game-dev\homasim-godot\changelog\gd-0.1.57.md"
backlog_path = r"d:\game-dev\homasim-godot\wiki\alpha_backlog.md"

# 1. Update Changelog
with open(changelog_path, 'r', encoding='utf-8') as f:
    cl_content = f.read()

new_cl_items = """
- **Tutorials & Codex Update:**
  - Added new tutorials for the "Hotel Overview" (F9) and the "Data Overlays" (left HUD edge), including triggers to unlock them upon first use.
  - Rewrote the main HUD welcome tutorial description to match the new UI layout.
  - Added a Codex entry for the "Gourmet Inspector" which unlocks automatically after the first inspection report is delivered (instead of spoiling his arrival!).
  - Repaired translation string mapping for the VIP Codex entry, fixing a truncation bug in German and removing redundant titles.
- **Bugfix (Save/Load):**
  - Fixed a critical bug where Lobby upgrades (WLAN, Klima) were not saved. The Lobby is now correctly serialized into the plot's room data upon upgrade, and its existing instance gracefully receives the data upon reload instead of creating duplicates.
"""

if "Tutorials & Codex Update:" not in cl_content:
    with open(changelog_path, 'a', encoding='utf-8') as f:
        f.write(new_cl_items)

# 2. Update Backlog
with open(backlog_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

new_lines = []
inserted = False
for line in lines:
    if line.startswith("- [x] **ANG-362 HUD-Sterne Overlay (offen):**"):
        new_lines.append(line)
        if not inserted:
            new_lines.append("- [x] **Bugfix & Polishing:** Lobby speichert nun Raum-Upgrades (WLAN, Klima) korrekt.\n")
            new_lines.append("- [x] **Tutorial-Updates:** HUD Welcome-Texte überarbeitet, Tutorials für F9-Hotel-Overview und Overlays hinzugefügt.\n")
            new_lines.append("- [x] **Inspektor:** Codex-Eintrag für Gourmet Inspector hinzugefügt (wird erst nach Abreise freigeschaltet).\n")
            inserted = True
    else:
        new_lines.append(line)

with open(backlog_path, 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("Changelog and Backlog updated.")
