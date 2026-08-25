# Übergabe-Protokoll – Session 25.08.2026

## Was war der letzte Stand?

Der Notfall-Teleport-Bug (Gäste werden bei Pathfinding-Fehler unsichtbar in ihr Zimmer gebeamt) war seit mehreren Sessions das Hauptproblem. Das Debug-Overlay war falsch positioniert (koordinaten-mismatch) und hat die Diagnose erschwert. In der heutigen Session wurde:

1. **Der Root-Cause des Notfall-Teleports** gefunden und behoben
2. **Ein robustes Debug-System** aufgebaut, das künftige Pfad-Probleme schnell lokalisierbar macht

---

## Was wurde bearbeitet?

### `GuestActor.gd`

**Root-Cause-Fix `_get_logical_start_tile()`:**
- Alte Bedingung: `if not _current_poi_id.is_empty() and _current_poi_id != "lobby":`
- Neue Bedingung: `if not _current_poi_id.is_empty():`
- **Warum:** Gäste am Snackautomaten haben `_current_poi_id = "lobby"`. Der `!= "lobby"` Ausschluss bewirkte, dass der POI-Door-Lookup übersprungen und die physische Position (tief im soliden Lobby-Körper) als Start genutzt wurde → Pfad unmöglich → Notfall-Teleport.

**Safety-Fallback:**
- Nach `_get_closest_walkable_tile()` wird geprüft, ob das Ergebnis solid ist.
- Falls ja → Lobby-Innentür als Notfall-Start (mit Log-Ausgabe).

**Debug-Labels:**
- Alle 4 `get_path_between_tiles()` Aufrufe übergeben jetzt `_guest_member.get("name")` als `debug_label`.
- `_debug_paths.append()` → Dictionary-Format `{path, label}`
- `_debug_paths.erase()` → `filter()` für Kompatibilität

**IN_POI State-Log:**
- Zustandswechsel zu `IN_POI` loggt jetzt POI-Name: `changed state: WALKING -> IN_POI [bar]`

### `MapGrid.gd`

- `_debug_paths` umgestellt auf `Array[Dictionary]` (`{path, label}`)
- `get_path_between_tiles()` hat neuen optionalen Parameter `debug_label: String = ""`
- `_draw()` zeichnet pro Pfad: grüner Kreis (Start), roter Kreis (Ziel), weißes Label (Gastnamen)
- Konsolen-Log bei jedem erfolgreichen Pfad: `[MapGrid] Path OK: <Name> | <start> -> <end> len=<N>`
- Konsolen-Log bei Pfadfehler: Active-Rooms-Dump bleibt erhalten

### `DebugOverlay.gd`
- Komplett deaktiviert (`_draw()` leer). Das veraltete Koordinatensystem (`WALK_W * TILE_PX` Offset) war der ursprüngliche Ursache des Overlay-Mismatches. `MapGrid._draw()` übernimmt alles korrekt via `to_local(tile_to_world())`.

---

## Aktueller Zustand

- Das Spiel läuft ruhig durch (laut User-Bestätigung: "ok es scheint ruhig zu laufen")
- Notfall-Teleports sind nicht mehr aufgetreten nach dem Fix
- Safety-Fallback feuerte einmal für Marie Janssen (bestätigte Korrektur der Lobby-Innentür-Route)
- Debug-Overlay zeigt korrekt ausgerichtete Pfade mit Gastnamen-Labels

---

## Sofortige nächste Schritte für den nächsten Agenten

1. **Beobachten:** Über mehrere Spieltage überwachen ob noch Notfall-Teleports auftreten. Falls ja, den Safety-Fallback-Log auswerten (`poi=` zeigt den aktuellen poi_id Wert).

2. **Debug-System aufräumen (optional):** Das Debug-System (Labels, Console-Logs) wurde für die Diagnose eingebaut. Wenn der Bug als stabil gilt, kann `get_path_between_tiles` den Debug-Label-Parameter wieder entfernen und die Label-Zeichnung aus `_draw()` raus. Die Failed-Path-Darstellung (magenta) kann dauerhaft bleiben.

3. **Offene Baustelle WLAN/Klima-Overlays:** `wiki/alpha_backlog.md` → "Offen / Nächste Session" → WLAN/Klima-Overlay-Buttons in HUD-Toolbar.

4. **Möglicher Edge-Case:** `_get_closest_walkable_tile()` sucht nur bis Radius 2. Wenn ein Gast in einem großen soliden Block steckt (z.B. mitten in einem Raum), hilft der Safety-Fallback. Langfristig wäre eine Erweiterung auf Radius 4-5 robuster.

---

## Dateien-Übersicht dieser Session

| Datei | Was geändert? |
|---|---|
| `scenes/ingame/guest/GuestActor.gd` | Root-Cause-Fix, Safety-Fallback, Debug-Labels, IN_POI-Log |
| `scenes/ingame/map/MapGrid.gd` | Debug-Label-Parameter, Dictionary-Format, `_draw()` Label-Rendering |
| `scenes/ingame/map/DebugOverlay.gd` | Deaktiviert (leere `_draw()`) |
| `changelog/gd-0.1.50.md` | Session-Einträge ergänzt |
| `wiki/alpha_backlog.md` | Wolfgang-Bug als ✅ markiert, neue Einträge |
| `_work/uebergabe.md` | Dieses Dokument |
