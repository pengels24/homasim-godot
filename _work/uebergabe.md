# Übergabe-Protokoll – v0.1.60 (19.09.2026)

## Letzter Stand

Session abgeschlossen mit dem großen TG-PM-Session-Durchbruch: Tagungsgäste kehren nun korrekt nach der Mittagspause um 13:30 in den Konferenzraum zurück und bleiben dort bis 17:00.

## Bearbeitete Systeme

### GuestActor.gd
- **is_event_time Fix (kritisch):** PM-Start war `830` (13:50) statt `810` (13:30). Fix in `_process_waiting()` Zeile 324.
- **Max-Guests-Check:** `_get_open_pois()` zählt jetzt nur Gäste in active_states [3,6,7,8,9] – nicht mehr WALKING-Gäste.

### ConferenceSmall.gd
- **Sitzplatz-Reservierung:** `_start_break()` löscht `occupied_by` NICHT mehr. Jeder TG behält seinen Platz reserviert. Bei Rückkehr findet er via `occupied_by == actor_id` seinen Platz.
- **Tooltip-Fix:** `get_live_details()` blendet Gäste aus die nicht `_current_poi_id == "conference_small"` haben.
- **Reload-Kommentare:** `_init_phase_from_time()` Kommentare aktualisiert.
- **Broadcast-Timing:** `return_from_conference_break` wird bei `TIME_SESSION_PM_START` (810 = 13:30) gesendet.

### CustomTooltip.gd
- **Multi-Instance Fix:** Tooltip nutzt `get_live_details()` wenn verfügbar (Gym, Pool, Spa) statt typ-basierter Zählung. Vorher zeigten beide Gym-Instanzen dieselben Gäste.

## Sofortige nächste Schritte

1. **Luftlinien-Pathfinding nach Reload aus POI:** TG-Gäste die beim Speichern in Bar/Restaurant waren, spawnen nach Reload an ihrem POI und gehen dann Luftlinie durch Wände zur Lobby. Root-Cause: beim Restore aus IN_POI-State in Bar/Restaurant fehlt der korrekte Inroom-Nav → Global-Nav Übergang.

2. **Conference POI für normale Gäste ausblenden:** Wenn Event läuft, sollte `conference_small` nicht in `_get_open_pois()` für normale Gäste auftauchen. Lösung: `is_guest_allowed()` in ConferenceSmall prüft ob Event aktiv ist und Gast kein TG-Gast ist → return false.

3. **ANG-365:** Techtree/Level Alignment (`req_level` in techtree.json vs `UNLOCK_LEVELS` in GameState.gd).

## Wichtige Architektur-Notizen

- `is_event_time` Zeitfenster: AM = 465–720 (07:45–12:00), PM = 810–1020 (13:30–17:00)
- `_current_poi_id` ist IMMER typ-basiert ("gym_small", "conference_small"), NICHT instance-key-basiert
- `_room_seats` wird nach Reload IMMER leer neu gebaut (Scene-Node-Rebuild) – Seat-Reservierung ist nur runtime-relevant
- TG-Gäste: `party.event_poi_id` enthält den Raum-Key (z.B. "P0001") und darf NICHT geleert werden bis 17:00