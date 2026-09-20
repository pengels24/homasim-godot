# MapGrid – OCC-Grid & Raum-Persistenz

## OCC-Grid Werte
| Wert | Bedeutung |
|------|-----------|
| `0` | Frei / Korridor |
| `1` | Raum-Körper (blockiert Platzierung) |
| `2` | Exit-Tile (Tür-Ausgang, blockiert Platzierung) |
| `3` | Wiese / Außenbereich |
| `4` | Clearance-Zone (begehbar, aber kein Baurecht) |

## Wichtige Funktionen

### `mark_placement()` / `unmark_placement()`
Markiert/entfernt Raum-Körper (1) und Exit-Tile (2) im OCC-Grid. Wird beim Platzieren und Abreißen aufgerufen.

### `remove_room(room)` – Queue-Free-Save-Bug Fix (v0.1.63)
**Wichtig:** `remove_child()` muss VOR `queue_free()` aufgerufen werden!
`queue_free()` ist asynchron (Frame-Ende). `save_all_rooms_to_db()` läuft sofort danach und würde den Node sonst noch als Kind des Parcels sehen und re-speichern → Ghost-Room.

```gdscript
room.get_parent().remove_child(room)  # ERST synchron entfernen
room.queue_free()                      # DANN deferred freigeben
save_all_rooms_to_db(...)              # Jetzt sauber
```

### `_sanitize_restored_rooms()` (v0.1.63)
Wird am Ende von `_restore_rooms()` aufgerufen. Entfernt überzählige Ghost-Room-Instanzen für Typen mit `max_count > 0`. Repair-Save danach.

### `rebuild_occ_from_active_rooms()` (v0.1.63)
Nuklear-Repair: Löscht alle Wert-1 und Wert-2 Zellen, re-markiert nur echte `active_rooms`. DevConsole: `repair-grid`.

## Debug-Tools

- `repair-grid` – OCC-Grid komplett neu aufbauen (Ghost-Room Fix)
- `occ-overlay` – Zeigt OCC-Werte als farbige Kacheln auf der Map
