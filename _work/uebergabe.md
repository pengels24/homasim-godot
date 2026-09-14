# Übergabeprotokoll (Stand: v0.1.53)

## Letzter Stand
- Die Session wurde erfolgreich mit einem Fix für einen schwerwiegenden Navigations-Bug in der Lobby beendet. 
- Das Problem war **Ticket ANG-357**, bei dem sich Gäste endlos in der Lobby aufhielten und ununterbrochen Sitzplätze wechselten, ohne jemals auf ihr Zimmer oder in einen POI zu gehen.
- **Ursache:** Die Lobby wird code-seitig als POI mit Sitzplätzen (Interaktionen) behandelt. Gäste im State `IN_POI [lobby]` haben sich einen freien Platz gesucht, gewartet, und wenn der Timer abgelaufen ist, hat `_process_waiting` in `GuestActor.gd` sofort die nächste Interaktion in der Lobby geclaimed. Dadurch wurde `_decide_next_action()` durch ein vorzeitiges `return` blockiert und die Gäste verließen die Lobby nie mehr.
- **Lösung:** Ein temporärer Flag (`_has_waited_for_functional`) wird nun in `_process_waiting` genutzt, um zu erkennen, dass der Gast in der Lobby bereits gesessen hat. Beim Ablauf des Timers (nach 15-30 Ingame-Minuten) wird die Platzsuche für die Lobby einmalig blockiert, der Platz wird freigegeben und `_decide_next_action()` zwingend aufgerufen.
- Der Fix wurde getestet und vom User bestätigt.

## Bearbeitete Dateien & Dokumentation
- `scenes/ingame/guest/GuestActor.gd`: Fix in `_process_waiting` hinzugefügt und alte temporäre Debug-Prints (`[LOBBY TRACE]`, `[LOBBY DEBUG]`) drin gelassen, um bei weiteren Bugs helfen zu können (sie sind nicht störend). Außerdem wurde in `scenes/ingame/staff/StaffActor.gd` auf Wunsch des Users das Log für State-Changes (`changing to next_state=`) auskommentiert.
- `changelog/gd-0.1.53.md`: Fix dokumentiert.
- `wiki/alpha_backlog.md`: ANG-357 ergänzt und als gelöst markiert.
- `wiki/02_features/25_techdoku_guestactor.md`: Neue Sektion `3b. Lobby als Ausnahme-POI` hinzugefügt.
- `wiki/rooms/lobby.md`: Neue Sektion `3.6 Verhinderung von Endlos-Interaktionen (Lobby-Loop)` hinzugefügt.

## Nächste Schritte (Sofort)
1. **ANG-362 HUD-Sterne Overlay (offen):** Laut Alpha-Backlog soll als nächstes das Sterne-Overlay (`star-progress_overlay.png`) im HUD auf gefüllte Sterne (★) umgestellt werden (140x24px, Gold #EAB308).
2. Der User hat sich erst einmal wegen seines RL-Jobs verabschiedet ("später machen wir weiter"). Beim nächsten Start kannst du direkt nachfragen, ob mit ANG-362 weitergemacht werden soll.
3. Bitte daran denken, die Debug-Prints in `StaffActor.gd` bei Bedarf irgendwann wieder zu aktivieren, falls der User danach verlangt.
