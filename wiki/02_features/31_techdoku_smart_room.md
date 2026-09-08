# Smart-Room Architektur (TechDoku)
> **Zuletzt aktualisiert:** 08.09.2026 (v0.1.50 – Wellness-Session-System)
> **Relevante Scripte:** `Room.gd`, `GuestActor.gd`, `PoolSmall.gd`, `GymSmall.gd`, `SpaSmall.gd`

Das "Smart Room" System macht den `GuestActor` vollständig blind gegenüber Raumtypen. Räume parsen ihre eigenen Möbel beim Laden und bieten Gästen dynamisch Interaktionen an. Der Actor fragt – der Raum antwortet.

---

## 1. Das Konzept (`Room.gd`)

Jeder Raum erbt von `Room.gd`. In der `_ready()` Funktion wird `_find_furniture_recursive(self)` aufgerufen. Diese Funktion durchsucht alle Nodes im Raum nach passenden Namen:

- **Betten:** Node-Name enthält `bed` → `_room_beds`
- **Stühle (Gäste):** Node-Name enthält `chair` (nicht `chairspecial`) → `_room_seats`
- **Spezial-Stühle (Personal):** Node-Name enthält `chairspecial` → nur für Personal

### Kern-API (alle Räume implementieren diese Methoden)

| Methode | Bedeutung |
|---|---|
| `get_available_interactions(actor)` | Gibt verfügbare Interaktionen zurück (Sitz, Bett, ...) |
| `claim_interaction(actor_id, id)` | Reserviert Platz → gibt `target_pos` + `duration` zurück |
| `release_interaction(actor_id)` | Gibt alle Plätze des Actors frei |
| `is_guest_allowed(actor)` | Prüft ob Gast den Raum betreten darf (z.B. Cooldown) |
| `is_gastro()` | *(v0.1.50)* True → STUDYING_MENU nach Ankunft am Platz |
| `can_serve_solo()` | *(v0.1.50)* True → Solo-Modus wenn Küche fehlt (z.B. Bar ohne Waiter) |

### `is_functional()`
Universelle Methode in `Room.gd` – prüft ob Personal anwesend ist:
- Hat der Raum `min_staff: 0`? Immer functional.
- Benötigt er Personal (`required_role`)? Dann: physisch im Raum ODER Arbeitsauftrag (`_current_task.target.room == self`).

---

## 2. Der Gast-Loop (`_process_waiting`)

Wenn ein Gast (`IN_POI` oder `SITTING`) seinen `_action_timer` abläuft:

1. **Abrufen:** `get_available_interactions()` → Liste freier Plätze (oder `[]` wenn Session abgelaufen)
2. **Alten Platz freigeben:** `release_interaction(actor_id)`
3. **Neuen Platz claimen:** `claim_interaction(actor_id, choice.id)` → gibt `target_pos` + `duration` zurück
4. **Bewegen:** `_execute_poi_move(target_pos, room_node)` → Tween zum Platz
5. **Timer setzen:** `_action_timer = duration * SECONDS_PER_GAME_MINUTE`

### Erster Besuch (`_on_poi_arrived`)
Beim Ankommen am POI (einmalig):
- EXP + Income werden vergeben
- `claim_interaction()` wird aufgerufen
- **`_action_timer` wird aus `claim_result["duration"]` gesetzt** ← wichtig! Verhindert Sofort-Wechsel.

---

## 3. Wellness-Räume: Session-System (v0.1.50)

Pool, Gym und Spa haben ein **zweistufiges Timing-System**:

### Spot-Timer (5–12 Min Ingame)
- Wird in `claim_interaction()` als `result["duration"]` zurückgegeben
- Steuert den nächsten Platzwechsel (Stuhl → Liege → Wasser usw.)
- Alternation: Pool/Spa wechseln `sit` ↔ `sleep`, Gym wechselt Platz-ID

### Session-Timer (60–180 Min Ingame)
- Wird beim **ersten** `claim_interaction()` in `_guest_session_end[guest_id]` gesetzt
- Begrenzt auf Schließzeit des Raums
- Wenn `now >= _guest_session_end[guest_id]` → `get_available_interactions()` gibt `[]` zurück
- Nächster Spot-Timer-Ablauf → Gast verlässt den Raum

