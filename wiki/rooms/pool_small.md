# Raum: Pool (Klein)
> **Zuletzt aktualisiert:** 08.09.2026 (v0.1.50 – Wellness-Session-System)
> **Scene:** `scenes/ingame/rooms/pool_small/PoolSmall.tscn`
> **Script:** `scenes/ingame/rooms/pool_small/PoolSmall.gd`

## 1. Identifikation

| Feld | Wert |
|---|---|
| **ID** | `pool_small` |
| **Kategorie** | Wellness |
| **Techtree-Gate** | `W1.1` |
| **Max Gäste** | 6 |
| **Preis** | Eintritt via `visit_income` |

## 2. Spielmechanik

Gäste besuchen den Pool und verbringen 1–3 Ingame-Stunden. Sie wechseln alle **5–12 Minuten** zwischen Liege und Wasser. Nach Ablauf der Session verlassen sie den Raum und können frühestens **60 Minuten** später wiederkommen.

**Gasttyp-Präferenz:** Family, Single, Couple (via `preferred_pois` im Gasttyp-System, 70% Gewichtung).

## 3. Session-System

### Furniture-Mapping
| Node-Typ | Interaktion | Live-Monitor |
|---|---|---|
| `bed`-Node | `sleep` → Liege | "Entspannt" (dunkelblau) |
| `chair`/`seat`-Node | `sit` → Wasser | "Badet" (cyan) |

### Timing
- **Session-Dauer:** 60–180 Ingame-Minuten (begrenzt auf Schließzeit 22:00)
- **Spot-Timer:** 5–12 Ingame-Minuten pro Platz
- **Alternation:** `sit` ↔ `sleep` erzwungen (Wasser → Liege → Wasser...)
- **Cooldown:** 60 Min nach Session-Ende (`is_guest_allowed()` blockiert Wiedereintritt)

### Wichtige Methoden (`PoolSmall.gd`)

| Methode | Funktion |
|---|---|
| `is_guest_allowed(actor)` | Prüft `_guest_cooldown_end` – blockiert nach Session |
| `get_available_interactions(actor)` | Kein `wander`. `[]` wenn Session abgelaufen → Gast verlässt Raum |
| `claim_interaction(actor_id, id)` | Setzt Session-Timer beim Erstbesuch, gibt Spot-Timer (5–12 Min) zurück |
| `release_interaction(actor_id)` | Spot-Wechsel: Session behalten. Session-Ende: Cooldown setzen |
| `get_live_details()` | Iteriert `guest_actors` Gruppe, zeigt Badet/Entspannt/Geht gleich, sortiert aufsteigend nach Restzeit |

## 4. Personal

- **Bademeister** (`required_role: lifeguard_chair`): Patrouilliert am Beckenrand via `get_patrol_target()`. Durchquert NICHT das Wasser.
- Kein Bademeister → Pool gilt als nicht `is_functional()` → Gäste besuchen ihn nicht.

### Bademeister-Hochsitz-Logik

Der Bademeister nutzt den `ChairSpecial`-Node als Hochsitz. `PoolSmall.gd` überschreibt `claim_interaction()`:
- Bei `staff_seat_*`-Interaktionen: Blickrichtung wird als Winkel von Hochsitz → **`Chair4`** (Pool-Mitte) berechnet und als `look_at_dir` zurückgegeben.
- `StaffActor.gd` bestimmt mit `get_local_path().size() > 0` ob gelaufen wird oder ob direkt Rotation gesetzt wird (Nav-Snap-Robustheit, Threshold 8.0px = 2 Grid-Zellen).

**Re-Claim Mechanismus (seit 10.09.2026):**
- `Room.gd.get_available_staff_interactions()` gibt auch Plätze zurück, die der anfragende Actor selbst belegt → `occupied_by == "" or == staff_id`.
- `Room.gd.claim_interaction()` für `staff_seat_` erlaubt Re-Claim durch denselben Actor → gibt immer `look_at_dir` zurück (kein leeres Dict).
- Resultat: Rotation wird sowohl beim Erstbesuch als auch nach Patrouille korrekt gesetzt.

## 5. Live-Monitor

```
Elena Tiedemann     Badet (63m)       ← im Wasser (seat)
Peter Mayr          Entspannt (78m)   ← auf Liege (bed)
Lisa Nickel         Geht gleich       ← Session abgelaufen, Abgang beim nächsten Spot-Timer
```

Sortierung: aufsteigend nach Restzeit (kleinste Zeit = geht als nächstes = oben).
