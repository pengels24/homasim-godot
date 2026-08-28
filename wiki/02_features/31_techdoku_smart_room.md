# Smart-Room Architektur (TechDoku)
> **Zuletzt aktualisiert:** 28.08.2026 (Phase 1)
> **Relevante Scripte:** `Room.gd`, `GuestActor.gd`, `StaffActor.gd`

Das "Smart Room" System ersetzt das alte, harte `claim_seat()` und `room_claim_bed()` System. Räume sind nun intelligent, parsen ihre eigenen Möbel beim Laden (über den Namen der Nodes) und bieten Gästen dynamisch Interaktionen an, aus denen die KIs dann per Gewichtung und Zustand wählen.

---

## 1. Das Konzept (`Room.gd`)

Jeder Raum erbt von `Room.gd`. In der `_ready()` Funktion wird `_find_furniture_recursive(self)` aufgerufen. Diese Funktion durchsucht alle Nodes im Raum nach passenden Namen (Groß-/Kleinschreibung egal):

- **Betten:** Node-Name enthält `bed` (aber nicht `beds`, `table`, `case`) → Werden in `_room_beds` gespeichert.
- **Stühle (Gäste):** Node-Name enthält `chair` (aber nicht `chairs`, `chairspecial`) → Werden in `_room_seats` gespeichert.
- **Spezial-Stühle (Personal):** Node-Name enthält `chairspecial` → Nur für Personal (z.B. Bademeister-Hochsitz).

### Die Basis-API

Die Gäste rufen nicht mehr `claim_seat` auf, sondern diese drei Methoden:

1. **`get_available_interactions(actor)`**
   Gibt ein Array aus Dictionaries zurück. Jedes Dictionary beschreibt eine mögliche Aktion, z.B. schlafen (`sleep`), sitzen (`sit`) oder wandern (`wander`).
2. **`claim_interaction(actor_id, interaction_id)`**
   Versucht, die gewünschte Interaktion zu reservieren. Blockiert das Möbelstück für andere. Gibt `target_pos` (wo der Actor hinlaufen soll) und oft `duration` zurück.
3. **`release_interaction(actor_id)`**
   Gibt alle vom Actor belegten Möbel in diesem Raum wieder frei. Wird aufgerufen, wenn der State wechselt (z.B. der Gast aufsteht).

---

## 2. Der Gast-Loop (`_wander_in_room`)

Wenn ein Gast (oder Staff im Pausenraum) einen Smart-Room betritt und sich aufhält (State: `IN_ROOM` oder `IN_POI` beim Wellness), feuert in regelmäßigen Abständen der `_action_timer`. Ist dieser abgelaufen, ruft der Actor `_wander_in_room(room)` auf:

1. **Abrufen:** Gast holt sich alle Interaktionen über `get_available_interactions()`.
2. **Filtern:** Er filtert die Interaktion heraus, die er *gerade eben* ausgeführt hat (`_last_interaction_id`), um nicht 2x nacheinander auf demselben Stuhl zu sitzen.
3. **Entscheiden (Gewichtung):**
   - Ist es Schlafenszeit (`force_sleep = true`), wird zwingend nach `type == "sleep"` gesucht.
   - Tagsüber würfelt der Gast:
     - 10% Chance auf ein kurzes Nickerchen (`sleep`)
     - 40% Chance, sich irgendwo hinzusetzen (`sit`)
     - 50% Chance, sich eine Random-Koordinate im Raum zum Stehen/Wandern zu suchen (`wander`).
4. **Belegen:** Er ruft `claim_interaction()` mit seiner Wahl auf und der Tween läuft los.

---

## 3. Raum-Übersicht & Erlaubte Aktionen

Die folgende Tabelle zeigt, welche Aktionen ein Raumtyp über die Smart-Room-Schnittstelle liefert:

| Raum / Kategorie | Aktion (`type`) | Auslöser / Möbel im `.tscn` | Besonderheiten |
| :--- | :--- | :--- | :--- |
| **EZ, DZ** | `sleep`, `sit`, `wander` | Node `*Bed*`, Node `*Chair*` | Erben alles automatisch von `Room.gd`. |
| **Family, Superior** | `sleep`, `sit`, `wander` | Node `*Bed*`, Node `*Chair*` | Erben alles automatisch von `Room.gd`. Gäste wechseln im Intervall durch. |
| **Lobby** | `sit`, `wander` | Node `*Chair*` | Gäste können hier sitzen, während sie auf Events oder Checkout warten. |
| **Bar / Restaurant** | `sit` | Node `*Chair*` | **Sonderregel (Gastro-Bypass):** Gast geht NICHT in `IN_POI`, sondern in `STUDYING_MENU`. Er wechselt den Platz *nicht*, bis das Essen vorbei ist. |
| **Spa, Gym, Pool** | *Geplant:* `sit`, `relax`, `swim`, `workout` | *Geplant:* Stühle, Liegen, Pools, Geräte | Muss noch auf Smart-Room migriert werden (hat noch Legacy `claim_seat`). |
| **StaffSmall** (Personalraum)| `sit`, `sleep` | Node `*Chair*`, Node `*Bed*` | StaffActor checkt tagsüber nach `sit`, nachts präferiert er `sleep`. |

---

## 4. WICHTIG: Veraltete Methoden (Legacy)

Folgende Methoden in `Room.gd` (oder Überschreibungen in den Räumen) sind **obsolet** und dürfen für neue Features oder Räume **nicht** mehr verwendet oder abgefragt werden:

- `has_free_room_seat()` / `has_free_seat()`
- `room_claim_seat(id)` / `claim_seat(id)`
- `room_leave_seat(id)` / `leave_seat(id)`
- `room_claim_bed(id)` / `claim_podium(id)`

*Hinweis: Wenn ein alter Raum (z.B. Spa) noch manuell `func claim_seat()` überschreibt, fällt das Pathfinding des Guests in einen Fallback-Modus. Diese Räume müssen bereinigt und in das neue Interaction-Array-System integriert werden!*
