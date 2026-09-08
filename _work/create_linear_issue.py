import subprocess, sys

title = "Architektur: StaffActor Smart-Room-Unification (analog GuestActor-Refactoring)"
desc = """## Problem

Der StaffActor.gd (1098 Zeilen) nutzt fuer den Personalraum noch eine Legacy-API:
- room.has_free_seat() - prueft Kapazitaet
- room.claim_seat(staff_id, prefer_bed) - belegt Platz
- room.leave_seat(staff_id) - gibt Platz frei

Dazu kommt hardcodierter String-Vergleich == "staff_small" (L356, L420) fuer die Break-Room-Suche.
Die Break-Room-Suchlogik ist zudem doppelt implementiert (L353-370 und L418-433) - DRY-Verletzung.

## Auswirkung

Jeder neue Staff-Raum-Typ (Umkleide, Buero, Kantine...) erfordert Aenderungen direkt im StaffActor.
Genau das Problem, das beim GuestActor mit der Smart-Room-Unification (v0.1.50, 07.09.2026) behoben wurde.

## Ziel: Smart Staff Room API

Statt Legacy:
  room.has_free_seat()
  room.claim_seat(staff_id, prefer_bed)
  room.leave_seat(staff_id)

Smart (neu, analog GuestActor):
  room.get_available_staff_interactions(actor)
  room.claim_staff_interaction(staff_id, type)
  room.release_staff_interaction(staff_id)

Hinweis: get_work_position() und get_patrol_target() sind bereits Smart-Staff-API.
Nur der Break-Room-Teil ist noch Legacy.

## Konkrete Aufgaben

1. Room.gd: Basis-Methoden claim_staff_interaction / release_staff_interaction / get_available_staff_interactions hinzufuegen
2. StaffSmall.gd: Legacy-Methoden durch neue API ersetzen
3. StaffActor.gd Refactoring:
   - _find_free_break_room() Hilfsfunktion extrahieren (DRY - aktuell 2x dupliziert)
   - Hardcoded == "staff_small" durch is_staff_poi == true aus get_definition() ersetzen
   - Legacy-Aufrufe durch neue Smart-API ersetzen
4. Neue Staff-Raeume benoetigen danach nur is_staff_poi: true in get_definition() - keine Actor-Aenderung

## Referenz

Vorbild: GuestActor Smart-Room-Unification (v0.1.50)
Betroffene Dateien: StaffActor.gd, StaffSmall.gd, Room.gd
Aktuell stabil - kein Hotfix noetig, vor dem naechsten neuen Staff-Raum-Typ umsetzen"""

result = subprocess.run(
    [sys.executable, "_dev/linear_cli.py", "create",
     "--title", title,
     "--desc", desc,
     "--priority", "2"],  # 2 = medium
    capture_output=True, text=True, encoding='utf-8'
)
with open('_work/linear_result.txt', 'w', encoding='utf-8') as f:
    f.write(result.stdout)
    if result.returncode != 0:
        f.write("\nSTDERR: " + result.stderr)
    f.write("\nReturn code: " + str(result.returncode))
print("Done - see _work/linear_result.txt")
