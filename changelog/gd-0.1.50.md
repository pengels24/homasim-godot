# Changelog gd-0.1.50 – Session 07.09.2026 (Abend)

## Architektur-Refactoring: Smart-Room-Unification

### Problem
GuestActor.gd enthielt 21+ hardcodierte Raum-ID Checks (pool_small, gym_small, spa_small,
conference_small, restaurant_small, bar). Jeder neue Raumtyp erforderte Änderungen an mehreren
Stellen im Actor – führte zu ständigen Regressionen.

### Lösung: POI-Behaviour-Protokoll
Der GuestActor ist jetzt vollständig blind gegenüber Raumtypen.

**Room.gd (Basis):**
- Neue Methode is_gastro() -> bool (Standard: false)
- Neue Methode can_serve_solo() -> bool (Standard: false)

**RestaurantSmall.gd:**
- Überschreibt is_gastro() → return true

**Bar.gd:**
- Überschreibt is_gastro() → return true
- Überschreibt can_serve_solo() → return is_bartender_present()

**PoolSmall.gd / GymSmall.gd / SpaSmall.gd:**
- Überschreiben claim_interaction() mit raumspezifischer Aufenthaltsdauer:
  - Pool: 60–180 Min (begrenzt auf Schließzeit)
  - Gym: 60–90 Min (begrenzt auf Schließzeit)
  - Spa: 90–180 Min (begrenzt auf Schließzeit)
- get_live_details() liest jetzt _action_timer statt _poi_stay_timer

**GastroManager.gd:**
- Neue Methode try_gastro_order(guest_id, spending_budget, saturation, room_node) -> Dictionary
  - Gibt {ordered, solo_mode} zurück
  - Kapselt is_functional(), can_serve_solo(), place_order_for_seat() zentral
  - Kein Actor-Objekt als Parameter – nur primitive Werte (clean dependency)

**GuestActor.gd – Entfernt:**
- Variable _poi_stay_timer (vollständig entfernt)
- is_smart_room Flag, is_bar_gastro_loop Flag
- is_bartender_present() direkte Abfrage im Actor
- Kompletter _poi_stay_timer Block für Pool/Gym/Spa
- Hardcodierter STUDYING_MENU Block (80 Zeilen → 20 Zeilen via GastroManager)
- SITTING + conference_small Sonderfall → vereinheitlicht zu [State.IN_POI, State.SITTING]
- Legacy auskommentierter Code (claim_podium, claim_seat) endgültig entfernt
- Alle _current_poi_id Einzelvergleiche in Entscheidungspfaden

**GuestActor.gd – Vereinfacht:**
- _process_waiting(): 3 saubere Branches (EATING, STUDYING_MENU, IN_POI/SITTING)
- _on_poi_arrived(): Einheitlicher Claim-Pfad für alle Räume
- _execute_poi_move(): is_gastro() statt langer Ausschlussliste
- _change_state(State.IN_POI): Nur noch _action_timer = 0.01
- Event-Gäste-Filter, Conference-Break und End-of-Day: is_gastro() statt hardcoded Listen

## Bugfixes

### Konferenz: Zucken der Zuhörer behoben
- Root Cause: State SITTING nicht in _process_waiting() abgefangen → dauernder Timer-Reset
- Fix: SITTING im einheitlichen [State.IN_POI, State.SITTING] Block

### Konferenz: Speaker-Wechsel funktioniert wieder
- Folge des Zucken-Fixes: Timer läuft durch → _swap_speaker() regulär ausgelöst

## Offene Tests (für morgen)
- Pool/Gym/Spa: Aufenthaltsdauer korrekt?
- Restaurant / Bar (solo + full): Bestell-Flow
- Tagungsgast: kein Zucken, Speaker-Wechsel nach ~15 Min
- Tagungsgast Mittagspause: Restaurant und Rückkehr
---

## Session 08.09.2026 - Wellness-Overhaul (Pool/Gym/Spa)

### Bugfixes

