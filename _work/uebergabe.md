# Übergabeprotokoll (14.09.2026)

## Letzter Stand
- Wir haben erfolgreich Bugs im **Gastro-Flow und den Live-Monitoren** von Bar und Restaurant (`Bar.gd`, `RestaurantSmall.gd`, `CustomTooltip.gd`) behoben.
- Neu ankommende Gäste (`WALKING`) blockieren nun nicht mehr den Hover-Tooltip der Räume und werden durch einen korrekten `Rect2.has_point` Scope-Fix auch im Live-Monitor sicher erkannt.
- `GuestActor.gd` speichert nun dynamisch `consumption_type` ("food" oder "drink"), womit der Live-Monitor im `EATING`-Status zwischen "Isst gerade" und "Trinkt gerade" unterscheidet.

## Bearbeitete Systeme
- **Gastro-Flow Live-Monitore:** `Bar.gd`, `RestaurantSmall.gd` (Scope Bugfix & Consumption Type Switch).
- **Tooltip System:** `CustomTooltip.gd` (Walking Gäste Fix).
- **GuestActor:** `consumption_type` via `recipes.json` in `_on_order_served` angebunden.
- **Lobby:** Das `(TG)` Tag für Tagungsgäste wird nur noch hinzugefügt, wenn tatsächlich ein `event_poi_id` gesetzt ist.

## Sofortige nächste Schritte
- **ANG-362 (Gourmet-Sterne HUD):** Dies ist im Backlog noch offen. Der User erwähnte, dass die neuen Sterne (★, 140x24px, Gold #EAB308) noch gepixelt werden müssen. Sobald die Assets da sind, muss das HUD-Overlay (`star-progress_overlay.png` o.ä.) umgebaut werden.
- **Alpha-Backlog:** Die restlichen Punkte im Linear-Backlog sichten und priorisieren (User will bis Freitag die Pre-Alpha Version für einen Streamer fertig haben!). Fokus: Crash-Sicherheit und fehlende QoL-Features, nichts Neues mehr anfangen, das Systeme brechen könnte.
- Die Startzeit der Bar in `config/rooms.json` (oder `Bar.gd` je nach finaler Implementation) wurde zu Testzwecken auf `open_from: 480` (08:00) gesetzt. Ggf. zurück auf 12:00 Uhr (720) stellen, falls das nicht so bleiben soll!
