#!/usr/bin/env python3
"""
Haengt einen Changelog-Eintrag an eine bestehende Datei an.
Liest immer als UTF-8, schreibt immer als UTF-8.
"""

entry = """

### 04.09.2026 - Session 3: Conference Break, Log-Cleanup, Tooltip-Fix & Restaurant-Debug

#### Log-Cleanup
- **GuestActor changed state:** Print auf Zeile 767 auskommentiert (groesster Log-Fluter)
- **StaffActor changing to next_state:** Print auf Zeile 105 auskommentiert
- Im Log bleiben: [CONF-DEBUG], [TGCHANGE], [DEBUG RESTAURANT], Fehler-Prints, MapGrid-Paths

#### Konferenz-Mittagspause (12:00 - 13:45)
- **go_conference_break():** Alle TG-Gaeste verlassen um 12:00 den Konferenzraum -> Lobby/Bar/Restaurant.
  `party.event_poi_id` temporaer geleert, gespeichert in `_conference_break_poi_key`.
- **return_from_conference_break():** 13:45 (TIME_BREAK_END=825) TG-Gaeste kehren zurueck, `event_poi_id` wiederhergestellt.
- **_broadcast_to_event_guests():** Hilfsmethode in ConferenceSmall.
- **_start_break() / _end_break() / _end_conference():** Phasen-Wechsel in ConferenceSmall.
- **end_conference_day():** 17:00 - 50% Heimweg, 50% Bar/Restaurant. `event_poi_id` geleert.

#### Hardcode-Sync
- `GuestActor._decide_next_action()` Zeile 631: Event-Zeit von `830` auf `825` korrigiert.

#### Tooltip Mismatch Fix (CustomTooltip.gd)
- Tooltip-Gaeste-Zaehler nutzt nun `get_nodes_in_group("guest_actors")` statt `ctrl._actors.values()`.
- WALKING wird gezaehlt wenn `_current_poi_id` noch auf den Zielraum zeigt.

#### Restaurant Debug-Prints
- `RestaurantSmall.place_order_for_seat()` mit praezisen Debug-Prints fuer alle Abbruchgruende.

#### Offener Bug (Cut mit offenem Ende)
- Gaeste verschwinden sofort aus Restaurant/Bar.
- Naechster Schritt: Testlauf mit Debug-Prints -> Abbruchgrund identifizieren.
"""

target = 'changelog/gd-0.1.50.md'

# Lesen
try:
    with open(target, 'r', encoding='utf-8') as f:
        existing = f.read()
except UnicodeDecodeError:
    # Fallback: latin-1 lesen und als UTF-8 behandeln
    with open(target, 'rb') as f:
        raw = f.read()
    existing = raw.decode('latin-1')

# Schreiben (immer UTF-8!)
with open(target, 'w', encoding='utf-8', newline='\r\n') as f:
    f.write(existing)
    f.write(entry)

print("Changelog erfolgreich angehaengt (UTF-8).")
