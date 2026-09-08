# Raum: Spa (Klein)
> **Zuletzt aktualisiert:** 08.09.2026 (v0.1.50 – Wellness-Session-System)
> **Scene:** `scenes/ingame/rooms/spa_small/SpaSmall.tscn`
> **Script:** `scenes/ingame/rooms/spa_small/SpaSmall.gd`

## 1. Identifikation

| Feld | Wert |
|---|---|
| **ID** | `spa_small` |
| **Kategorie** | Wellness |
| **Techtree-Gate** | `W1.2` |
| **Max Gäste** | 6 |
| **Preis** | Eintritt via `visit_income` |

## 2. Spielmechanik

Gäste entspannen im Spa für 1,5–3 Ingame-Stunden und wechseln alle **5–12 Minuten** zwischen Massageliege und Entspannungsstuhl. Nach Ablauf der Session verlassen sie den Raum mit 60 Min Cooldown.

**Gasttyp-Präferenz:** Business, Luxury, VIP (via `preferred_pois` im Gasttyp-System, 70% Gewichtung).

## 3. Session-System

### Furniture-Mapping
| Node-Typ | Interaktion | Live-Monitor |
|---|---|---|
| `bed`-Node | `sleep` → Massageliege | "Liegt" (lila/indigo) |
| `chair`/`seat`-Node | `sit` → Entspannungsstuhl | "Entspannt" (blau) |

> **Key für Lookup:** `_room_beds[i]["occupied_by"] == gm.id` (NICHT `actor.get("actor_id")` – falscher Key!)

### Timing
- **Session-Dauer:** 90–180 Ingame-Minuten (begrenzt auf Schließzeit)
- **Spot-Timer:** 5–12 Ingame-Minuten pro Platz
- **Alternation:** `sit` ↔ `sleep` erzwungen (Stuhl → Liege → Stuhl...)
- **Cooldown:** 60 Min nach Session-Ende

### Wichtige Methoden (`SpaSmall.gd`)

| Methode | Funktion |
|---|---|
| `is_guest_allowed(actor)` | Prüft `_guest_cooldown_end` |
| `get_available_interactions(actor)` | Kein `wander`. Erzwingt sit↔sleep Alternation. `[]` wenn Session abgelaufen |
| `claim_interaction(actor_id, id)` | Setzt Session-Timer beim Erstbesuch, gibt Spot-Timer (5–12 Min) zurück |
| `release_interaction(actor_id)` | Spot-Wechsel: Session behalten. Session-Ende: Cooldown setzen |
| `get_live_details()` | Zeigt Liegt/Entspannt/Geht gleich, sortiert aufsteigend nach Restzeit |
| `get_work_position(staff_id)` | Personal patrouilliert alle 10 Aufrufe statt ServicePoint |

## 4. Personal

- **Wellness-Fachkraft** (optional): Patrouilliert via `get_patrol_target()` / `get_work_position()`.
- Ohne Personal: Spa gilt als nicht `is_functional()` sofern `min_staff > 0`.

## 5. Live-Monitor

```
Ophelia Mayr     Liegt (52m)        ← auf Massageliege (bed)
Manfred Schäfer  Entspannt (114m)   ← auf Stuhl (seat)
Sandro Tiedemann Geht gleich        ← Session abgelaufen
```

Sortierung: aufsteigend nach Restzeit.

## 6. Veraltete Konzepte (nicht mehr gültig)

- ~~`claim_seat()` beim `_ready`~~ → ersetzt durch `claim_interaction()` via Smart-Room-API
- ~~Platzwechsel alle 20–30 Min~~ → jetzt 5–12 Min
- ~~Aufenthaltsdauer direkt in Actor~~ → jetzt via `_guest_session_end` im Raum