### Cooldown (60 Min nach Session-Ende)
- `release_interaction()` unterscheidet:
  - **Spot-Wechsel** (Session noch gültig) → Session wird behalten, kein Cooldown
  - **Session-Ende** (Session abgelaufen) → `_guest_cooldown_end[guest_id] = now + 60`
- `is_guest_allowed()` prüft `_guest_cooldown_end` → verhindert Wiedereintritt für 60 Min

### Aufenthaltsdauern

| Raum | Session-Dauer | Spot-Timer |
|---|---|---|
| Pool | 60–180 Min | 5–12 Min |
| Gym | 60–90 Min | 5–12 Min |
| Spa | 90–180 Min | 5–12 Min |

---

## 4. Raum-Übersicht & Erlaubte Aktionen

| Raum | Aktion | Besonderheiten |
| :--- | :--- | :--- |
| **EZ, DZ, Family, Superior** | `sleep`, `sit`, `wander` | Erben alles von `Room.gd` automatisch. |
| **Lobby** | `sit`, `wander` | Checkout-Gäste warten hier. |
| **Restaurant** | `sit` (→ `eat`) | `is_gastro() = true` → STUDYING_MENU nach Ankunft. Vollständiger Gastro-Flow via GastroManager. |
| **Bar** | `sit` (→ `drink`) | `is_gastro() = true`, `can_serve_solo() = is_bartender_present()` → Solo-Drink wenn kein Waiter. |
| **Pool** | `bed` (Liege), `seat` (Wasser) | Session 60–180 Min, Spot-Timer 5–12 Min. Alternation sit↔sleep. Kein `wander`. |
| **Gym** | `seat` (Geräte) | Session 60–90 Min, Spot-Timer 5–12 Min. Kein `wander`. |
| **Spa** | `seat` (Stuhl), `bed` (Liege) | Session 90–180 Min, Spot-Timer 5–12 Min. Alternation sit↔sleep. Kein `wander`. |
| **Konferenzraum** | `sit`, `speak`, `wander_pre` | SITTING-State für Zuhörer, kein Gastro-Trigger. |
| **StaffSmall** | `sit`, `sleep` | Für StaffActor Pausen. |

### Pool/Spa Furniture-Mapping
- `bed` Node → **Liege** (`sleep` Interaktion) → Live-Monitor: "Liegt" / "Entspannt"
- `seat`/`chair` Node → **Wasser/Stuhl** (`sit` Interaktion) → Live-Monitor: "Badet" / "Entspannt"

---

## 5. Live-Monitor Integration

Wellness-Räume implementieren `get_live_details()` mit:
- **Name** (links)
- **Status-Text** (rechts): Abhängig von Session-Zustand und Spot-Typ
  - Session läuft: `"Badet (45m)"`, `"Trainiert (30m)"`, `"Liegt (60m)"`
  - Session abgelaufen: `"Geht gleich"` (Abgang beim nächsten Spot-Timer)
- **Sortierung:** Aufsteigend nach Restzeit (kleinste Zeit = geht als nächstes = oben)

---

## 6. Neue Gastro-Räume einbauen (Checkliste)

Ein neuer Gastro-Raum (z.B. Kiosk, Poolbar) braucht nur:

1. `func is_gastro() -> bool: return true`
2. `func place_order_for_seat(guest_id, budget, missing_sat) -> bool` implementieren
3. `claim_interaction()` für Sitzplatz-Verwaltung (wie Restaurant/Bar)

**Keine Änderungen am `GuestActor` nötig!**

---

## 7. Veraltete Methoden (Legacy – NICHT mehr verwenden)

- `has_free_room_seat()` / `has_free_seat()`
- `room_claim_seat(id)` / `claim_seat(id)`
- `room_leave_seat(id)` / `leave_seat(id)`
- `claim_podium(id)`
- `_poi_stay_timer` (Variable in GuestActor – entfernt in v0.1.50)
- `is_smart_room` (Flag in GuestActor – entfernt in v0.1.50)
- `_process()` in Wellness-Räumen zum Kicking von Gästen (entfernt in v0.1.50 – führte zu Freezes)
