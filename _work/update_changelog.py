import os

changelog_path = r"d:\game-dev\homasim-godot\changelog\gd-0.1.50.md"
content = """
### 26.08.2026 - Gastro-Loop Fixes, Waiter Patrol & UI (Session End)

#### Bugfixes
- **Room.gd Parse Error:** Absturz beim Aufruf von `is_operational()` behoben. `actor.get()` unterstuetzt in Godot 4 kein Fallback-Argument, weshalb `actor.get("_staff_data", {})` entfernt und `def` korrekt typisiert wurde.
- **Lobby Live-Monitor (Falsche Gaeste-Namen):** Die Anzeige in allen POI-Monitoren basierte auf dem internen Godot-Node-Namen (`GuestActor_XXXX`) oder auf einem nicht vorhandenen Label. Der Live-Monitor holt sich jetzt den korrekten Klarnamen aus dem internen `_guest_member`-Objekt.
- **Lobby Live-Monitor (Falsche Status-Texte):** Falsche Status-Ids korrigiert. Die Logik nutzte harte Integer (4, 8), die durch das Enum in `GuestActor.gd` abwichen (`EATING` ist 8, `AWAITING_CHECKOUT` ist 4). Der Gast wird nun beim Automaten oder Auschecken korrekt angezeigt.
- **Lobby Live-Monitor (Fehlende Translations):** Fehlende Fallback-Texte beim Aufruf von `GameState.T()` hinzugefuegt (z.B. `"Checkt aus"`, `"Holt einen Snack"`).
- **Ingame.gd 22:00 Uhr Rauswurf:** Der harte Schnitt um 22:00 Uhr, der alle Gaeste zwangsweise aus Lobby und Bar ins Bett schickte, wurde entfernt. Gaeste bleiben nun organisch bis zur regulaeren Nachtruhe ab 23:00 Uhr im Raum.
- **Bar Solo-Modus Fallback:** Die Bar schaltet jetzt korrekt auf den Solo-Modus zurueck, sobald die Kueche keine Bestellungen mehr annimmt (`_has_active_kitchen()`). Gaeste zahlen dann sofort beim Eintreten Eintritt (`visit_income`), da der Barkeeper keine Essensbestellungen mehr aufnehmen kann.

#### Features & Improvements
- **Waiter Idle Patrol (Tisch abwischen):** Bedienungen (Waiters), die untaetig an ihrer Arbeitsstation (z. B. Tresen) stehen, starten jetzt zufaellig Dummy-Aufgaben (`clean_table`). Sie laufen zu einem freien Tisch, bleiben dort kurz stehen und erzeugen im Raum den typischen Putz-Fortschrittsbalken samt Besen-Icon (`RoomStatusIndicator`), bevor sie zurueckkehren. Das laesst das Personal deutlich lebendiger wirken.
- **RoomStatusIndicator Force Clean:** Die Progress-Bar wurde erweitert (`force_clean`), um das Besen-Icon manuell einzublenden, auch wenn der Raum systemisch gar keinen Schmutz hat (genutzt fuer den neuen Dummy-Putz-Loop des Waiters).
"""

with open(changelog_path, "a", encoding="utf-8") as f:
    f.write(content)

print("Changelog updated.")
