# TechDoku: GuestActor (Gäste-Verhalten)
*Stand: v0.1.61 – 19.09.2026 (Save/Load Fix, Luftlinien-Bugfix)*

Der `GuestActor` steuert die visuelle und logische Repräsentation eines einzelnen Hotelgastes auf der Karte. Jeder `GuestActor` ist an ein `GuestMember`-Datenobjekt gekoppelt, welches die eigentlichen Werte (Sättigung, Geduld, Geldbeutel, Budget) hält.

## 1. Lebenszyklus & Setup
- **Spawn**: Wird vom `GuestManager` instantiiert, sobald eine neue `GuestParty` anreist oder geladen wird.
- **Setup**: `setup(member, map_grid, start_room, guest_manager)` verknüpft Actor mit Datenmodell.
- **Despawn**: Nach Checkout und Verlassen des Grundstücks (`LEAVING`) wird der Actor entfernt.

- `SITTING`: Unterzustand für feste Platzbindung (z.B. Tagungsgast sitzt während Vortrag).
- `SLEEPING`: Gast schläft im Zimmer.
- `STUDYING_MENU`: Liest Speisekarte – wird von `is_gastro() == true` ausgelöst.
- `WAITING_FOR_FOOD`: Hat bestellt, wartet auf Lieferung – Geduld sinkt.
- `EATING`: Isst gerade – Sättigungsbalken steigt, Timer läuft.
- `WAITING_IN_LINE`: Steht in einer Warteschlange (z.B. Snackautomat besetzt).
- `AWAITING_CHECKOUT`: Steht in der Lobby, wartet auf Checkout.
- `LEAVING`: Hat ausgecheckt, läuft zum Ausgang.

## 2a. `get_status_text()` – Single Source of Truth (v0.1.50)

> ⚠️ **Regel:** Alle Status-Texte für UI (Gästeliste F3, Tooltips, Detail-Panel) kommen **ausschließlich** aus `GuestActor.get_status_text()`. Nie direkt im UI-Code State-IDs prüfen!

Gibt einen lokalisierten, lesbaren Kurztext zurück. Reihenfolge:

| State(s) | Format | Beispiel |
|---|---|---|
| `AWAITING_CHECKOUT` | Translation-Key | `"Wartet auf Checkout"` |
| `LEAVING` | Translation-Key | `"Reist ab"` |
| `WALKING` (Checkout) | Translation-Key | `"Zur Rezeption"` |
| `WALKING` (Raum) | `"Unterwegs (Raumnummer)"` | `"Unterwegs (Z0005)"` |
| `IN_POI`-Gruppe | `"Raumname Raumnummer"` | `"Fitness-Studio W0003"` |
| `IN_POI` vending_machine | `GameState.T("poi.vending_machine")` | `"Snack-Automat"` |
| `IN_ROOM/SITTING/SLEEPING` | `"Raumtyp Raumnummer"` | `"Doppelzimmer Z0005"` |
| `IDLE` / unbekannt | `"-"` | `"-"` |

**Koordinaten-Fallback** (`type_x_y`): Wird immer unterdrückt (enthält `_`). Nur echte Raumnummern (Präfix + 4 Ziffern) werden angezeigt.

**Neue States/Räume eintragen:** Nur `get_status_text()` in `GuestActor.gd` editieren – kein UI-Code anfassen.


## 3. _process_waiting – Architektur (v0.1.50)

`_process_waiting()` hat drei saubere, voneinander unabhängige Branches:

```
_action_timer -= delta * speed
if _action_timer <= 0.0:
    if current_state == EATING:
        ...
        return  # PFLICHT
    elif current_state == STUDYING_MENU:
        GastroManager.try_gastro_order(...)
        return  # PFLICHT
    elif current_state in [IN_POI, SITTING]:
        ...
        # kein return – fällt durch zu _decide_next_action()
    _decide_next_action()
```

> ⚠️ **Regel:** Jeder Branch der einen State-Wechsel auslöst MUSS mit `return` enden.
> `SITTING` wird seit v0.1.50 im gemeinsamen `[IN_POI, SITTING]` Block behandelt.

