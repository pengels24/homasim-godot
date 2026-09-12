# HO·MA·SIM – Alpha Backlog & Roadmap
> Branch: `dev` | Start: v0.1.40 | Aktuell: v0.1.52 | Stand: 12.09.2026
> Bibel für die Alpha-Phase. Vor jeder Umsetzung hier nachschlagen!

---

## ⚠️ Getroffene Design-Entscheidungen (nicht mehr diskutieren!)

- **Personalflure:** Kommen NICHT in die Alpha. Grund: würde auf altem 1-Layer-Nav aufbauen → Brückencode. Kommen zusammen mit dem Nav-Rework (3 Layer: Gäste / Personal / Rauminneres + feineres Grid).
- **Küche/Restaurant Alpha:** Nur eine Tür (Gäste-Eingang). Zweite Tür (Personaleingang) kommt mit Personalflur-Feature.
- **Branching:** `master` = TechDemo-Bugfixes. `dev` = Alpha-Entwicklung. Nach TechDemo-Fix immer kurz `git merge master` in `dev`.

---

## 🛠 Ungeplante Fixes & Features (Aktuelle Session)
- ✅ **ConferenceSmall Speaker-Swap ohne Reload (ANG-346, 12.09.2026):** Reihenfolge in `_on_minute_passed()` getauscht → Phase wird vor Speaker-Timer-Check gesetzt. Feuert jetzt nach 15 Min ohne Reload.
- ✅ **TG-Gäste aus Rezeptionsliste gefiltert (12.09.2026):** `ModalContentReception.gd` überspringt Parties mit `event_poi_id != ""`.
- ✅ **Mittagspause Lobby-Gewichtung (12.09.2026):** Gastro 3× vs. Lobby 1× in `go_conference_break()` – verhindert überfüllte Lobby während Pause.
- ✅ **ModalContentFinances String-Format-Guard (12.09.2026):** `_translate_tx_desc()` crashte bei Keys ohne `%s`. Guard prüft jetzt ob Platzhalter vorhanden.
- ✅ **tx.construction Translation-Key (12.09.2026):** `language.csv` ergänzt – `Ausstattung: %s` (DE) / `Equipment: %s` (EN). Betrifft WLAN/Klima Bau-Transaktionen.
- ✅ **Konferenz-Pausenzeiten angepasst (12.09.2026):** Rückkehr 13:45 → 13:15, Nachmittagsstart 14:00 → 13:30.
- ✅ **AGENTS.md Versions-Regl (12.09.2026):** Direktive – eine Session = eine Version, +v nur am Tagesende.
- ✅ **wiki/_dev/test_review.md angelegt (12.09.2026):** Living-Checklist für Testpunkte.
- ✅ **Skill /review erstellt (12.09.2026):** Eintragen in test_review.md via `/review [text]`.

- ✅ **Pool Live Monitor:** Erfasst nun alle Gäste der Gruppe `guest_actors` (nicht nur sitzende) inkl. verbleibender Ingame-Minuten-Anzeige ("Baden (Xm)").
- ✅ **Pool Interaktionen:** `get_available_interactions()` überschrieben, um `"wander"` im Pool zu unterbinden.
- ✅ **GuestActor Pathfinding (Checkout):** `_current_poi_id` Aktualisierung in `start_checkout` korrigiert, um Ghost-Walking (Luftlinie durch Wände) bei der Abreise zu verhindern.
- ✅ **QuestManager POI-Zähler:** Fehlenden Trigger `QuestManager.on_poi_used` in `GuestActor` eingebaut, damit POI-bezogene Quests richtig zählen.
- ✅ **QuestManager Wildcard-Fix:** Logikfehler beim Abgleich von generischen Quests (leere `target_id`) korrigiert.
- ✅ **Konferenzraum Quest:** Veralteten Forschungs-Node `B1.1` in `quests.json` durch `P1.2` ersetzt.
- ✅ **Konferenz-Gäste Pathing & UI:** Pathfinding-Fixes für Event-Gäste (Lobby-Verteilung per `get_free_walkable_pos()`), Fix des globalen AStar-Debugs, LiveMonitor Updates (Anzeige von `(TG)` und Live-Snack-State), korrekte Zählung im Raum-Tooltip und Behebung eines `Object.get()` Crashes.
- ✅ **Konferenz-Spawn Wellen:** Fehler in der while-Bedingung `GuestManager.spawn_conference_guests` korrigiert, sodass auch die 3. Welle (Gäste 9-12) das Hotel erreicht.
- ✅ **Konferenz-Priorität:** `GuestActor._decide_next_action()` priorisiert zur Event-Zeit den Konferenzraum zwingend vor regulären POIs.
- ✅ **Room Key Fixes:** Restliche `instance_id`-Überbleibsel in `GuestActor._walk_to_poi()`, `CustomTooltip.gd` und der Türsteher-Logik von `ConferenceSmall.gd` durch den sicheren `GuestManager._room_key` abgelöst.
- ✅ **ConferenceSmall Flow-Overhaul (03.09.2026):**
  - Speaker-Swap atomar (kein release/claim-Umweg mehr)
  - `_current_poi_id` immer auf POI-Typ ("conference_small"), nicht Raumkey ("P0001")
  - `is_in_event_room` nutzt jetzt korrekt `_room_key()` Vergleich
  - Wander-Vorpuffer 07:45–08:00 implementiert (`wander_pre` Interaktion)
  - Tagungsraum öffnet um 07:45 (`open_from: 465`)
  - Double-Offset Bug bei `get_random_walkable_local_pos()` behoben (kein `to_global()` mehr)
  - Blickrichtung zum Speakertable für alle Stühle beim `claim_interaction`
  - Live-Monitor zeigt Wander-TG (vor 08:00) korrekt an
