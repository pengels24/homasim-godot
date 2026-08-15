# Changelog – gd-0.1.50
> Datum: 2026-07-29 | Branch: `dev`

---

## Bugfixes

- **Parzelle – Rechtsklick/Pan geblockt:** Der `build_overlay` (world-space `ColorRect` mit `mouse_filter = STOP`) lag über der gesamten Parzelle und fraß alle Mouse-Events. Behoben durch vollständiges Entfernen des Overlays.
- **Parzelle – Panel skalierte mit Zoom:** `build_overlay` war in World-Space und wuchs mit dem Kamera-Zoom. Behoben durch Entfernen des Overlays; Panel verbleibt auf dem CanvasLayer (Screen-Space) und skaliert nie.
- **Parzelle – Panel unsichtbar nach Parzellenkauf:** `_process` lief nicht während Godots Pause-Modus (`PROCESS_MODE_INHERIT`). Dadurch wurde die Panel-Visibility nie auf `true` gesetzt. Behoben durch `process_mode = Node.PROCESS_MODE_ALWAYS` in `Parzelle._ready()`.
- **MapGrid – Zoom nach Buy-Modus geblockt:** `exit_buy_mode()` rief `queue_free()` auf `_buy_overlay_root` auf, setzte die Variable aber nicht auf `null`. Da `is_instance_valid()` für queue_free'd Nodes noch `true` liefert, war `_on_input_camera_zoom()` weiterhin geblockt. Behoben durch `_buy_overlay_root = null` direkt nach `queue_free()`.
- **MapGrid – `_show_built_parcels`:** Veralteter Zugriff auf `p.build_overlay` (existiert nicht mehr) entfernt. Panel-Visibility wird jetzt vollständig von `Parzelle._process` übernommen.

---

## Verbesserungen

- **ParzelleBuildUI – Theme-konform:** `ParzelleBuildUI.tscn` komplett auf Standard-Theme-Variations umgestellt:
  - `theme_type_variation = "TooltipPanel"` (Hintergrund)
  - `theme_type_variation = "TooltipHeader"` (Titel-Label)
  - `theme_type_variation = "TooltipProgressBar"` (Fortschrittsbalken)
  - `theme_type_variation = "TooltipText"` (Zeit-Label)
  - Struktur identisch zu `CustomTooltip.tscn` (MarginContainer -> VBoxContainer -> HSeparator)
  - Alle hardcodierten Farben, Fontgrößen und StyleBoxes entfernt

### UI / Tutorials / Texte (Aktuelle Session)
- **Tutorial-Bilder:** Bilder für Kategorien Gäste, Räume und Forschung um 30% verkleinert.
- **Tutorial-Texte Räume:** Formatierung mit echten Zeilenumbrüchen in language.csv via Python-Skript eingefügt.
- **Codex-Tabs:** Alten Codex-Tab in Gäste umbenannt, Präfix Neuer Gästetyp: entfernt, neuen leeren Codex-Tab angehängt.
- **Techtree-Texte:** Python-Skript geschrieben, um abgeschnittene Techtree-Texte in language.csv zu reparieren (Kommas maskiert) und zerstörte Umlaute zu korrigieren. Doppelte Keys entfernt.
- **Issue angelegt:** Issue für Automatisierung der Techtree-Texte in den Backlog aufgenommen.

### UI & QoL
- Techtree-Texte automatisiert: Voraussetzungen, Kosten und Freischaltungen generieren sich nun automatisch für Tooltip und Codex.
- Float-Rundungsfehler (z.B. Level 3.0 statt 3) im Techtree gefixt.
- CSV-Import repariert (versteckte Zeilenumbrüche).

