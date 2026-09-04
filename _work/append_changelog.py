#!/usr/bin/env python3
# Haengt den Session-Eintrag an gd-0.1.50.md an (cp1252 encoding)

entry = """

### 04.09.2026 - Session 3: Conference Break, Log-Cleanup, Tooltip-Fix & Restaurant-Debug

#### Log-Cleanup
- **GuestActor changed state:** Print auf Zeile 767 auskommentiert (groesster Log-Fluter, hunderte Zeilen pro Sekunde)
- **StaffActor changing to next_state:** Print auf Zeile 105 auskommentiert (zweiter Fluter)
- Im Log bleiben: [CONF-DEBUG], [TGCHANGE], [DEBUG RESTAURANT], Fehler/Abbruch-Prints und MapGrid-Path-Meldungen

#### Konferenz-Mittagspause (12:00 - 13:45)
- **go_conference_break():** Alle TG-Gaeste verlassen um 12:00 den Konferenzraum und gehen zu Lobby/Bar/Restaurant.
  `party.event_poi_id` wird temporaer geleert (Gaeste werden als normale Gaeste akzeptiert), gespeichert in `_conference_break_poi_key`.
- **return_from_conference_break():** Um 13:45 (TIME_BREAK_END=825) kehren TG-Gaeste zurueck. `event_poi_id` wiederhergestellt.
- **_broadcast_to_event_guests():** Hilfsmethode in ConferenceSmall - ermittelt alle Gaeste mit matching `event_poi_id` und ruft eine Methode auf ihrem GuestActor auf.
- **_start_break() / _end_break():** Phasen-Wechsel in ConferenceSmall (break -> wander_pm -> session_pm).
- **end_conference_day():** Um 17:00 - 50% gehen direkt heim, 50% noch Bar/Restaurant. `event_poi_id` wird geleert.

#### Hardcode-Sync
- `GuestActor._decide_next_action()` Zeile 631: Event-Zeit-Pruefung von `830` auf `825` korrigiert (sync mit TIME_BREAK_END in ConferenceSmall).

#### Tooltip Mismatch Fix (CustomTooltip.gd)
- Tooltip-Gaeste-Zaehler nutzte `ctrl._actors.values()` (konnte leer/null sein), Live-Monitor nutzte `get_nodes_in_group("guest_actors")`.
- Fix: Tooltip nutzt jetzt ebenfalls `get_nodes_in_group("guest_actors")`.
- WALKING wird jetzt mitgezaehlt, aber nur wenn `_current_poi_id` noch auf den angefragten Raum zeigt (Gast laeuft zum Tisch).

#### Restaurant Debug-Prints (Diagnose fuer Verschwinde-Bug)
- `RestaurantSmall.place_order_for_seat()` umgeschrieben mit praezisen Debug-Prints fuer jeden moeglichen Abbruchgrund:
  - Seat dirty statt clean
  - Seat nicht gefunden (occupied_by != guest_id)
  - Kein Waiter zugewiesen
  - Kueche geschlossen
  - Keine Rezepte im Budget
- Erlaubt beim naechsten Testlauf sofortige Diagnose.

#### Offener Bug (Cut mit offenem Ende)
- Gaeste verschwinden sofort aus Restaurant/Bar: Tooltip zeigt 0, Live-Monitor zeigt Gast.
- Naechster Schritt: Testlauf mit Debug-Prints -> Abbruchgrund identifizieren.
"""

with open('changelog/gd-0.1.50.md', 'a', encoding='cp1252') as f:
    f.write(entry)

print("Changelog erfolgreich angehaengt.")
