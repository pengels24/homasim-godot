# Übergabeprotokoll (Session: Gestaffelte Aufwachphase & Balancing)

## Letzter Stand
Der User hat erfolgreich die **gestaffelte Aufwachphase** (Staggered Wake-Up) getestet. Das neue System weist Gästen anhand ihres Typs (`GuestDefinitions`) und eines Zufallswerts ein individuelles Aufwach-Zeitfenster zwischen 06:00 und 07:00 Uhr zu. Dadurch wurde die massive Auslastungsspitze in der Gastronomie ("Flashmob" um 06:15 Uhr) eliminiert. Die Bedienung kommt nun hinterher, und die Gäste rotieren organisch durch das Restaurant.

## Bearbeitete Systeme
1. **`data/GuestDefinitions.gd`:** Keys `"wake_up_min"` und `"wake_up_max"` für jeden Gästetyp (single, couple, business, family, etc.) hinzugefügt, aufgeteilt in drei 20-Minuten-Blöcke.
2. **`scenes/ingame/guest/GuestActor.gd`:** 
   - Variable `_my_wake_up_time` in `setup()` initialisiert.
   - Harter Cut bei 06:15 Uhr in Phase 2.5 (Wachwerd-Phase) entfernt und durch personalisierten Timer ersetzt.
3. **Tech-Doku:** Die Logik ist nun auch im `wiki/02_features/25_techdoku_guestactor.md` unter Punkt 12 hinterlegt.

## Nächste Schritte für neuen Agenten
- Die Gastro-Stabilitätsphase inklusive Load-Balancing am Morgen ist damit offiziell und stabil abgeschlossen.
- Als nächstes große Tasks stehen laut `alpha_backlog.md` an:
  1. **Pre-Alpha End-Screen** 
  2. **Gourmet-Inspektor-Event**
- Frage den User explizit, welches dieser beiden Features nun gestartet werden soll.