- ✅ **Conference Flow Fixes (04.09.2026):**
  - Infinite EXP-Loop behoben: `GuestActor` fragt den Event-Raum nun direkt über `_guest_manager._get_room_node(party.event_poi_id)` ab, anstatt fälschlicherweise das Schlafzimmer (`_target_room`) zu prüfen, was zu Dauerschleifen (`WALKING -> IN_POI`) führte.
  - Präfix des Konferenzraums in der Definition von `P` (Personal) auf `C` geändert (Vermeidung von ID-Kollisionen mit `party_id`).
  - Live-Monitor: Harte `...` Anzeige für wandernde Tagungsgäste durch übersetzbaren Text `GameState.T("poi.conference.waiting")` ("Wartet") ersetzt.
- ✅ **Conference EXP-Loop Root Cause Fix (04.09.2026, Session 2):**
  - Root Cause gefunden: `get_available_interactions` listete den eigenen besetzten Sitz nicht als verfügbar (`occupied_by == actor_id` fehlte). Gäste sahen 0 Optionen → `_decide_next_action()` → globaler Walk → EXP-Bypass via `_has_claimed_seat == true`.
  - Fix 1: `ConferenceSmall.get_available_interactions` gibt jetzt auch den eigenen Sitz zurück (`occupied_by == "" or occupied_by == actor_id`).
  - Fix 2: Fallthrough-Guard in `GuestActor._process_waiting`: Vor `_decide_next_action()` wird `release_interaction` aufgerufen und `_has_claimed_seat = false` gesetzt.
  - Speaker Swap 1 und 2 laufen jetzt sauber durch, Live-Monitor stabil, kein EXP-Spam mehr.
- ✅ **Log-Cleanup (04.09.2026, Session 3):**
  - `[GuestActor] changed state:` Print auskommentiert (war bei 12 Gästen der dominante Fluter).
  - `[StaffActor] changing to next_state=` Print auskommentiert. Nützliche Fehler-Prints bleiben erhalten.
- ✅ **Konferenz-Mittagspause implementiert (04.09.2026, Session 3):**
  - `go_conference_break()` / `return_from_conference_break()` / `end_conference_day()` in `GuestActor.gd`.
  - `_start_break()` / `_end_break()` / `_broadcast_to_event_guests()` in `ConferenceSmall.gd`.
  - `party.event_poi_id` wird während der Pause temporär geleert (TG-Gäste akzeptiert als normale Gäste in Bar/Restaurant).
  - `TIME_BREAK_END` auf 825 (13:45), Hardcode in `GuestActor._decide_next_action()` synchronisiert.
  - End of Day (17:00): 50% direkt nach Hause, 50% noch Bar/Restaurant.
- ✅ **Tooltip-Mismatch behoben (04.09.2026, Session 3):**
  - Tooltip nutzt nun `get_nodes_in_group("guest_actors")` statt `ctrl._actors.values()` (dieselbe Quelle wie Live-Monitor).
  - WALKING-State wird gezählt wenn `_current_poi_id` noch auf den Raum zeigt.
