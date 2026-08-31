import os
import datetime

# 1. Version lesen
version = "v0.1.50"
if os.path.exists("version.txt"):
    with open("version.txt", "r", encoding="utf-8") as f:
        version = f.read().strip()

# 2. Changelog schreiben
changelog_file = f"changelog/gd-{version.replace('v', '')}.md"
date_str = datetime.datetime.now().strftime("%Y-%m-%d")

changelog_content = f"""---
# Changelog – gd-{version.replace('v', '')}
> Datum: {date_str} | Branch: `dev`

---

## Refactoring & Architektur
- **Smart Room Logik:** `is_functional()` aus individuellen Räumen (Spa, Pool, Gym, Restaurant) in die Basisklasse `Room.gd` migriert.
- **is_functional() Edge-Case:** Die Logik prüft nun, ob ein Mitarbeiter den Raum physisch besetzt ODER aktuell einen Arbeitsauftrag für den Raum ausführt (z.B. Kellner holt Essen in der Küche). Verhindert, dass Räume fälschlicherweise als "Unterbesetzt" markiert werden, während Mitarbeiter arbeiten.
- **Übersetzungen Live-Monitor:** Harte Strings in den `get_live_details()` von Pool, Spa, Gym und Conference in saubere `GameState.T("poi...")` Keys umgewandelt und in `language.csv` eingetragen.

## Bugfixes & Tweaks
- **Staff Debug-Paths:** Footprints auf dem Grid blieben hängen, da `_get_staff_name()` beim Löschen fehlte. (Vorherige Session, aber hier festgehalten).
- **Gym Aufenthaltsdauer:** Gym hat nun einen eigenen Timer-Override in `GuestActor.gd` und dauert max 60-90 Ingame-Minuten (vorher 60-180 Min wie Pool/Spa).
- **String-Crash Fix:** Absturz in `ModalContentStaff.gd` beim Zuweisen von Personal (fehlender Translation-Key führte zu Formatierungsfehler) behoben.

"""

if os.path.exists(changelog_file):
    with open(changelog_file, "a", encoding="utf-8") as f:
        f.write("\n" + changelog_content)
else:
    with open(changelog_file, "w", encoding="utf-8") as f:
        f.write(changelog_content)

# 3. Alpha Backlog
backlog_path = "wiki/alpha_backlog.md"
if os.path.exists(backlog_path):
    with open(backlog_path, "r", encoding="utf-8") as f:
        backlog_lines = f.readlines()
    
    new_backlog = []
    inserted = False
    for line in backlog_lines:
        new_backlog.append(line)
        if line.strip() == "## 🔧 Ungeplante Fixes & Features (Aktuelle Session)" and not inserted:
            new_backlog.append("- [x] **Smart Room Refactoring:** `is_functional()` Logik in `Room.gd` Basisklasse zusammengefasst und Edge-Case (fetch task) gefixt.\n")
            new_backlog.append("- [x] **Translation Enforcement:** Alle harten Strings aus den `get_live_details()` in die language.csv überführt.\n")
            new_backlog.append("- [x] **Gym Balancing:** Aufenthaltsdauer im Fitnessstudio auf 60-90 Minuten reduziert.\n")
            new_backlog.append("- [x] **UI Crash Fix:** Absturz bei fehlenden Keys im Staff-Modal gefixt.\n")
            inserted = True
            
    with open(backlog_path, "w", encoding="utf-8") as f:
        f.writelines(new_backlog)

# 4. Status Quo
# Keine GANZ NEUEN Räume fertiggestellt, nur bestehende überarbeitet.
# Daher kein Update für status_quo.md nötig.

# 5. Übergabeprotokoll
uebergabe_path = "_work/uebergabe.md"
uebergabe_content = f"""# Übergabeprotokoll ({date_str})

## Letzter Stand
Der Hotelbetrieb läuft absolut stabil. Die "Smart Room"-Architektur (wo Räume eigenständig ihre `is_functional()` Logik prüfen) wurde erfolgreich über alle Leisure-Räume (Pool, Spa, Gym, Restaurant, Bar) ausgerollt. 

## Bearbeitete Systeme
- **Room.gd / is_functional():** Prüft nun, ob Personal im Raum steht ODER einen Task für den Raum (`_current_task.target.room`) ausführt.
- **GuestActor.gd:** `stay_dur` für das Gym auf 60-90 Min isoliert.
- **UI & Translations:** `language.csv` wurde streng nach Direktive ergänzt. Live-Monitore (Pool, Spa, Gym, Conference) nutzen nun `GameState.T()`.

## Nächste Schritte
Der User möchte als Nächstes wahrscheinlich mit dem **Konferenzraum** (Conference room) weitermachen oder den nächsten Raum im Tech-Tree freischalten. Die Basis ist dafür nun maximal stabil!
"""
os.makedirs("_work", exist_ok=True)
with open(uebergabe_path, "w", encoding="utf-8") as f:
    f.write(uebergabe_content)

print("Doku-Update komplett.")
