# Übergabe-Protokoll – 08.09.2026 (Session Ende)

## Was wurde gemacht?

### Wellness-System komplett stabilisiert (Pool / Gym / Spa)

**Root Causes identifiziert und behoben:**

1. **Session-Timer-Reset bei Spot-Wechsel** (ANG-339 o.ä.)
   - Ursache: `release_interaction()` löschte `_guest_session_end` bei JEDEM Aufruf (auch Spot-Wechsel)
   - Fix: Cooldown-System. `release_interaction()` prüft ob Session wirklich abgelaufen. Wenn ja: Cooldown 60 Min + Session löschen. Wenn nein (Spot-Wechsel): nichts löschen.

2. **Doppelbelegung von Sitzen** 
   - Ursache: `_process()`-Hack setzte `_action_timer = 0.0` → L212 Guard `if _action_timer <= 0.0: return` in `_process_waiting` → Gast eingefroren mit behaltenem Seat
   - Fix: `_process()` aus allen drei Räumen entfernt

3. **Sofort-Wechsel nach erstem Ankommen (EXP-Bug)**
   - Ursache: `_on_poi_arrived()` rief `claim_interaction()` auf aber ignorierte `duration` im Rückgabe-Dict. `_action_timer` blieb auf `0.01` → sofort weiter
   - Fix: In `_on_poi_arrived()` wird jetzt `dur = claim_result.get("duration", ...)` gesetzt und `_action_timer = dur * SECONDS_PER_GAME_MINUTE`

4. **Spa Bed-Lookup** nutzte falschen Key (`actor.get("actor_id")` statt `gm.id`) → "Liegt" wurde nie angezeigt. Fix in `SpaSmall.get_live_details()`.

**Features:**
- Wellness POI-Präferenzen nach Gasttyp (70% preferred_pois, 30% random)
- Spot-Alternation Pool/Spa (sit↔sleep), Gym (Platz-ID Wechsel)
- Spot-Timer auf 5–12 Min reduziert
- Live-Monitor: Badet/Entspannt (Pool), Liegt/Entspannt (Spa), "Geht gleich" bei Session-Ende, Sortierung aufsteigend nach Restzeit

## Letzter getesteter Stand

- Pool: ✅ Stabil (Gäste wechseln Spots, verlassen nach Session, Cooldown funktioniert)
- Gym: ✅ Stabil (idem)
- Spa: ✅ Stabil (idem)
- Live-Monitor alle 3: ✅ Korrekte Statusanzeige, Sortierung

## Offene Issues / Nächste Schritte

1. **ANG-340 (Linear):** [Space]-Taste pausiert Spiel UND kollabiert fokussierten Live-Monitor. NICHT behoben, nur geloggt. Bitte vor nächster Session angehen.
2. **Restaurant / Bar testen:** Noch nicht in dieser Session getestet. Smart-Room-Unification vom 07.09. müsste aber halten.
3. **Tagungsgast testen:** Mittagspause + Speaker-Swap – wurden in dieser Session nicht getestet.

## Relevante Dateien

- `scenes/ingame/rooms/pool_small/PoolSmall.gd` – Session + Cooldown + Live-Monitor
- `scenes/ingame/rooms/gym_small/GymSmall.gd` – Session + Cooldown + Live-Monitor  
- `scenes/ingame/rooms/spa_small/SpaSmall.gd` – Session + Cooldown + Alternation + Live-Monitor
- `scenes/ingame/guest/GuestActor.gd` – `_on_poi_arrived()` Timer-Fix (L928-933)
- `translations/language.csv` – 3 neue Keys: `poi.status.leaving_soon`, `poi.pool.swimming`, `poi.pool.lounging`

## Architektur-Wissen (wichtig!)

- `_action_timer = 0.0` NIEMALS von außen setzen! L212 Guard friert Gast ein.
- Spot-Wechsel und Session-Ende sind ZWEI verschiedene Ereignisse im `release_interaction()`
- `get_available_interactions()` ist das Steuerungselement: gibt `[]` zurück wenn Session abgelaufen
- `is_guest_allowed()` prüft Cooldown (nach Session-Ende)
