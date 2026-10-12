# ANG-364 – Nav-System Komplett-Rework (Post-Alpha)
> Status: Backlog | Priorität: Hoch | Ziel: nach v0.1 stable
> ⚠️ **TEILWEISE ÜBERHOLT (12.10.2026):** Verbindlich ist `alpha_grid_rework_plan.md`. Abweichungen: Bau-Raster bleibt 16 px (kein freies 4-px-Bausystem), Speichern über Raum-ID + Slot-ID statt `tile_id`, kein `v3_`-Ordner, Start im Alpha-Anfang statt Post-Alpha.

---

## Problem-Analyse (Session 19.09.2026)

### Problem 1: Zwei Nav-Systeme mit unterschiedlichen Skalen
Das aktuelle System nutzt **zwei getrennte Navigation-Systeme**:
- **Global-Nav:** 16×16 AStar-Grid auf Parzellen-Ebene (Flure/Korridore)
- **InRoom-Nav:** 4×4 Pixel-Grid für Raum-Innennavigation

**Symptome:**
- Jeder Übergang (Raum-Tür = "wo endet Global, wo beginnt InRoom") ist fehleranfällig
- Falscher `previous_state` beim Restore → `_get_current_room_node()` gibt null zurück → Phase 1 von `_execute_walk()` generiert keinen lokalen Austrittspfad → Luftlinie durch Wände
- Koordinaten-Konversion (`world_to_tile()` / `tile_to_world()`) akkumuliert Rundungsfehler
- `get_target_tile()`, `get_door_world_inside()`, `get_local_path()` sind fragile Brücken zwischen den Systemen

**Pragmatischer Fix (v0.1.60):** `_current_poi_id` nach Restore nicht leeren → `_get_current_room_node()` findet Raum → Phase 1 generiert korrekten Austrittspfad.

### Problem 2: Berechnete statt deklarierter Positionen
Gast-Positionen werden als `pos_x / pos_y` (Welt-Koordinaten) gespeichert. Beim Restore:
- `pos_x/pos_y` laden → in Tile umrechnen → auf `is_point_solid` prüfen → ggf. teleportieren
- Rundungsfehler in dieser Kette können Gäste auf den falschen Tile setzen → unerwartetes Verhalten

---

## Architektur-Ziel: Unified 4×4 Grid

### Konzept (von Peter, 19.09.2026)
**Ein einheitliches 4×4 Tile-System** für die gesamte Map:

```
5×5 Parzellen × 16 Tiles × 4 Pixel = 80×80 Tiles gesamt = 6.400 Tiles
Jeder Tile: 4×4 Pixel | Nummerierung: 0–6399 (tile_id)
```

**Vorteile:**
- Kein Systemwechsel mehr – Räume und Korridore im gleichen Grid
- Keine Koordinaten-Konversion
- Nahtloser Übergang: wo vorher freie Fläche war, ist jetzt ein Tisch/Blocker/NavWall – alles im gleichen Raster
- Gäste und Staff speichern einfach `tile_id: 4673` statt `pos_x/pos_y` → deterministisch, kein Rundungsfehler
- **Bonus für den Spieler:** Flexibler Flurbau – nicht mehr zwingend 16 Tiles breit. 4, 8, 12, 20-breite Gänge möglich → feinere Hotelplanung

**Tile States:**
```
NOT_OWNED | NOT_BUILT | BUILT_FREE | BUILT_OCCUPIED | BLOCKED | WALL | DOOR
```

### Kompatibilität der Assets
- Raum-Sprites sind bereits auf 4×4 Pixel-Grid gepixelt ✅
- Raumgrößen sind Vielfache von 16 (= Vielfache von 4×4-Tiles) ✅
- Kein Artwork-Rework nötig ✅

### Bausystem-Änderung
- Aktuell: Spieler kauft/baut auf **16×16 Parzellen** (ganzer Block)
- Neu: Spieler kauft/baut auf **4×4 Tiles** (freie Feinplatzierung)
- Das ist der größte UI/UX-Umbau im Rework

---

## Referenz-Spiele
- **Two Point Hospital / Prison Architect:** Unified Feingrid, freie Raumplatzierung, gleiche Prinzipien

---

## Umsetzungs-Roadmap (grob, post-Alpha)
1. Neues MapGrid mit 4×4 Tile-System
2. Migration der Raumdefinitionen auf Tile-basierte Größen
3. Neues Bausystem UI (Tile-Kauf statt Parzellen-Kauf)
4. GuestActor/StaffActor auf `tile_id`-basiertes Speichern umstellen
5. Altes 2-System-Nav komplett ersetzen
6. Save-Migration für bestehende Saves (v2_ → v3_)
