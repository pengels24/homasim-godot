# Übergabe-Protokoll – v0.1.59 (17.09.2026)

## Letzter Stand
Session beendet nach erfolgreicher Behebung eines kritischen Gastro-Bugs kurz vor dem Pre-Alpha-Release.

## Geänderte Dateien
- `scenes/ingame/guest/GuestActor.gd` – Haupt-Fixes (Pre-Claim Sitzposition, M1.4, visited_rooms)
- `scenes/ingame/guest/GuestParty.gd` – visited_rooms Serialisierung (to_dict/from_dict)
- `scenes/ingame/staff/StaffActor.gd` – Pathfinding Endlos-Loop Fix
- `autoload/StaffManager.gd` – M1.2 Schulungsbonus
- `version.txt` – v0.1.59
- `changelog/gd-0.1.59.md` – neu erstellt
- `wiki/alpha_backlog.md` – aktualisiert

## Was getestet wurde ✅
- Gym: Mehrere Gäste gleichzeitig → funktioniert
- Bar: TG-Mittagspause mit 8+ Gästen → alle bleiben sitzen (Studying Menu / Bestellung)
- Restaurant: TG-Mittagspause → alle bleiben sitzen
- StaffActor: Kein Path-Spam mehr wenn schon im Zielraum

## Sofortige nächste Schritte (für morgen)
1. **Inspektor-Events (ANG-355):** Logik für Inspector-Spawn, Report-Generierung mit `visited_rooms`-Daten
2. **Bau-Validierung (ANG-349):** Max. 1 Konferenzraum beim Bauen prüfen
3. **Abschluss-Tests** vor Pre-Alpha-Release: Kompletter Durchlauf Tag 1-4, Checkout, Inspektor

## Wichtige Architektur-Details
- `_pre_claimed_seat_pos` / `_pre_claimed_duration` in GuestActor: Werden in `_walk_to_poi()` beim Pre-Claim gesetzt, in `_on_poi_arrived()` konsumiert und danach auf INF/0 zurückgesetzt.
- `visited_rooms` in GuestParty: Dict mit room_id → `{name, reviews: [{day, cleanliness, condition, sat_delta}]}`. Einmal pro Tag & Raum beschrieben.
- Techtree M1.4: Feature-Key `"ui.techtree.feature.M1.4"` in TechtreeManager prüfen.