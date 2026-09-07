# Changelog – gd-0.1.50
> Session: 2026-09-07 | Branch: `dev`

---

## 🐛 Bugfixes

### ROOT CAUSE: Gastro-Flow-Totalausfall (GuestActor.gd)
- **Root Cause gefunden & behoben:** In `_process_waiting()` fehlten zwei `return`-Statements am Ende der `EATING`- und `STUDYING_MENU`-Branches. Dadurch fiel die Ausführung nach jeder Branch auf Zeile 422 durch (`_decide_next_action()`), was für **alle** gastronomiebezogenen Flows einen sofortigen Abbruch auslöste.
  - `STUDYING_MENU`: Gast bestellte → `_change_state(WAITING_FOR_FOOD)` → kein return → `_decide_next_action()` → Gast stand sofort auf und ging
  - `EATING`: Gast fertig → `_walk_to_room()` → kein return → `_decide_next_action()` → Gast ging nicht ins Zimmer, sondern in nächstes POI
  - **Fix:** `return` am Ende beider Branches eingefügt
  - **Ursache des Regressions:** Conference-Code hatte `elif current_state == State.IN_POI:` Block hinzugefügt, wodurch `_decide_next_action()` an Zeile 422 aus dem IN_POI-Block herausgerutscht war

### Snackautomat: _current_poi_id Bug (GuestActor.gd)
- **Root Cause:** In `_walk_to_poi()` wurde nach `_execute_walk()` die `_current_poi_id` aus `target_room.get_definition().id` gelesen. Da der Snackautomat in der **Lobby** liegt, lieferte `get_definition()` `"lobby"` statt `"vending_machine"`. In `_on_poi_arrived()` wurde dann sofort `return` ausgelöst (`_current_poi_id == "lobby"`).
  - **Fix:** Spezialfall-Check vor der Definition-Abfrage: `if poi_id == "vending_machine": _current_poi_id = "vending_machine"`

### Snackautomat: Direkter Tween statt _execute_walk (GuestActor.gd)
- **Root Cause:** `_execute_walk()` hat einen `is_nearby`-Check (< 200px) eingebaut, der bei leerem `path_tiles`-Array das Berechnen des lokalen Pfads zum Essplatz verhinderte → Gast blieb am Automaten stehen.
  - **Fix:** Für den Ess-Walk nach Automatenkauf wird jetzt ein direkter Tween mit `lobby.get_local_path()` erstellt, der NavBlocker respektiert und keine Distanzbeschränkung hat.

### HUD Gästezähler: TG-Gäste fehlten (GuestManager.gd)
- **Root Cause:** `spawn_conference_guests()` emittierte nach `_active.append(party)` nur `sig_party_event_arrived`, aber nicht `parties_changed`. Der HUD-Zähler hing ausschließlich an `parties_changed` → TG-Gäste wurden erst sichtbar wenn ein normaler Gast eine Aktion auslöste.
  - **Fix:** `parties_changed.emit()` direkt nach `_active.append(party)` in `spawn_conference_guests()` hinzugefügt.

---

## 🔧 Debug-Infrastruktur (temporär, zum Entfernen nach Test)
- `[DEBUG GASTRO]` Stack-Trace Print in `_decide_next_action()` für WAITING_FOR_FOOD State
- `[VENDING]` Prints für kompletten Snackautomat-Flow (Ankunft, buy_snack Ergebnis, Tween-Start)
- `[DEBUG RESTAURANT]` Print in `RestaurantSmall.place_order_for_seat()`
- `[CONF-DEBUG]` Prints in `ConferenceSmall.get_available_interactions()` (temporär)

---

## 📝 Hinweise
- Alle obigen Fixes betreffen `GuestActor.gd` und `GuestManager.gd`
- Debug-Prints vor nächstem Release entfernen
