# Übergabeprotokoll – Session 03.09.2026

## Kontext
Version: v0.1.50 | Branch: dev

---

## Was war der letzte Stand?

Der ConferenceSmall-Raum (Tagungsraum / P0001) hatte massive Pathfinding- und Flow-Probleme:
- TG liefen in Loops: rein, raus, wieder rein
- TG standen alle auf einem Pixel vor der Tür
- TG wanderten außerhalb der Map
- 35€ wurden fälschlicherweise pro TG-Besuch berechnet

## Was wurde in dieser Session bearbeitet?

### Primäre Dateien
- `scenes/ingame/rooms/conference_small/ConferenceSmall.gd`
- `scenes/ingame/guest/GuestActor.gd`

### Fixes (in Reihenfolge)

1. **Speaker-Swap atomar** (`ConferenceSmall._swap_speaker`):
   - Kein `release_interaction` + `_decide_next_action` mehr
   - Direktes Vertauschen der `occupied_by` Felder im `_room_seats` Array
   - Beide Akteure direkt per `_execute_poi_move` zu neuen Plätzen geschickt

2. **`_current_poi_id` Type-Fix** (`GuestActor._walk_to_poi`):
   - `_walk_to_poi("P0001")` setzte `_current_poi_id = "P0001"` (Raumkey)
   - `_get_poi_room_node` sucht nach Definition-ID → fand null → `is_in_event_room = false`
   - Fix: `_current_poi_id = def.get("id", poi_id)` → immer "conference_small"

3. **`is_in_event_room` Check** (`GuestActor._process_waiting`):
   - Vergleich `party.event_poi_id` ("P0001") vs `_current_poi_id` ("conference_small") → immer false
   - Fix aus Session: `_get_poi_room_node` → Room-Node → `_room_key()` → "P0001" → Vergleich

4. **Wander-Vorpuffer 07:45–08:00**:
   - `open_from: 465` (07:45 statt 480/08:00)
   - `get_available_interactions()` gibt vor 08:00 `wander_pre` zurück (random Walkable-Pos)
   - `claim_interaction("wander_pre")` gibt Position ohne Sitz zu belegen zurück
   - `_action_timer = 0.5–1.5 min` für kurzes Wuseln

5. **Double-Offset Bug bei `get_random_walkable_local_pos()`**:
   - Diese Funktion gibt bereits World-Koordinaten zurück (Room.gd Zeile 218)
   - `to_global(pos)` war ein doppelter Offset → TG außerhalb der Map
   - Fix: `to_global()` entfernt, direkt als `target_pos` verwenden

6. **35€ visit_income blockiert** (`GuestActor._on_poi_arrived`):
   - `income = 0` wenn `party.event_poi_id != ""`
   - TG zahlen über Event-Budget, nicht per Visit

7. **Live-Monitor Wander-Phase** (`ConferenceSmall.get_live_details`):
   - Zweite Schleife über `guest_actors` Gruppe
   - Zeigt TG mit `current_state == 3` (IN_POI) und `_current_poi_id == "conference_small"` an
   - Status-Text: "..." in Grau (#6b7280)

8. **Blickrichtung zum Speakertable** (`ConferenceSmall.claim_interaction`):
   - Für alle Sitze (nicht nur Speaker): `look_at_pos = Speakertable.global_position`

---

## Aktueller Teststatus

**Wuseln (07:45–08:00):** ✅ Funktioniert laut User-Feedback
**8:00 Uhr Sitz-Phase:** ⚠️ NOCH NICHT GETESTET (Token-Limit erreicht)
**Live-Monitor:** ⚠️ Wartet auf Test (Wander-TG sichtbar, Sitz-TG nach 08:00?)
**visit_income:** ✅ Implementiert, noch nicht bestätigt

---

## Sofortige nächste Schritte für nächste Session

1. **Test: 08:00 Uhr Übergang** – Setzen sich TG auf Stühle? Zeigt Live-Monitor die Namen korrekt?
2. **Debug-Prints entfernen** in `ConferenceSmall.get_available_interactions()` (Zeilen 229, 241, 244)
3. **`get_room_entry_pos`** in ConferenceSmall prüfen – Door.global_position ist die äußere Türposition, könnte Probleme beim Verlassen bereiten
4. **Blickrichtung testen** – schauen alle TG zum Speakertable?
5. Falls 08:00 Übergang nicht klappt: In `_process_waiting` schauen ob `wander_pre` korrekt in Sitz-Modus wechselt (Timer läuft ab → `get_available_interactions` → Sitzplatz verfügbar)

---

## Wichtige Code-Zusammenhänge

```
GuestActor._decide_next_action()
  → is_event_time && event_room_open
  → _walk_to_poi("P0001")           ← poi_id = Raumkey
    → target_room = ConferenceSmall  ← gefunden per _room_key()
    → get_available_interactions()   ← vor 08:00: wander_pre, nach 08:00: seat_X
    → claim_interaction()            ← wander_pre: kein Sitz; seat_X: Sitz belegt
    → extra_pos = world_pos          ← KEIN to_global() mehr!
    → _execute_walk(...)
    → _current_poi_id = "conference_small"  ← def.get("id"), nicht poi_id!

GuestActor._process_waiting (IN_POI)
  → is_in_event_room:
    → _get_poi_room_node("conference_small") → Room-Node ✓
    → _room_key(Room-Node) = "P0001"
    → party.event_poi_id = "P0001" → match → is_in_event_room = true ✓
```

---

## Offene Punkte (laut User nach Test)

- Wander funktioniert ✅
- 08:00 Übergang: zu testen
- Live-Monitor während Wandern: implementiert, zu testen
- Blickrichtung: implementiert, zu testen
