## Version: 0.1.28
**Datum: 2026-06-26**

### Features & Verbesserungen

- **Bar als vollständiger POI**: Bar öffnet/schließt anhand der Öffnungszeiten aus der Room-Definition. Tooltip zeigt korrekt „Geöffnet" / „Geschlossen" inkl. Uhrzeiten. Gäste prüfen Budget und laufen zur Bar, Einnahmen werden korrekt per `FinanceManager.add_transaction()` verbucht. FloatingValue (+€) und Ka-Ching-Sound bereits vorhanden und aktiv.
- **Individuelles Gast-Budget**: Jeder `GuestMember` hat jetzt sein eigenes `daily_budget` / `spending_budget` (statt eines gemeinsamen Party-Topfs). Erwachsene erhalten einen individuellen Zufallsbetrag (aus GuestDefinitions), Kinder 20–40 % davon. Täglich morgens wird das Budget pro Member zurückgesetzt.
- **Budget-Anzeige überall konsistent**: F10-Gästeliste, Detail-Panel und Follow-Tooltip zeigen das individuelle Member-Budget (Verbleibend / Tagesbudget in €).
- **POI-Staffing zentralisiert**: `StaffManager.is_poi_staffed(poi)` ist nun die einzige Prüfstelle für den „Unterbesetzt"-Status. POIs ohne `required_role` (z. B. Lobby) gelten immer als besetzt. `CustomTooltip.gd`, `Room.gd` und `GuestActor.gd` nutzen ausschließlich diese Funktion.
- **Debug-Overlay**: `Ctrl+T` togglet das OCC-Grid-Overlay (🔴 blockiert / 🟢 begehbar) direkt im Spiel – nur im Debug-Build aktiv.

### Bugfixes

- **Pathfinding durch Lobby behoben**: Lobby-Innenraum-Tiles erhalten `weight_scale = 8.0` im `AStarGrid2D`. NPCs bevorzugen jetzt den längeren Weg durch Korridore statt diagonal durch die Lobby zu laufen.
- **Lobby-Wände im AStar**: Race-Condition beim Lobby-Spawn behoben – `_mark_lobby_on_parcel()` wird per `call_deferred()` aufgerufen, sodass `get_solid_tiles()` erst nach vollständigem `_apply_visuals()` läuft.
- **Lobby-Icon „Unterbesetzt"**: Icon und Tooltip erscheinen bei der Lobby nicht mehr fälschlicherweise – Lobby hat kein `required_role` und gilt stets als besetzt.
- **Gast-Tooltip POI-Name**: „room.bar.name" (unaufgelöster Übersetzungsschlüssel) ersetzt durch direktes `capitalize()` des poi_id – zeigt korrekt „Bar", „Spa" etc.
- **`MapGrid.gd` Dateikorruption**: Durch einen fehlerhaften Edit entstandene Korruption in `save_all_rooms_to_db()` und `_mark_parcel_walls()` vollständig behoben.

### Technische Änderungen

- `GuestMember.gd`: Felder `daily_budget: int` und `spending_budget: int` ergänzt; `to_dict()` / `from_dict()` aktualisiert (Savegame-kompatibel mit Fallback 0).
- `GuestManager.gd`: Check-in setzt Budget per Member via `randi_range()`; Tages-Reset iteriert über alle Members der Party.
- `GuestActor.gd`: Budget-Check (`_walk_to_poi`) und -Abzug (`_on_poi_arrived`) laufen auf `_guest_member.spending_budget` statt `party.spending_budget`.
- `MapGrid.gd`: `_mark_lobby_on_parcel()` setzt nach Solid-Tiles per Member `astar.set_point_weight_scale(pos, 8.0)` für alle Lobby-Innen-Tiles.
- `StaffActor.gd`: Debug-Pfadlinie (`Line2D`) entfernt – war temporäres Diagnosetool.
- `DebugOverlay.gd`: Komplette Tab-Einrückung korrigiert (Mixed-Indentation-Fehler).
- `GuestFollowTooltip.gd`: WALKING-Case wiederhergestellt; Budget-Zeile ergänzt.
- `ModalContentGuestList.gd`: Budget-Spalte und Detail-Panel zeigen `member.spending_budget` statt `party.base_price`.
- `Ingame.gd`: `_on_debug_action_requested()` (Ctrl+T) togglet jetzt OCC-Debug-Grid statt Tagesabschluss-Szene auszulösen.
