# Changelog – v0.1.62
> Branch: `dev` | Datum: 19.09.2026

## 🧹 Refactoring / Cleanup (ANG-365)

### `UNLOCK_LEVELS` vollständig entfernt
- `GameState.gd`: Konstante `UNLOCK_LEVELS` entfernt. `MAX_HOTEL_LEVEL = 10` bleibt erhalten.
- `HUD.gd`: Dynamische `req_level`-Abfragen aus `StaffSmall.req_level` und `TechtreeManager.tiers_config` (Tier-1-Gate).
- `IngameUIManager.gd`: `open_staff()` und `open_tech_tree()` lesen jetzt Literale (2 bzw. 3) mit Kommentar-Referenz.
- `RoomContextMenu.gd`: Service- und Reparatur-Button prüfen `< 2` statt `UNLOCK_LEVELS.get("staff", 2)`.
- `GuestManager.gd` + `Room.gd`: `auto_staff` auf Literal `100` gesetzt (TODO: Tier-2-Feature).

### `req_level` in Raum-Definitionen
Alle Raum-GD-Dateien haben nun ihr `req_level` direkt in der `get_data()`-Methode:
- `BedFamily` → 6, `BedSuperior` → 5
- `KitchenSmall` / `RestaurantSmall` → 4
- `PoolSmall` / `SpaSmall` → 6
- `GymSmall` → 8, `ConferenceSmall` → 6

### `techtree.json`: req_level für alle Tier-1-Nodes gesetzt
13 Nodes erhalten `req_level`-Werte passend zur Level-1–8-Progression.
W1.4-Dependencies auf `["W1.1", "W1.2"]` korrigiert.

---

## 🐛 Bugfixes

### Techtree UI: Rendering-Bug beim Öffnen (Init-State)
- `ModalContentTechtree._ready()`: `await get_tree().process_frame` + `update_button_states()` nach `_build_ui()` eingefügt.
- Buttons zeigen beim Öffnen nun sofort den korrekten Zustand (kein Glow = kein permanenter Border-Effekt), identisch zum Zustand nach dem ersten Hover.

### Techtree Tooltip: req_level zeigte immer Tier-Gate-Level (3)
- `_generate_tooltip()` las nur `tiers_config.gate.req_level` → zeigte immer „Hotel Level 3".
- Fix: `max(tier_gate_level, node_req_level)` → Nodes zeigen nun ihren tatsächlichen Level-Bedarf (z.B. G1.4 → Level 7, W1.4 → Level 8).

---

## 🔁 Umbenennungen (Zimmer Techtree-Nodes)

IDs wurden nach tatsächlicher Unlock-Reihenfolge neu nummeriert:

| Alt | Neu | Name | Level |
|-----|-----|------|-------|
| Z1.3 | **Z1.2** | Superior Rooms | 5 |
| Z1.4 | **Z1.3** | WLAN (Internet) | 5 |
| Z1.5 | **Z1.4** | Air Conditioning | 5 |
| Z1.2 | **Z1.5** | Family Rooms | 6 |

Alle Referenzen aktualisiert: `techtree.json`, `quests.json`, `RoomContextMenu.gd`, `Room.gd`, `BedFamily.gd`, `BedSuperior.gd`, `language.csv`.

---

## 🎨 UI / Layout

### Techtree Zimmer-Row: 4-Spalten-Layout
- `techtree.json` col/row für Zimmer-Nodes angepasst:
  - col=0: Z1.1 (L3)
  - col=1: Z1.2 Superior (L5)
  - col=2: Z1.3 WLAN + Z1.4 Klima (beide L5)
  - col=3: Z1.5 Family (L6)
- Modal passt sich automatisch an (kein TSCN-Edit nötig).
