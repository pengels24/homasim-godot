# Übergabe-Protokoll – v0.1.62 (19.09.2026, Abend-Nachtrag)

## Letzter Stand

Session abgeschlossen. Branch `dev`. Zwei Commits:
- `b670cef` – ANG-365 Hauptarbeit
- `09bc6e5` – TG PM-Trigger Fix + Backlog-Cleanup

## Zusätzlich in Abendsession erledigt

- **TG PM-Trigger Fix:** `GuestActor._decide_next_action()` Z. 811: `825 → 800` (13:45 → 13:20). TG-Gäste gehen jetzt pünktlich zur Nachmittags-Session.
- **Conference POI Hide:** Bereits implementiert in `_get_open_pois()` – kein Fix nötig, Backlog-Eintrag war veraltet.
- **EXP-Kurven-Analyse:** Simulation zeigt ~2.9h für L1→L8 (inkl. POI/Quest/Task EXP). Aktuelle Kurve ist OK – kein Anpassungsbedarf.
- **Test-Review erweitert:** TG-Ende Flow + Gym als `[~]` Beobachtungspunkte eingetragen.

## Bearbeitete Systeme

### ANG-365: UNLOCK_LEVELS komplett entfernt
- `GameState.gd`: Konstante `UNLOCK_LEVELS` entfernt. Nur `MAX_HOTEL_LEVEL = 10` bleibt.
- `HUD.gd`: Dynamische Abfragen via `TechtreeManager.tiers_config` (Tier-Gate) und Literale.
- `IngameUIManager.gd` (Z. 727, 750): Literale 2 und 3 mit Kommentar-Referenz.
- `RoomContextMenu.gd` (Z. 74, 229): Literal `2` für Staff-Level.
- `GuestManager.gd` (Z. 323, 1043) + `Room.gd` (Z. 588, 602): `auto_staff` als Literal `100` (TODO: Tier-2-Feature).

### req_level in Raum-Definitionen
Alle Raum-GD-Files haben `req_level` in `get_data()`:
- `BedFamily` → 6, `BedSuperior` → 5
- `KitchenSmall` / `RestaurantSmall` → 4
- `PoolSmall` / `SpaSmall` → 6
- `GymSmall` → 8, `ConferenceSmall` → 6

### techtree.json
- `req_level` für alle Tier-1-Nodes gesetzt (Z1.1–Z1.5, G1.1–G1.4, W1.1–W1.4, M1.1–M1.4, P1.1–P1.3)
- W1.4 Dependencies korrigiert: `["W1.1", "W1.2"]`
- Zimmer-Nodes umbenannt nach Unlock-Reihenfolge:
  - Z1.3 → Z1.2 (Superior, L5), Z1.4 → Z1.3 (WLAN, L5), Z1.5 → Z1.4 (Klima, L5), Z1.2 → Z1.5 (Family, L6)
- Zimmer col/row-Layout auf 4 Spalten angepasst:
  - col=0: Z1.1, col=1: Z1.2, col=2: Z1.3+Z1.4, col=3: Z1.5

### Techtree UI (ModalContentTechtree.gd + TechNodeButton.gd)
- Rendering-Bug gefixt: `await get_tree().process_frame` + `update_button_states()` nach `_build_ui()` in `_ready()`
- `_update_single_button()`: Kein permanenter Glow mehr für unlocked Nodes (`set_glow_state(false, ...)` für alle States). Nur Font-Color differenziert Zustände.
- `_generate_tooltip()`: `req_level = max(tier_gate_level, node_req_level)` – zeigt korrekte Level-Anforderung pro Node.

### Sonstiges
- `quests.json`, `language.csv` – Z1.2–Z1.5 IDs und Keys aktualisiert (atomic rename via Python-Script)
- `wiki/02_features/01_architektur_techtree_und_fp.md` – auf v0.1.62 aktualisiert

## Sofortige nächste Schritte

1. **Techtree Layout** – Die anderen Kategorien (Gastro, Wellness etc.) sind layout-mäßig OK. Falls der User weitere col/row-Anpassungen wünscht, nur in `techtree.json`.
2. **EXP-Kurven-Anpassung** – Noch offen: Kalibrierung der EXP-Kurve für 2–3 Stunden Spielzeit (aktuell dauert es zu lang oder zu kurz bis Level 8).
3. **Conference POI / TG Pre-Trigger** – Zwei offene Punkte aus dem Alpha-Backlog:
   - Conference POI aus `_get_open_pois()` für normale Gäste ausblenden wenn Event läuft
   - TG Pre-Trigger bei 13:20 fehlt (Gäste kommen 7 Min zu spät)
4. **GuestActor.gd** – Nach aktuellen Bugfixes: Techdoku aktuell? Ggf. nachfragen.

## Offene Punkte (nicht blockierend)

- `wiki/rooms/bed_family.md` und `wiki/rooms/bed_superior.md` zeigen noch alte Z1.2/Z1.3 IDs → kosmetisch, nicht kritisch
- `room_tutorial_draft.md` hat noch alte Refs → kosmetisch
- `_dev/GDD.md` hat noch alte Zimmer-Nummern → kosmetisch