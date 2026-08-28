# Übergabeprotokoll

## Exakter letzter Stand
- Der **Pool** (`pool_small`) wurde erfolgreich implementiert und verifiziert.
- Gäste betreten den Pool nur, wenn der Bademeister (`StaffActor`) anwesend ist.
- Der **Live-Monitor** für den Pool zeigt nun alle Gäste korrekt an, iteriert dafür über die Gruppe `guest_actors` anstatt über physische Sitzplätze (was für Gäste im Wasser fehlschlagen würde).
- Die verbleibende Aufenthaltszeit wird im Live-Monitor dynamisch in Ingame-Minuten angezeigt (z.B. "Baden (74m)").
- Ein tiefgreifender Bug im `GuestActor.gd` wurde behoben: Beim Eintreffen an Smart-POIs (wie dem Pool) wurde der `_action_timer` auf `0.0` gesetzt, wodurch der Gast in `_process_waiting` ewig feststeckte (jetzt `0.01`).
- `PoolSmall.gd` überschreibt nun `get_available_interactions()`, um sinnfreie `"wander"`-Aktionen herauszufiltern. Gäste stehen nicht mehr in der Ecke.

## Bearbeitete Systeme
- `scenes/ingame/guest/GuestActor.gd`
- `scenes/ingame/rooms/pool_small/PoolSmall.gd`
- UI / Live Monitor Logik (indirekt)

## Sofortige nächste Schritte (Für morgen)
- **Spa & Gym:** Das Spa (`spa_small`) und das Fitnessstudio (`gym_small`) müssen nach exakt demselben Muster eingebunden und getestet werden.
- Auch dort müssen ggf. die `"wander"`-Aktionen in `get_available_interactions()` herausgefiltert werden.
- Auch dort muss der Live-Monitor auf eine gruppenbasierte Iteration umgestellt und die Restzeit-Anzeige implementiert werden.
- Danach kann der Deckel auf den Wellness/Fitness-Bereich endgültig drauf.