### Codex & Techtree Tooltips (Aktuelle Session)
- **POI-Codex:** Neuen Codex-Eintrag für 'Point of Interest (POI)' in tutorials.json und language.csv angelegt.
- **Tutorials UI:** Platzhalter-Text aus dem 'Codex'-Reiter (ModalContentTutorials.gd) entfernt, sodass jetzt echte Einträge aus der Datenbasis geladen werden.
- **Techtree Tooltips:** Die Tooltips im Forschungsbaum (ModalContentTechtree.gd) ignorieren nun nicht mehr die schönen Beschreibungstexte, sondern zeigen sie ganz oben an. Der generische 'Schaltet neue Inhalte frei'-Platzhalter wurde dafür komplett entfernt.
- **Tooltip Word-Wrap:** Ein manueller Word-Wrap (_wrap_text) für die Techtree-Tooltips wurde implementiert, um den Godot 4 Bug zu umgehen, bei dem Tooltip-Panels bei extrem langen einzeiligen Texten (wie bei G1.2/G1.3) die Proportionen des Hintergrunds zerstören.
- **Tutorial-Texte:** Die harten Techtree-Voraussetzungen in den Tutorial-Beschreibungen wurden per Skript um die tatsächlichen Namen erweitert (z.B. 'Techtree Z1.2 (Familienzimmer)').

### Techtree & UI (Fortsetzung)
- **Techtree Freischaltungen:** Funktionale Nodes (W1.1 Wellness-Bonus, P1.3 VIP-Gaeste und G1.4 Gourmetkueche) wurden aus dem demo_locked Status befreit und koennen nun erforscht werden.
- **Techtree Tooltips:** Die hartkodierten Platzhalter-Features fuer kuenftige Raeume (W1.2, W1.3, P1.2) aus den unlocks_features der JSON entfernt, da diese automatisch durch die Raum-Logik befuellt werden.
- **Room Hover Bug:** Einen Fehler behoben, bei dem Moebelstuecke (NavBlocker, Betten, Stuehle) die Mauseingaben blockierten und so den Raum-Hover-Effekt unterbrachen. Der Mouse-Filter wird nun fuer alle Moebel dynamisch und rekursiv auf IGNORE gesetzt - dies funktioniert nun auch fuer Multi-Tile Raeume wie das Doppelzimmer korrekt.
- **Grid-Verschmelzung (ANG-332):** Kaufbare Parzellen werden nun nicht mehr als separates Grid berechnet. Das MapGrid verschmilzt alle gekauften Parzellen dynamisch zu einem einzigen großen Grid. Der Nullpunkt wird beim Kauf einer Parzelle links/oben vom Hotel neu berechnet, wodurch Koordinaten für Räume, Wegfindung und Gäste global eindeutig bleiben.
- **Tutorials & Codex (Dynamisch):** Die Liste der verfügbaren Räume im Codex wird nicht länger manuell gepflegt, sondern generiert sich zur Laufzeit automatisch aus den Definitionen aller baubaren Räume (inkl. automatischer Fallback-Icons und Text-Zuordnungen).
- **Techtree P1.2:** Der Konferenzraum hat seinen Demo-Lock verloren und ist nun in der Alpha regulär erforsch- und baubar.
- **Bugfixes & Polish:**
    - FloorLayer (Rasen) hat nun Z-Index -2 und wächst nicht mehr optisch durch Hotel-Flure.
    - `room_category.business` (Übersetzung) ergänzt.
    - Fehlerhafter Pfad für `map-pin.svg` im Codex behoben.
    - Ungenutzte Parameter, Integer-Division-Warnungen und Ternary-Operator Typenwarnungen in MapGrid.gd und BuildCursor.gd beseitigt.
