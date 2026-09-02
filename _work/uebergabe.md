# Übergabeprotokoll (HomaSim Godot)

## Letzter Stand der Session
Die Bugs rund um die P1.2-Konferenzen (Botaniker-Tagung) wurden massiv und erfolgreich gefixt.
1. **Spawn-Wellen:** Fehler in der Schleife von `GuestManager.spawn_conference_guests` behoben (Welle 3 spawnt nun korrekt).
2. **Priorität & Pathing:** Event-Gäste werden nun zwingend in den Event-Raum navigiert (`GuestActor._decide_next_action`), anstatt in der Lobby zu trödeln.
3. **Room-Key-Migration komplettiert:** Die tief vergrabenen alten `instance_id` Abfragen in `GuestActor._walk_to_poi`, `CustomTooltip.gd` und der Türsteher-Logik in `ConferenceSmall.gd` wurden auf den neuen sicheren String-Key (`GuestManager._room_key(room)`) umgeschrieben. Die Räume erkennen sich wieder selbst als aktive Events und lassen die Gäste eintreten!

## Nächste sofortige Schritte für den nächsten Agenten
Der User hat völlig richtig angemerkt, dass die Mechanik der P1.1 Stadt-Events (Messe, Konzert) sich aktuell mit den P1.2 Hotel-Konferenzen beißt.

1. **Architektur anpassen:** Aktuell laufen beide über eine einzige Variable `active_event` im `EventManager`. Sie können also nicht gleichzeitig am selben Tag stattfinden.
2. **Quota / Spawn Fix:** Aktuell spawnen Stadt-Events einfach per `randi_range(2, 3)` mehrere normale Hotelbuchungen pro Tick an der Rezeption. Da das Hotel ein hartes Tageslimit an Buchungen hat, ist das Limit um die Mittagszeit verbraucht und nachmittags kommt niemand mehr.
   - *Lösungsidee:* Stattdessen das Tageslimit (`x`) im GuestManager um einen Faktor (z.B. +50%) erhöhen.
3. **Plan:** Dazu wurde in der letzten Session ein fertiger **Implementation Plan** (`implementation_plan.md` in den Artifacts) erstellt. Der User wird sich diesen durchlesen und sein Feedback / seine Design-Entscheidung dazu mitteilen.
4. **Aufgabe:** Lies den Implementation Plan und das Feedback des Users dazu. Setze dann die Entkopplung von Stadt-Events und Konferenzen sowie das Rebalancing der Daily-Quotas im `GuestManager` um. Das UI oben links muss entsprechend erweitert werden, falls beides aktiv ist.
