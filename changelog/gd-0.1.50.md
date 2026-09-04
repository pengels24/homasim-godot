# Changelog ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ gd-0.1.50
> Datum: 2026-07-29 | Branch: `dev`

---

## Bugfixes

- **Parzelle ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Rechtsklick/Pan geblockt:** Der `build_overlay` (world-space `ColorRect` mit `mouse_filter = STOP`) lag ÃƒÆ’Ã‚Â¼ber der gesamten Parzelle und fraÃƒÆ’Ã…Â¸ alle Mouse-Events. Behoben durch vollstÃƒÆ’Ã‚Â¤ndiges Entfernen des Overlays.
- **Parzelle ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Panel skalierte mit Zoom:** `build_overlay` war in World-Space und wuchs mit dem Kamera-Zoom. Behoben durch Entfernen des Overlays; Panel verbleibt auf dem CanvasLayer (Screen-Space) und skaliert nie.
- **Parzelle ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Panel unsichtbar nach Parzellenkauf:** `_process` lief nicht wÃƒÆ’Ã‚Â¤hrend Godots Pause-Modus (`PROCESS_MODE_INHERIT`). Dadurch wurde die Panel-Visibility nie auf `true` gesetzt. Behoben durch `process_mode = Node.PROCESS_MODE_ALWAYS` in `Parzelle._ready()`.
- **MapGrid ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Zoom nach Buy-Modus geblockt:** `exit_buy_mode()` rief `queue_free()` auf `_buy_overlay_root` auf, setzte die Variable aber nicht auf `null`. Da `is_instance_valid()` fÃƒÆ’Ã‚Â¼r queue_free'd Nodes noch `true` liefert, war `_on_input_camera_zoom()` weiterhin geblockt. Behoben durch `_buy_overlay_root = null` direkt nach `queue_free()`.
- **MapGrid ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ `_show_built_parcels`:** Veralteter Zugriff auf `p.build_overlay` (existiert nicht mehr) entfernt. Panel-Visibility wird jetzt vollstÃƒÆ’Ã‚Â¤ndig von `Parzelle._process` ÃƒÆ’Ã‚Â¼bernommen.

---

## Verbesserungen

- **ParzelleBuildUI ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Theme-konform:** `ParzelleBuildUI.tscn` komplett auf Standard-Theme-Variations umgestellt:
  - `theme_type_variation = "TooltipPanel"` (Hintergrund)
  - `theme_type_variation = "TooltipHeader"` (Titel-Label)
  - `theme_type_variation = "TooltipProgressBar"` (Fortschrittsbalken)
  - `theme_type_variation = "TooltipText"` (Zeit-Label)
  - Struktur identisch zu `CustomTooltip.tscn` (MarginContainer -> VBoxContainer -> HSeparator)
  - Alle hardcodierten Farben, FontgrÃƒÆ’Ã‚Â¶ÃƒÆ’Ã…Â¸en und StyleBoxes entfernt

### UI / Tutorials / Texte (Aktuelle Session)
- **Tutorial-Bilder:** Bilder fÃƒÆ’Ã‚Â¼r Kategorien GÃƒÆ’Ã‚Â¤ste, RÃƒÆ’Ã‚Â¤ume und Forschung um 30% verkleinert.
- **Tutorial-Texte RÃƒÆ’Ã‚Â¤ume:** Formatierung mit echten ZeilenumbrÃƒÆ’Ã‚Â¼chen in language.csv via Python-Skript eingefÃƒÆ’Ã‚Â¼gt.
- **Codex-Tabs:** Alten Codex-Tab in GÃƒÆ’Ã‚Â¤ste umbenannt, PrÃƒÆ’Ã‚Â¤fix Neuer GÃƒÆ’Ã‚Â¤stetyp: entfernt, neuen leeren Codex-Tab angehÃƒÆ’Ã‚Â¤ngt.
- **Techtree-Texte:** Python-Skript geschrieben, um abgeschnittene Techtree-Texte in language.csv zu reparieren (Kommas maskiert) und zerstÃƒÆ’Ã‚Â¶rte Umlaute zu korrigieren. Doppelte Keys entfernt.
- **Issue angelegt:** Issue fÃƒÆ’Ã‚Â¼r Automatisierung der Techtree-Texte in den Backlog aufgenommen.

### UI & QoL
- Techtree-Texte automatisiert: Voraussetzungen, Kosten und Freischaltungen generieren sich nun automatisch fÃƒÆ’Ã‚Â¼r Tooltip und Codex.
- Float-Rundungsfehler (z.B. Level 3.0 statt 3) im Techtree gefixt.
- CSV-Import repariert (versteckte ZeilenumbrÃƒÆ’Ã‚Â¼che).

### Codex & Techtree Tooltips (Aktuelle Session)
- **POI-Codex:** Neuen Codex-Eintrag fÃƒÆ’Ã‚Â¼r 'Point of Interest (POI)' in tutorials.json und language.csv angelegt.
- **Tutorials UI:** Platzhalter-Text aus dem 'Codex'-Reiter (ModalContentTutorials.gd) entfernt, sodass jetzt echte EintrÃƒÆ’Ã‚Â¤ge aus der Datenbasis geladen werden.
- **Techtree Tooltips:** Die Tooltips im Forschungsbaum (ModalContentTechtree.gd) ignorieren nun nicht mehr die schÃƒÆ’Ã‚Â¶nen Beschreibungstexte, sondern zeigen sie ganz oben an. Der generische 'Schaltet neue Inhalte frei'-Platzhalter wurde dafÃƒÆ’Ã‚Â¼r komplett entfernt.
- **Tooltip Word-Wrap:** Ein manueller Word-Wrap (_wrap_text) fÃƒÆ’Ã‚Â¼r die Techtree-Tooltips wurde implementiert, um den Godot 4 Bug zu umgehen, bei dem Tooltip-Panels bei extrem langen einzeiligen Texten (wie bei G1.2/G1.3) die Proportionen des Hintergrunds zerstÃƒÆ’Ã‚Â¶ren.
- **Tutorial-Texte:** Die harten Techtree-Voraussetzungen in den Tutorial-Beschreibungen wurden per Skript um die tatsÃƒÆ’Ã‚Â¤chlichen Namen erweitert (z.B. 'Techtree Z1.2 (Familienzimmer)').

### Techtree & UI (Fortsetzung)
- **Techtree Freischaltungen:** Funktionale Nodes (W1.1 Wellness-Bonus, P1.3 VIP-Gaeste und G1.4 Gourmetkueche) wurden aus dem demo_locked Status befreit und koennen nun erforscht werden.
- **Techtree Tooltips:** Die hartkodierten Platzhalter-Features fuer kuenftige Raeume (W1.2, W1.3, P1.2) aus den unlocks_features der JSON entfernt, da diese automatisch durch die Raum-Logik befuellt werden.
- **Room Hover Bug:** Einen Fehler behoben, bei dem Moebelstuecke (NavBlocker, Betten, Stuehle) die Mauseingaben blockierten und so den Raum-Hover-Effekt unterbrachen. Der Mouse-Filter wird nun fuer alle Moebel dynamisch und rekursiv auf IGNORE gesetzt - dies funktioniert nun auch fuer Multi-Tile Raeume wie das Doppelzimmer korrekt.
- **Grid-Verschmelzung (ANG-332):** Kaufbare Parzellen werden nun nicht mehr als separates Grid berechnet. Das MapGrid verschmilzt alle gekauften Parzellen dynamisch zu einem einzigen groÃƒÆ’Ã…Â¸en Grid. Der Nullpunkt wird beim Kauf einer Parzelle links/oben vom Hotel neu berechnet, wodurch Koordinaten fÃƒÆ’Ã‚Â¼r RÃƒÆ’Ã‚Â¤ume, Wegfindung und GÃƒÆ’Ã‚Â¤ste global eindeutig bleiben.
- **Tutorials & Codex (Dynamisch):** Die Liste der verfÃƒÆ’Ã‚Â¼gbaren RÃƒÆ’Ã‚Â¤ume im Codex wird nicht lÃƒÆ’Ã‚Â¤nger manuell gepflegt, sondern generiert sich zur Laufzeit automatisch aus den Definitionen aller baubaren RÃƒÆ’Ã‚Â¤ume (inkl. automatischer Fallback-Icons und Text-Zuordnungen).
- **Techtree P1.2:** Der Konferenzraum hat seinen Demo-Lock verloren und ist nun in der Alpha regulÃƒÆ’Ã‚Â¤r erforsch- und baubar.
- **Bugfixes & Polish:**
    - FloorLayer (Rasen) hat nun Z-Index -2 und wÃƒÆ’Ã‚Â¤chst nicht mehr optisch durch Hotel-Flure.
    - `room_category.business` (ÃƒÆ’Ã…â€œbersetzung) ergÃƒÆ’Ã‚Â¤nzt.
    - Fehlerhafter Pfad fÃƒÆ’Ã‚Â¼r `map-pin.svg` im Codex behoben.
    - Ungenutzte Parameter, Integer-Division-Warnungen und Ternary-Operator Typenwarnungen in MapGrid.gd und BuildCursor.gd beseitigt.
