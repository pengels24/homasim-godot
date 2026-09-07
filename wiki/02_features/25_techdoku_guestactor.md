# TechDoku: GuestActor (Gäste-Verhalten)
*Stand: v0.1.50 – 2026-09-07*

Der `GuestActor` steuert die visuelle und logische Repräsentation eines einzelnen Hotelgastes auf der Karte. Jeder `GuestActor` ist an ein `GuestMember`-Datenobjekt gekoppelt, welches die eigentlichen Werte (Sättigung, Geduld, Geldbeutel, Budget) hält.

## 1. Lebenszyklus & Setup
- **Spawn**: Wird vom `GuestManager` instantiiert, sobald eine neue `GuestParty` (Gästegruppe) anreist oder aus einem Savegame geladen wird.
- **Setup**: `setup(member, map_grid, start_room, guest_manager)` verknüpft den Actor mit dem Datenmodell und setzt den initialen Zustand.
- **Despawn**: Wenn der Checkout abgeschlossen ist und der Gast das Grundstück verlässt (`LEAVING`), wird der Actor aus dem Tree entfernt.

## 2. State-Machine (Zustände)
Der Ablauf eines Gastes wird über die Enum `State` gesteuert:
- `IDLE`: Der Gast überlegt, was er als Nächstes tut. Sucht nach offenen POIs, geht aufs Zimmer oder wartet.
- `WALKING`: Bewegt sich entlang eines AStar-Pfads zu einem Ziel.
- `IN_ROOM`: Befindet sich im eigenen gebuchten Zimmer (meist zum Schlafen oder Erholen).
- `IN_POI`: Befindet sich in einem besuchbaren Raum (Lobby, Restaurant, Bar, Pool, etc.).
- `STUDYING_MENU`: Liest die Speisekarte (Restaurant/Bar) – Gastro-spezifisch.
- `WAITING_FOR_FOOD`: Hat bestellt, wartet auf Lieferung – Geduld sinkt über `_process_impatient`.
- `EATING`: Isst gerade – Sättigungsbalken steigt, Timer läuft.
- `AWAITING_CHECKOUT`: Steht in der Lobby und wartet auf Checkout.
- `LEAVING`: Hat ausgecheckt und läuft zum Ausgang.

## 3. _process_waiting – KRITISCHE ARCHITEKTUR-NOTIZ
> ⚠️ **ACHTUNG – Fallthrough-Gefahr!**

`_process_waiting()` hat einen `if _action_timer <= 0.0:` Block mit folgenden Branches:

```
if _action_timer <= 0.0:
    if current_state == EATING:
        ...
        return  ← PFLICHT, sonst Fallthrough!
    elif current_state == STUDYING_MENU:
        ...
        return  ← PFLICHT, sonst Fallthrough!
    elif current_state == IN_POI:
        ...
        # kein return am Ende (fällt durch zu _decide_next_action)
    
    _decide_next_action()  ← Zeile 422 – läuft für IN_POI + alle anderen States
```

**Regel:** Jeder Branch der einen State-Wechsel oder Walk auslöst, MUSS mit `return` enden. Andernfalls fällt die Ausführung auf `_decide_next_action()` durch – was Gäste sofort aus Restaurant/Bar herauslaufen lässt.

**History:** Dieser Bug trat auf als der Conference-Code den `elif IN_POI` Block hinzufügte und dabei `_decide_next_action()` aus dem IN_POI-Block herausrutschen ließ (v0.1.50 Fix).

## 4. Gastronomie-Integration (Restaurant / Bar)
Ist ein Gast im Restaurant oder an der Bar, durchläuft er eine Mini-State-Machine:
1. **IN_POI** → Eintreffen, Platz nehmen via Smart Room API (`claim_interaction`)
2. **STUDYING_MENU** → `_execute_poi_move()` Callback setzt diesen State; Timer für Menü-Lesen läuft
3. **WAITING_FOR_FOOD** → `place_order_for_seat()` war erfolgreich; `_process_impatient()` tickt
4. **EATING** → Essen wurde geliefert (Signal von RestaurantSmall/KitchenSmall); Sättigung steigt
5. **WALKING** → Nach dem Essen: `_walk_to_room()` → zurück ins Zimmer

**Bar-Sonderfall:** Bei der Bar gibt es keine Küche – bei `ordered == false` geht der Gast direkt in `EATING` (Getränk am Tresen).

## 5. Vending Machine (Lobby Snack-Automat)
Der Snackautomat ist ein Pseudo-POI in der Lobby.

**Wichtige Besonderheit:** `target_room` ist die **Lobby**, nicht ein eigener Raum. Daher:
- `_current_poi_id` muss in `_walk_to_poi()` **explizit** auf `"vending_machine"` gesetzt werden, BEVOR `target_room.get_definition().id` gelesen wird – sonst würde `"lobby"` überschreiben und `_on_poi_arrived()` sofort per Early-Return abbrechen.
- Der Ess-Walk nach dem Kauf nutzt **keinen** `_execute_walk()` (wegen des `is_nearby < 200px` Checks), sondern einen direkten Tween mit `lobby.get_local_path()` für korrekte NavBlocker-Respektierung.

**Flow:**
1. `_walk_to_poi("vending_machine")` → Gast läuft zu `get_vending_target_world()`
2. `_on_poi_arrived()` → `lobby.buy_snack()` → EXP + Geld
3. Direkter Tween zu `lobby.get_snack_eating_target_world()` via `get_local_path()`
4. `_change_state(EATING)` → 15s essen → dann `_walk_to_room()`

## 6. Smart Room System
Das Gast-Interaktionssystem läuft über die generische Smart Room API:
- `get_available_interactions(actor)` → listet verfügbare Interaktionen (Sitze, etc.)
- `claim_interaction(actor_id, interaction_id)` → reserviert Platz, gibt `target_pos` zurück
- `release_interaction(actor_id)` → gibt Platz frei

Der GuestActor trackt seine aktive Interaktion über `_has_claimed_seat` und gibt diese beim Verlassen oder State-Wechsel automatisch frei.

## 7. Tagungsgäste (TG-Gäste)
Conference-Gäste (`party.event_poi_id != ""`) verhalten sich anders:
- Priorisieren zur Tagungszeit zwingend den Konferenzraum (`_decide_next_action`)
- Während `party.event_poi_id` gesetzt: konferenzraum-spezifische Wander-Logik
- Mittagspause: `event_poi_id` wird temporär geleert → TG-Gäste dürfen Bar/Restaurant nutzen
- End of Day (17:00): 50% direkt nach Hause, 50% noch Bar/Restaurant
- Mitternacht: aus `_active` entfernt via `GuestManager.process_midnight_penalties()`

## 8. Zufriedenheit (Satisfaction) & Bedürfnisse
Die `satisfaction` ist ein zentraler Wert der gesamten `GuestParty`:
- **Sinkt durch**: Lange Wartezeiten, Hunger, dreckige/kaputte Zimmer, fehlende Requirements
- **Steigt durch**: Erfolgreiche POI-Besuche (+2%), WLAN (+1%), Klima (+1%)
- Max. +4% pro Besuch (Balancing-Bremse)

## 9. Pathfinding & Bewegung
Gäste nutzen `MapGrid.get_path_astar()` für globale Pfade und `room.get_local_path()` für Bewegungen innerhalb von Räumen. Geschwindigkeit (`_base_speed`) ist pro Gästetyp konfigurierbar und skaliert synchron mit `TimeManager.user_speed`.
