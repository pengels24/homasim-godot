# Changelog – gd-0.1.50 (09.09.2026)

> Session: TG-Checkout-Flow Overhaul + Event-HUD Features
> Branch: `dev`

---

## 🐛 Bugfixes

### TG-Checkout nach Autosave/Reload (Komplett-Overhaul)

**Problem:** Tagungsgäste (TG) blieben nach Konferenzende in der Lobby hängen oder waren unsichtbar.

**Root Causes & Fixes:**

- **Root Cause 1:** In `GuestController.spawn_active_guests()` wurden TG-Gäste mit leerem `event_poi_id` in Lobby-Idle-Loop geworfen.
  - **Fix:** Two-Pass-Pattern – TG-Parties werden NACH dem Loop via `GuestManager.checkout_event_party()` ausgecheckt.

- **Root Cause 2:** `GuestManager` kannte keinen Event-Party-Checkout – Party blieb als Zombie in `_active`.
  - **Fix:** Neue Methode `GuestManager.checkout_event_party()` – entfernt aus `_active`, setzt `state = "gone"`, emittet `sig_party_checked_out_physically`.

- **Root Cause 3:** Neu gespawnte Actors hatten `_current_poi_id = ""` → `_walk_to_exit()` fand keinen `current_room` → Sofort-Exit (unsichtbar).
  - **Fix:** `GuestActor.complete_checkout()` setzt `_current_poi_id = "lobby"` beim Reload-Spawn.

- **Root Cause 4:** Spawn am generischen `_get_lobby_spawn_pos()` → Alle TG stacken auf dem Flur.
  - **Fix:** `_on_party_checked_out_physically()` nutzt `lobby.get_checkout_wait_pos(member.party_id)` → 4 ReceptionX-Waypoints.

- **Root Cause 5:** Post-Essen-Guard fehlte → TG-Gäste gingen nach Restaurant in Lobby-Idle statt Checkout.
  - **Fix:** Guard in `GuestActor._process_waiting()`: TG fertig gegessen + Tagung vorbei → `start_checkout()` direkt.

### Lobby Live Monitor Konsistenz
- **Problem:** Tooltip zeigte 0, Live Monitor 12 TG-Gäste (LEAVING-State) – verwirrend.
- **Fix:** `Lobby.gd` filtert LEAVING-State aus `get_live_details()` (wie WALKING bereits gefiltert).

---

## ✨ Neue Features

### Event-HUD: Tagungsrestzeit
- `event_name_label` zeigt Countdown bis Sessionsende (Morgen: bis 12:00, Nachmittag: bis 17:00).
- Format: `Marketingkonferenz (1h30m)` bzw. `Marketingkonferenz (45min)`

### Event-HUD: Klick zum Tagungsraum
- Klick auf Event-Indikator → Kamera fliegt smooth (Tween 0.4s SINE, Zoom 4) zum Tagungsraum.
- Raum-Matching via `GuestManager._room_key()` + `EventManager.active_conferences`
- Wie F4-Raumliste "Gehe zu Raum". Erfordert EventIndicator als Control-Node.

---

## 📁 Geänderte Dateien

| Datei | Änderung |
|---|---|
| `scenes/ingame/GuestManager.gd` | `checkout_event_party()` neu |
| `scenes/ingame/guest/GuestController.gd` | Two-Pass, ReceptionX-Spawn |
| `scenes/ingame/guest/GuestActor.gd` | `complete_checkout()` lobby-poi-id, Post-Essen-Guard |
| `scenes/ingame/rooms/lobby/Lobby.gd` | LEAVING-State aus Live Monitor gefiltert |
| `scenes/ingame/hud/HUD.gd` | Event-Timer + Kamera-Jump |

---

# Session 2 – 10.09.2026

> Autosave-Fix, HUD-Timer-Fix, Guest-Status-Refactoring, Gästeliste UI-Overhaul

---

## 🐛 Bugfixes

