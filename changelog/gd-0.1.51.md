# Changelog – gd-0.1.51 (laufend)

> Branch: `dev` | Stand: offen

---

## 🐛 Bugfixes

- **ANG-340: [Space] kollabierte fokussierten Live-Monitor:** `BtnCollapse`, `BtnClose` und `ColorPickerButton` in `RoomDetailsMonitor.tscn` hatten kein `focus_mode = 0`. Nach dem Klick behielten sie den Keyboard-Focus → Space triggerte den Button statt die Spielsteuerung. Fix: `focus_mode = FOCUS_NONE` auf allen 3 Header-Buttons.
- **Bademeister Blickrichtung (Hochsitz):** `claim_interaction` in `PoolSmall.gd` überschrieben. `look_at_dir` wird als Winkel von Hochsitz → `Chair4`-Position (Pool-Mitte) berechnet. Korrekt typisiert (`Vector2` statt Variant-Inference).
- **Bademeister Rotation nach Ankunft / Rückkehr:** `Room.gd` `get_available_staff_interactions` gibt jetzt auch den eigenen bereits belegten Platz zurück. `claim_interaction` für `staff_seat_` erlaubt Re-Claim durch denselben Actor. Chair-Entscheidungslogik in `StaffActor.gd` auf Pfad-Verfügbarkeit umgestellt: `lp.size() > 0` → laufen, sonst → Rotation setzen. Threshold 8.0px (2 Grid-Zellen à 4px) für Nav-Snap-Robustheit.
- **Godot Parse-Fehler (Variant-Inference):** Alle `.call()`-Rückgaben explizit typisiert (`Dictionary`, `Vector2`).

---

## ✨ Features & Verbesserungen

- **ANG-343: StaffActor Smart-Room-Unification:** 3 hardcodierte `get_job_type()`-Checks durch generische Room-API ersetzt.
  - Bartender-Block (Dead Code, ~22 Zeilen) entfernt – `Bar.gd` implementiert `get_work_position()` + `get_work_look_dir()` bereits.
  - Lifeguard-Guard von `get_job_type() == "lifeguard"` auf `has_method("get_available_staff_interactions")` umgestellt.
  - Waiter-Wander-Center nutzt jetzt `room.get_work_position()` statt `get_waiter_stand_pos()` direkt.

---

## 📁 Geänderte Dateien

| Datei | Änderung |
|---|---|
| `scenes/ingame/staff/StaffActor.gd` | ANG-343 Refactoring, Bademeister-Logik (Pfad-basiert), Typ-Fixes |
| `scenes/ingame/rooms/Room.gd` | `get_available_staff_interactions` + `claim_interaction` Re-Claim-Support |
| `scenes/ingame/rooms/pool_small/PoolSmall.gd` | `claim_interaction` Override für Bademeister-Blickrichtung (Chair4) |
| `scenes/ingame/hud/modals/RoomDetailsMonitor.tscn` | ANG-340: `focus_mode = FOCUS_NONE` auf Header-Buttons |
