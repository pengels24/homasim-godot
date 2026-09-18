# Changelog – v0.1.60
> Branch: `dev` | Datum: 19.09.2026 | Session-Ende

---

## 🐛 Bugfixes

### ConferenceSmall – PM-Session Timing Fix (kritisch)
- **Root-Cause:** `is_event_time` in `GuestActor._process_waiting()` hatte PM-Start bei `830` (13:50), aber `ConferenceSmall.TIME_SESSION_PM_START = 810` (13:30). TG-Gäste wurden beim Ankommen im Konferenzraum sofort via „Pause!"-Branch rausgeworfen.
- **Fix:** Magic Number `830` → `810` in `GuestActor.gd` Zeile 324.

### ConferenceSmall – Sitzplatz-Reservierung während Mittagspause
- **Problem:** `_start_break()` löschte alle `occupied_by`-Einträge → bei Rückkehr Race Condition: alle 12 Gäste kämpften um dieselben Plätze, viele fanden keinen freien Sitz → `send_back_to_room()`.
- **Fix:** `_start_break()` löscht die Sitze NICHT mehr. Jeder TG-Gast behält seinen `occupied_by`-Eintrag (Reservierung). Bei Rückkehr findet jeder via `s["occupied_by"] == actor_id` exakt seinen eigenen Platz. Kein Race Condition mehr.
- **Reload-Verhalten:** `_room_seats` wird nach Reload immer leer neu gebaut (Scene-Nodes), daher ist die Reservierung nur runtime-relevant. `_init_phase_from_time()` leert die Sitze sicherheitshalber nach Reload und broadcastet `return_from_conference_break`.

### ConferenceSmall – get_live_details() Tooltip während Pause
- **Fix:** Gäste die nicht `_current_poi_id == "conference_small"` haben (= auf Pause) werden im Tooltip ausgeblendet.

### GuestActor – Max-Guests-Check: nur IN_POI-States zählen
- **Problem:** `_get_open_pois()` zählte auch Gäste die noch auf dem Weg zum POI waren (WALKING), wodurch Bar/Restaurant/Pool als voll galten obwohl sie leer waren.
- **Fix:** Max-Guests-Check filtert jetzt auf `active_states = [3, 6, 7, 8, 9]` (IN_POI, STUDYING_MENU, WAITING_FOR_FOOD, EATING, SITTING).

### CustomTooltip – Doppelzählung bei mehreren Gym/Pool/Spa-Instanzen
- **Problem:** Tooltip zählte `_current_poi_id == "gym_small"` typbasiert → beide Gym-Instanzen zeigten dieselben 6 Gäste.
- **Fix:** Wenn Raum `get_live_details()` hat, wird dieses für die Gästeliste im Tooltip verwendet (instanzspezifisch). Fallback auf typ-basierten Check für Räume ohne `get_live_details()`.

---

## 🔧 Verbesserungen

### ConferenceSmall – Reload-Fix-Kommentare aktualisiert
- `_init_phase_from_time()` Kommentare erklären jetzt klar, warum explizites Seat-Leeren nach Reload redundant aber sicher ist.

### DevConsole – `list-pois` Befehl
- `max_guests` wird aus der Room-Definition gelesen statt aus `_room_seats.size()`.

---

## 🔖 Offene Punkte (nächste Session)
- Luftlinien-Pathfinding beim Reload aus POI heraus (TG in Bar/Restaurant nach Reload)
- Conference POI aus `_get_open_pois()` für normale Gäste ausblenden wenn Event läuft
- ANG-365: Techtree/Level Alignment (`req_level` vs `UNLOCK_LEVELS`)
