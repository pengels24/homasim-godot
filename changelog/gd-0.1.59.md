# Changelog – v0.1.59
> Datum: 17.09.2026 | Branch: `dev`

## 🐛 Bugfixes

- **[KRITISCH] GuestActor – TG-Gäste verließen Bar/Restaurant sofort bei Mittagspause**
  - Root-Cause: `_walk_to_poi()` reservierte beim Losgehen bereits einen Sitzplatz via `claim_interaction`, speicherte aber die Sitzposition und Aufenthaltsdauer nicht. In `_on_poi_arrived()` wurde dadurch `seat_pos = global_position` (Eingang) statt des echten Barhockers verwendet → Gast "saß" bei Ankunft am Eingang, Timer lief sofort ab, Gast verließ den POI.
  - Fix: Neue Variablen `_pre_claimed_seat_pos: Vector2` und `_pre_claimed_duration: float` in `GuestActor.gd`. Werden beim Pre-Claim in `_walk_to_poi()` befüllt und in `_on_poi_arrived()` direkt verwendet. Kein Release/Re-Claim → kein Race-Condition-Problem bei Gruppen.
  - Betrifft: `scenes/ingame/guest/GuestActor.gd`

- **StaffActor – Endlos-Loop "Path failed to target_room"**
  - Wenn Staff bereits im Zielraum stand, wurde `get_path_between_tiles(A, A)` aufgerufen → leerer Pfad → Task wurde verworfen und sofort erneut gestartet → Endlos-Spam im Log.
  - Fix: Wenn `start_tile == end_tile`, wird ein Dummy-Pfad `[end_tile]` zurückgegeben. Staff meldet sofort "angekommen" und beginnt die Arbeit.
  - Betrifft: `scenes/ingame/staff/StaffActor.gd`

## ✨ Features / Verbesserungen

- **Techtree M1.2 – Schulungsbonus:** Staff erhält nach Schulung +10% Arbeitsqualität-Multiplikator (in `StaffManager.gd`).
- **Techtree M1.3 – Effizienz:** Alle Angestellten bewegen sich nach Unlock um +15% schneller (`StaffActor.gd`, `_base_speed`).
- **Techtree M1.4 – Hotelleitung:**
  - Ankunftsgeduld für alle neuen Gäste +20% (in `GuestManager.gd`).
  - Allgemeiner Gedulds-Drain um -20% reduziert (in `GuestActor.gd`, `_process_impatient`).

- **ANG-354 – Raum-Bewertungshistorie (visited_rooms):**
  - `GuestParty.visited_rooms` speichert pro Raum und Tag: Sauberkeit, Zustand, Zufriedenheits-Penalty.
  - Einmalige Bewertung pro Tag, Raum und Party (kein Doppel-Penalty).
  - Wird in `GuestParty.to_dict()` / `from_dict()` serialisiert → bleibt über Saves hinweg erhalten.
  - Basis für spätere Inspektor-Berichtslogik.

## 🔧 Technisch / Intern

- Debug-Print `[GuestActor][DEBUG]` aus `_on_poi_arrived()` wieder entfernt (war nur für Fehlersuche).

- **[KRITISCH] Parzellen-Bau-Timer Bug (Savegame)**
  - Root-Cause: Timer von Parzellen blieben beim Laden eines Savegames fälschlicherweise bei 720 Minuten hängen. Zudem wurden die Wände nach Bauende nicht korrekt rekonfiguriert, wodurch sie visuell im Weg standen.
  - Fix: Runtime-Check in Parzelle.gd::_process hinzugefügt, der korrupte Timer (>= 720) erkennt und den Status auf gebaut setzt. Zudem wird _configure_walls() nach Abschluss nun zuverlässig aufgerufen.
  - Betrifft: scenes/ingame/map/Parzelle.gd

- **Toast-Translation Bug (Gast wütend abgereist)**
  - Root-Cause: Hardcodierter String im Code für Timeout-Toasts.
  - Fix: Der Toast für wütend abreisende Gäste greift nun auf GameState.T("toast.guest.angry_leave") zu. In der language.csv wurden die Platzhalter von %d auf %s korrigiert.
  - Betrifft: scenes/ingame/GuestManager.gd, 	ranslations/language.csv

## ✨ Features / Verbesserungen

- **Animiertes Bau-Overlay (Parzellen)**
  - Implementierung eines neuen Custom-Shaders (construction_hatch.gdshader), der auf zu bauenden Parzellen ein 50% transparentes, orangefarbenes Schraffurmuster ("Hazard Stripes") projiziert, das sich sanft bewegt. Das Muster lässt einen 10px Rand ringsrum, wie vom Design gefordert.
  - Betrifft: scenes/ingame/map/Parzelle.gd, ssets/shaders/construction_hatch.gdshader
