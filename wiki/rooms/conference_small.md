# Conference Small (Tagungsraum)
**ID:** `conference_small`
**Kategorie:** Business

## Funktionsweise (Smart Room 2.0)
Der Tagungsraum (Conference Small) bietet Platz für bis zu 12 Personen (11 Zuhörer, 1 Redner). Seit dem Update auf das Smart Room System und die Einführung des EventManagers (Tier 2/3) arbeitet der Raum im **Dual-Modus**:

1. **Event-Modus (Modus A):**
   - Wenn der `EventManager` morgens ein Event auf diesen Raum bucht (z.B. Botaniker-Tagung), ist der Raum für diesen Tag exklusiv reserviert.
   - Die Zahlung pro Teilnehmer erfolgt erst um **07:45 Uhr** direkt über den `ConferenceSmall` Raum (Vorpuffer-Öffnung), nicht im `EventManager`.
   - Reguläre Hotelgäste (VIPs, Business-Gäste ohne Event) dürfen den Raum nicht betreten.
   - Tagungsgäste haben einen strikten Tagesablauf: 07:45–12:00 Konferenz, 12:00–13:15 Mittagspause (Bar/Restaurant), 13:30–17:00 Nachmittagssession.

2. **Regulärer Modus (Modus B):**
   - Findet kein Event statt, verhält sich der Raum wie ein regulärer POI. 
   - Business-, Luxus- und VIP-Gäste können den Raum gegen Eintrittsgeld (`visit_income`) nutzen.
   - Event-Gäste aus anderen Räumen werden geblockt.

## Interaktion & Bestuhlung
Der Raum wickelt die Sitzplätze dynamisch über `get_available_interactions` und `claim_interaction` ab:
- **Rednerpult (`ChairSpeaker`):** Der Raum erzwingt für den Gast an diesem Platz per `look_at_pos` die Blickrichtung zum `Speakertable`.
- **Zuhörer (`Chair1` bis `Chair11`):** Reguläre Sitzplätze.
- **Seat Swap (Rotation):** Der Raum misst über das Signal `TimeManager.sig_minute_passed` die Zeit des aktuellen Redners. Nach exakt 15 Ingame-Minuten wird die `_swap_speaker()` Logik ausgelöst. Der aktuelle Redner gibt seinen Platz ab und tauscht ihn logisch mit einem zufällig gewählten Zuhörer im Raum. Beide Gäste fordern im nächsten Frame eine neue Interaktion an und laufen zu ihren neuen Plätzen, ohne den Raum zu verlassen.

### Wichtig: Eigener Sitz in `get_available_interactions`
Die Bedingung für freie Sitzplätze lautet `occupied_by == "" or occupied_by == actor_id`.
**Warum:** Wenn der Timer eines sitzenden Gastes abläuft, ruft `_process_waiting` `get_available_interactions(self)` auf. Da der Gast seinen eigenen Sitz belegt, würde bei `occupied_by == ""` das Ergebnis 0 sein → Fallthrough zu `_decide_next_action()` → globaler Walk → erneutes `_on_poi_arrived()` → **EXP-Spam**. Durch das Einschließen des eigenen Sitzes bekommt der Gast seine aktuelle Position zurück, bewegt sich minimal (`_execute_poi_move`) und bleibt im Raum – ohne State-Change und ohne EXP.

### Fallthrough-Guard in `GuestActor._process_waiting`
Falls trotzdem `interactions.size() == 0` (z.B. designierter Speaker darf nicht auf Zuhörersitz), wird **vor** `_decide_next_action()` der Sitz via `release_interaction` freigegeben und `_has_claimed_seat = false` gesetzt. Verhindert, dass `_on_poi_arrived` via den `_has_claimed_seat`-Bypass EXP vergibt, obwohl der Gast nicht wirklich neu ankommt.


## Stats & Limitierungen
- **Kapazität:** max 12 Gäste (`max_guests = 12`)
- **Raumgröße:** 3x2 (bzw. 2x3 im Portrait-Modus)
- **Live-Monitor:** Zeigt den aktuellen Redner orange mit dem Status "Hält einen Vortrag" (`poi.conference.speaking`) an, während Zuhörer lila markiert bleiben (`poi.conference.attending`).

## TG-Checkout nach Tagungsende (17:00)

### Problem & Architektur
Tagungsgäste haben **kein Hotelzimmer** (`party.room_id = ""`). Der normale Checkout-Flow (`GuestManager.do_checkout()`) setzt ein Zimmer voraus und ist daher nicht direkt verwendbar. Der Checkout-Flow für TG-Gäste wird stattdessen über `GuestManager.checkout_event_party()` gesteuert.

### Identifikation von "abgereisten" TG-Gästen
Ein TG-Gast gilt nach 17:00 als "fertig", wenn:
- `party.room_id == ""` (kein Zimmer)
- `party.event_poi_id == ""` (Tagung beendet – wird um 17:00 von `ConferenceSmall._end_conference_day()` geleert)

### Two-Pass-Pattern in `GuestController.spawn_active_guests()`
Um Array-Modification-während-Iteration zu vermeiden (Godot-Bug), wird ein Two-Pass verwendet:
1. **Pass 1:** Alle aktiven Parties iterieren. TG-Parties die die obige Bedingung erfüllen → in `tg_checkout_parties` sammeln.
2. **Pass 2:** Für jede gesammelte Party: `_guest_manager.checkout_event_party(party)` aufrufen.

### `GuestManager.checkout_event_party(party)`
Neue dedizierte Methode für den Event-Checkout ohne Zimmer:
```gdscript
_active.erase(party)
party.state = "gone"
sig_party_checked_out_physically.emit(party)
```
→ `GuestController._on_party_checked_out_physically()` greift → Actors werden gespawnt.

### `GuestActor.complete_checkout(spawn_pos)`
Beim Reload-Spawn (IDLE-State) muss `_current_poi_id = "lobby"` gesetzt werden, BEVOR `_walk_to_exit()` aufgerufen wird.  
**Warum:** `_walk_to_exit()` → `_execute_walk()` → Phase 1 nutzt `_get_current_room_node(previous_state)`. Ist `_current_poi_id = ""`, gibt `_get_current_room_node` null zurück → kein lokaler Pfad → Gast teleportiert sofort zur Exit-Tile → `queue_free()` → **unsichtbarer Sofort-Exit**.

### Spawn-Position
TG-Actors spawnen beim Checkout-Flow an den **ReceptionX-Waypoints** der Lobby (`lobby.get_checkout_wait_pos(member.party_id)`), genau wie ankommende Hotelgäste. Nicht am generischen `_get_lobby_spawn_pos()` (= Flur-Position).

### Post-Essen-Guard
Falls ein TG-Gast während der 17:00–17:30-Mittagszeit noch im Restaurant/Bar ist, greift ein Guard in `GuestActor._process_waiting()`:
- `state == EATING` (oder STUDYING_MENU, WAITING_FOR_FOOD)
- `party.event_poi_id == ""` (Tagung vorbei)
- `party.room_id == ""` (kein Zimmer)
→ direkt `start_checkout()` aufrufen, ohne in Lobby-IDLE zu fallen.
