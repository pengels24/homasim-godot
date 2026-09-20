# Übergabe – Session 20.09.2026 (v0.1.63)

## Letzter Stand

Session fokussiert auf **Ghost-Room Blocking Bug** nach Abriss + POI-Kapazitäts-Fixes.

## Was wurde gemacht

1. **max_count:1 für alle POIs** (Gym, Pool, Spa, Bar, Restaurant, Küche) – Pre-Alpha Workaround für ANG-366 (Architektur-Schuld: POI-IDs sind nicht instanzspezifisch).
2. **Queue-Free-Save-Bug gefixt** (`MapGrid.remove_room`): `remove_child()` vor `queue_free()` → Ghost-Rooms werden nicht mehr ins Save geschrieben.
3. **_sanitize_restored_rooms()** in `MapGrid.gd`: Läuft beim Load, entfernt überzählige max_count:1-Rooms.
4. **rebuild_occ_from_active_rooms()** in `MapGrid.gd`: Nuklear-OCC-Repair. DevConsole: `repair-grid`.
5. **occ-overlay DevConsole**: Zeigt OCC-Werte auf der Map. Early-Return-Bug in `_draw()` erst am Ende der Session entdeckt und gefixt.

## Offene Probleme (sofort angehen!)

### 🔴 PRIO 1: Ghost-Room Blocking (noch nicht gelöst!)
- User kann an der Stelle wo Gym abgerissen wurde nicht bauen
- `repair-grid` + Reload halfen NICHT (mit altem Code)
- `occ-overlay` hatte Early-Return-Bug (`if not _show_debug_grid: return`) → war blind
- **v0.1.63 Fix:** Early-Return auf `and not _show_occ_overlay` erweitert
- **Nächster Schritt:** Game neu starten → `occ-overlay` aktivieren → Screenshot zeigt exakte OCC-Werte am Blocking-Ort
- Wenn `repair-grid` danach immer noch nicht hilft: OCC-Screenshot analysieren

### 🔴 PRIO 2: HUD Event-Panel bleibt 2-zeilig
- Nach Tagungsende zeigt das Panel noch 2 Zeilen statt 1
- Noch nicht angefangen

## Dateien geändert (diese Session)
- `scenes/ingame/map/MapGrid.gd` – remove_room fix, _sanitize, rebuild_occ, occ-overlay
- `autoload/DevConsole.gd` – repair-grid + occ-overlay Befehle
- `scenes/ingame/rooms/gym_small/GymSmall.gd` (+ Spa, Pool, Bar, Restaurant, Kitchen) – max_count:1
- `version.txt` – v0.1.63
- `changelog/gd-0.1.63.md` – neu
- `wiki/alpha_backlog.md` – aktualisiert
- `wiki/04_maintenance/mapgrid_occ_system.md` – neu