## 3b. Lobby als Ausnahme-POI (v0.1.53)
Die Lobby ist ein spezieller POI (hat z.B. Sitzplätze, aber keine echten POI-Eigenschaften wie `is_poi`). Wenn Gäste in die Lobby geschickt werden, sollen sie nach einer kurzen Wartezeit (Sitzplatz-Timer 15-30 Minuten) wieder in den Entscheidungsbaum übergehen. 
Damit sie nicht in einem endlosen Interaktions-Loop (von Platz zu Platz) gefangen bleiben, wird für die Lobby eine Ausnahmelogik verwendet:
- Nach einer Interaktion wird ein Flag `_has_waited_for_functional` "missbraucht", um zu markieren, dass der Gast bereits in der Lobby saß.
- Beim nächsten Durchlauf von `_process_waiting` wird dadurch die Interaktions-Suche übersprungen, der Gast gibt den Sitz frei und ruft `_decide_next_action()` auf.

## 4. Gastronomie – Smart Room Protocol (v0.1.50)

Der `GuestActor` kennt **keine Raum-IDs** mehr. Der Raum teilt über Methoden mit was er ist.

**Trigger:** `_execute_poi_move()` prüft `room_node.is_gastro()` – nur dann wird `STUDYING_MENU` nach Ankunft am Platz ausgelöst.

**Flow:**
1. `IN_POI` → `claim_interaction()` → `_execute_poi_move()` → `[STUDYING_MENU falls is_gastro()]`
2. `STUDYING_MENU` → `GastroManager.try_gastro_order(id, budget, saturation, room_node)` → eines von:
   - `ordered == true` → `WAITING_FOR_FOOD`
   - `solo_mode == true` → `EATING` direkt (Bar mit Barkeeper aber ohne Waiter)
   - beide false → Platz freigeben, `_decide_next_action()`
3. `WAITING_FOR_FOOD` → Signal `GastroManager.sig_order_served` → `EATING`
4. `EATING` → nach 15s → `release_interaction()` → `_walk_to_room()`

## 5. Wellness-Räume (Pool / Gym / Spa) – v0.1.50+

Wellness-Räume nutzen ein **zweistufiges Timing-System** – vollständig in den jeweiligen Room-Scripts implementiert. `GuestActor` selbst hat keine spezielle Wellness-Logik.

### Timing-Hierarchie

```
Session-Timer (60-180 Min)
  └── Spot-Timer (5-12 Min pro Platz)
       └── Alternation: sit ↔ sleep (Pool/Spa)
```

### Ablauf beim ersten Betreten (`_on_poi_arrived`)
1. `get_available_interactions(self)` → freie Spots
2. `claim_interaction(id, spot_id)` → gibt `target_pos` + `duration` (Spot-Timer)
3. **`_action_timer = duration * SECONDS_PER_GAME_MINUTE`** ← setzt ersten Timer korrekt
4. EXP + Income vergeben (einmalig)
5. `_execute_poi_move(seat_pos, room_node)` → Gast läuft zum Platz

### Spot-Wechsel (alle 5-12 Min, via `_process_waiting`)
1. `get_available_interactions()` → `[]` falls Session abgelaufen → Abgang
2. `release_interaction(id)` → Room-Script entscheidet: Cooldown setzen oder Session behalten
3. `claim_interaction(id, new_spot)` → neuer Platz
4. Neuer `_action_timer` aus `claim_result["duration"]`

### Session-Ende (automatisch)
|---|---|
| `get_available_interactions(actor)` | Liste verfügbarer Interaktionen (Sitz, Bett, ...) |
| `claim_interaction(actor_id, id)` | Reserviert Platz, gibt `target_pos` + `duration` zurück |
| `release_interaction(actor_id)` | Gibt alle belegten Plätze frei |
| `is_gastro()` | *(NEU v0.1.50)* True → STUDYING_MENU nach Ankunft |
| `can_serve_solo()` | *(NEU v0.1.50)* True → Solo-Drink ohne Kellner möglich |

`_has_claimed_seat` trackt ob ein Sitz geclaimed ist. Wird beim Verlassen automatisch freigegeben.

## 8. Tagungsgäste (TG-Gäste)
Conference-Gäste (`party.event_poi_id != ""`) verhalten sich anders:
- Priorisieren zur Tagungszeit zwingend den Konferenzraum (`_decide_next_action`)
- `SITTING` State im gemeinsamen `[IN_POI, SITTING]` Block – kein Sonderfall mehr
- Mittagspause: `event_poi_id` temporär geleert → TG-Gäste dürfen Gastro-Räume nutzen (via `is_gastro()`)
- End of Day: 50% direkt nach Hause, 50% noch Gastro-Räume (via `is_gastro()`)
- Event-Gäste-Filter in `_get_open_pois()`: `is_gastro()` statt hardcoded ID-Liste

