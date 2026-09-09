# Übergabeprotokoll – Session 09.09.2026

## 🎯 Letzter Stand

TG-Checkout-Flow (Tagungsgäste) nach 5 Root Causes vollständig repariert.  
Alle Räume im Spiel sind nun vollständig funktional.  
Zwei Event-HUD Features implementiert (Timer + Kamera-Jump).

---

## ✅ Was wurde in dieser Session erledigt?

### 1. TG-Checkout-Flow Komplett-Overhaul
5 Root Causes gefunden und behoben:

**RC1 – Two-Pass-Pattern in GuestController:**
`spawn_active_guests()` hat TG-Parties mit leerem `event_poi_id` in Lobby-Idle geworfen.
Fix: TG-Parties werden nach Loop in `tg_checkout_parties` gesammelt → danach `checkout_event_party()` aufgerufen.

**RC2 – checkout_event_party() in GuestManager:**
Neue Methode: Entfernt Party aus `_active`, setzt `state = "gone"`, emittet `sig_party_checked_out_physically` → normaler Checkout-Flow.

**RC3 – complete_checkout() setzt _current_poi_id:**
Frisch gespawnte Actors hatten `_current_poi_id = ""` → `_walk_to_exit()` ohne `current_room` → Sofort-Exit (unsichtbar).
Fix: `complete_checkout()` setzt `_current_poi_id = "lobby"` bei IDLE-Spawn.

**RC4 – ReceptionX-Waypoints statt Flur-Spawn:**
`_on_party_checked_out_physically()` nutzt jetzt `lobby.get_checkout_wait_pos(member.party_id)` → korrekte Verteilung auf 4 ReceptionX-Points.

**RC5 – Post-Essen-Guard in GuestActor:**
Nach Restaurant/Bar-Besuch gingen TG-Gäste in Lobby-Idle statt Checkout.
Fix: Guard in `_process_waiting()`: Tagung vorbei + TG-Gast + fertig gegessen → `start_checkout()` direkt.

**Bonus Fix:**
Lobby Live Monitor filtert LEAVING-State Actors aus `get_live_details()` → Tooltip=0 / Live Monitor=0 konsistent.

### 2. Event-HUD Features
- `event_name_label` zeigt Restzeit: "Marketingkonferenz (1h30m)" / "...  (45min)"
- Klick auf Event-Indikator → Kamera-Jump zum Tagungsraum (Tween 0.4s, Zoom 4)
  - **NOCH NICHT GETESTET** – erst wenn nächstes Tagungsevent startet prüfen ob EventIndicator ein Control-Node ist

---

## 📁 Geänderte Dateien

| Datei | Was |
|---|---|
| `scenes/ingame/GuestManager.gd` | `checkout_event_party()` neu |
| `scenes/ingame/guest/GuestController.gd` | Two-Pass, ReceptionX-Spawn |
| `scenes/ingame/guest/GuestActor.gd` | `complete_checkout()` lobby-poi-id, Post-Essen-Guard |
| `scenes/ingame/rooms/lobby/Lobby.gd` | LEAVING-State aus Live Monitor gefiltert |
| `scenes/ingame/hud/HUD.gd` | Event-Timer + Kamera-Jump |
| `wiki/alpha_backlog.md` | Session-Fixes eingetragen |
| `wiki/status_quo.md` | Konferenzraum als fertig markiert, TG + Event-HUD ergänzt |
| `changelog/gd-0.1.50.md` | Session-Changelog erstellt |

---

## ⚠️ Offene Punkte / Nächste Schritte

1. **Event-HUD Kamera-Jump testen** – beim nächsten Tagungsevent: Klick auf Event-Indikator → Kamera springt? Falls nicht → EventIndicator ist kein Control-Node → in HUD.tscn anpassen
2. **ANG-343: StaffActor Smart-Room-Unification** – Medium Prio, vor neuem Staff-Raum
3. **Autosave Setting Bug** – Autosave triggert obwohl disabled (noch nicht behoben)
4. **Visual Bug** – Gäste/Speaker schauen nicht korrekt zum Tisch (Look Direction)
5. **Live Monitor Bug** – Zeigt falsche Destinations für Bar/Restaurant Gäste

---

## 🏁 Meilenstein

**Alle Räume vollständig funktional:**  
Lobby, Zimmer, Küche, Restaurant, Bar, Pool, Gym, Spa, Personalraum, Konferenzraum  
→ Das Spiel ist bereit für Alpha-Content-Erweiterungen (neue Räume, Tier 2 Techtree, Gourmetsterne etc.)
