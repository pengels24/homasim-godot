import os

alpha_backlog_path = r"d:\game-dev\homasim-godot\wiki\alpha_backlog.md"
uebergabe_path = r"d:\game-dev\homasim-godot\_work\uebergabe.md"

# 1. Update uebergabe.md
uebergabe_content = """# Übergabeprotokoll (Ende von Session Gastro-Loop / UI Fixes)

## Letzter Stand
Der Gastro-Loop mit Waiter-Integration funktioniert nun. 
Die Bugs im Live Monitor der Lobby (falsche Enum-IDs für GuestActor-States und interne Node-Namen statt Klarnamen) wurden behoben.
Der harte 22:00 Uhr Rausschmiss aus POIs wurde entfernt (Gäste gehen nun organisch ab 23:00 Uhr ins Bett).
Die Bar schaltet korrekt in den Solo-Modus zurück, wenn die Küche schließt.
Waiters führen im Idle-Zustand nun "Dummy-Clean" Tasks an sauberen Tischen aus, um geschäftig zu wirken (inklusive Fortschrittsbalken und Besen-Icon).

## Nächste Schritte (TODOs)
1. **NavGrid / Pathfinding für Betten im Personalraum fixen:** 
   Personal setzt sich an das Fußende (auf unsichtbare Sitze oder den Rand) anstatt im Bett zu schlafen. Offenbar reichen die AStar-Punkte nicht bis zum Ziel (Zentrum des Bettes). Dies in `StaffSmall.gd` bzw. MapGrid analysieren (Target-Nodes nach oben verschieben oder Snap am Pfadende forcieren).
2. **Phase 4 & 5 aus dem Alpha-Backlog:** Sobald das Personal komplett rund läuft.

Viel Erfolg!
"""

with open(uebergabe_path, "w", encoding="utf-8") as f:
    f.write(uebergabe_content)

print("uebergabe.md created.")

# 2. Add open point to alpha_backlog.md
with open(alpha_backlog_path, "r", encoding="utf-8") as f:
    backlog_lines = f.readlines()

new_backlog = []
for line in backlog_lines:
    if "### Ungeplante Tasks & Fixes" in line:
        new_backlog.append(line)
        new_backlog.append("- [x] Bar Solo-Modus Rückkehr (Küche zu -> Bar im Self-Service)\n")
        new_backlog.append("- [x] Waiter Idle-Patrol (Dummy-Clean an Tischen) + Force Room Indicator Icon\n")
        new_backlog.append("- [x] Live-Monitor Lobby Guest-Namen und Status-IDs gefixt\n")
        new_backlog.append("- [ ] **BUG:** Personalraum Betten-Pathfinding (Staff sitzt am Fußende anstatt im Bett zu liegen)\n")
    else:
        new_backlog.append(line)

with open(alpha_backlog_path, "w", encoding="utf-8") as f:
    f.writelines(new_backlog)
    
print("alpha_backlog.md updated.")