- **Session-Timer-Reset (Pool/Gym/Spa):** Spot-Wechsel setzte Session zurueck -> EXP-Spam. Fix: Cooldown-System trennt Spot-Wechsel von echtem Session-Ende.
- **Doppelbelegung von Sitzen:** _process()-Hack setzte _action_timer=0.0 -> permanenter Ruhezustand -> Seats nie freigegeben. Fix: _process() entfernt.
- **Sofort-Wechsel nach erstem Ankommen:** _on_poi_arrived() ignorierte duration aus claim_interaction(). _action_timer blieb auf 0.01. Fix: duration korrekt als erster Timer gesetzt.
- **Gast bleibt nach Session-Ende:** get_available_interactions() gibt [] zurueck -> naechster Spot-Timer -> sauberer Abgang.
- **Spa Bed-Lookup:** nutzte falschen Key actor.get("actor_id") statt gm.id. Behoben.

### Features

- **Wellness POI-Praeferenzen:** 70/30 Gewichtung (preferred_pois/random). Pool -> Family/Single/Couple, Spa -> Business/Luxury/VIP.
- **Alternation (Pool/Spa):** sit<->sleep (Wasser<->Liege) erzwingt Platzwechsel fuer visuelle Lebendigkeit.
- **Spot-Timer:** 5-12 Min (war 10-20), belebtere Atmosphaere.
- **Live-Monitor Pool:** Badet (Wasser/seat) vs Entspannt (Liege/bed), verschiedene Farben.
- **Live-Monitor Spa:** Liegt (Liege/bed) vs Entspannt (Stuhl/seat), verschiedene Farben.
- **Live-Monitor alle Wellness:** "Geht gleich" bei abgelaufener Session, Sortierung aufsteigend nach Restzeit.
- **Language Keys:** poi.status.leaving_soon, poi.pool.swimming, poi.pool.lounging

### Architektur: Cooldown-System

- `_guest_session_end`: wann Session endet
- `_guest_cooldown_end`: 60 Min Sperre nach Session-Ende
- `is_guest_allowed()`: prueft Cooldown (kein Wiedereintritt)
- `release_interaction()`: Cooldown nur bei echtem Session-Ende, nicht bei Spot-Wechsel

---

## Session 08.09.2026 (Nachmittag) - Tests, Fixes & Aufraumen

### Getestet & bestaetigt ✅

- Bar Gastro-Flow (vollstaendig): Studiert Speisekarte → Kuechenauftrag → Abholbereit → Serviert → Sitzt/Trinkt
- Restaurant Gastro-Flow (vollstaendig): identischer Flow, beide Raeume teilen Kueche korrekt
- Kueche: beliefert Bar und Restaurant parallel, Status-Anzeige korrekt
- Zimmer (DZ): Check-in, Navigation im Zimmer, Wander/Schlafen, Checkout-Walk ohne Ghost-Walking
- Personalraum: Smart Room API fuer Gaeste korrekt, Staff Legacy-API bewusst erhalten

### Bugfixes

- **Check-in POI-Sperre (Save-Load Bug):** _checkin_poi_block_until wurde in setup() gesetzt.
  setup() wird auch beim Spielladen aufgerufen → alle Gaeste bekamen 60 Min Sperre beim Spielstart.
  Fix: Sperre in start_checkin() verschoben (wird nur bei echtem Neuankoemmling aufgerufen).
- **Autosave ignoriert Setting:** Timer lief weiter obwohl Autosave in Settings auf "Aus".
  Fix 1: Guard direkt in _on_timed_autosave() (prueft autosave_enabled zur Laufzeit).
  Fix 2: Guard in _on_day_ended() (Tag-Ende-Save auch deaktiviert wenn Autosave aus).
  Fix 3: sig_settings_changed Signal in SettingsManager + IngameSaveController reagiert
         mit Timer-Neustart/Stop bei Live-Aenderung der Einstellung.

### Features

- **Check-in POI-Sperre (60 Ingame-Min):** Nach echtem Check-in bleiben Gaeste 60 Min im Zimmer,
  bevor sie POIs besuchen (realistisch: Koffer ablegen, ankommen). Kein Einfluss auf Save-Load.

### Linear Issues

- ANG-343 angelegt: "Architektur: StaffActor Smart-Room-Unification" (Prio: Medium)
  StaffActor hat Legacy claim_seat/leave_seat API + hardcoded "staff_small" String.
  Refactoring analog GuestActor (v0.1.50) vor dem naechsten neuen Staff-Raum-Typ.

### Noch offen

- ANG-340: [Space] kollabiert fokussierten Live-Monitor (Backlog)
- Conference: Test Speaker-Swap, Mittagspause, Zuhoehrer-Zucken → Fokus morgen