- **Multi-Tile-Room Nav-Bug:** Fehlerhafte Registrierung von Möbeln (Betten) in gedrehten Räumen (Portrait) behoben. Das Spiel griff versehentlich immer auf die Möbel des Landscape-Nodes zu, wodurch Betten physikalisch außerhalb der Räume (auf dem Flur) lagen und Gäste fälschlicherweise durch Wände auf den Flur schlafen geschickt wurden.
- **Küchenpersonal Pathfinding:** Interne Grid-Auflösung (LOCAL_NAV_CELL_SIZE) in Räumen von 8 auf 4 Pixel erhöht, damit das Kochen/Wandern zwischen großen NavBlocker-Boxen möglich wird.
- **NavBlocker Debug-Overlay:** Das interne Debug-Overlay (SHOW_DEBUG_PATHS) zeichnet rote Kollisionsboxen und AStar-Punkte nun maßstabsgetreu und über den Möbeln auf dem korrekten Canvas-Layer.
- **Lokale Wegfindung:** Ein Fallback eingebaut, falls das interne AStar-Raster in einem Raum komplett blockiert ist (verhindert Hänger am Tür-Knoten).
- **Lokale Wegfindung Fixes:** Bug behoben, bei dem kurze Wege die Start-/Endpunkte überschrieben haben (path_world[0]). Die Wegfindung fügt Start- und Endpunkte nun korrekt ein.
- **StaffActor Wegfindung:** Mitarbeiter nutzen nun korrekt das interne AStar-Netz des Raumes, um zu ihrem get_work_position-Ziel zu navigieren, anstatt die Möbel auf einer geraden Luftlinie zu durchqueren.
- **KitchenSmall WorkArea:** %ChefWorkArea Marker wird nun korrekt ausgelesen und als dynamischer Arbeitsplatz mit Fallback (Raummitte) genutzt.
- **ServicePoint System:** Neues %ServicePoint Marker-System für Räume eingeführt (Room.get_service_position()). Reinigungskräfte und Hausmeister laufen nun in das Zimmer hinein zum Marker (oder in die Raummitte), anstatt von außen durch die Tür zu wischen.
- **POI-Verhalten & Wellness-Logik:** Rekursions-Bug in `GuestActor.gd` behoben, durch den Gäste den Pool sofort wieder verließen. Tiefere Logik für Wellness-Aufenthalte implementiert (1-3 Ingame-Stunden Dauer, alle 15-30 Minuten Platzwechsel). POI-Limitierung für Gäste hinzugefügt (`max_guests`). Schließzeiten der POIs werden beim Aufenthalt berücksichtigt.
- **Konferenzraum-Logik:** Chair12 als dediziertes Rednerpult konfiguriert. Gäste rotieren nun dynamisch ans Pult (10-15 Min Vortrag) und räumen den Platz danach für den nächsten.
- **Bademeister-Sitzposition:** `PoolSmall.gd` Rotation des Hochsitzes korrigiert (`+ PI/2.0`). Die optische Fehlplatzierung im Wasser liegt am Sprite-Offset.
- **Gym & Spa Initialisierung:** `claim_seat` in `GymSmall.gd` und `SpaSmall.gd` ergänzt, um fehlgeschlagene Sitzplatzsuche der Gäste zu verhindern.
- **GuestActor Pool Exit:** Bug behoben (Geisterschweben), durch den Gäste beim Verlassen des Pools fälschlicherweise den Restaurant-AStar für den Pool-Raum nutzten.
- **Bademeister Patrouille:** Radius-Berechnung in `StaffActor.gd` korrigiert (Plot-Tiles x 32px), damit er das gesamte Pool-Areal nutzt und nicht nur das obere linke Viertel und dadurch in Möbel navigiert.
- **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch über `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) für fehlende Voraussetzungen / falschen Zimmertyp integriert.
- **Pool-Patrouille Bademeister:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- **Debugger-Cleanup:** Godot-Warnings beim Start behoben (Shadowed Variables `is_active`/`ready`, Unused Signals in GameState/GuestManager, Integer Division in ParzelleBuildUI, sowie leere Tween-Errors in GuestActor gefixt).
- **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik für AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- **UI & Font Colors:** Harte Farbcodierungen in Skripten (`GuestFollowTooltip.gd` & `ModalContentGuestList.gd`) entfernt und stattdessen `StyleBoxFlat`-Ressourcen für Needs-Bars in den `.tscn`s eingerichtet. Schriftfarbe der Prozentzahlen in den Balken auf dunkelgrau gesetzt.
- **Language CSV Encoding:** UTF-8 BOM Fehler behoben, welcher Umlautfehler bei 'Spaß' verursachte. Lokalisierte Keys ("HU", "DU", "EN", "SP") hinzugefügt.
- **Gästelisten Live-Sync Fix:** `ModalContentGuestList.gd` komplett überarbeitet, sodass die Gästeliste und der Detailbereich nun 100% synchron und fehlerfrei aktualisiert werden. Der ID-Vergleichs-Bug `member.id == _selected_guest.get("id")` (der Gast hat keine "id") wurde zu einem direkten Actor-Vergleich korrigiert. Zudem aktualisiert die Liste nun auch das Budget (`member.spending_budget`) live pro Frame und wertet die States wie EATING/SLEEPING korrekt zum jeweiligen `_current_poi_id` bzw. Zimmer auf.

---

### Wellness & Gästebedürfnisse (Session 2026-08-11)

- **POI Need-Restoration:** `need_restoration`-Dictionary in POI-Definitionen (Spa, Pool, Gym, Bar) vollständig implementiert. Gäste erhalten beim Verlassen eines POIs die definierten Stat-Veränderungen (`energy`, `fun`, `saturation`, `thirst`). Negative Werte (z.B. `energy: -10` für Schwimmen) werden korrekt angewandt – Gäste werden nach intensiver Aktivität spürbar müder.
- **SpaSmall Kapazität:** Max. Gäste-Kapazität von 4 auf 6 erhöht.
- **SpaSmall Patrouille:** Patrol-Intervall des Bademeister-äquivalents auf 20 Sekunden gesetzt, um unnötige Unruhe zu vermeiden.

### Gast-Pathfinding & Spawn (Session 2026-08-11)

- **Gast Spawn-Fix (Lobby) – Root Cause behoben:** `Path failed: SOLID`-Fehler beim Gäste-Spawn vollständig eliminiert. Die Ursache: Reception-Waypoints (Tresen-Wartepunkte) liegen ausserhalb der Lobby-Clearance und sind daher im globalen AStar als solid markiert. Der bisherige Code versuchte, Gäste zu diesen solid Tiles zu bewegen → Fehler.
  - **Neue Lösung:** `start_waiting_in_lobby()` platziert neue Gäste nun direkt (Teleport) an einem Reception-Waypoint. Kein Walk-Pfad nötig, da das Rezeptions-Modal den Bildschirm verdeckt. Zusätzlich: Gäste erscheinen jetzt sofort sichtbar in der Lobby, sobald die Toast-Meldung „Neue Gäste" erscheint.
  - **Check-in Flow:** Nach Check-in nutzen Gäste die lokale Lobby-Navigation (NavMesh) zur Innentür, dann den globalen AStar durch den Korridor zum Zimmer.
- **GuestActor `_execute_walk`:** `State.WAITING_IN_LINE` in den Bedingungsblock für lokalen Pfad-aus-Raum aufgenommen, damit der Lobby-LOCAL-Pfad korrekt beim Check-in triggert.
- **GuestActor `_walk_to_room`:** Wenn der Gast aus dem `WAITING_IN_LINE`-State kommt (an der Rezeption), wird `lobby.get_target_tile()` als Startpunkt für den globalen AStar-Pfad genutzt (statt des solid Waypoint-Tiles).
- **MapGrid:** `is_tile_walkable(tile)` und `find_nearest_walkable_tile(tile, max_radius)` als public Hilfsmethoden ergänzt.

### Quests & Systeme (Session 2026-08-13)

- **Quests & QuestManager (ANG-336):** Neue Quests für Gastronomie (Baue Bar, Küche, Restaurant, Koche/Serviere X Gerichte) in `quests.json` hinzugefügt und dynamisches Quest-Tracking (`_increment_quest_progress`, `_check_quest_threshold`) im `QuestManager` implementiert (z.B. für POI Nutzung, Tagesabschluss, gekochtes Essen).
- **Events & DevConsole:** Event-Status wird nun im Savegame (`event_data`) über `SaveManager` und `EventManager` gespeichert. `DevConsole` um `set-conference:on/off` (manuelles Triggern des Tagungs-Events) und `add-guest-budget` erweitert.
- **Icons & Assets:** Zahlreiche neue Pixel-Art Icons für Räume (Bar, Betten, Konferenzraum, Gym, Spa) und das Overlay-Toolbar (Brush, Cat, Usage, Value, Wrench) hinzugefügt.
- **Dokumentations-Richtlinien:** `AGENTS.md` um Dokumentationspflicht nach Tests erweitert. `update_doku` Skill angepasst.

### Bugfixes & Persistenz (Session 2026-08-13 – Abend)

- **Upgrade-Persistenz Fix (`acquired_traits`):** Zimmer-Upgrades (WLAN, Klima) gingen nach Speichern und Neuladen verloren. Root Cause: `Ingame.gd` rief nach dem Laden nochmals `room.configure({guest_manager: ...})` auf alle platzierten Räume auf, was in `Room.gd` den `else`-Zweig triggerte und `acquired_traits = []` resetzte – obwohl die Traits korrekt aus dem Savegame geladen wurden. Fix: `configure()` setzt `acquired_traits` nur noch zurück, wenn der Key `acquired_traits` tatsächlich im übergebenen Dictionary enthalten ist (`elif data.has("acquired_traits"):`).

### UI-Verbesserungen (Session 2026-08-13 – Abend)

- **POI Tooltip – Öffnungszeiten:** Tooltip geöffneter POIs zeigt jetzt die konkreten Öffnungszeiten: „🍺 Geöffnet (08:00 - 22:00 Uhr)" statt dem generischen „🍺 Geöffnet".

### Lobby Check-In Flow (Session 2026-08-14)

- **Gast sichtbar an Rezeption:** `start_waiting_in_lobby()` platziert Gäste nun sofort per Teleport an einem zufälligen `receptionX`-Waypoint in der Lobby. Der Gast ist unsichtbar während der Staffelung (delay) und erscheint dann direkt sichtbar stehend an der Rezeption (`WAITING_IN_LINE`). Kein fehlerhafter Walk-Pfad durch die solide Lobby-Fläche mehr.
- **Check-in Walk korrekt:** Nach Bestätigung des Check-ins nutzt der Gast die **lokale Lobby-Navigation** (Room.gd AStar2D) von seiner receptionX-Position zur Lobby-Innentür, dann den **globalen Korridorpfad** zum Zimmer. Kein Durchlaufen von Möbeln oder Wänden mehr.
- **`previous_state` Fix in `_walk_to_room`:** `_change_state(WALKING)` überschrieb `previous_state` (von `WAITING_IN_LINE` auf `WALKING`), bevor `_execute_walk` ihn auslesen konnte. Fix: `previous_state` wird vor dem `_change_state`-Aufruf gesichert und danach wiederhergestellt.
- **Reload-Fix:** `GuestController.spawn_active_guests()` iteriert nun auch über `_guest_manager._waiting` und platziert wartende Gäste nach einem Spielstand-Reload sichtbar an der Rezeption.


### Conference Flow & POI Pathing Fixes (Session 2026-08-14)
- **Conference Flow & Tweens:** Instant-Teleport zum Rednerpult (Chair12) durch animierten _execute_poi_move() Tween ersetzt. Cooldown von 10-15 Ingame-Minuten nach dem Reden eingebaut, damit der Redner nach dem Zurücktreten nicht sofort wieder ans Pult rennt.
- **POI Leave Pathing Fix:** Gäste, die im Status STUDYING_MENU oder WAITING_FOR_FOOD einen POI verließen (z.B. weil dieser schließt), ignorierten das lokale AStar-Grid und liefen Luftlinie durch Wände (Skipped local_path_out). Diese Gastro-States wurden in _execute_walk zur lokalen Pfadgenerierung hinzugefügt.

### Offen / Nächste Session
- **WLAN/Klima-Overlays in OverlayToolbar:** Zwei neue Overlay-Buttons (WLAN-Abdeckung, Klima-Abdeckung) mit Rot/Grün-Indikator pro Raum in die HUD-Toolbar integrieren.

### Ingame & Navigation (Aktuelle Session)
- **Bar/Gastro Einlauf-Animation:** G�ste teleportieren nicht mehr unsichtbar an den Platz, sondern laufen nach dem Eintreten sichtbar durch den Raum zum Hocker.
- **Gym/Pool/Spa Sichtbarkeit:** Unsichtbarkeit-Bug an Trainingsger�ten und im Wasser behoben.
- **GuestActor Navigation-Refactoring:** _get_logical_start_tile() komplett �berarbeitet. Die Start-Kachel-Ermittlung aus POIs funktioniert nun generisch und robust �ber _current_poi_id. Verhindert SOLID-Fehler bei unerwarteten Statuswechseln (z. B. Bettzeit um 23:00 Uhr w�hrend Wartezeit in Restaurant).

### UI / Finanzen (Aktuelle Session)
- **Kassenbuch Gastro-Namen:** Fehlende Rezeptnamen in Gastro-Kassenbucheintr�gen () repariert (Key 
ame_key statt 
ame verwendet).
- **Kassenbuch Checkout-Details:** Checkout-Logs um Zimmertyp und Aufenthaltsdauer erweitert. ModalContentFinances.gd unterst�tzt nun dynamische Anzahl an Platzhaltern in der �bersetzung.
