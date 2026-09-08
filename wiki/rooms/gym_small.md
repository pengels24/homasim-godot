# Raum: Fitness-Studio (Klein)
> **Zuletzt aktualisiert:** 08.09.2026 (v0.1.50 – Wellness-Session-System)
> **Scene:** `scenes/ingame/rooms/gym_small/GymSmall.tscn`
> **Script:** `scenes/ingame/rooms/gym_small/GymSmall.gd`

## 1. Identifikation

| Feld | Wert |
|---|---|
| **ID** | `gym_small` |
| **Kategorie** | Wellness |
| **Techtree-Gate** | `W1.4` |
| **Req. Level** | 4 |
| **Max Gäste** | 6 |
| **Adults Only** | Ja |
| **Öffnungszeit** | 06:00–22:00 |
| **Preis** | Eintritt via `visit_income` (25€) |

## 2. Spielmechanik

Gäste trainieren im Gym für 1–1,5 Ingame-Stunden und wechseln alle **5–12 Minuten** das Trainingsgerät. Kein Herumwandern – nur Geräte (`seat`-Nodes). Nach der Session: 60 Min Cooldown.

**Gasttyp-Präferenz:** Alle Gasttypen (kein spezifisches `preferred_pois`).

## 3. Session-System

### Furniture-Mapping
| Node-Typ | Interaktion | Bemerkung |
|---|---|---|
| `chair`/`seat`-Node | `sit` → Trainingsgerät | Einziger Typ, kein `wander`, kein `sleep` |

### Timing
- **Session-Dauer:** 60–90 Ingame-Minuten (begrenzt auf Schließzeit 22:00)
- **Spot-Timer:** 5–12 Ingame-Minuten pro Gerät
- **Alternation:** Erzwingt Wechsel der Platz-ID (nicht derselbe Stuhl zweimal hintereinander)
- **Cooldown:** 60 Min nach Session-Ende

### Wichtige Methoden (`GymSmall.gd`)

| Methode | Funktion |
|---|---|
| `is_guest_allowed(actor)` | Prüft `_guest_cooldown_end` |
| `get_available_interactions(actor)` | Kein `wander`. `[]` wenn Session abgelaufen → Gast verlässt Raum |
| `claim_interaction(actor_id, id)` | Setzt Session-Timer beim Erstbesuch, gibt Spot-Timer (5–12 Min) zurück |
| `release_interaction(actor_id)` | Spot-Wechsel: Session behalten. Session-Ende: Cooldown setzen |
| `get_live_details()` | Zeigt Trainiert/Geht gleich, sortiert aufsteigend nach Restzeit |

## 4. Personal

- Kein dediziertes Personal (`min_staff: 0`). Gym läuft ohne Personal.

## 5. Live-Monitor

```
Daniela Hamann   Geht gleich       ← Session abgelaufen, Abgang beim nächsten Spot-Timer
Anton Kramer     Trainiert (17m)   ← 17 Ingame-Minuten verbleibend
Damian Nickel    Trainiert (22m)
```

Sortierung: aufsteigend nach Restzeit (kleinste Zeit = geht als nächstes = oben).

## 6. Besonderheiten

- `adults_only: true` – Kinder dürfen nicht trainieren
- Gym hat **keine** `bed`-Nodes, nur `chair`/`seat` → keine `sleep`-Interaktionen, keine Alternation zwischen Typen
- `_action_timer = 0.0` von außen NIEMALS setzen – friert Gast ein (L212 Guard in `_process_waiting`)
