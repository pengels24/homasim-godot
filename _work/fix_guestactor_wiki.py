import os

path = r'd:\game-dev\homasim-godot\wiki\02_features\25_techdoku_guestactor.md'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

header = """# TechDoku: GuestActor (Gäste-Verhalten)
*Stand: v0.1.61 – 19.09.2026 (Save/Load Fix, Luftlinien-Bugfix)*

Der `GuestActor` steuert die visuelle und logische Repräsentation eines einzelnen Hotelgastes auf der Karte. Jeder `GuestActor` ist an ein `GuestMember`-Datenobjekt gekoppelt, welches die eigentlichen Werte (Sättigung, Geduld, Geldbeutel, Budget) hält.

## 1. Lebenszyklus & Setup
- **Spawn**: Wird vom `GuestManager` instantiiert, sobald eine neue `GuestParty` anreist oder geladen wird.
- **Setup**: `setup(member, map_grid, start_room, guest_manager)` verknüpft Actor mit Datenmodell.
- **Despawn**: Nach Checkout und Verlassen des Grundstücks (`LEAVING`) wird der Actor entfernt.

"""

save_load_section = """
## 11. Save/Load – State-Serialisierung (v0.1.61)

### State-Mapping in get_save_state()

| Aktueller State | Gespeicherter State | Begründung |
|---|---|---|
| `WALKING` | `IN_ROOM` | Unterwegs → beim Laden neu starten |
| `STUDYING_MENU` | `IN_POI` | Sitzt im POI-Raum → `_current_poi_id` muss erhalten bleiben! |
| `WAITING_FOR_FOOD` | `IN_POI` | Bestellung wird nach Load neu aufgegeben |
| alle anderen | unverändert | Direkt persistiert |

> ⚠️ `STUDYING_MENU` muss als `IN_POI` gespeichert werden! Sonst ist `_current_poi_id` nach Reload leer → Phase 1 von `_execute_walk()` kann Austrittspfad nicht generieren → Luftlinie durch Wände.

### restore_save_state() – IN_POI/EATING Branch

Gäste bleiben nach Reload in `IN_POI` (nicht `IN_ROOM`):
- Visuell an ihrem gespeicherten Platz (Restaurant, Bar etc.)
- `_current_poi_id` erhalten → Phase 1 von `_execute_walk()` findet den Raum
- Timer aus Save restored (min. 5s) → kein "Feueralarm"-Exodus aller Gäste gleichzeitig
- `_restoring_from_save = true` → blockiert doppeltes Payment/EXP

### restore_save_state() – IN_ROOM Branch (TG-Gäste)

`_current_poi_id` wird nur gesetzt wenn saved position ein **solid tile** ist (= wirklich innerhalb eines POI-Raums). Gäste im Korridor (WALKING-State beim Speichern) bekommen keine falsche Raum-ID.

### Warum _current_poi_id für Phase 1 entscheidend ist

`_get_current_room_node()` prüft `_current_poi_id` zuerst:
```gdscript
if not _current_poi_id.is_empty():
    return _get_poi_room_node(_current_poi_id)  # POI-Raum gefunden!
```
→ Phase 1 von `_execute_walk()` generiert `get_local_path(seat, door_inside)` korrekt → kein Luftlinie.

> Siehe auch: `wiki/_dev/ang364_nav_rework.md` für den Post-Alpha Nav-Rework Plan.
"""

if not content.startswith('# TechDoku'):
    idx = content.find('## 2. State-Machine')
    if idx == -1:
        idx = 0
    content = header + content[idx:]

# Save/Load Sektion anhängen falls noch nicht vorhanden
if '## 11. Save/Load' not in content:
    content = content.rstrip() + '\n' + save_load_section

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Done. Lines:', len(content.splitlines()))