## 9. Zufriedenheit (Satisfaction) & Bedürfnisse
`satisfaction` ist ein zentraler Wert der gesamten `GuestParty`:
- **Sinkt durch**: Lange Wartezeiten, Hunger, dreckige/kaputte Zimmer
- **Steigt durch**: Erfolgreiche POI-Besuche (+2%), WLAN (+1%), Klima (+1%)
- Max. +4% pro Besuch (Balancing-Bremse)

## 10. Pathfinding & Bewegung
Gäste nutzen `MapGrid.get_path_astar()` für globale Pfade und `room.get_local_path()` für Bewegungen innerhalb von Räumen. Geschwindigkeit (`_base_speed`) skaliert mit `TimeManager.user_speed`.

## Gastro Consumption Type
- **`consumption_type`**: Gibt an, ob der Gast gerade ein Getränk (`"drink"`) oder eine Mahlzeit (`"food"`) zu sich nimmt. Wird in `_on_order_served` anhand des Rezept-Typs gesetzt oder auf `"drink"` bei Solo-Bestellungen an der Bar.
- **Live-Monitor:** Räume wie Bar und Restaurant lesen diesen Typ aus (während der Gast im `State.EATING` ist), um korrekt zwischen *Trinkt gerade* und *Isst gerade* zu unterscheiden.


### Zwangspause nach POI-Besuch (ANG-361)
Um zu verhindern, dass Gäste hektisch von POI zu POI rennen, wurde eine Zwangspause implementiert. Beim Verlassen eines beliebigen POIs (inklusive Lobby) wird `_poi_rest_until` gesetzt. Solange dieser Timer aktiv ist, werden alle `open_pois` blockiert, wodurch der Gast zwingend auf sein Zimmer geht und dort über `_wander_in_room()` die Zeit absitzt. Einzig enormer Hunger (`< HUNGER_THRESHOLD`) kann diese Zwangspause überschreiben, sofern sich der Gast noch eine Mahlzeit leisten kann.

## 11. Save/Load – State-Serialisierung (v0.1.61)

### State-Mapping in get_save_state()

| Aktueller State | Gespeicherter State | Begründung |
|---|---|---|
| `WALKING` | `IN_ROOM` | Unterwegs → beim Laden neu starten |
| `STUDYING_MENU` | `IN_POI` | Sitzt im POI-Raum → `_current_poi_id` muss erhalten bleiben! |
| `WAITING_FOR_FOOD` | `IN_POI` | Bestellung wird nach Load neu aufgegeben |
| alle anderen | unverändert | Direkt persistiert |

> ⚠️ `STUDYING_MENU` muss als `IN_POI` gespeichert werden! Sonst ist `_current_poi_id` nach Reload leer → Phase 1 von `_execute_walk()` kann Austrittspfad nicht generieren → Luftlinie durch Wände.

### restore_save_state() – IN_POI/EATING Branch

Gäste bleiben nach Reload in `IN_POI` (nicht `IN_ROOM`):
- Visuell an ihrem gespeicherten Platz (Restaurant, Bar etc.)
- `_current_poi_id` erhalten → Phase 1 von `_execute_walk()` findet den Raum
- Timer aus Save restored (min. 5s) → kein "Feueralarm"-Exodus aller Gäste gleichzeitig
- `_restoring_from_save = true` → blockiert doppeltes Payment/EXP

### restore_save_state() – IN_ROOM Branch (TG-Gäste)

`_current_poi_id` wird nur gesetzt wenn saved position ein **solid tile** ist (= wirklich innerhalb eines POI-Raums). Gäste im Korridor (WALKING-State beim Speichern) bekommen keine falsche Raum-ID.

### Warum _current_poi_id für Phase 1 entscheidend ist

`_get_current_room_node()` prüft `_current_poi_id` zuerst:
```gdscript
if not _current_poi_id.is_empty():
    return _get_poi_room_node(_current_poi_id)  # POI-Raum gefunden!
```
→ Phase 1 von `_execute_walk()` generiert `get_local_path(seat, door_inside)` korrekt → kein Luftlinie.

> Siehe auch: `wiki/_dev/ang364_nav_rework.md` für den Post-Alpha Nav-Rework Plan.
