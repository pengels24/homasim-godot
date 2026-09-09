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
