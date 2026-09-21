# Changelog v0.1.65

## Bugfixes & Gastro-Logik
- **Gastro-POI Timer Bugfix:** Behebung eines kritischen Fehlers in `GuestActor.gd`, bei dem der `_action_timer` beim Wechsel in den State `IN_POI` fälschlicherweise auf `0.01` überschrieben wurde. Dies führte dazu, dass Gäste, obwohl sie erfolgreich einen Sitzplatz reserviert hatten, die Interaktion sofort wieder abbrachen und den Raum verließen, wenn dieser voll war (Endlosschleife `IN_POI -> WALKING`).
- **Flow Stabilität:** Gäste setzen sich nun korrekt an ihre Tische, warten die vorgesehene Zeit ab und durchlaufen den Bestellprozess störungsfrei. Das Restaurant füllt sich nun wie gewünscht.
- **Trace-Bereinigung:** [GASTRO TRACE] Ausgaben eingebaut und analysiert, um den Fehler exakt zu isolieren.