- **Multi-Tile-Room Nav-Bug:** Fehlerhafte Registrierung von MÃƒÆ’Ã‚Â¶beln (Betten) in gedrehten RÃƒÆ’Ã‚Â¤umen (Portrait) behoben. Das Spiel griff versehentlich immer auf die MÃƒÆ’Ã‚Â¶bel des Landscape-Nodes zu, wodurch Betten physikalisch auÃƒÆ’Ã…Â¸erhalb der RÃƒÆ’Ã‚Â¤ume (auf dem Flur) lagen und GÃƒÆ’Ã‚Â¤ste fÃƒÆ’Ã‚Â¤lschlicherweise durch WÃƒÆ’Ã‚Â¤nde auf den Flur schlafen geschickt wurden.
- **KÃƒÆ’Ã‚Â¼chenpersonal Pathfinding:** Interne Grid-AuflÃƒÆ’Ã‚Â¶sung (LOCAL_NAV_CELL_SIZE) in RÃƒÆ’Ã‚Â¤umen von 8 auf 4 Pixel erhÃƒÆ’Ã‚Â¶ht, damit das Kochen/Wandern zwischen groÃƒÆ’Ã…Â¸en NavBlocker-Boxen mÃƒÆ’Ã‚Â¶glich wird.
- **NavBlocker Debug-Overlay:** Das interne Debug-Overlay (SHOW_DEBUG_PATHS) zeichnet rote Kollisionsboxen und AStar-Punkte nun maÃƒÆ’Ã…Â¸stabsgetreu und ÃƒÆ’Ã‚Â¼ber den MÃƒÆ’Ã‚Â¶beln auf dem korrekten Canvas-Layer.
- **Lokale Wegfindung:** Ein Fallback eingebaut, falls das interne AStar-Raster in einem Raum komplett blockiert ist (verhindert HÃƒÆ’Ã‚Â¤nger am TÃƒÆ’Ã‚Â¼r-Knoten).
- **Lokale Wegfindung Fixes:** Bug behoben, bei dem kurze Wege die Start-/Endpunkte ÃƒÆ’Ã‚Â¼berschrieben haben (path_world[0]). Die Wegfindung fÃƒÆ’Ã‚Â¼gt Start- und Endpunkte nun korrekt ein.
- **StaffActor Wegfindung:** Mitarbeiter nutzen nun korrekt das interne AStar-Netz des Raumes, um zu ihrem get_work_position-Ziel zu navigieren, anstatt die MÃƒÆ’Ã‚Â¶bel auf einer geraden Luftlinie zu durchqueren.
- **KitchenSmall WorkArea:** %ChefWorkArea Marker wird nun korrekt ausgelesen und als dynamischer Arbeitsplatz mit Fallback (Raummitte) genutzt.
- **ServicePoint System:** Neues %ServicePoint Marker-System fÃƒÆ’Ã‚Â¼r RÃƒÆ’Ã‚Â¤ume eingefÃƒÆ’Ã‚Â¼hrt (Room.get_service_position()). ReinigungskrÃƒÆ’Ã‚Â¤fte und Hausmeister laufen nun in das Zimmer hinein zum Marker (oder in die Raummitte), anstatt von auÃƒÆ’Ã…Â¸en durch die TÃƒÆ’Ã‚Â¼r zu wischen.
- **POI-Verhalten & Wellness-Logik:** Rekursions-Bug in `GuestActor.gd` behoben, durch den GÃƒÆ’Ã‚Â¤ste den Pool sofort wieder verlieÃƒÆ’Ã…Â¸en. Tiefere Logik fÃƒÆ’Ã‚Â¼r Wellness-Aufenthalte implementiert (1-3 Ingame-Stunden Dauer, alle 15-30 Minuten Platzwechsel). POI-Limitierung fÃƒÆ’Ã‚Â¼r GÃƒÆ’Ã‚Â¤ste hinzugefÃƒÆ’Ã‚Â¼gt (`max_guests`). SchlieÃƒÆ’Ã…Â¸zeiten der POIs werden beim Aufenthalt berÃƒÆ’Ã‚Â¼cksichtigt.
- **Konferenzraum-Logik:** Chair12 als dediziertes Rednerpult konfiguriert. GÃƒÆ’Ã‚Â¤ste rotieren nun dynamisch ans Pult (10-15 Min Vortrag) und rÃƒÆ’Ã‚Â¤umen den Platz danach fÃƒÆ’Ã‚Â¼r den nÃƒÆ’Ã‚Â¤chsten.
- **Bademeister-Sitzposition:** `PoolSmall.gd` Rotation des Hochsitzes korrigiert (`+ PI/2.0`). Die optische Fehlplatzierung im Wasser liegt am Sprite-Offset.
- **Gym & Spa Initialisierung:** `claim_seat` in `GymSmall.gd` und `SpaSmall.gd` ergÃƒÆ’Ã‚Â¤nzt, um fehlgeschlagene Sitzplatzsuche der GÃƒÆ’Ã‚Â¤ste zu verhindern.
- **GuestActor Pool Exit:** Bug behoben (Geisterschweben), durch den GÃƒÆ’Ã‚Â¤ste beim Verlassen des Pools fÃƒÆ’Ã‚Â¤lschlicherweise den Restaurant-AStar fÃƒÆ’Ã‚Â¼r den Pool-Raum nutzten.
- **Bademeister Patrouille:** Radius-Berechnung in `StaffActor.gd` korrigiert (Plot-Tiles x 32px), damit er das gesamte Pool-Areal nutzt und nicht nur das obere linke Viertel und dadurch in MÃƒÆ’Ã‚Â¶bel navigiert.
- **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch ÃƒÆ’Ã‚Â¼ber `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) fÃƒÆ’Ã‚Â¼r fehlende Voraussetzungen / falschen Zimmertyp integriert.
- **Pool-Patrouille Bademeister:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- **Debugger-Cleanup:** Godot-Warnings beim Start behoben (Shadowed Variables `is_active`/`ready`, Unused Signals in GameState/GuestManager, Integer Division in ParzelleBuildUI, sowie leere Tween-Errors in GuestActor gefixt).
- **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik fÃƒÆ’Ã‚Â¼r AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- **UI & Font Colors:** Harte Farbcodierungen in Skripten (`GuestFollowTooltip.gd` & `ModalContentGuestList.gd`) entfernt und stattdessen `StyleBoxFlat`-Ressourcen fÃƒÆ’Ã‚Â¼r Needs-Bars in den `.tscn`s eingerichtet. Schriftfarbe der Prozentzahlen in den Balken auf dunkelgrau gesetzt.
- **Language CSV Encoding:** UTF-8 BOM Fehler behoben, welcher Umlautfehler bei 'SpaÃƒÆ’Ã…Â¸' verursachte. Lokalisierte Keys ("HU", "DU", "EN", "SP") hinzugefÃƒÆ’Ã‚Â¼gt.
- **GÃƒÆ’Ã‚Â¤stelisten Live-Sync Fix:** `ModalContentGuestList.gd` komplett ÃƒÆ’Ã‚Â¼berarbeitet, sodass die GÃƒÆ’Ã‚Â¤steliste und der Detailbereich nun 100% synchron und fehlerfrei aktualisiert werden. Der ID-Vergleichs-Bug `member.id == _selected_guest.get("id")` (der Gast hat keine "id") wurde zu einem direkten Actor-Vergleich korrigiert. Zudem aktualisiert die Liste nun auch das Budget (`member.spending_budget`) live pro Frame und wertet die States wie EATING/SLEEPING korrekt zum jeweiligen `_current_poi_id` bzw. Zimmer auf.

---

### Wellness & GÃƒÆ’Ã‚Â¤stebedÃƒÆ’Ã‚Â¼rfnisse (Session 2026-08-11)

- **POI Need-Restoration:** `need_restoration`-Dictionary in POI-Definitionen (Spa, Pool, Gym, Bar) vollstÃƒÆ’Ã‚Â¤ndig implementiert. GÃƒÆ’Ã‚Â¤ste erhalten beim Verlassen eines POIs die definierten Stat-VerÃƒÆ’Ã‚Â¤nderungen (`energy`, `fun`, `saturation`, `thirst`). Negative Werte (z.B. `energy: -10` fÃƒÆ’Ã‚Â¼r Schwimmen) werden korrekt angewandt ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ GÃƒÆ’Ã‚Â¤ste werden nach intensiver AktivitÃƒÆ’Ã‚Â¤t spÃƒÆ’Ã‚Â¼rbar mÃƒÆ’Ã‚Â¼der.
- **SpaSmall KapazitÃƒÆ’Ã‚Â¤t:** Max. GÃƒÆ’Ã‚Â¤ste-KapazitÃƒÆ’Ã‚Â¤t von 4 auf 6 erhÃƒÆ’Ã‚Â¶ht.
- **SpaSmall Patrouille:** Patrol-Intervall des Bademeister-ÃƒÆ’Ã‚Â¤quivalents auf 20 Sekunden gesetzt, um unnÃƒÆ’Ã‚Â¶tige Unruhe zu vermeiden.

### Gast-Pathfinding & Spawn (Session 2026-08-11)

- **Gast Spawn-Fix (Lobby) ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Root Cause behoben:** `Path failed: SOLID`-Fehler beim GÃƒÆ’Ã‚Â¤ste-Spawn vollstÃƒÆ’Ã‚Â¤ndig eliminiert. Die Ursache: Reception-Waypoints (Tresen-Wartepunkte) liegen ausserhalb der Lobby-Clearance und sind daher im globalen AStar als solid markiert. Der bisherige Code versuchte, GÃƒÆ’Ã‚Â¤ste zu diesen solid Tiles zu bewegen ÃƒÂ¢Ã¢â‚¬Â Ã¢â‚¬â„¢ Fehler.
  - **Neue LÃƒÆ’Ã‚Â¶sung:** `start_waiting_in_lobby()` platziert neue GÃƒÆ’Ã‚Â¤ste nun direkt (Teleport) an einem Reception-Waypoint. Kein Walk-Pfad nÃƒÆ’Ã‚Â¶tig, da das Rezeptions-Modal den Bildschirm verdeckt. ZusÃƒÆ’Ã‚Â¤tzlich: GÃƒÆ’Ã‚Â¤ste erscheinen jetzt sofort sichtbar in der Lobby, sobald die Toast-Meldung ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾Neue GÃƒÆ’Ã‚Â¤ste" erscheint.
  - **Check-in Flow:** Nach Check-in nutzen GÃƒÆ’Ã‚Â¤ste die lokale Lobby-Navigation (NavMesh) zur InnentÃƒÆ’Ã‚Â¼r, dann den globalen AStar durch den Korridor zum Zimmer.
- **GuestActor `_execute_walk`:** `State.WAITING_IN_LINE` in den Bedingungsblock fÃƒÆ’Ã‚Â¼r lokalen Pfad-aus-Raum aufgenommen, damit der Lobby-LOCAL-Pfad korrekt beim Check-in triggert.
- **GuestActor `_walk_to_room`:** Wenn der Gast aus dem `WAITING_IN_LINE`-State kommt (an der Rezeption), wird `lobby.get_target_tile()` als Startpunkt fÃƒÆ’Ã‚Â¼r den globalen AStar-Pfad genutzt (statt des solid Waypoint-Tiles).
- **MapGrid:** `is_tile_walkable(tile)` und `find_nearest_walkable_tile(tile, max_radius)` als public Hilfsmethoden ergÃƒÆ’Ã‚Â¤nzt.

### Quests & Systeme (Session 2026-08-13)

- **Quests & QuestManager (ANG-336):** Neue Quests fÃƒÆ’Ã‚Â¼r Gastronomie (Baue Bar, KÃƒÆ’Ã‚Â¼che, Restaurant, Koche/Serviere X Gerichte) in `quests.json` hinzugefÃƒÆ’Ã‚Â¼gt und dynamisches Quest-Tracking (`_increment_quest_progress`, `_check_quest_threshold`) im `QuestManager` implementiert (z.B. fÃƒÆ’Ã‚Â¼r POI Nutzung, Tagesabschluss, gekochtes Essen).
- **Events & DevConsole:** Event-Status wird nun im Savegame (`event_data`) ÃƒÆ’Ã‚Â¼ber `SaveManager` und `EventManager` gespeichert. `DevConsole` um `set-conference:on/off` (manuelles Triggern des Tagungs-Events) und `add-guest-budget` erweitert.
- **Icons & Assets:** Zahlreiche neue Pixel-Art Icons fÃƒÆ’Ã‚Â¼r RÃƒÆ’Ã‚Â¤ume (Bar, Betten, Konferenzraum, Gym, Spa) und das Overlay-Toolbar (Brush, Cat, Usage, Value, Wrench) hinzugefÃƒÆ’Ã‚Â¼gt.
- **Dokumentations-Richtlinien:** `AGENTS.md` um Dokumentationspflicht nach Tests erweitert. `update_doku` Skill angepasst.

### Bugfixes & Persistenz (Session 2026-08-13 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Abend)
- **TagesgÃƒÂ¤ste (Day Guests) Fixes:** TagesgÃƒÂ¤ste dÃƒÂ¼rfen keine exklusiven Hotel-Einrichtungen (Pool, Gym, Spa) mehr nutzen. Sie verfallen nun auf die Lobby als Wartebereich zurÃƒÂ¼ck anstatt bei ausgebuchten POIs abzureisen. Die Wartezeit bei noch geschlossenen Events wurde von 15-45 auf 5-10 Ingame-Minuten reduziert.
- **TagesgÃƒÂ¤ste Spawn:** Spawnen nun unsichtbar und werden korrekt in den Wartebereich (Lobby) teleportiert (start_waiting_for_event).
- **Tooltip Anpassung:** TagesgÃƒÂ¤ste werden nun zur eindeutigen Unterscheidung im Tooltip mit dem Zusatz (Tagesgast) markiert.
- **GuestActor Fallback:** Logik fÃƒÂ¼r claim_seat bzw. 
oom_claim_seat in _walk_to_poi korrigiert und Lobby-Wander-Fallback hinzugefÃƒÂ¼gt. State.IDLE zur lokalen Wegfindungs-Abfrage in _execute_walk hinzugefÃƒÂ¼gt.

- **Upgrade-Persistenz Fix (`acquired_traits`):** Zimmer-Upgrades (WLAN, Klima) gingen nach Speichern und Neuladen verloren. Root Cause: `Ingame.gd` rief nach dem Laden nochmals `room.configure({guest_manager: ...})` auf alle platzierten RÃƒÆ’Ã‚Â¤ume auf, was in `Room.gd` den `else`-Zweig triggerte und `acquired_traits = []` resetzte ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ obwohl die Traits korrekt aus dem Savegame geladen wurden. Fix: `configure()` setzt `acquired_traits` nur noch zurÃƒÆ’Ã‚Â¼ck, wenn der Key `acquired_traits` tatsÃƒÆ’Ã‚Â¤chlich im ÃƒÆ’Ã‚Â¼bergebenen Dictionary enthalten ist (`elif data.has("acquired_traits"):`).

### UI-Verbesserungen (Session 2026-08-13 ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ Abend)

- **POI Tooltip ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ ÃƒÆ’Ã¢â‚¬â€œffnungszeiten:** Tooltip geÃƒÆ’Ã‚Â¶ffneter POIs zeigt jetzt die konkreten ÃƒÆ’Ã¢â‚¬â€œffnungszeiten: ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾ÃƒÂ°Ã…Â¸Ã‚ï¿½Ã‚Âº GeÃƒÆ’Ã‚Â¶ffnet (08:00 - 22:00 Uhr)" statt dem generischen ÃƒÂ¢Ã¢â€šÂ¬Ã…Â¾ÃƒÂ°Ã…Â¸Ã‚ï¿½Ã‚Âº GeÃƒÆ’Ã‚Â¶ffnet".

### Lobby Check-In Flow (Session 2026-08-14)

- **Gast sichtbar an Rezeption:** `start_waiting_in_lobby()` platziert GÃƒÆ’Ã‚Â¤ste nun sofort per Teleport an einem zufÃƒÆ’Ã‚Â¤lligen `receptionX`-Waypoint in der Lobby. Der Gast ist unsichtbar wÃƒÆ’Ã‚Â¤hrend der Staffelung (delay) und erscheint dann direkt sichtbar stehend an der Rezeption (`WAITING_IN_LINE`). Kein fehlerhafter Walk-Pfad durch die solide Lobby-FlÃƒÆ’Ã‚Â¤che mehr.
- **Check-in Walk korrekt:** Nach BestÃƒÆ’Ã‚Â¤tigung des Check-ins nutzt der Gast die **lokale Lobby-Navigation** (Room.gd AStar2D) von seiner receptionX-Position zur Lobby-InnentÃƒÆ’Ã‚Â¼r, dann den **globalen Korridorpfad** zum Zimmer. Kein Durchlaufen von MÃƒÆ’Ã‚Â¶beln oder WÃƒÆ’Ã‚Â¤nden mehr.
- **`previous_state` Fix in `_walk_to_room`:** `_change_state(WALKING)` ÃƒÆ’Ã‚Â¼berschrieb `previous_state` (von `WAITING_IN_LINE` auf `WALKING`), bevor `_execute_walk` ihn auslesen konnte. Fix: `previous_state` wird vor dem `_change_state`-Aufruf gesichert und danach wiederhergestellt.
- **Reload-Fix:** `GuestController.spawn_active_guests()` iteriert nun auch ÃƒÆ’Ã‚Â¼ber `_guest_manager._waiting` und platziert wartende GÃƒÆ’Ã‚Â¤ste nach einem Spielstand-Reload sichtbar an der Rezeption.


### Conference Flow & POI Pathing Fixes (Session 2026-08-14)
- **Conference Flow & Tweens:** Instant-Teleport zum Rednerpult (Chair12) durch animierten _execute_poi_move() Tween ersetzt. Cooldown von 10-15 Ingame-Minuten nach dem Reden eingebaut, damit der Redner nach dem ZurÃƒÆ’Ã‚Â¼cktreten nicht sofort wieder ans Pult rennt.
- **POI Leave Pathing Fix:** GÃƒÆ’Ã‚Â¤ste, die im Status STUDYING_MENU oder WAITING_FOR_FOOD einen POI verlieÃƒÆ’Ã…Â¸en (z.B. weil dieser schlieÃƒÆ’Ã…Â¸t), ignorierten das lokale AStar-Grid und liefen Luftlinie durch WÃƒÆ’Ã‚Â¤nde (Skipped local_path_out). Diese Gastro-States wurden in _execute_walk zur lokalen Pfadgenerierung hinzugefÃƒÆ’Ã‚Â¼gt.

### Offen / NÃƒÆ’Ã‚Â¤chste Session
- **WLAN/Klima-Overlays in OverlayToolbar:** Zwei neue Overlay-Buttons (WLAN-Abdeckung, Klima-Abdeckung) mit Rot/GrÃƒÆ’Ã‚Â¼n-Indikator pro Raum in die HUD-Toolbar integrieren.

### Ingame & Navigation (Aktuelle Session)
- **Bar/Gastro Einlauf-Animation:** GÃƒÂ¤ste teleportieren nicht mehr unsichtbar an den Platz, sondern laufen nach dem Eintreten sichtbar durch den Raum zum Hocker.
- **Gym/Pool/Spa Sichtbarkeit:** Unsichtbarkeit-Bug an TrainingsgerÃƒÂ¤ten und im Wasser behoben.
- **GuestActor Navigation-Refactoring:** _get_logical_start_tile() komplett ÃƒÂ¼berarbeitet. Die Start-Kachel-Ermittlung aus POIs funktioniert nun generisch und robust ÃƒÂ¼ber _current_poi_id. Verhindert SOLID-Fehler bei unerwarteten Statuswechseln (z. B. Bettzeit um 23:00 Uhr wÃƒÂ¤hrend Wartezeit in Restaurant).

### UI / Finanzen (Aktuelle Session)
- **Kassenbuch Gastro-Namen:** Fehlende Rezeptnamen in Gastro-KassenbucheintrÃƒÂ¤gen () repariert (Key 
ame_key statt 
ame verwendet).
- **Kassenbuch Checkout-Details:** Checkout-Logs um Zimmertyp und Aufenthaltsdauer erweitert. ModalContentFinances.gd unterstÃƒÂ¼tzt nun dynamische Anzahl an Platzhaltern in der ÃƒÅ“bersetzung.

### Ingame & Navigation (Aktuelle Session 2)
- **Smart Room / GuestActor State Machine Fix:** Schwerwiegender Bug in GuestActor._process_waiting behoben. Der 'Toter Gast'-Fehler nach dem Laden eines Spielstands entstand, weil der ablaufende Action-Timer im Status IN_ROOM oder IDLE komplett ignoriert wurde, was zu einem ewigen Early-Return im nÃƒÂ¤chsten Frame fÃƒÂ¼hrte. Es wurde eine Fallback-Logik (else-Branch) hinzugefÃƒÂ¼gt, die _decide_next_action() korrekt aufruft.
- **Smart Room Migration:** SpaSmall, GymSmall, PoolSmall und ConferenceSmall bereiten sich auf Smart Room Migration vor (Dokumentation aktualisiert).
- **Guest Spawn:** GÃƒÂ¤ste spawnen nun am receptionX Wegpunkt und nicht auf der StraÃƒÅ¸e (keine Animation beim Betreten, direktes Warten).

### Ingame & Navigation (Aktuelle Session 3)
- **Smart-Room API Integration:** Room.gd Basisklasse um generische Methoden (get_available_interactions, claim_interaction, 
elease_interaction) erweitert. GuestActor._wander_in_room und _change_state darauf umgestellt, um alte Hardcoded-Logik (Betten/Sitze) aufzulÃƒÂ¶sen und Race-Conditions bei der Freigabe von Interaktionen zu vermeiden.
- **Vending Machine Walk-Target Fix:** Bug in GuestActor._walk_to_poi behoben, der dazu fÃƒÂ¼hrte, dass GÃƒÂ¤ste den GetrÃƒÂ¤nkeautomaten-POI mit freien SitzplÃƒÂ¤tzen in der Lobby (Lobby als Room hat has_free_room_seat() == true geerbt) verwechselten und sich stattdessen unten rechts auf einen Sofa-Platz setzten, um dort die Automat-Interaktion (und Animation) abzuspielen. Vending Machine hat nun PrioritÃƒÂ¤t vor der Sitzplatz-Suche.
- **Lobby Special Nodes:** _find_special_nodes in Lobby.gd prÃƒÂ¤zisiert, sodass Container wie Chairs oder Deskchairs nicht mehr fÃƒÂ¤lschlicherweise als SnackPoint registriert werden.
-   * * S m a r t R o o m   B a r   M i g r a t i o n : * *   G a s t - S i t z p l a t z - Z u w e i s u n g   r e p a r i e r t .   G s t e   s t a p e l n   s i c h   n i c h t   m e h r   a u f   d e m   F a l l b a c k - P u n k t ,   s o n d e r n   b l o c k i e r e n   S i t z p l t z e   s a u b e r   b e r   c l a i m _ i n t e r a c t i o n ,   b e v o r   s i e   l o s l a u f e n . 
 
 -   * * G u e s t A c t o r   S t a t e - F l o w   ( B a r ) : * *   S t a t e   E A T I N G   r u f t   n u n   k o r r e k t   r e l e a s e _ i n t e r a c t i o n   a u f ,   d a m i t   S m a r t R o o m - P l t z e   w i e d e r   f r e i g e g e b e n   w e r d e n . 
 
 
### Personal & StaffActor Fixes
- **StaffActor Z-Index & Map Sichtbarkeit:** StaffActor Z-Index auf 100 erhÃƒÂ¶ht, damit Personal ÃƒÂ¼ber dem NavGrid gerendert wird. configure() Methode angepasst, damit spawn_room beim Start ÃƒÂ¼bergeben und gespeichert wird, was den verbuggten Lobby-Teleport direkt nach dem Spawn (und das Flackern auf der Karte) verhindert.
- **StaffActor Logging & State-Machine Bereinigung:** Die Log-Ausgaben im Stil von GuestActor in StaffActor mittels eines zentralen _set_state-Wrappers komplett wiederhergestellt (mit korrektem Vornamen/Nachnamen Parsing). Einen redundanten Mikrosekunden-Switch auf working wÃƒÂ¤hrend des "Chillings" (walking) behoben.
- **StaffActor Idle Timer:** Den Timer fÃƒÂ¼r den Sitzplatzwechsel im Pausenraum (_process_resting) von 2% auf realistische 10% (alle 2 Sekunden) erhÃƒÂ¶ht, damit das Personal lebendiger wirkt.
- **StaffSmall & Raumsitze-KapazitÃƒÂ¤t:** KapazitÃƒÂ¤ts-Check has_free_seat() bei Personal-RÃƒÂ¤umen gefixt, um zu verhindern, dass Staff-Actors in einen ÃƒÂ¼berfÃƒÂ¼llten Pausenraum spawnen. Smart-Room Interaktionen in Room.gd und StaffSmall.gd ÃƒÂ¼berprÃƒÂ¼ft.
- **Staff-Aufgaben Annahme:** Validierung und Logging des Service-Rufen Buttons. Die Wegfindung zu ZielrÃƒÂ¤umen wurde stabilisiert, und Tasks (clean_room, 
epair_room) werden zuverlÃƒÂ¤ssig angenommen und ausgefÃƒÂ¼hrt.
- **SmartRoom Bar Migration:** Gast-Sitzplatz-Zuweisung repariert. GÃƒÂ¤ste stapeln sich nicht mehr auf dem Fallback-Punkt, sondern blockieren SitzplÃƒÂ¤tze sauber ÃƒÂ¼ber `claim_interaction`, bevor sie loslaufen.
- **GuestActor State-Flow (Bar):** State EATING ruft nun korrekt `release_interaction` auf, damit SmartRoom-PlÃƒÂ¤tze wieder freigegeben werden.

### Personal & StaffActor Fixes
- **StaffActor Z-Index & Map Sichtbarkeit:** `StaffActor` Z-Index auf 100 erhÃƒÂ¶ht, damit Personal ÃƒÂ¼ber dem NavGrid gerendert wird. `configure()` Methode angepasst, damit `spawn_room` beim Start ÃƒÂ¼bergeben und gespeichert wird, was den verbuggten Lobby-Teleport direkt nach dem Spawn (und das Flackern auf der Karte) verhindert.
- **StaffActor Logging & State-Machine Bereinigung:** Die Log-Ausgaben im Stil von `GuestActor` in `StaffActor` mittels eines zentralen `_set_state`-Wrappers komplett wiederhergestellt (mit korrektem Vornamen/Nachnamen Parsing). Einen redundanten Mikrosekunden-Switch auf `working` wÃƒÂ¤hrend des "Chillings" (`walking`) behoben.
- **StaffActor Idle Timer:** Den Timer fÃƒÂ¼r den Sitzplatzwechsel im Pausenraum (`_process_resting`) von 2% auf realistische 10% (alle 2 Sekunden) erhÃƒÂ¶ht, damit das Personal lebendiger wirkt.
- **StaffSmall & Raumsitze-KapazitÃƒÂ¤t:** KapazitÃƒÂ¤ts-Check `has_free_seat()` bei Personal-RÃƒÂ¤umen gefixt, um zu verhindern, dass Staff-Actors in einen ÃƒÂ¼berfÃƒÂ¼llten Pausenraum spawnen. Smart-Room Interaktionen in `Room.gd` und `StaffSmall.gd` ÃƒÂ¼berprÃƒÂ¼ft.
- **Staff-Aufgaben Annahme:** Validierung und Logging des Service-Rufen Buttons. Die Wegfindung zu ZielrÃƒÂ¤umen wurde stabilisiert, und Tasks (`clean_room`, `repair_room`) werden zuverlÃƒÂ¤ssig angenommen und ausgefÃƒÂ¼hrt.

### Ingame & Navigation (Aktuelle Session 4)
- **GuestActor Navigation:** Fehlendes Exit-Pathing fr Gste repariert, deren Zielort auf dem identischen (oder direkt benachbarten) Global-Grid-Tile lag. Ohne globalen Weg ignorierten Gste die lokale Tr und liefen Luftlinie durch Wnde. _execute_walk prft nun generisch current_room != target_room statt path_tiles.size() > 0.

### Ingame & Navigation (Aktuelle Session 5)
- **MapGrid Teleport-Fix:** Workaround fr SOLID Start- und End-Tiles in MapGrid.gd eingebaut. Die Wegfindung schlgt nicht mehr sofort fehl, wenn der Gast auf oder neben einem Hindernis steht, was die unsichtbaren Notfall-Teleports aus Rumen heraus verhindert.
- **Room.gd INF-Bug:** Fehler in get_local_path behoben, der Gste (z. B. in der Bar) beim ziellosen Eintreten (Vector2.INF) an den hintersten verfgbaren Punkt (hinter den Tresen) fhrte. Gste bleiben nun wie vorgesehen an der Tr stehen, bis sie ein konkretes Ziel haben.
- **GuestActor Bar Loop:** Logik in _decide_next_action erweitert: Gste whlen nicht mehr ihren aktuellen POI als nchstes Ziel, um Endlos-Schleifen im selben Raum zu vermeiden.


### 23.08.2026 - Pathfinding Fixes (End of Session)
- **Bugfix:** GuestActor teleportiert bei fehlendem Pfad zur ZimmertÃƒÂ¼r.
- **Bugfix:** Room.gd ersetzt bei INF-Zielen das Ziel durch einen gÃƒÂ¼ltigen AStar Punkt im Raum, um GÃƒÂ¤ste-Wand-Clipping in der Lobby zu verhindern.
- **Logs:** `push_warning` fÃƒÂ¼r Pfad-FehlschlÃƒÂ¤ge zu regulÃƒÂ¤rem `print` geÃƒÂ¤ndert.
- **Logs:** GuestActor loggt nun regulÃƒÂ¤re Status-Wechsel (`_change_state`) analog zum StaffActor.
- **Debug:** MapGrid gibt nun bei AStar-FehlschlÃƒÂ¤gen auf derselben X-Achse die Tile-Solidity fÃƒÂ¼r jedes Tile auf der Achse aus.
- **Translation:** Fehlender Key `roomdef.name.long.lobby` in `language.csv` ergÃƒÂ¤nzt.

### 25.08.2026 - Pathfinding Root-Cause Fix & Debug-System

#### Bugfixes
- **Notfall-Teleport Root-Cause behoben:** GÃƒÂ¤ste, die nach dem Essen am Snackautomaten zurÃƒÂ¼ck in ihr Zimmer wollten, wurden mit `_current_poi_id = "lobby"` gespeichert. Die Bedingung `_current_poi_id != "lobby"` in `_get_logical_start_tile()` ÃƒÂ¼bersprang den POI-Door-Lookup, sodass die physische Position (tief im soliden Lobby-KÃƒÂ¶rper) als Start genutzt wurde Ã¢â€ â€™ Pfadfehler Ã¢â€ â€™ Notfall-Teleport.
  - **Fix:** Bedingung auf `not _current_poi_id.is_empty()` reduziert (kein Lobby-Ausschluss mehr). Damit liefert `lobby.get_target_tile()` korrekt die Lobby-InnentÃƒÂ¼r `(4, 39)` als Start.
- **Safety-Fallback eingebaut:** `_get_logical_start_tile()` prÃƒÂ¼ft nach der Tile-Berechnung, ob das Ergebnis solid ist. Falls ja, wird als letzter Ausweg die Lobby-InnentÃƒÂ¼r genutzt (loggt `[GuestActor] Safety fallback: ...`).
- **`_get_closest_walkable_tile` Limitation:** Funktion sucht nur Radius 1Ã¢â‚¬â€œ2; falls Gast tief im Lobby-KÃƒÂ¶rper sitzt, wird das solid Original-Tile zurÃƒÂ¼ckgegeben Ã¢â€ â€™ kein Pfad. Safety-Fallback fÃƒÂ¤ngt diesen Zustand nun ab.

#### Debug-System (MapGrid & GuestActor)
- **MapGrid `_debug_paths` Format:** Von `Array[Array]` auf `Array[Dictionary]` umgestellt (`{path, label}`), um den auslÃƒÂ¶senden Akteur pro Pfad zu speichern.
- **`get_path_between_tiles()` Debug-Label:** Neuer optionaler Parameter `debug_label: String = ""`. Alle `GuestActor`-Aufrufe ÃƒÂ¼bergeben `_guest_member.get("name")` als Label.
- **Visuelle Pfad-Beschriftung:** `MapGrid._draw()` zeichnet jeden Pfad mit grÃƒÂ¼nem Startkreis, rotem Zielkreis und weiÃƒÅ¸em Label-Text (Gastnamen) direkt auf der Map.
- **Konsolen-Log pro Pfad:** Jeder erfolgreiche Pfad loggt `[MapGrid] Path OK: <Name> | <start> -> <end> len=<N>`.
- **`DebugOverlay.gd` deaktiviert:** Das veraltete `DebugOverlay._draw()` (nutzte alten `WALK_W * TILE_PX` Offset = ursprÃƒÂ¼nglicher Overlay-Bug) ist nun leer. `MapGrid._draw()` ÃƒÂ¼bernimmt das gesamte Debug-Rendering mit korrekter `to_local(tile_to_world())` Transformation.
- **IN_POI State-Log erweitert:** Zustandswechsel zu `IN_POI` loggt nun den POI-Namen: `changed state: WALKING -> IN_POI [bar]`.
- **`_debug_paths.erase` angepasst:** GuestActor entfernt nach Bewegung den eigenen Eintrag per `filter()` statt `erase()` (kompatibel mit neuem Dictionary-Format).
### 26.08.2026 - Bar Solo-Loop & Hunger Priority

#### Bugfixes & Improvements
- **Bar Solo-Loop (Missing Clean-Tasks):** Im Solo-Loop (kein Waiter eingestellt) setze Bar.gd beim Verlassen eines Gastes den Stuhl bisher immer auf status = "dirty" und erzeugte einen clean_table-Task. Da diesen Task nur Waiter ausfOhren dOrfen, blieben alle 8 StOhle irgendwann dauerhaft dreckig, weshalb get_available_interactions 0 zurOckgab und Gste die Bar sofort wieder verlieYen.
  - **Fix:** In elease_interaction() wird der Stuhl im Solo-Loop (_has_waiter_assigned() == false) nun direkt wieder auf clean gesetzt, da ohne KOche/Bedienung keine Essensreste anfallen und der Barkeeper den Tresen magisch subert.
- **GuestActor Hunger-Priorisierung:** Gste haben bei der POI-Auswahl in _decide_next_action() bisher vllig zufllig zwischen allen mglichen Zielen gewhlt. Gste mit groYem Hunger ignorierten dadurch oft den Snack-Automaten und verhungerten.
  - **Fix:** Fllt der Hunger (saturation) unter 30, bevorzugt der Gast nun mit 80% Wahrscheinlichkeit gezielt Essens-POIs (ending_machine, estaurant_small, ar), sofern verfOgbar.
- **Bar als Food-POI:** Die Bar wurde in die Liste der ood_pois aufgenommen, da sie im Gastro-Loop (mit KOche und Waiter) ebenfalls Snacks anbietet.
- **GuestActor Debug-Logs:** Neuer Log-Print, der den exakten Grund ausgibt, falls ein Gast einen POI-Besuch direkt beim Eintreten abbricht (  available interactions etc.).
- **Bar NavWeight (User-Side):** Der Tresenbereich wurde vom User in Bar.tscn per NavWeight in der Szene mit einem erhhten Pfadkosten-Gewicht versehen, damit Gste sich brav vor den Tresen setzen.

### 26.08.2026 - Gastro-Loop Fixes, Waiter Patrol & UI (Session End)

#### Bugfixes
- **Room.gd Parse Error:** Absturz beim Aufruf von `is_operational()` behoben. `actor.get()` unterstuetzt in Godot 4 kein Fallback-Argument, weshalb `actor.get("_staff_data", {})` entfernt und `def` korrekt typisiert wurde.
- **Lobby Live-Monitor (Falsche Gaeste-Namen):** Die Anzeige in allen POI-Monitoren basierte auf dem internen Godot-Node-Namen (`GuestActor_XXXX`) oder auf einem nicht vorhandenen Label. Der Live-Monitor holt sich jetzt den korrekten Klarnamen aus dem internen `_guest_member`-Objekt.
- **Lobby Live-Monitor (Falsche Status-Texte):** Falsche Status-Ids korrigiert. Die Logik nutzte harte Integer (4, 8), die durch das Enum in `GuestActor.gd` abwichen (`EATING` ist 8, `AWAITING_CHECKOUT` ist 4). Der Gast wird nun beim Automaten oder Auschecken korrekt angezeigt.
- **Lobby Live-Monitor (Fehlende Translations):** Fehlende Fallback-Texte beim Aufruf von `GameState.T()` hinzugefuegt (z.B. `"Checkt aus"`, `"Holt einen Snack"`).
- **Ingame.gd 22:00 Uhr Rauswurf:** Der harte Schnitt um 22:00 Uhr, der alle Gaeste zwangsweise aus Lobby und Bar ins Bett schickte, wurde entfernt. Gaeste bleiben nun organisch bis zur regulaeren Nachtruhe ab 23:00 Uhr im Raum.
- **Bar Solo-Modus Fallback:** Die Bar schaltet jetzt korrekt auf den Solo-Modus zurueck, sobald die Kueche keine Bestellungen mehr annimmt (`_has_active_kitchen()`). Gaeste zahlen dann sofort beim Eintreten Eintritt (`visit_income`), da der Barkeeper keine Essensbestellungen mehr aufnehmen kann.

#### Features & Improvements
- **Waiter Idle Patrol (Tisch abwischen):** Bedienungen (Waiters), die untaetig an ihrer Arbeitsstation (z. B. Tresen) stehen, starten jetzt zufaellig Dummy-Aufgaben (`clean_table`). Sie laufen zu einem freien Tisch, bleiben dort kurz stehen und erzeugen im Raum den typischen Putz-Fortschrittsbalken samt Besen-Icon (`RoomStatusIndicator`), bevor sie zurueckkehren. Das laesst das Personal deutlich lebendiger wirken.
- **RoomStatusIndicator Force Clean:** Die Progress-Bar wurde erweitert (`force_clean`), um das Besen-Icon manuell einzublenden, auch wenn der Raum systemisch gar keinen Schmutz hat (genutzt fuer den neuen Dummy-Putz-Loop des Waiters).

### 27.08.2026 - Gastro-Loop, Staff Fixes & DayTransition Ã°Å¸Å’â„¢
- **Gastro-Loop**: GÃƒÂ¤ste werden um 22:00 Uhr nicht mehr hart aus der Lobby geworfen (entfernt aus Ingame.gd).
- **Bar Solo-Modus**: Wenn die KÃƒÂ¼che schlieÃƒÅ¸t (_has_active_kitchen() == false), geht die Bar automatisch in den Solo-Modus (GÃƒÂ¤ste zahlen beim Betreten).
- **Kellner-Patrouille**: Kellner im Idle-Status patrouillieren nun zufÃƒÂ¤llig zu Tischen und reinigen diese pro forma (inkl. Besen-Icon im RoomStatusIndicator), um dynamischer zu wirken.
- **RoomStatusIndicator**: UnterstÃƒÂ¼tzt nun orce_clean, um unabhÃƒÂ¤ngig vom echten Schmutz-Status des Raumes das Besen-Icon anzuzeigen.
- **DayTransitionModal**: Neues Hintergrundbild (Stadt bei Nacht) mit Clipping-Maske (Horizont). Der Mond bewegt sich nun auf einer perfekten Symmetrie-Parabel, die genau am Horizont verschwindet. Farb-Fade auf sattes Schwarz (#000000) gesetzt.
- **Staff Pathing Bug (Betten)**: Die MÃƒÂ¶bel-Erkennung in Room.gd wurde korrigiert. Nachttische (BedTable) und SchrÃƒÂ¤nke (BedCase) werden nicht mehr fÃƒÂ¤lschlicherweise als Betten registriert, sodass Mitarbeiter sich nun korrekt in die echten Betten legen, anstatt daneben zu sitzen.


### 27.08.2026 - Restaurant Flow, Staff Footprints & Vending Machine Balancing
- **Restaurant Guest Flow:** Bug behoben, durch den GÃƒÂ¤ste nach dem Karte-Studieren ohne Bestellung wieder gingen. Ursache war, dass Room.gd nach 'chair' suchte, die Nodes im Restaurant aber 'Chair' (PascalCase) hieÃƒÅ¸en, weshalb _room_seats leer war. Eine eigene _ready()-Funktion in RestaurantSmall.gd fÃƒÂ¼gt die StÃƒÂ¼hle nun manuell hinzu.
- **Restaurant Debugging:** AusfÃƒÂ¼hrliche Konsolen-Logs ([DEBUG RESTAURANT]) in place_order_for_seat ergÃƒÂ¤nzt, um exakt auszugeben, warum eine Bestellung abgelehnt wird (Kein Waiter, KÃƒÂ¼che zu, Budget/Hunger passt zu keinem Rezept, Stuhl unsauber).
- **Staff Footprint Bug:** Fehler behoben, bei dem Personal grÃƒÂ¼ne Pfad-Linien (DebugLine) auf dem Boden zurÃƒÂ¼cklieÃƒÅ¸, wenn sie z.B. schlafen gingen. Die Linie wird nun in StaffActor._set_state() automatisch geleert, sobald sie den State 'walking' verlassen.
- **Vending Machine Balancing:** Den hardcodierten Schwellenwert von 40 fÃƒÂ¼r den Snackomat-Hunger aus GuestActor.gd entfernt. Dieser ist nun als VENDING_MACHINE_HUNGER_THRESHOLD direkt im Lobby.gd-Skript konfigurierbar, unabhÃƒÂ¤ngig von der generellen Hunger-Priorisierung.

### 27.08.2026 - POI Zustandstrennung & Timeout Logik

#### Bugfixes & Improvements
- **Trennung von is_open und is_functional:** Die Basisklasse Room.gd trennt nun sauber zwischen reinen Ãƒâ€“ffnungszeiten (is_open()) und der physischen VerfÃƒÂ¼gbarkeit des nÃƒÂ¶tigen Personals (is_functional()). Ein Raum wird nicht mehr geschlossen, nur weil der Kellner Tische abrÃƒÂ¤umt (Zustand: Laufen).
- **Gast Warte-Logik fÃƒÂ¼r POIs:** Betritt ein Gast einen Raum (z.B. Restaurant), der zwar geÃƒÂ¶ffnet, aber kurzzeitig nicht funktional ist (z.B. Kellner macht Pause), wartet der Gast nun einmalig eine definierbare Zeit (Standard: 3 Ingame-Minuten), bevor er abbricht. Das verhindert stÃƒÂ¤ndiges Rein- und Rauslaufen.
- **Bar Solo-Modus PrÃƒÂ¼fung:** Die Bar.gd ÃƒÂ¼berschreibt nun is_functional(). Sie gilt nur als funktional fÃƒÂ¼r Bestellungen am Tisch, wenn *sowohl* Barkeeper *als auch* Bedienung anwesend sind.
- **Bar Solo-Modus Fallback:** Sitzt der Gast an der Bar und wartet vergebens auf die Bedienung (nach den 3 Ingame-Minuten), prÃƒÂ¼ft er, ob zumindest der Barkeeper da ist (is_bartender_present()). Wenn ja, bestellt er sein GetrÃƒÂ¤nk am Tresen und wechselt in den EATING-Status.
- **Bar Eintritt-Fix:** Der Eintritt fÃƒÂ¼r die Bar wird nun nicht mehr blind abgebucht. Ist der Gastro-Loop aktiv (Bedienung und Barkeeper anwesend), entfÃƒÂ¤llt der Eintritt, da ÃƒÂ¼ber MenÃƒÂ¼ gezahlt wird. Fehlt die Bedienung (Solo-Modus), wird der Eintritt von 15 Geld als Pauschalpreis fÃƒÂ¼r GetrÃƒÂ¤nke beim Betreten abgerechnet.
- **Food-Timeout fÃƒÂ¼r GÃƒÂ¤ste:** Wenn ein Gast im Restaurant erfolgreich bestellt hat, die Bedienung aber ausfÃƒÂ¤llt (z.B. in Pause geht) und das Essen nicht kommt, wartet der Gast nicht mehr unendlich lange. Nach 45 Ingame-Minuten bricht der Gast wÃƒÂ¼tend ab (-15 Zufriedenheits-Malus) und das ungelieferte Essen wird in der KÃƒÂ¼che gelÃƒÂ¶scht (GastroManager.cancel_order()).

### 28.08.2026 - Gastro-Loop Finalisierung & Live-Monitor Fixes (Session End)

#### Bugfixes
- **Smart-Room Loop Bug (Table Hopping):** GÃƒÂ¤ste wechselten in Smart-RÃƒÂ¤umen (und im Restaurant) kontinuierlich ihre SitzplÃƒÂ¤tze. Ursache war, dass der `IN_POI` State im `GuestActor.gd` den `_action_timer` nicht dekrementierte, wodurch in jedem Frame ein neuer Sitzplatz beansprucht (`claim_interaction`) und der alte freigegeben wurde (`release_interaction`). Der Timer-Check wurde hinzugefÃƒÂ¼gt.
- **Gastro-Room Bypass:** Gastro-RÃƒÂ¤ume (Restaurant, Bar, Kiosk) ÃƒÂ¼berspringen nun die generische Smart-Room-Schleife (`IN_POI`) nach der Ankunft und wechseln stattdessen direkt in den Status `STUDYING_MENU`. Dies lÃƒÂ¶st das Problem des redundanten Platzwechselns in Restaurants vollstÃƒÂ¤ndig.
- **Live-Monitor Bar:** Die Status-Anzeige der Bar wurde an das Restaurant angeglichen. Sie liest nun den internen `actor_state` aus und zeigt "Studiert Speisekarte" (statt pauschal "Sitzt / Trinkt") sowie den neuen Lieferstatus "Wird abgeholt & serviert" an.
- **Live-Monitor Parse Error:** Einen Scope-Fehler in `Bar.gd` behoben, der verhinderte, dass die Bar-Skripte nach dem letzten Update kompiliert wurden (`actor_state` deklariert im if-Block).
- **StaffActor Order-ID Fix:** Kellner konnten den Status einer Bestellung beim Abholen in der KÃƒÂ¼che nicht auf "serving" setzen, da sie in der Aufgaben-Struktur (Task) an der falschen Stelle nach der `order_id` suchten. Dies wurde behoben (Zugriff auf `target.order_id`), sodass die Live-Ansicht den Servier-Vorgang nun korrekt anzeigt.
- **Staff Debug-Pfade:** Die MapGrid Debug-Linien fÃƒÂ¼r das Personal zeigten die interne UUID anstatt des Namens. `StaffActor.gd` ÃƒÂ¼bergibt nun wieder korrekt den generierten Vor- und Nachnamen an den Pfad-Renderer.

#### Refactoring
- **Legacy Seat-Logic entfernt:** Die alten, harten `claim_seat` und `claim_podium` Fallbacks wurden aus `GuestActor.gd` (`_walk_to_poi` & `_on_poi_arrived`) komplett entfernt. Das Spiel nutzt nun ausschlieÃƒÅ¸lich die Smart-Room API (`claim_interaction` / `get_available_interactions`).


### Session Update (Pool Fixes & Live Monitor)
- **Fix (GuestActor):** Beim Betreten eines Smart Rooms (wie dem Pool) wurde `_action_timer` auf 0.0 gesetzt, was sofort den `_process_waiting`-Loop lahmlegte. GÃƒÂ¤ste blieben dauerhaft im Eingang stehen (Timer auf 0.01 korrigiert).
- **Feature (Pool):** `PoolSmall` nutzt im Live-Monitor nun die Iteration ÃƒÂ¼ber die Gruppe `guest_actors` anstatt der starren Auswertung von `_room_seats`, um wandernde/schwimmende GÃƒÂ¤ste korrekt zu erfassen.
- **Feature (Pool):** `get_available_interactions()` in `PoolSmall` ÃƒÂ¼berschrieben. `"wander"`-Aktionen werden gefiltert, damit GÃƒÂ¤ste am Pool entweder liegen oder schwimmen und nicht sinnlos in der Ecke stehen.
- **Feature (Pool):** Der Live-Monitor zeigt bei GÃƒÂ¤sten im Pool nun die verbleibende Aufenthaltszeit in Ingame-Minuten an (z.B. "Baden (74m)").


### Session Update (Pool Fixes & Live Monitor)
- **Fix (GuestActor):** Beim Betreten eines Smart Rooms (wie dem Pool) wurde `_action_timer` auf 0.0 gesetzt, was sofort den `_process_waiting`-Loop lahmlegte. GÃƒÂ¤ste blieben dauerhaft im Eingang stehen (Timer auf 0.01 korrigiert).
- **Feature (Pool):** `PoolSmall` nutzt im Live-Monitor nun die Iteration ÃƒÂ¼ber die Gruppe `guest_actors` anstatt der starren Auswertung von `_room_seats`, um wandernde/schwimmende GÃƒÂ¤ste korrekt zu erfassen.
- **Feature (Pool):** `get_available_interactions()` in `PoolSmall` ÃƒÂ¼berschrieben. `"wander"`-Aktionen werden gefiltert, damit GÃƒÂ¤ste am Pool entweder liegen oder schwimmen und nicht sinnlos in der Ecke stehen.
- **Feature (Pool):** Der Live-Monitor zeigt bei GÃƒÂ¤sten im Pool nun die verbleibende Aufenthaltszeit in Ingame-Minuten an (z.B. "Baden (74m)").

---
# Changelog Ã¢â‚¬â€œ gd-0.1.50
> Datum: 2026-08-31 | Branch: `dev`

---

## Refactoring & Architektur
- **Smart Room Logik:** `is_functional()` aus individuellen RÃƒÂ¤umen (Spa, Pool, Gym, Restaurant) in die Basisklasse `Room.gd` migriert.
- **is_functional() Edge-Case:** Die Logik prÃƒÂ¼ft nun, ob ein Mitarbeiter den Raum physisch besetzt ODER aktuell einen Arbeitsauftrag fÃƒÂ¼r den Raum ausfÃƒÂ¼hrt (z.B. Kellner holt Essen in der KÃƒÂ¼che). Verhindert, dass RÃƒÂ¤ume fÃƒÂ¤lschlicherweise als "Unterbesetzt" markiert werden, wÃƒÂ¤hrend Mitarbeiter arbeiten.
- **ÃƒÅ“bersetzungen Live-Monitor:** Harte Strings in den `get_live_details()` von Pool, Spa, Gym und Conference in saubere `GameState.T("poi...")` Keys umgewandelt und in `language.csv` eingetragen.

## Bugfixes & Tweaks
- **Staff Debug-Paths:** Footprints auf dem Grid blieben hÃƒÂ¤ngen, da `_get_staff_name()` beim LÃƒÂ¶schen fehlte. (Vorherige Session, aber hier festgehalten).
- **Gym Aufenthaltsdauer:** Gym hat nun einen eigenen Timer-Override in `GuestActor.gd` und dauert max 60-90 Ingame-Minuten (vorher 60-180 Min wie Pool/Spa).
- **String-Crash Fix:** Absturz in `ModalContentStaff.gd` beim Zuweisen von Personal (fehlender Translation-Key fÃƒÂ¼hrte zu Formatierungsfehler) behoben.


### 01.09.2026 - Pathfinding Fixes, Quests & UI Tooltips
- **Pathfinding Fix (Ghost Walking):** Behoben, dass GÃƒÂ¤ste bei der Abreise (`start_checkout`) geradlinig durch WÃƒÂ¤nde vom Bett zur TÃƒÂ¼r liefen. Das Problem lag daran, dass `_current_poi_id` auf `"lobby"` gesetzt wurde, bevor der Pfad berechnet wurde. Dadurch dachte das Spiel, der Gast sei bereits in der Lobby und ÃƒÂ¼bersprang die Berechnung des lokalen Weges aus dem Hotelzimmer heraus.
- **Quest-Tracking (POI-Nutzung):** Die Methode `QuestManager.on_poi_used` wurde zwar definiert, aber von `GuestActor` nie aufgerufen. GÃƒÂ¤ste informieren nun den QuestManager, wenn sie an einem POI eintreffen, sodass Quests wie "KÃƒÂ¼hles Nass" oder "AufwÃƒÂ¤rmen" korrekt hochzÃƒÂ¤hlen.
- **Quest-Tracking (Wildcards):** Fix im `QuestManager._increment_quest_progress`, damit generische Quests (ohne festes Ziel, d.h. `target_id == ""`), korrekt hochzÃƒÂ¤hlen. Die PrÃƒÂ¼fung vergleicht nun sauber, ob die Quest-Definition ÃƒÂ¼berhaupt ein `target_id` vorgibt.
- **Konferenzraum-Quest (BenÃƒÂ¶tigt Forschung):** Die Quest zum Bau des Konferenzraums in `quests.json` setzte fÃƒÂ¤lschlicherweise noch die veraltete Forschung `"B1.1"` voraus. Da dieser Knoten nicht mehr existiert, stockte der Quest-Fortschritt (und zeigte "BenÃƒÂ¶tigt Forschung: ???"). Dies wurde auf den korrekten Knoten `"P1.2"` aktualisiert.
- **Staff-Raum KapazitÃƒÂ¤t:** Fix in `StaffSmall.gd`. Die `has_free_seat` Methode liest die KapazitÃƒÂ¤t nun korrekt aus der Definition aus, was Clipping-Probleme in vollen PausenrÃƒÂ¤umen verhindert.
- **Raum-Tooltips (UI):** Tooltips (`CustomTooltip.gd`) bereinigt: Bei RÃƒÂ¤umen ohne Personalbedarf (`min_staff == 0`) verschwindet der Eintrag "Anwesende Mitarbeiter: 0" nun komplett (sofern kein Putzpersonal o.ÃƒÂ¤. anwesend ist). RÃƒÂ¤ume, die nicht fÃƒÂ¼r GÃƒÂ¤ste gedacht sind (z.B. KÃƒÂ¼che, `is_guest_poi == false`), zeigen keinen Platzhalter mehr fÃƒÂ¼r anwesende GÃƒÂ¤ste an.

### 02.09.2026 - Konferenz Event Fixes & UI Verbesserungen
- **Tagungs-GÃ¤ste Lobby Wait Position:** Event-GÃ¤ste sammeln sich vor Beginn nicht mehr am Checkout-Punkt (bzw. in der Wand, falls keine Rezeption existiert), sondern nutzen den AStar der Lobby, um sich locker im freien Raum zu verteilen (get_free_walkable_pos).
- **Tagungs-GÃ¤ste Lobby Wanderung:** Wenn die Event-GÃ¤ste vor 07:45 in der Lobby spazieren (_walk_to_poi('lobby')), nutzen sie nun ebenfalls einen zufÃ¤lligen internen Punkt der Lobby, anstatt fÃ¤lschlicherweise zum Korridor-Ausgangs-Tile zu navigieren und dort zu verharren.
- **AStar Debugging (Failed Paths) Fix:** Durch die vorherige fehlerhafte Zuweisung eines internen Lobby-Tiles an den globalen World-AStar entstanden kaputte Pfade (magenta Linien). Dies wurde durch saubere Trennung von get_target_tile() und lokalem Room-AStar behoben.
- **Lobby Live-Monitor:** TagungsgÃ¤ste erhalten in der Live-Monitor-Liste der Lobby nun automatisch ein angehÃ¤ngtes '(TG)', um sie sofort von normalen GÃ¤sten zu unterscheiden.
- **Lobby Live-Monitor Status-Genauigkeit:** GÃ¤ste, die am Vending Machine sind, zeigen nicht mehr pauschal 'Holt einen Snack' an. Wechselt ihr State auf EATING, steht dort korrekterweise 'Isst einen Snack'.
- **Object.get() Godot 4 Crash Fix:** Behebung eines Absturzes im Lobby-Monitor durch Aufruf von get('event_poi_id', '') auf dem GuestParty Objekt (nimmt in Godot 4 nur 1 Argument; korrigiert zu party.event_poi_id).
- **Raum-Tooltip TagungsgÃ¤ste:** Der Room-Tooltip ignoriert Event-GÃ¤ste nicht mehr. Die PrÃ¼fung vergleicht die _current_poi_id nun auch mit der instance_id des Event-Raums. AuÃŸerdem erhalten Event-GÃ¤ste im Tooltip ein '(TG)'.
- **CustomTooltip valid_states:** IDLE und WAITING_IN_LINE zu den  alid_states im CustomTooltip hinzugefÃ¼gt, damit wartende GÃ¤ste in der Tooltip-Statistik gezÃ¤hlt werden und mit dem LiveMonitor Ã¼bereinstimmen.
- **Fehlende Ãœbersetzungen:** poi.lobby.checking_out, poi.lobby.vending, poi.lobby.sitting und poi.lobby.eating_snack zur language.csv (DE & EN) hinzugefÃ¼gt, sodass keine rohen Keys mehr im HUD angezeigt werden.
- **Konferenz-Spawn Wellen:** Fehler in der while-Bedingung `GuestManager.spawn_conference_guests` korrigiert, sodass auch die 3. Welle (GÃ¤ste 9-12) das Hotel rechtzeitig erreicht.
- **Konferenz-PrioritÃ¤t:** `GuestActor._decide_next_action()` priorisiert zur Event-Zeit den Konferenzraum zwingend vor regulÃ¤ren POIs. Behebt den Bug, dass EventgÃ¤ste ziellos in der Lobby blieben.
- **Room Key Fixes:** Restliche `instance_id`-Ãœberbleibsel in `GuestActor._walk_to_poi()`, `CustomTooltip.gd` und der TÃ¼rsteher-Logik von `ConferenceSmall.gd` durch den sicheren persistenten `GuestManager._room_key` abgelÃ¶st. Verhindert Pathfinding- und Tooltip-Fehler.

### 03.09.2026 - ConferenceSmall Flow-Overhaul (Wander-Vorpuffer & Sitz-Logik)

#### Bugfixes
- **Speaker-Swap StabilitÃ¤t:** `_swap_speaker()` in `ConferenceSmall.gd` fÃ¼hrt den Rednertausch nun atomar durch (direktes Vertauschen der `occupied_by` Felder), ohne `release_interaction` + `_decide_next_action` aufzurufen. Behebt instabilen Zustand, der TG aus dem Raum geworfen hat.
- **Event-Raum Check (ID-Mismatch):** `is_in_event_room` in `GuestActor._process_waiting` verglich `party.event_poi_id` ("P0001") direkt mit `_current_poi_id` ("conference_small") â†’ immer false â†’ Kick-out-Loop. Fix: AuflÃ¶sung des Raum-Nodes Ã¼ber `_get_poi_room_node` und Vergleich via `_guest_manager._room_key()`.
- **`_current_poi_id` Typ-Fix:** `_walk_to_poi("P0001")` setzte `_current_poi_id = "P0001"` (Raumkey), wodurch `_get_poi_room_node` den Raum nicht finden konnte. Fix: `_current_poi_id` wird nun immer auf den POI-Typ aus der Definition gesetzt (`def.get("id")` = "conference_small").
- **Doppelter `var`-Deklaration:** Merge-Artifact erzeugte `var seat_pos` doppelt in `_walk_to_poi` â†’ Parsing Error. Bereinigt.
- **Double-Offset Bug (Wander-Pos):** `get_random_walkable_local_pos()` gibt bereits World-Koordinaten zurÃ¼ck (wie Room.gd Zeile 218 zeigt). ZusÃ¤tzliches `to_global()` in ConferenceSmall fÃ¼hrte zu Koordinaten weit auÃŸerhalb der Map. Entfernt.
- **State.IN_POI Zahl:** Live-Monitor nutzte `== 5` fÃ¼r IN_POI, korrekt ist `== 3` (IDLE=0, WALKING=1, IN_ROOM=2, IN_POI=3).
- **35â‚¬ visit_income fÃ¼r TG:** Event-GÃ¤ste zahlten fÃ¤lschlicherweise den `visit_income` (35â‚¬) beim Betreten des Tagungsraums. Diese Einnahme ist bereits Ã¼ber das Event-Budget abgedeckt. Fix: `income = 0` wenn `party.event_poi_id != ""`.

#### Features
- **Wander-Vorpuffer (07:45â€“08:00):** Tagungsraum Ã¶ffnet nun um 07:45 (`open_from: 465`). TG betreten den Raum ab 07:45 und wuseln darin bis 08:00 (`wander_pre`-Interaktion mit 0.5â€“2.5 min Zyklus), anstatt drauÃŸen zu warten.
- **Blickrichtung zum Speakertable:** Alle KonferenzstÃ¼hle setzen beim `claim_interaction` `look_at_pos` auf den Speakertable, sodass alle sitzenden TG in Richtung Redner schauen.
- **Live-Monitor Wander-Phase:** Live-Monitor zeigt nun auch wuselnde TG (ohne Sitzplatz) mit Status "..." in Grau an, damit der Monitor vor 08:00 nicht leer wirkt.


### 04.09.2026 - Konferenz Event Fixes & UI Verbesserungen
- **Konferenz-Gast EXP-Loop:** Bug behoben, bei dem wuselnde Tagungsgäste in einer Endlosschleife WALKING -> IN_POI hingen und jede Sekunde +30 EXP generierten. Der GuestActor prüft den korrekten Konferenzraum nun direkt beim GuestManager (party.event_poi_id) ab, anstelle des Schlafzimmers (_target_room).
- **Konferenzraum-Namensgebung:** Der Präfix in der ConferenceSmall.gd wurde von P (Personal) auf C geändert, um kuriose Zufallskollisionen (wie P0001) mit der intern generierten party_id (P%04d) zu vermeiden.
- **Live-Monitor UI:** Die Platzhalter-Anzeige (...) für Tagungsgäste, die vor Veranstaltungsbeginn im Raum wandern, durch den übersetzbaren String GameState.T('poi.conference.waiting') (Wartet / Waiting) aus language.csv ersetzt.



### 04.09.2026 - Session 3: Conference Break, Log-Cleanup, Tooltip-Fix & Restaurant-Debug

#### Log-Cleanup
- **GuestActor changed state:** Print auf Zeile 767 auskommentiert (groesster Log-Fluter, hunderte Zeilen pro Sekunde)
- **StaffActor changing to next_state:** Print auf Zeile 105 auskommentiert (zweiter Fluter)
- Im Log bleiben: [CONF-DEBUG], [TGCHANGE], [DEBUG RESTAURANT], Fehler/Abbruch-Prints und MapGrid-Path-Meldungen

#### Konferenz-Mittagspause (12:00 - 13:45)
- **go_conference_break():** Alle TG-Gaeste verlassen um 12:00 den Konferenzraum und gehen zu Lobby/Bar/Restaurant.
  `party.event_poi_id` wird temporaer geleert (Gaeste werden als normale Gaeste akzeptiert), gespeichert in `_conference_break_poi_key`.
- **return_from_conference_break():** Um 13:45 (TIME_BREAK_END=825) kehren TG-Gaeste zurueck. `event_poi_id` wiederhergestellt.
- **_broadcast_to_event_guests():** Hilfsmethode in ConferenceSmall - ermittelt alle Gaeste mit matching `event_poi_id` und ruft eine Methode auf ihrem GuestActor auf.
- **_start_break() / _end_break():** Phasen-Wechsel in ConferenceSmall (break -> wander_pm -> session_pm).
- **end_conference_day():** Um 17:00 - 50% gehen direkt heim, 50% noch Bar/Restaurant. `event_poi_id` wird geleert.

#### Hardcode-Sync
- `GuestActor._decide_next_action()` Zeile 631: Event-Zeit-Pruefung von `830` auf `825` korrigiert (sync mit TIME_BREAK_END in ConferenceSmall).

#### Tooltip Mismatch Fix (CustomTooltip.gd)
- Tooltip-Gaeste-Zaehler nutzte `ctrl._actors.values()` (konnte leer/null sein), Live-Monitor nutzte `get_nodes_in_group("guest_actors")`.
- Fix: Tooltip nutzt jetzt ebenfalls `get_nodes_in_group("guest_actors")`.
- WALKING wird jetzt mitgezaehlt, aber nur wenn `_current_poi_id` noch auf den angefragten Raum zeigt (Gast laeuft zum Tisch).

#### Restaurant Debug-Prints (Diagnose fuer Verschwinde-Bug)
- `RestaurantSmall.place_order_for_seat()` umgeschrieben mit praezisen Debug-Prints fuer jeden moeglichen Abbruchgrund:
  - Seat dirty statt clean
  - Seat nicht gefunden (occupied_by != guest_id)
  - Kein Waiter zugewiesen
  - Kueche geschlossen
  - Keine Rezepte im Budget
- Erlaubt beim naechsten Testlauf sofortige Diagnose.

#### Offener Bug (Cut mit offenem Ende)
- Gaeste verschwinden sofort aus Restaurant/Bar: Tooltip zeigt 0, Live-Monitor zeigt Gast.
- Naechster Schritt: Testlauf mit Debug-Prints -> Abbruchgrund identifizieren.