### Autosave – Option „Aus" fehlte (SettingsManager.gd)
- **Problem:** Autosave-Optionsfeld zeigte 5 / 10 / 15 Min, aber kein „Aus". Index 0 war ohne Wert.
- **Fix:** `SettingsManager.gd` – Fehlenden Wert `0` als ersten Eintrag ergänzt; Index ist jetzt 0-basiert korrekt ausgerichtet.

### HUD Timer – `max()` Type-Inference-Fehler (HUD.gd)
- **Problem:** Godot 4 `max()` konnte Rückgabetyp nicht inferieren → Laufzeit-Fehler beim Timer-Display.
- **Fix:** `max()` durch `maxi()` + explizit typisierte Variablen ersetzt.

---

## ✨ Neue Features / Verbesserungen

### GuestActor – `get_status_text()` (Single Source of Truth)
- **Ziel:** Skalierbarkeit – neue States oder Räume nur noch an einem Ort eintragen, nie in UI-Klassen.
- Neue Methode `GuestActor.get_status_text() -> String` mit vollständigem `match current_state:` für alle 12 States.
- **WALKING:** Zeigt Ziel-Raumnummer: `"Unterwegs (Z0005)"` – kürzer und eindeutig auch bei mehreren Räumen gleichen Typs.
- **IN_POI-Gruppe:** Kein `"in "` Präfix mehr. Koordinaten-Fallback-Keys (enthalten `_`) werden unterdrückt.
- **vending_machine:** Sonderfall – zeigt `GameState.T("poi.vending_machine")` = „Snack-Automat" statt englischem Fallback.
- **IN_ROOM/SITTING/SLEEPING:** Zeigt jetzt auch Raumnummer (z.B. `"Doppelzimmer Z0005"`).

### Gästeliste (F3) – UI-Overhaul
- **Konsistente Spaltenbreiten:** Header und Datenzeilen nutzen identische `size_flags_stretch_ratio` → keine Verschiebungen mehr.
- **Ausrichtung:** Textspalten (Name, Raum, Status) linksbündig. Wertspalten (Budget, Sättigung, Zufr.) rechtsbündig – Header und Zeilen.
- **Overflow:** `clip_text = true` + `OVERRUN_TRIM_ELLIPSIS` auf Status-Spalte → elegantes „..." statt harter Abschnitt.
- **Hover-Tooltip:** Bei abgekürztem Status vollständiger Text als Tooltip (wird sekündlich synchron mit Label aktualisiert).
- **Status-Spalte breiter:** `stretch_ratio` 1.5 → 2.0 für mehr Platz.
- **Header-Umbenennung:** „Zimmer" → „Raum" (DE) / „Room" (EN); „Status" → „Status / Raum".
- **Kein float:** `energy_val` und `sat` konsequent als `int` typisiert; `int()`-Casts entfernt.
- **`ModalContentGuestList.gd`:** ~120 Zeilen duplizierter State-Checking-Code durch 3 Zeilen `actor.get_status_text()` ersetzt.

---

## 📁 Geänderte Dateien (Session 2)

| Datei | Änderung |
|---|---|
| `autoload/SettingsManager.gd` | Autosave Index-Offset-Fix |
| `scenes/ingame/hud/HUD.gd` | `maxi()` Type-Fix |
| `scenes/ingame/guest/GuestActor.gd` | `get_status_text()` neu, WALKING/IN_POI/IN_ROOM Formatierung |
| `scenes/ingame/hud/modals/content/ModalContentGuestList.gd` | Status via `get_status_text()`, Ausrichtung, clip_text, Tooltip, int statt float |
| `scenes/ingame/hud/modals/content/ModalContentGuestList.tscn` | Header-Ratios, Ausrichtung Budget/Sättigung/Zufr. |
| `translations/language.csv` | „Zimmer"→„Raum", „Status"→„Status / Raum", `poi.vending_machine` neu |