- ✅ **Gastro-Flow-Totalausfall behoben (07.09.2026):**
  - **Root Cause:** In `_process_waiting()` fehlten `return`-Statements am Ende der `EATING`- und `STUDYING_MENU`-Branches. Ausführung fiel auf `_decide_next_action()` (Zeile 422) durch – Conference-Code hatte diese Zeile aus dem IN_POI-Block herausrutschen lassen.
  - **Fix 1:** `return` am Ende des EATING-Branches (verhindert Fallthrough nach `_walk_to_room()`)
  - **Fix 2:** `return` am Ende des STUDYING_MENU-Branches (verhindert Fallthrough nach `_change_state(WAITING_FOR_FOOD)`)
  - Resultat: Restaurant, Bar und Post-Essen-Zimmer-Walk funktionieren wieder korrekt.
- ✅ **Snackautomat vollständig repariert (07.09.2026):**
  - Bug 1: `_current_poi_id` wurde durch `target_room.get_definition().id` auf `"lobby"` überschrieben → `_on_poi_arrived()` brach sofort ab. Fix: Expliziter Spezialfall `if poi_id == "vending_machine"`.
  - Bug 2: `_execute_walk()` `is_nearby`-Check (< 200px) verhinderte Ess-Walk. Fix: Direkter Tween mit `lobby.get_local_path()` für NavBlocker-respektierenden Weg zum Essplatz.
- ✅ **HUD Gästezähler für TG-Gäste (07.09.2026):** `parties_changed.emit()` fehlte in `spawn_conference_guests()` nach `_active.append()`. TG-Gäste wurden erst bei nächster normaler Gästeaktion gezählt.
- ✅ **Konferenz: Zucken der Zuhörer + Speaker-Wechsel-Ausfall behoben (07.09.2026, Abend):** Root Cause: `State.SITTING` wurde in `_process_waiting()` nicht abgefangen → endloser Timer-Reset → Speaker-Swap-Timer erreichte nie 15 Min. Fix: `SITTING` im einheitlichen `[State.IN_POI, State.SITTING]` Block behandelt.
- ✅ **ARCHITEKTUR: Smart-Room-Unification (07.09.2026, Abend):** 21+ hardcodierte Raum-ID Checks aus `GuestActor.gd` vollständig entfernt. Neue Architektur:
  - `Room.gd`: Neue Basis-Methoden `is_gastro()` und `can_serve_solo()`
  - `RestaurantSmall.gd` + `Bar.gd`: Überschreiben `is_gastro()` → `true`
  - `Bar.gd`: Überschreibt `can_serve_solo()` → `is_bartender_present()`
  - `PoolSmall/GymSmall/SpaSmall.gd`: Überschreiben `claim_interaction()` mit korrekter Aufenthaltsdauer (Pool 60-180, Gym 60-90, Spa 90-180 Min). `get_live_details()` liest `_action_timer` statt `_poi_stay_timer` (entfernt)
  - `GastroManager.gd`: Neue zentrale Methode `try_gastro_order()` für alle Gastro-Räume
  - `GuestActor.gd`: `_poi_stay_timer`, `is_smart_room`, `is_bar_gastro_loop` und alle Room-ID-Checks entfernt. STUDYING_MENU Block (80→20 Zeilen), vereinheitlichter IN_POI/SITTING Block, `_change_state(State.IN_POI)` ohne room-ID Logik.
  - **Ergebnis:** Neue Gastro-Räume benötigen nur `is_gastro() -> true` + `place_order_for_seat()` – keine Änderungen am Actor mehr nötig.
  - **Offene Tests (morgen):** Pool/Gym/Spa Aufenthalt, Restaurant, Bar (solo+full), Tagungsgast (kein Zucken, Speaker-Swap, Mittagspause)
- ✅ **Wellness-System Overhaul (08.09.2026):**
  - Session-Timer-Reset bei Spot-Wechsel behoben (Cooldown-System in Pool/Gym/Spa)
  - Doppelbelegung von Sitzen behoben (_process()-Hack entfernt)
  - Sofort-Wechsel nach erstem Ankommen behoben (_on_poi_arrived nutzt claim duration als ersten Timer)
  - Gast bleibt nach Session-Ende behoben (get_available_interactions gibt [] -> naechster Spot-Timer -> Abgang)
  - Spa Bed-Lookup-Fix (gm.id statt actor.get("actor_id"))
  - Wellness POI-Praeferenzen nach Gasttyp (70/30 preferred_pois/random)
  - Spot-Wechsel Alternation Pool/Spa (sit<->sleep), Spot-Timer auf 5-12 Min reduziert
  - Live-Monitor: Badet/Entspannt (Pool), Liegt/Entspannt (Spa), Geht gleich, Sortierung nach Restzeit
