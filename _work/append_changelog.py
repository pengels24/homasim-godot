import pathlib

f = pathlib.Path("changelog/gd-0.1.50.md")
content = f.read_text(encoding="latin-1")

if "Session 2" in content or "Root Cause Fix" in content:
    print("SKIP: Eintrag schon vorhanden")
else:
    new_entry = (
        "\n\n"
        "### 04.09.2026 (Session 2) - Konferenz EXP-Loop Root Cause Fix\n"
        "\n"
        "#### Bugfixes\n"
        "- **EXP-Spam Loop (Root Cause):** Nach 08:00 liefen Tagungsgaeste in einer Endlosschleife:"
        " Timer lief ab -> `_process_waiting` rief `get_available_interactions(self)` auf -> 0 Interaktionen"
        " (eigener Sitz war nicht als 'frei' gelistet, da `occupied_by == actor_id`) -> Fallthrough zu"
        " `_decide_next_action()` -> globaler Walk -> `_on_poi_arrived()` -> EXP (via `_has_claimed_seat == true`"
        " Bypass) -> Timer auf 1-3 Ingame-Min gesetzt -> Wiederholung alle 2-6 Echtzeitsekunden.\n"
        "- **Fix 1 - `get_available_interactions` (ConferenceSmall.gd):** Bedingung geaendert von"
        " `occupied_by == \"\"` auf `occupied_by == \"\" or occupied_by == actor_id`. Gaeste sehen ihren"
        " eigenen Sitz als verfuegbar -> bleiben per `_execute_poi_move` (lokale Bewegung, kein State-Change,"
        " kein EXP) auf dem Platz. Kein globaler Walk mehr.\n"
        "- **Fix 2 - Fallthrough-Guard (GuestActor.gd):** Sicherheitsnetz: Vor `_decide_next_action()` werden"
        " jetzt `release_interaction` aufgerufen UND `_has_claimed_seat = false` gesetzt. Verhindert EXP-Bypass"
        " in `_on_poi_arrived`.\n"
        "- **Parse-Error Fix:** Durch ersten Patch-Versuch entstand ein orphaned `else` in `GuestActor.gd`."
        " Behoben durch vollstaendige Neustrukturierung des `elif State.IN_POI` Blocks in `_process_waiting`.\n"
        "\n"
        "#### Ergebnis\n"
        "- Live-Monitor stabil waehrend der gesamten Konferenz (kein Flackern mehr).\n"
        "- Speaker Swap (1. und 2. Wechsel) funktioniert korrekt inkl. Farbwechsel im Live-Monitor.\n"
        "- Zuhoerer machen nur minimale Mikrobewegungen (natuerliches Verhalten, lokaler claim auf denselben Sitz).\n"
        "- Kein EXP-Spam zwischen 08:00 und Konferenzende.\n"
    )
    f.write_text(content.rstrip() + new_entry, encoding="latin-1")
    print("OK: Changelog ergaenzt")
