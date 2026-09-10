# Changelog – gd-0.1.50 (09.–10.09.2026)

> Branch: `dev` | Umfang: TG-Checkout-Overhaul, Event-HUD, Autosave-Fix, Gästeliste UI

---

## 🐛 Bugfixes

- **TG-Checkout nach Autosave/Reload:** Tagungsgäste blieben nach Konferenzende in der Lobby hängen oder exiteten unsichtbar. Komplett-Overhaul: Two-Pass-Pattern in `GuestController`, neue Methode `GuestManager.checkout_event_party()`, `_current_poi_id = "lobby"` beim Reload-Spawn gesetzt, Spawn an ReceptionX-Waypoints statt generischem Lobby-Pos, Post-Essen-Guard zum direkten Checkout.
- **Lobby Live Monitor:** LEAVING-State in `get_live_details()` gefiltert – Tooltip (0) und Live-Monitor jetzt konsistent.
- **Autosave – Option „Aus" fehlte:** `SettingsManager.gd` Index-Offset korrigiert; Option `0 Min` (Aus) fehlte als erster Eintrag.
- **HUD Timer – `max()` Type-Inference:** `max()` durch `maxi()` + typisierte Variablen ersetzt (Godot 4 Strict-Mode).

---

## ✨ Features & Verbesserungen

### Event-HUD
- `event_name_label` zeigt Countdown bis Sessionsende: `"Marketingkonferenz (1h30m)"` / `"(45min)"`
- Klick auf Event-Indikator → Kamera fliegt smooth (Tween 0.4s SINE, Zoom 4) zum aktiven Tagungsraum.

### GuestActor – `get_status_text()` (Single Source of Truth)
- Neue zentrale Methode für alle 12 States. UI-Klassen fragen nur noch `actor.get_status_text()` – kein State-Checking mehr in Modals.
- **WALKING:** `"Unterwegs (Z0005)"` – Ziel-Raumnummer direkt, ohne Typname.
- **POI-Räume:** Kein `"in "` Präfix. Koordinaten-Fallback-Keys (`type_x_y`) werden unterdrückt.
- **Snack-Automat:** Sonderfall `vending_machine` → `"Snack-Automat"` (DE) / `"Vending Machine"` (EN).
- **Zimmer:** `"Doppelzimmer Z0005"` mit Raumnummer.

### Gästeliste (F3) – UI-Overhaul
- Konsistente Spaltenbreiten: Header und Zeilen mit identischen `stretch_ratio`-Werten.
- Textspalten linksbündig (Name, Raum, Status), Wertspalten rechtsbündig (Budget, Sättigung, Zufr.).
- Status-Spalte: `clip_text` + `OVERRUN_TRIM_ELLIPSIS` + Hover-Tooltip mit vollem Text (sekündlich synchron).
- Spalte „Zimmer" → **„Raum"**, Spalte „Status" → **„Status / Raum"**.
- `float` → `int` für alle Needs-Werte (Sättigung, Zufriedenheit).
- ~120 Zeilen duplizierter State-Checking-Code → 3 Zeilen `actor.get_status_text()`.

---

## 📁 Geänderte Dateien

| Datei | Änderung |
|---|---|
| `autoload/SettingsManager.gd` | Autosave Index-Offset-Fix |
| `scenes/ingame/GuestManager.gd` | `checkout_event_party()` neu |
| `scenes/ingame/guest/GuestController.gd` | Two-Pass, ReceptionX-Spawn |
| `scenes/ingame/guest/GuestActor.gd` | `complete_checkout()`, Post-Essen-Guard, `get_status_text()` neu |
| `scenes/ingame/rooms/lobby/Lobby.gd` | LEAVING-State aus Live Monitor gefiltert |
| `scenes/ingame/hud/HUD.gd` | Event-Timer, Kamera-Jump, `maxi()` Fix |
| `scenes/ingame/hud/modals/content/ModalContentGuestList.gd` | `get_status_text()`, Ausrichtung, Clip, Tooltip, int |
| `scenes/ingame/hud/modals/content/ModalContentGuestList.tscn` | Header-Ratios, Spaltenausrichtung |
| `translations/language.csv` | „Zimmer"→„Raum", „Status"→„Status / Raum", `poi.vending_machine` |
| `wiki/02_features/25_techdoku_guestactor.md` | `get_status_text()` dokumentiert, States vollständig |
