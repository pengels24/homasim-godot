# Changelog – gd-0.1.51 (laufend)

> Branch: `dev` | Stand: offen

---

## 🐛 Bugfixes

- **ANG-340: [Space] kollabierte fokussierten Live-Monitor:** `BtnCollapse`, `BtnClose` und `ColorPickerButton` in `RoomDetailsMonitor.tscn` hatten kein `focus_mode = 0`. Nach dem Klick behielten sie den Keyboard-Focus → Space triggerte den Button statt die Spielsteuerung. Fix: `focus_mode = FOCUS_NONE` auf allen 3 Header-Buttons.
- **Bademeister schaut nicht zum Pool (Hochsitz):** `claim_interaction` in `PoolSmall.gd` überschrieben. `look_at_dir` wird jetzt als Winkel von Stuhl → `get_service_position()` (Pool-Mitte) berechnet statt Stuhl-Eigenrotation zu verwenden.

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
| | |
