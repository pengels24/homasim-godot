# gd-0.1.33 – Hotfix-Session (2026-07-02)

## Features & Verbesserungen
- Spielgeschwindigkeit wird vor Pause gespeichert und nach Check-in/Rezeption-Schließen wiederhergestellt (kein Reset auf 1x mehr)
- Englische Übersetzung vervollständigt: 38 fehlende EN-Keys (Finanzen, SimBrowser) ergänzt
- 10 neue Toast-Meldungen als Translation-Keys angelegt

## Bugfixes
- **Lobby** ist jetzt korrekter Systemraum: kein Aktionsmenü, keine Wertabnahme, kein Service-Icon, kein Sauberkeit/Wartungs-Tooltip
- **Lobby-Hitbox** deckt nun die volle 4x4-Fläche ab (vorher nur ein Viertel)
- **Staff-Tooltip** zeigt jetzt den echten Raumnamen statt des rohen Translation-Keys
- Manueller Service/Wartungs-Aufruf erzeugt jetzt ein echtes Ticket (kein direktes Wert-Setzen mehr)

## Technische Änderungen
- TimeManager: _pre_pause_speed merkt Geschwindigkeit vor Pause
- Lobby.gd: get_tile_size(), _on_hour_passed(), get_target_tile(), get_room_entry_pos() ueberschrieben
- RoomContextMenu.gd: Lobby-Check blockiert Menue-Oeffnung; Service/Repair via Signal
- CustomTooltip.gd: Sauberkeit/Wartung fuer Lobby ausgeblendet
- StaffFollowTooltip.gd: Raumname via GameState.T() uebersetzt
- Alle 12 hardcoded Toast-Strings in 5 Dateien auf GameState.T() umgestellt
