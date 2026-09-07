# Smart-Room Architektur (TechDoku)
> **Zuletzt aktualisiert:** 07.09.2026 (v0.1.50 – Smart-Room-Unification)
> **Relevante Scripte:** `Room.gd`, `GuestActor.gd`, `GastroManager.gd`

Das "Smart Room" System macht den `GuestActor` vollständig blind gegenüber Raumtypen. Räume parsen ihre eigenen Möbel beim Laden und bieten Gästen dynamisch Interaktionen an. Der Actor fragt – der Raum antwortet.

---

## 1. Das Konzept (`Room.gd`)

Jeder Raum erbt von `Room.gd`. In der `_ready()` Funktion wird `_find_furniture_recursive(self)` aufgerufen. Diese Funktion durchsucht alle Nodes im Raum nach passenden Namen:

- **Betten:** Node-Name enthält `bed` → `_room_beds`
- **Stühle (Gäste):** Node-Name enthält `chair` (nicht `chairspecial`) → `_room_seats`
- **Spezial-Stühle (Personal):** Node-Name enthält `chairspecial` → nur für Personal

### Kern-API (alle Räume implementieren diese 5 Methoden)

| Methode | Bedeutung |
|---|---|
| `get_available_interactions(actor)` | Gibt verfügbare Interaktionen zurück (Sitz, Bett, ...) |
| `claim_interaction(actor_id, id)` | Reserviert Platz → gibt `target_pos` + `duration` zurück |
| `release_interaction(actor_id)` | Gibt alle Plätze des Actors frei |
| `is_gastro()` | *(NEU v0.1.50)* True → STUDYING_MENU nach Ankunft am Platz |
| `can_serve_solo()` | *(NEU v0.1.50)* True → Solo-Modus wenn Küche fehlt (z.B. Bar ohne Waiter) |

### `is_functional()`
Universelle Methode in `Room.gd` – prüft ob Personal anwesend ist:
- Hat der Raum `min_staff: 0`? Immer functional.
- Benötigt er Personal (`required_role`)? Dann: physisch im Raum ODER Arbeitsauftrag (`_current_task.target.room == self`).

---

## 2. Der Gast-Loop (`_process_waiting`)

Wenn ein Gast (`IN_POI` oder `SITTING`) seinen `_action_timer` abläuft:

1. **Abrufen:** `get_available_interactions()` → Liste freier Plätze
2. **Alten Platz freigeben:** `release_interaction(actor_id)`
3. **Neuen Platz clamen:** `claim_interaction(actor_id, choice.id)` → gibt `target_pos` + `duration` zurück
4. **Bewegen:** `_execute_poi_move(target_pos, room_node)` → Tween zum Platz
5. **Timer setzen:** `_action_timer = duration * SECONDS_PER_GAME_MINUTE`

Gastro-Trigger: `_execute_poi_move()` prüft `room_node.is_gastro()` – nur dann wird nach Ankunft `STUDYING_MENU` ausgelöst.

---

## 3. Raum-Übersicht & Erlaubte Aktionen

| Raum | Aktion | Besonderheiten |
| :--- | :--- | :--- |
| **EZ, DZ, Family, Superior** | `sleep`, `sit`, `wander` | Erben alles von `Room.gd` automatisch. |
| **Lobby** | `sit`, `wander` | Checkout-Gäste warten hier. |
| **Restaurant** | `sit` (→ `eat`) | `is_gastro() = true` → STUDYING_MENU nach Ankunft. Vollständiger Gastro-Flow via GastroManager. |
| **Bar** | `sit` (→ `drink`) | `is_gastro() = true`, `can_serve_solo() = is_bartender_present()` → Solo-Drink wenn kein Waiter. |
| **Pool** | `sit`, `swim` (kein `wander`) | `claim_interaction()` überschrieben → 60–180 Min Aufenthalt (begrenzt auf Schließzeit). |
| **Gym** | `sit` (kein `wander`) | `claim_interaction()` überschrieben → 60–90 Min Aufenthalt. |
| **Spa** | `sit`, `lie` (kein `wander`) | `claim_interaction()` überschrieben → 90–180 Min Aufenthalt. |
| **Konferenzraum** | `sit`, `speak`, `wander_pre` | SITTING-State für Zuhörer, kein Gastro-Trigger. |
| **StaffSmall** | `sit`, `sleep` | Für StaffActor Pausen. |

---

## 4. Neue Gastro-Räume einbauen (Checkliste)

Ein neuer Gastro-Raum (z.B. Kiosk, Poolbar) braucht nur:

1. `func is_gastro() -> bool: return true`
2. `func place_order_for_seat(guest_id, budget, missing_sat) -> bool` implementieren
3. `claim_interaction()` für Sitzplatz-Verwaltung (wie Restaurant/Bar)

**Keine Änderungen am `GuestActor` nötig!**

---

## 5. Veraltete Methoden (Legacy – NICHT mehr verwenden)

- `has_free_room_seat()` / `has_free_seat()`
- `room_claim_seat(id)` / `claim_seat(id)`
- `room_leave_seat(id)` / `leave_seat(id)`
- `claim_podium(id)`
- `_poi_stay_timer` (Variable in GuestActor – entfernt in v0.1.50)
- `is_smart_room` (Flag in GuestActor – entfernt in v0.1.50)


