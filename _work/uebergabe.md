# Übergabeprotokoll (v0.1.65)
*Stand: 21.09.2026*

## Letzter Stand der Session
Die Session konzentrierte sich auf massive Bugfixes im Bereich des Gastronomie-Systems, insbesondere bezüglich der Navigation und des Timings der Gäste. Der langwierige Bug, bei dem Gäste Restaurants sofort nach Betreten wieder verließen (und bei einem vollen Restaurant endlos zwischen POI und Walking State pendelten), wurde erfolgreich behoben. Die Gäste reservieren nun ihre Plätze, laufen zum Stuhl und warten dort korrekt.

## Bearbeitete Systeme & Refactorings
- **GuestActor.gd (`_change_state`, `_on_poi_arrived`, `_process_waiting`)**: 
  - Der `_action_timer` wurde beim Wechsel in den `IN_POI` State versehentlich hart auf `0.01` überschrieben (Altlast). Dies wurde entfernt. 
  - Die `_on_poi_arrived()` Funktion setzt den `_action_timer` nun korrekt und dauerhaft auf die Berechnungen aus der `claim_interaction()` (z.B. 120 Sekunden), ohne dass der State-Wechsel dies sofort zunichtemacht.
  - Das verhinderte die Endlosschleife und garantiert nun, dass Gäste ihren Platz behalten und die Bestellung durchführen.
- **GuestFlow bei Spielstand-Reload (`GuestController`)**: Abreisende Gäste blockieren nicht mehr nach einem Reload das Restaurant.

## Sofortige nächste Schritte
- **Offener Punkt aus Alpha-Backlog**: Das HUD Event-Panel bleibt fälschlicherweise nach dem Tagungsende zweizeilig. Dieser UI-Bug muss behoben werden.
- **Pre-Alpha End-Screen**: Muss nach der Stabilitätsphase implementiert werden.
- **Gourmet-Inspektor-Event**: Überprüfung der Funktionsweise, da das Gastro-System (als Voraussetzung) nun stabil läuft.