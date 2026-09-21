# Changelog v0.1.65

## Bugfixes & Gastro-Logik
- **Gastro-POI Timer Bugfix:** Behebung eines kritischen Fehlers in `GuestActor.gd`, bei dem der `_action_timer` beim Wechsel in den State `IN_POI` fälschlicherweise auf `0.01` überschrieben wurde. Dies führte dazu, dass Gäste, obwohl sie erfolgreich einen Sitzplatz reserviert hatten, die Interaktion sofort wieder abbrachen und den Raum verließen, wenn dieser voll war (Endlosschleife `IN_POI -> WALKING`).
- **Flow Stabilität:** Gäste setzen sich nun korrekt an ihre Tische, warten die vorgesehene Zeit ab und durchlaufen den Bestellprozess störungsfrei. Das Restaurant füllt sich nun wie gewünscht.
- **Trace-Bereinigung:** [GASTRO TRACE] Ausgaben eingebaut und analysiert, um den Fehler exakt zu isolieren.
- **Gedulds-Balancing:** Patience-Verlustrate in `GuestActor` halbiert (Timer-Limit verdoppelt), damit Gäste nicht zu früh wegen Warten gehen.
- **Gastro-Tutorial-Tipp (tip_gastro_overload):**
  - Trigger-Bedingung überarbeitet: Feuert nun erst, wenn alle Sitzplätze physisch von Gästen belegt sind (Status: IN_POI, STUDYING_MENU, WAITING_FOR_FOOD, EATING).
  - Personalabfrage global über `StaffManager.hired_staff` optimiert (zuverlässige Zählung der Köche/Bedienungen statt instanzspezifischer Check).
  - Fehlende Lokalisierung (`tutorial.tip_gastro_overload.title` & `.desc`) in `language.csv` ergänzt.

## Features & Balancing
- **Gestaffelte Aufwachphase (Staggered Wake-Up):** Zur massiven Entlastung der Gastronomie-Lastspitzen um 06:15 Uhr wachen Gäste nun gestaffelt in 20-Minuten-Blöcken auf. 
  - Die Aufwachzeit richtet sich primär nach dem Gästetyp (z.B. `business` wachen als Erstes auf, `family` als Letztes).
  - Ein zusätzlicher Zufalls-Timer `randi_range(min, max)` sorgt dafür, dass die Zimmertüren organisch nacheinander aufgehen ("Tröpfchen"-Verteilung) anstatt eines massiven Pulks, was die Simulation realistischer und stabiler macht.
