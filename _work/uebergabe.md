# Übergabeprotokoll (30.09.2026)

## Letzter Stand
- Wir haben eine Reihe von "Quality of Life" und UI-Feedback Anpassungen eingebaut.
- Der Bau-Modus gibt nun visuelles Feedback (Verboten-Cursor + Tooltip), wenn man über einen bestehenden Raum hovert und kein Bauwerkzeug (Blueprint/Abriss) aktiv ist.
- Im Live-Monitor (Raum Hover Tooltips) zeigt "Unterbesetzt" nun einen orangen Zustand an, "Kein Personal" einen roten. 
- Das rote "Kein Personal"-Icon ändert beim Hover den Cursor zur Hand und öffnet beim Klick das Personal-Management direkt auf dem "Zuweisungen"-Tab.
- Icons im Livemonitor wurden vom User aufgeräumt, Abriss-Icon ist nun im Baumenü weiß.
- PiP-Kameras (Gäste-/Raumliste) haben ein Rendering-Update bekommen (`visibility_layer` Maskierung), sodass die Hover-Icons von Räumen nicht mehr verschwommen im PiP zu sehen sind.

## Bearbeitete Systeme
- **InputHandler / Cursor-Logik:** (`InputHandler.gd`, `BuildCursor.gd`, `DemolishCursor.gd`) Einführung von globalen Flags `is_cursor_tool_active` und `_hovered_room_count`, um den Mouse-Cursor dynamisch zu verwalten.
- **CustomTooltip:** Anpassungen für Bau-Modus (zeigt reduzierte Info mit roter Warnung).
- **RoomStatusIndicator:** Hover-Events, Klick-Events (`gui_input`) zur Navigation. Ein schwerer Einrückungsfehler in `_set_visibility_layer_recursive` wurde behoben.
- **IngameUIManager & ModalContentStaff:** Modaler Aufruf von `open_staff` nimmt nun einen Start-Tab Parameter entgegen.

## Nächste Schritte
- Der User hat angekündigt, dass er nun "den nächsten Punkt" oder "das Ende des Tunnels" testen möchte. Es sollte also mit dem Feedback vom User oder neuen Aufgaben aus dem Backlog weitergehen.
- Bereit halten für weitere UI-Verfeinerungen oder den nächsten Task auf der Alpha-Liste.