- ✅ **ANG-340: [Space] kollabierte fokussierten Live-Monitor (10.09.2026):** `focus_mode = FOCUS_NONE` auf `BtnCollapse`, `BtnClose` und `ColorPickerButton` in `RoomDetailsMonitor.tscn`.
- ✅ **Tests bestätigt (08.09.2026 Nachmittag):** Bar-Flow, Restaurant-Flow, Küche, Zimmer (DZ), Personalraum – alle grün
- ✅ **Check-in POI-Sperre (60 Ingame-Min):** Nach echtem Check-in bleiben Gäste im Zimmer. Fix: in `start_checkin()` statt `setup()` gesetzt (Save-Load-Bug)
- ✅ **Autosave ignoriert Setting:** Dreifacher Guard + `sig_settings_changed` → Timer stoppt/startet live bei Einstellungsänderung
- ✅ **ANG-343: StaffActor Smart-Room-Unification (10.09.2026):** 3 hardcodierte `get_job_type()`-Checks entfernt. Bartender-Block (Dead Code) gelöscht. Lifeguard-Guard → `has_method("get_available_staff_interactions")`. Waiter-Wander → `get_work_position()`. Getestet: Bartender ✅, Waiter ✅, Lifeguard ✅.
- ✅ **Bademeister Blickrichtung & Rotation (10.09.2026):** `PoolSmall.claim_interaction` überschrieben → `look_at_dir` auf Chair4. `Room.gd` Re-Claim erlaubt (`occupied_by == actor_id`). StaffActor Pfad-basierte sit-vs-walk Entscheidung (lp.size() statt Distanz-Threshold). Threshold 8.0px (2×4px Grid).
- ✅ **TG-Checkout-Flow Komplett-Overhaul (09.09.2026):**
  - `GuestController.spawn_active_guests()`: Two-Pass-Pattern – TG-Gäste nach Tagungsende werden gesammelt und NACH dem Loop via `checkout_event_party()` sauber ausgecheckt (kein Array-Modification-Bug)
  - `GuestManager.checkout_event_party()`: Neue Methode – entfernt Party aus `_active`, setzt `state = "gone"`, emittet `sig_party_checked_out_physically` → normaler Checkout-Flow greift
  - `GuestActor.complete_checkout()`: Setzt `_current_poi_id = "lobby"` bei Reload-Spawn, damit `_walk_to_exit()` via Smart-Room-Navigation einen korrekten lokalen Pfad durch die Lobby generiert (verhindert unsichtbaren Sofort-Exit)
  - Spawn an korrekten `ReceptionX`-Waypoints (`lobby.get_checkout_wait_pos()`) statt generischem Lobby-Spawn
  - Guard in `GuestActor`: Nach dem Essen → direkt `start_checkout()` wenn Tagung vorbei (kein Idle in Lobby)
  - Lobby Live Monitor filtert LEAVING-State aus → Tooltip (0) und Live Monitor (0) konsistent, kein "Tooltip=0 / LiveMon=12" Verwirrung
- ✅ **Event-HUD Features (09.09.2026):**
  - `HUD.gd`: `event_name_label` zeigt Restzeit der Tagungssession als Countdown (z.B. „Marketingkonferenz (1h30m)")
  - `HUD.gd`: Klick auf Event-Indikator → Kamera springt smooth (Tween 0.4s, Zoom 4) zum aktiven Tagungsraum – identisch F4-Raumliste
  - Erfordert: `EventIndicator` im HUD muss ein Control-Node sein (gui_input Hook)
- ✅ **Autosave-Fix (10.09.2026):** `SettingsManager.gd` – Index-Offset korrigiert; Option „Aus" (0 Min) fehlte als erster Eintrag.
- ✅ **HUD Timer Type-Fix (10.09.2026):** `HUD.gd` – `max()` durch `maxi()` ersetzt (Godot 4 Type-Inference-Bug).
- ✅ **GuestActor `get_status_text()` – Single Source of Truth (10.09.2026):**
  - Neue Methode kapselt alle 12 States (`WALKING`, `IN_POI`, `IN_ROOM`, `SITTING`, `SLEEPING`, `STUDYING_MENU`, `WAITING_FOR_FOOD`, `EATING`, `WAITING_IN_LINE`, `AWAITING_CHECKOUT`, `LEAVING`, `IDLE`).
  - WALKING: zeigt Ziel-Raumnummer `"Unterwegs (Z0005)"`.
  - IN_POI: kein `"in "` Präfix mehr; Koordinaten-Fallback-Keys unterdrückt.
  - vending_machine: Sonderfall → `"Snack-Automat"` (DE) / `"Vending Machine"` (EN).
  - IN_ROOM/SITTING/SLEEPING: zeigt Raumnummer (z.B. `"Doppelzimmer Z0005"`).
  - **Architektur:** Neue States/Räume nur noch in `GuestActor.get_status_text()` eintragen – kein UI-Code mehr.
- ✅ **Gästeliste (F3) UI-Overhaul (10.09.2026):**
  - ~120 Zeilen duplizierter State-Checking-Code → 3 Zeilen `actor.get_status_text()`.
  - Konsistente Spaltenbreiten (Header + Zeilen gleiche `stretch_ratio`).
  - Textspalten linksbündig, Wertspalten (Budget, Sättigung, Zufr.) rechtsbündig.
  - `clip_text` + `OVERRUN_TRIM_ELLIPSIS` auf Status-Spalte + sekündlich synchroner Tooltip.
  - Header: „Zimmer" → „Raum", „Status" → „Status / Raum".
  - `float` → `int` für alle Needs-Werte.
- ✅ **Reachability-Check (Insel-Erkennung) reaktiviert (11.09.2026):** Der Bau-Validierungscheck für abgekappte Räume war dead code (zwei Root-Causes gleichzeitig).
  - **Root Cause 1:** `lobby_tile` zeigte auf Lobby-Körper-Mitte (val=1 = solid) → `is_point_solid()` war immer true → Check übersprungen.
  - **Root Cause 2:** Lobby ist in `active_rooms`, ihr externer Exit-Tile liegt außerhalb der Parzelle (col -1) → von innen nie erreichbar → alle Ghost-Positionen fälschlich rot.
  - **Fix:** Check 1 startet vom **Ghost-Exit-Tile** (nicht Lobby). Lobby wird in der Check-1-Schleife übersprungen (`id == "lobby"`). Check 2 nutzt internen Corridor-Tile (entrance_dir-abhängig) für Ghost-Verbindungstest.
  - **Ergebnis:** Ghost zeigt korrekt rot wenn er einen Raum isolieren würde, grün bei valider Platzierung.
- ✅ **Pre-Alpha Demo Ende (11.09.2026):** Nach Erreichen des 1. Sterns friert die EXP ein. Modaltext auf Pre-Alpha angepasst. Startup Disclaimer angepasst.
- ✅ **Hotelübersicht Modal F9 (11.09.2026):** Modal mit WiSim-Metriken (Auslastung, Ruf, Finanzen, etc.) inkl. Hotkey eingebaut.
- ✅ **Gourmet-Sterne: Anonymer Inspektor & Bericht (11.09.2026):** Inspektor spawnt komplett getarnt als "single" (ohne Log-Eintrag). Nach dem Checkout triggert ein neues `ModalContentInspectorReport` mit der Sterne-Bewertung, gefolgt von der Star-Animation.

## 🧱 Phase 1 – Fundament (v0.1.40–41)
*Zuerst, weil alles andere darauf aufbaut.*

### 1.1 Max-Level auf 10 + Balancing
**Status:** ✅ Erledigt (Max-Level ist 15, `get_xp_needed_for_level` ist bis Lvl 10 exponentiell ausgebaut, `UNLOCK_LEVELS` aktiv).

- Level-Kurve von aktuell 5 auf 10 verlängern (`wiki/22_balancing_levelkurve.md` als Basis)
- EXP-Bedarf exponentiell weiterrechnen (ca. Faktor 1.5x pro Level)
- `UNLOCK_LEVELS` in `GameState.gd` für alle neuen Features vorbereiten
- Techtree: Tier-2-Gate (`req_level: 10, req_stars: 1`) bereits in `techtree.json` vorhanden – muss nur mit Content gefüllt werden
- **Abhängigkeit:** Alles andere (Techtree, Küche, Gourmetsterne) braucht definierte Level-Gates

### 1.2 Starteinstellung EXP-Boost
**Status:** ✅ Erledigt (`NewHotelModal` hat Schwierigkeitsgrade und übermittelt Multiplikatoren für EXP, Geld und Rückerstattung an Savegame).

- Im "Neues Hotel"-Dialog: Schwierigkeitsgrad wählbar
- **Casual:** +50% EXP | **Standard:** 100% | **Hard:** -25% EXP (ggf. weniger Startkapital)
- Multiplikator wird im Savegame gespeichert, beeinflusst alle EXP-Quellen global
- (`wiki/23_balancing_cash.md` enthält bereits Startkapital-Staffelung: 100k / 50k / 25k)

### 1.3 Mitarbeiter-Moralwerte aktivieren
**Status:** ✅ Erledigt (`StaffManager._process_morale` triggert jeden Mitternacht; `StaffActor.gd` rechnet bis zu 30% Strafe auf Arbeitszeit bei Moral < 50; Kündigung bei Moral <= 0).

Konzept aus `wiki/02_features/06_personal_und_aufgabensystem.md`:
- **`morale`** (0–100): Beeinflusst Arbeitsgeschwindigkeit und Fehlerrate
- **Auswirkungen:** `morale < 20` → Mitarbeiterkündigt; `morale < 50` → Arbeitsgeschwindigkeit –30%
- **Morale sinkt durch:** Überstunden / zu viele Tasks ohne Pause
- **Morale steigt durch:** Personalraum-Besuch (+5 Basis), Schulungen, regelmäßiges Gehalt
- Anzeige im Staff-Modal (Balken oder Wert)
- **Hinweis:** Personalraum-Logik (was morale.raise auslöst) kommt in Phase 3

---

## 🍳 Phase 2 – Küche & Restaurant (v0.1.42–43)
*Größtes Feature-Paket. Braucht Phase 1 (Level-Gates definiert).*

### 2.1 Szenen bauen (Workflow)
**Status:** ✅ Erledigt. `RestaurantSmall` und `KitchenSmall` sind gebaut und im Spiel. Pixel-Assets integriert.

### 2.2 Ins Spiel integrieren
**Status:** ✅ Erledigt. Erlaubte POIs eingetragen, Techtree integriert.

### 2.3 Neue Jobs
**Status:** ✅ Erledigt. Koch und Bedienung sind definiert und funktionieren im Gastronomie-Ablauf.

### 2.4 Küchen-Logik & Balancing
**Status:** ✅ Erledigt. Bestell-Queue, Köche und Bedienungen arbeiten zusammen. Gäste erhalten Essen und zahlen. Income-Kategorie "Gastro" ist im Code verankert.

---

## 🛋️ Phase 3 – Personal & Wohlbefinden (v0.1.44)
*Baut auf Moral-System aus Phase 1 auf.*

### 3.1 Personalraum (Staff Room)
**Status:** ✅ Erledigt (Szene existiert, Mitarbeiter nutzen Stühle, Tooltips und Zuweisungen funktionieren).

**Konzept:** Aus `wiki/02_features/06_personal_und_aufgabensystem.md`

- Neuer Raumtyp: Mitarbeiter wechseln in `IDLE`-State → suchen nächsten freien Personalraum
- **Slot-System:** Jeder Personalraum hat 4 Plätze ("Take the next free place")
- Mitarbeiter im Personalraum: `morale` steigt pro Minute um X
- Balancing: Wie oft / wie lang geht jemand rein? (abhängig von morale-Schwellenwert)
- **Auswirkung auf 1.3:** `morale`-Anstieg durch Personalraum erst hier vollständig implementieren

### 3.2 Tiefere Gästewerte / Gästebedürfnisse
**Status:** ✅ Erledigt (Check-In prüft Raum-Traits, UI Tooltip zeigt rot/grün Status, täglicher Zufriedenheits-Abzug greift).

Zimmer-Typen bekommen Eigenschaften (z.B. `"wlan"`, `"desk"`). Wenn Gäste einchecken, wird abgeglichen, ob das Zimmer ihre Anforderungen erfüllt. Fehlt etwas (z.B. WLAN für den Geschäftsreisenden), sinkt die Zufriedenheit und wir zeigen das im UI an. Die Basisdaten dafür (z.B. `"wlan"` beim Geschäftsreisenden) existieren bereits im Code.
- [x] **Room Hover Bug:** Moebelstuecke (speziell in Multi-Tile-Raeumen) blockieren keine Mauseingaben mehr fuer den Raum-Tooltip.
- [x] **Techtree Nodes:** Funktionale Phase-4-Nodes aus dem Demo-Lock befreit und Platzhalter entfernt.
- [x] **Techtree UI:** Tooltips zeigen nun echte Raumbeschreibungen und nutzen manuelles Word-Wrapping, um Layout-Bugs von Godot zu umgehen.
- [x] **Codex:** POI-Eintrag hinzugefügt und Tutorial-UI auf Echt-Daten-Binding umgestellt.
- [x] **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch über `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **GuestActor Teleport Fix:** Fehlerhaftes Teleportieren (Hide/Fade) von Gästen im Restaurant behoben. Das versehentliche Töten von Tweens im State-Change durch `call_deferred` unterbunden.
- [x] **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik für AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- [x] **StaffActor Bademeister Fix:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- ✅ ANG-324: Exploit-Fix – Pausenräume können nicht mehr abgerissen werden, wenn dadurch das Kapazitätslimit unter die Anzahl des eingestellten Personals fällt.
- ✅ ANG-320: Tutorial-Texte ergänzt, Räume-Kategorie im Codex hinzugefügt, Wiki-Dokumentation für Räume samt Navigation Points erstellt.
- ✅ Fix: Crash beim Laden von leeren Personalräumen.
- ✅ Fix: Lobby war nicht korrekt als Nav-Raum definiert.
- ✅ **GuestActor Wegfindung:** Bug behoben, durch den Gäste beim Verlassen des Zimmers geradewegs durch Wände liefen (Status-Machine Bug mit `previous_state` behoben).
- ✅ **CustomTooltip:** Position wird nun auf den Viewport geclempt, sodass der Tooltip nicht mehr oben aus dem Bild rutscht.
- ✅ **ANG-332:** Feature-Issue für "Weitere Parzelle" Reward im LevelUp-Screen angelegt.
- ✅ **Parzellen-Kauf-UI:** Progressbar komplett auf `ParzelleBuildUI.tscn` (Tooltip-Style) umgestellt. Inklusive 3.0-Scaling auf dem CenterContainer, um den Kamera-Zoom (0.33) exakt auszugleichen und pixel-perfect Font-Rendering zu garantieren.
- ✅ **MapGrid:** Beim Beenden des Parzellen-Kauf-Modus wird die Kamera jetzt via `center_on_entry()` zentriert (identisch zur HOME-Taste).
- ✅ **Loca-Fix:** Die fehlenden Übersetzungen (`tx.plot_buy`, `ui.confirm.plot_buy_title`, `ui.confirm.plot_buy_desc`) für den Parzellenkauf wurden in `language.csv` nachgetragen. Floating-Value-Anzeige nach Kauf integriert.
- ✅ **MapGrid-Erweiterung:** Verschmelzung der Parzellen-Grids implementiert, sodass gekaufte Parzellen zu einem großen nahtlosen Grid zusammengefügt werden (Verschiebung des Nullpunkts entfällt, Koordinaten sind global eindeutig).
- ✅ **MapGrid.tscn:** Z-Index des `FloorLayer` (Rasen) auf -2 gesetzt, damit dieser nicht mehr durch die Beton-Böden wächst.
- ✅ **Loca-Fix:** Die Kategorie `room_category.business` in `language.csv` ergänzt.
- ✅ **Techtree:** Demo-Lock für den Raum P1.2 (Konferenzraum) entfernt.
- ✅ **Codex:** Die Raum-Liste in "Tutorials & Codex" generiert sich nun dynamisch aus dem `room_registry`, statt manuell gepflegt werden zu müssen. Vorschaubilder und Tooltip-Beschreibungen werden sauber verknüpft (mit Fallbacks).
- ✅ **Bugfixes & Warnings:** Fehlerhaften Icon-Pfad für `map-pin.svg` korrigiert sowie diverse Godot-Warnungen (Integer-Division, Ternary-Kompatibilität, ungenutzte Parameter) in `MapGrid.gd` behoben.

---

## 🌳 Phase 4 – Techtree mit Leben füllen (v0.1.45)

### 4.1 Bestehende Nodes mit Inhalt versehen

Aktuell gesperrte Nodes ohne Inhalt:

| ID | Kategorie | Geplanter Inhalt |
|---|---|---|
| `G1.4` | Gastronomie | Gourmetküche (Vorstufe Gourmetsterne) |
| `W1.1` | Wellness | Spa / Massage |
| `W1.2` | Wellness | Pool / Außenbereich |
| `W1.3` | Wellness | Wellness-Paket (Kombination) |
| ~~`M1.2`~~ | ~~Management~~ | ~~Personalentwicklung (Schulungsbonus)~~ ✅ Erledigt |
| ~~`M1.3`~~ | ~~Management~~ | ~~Prozessoptimierung (Effizienz-Bonus)~~ ✅ Erledigt |
| `M1.4` | Management | Hotelleitung (Globaler Effizienz-Bonus) |
| `P1.1` | Prestige | Events (Konzerte, Messen etc.) |
| `P1.2` | Prestige | Veranstaltungszentrum |
| `P1.3` | Prestige | Prestige-Paket |
| Tier 2 | Alle | Req: Level 10 + 1 Stern – Tier-2-Nodes definieren |

- Für jeden Node: Was genau schaltet er frei? Raum? Feature? Bonus?
- Translation-Keys für alle Namen in `language.csv` nachtragen
- Level-Gates pro Node sauber definieren

---

## ⭐ Phase 5 – Events & Prestige (v0.1.46–47)

### 5.1 Zufallsereignisse
- Event-System: Zufällige Ereignisse nach Zeit/Wahrscheinlichkeit
- Beispiele: Rohrbruch, TV-Ausfall, Stromausfall, Schädlingsbefall
- Jedes Event: Dauer + Reparaturkosten + Impact auf `satisfaction` betroffener Gäste
- Benachrichtigung: Toast + Activity-Log-Eintrag + Raum-Indikator
- Spieler-Reaktion: Haustechnik schicken oder selbst bestätigen

### 5.2 Gourmetsterne
- Voraussetzung: `G1.4` (Gourmetküche) erforscht
- Bewertungs-Logik: Restaurant-Qualität (Küchen-Skills) + Ø Gästezufriedenheit über Zeit → 0–3 Sterne
- **Inspektor-Event:** Seltenes Zufallsevent (1x pro ~30 Tage). Inspektor besucht → bewertet anonym → Toast mit Ergebnis (✅ Implementiert als Inspektor-Bericht + Anonyme Spawns)
- Sterne geben Boni: +Reputation, +Einnahmen-Multiplikator Restaurant, neue Gästetypen (✅ Teilweise implementiert)

---

## 📊 Abhängigkeits-Übersicht (Schnellreferenz)

```
Phase 1: Fundament
├── 1.1 Max-Level 10          ← ZUERST (Level-Gates für alles andere)
├── 1.2 EXP-Boost Starteinstellung
└── 1.3 Morale aktivieren     ← Basis für Phase 3

Phase 2: Küche & Restaurant   ← Braucht 1.1 (Level-Gates)
├── 2.1 Szenen (Peter + Workflow)
├── 2.2 Integration + Techtree G1.2/G1.3 entsperren
├── 2.3 Neue Jobs
└── 2.4 Küchen-Logik

Phase 3: Personal & Gäste     ← Braucht 1.3 (Morale-System)
├── 3.1 Personalraum           ← Braucht 1.3 (Morale-Raise-Logik)
└── 3.2 Gästebedürfnisse       ← Requirements-Array bereits vorhanden!

Phase 4: Techtree-Content      ← Braucht 2.x (Räume müssen existieren)
└── 4.1 Alle demo_locked Nodes mit Inhalt

Phase 5: Events & Prestige     ← Braucht 4.1 (G1.4 Gourmetküche)
├── 5.1 Zufallsereignisse
└── 5.2 Gourmetsterne + Inspektor
```

---

## 🔮 Spätere Features (nach Alpha / Beta)

- **Savegames - Actor-State-Serialisierung (ANG-314):** Beim Laden eines Spielstands exakte Positionen, Pathfinding und Timer (Gäste & Staff), offene Putz-Tasks und Gastro-Bestellungen wiederherstellen, um Immersion-Breaks zu verhindern. Erst implementieren, wenn alle State-Machines feature-complete sind.
- **Rework: New Game UI (Erweiterte Spieleinstellungen / Seite 2):** Vergrößerung des Fensters (ggf. mit Tabs oder 2. Seite) um feinere Anpassungen von Startkapital, Mitarbeiter-Schwellenwerten (Pausenverhalten) und anderen Startbedingungen zu ermöglichen.
- **Personalflure:** Kommt mit Nav-Rework (3 Ebenen: Gäste / Personal / Rauminneres + feineres Grid)
- **Zoning:** Mitarbeiter-Zonen auf der Karte (im Wiki skizziert)
- **Sicherheitszentrale:** PiP-Kamera recyceln als Überwachungssystem (ab Level 20, Wiki-Konzept vorhanden)
- **Connecting Rooms:** Zimmer mit Verbindungstür (Familie-Segment)
- **Krankheits-System:** Mitarbeiter werden krank (Wiki-Konzept vorhanden)

---

## 📁 Relevante Dateien (Schnellreferenz)

| Was | Datei |
|---|---|
| Gäste-Typen & Requirements | `data/GuestDefinitions.gd` |
| Mitarbeiter-Dict (morale) | `autoload/StaffManager.gd` |
| Gäste-Werte (satisfaction, patience) | `scenes/ingame/guest/GuestParty.gd` |
| Techtree-Struktur | `config/techtree.json` |
| Level-Kurve Konzept | `wiki/22_balancing_levelkurve.md` |
| Cash-Balancing Konzept | `wiki/23_balancing_cash.md` |
| Personal-System Konzept | `wiki/02_features/06_personal_und_aufgabensystem.md` |
| Techtree-Architektur Konzept | `wiki/02_features/01_architektur_techtree_und_fp.md` |
| Raumtypen-Referenz | `wiki/02_features/22_raumtypen_referenz.md` |
