# Changelog â€“ gd-0.1.50
> Datum: 2026-07-29 | Branch: `dev`

---

## Bugfixes

- **Parzelle â€“ Rechtsklick/Pan geblockt:** Der `build_overlay` (world-space `ColorRect` mit `mouse_filter = STOP`) lag Ã¼ber der gesamten Parzelle und fraÃŸ alle Mouse-Events. Behoben durch vollstÃ¤ndiges Entfernen des Overlays.
- **Parzelle â€“ Panel skalierte mit Zoom:** `build_overlay` war in World-Space und wuchs mit dem Kamera-Zoom. Behoben durch Entfernen des Overlays; Panel verbleibt auf dem CanvasLayer (Screen-Space) und skaliert nie.
- **Parzelle â€“ Panel unsichtbar nach Parzellenkauf:** `_process` lief nicht wÃ¤hrend Godots Pause-Modus (`PROCESS_MODE_INHERIT`). Dadurch wurde die Panel-Visibility nie auf `true` gesetzt. Behoben durch `process_mode = Node.PROCESS_MODE_ALWAYS` in `Parzelle._ready()`.
- **MapGrid â€“ Zoom nach Buy-Modus geblockt:** `exit_buy_mode()` rief `queue_free()` auf `_buy_overlay_root` auf, setzte die Variable aber nicht auf `null`. Da `is_instance_valid()` fÃ¼r queue_free'd Nodes noch `true` liefert, war `_on_input_camera_zoom()` weiterhin geblockt. Behoben durch `_buy_overlay_root = null` direkt nach `queue_free()`.
- **MapGrid â€“ `_show_built_parcels`:** Veralteter Zugriff auf `p.build_overlay` (existiert nicht mehr) entfernt. Panel-Visibility wird jetzt vollstÃ¤ndig von `Parzelle._process` Ã¼bernommen.

---

## Verbesserungen

- **ParzelleBuildUI â€“ Theme-konform:** `ParzelleBuildUI.tscn` komplett auf Standard-Theme-Variations umgestellt:
  - `theme_type_variation = "TooltipPanel"` (Hintergrund)
  - `theme_type_variation = "TooltipHeader"` (Titel-Label)
  - `theme_type_variation = "TooltipProgressBar"` (Fortschrittsbalken)
  - `theme_type_variation = "TooltipText"` (Zeit-Label)
  - Struktur identisch zu `CustomTooltip.tscn` (MarginContainer -> VBoxContainer -> HSeparator)
  - Alle hardcodierten Farben, FontgrÃ¶ÃŸen und StyleBoxes entfernt

### UI / Tutorials / Texte (Aktuelle Session)
- **Tutorial-Bilder:** Bilder fÃ¼r Kategorien GÃ¤ste, RÃ¤ume und Forschung um 30% verkleinert.
- **Tutorial-Texte RÃ¤ume:** Formatierung mit echten ZeilenumbrÃ¼chen in language.csv via Python-Skript eingefÃ¼gt.
- **Codex-Tabs:** Alten Codex-Tab in GÃ¤ste umbenannt, PrÃ¤fix Neuer GÃ¤stetyp: entfernt, neuen leeren Codex-Tab angehÃ¤ngt.
- **Techtree-Texte:** Python-Skript geschrieben, um abgeschnittene Techtree-Texte in language.csv zu reparieren (Kommas maskiert) und zerstÃ¶rte Umlaute zu korrigieren. Doppelte Keys entfernt.
- **Issue angelegt:** Issue fÃ¼r Automatisierung der Techtree-Texte in den Backlog aufgenommen.

### UI & QoL
- Techtree-Texte automatisiert: Voraussetzungen, Kosten und Freischaltungen generieren sich nun automatisch fÃ¼r Tooltip und Codex.
- Float-Rundungsfehler (z.B. Level 3.0 statt 3) im Techtree gefixt.
- CSV-Import repariert (versteckte ZeilenumbrÃ¼che).

### Codex & Techtree Tooltips (Aktuelle Session)
- **POI-Codex:** Neuen Codex-Eintrag fÃ¼r 'Point of Interest (POI)' in tutorials.json und language.csv angelegt.
- **Tutorials UI:** Platzhalter-Text aus dem 'Codex'-Reiter (ModalContentTutorials.gd) entfernt, sodass jetzt echte EintrÃ¤ge aus der Datenbasis geladen werden.
- **Techtree Tooltips:** Die Tooltips im Forschungsbaum (ModalContentTechtree.gd) ignorieren nun nicht mehr die schÃ¶nen Beschreibungstexte, sondern zeigen sie ganz oben an. Der generische 'Schaltet neue Inhalte frei'-Platzhalter wurde dafÃ¼r komplett entfernt.
- **Tooltip Word-Wrap:** Ein manueller Word-Wrap (_wrap_text) fÃ¼r die Techtree-Tooltips wurde implementiert, um den Godot 4 Bug zu umgehen, bei dem Tooltip-Panels bei extrem langen einzeiligen Texten (wie bei G1.2/G1.3) die Proportionen des Hintergrunds zerstÃ¶ren.
- **Tutorial-Texte:** Die harten Techtree-Voraussetzungen in den Tutorial-Beschreibungen wurden per Skript um die tatsÃ¤chlichen Namen erweitert (z.B. 'Techtree Z1.2 (Familienzimmer)').

### Techtree & UI (Fortsetzung)
- **Techtree Freischaltungen:** Funktionale Nodes (W1.1 Wellness-Bonus, P1.3 VIP-Gaeste und G1.4 Gourmetkueche) wurden aus dem demo_locked Status befreit und koennen nun erforscht werden.
- **Techtree Tooltips:** Die hartkodierten Platzhalter-Features fuer kuenftige Raeume (W1.2, W1.3, P1.2) aus den unlocks_features der JSON entfernt, da diese automatisch durch die Raum-Logik befuellt werden.
- **Room Hover Bug:** Einen Fehler behoben, bei dem Moebelstuecke (NavBlocker, Betten, Stuehle) die Mauseingaben blockierten und so den Raum-Hover-Effekt unterbrachen. Der Mouse-Filter wird nun fuer alle Moebel dynamisch und rekursiv auf IGNORE gesetzt - dies funktioniert nun auch fuer Multi-Tile Raeume wie das Doppelzimmer korrekt.
- **Grid-Verschmelzung (ANG-332):** Kaufbare Parzellen werden nun nicht mehr als separates Grid berechnet. Das MapGrid verschmilzt alle gekauften Parzellen dynamisch zu einem einzigen groÃŸen Grid. Der Nullpunkt wird beim Kauf einer Parzelle links/oben vom Hotel neu berechnet, wodurch Koordinaten fÃ¼r RÃ¤ume, Wegfindung und GÃ¤ste global eindeutig bleiben.
- **Tutorials & Codex (Dynamisch):** Die Liste der verfÃ¼gbaren RÃ¤ume im Codex wird nicht lÃ¤nger manuell gepflegt, sondern generiert sich zur Laufzeit automatisch aus den Definitionen aller baubaren RÃ¤ume (inkl. automatischer Fallback-Icons und Text-Zuordnungen).
- **Techtree P1.2:** Der Konferenzraum hat seinen Demo-Lock verloren und ist nun in der Alpha regulÃ¤r erforsch- und baubar.
- **Bugfixes & Polish:**
    - FloorLayer (Rasen) hat nun Z-Index -2 und wÃ¤chst nicht mehr optisch durch Hotel-Flure.
    - `room_category.business` (Ãœbersetzung) ergÃ¤nzt.
    - Fehlerhafter Pfad fÃ¼r `map-pin.svg` im Codex behoben.
    - Ungenutzte Parameter, Integer-Division-Warnungen und Ternary-Operator Typenwarnungen in MapGrid.gd und BuildCursor.gd beseitigt.
- **Multi-Tile-Room Nav-Bug:** Fehlerhafte Registrierung von MÃ¶beln (Betten) in gedrehten RÃ¤umen (Portrait) behoben. Das Spiel griff versehentlich immer auf die MÃ¶bel des Landscape-Nodes zu, wodurch Betten physikalisch auÃŸerhalb der RÃ¤ume (auf dem Flur) lagen und GÃ¤ste fÃ¤lschlicherweise durch WÃ¤nde auf den Flur schlafen geschickt wurden.
- **KÃ¼chenpersonal Pathfinding:** Interne Grid-AuflÃ¶sung (LOCAL_NAV_CELL_SIZE) in RÃ¤umen von 8 auf 4 Pixel erhÃ¶ht, damit das Kochen/Wandern zwischen groÃŸen NavBlocker-Boxen mÃ¶glich wird.
- **NavBlocker Debug-Overlay:** Das interne Debug-Overlay (SHOW_DEBUG_PATHS) zeichnet rote Kollisionsboxen und AStar-Punkte nun maÃŸstabsgetreu und Ã¼ber den MÃ¶beln auf dem korrekten Canvas-Layer.
- **Lokale Wegfindung:** Ein Fallback eingebaut, falls das interne AStar-Raster in einem Raum komplett blockiert ist (verhindert HÃ¤nger am TÃ¼r-Knoten).
- **Lokale Wegfindung Fixes:** Bug behoben, bei dem kurze Wege die Start-/Endpunkte Ã¼berschrieben haben (path_world[0]). Die Wegfindung fÃ¼gt Start- und Endpunkte nun korrekt ein.
- **StaffActor Wegfindung:** Mitarbeiter nutzen nun korrekt das interne AStar-Netz des Raumes, um zu ihrem get_work_position-Ziel zu navigieren, anstatt die MÃ¶bel auf einer geraden Luftlinie zu durchqueren.
- **KitchenSmall WorkArea:** %ChefWorkArea Marker wird nun korrekt ausgelesen und als dynamischer Arbeitsplatz mit Fallback (Raummitte) genutzt.
- **ServicePoint System:** Neues %ServicePoint Marker-System fÃ¼r RÃ¤ume eingefÃ¼hrt (Room.get_service_position()). ReinigungskrÃ¤fte und Hausmeister laufen nun in das Zimmer hinein zum Marker (oder in die Raummitte), anstatt von auÃŸen durch die TÃ¼r zu wischen.
- **POI-Verhalten & Wellness-Logik:** Rekursions-Bug in `GuestActor.gd` behoben, durch den GÃ¤ste den Pool sofort wieder verlieÃŸen. Tiefere Logik fÃ¼r Wellness-Aufenthalte implementiert (1-3 Ingame-Stunden Dauer, alle 15-30 Minuten Platzwechsel). POI-Limitierung fÃ¼r GÃ¤ste hinzugefÃ¼gt (`max_guests`). SchlieÃŸzeiten der POIs werden beim Aufenthalt berÃ¼cksichtigt.
- **Konferenzraum-Logik:** Chair12 als dediziertes Rednerpult konfiguriert. GÃ¤ste rotieren nun dynamisch ans Pult (10-15 Min Vortrag) und rÃ¤umen den Platz danach fÃ¼r den nÃ¤chsten.
- **Bademeister-Sitzposition:** `PoolSmall.gd` Rotation des Hochsitzes korrigiert (`+ PI/2.0`). Die optische Fehlplatzierung im Wasser liegt am Sprite-Offset.
- **Gym & Spa Initialisierung:** `claim_seat` in `GymSmall.gd` und `SpaSmall.gd` ergÃ¤nzt, um fehlgeschlagene Sitzplatzsuche der GÃ¤ste zu verhindern.
- **GuestActor Pool Exit:** Bug behoben (Geisterschweben), durch den GÃ¤ste beim Verlassen des Pools fÃ¤lschlicherweise den Restaurant-AStar fÃ¼r den Pool-Raum nutzten.
- **Bademeister Patrouille:** Radius-Berechnung in `StaffActor.gd` korrigiert (Plot-Tiles x 32px), damit er das gesamte Pool-Areal nutzt und nicht nur das obere linke Viertel und dadurch in MÃ¶bel navigiert.
- **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch Ã¼ber `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) fÃ¼r fehlende Voraussetzungen / falschen Zimmertyp integriert.
- **Pool-Patrouille Bademeister:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- **Debugger-Cleanup:** Godot-Warnings beim Start behoben (Shadowed Variables `is_active`/`ready`, Unused Signals in GameState/GuestManager, Integer Division in ParzelleBuildUI, sowie leere Tween-Errors in GuestActor gefixt).
- **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik fÃ¼r AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- **UI & Font Colors:** Harte Farbcodierungen in Skripten (`GuestFollowTooltip.gd` & `ModalContentGuestList.gd`) entfernt und stattdessen `StyleBoxFlat`-Ressourcen fÃ¼r Needs-Bars in den `.tscn`s eingerichtet. Schriftfarbe der Prozentzahlen in den Balken auf dunkelgrau gesetzt.
- **Language CSV Encoding:** UTF-8 BOM Fehler behoben, welcher Umlautfehler bei 'SpaÃŸ' verursachte. Lokalisierte Keys ("HU", "DU", "EN", "SP") hinzugefÃ¼gt.
- **GÃ¤stelisten Live-Sync Fix:** `ModalContentGuestList.gd` komplett Ã¼berarbeitet, sodass die GÃ¤steliste und der Detailbereich nun 100% synchron und fehlerfrei aktualisiert werden. Der ID-Vergleichs-Bug `member.id == _selected_guest.get("id")` (der Gast hat keine "id") wurde zu einem direkten Actor-Vergleich korrigiert. Zudem aktualisiert die Liste nun auch das Budget (`member.spending_budget`) live pro Frame und wertet die States wie EATING/SLEEPING korrekt zum jeweiligen `_current_poi_id` bzw. Zimmer auf.

---

### Wellness & GÃ¤stebedÃ¼rfnisse (Session 2026-08-11)

- **POI Need-Restoration:** `need_restoration`-Dictionary in POI-Definitionen (Spa, Pool, Gym, Bar) vollstÃ¤ndig implementiert. GÃ¤ste erhalten beim Verlassen eines POIs die definierten Stat-VerÃ¤nderungen (`energy`, `fun`, `saturation`, `thirst`). Negative Werte (z.B. `energy: -10` fÃ¼r Schwimmen) werden korrekt angewandt â€“ GÃ¤ste werden nach intensiver AktivitÃ¤t spÃ¼rbar mÃ¼der.
- **SpaSmall KapazitÃ¤t:** Max. GÃ¤ste-KapazitÃ¤t von 4 auf 6 erhÃ¶ht.
- **SpaSmall Patrouille:** Patrol-Intervall des Bademeister-Ã¤quivalents auf 20 Sekunden gesetzt, um unnÃ¶tige Unruhe zu vermeiden.

### Gast-Pathfinding & Spawn (Session 2026-08-11)

- **Gast Spawn-Fix (Lobby) â€“ Root Cause behoben:** `Path failed: SOLID`-Fehler beim GÃ¤ste-Spawn vollstÃ¤ndig eliminiert. Die Ursache: Reception-Waypoints (Tresen-Wartepunkte) liegen ausserhalb der Lobby-Clearance und sind daher im globalen AStar als solid markiert. Der bisherige Code versuchte, GÃ¤ste zu diesen solid Tiles zu bewegen â†’ Fehler.
  - **Neue LÃ¶sung:** `start_waiting_in_lobby()` platziert neue GÃ¤ste nun direkt (Teleport) an einem Reception-Waypoint. Kein Walk-Pfad nÃ¶tig, da das Rezeptions-Modal den Bildschirm verdeckt. ZusÃ¤tzlich: GÃ¤ste erscheinen jetzt sofort sichtbar in der Lobby, sobald die Toast-Meldung â€žNeue GÃ¤ste" erscheint.
  - **Check-in Flow:** Nach Check-in nutzen GÃ¤ste die lokale Lobby-Navigation (NavMesh) zur InnentÃ¼r, dann den globalen AStar durch den Korridor zum Zimmer.
- **GuestActor `_execute_walk`:** `State.WAITING_IN_LINE` in den Bedingungsblock fÃ¼r lokalen Pfad-aus-Raum aufgenommen, damit der Lobby-LOCAL-Pfad korrekt beim Check-in triggert.
- **GuestActor `_walk_to_room`:** Wenn der Gast aus dem `WAITING_IN_LINE`-State kommt (an der Rezeption), wird `lobby.get_target_tile()` als Startpunkt fÃ¼r den globalen AStar-Pfad genutzt (statt des solid Waypoint-Tiles).
- **MapGrid:** `is_tile_walkable(tile)` und `find_nearest_walkable_tile(tile, max_radius)` als public Hilfsmethoden ergÃ¤nzt.

### Quests & Systeme (Session 2026-08-13)

- **Quests & QuestManager (ANG-336):** Neue Quests fÃ¼r Gastronomie (Baue Bar, KÃ¼che, Restaurant, Koche/Serviere X Gerichte) in `quests.json` hinzugefÃ¼gt und dynamisches Quest-Tracking (`_increment_quest_progress`, `_check_quest_threshold`) im `QuestManager` implementiert (z.B. fÃ¼r POI Nutzung, Tagesabschluss, gekochtes Essen).
- **Events & DevConsole:** Event-Status wird nun im Savegame (`event_data`) Ã¼ber `SaveManager` und `EventManager` gespeichert. `DevConsole` um `set-conference:on/off` (manuelles Triggern des Tagungs-Events) und `add-guest-budget` erweitert.
- **Icons & Assets:** Zahlreiche neue Pixel-Art Icons fÃ¼r RÃ¤ume (Bar, Betten, Konferenzraum, Gym, Spa) und das Overlay-Toolbar (Brush, Cat, Usage, Value, Wrench) hinzugefÃ¼gt.
- **Dokumentations-Richtlinien:** `AGENTS.md` um Dokumentationspflicht nach Tests erweitert. `update_doku` Skill angepasst.

### Bugfixes & Persistenz (Session 2026-08-13 â€“ Abend)
- **Tagesgäste (Day Guests) Fixes:** Tagesgäste dürfen keine exklusiven Hotel-Einrichtungen (Pool, Gym, Spa) mehr nutzen. Sie verfallen nun auf die Lobby als Wartebereich zurück anstatt bei ausgebuchten POIs abzureisen. Die Wartezeit bei noch geschlossenen Events wurde von 15-45 auf 5-10 Ingame-Minuten reduziert.
- **Tagesgäste Spawn:** Spawnen nun unsichtbar und werden korrekt in den Wartebereich (Lobby) teleportiert (start_waiting_for_event).
- **Tooltip Anpassung:** Tagesgäste werden nun zur eindeutigen Unterscheidung im Tooltip mit dem Zusatz (Tagesgast) markiert.
- **GuestActor Fallback:** Logik für claim_seat bzw. 
oom_claim_seat in _walk_to_poi korrigiert und Lobby-Wander-Fallback hinzugefügt. State.IDLE zur lokalen Wegfindungs-Abfrage in _execute_walk hinzugefügt.

- **Upgrade-Persistenz Fix (`acquired_traits`):** Zimmer-Upgrades (WLAN, Klima) gingen nach Speichern und Neuladen verloren. Root Cause: `Ingame.gd` rief nach dem Laden nochmals `room.configure({guest_manager: ...})` auf alle platzierten RÃ¤ume auf, was in `Room.gd` den `else`-Zweig triggerte und `acquired_traits = []` resetzte â€“ obwohl die Traits korrekt aus dem Savegame geladen wurden. Fix: `configure()` setzt `acquired_traits` nur noch zurÃ¼ck, wenn der Key `acquired_traits` tatsÃ¤chlich im Ã¼bergebenen Dictionary enthalten ist (`elif data.has("acquired_traits"):`).

### UI-Verbesserungen (Session 2026-08-13 â€“ Abend)

- **POI Tooltip â€“ Ã–ffnungszeiten:** Tooltip geÃ¶ffneter POIs zeigt jetzt die konkreten Ã–ffnungszeiten: â€žðŸº GeÃ¶ffnet (08:00 - 22:00 Uhr)" statt dem generischen â€žðŸº GeÃ¶ffnet".

### Lobby Check-In Flow (Session 2026-08-14)

- **Gast sichtbar an Rezeption:** `start_waiting_in_lobby()` platziert GÃ¤ste nun sofort per Teleport an einem zufÃ¤lligen `receptionX`-Waypoint in der Lobby. Der Gast ist unsichtbar wÃ¤hrend der Staffelung (delay) und erscheint dann direkt sichtbar stehend an der Rezeption (`WAITING_IN_LINE`). Kein fehlerhafter Walk-Pfad durch die solide Lobby-FlÃ¤che mehr.
- **Check-in Walk korrekt:** Nach BestÃ¤tigung des Check-ins nutzt der Gast die **lokale Lobby-Navigation** (Room.gd AStar2D) von seiner receptionX-Position zur Lobby-InnentÃ¼r, dann den **globalen Korridorpfad** zum Zimmer. Kein Durchlaufen von MÃ¶beln oder WÃ¤nden mehr.
- **`previous_state` Fix in `_walk_to_room`:** `_change_state(WALKING)` Ã¼berschrieb `previous_state` (von `WAITING_IN_LINE` auf `WALKING`), bevor `_execute_walk` ihn auslesen konnte. Fix: `previous_state` wird vor dem `_change_state`-Aufruf gesichert und danach wiederhergestellt.
- **Reload-Fix:** `GuestController.spawn_active_guests()` iteriert nun auch Ã¼ber `_guest_manager._waiting` und platziert wartende GÃ¤ste nach einem Spielstand-Reload sichtbar an der Rezeption.


### Conference Flow & POI Pathing Fixes (Session 2026-08-14)
- **Conference Flow & Tweens:** Instant-Teleport zum Rednerpult (Chair12) durch animierten _execute_poi_move() Tween ersetzt. Cooldown von 10-15 Ingame-Minuten nach dem Reden eingebaut, damit der Redner nach dem ZurÃ¼cktreten nicht sofort wieder ans Pult rennt.
- **POI Leave Pathing Fix:** GÃ¤ste, die im Status STUDYING_MENU oder WAITING_FOR_FOOD einen POI verlieÃŸen (z.B. weil dieser schlieÃŸt), ignorierten das lokale AStar-Grid und liefen Luftlinie durch WÃ¤nde (Skipped local_path_out). Diese Gastro-States wurden in _execute_walk zur lokalen Pfadgenerierung hinzugefÃ¼gt.

### Offen / NÃ¤chste Session
- **WLAN/Klima-Overlays in OverlayToolbar:** Zwei neue Overlay-Buttons (WLAN-Abdeckung, Klima-Abdeckung) mit Rot/GrÃ¼n-Indikator pro Raum in die HUD-Toolbar integrieren.

### Ingame & Navigation (Aktuelle Session)
- **Bar/Gastro Einlauf-Animation:** Gäste teleportieren nicht mehr unsichtbar an den Platz, sondern laufen nach dem Eintreten sichtbar durch den Raum zum Hocker.
- **Gym/Pool/Spa Sichtbarkeit:** Unsichtbarkeit-Bug an Trainingsgeräten und im Wasser behoben.
- **GuestActor Navigation-Refactoring:** _get_logical_start_tile() komplett überarbeitet. Die Start-Kachel-Ermittlung aus POIs funktioniert nun generisch und robust über _current_poi_id. Verhindert SOLID-Fehler bei unerwarteten Statuswechseln (z. B. Bettzeit um 23:00 Uhr während Wartezeit in Restaurant).

### UI / Finanzen (Aktuelle Session)
- **Kassenbuch Gastro-Namen:** Fehlende Rezeptnamen in Gastro-Kassenbucheinträgen () repariert (Key 
ame_key statt 
ame verwendet).
- **Kassenbuch Checkout-Details:** Checkout-Logs um Zimmertyp und Aufenthaltsdauer erweitert. ModalContentFinances.gd unterstützt nun dynamische Anzahl an Platzhaltern in der Übersetzung.

### Ingame & Navigation (Aktuelle Session 2)
- **Smart Room / GuestActor State Machine Fix:** Schwerwiegender Bug in GuestActor._process_waiting behoben. Der 'Toter Gast'-Fehler nach dem Laden eines Spielstands entstand, weil der ablaufende Action-Timer im Status IN_ROOM oder IDLE komplett ignoriert wurde, was zu einem ewigen Early-Return im nächsten Frame führte. Es wurde eine Fallback-Logik (else-Branch) hinzugefügt, die _decide_next_action() korrekt aufruft.
- **Smart Room Migration:** SpaSmall, GymSmall, PoolSmall und ConferenceSmall bereiten sich auf Smart Room Migration vor (Dokumentation aktualisiert).
- **Guest Spawn:** Gäste spawnen nun am receptionX Wegpunkt und nicht auf der Straße (keine Animation beim Betreten, direktes Warten).

### Ingame & Navigation (Aktuelle Session 3)
- **Smart-Room API Integration:** Room.gd Basisklasse um generische Methoden (get_available_interactions, claim_interaction, 
elease_interaction) erweitert. GuestActor._wander_in_room und _change_state darauf umgestellt, um alte Hardcoded-Logik (Betten/Sitze) aufzulösen und Race-Conditions bei der Freigabe von Interaktionen zu vermeiden.
- **Vending Machine Walk-Target Fix:** Bug in GuestActor._walk_to_poi behoben, der dazu führte, dass Gäste den Getränkeautomaten-POI mit freien Sitzplätzen in der Lobby (Lobby als Room hat has_free_room_seat() == true geerbt) verwechselten und sich stattdessen unten rechts auf einen Sofa-Platz setzten, um dort die Automat-Interaktion (und Animation) abzuspielen. Vending Machine hat nun Priorität vor der Sitzplatz-Suche.
- **Lobby Special Nodes:** _find_special_nodes in Lobby.gd präzisiert, sodass Container wie Chairs oder Deskchairs nicht mehr fälschlicherweise als SnackPoint registriert werden.
-   * * S m a r t R o o m   B a r   M i g r a t i o n : * *   G a s t - S i t z p l a t z - Z u w e i s u n g   r e p a r i e r t .   G s t e   s t a p e l n   s i c h   n i c h t   m e h r   a u f   d e m   F a l l b a c k - P u n k t ,   s o n d e r n   b l o c k i e r e n   S i t z p l t z e   s a u b e r   b e r   c l a i m _ i n t e r a c t i o n ,   b e v o r   s i e   l o s l a u f e n . 
 
 -   * * G u e s t A c t o r   S t a t e - F l o w   ( B a r ) : * *   S t a t e   E A T I N G   r u f t   n u n   k o r r e k t   r e l e a s e _ i n t e r a c t i o n   a u f ,   d a m i t   S m a r t R o o m - P l t z e   w i e d e r   f r e i g e g e b e n   w e r d e n . 
 
 
### Personal & StaffActor Fixes
- **StaffActor Z-Index & Map Sichtbarkeit:** StaffActor Z-Index auf 100 erhöht, damit Personal über dem NavGrid gerendert wird. configure() Methode angepasst, damit spawn_room beim Start übergeben und gespeichert wird, was den verbuggten Lobby-Teleport direkt nach dem Spawn (und das Flackern auf der Karte) verhindert.
- **StaffActor Logging & State-Machine Bereinigung:** Die Log-Ausgaben im Stil von GuestActor in StaffActor mittels eines zentralen _set_state-Wrappers komplett wiederhergestellt (mit korrektem Vornamen/Nachnamen Parsing). Einen redundanten Mikrosekunden-Switch auf working während des "Chillings" (walking) behoben.
- **StaffActor Idle Timer:** Den Timer für den Sitzplatzwechsel im Pausenraum (_process_resting) von 2% auf realistische 10% (alle 2 Sekunden) erhöht, damit das Personal lebendiger wirkt.
- **StaffSmall & Raumsitze-Kapazität:** Kapazitäts-Check has_free_seat() bei Personal-Räumen gefixt, um zu verhindern, dass Staff-Actors in einen überfüllten Pausenraum spawnen. Smart-Room Interaktionen in Room.gd und StaffSmall.gd überprüft.
- **Staff-Aufgaben Annahme:** Validierung und Logging des Service-Rufen Buttons. Die Wegfindung zu Zielräumen wurde stabilisiert, und Tasks (clean_room, 
epair_room) werden zuverlässig angenommen und ausgeführt.
- **SmartRoom Bar Migration:** Gast-Sitzplatz-Zuweisung repariert. Gäste stapeln sich nicht mehr auf dem Fallback-Punkt, sondern blockieren Sitzplätze sauber über `claim_interaction`, bevor sie loslaufen.
- **GuestActor State-Flow (Bar):** State EATING ruft nun korrekt `release_interaction` auf, damit SmartRoom-Plätze wieder freigegeben werden.

### Personal & StaffActor Fixes
- **StaffActor Z-Index & Map Sichtbarkeit:** `StaffActor` Z-Index auf 100 erhöht, damit Personal über dem NavGrid gerendert wird. `configure()` Methode angepasst, damit `spawn_room` beim Start übergeben und gespeichert wird, was den verbuggten Lobby-Teleport direkt nach dem Spawn (und das Flackern auf der Karte) verhindert.
- **StaffActor Logging & State-Machine Bereinigung:** Die Log-Ausgaben im Stil von `GuestActor` in `StaffActor` mittels eines zentralen `_set_state`-Wrappers komplett wiederhergestellt (mit korrektem Vornamen/Nachnamen Parsing). Einen redundanten Mikrosekunden-Switch auf `working` während des "Chillings" (`walking`) behoben.
- **StaffActor Idle Timer:** Den Timer für den Sitzplatzwechsel im Pausenraum (`_process_resting`) von 2% auf realistische 10% (alle 2 Sekunden) erhöht, damit das Personal lebendiger wirkt.
- **StaffSmall & Raumsitze-Kapazität:** Kapazitäts-Check `has_free_seat()` bei Personal-Räumen gefixt, um zu verhindern, dass Staff-Actors in einen überfüllten Pausenraum spawnen. Smart-Room Interaktionen in `Room.gd` und `StaffSmall.gd` überprüft.
- **Staff-Aufgaben Annahme:** Validierung und Logging des Service-Rufen Buttons. Die Wegfindung zu Zielräumen wurde stabilisiert, und Tasks (`clean_room`, `repair_room`) werden zuverlässig angenommen und ausgeführt.

### Ingame & Navigation (Aktuelle Session 4)
- **GuestActor Navigation:** Fehlendes Exit-Pathing fr Gste repariert, deren Zielort auf dem identischen (oder direkt benachbarten) Global-Grid-Tile lag. Ohne globalen Weg ignorierten Gste die lokale Tr und liefen Luftlinie durch Wnde. _execute_walk prft nun generisch current_room != target_room statt path_tiles.size() > 0.

### Ingame & Navigation (Aktuelle Session 5)
- **MapGrid Teleport-Fix:** Workaround fr SOLID Start- und End-Tiles in MapGrid.gd eingebaut. Die Wegfindung schlgt nicht mehr sofort fehl, wenn der Gast auf oder neben einem Hindernis steht, was die unsichtbaren Notfall-Teleports aus Rumen heraus verhindert.
- **Room.gd INF-Bug:** Fehler in get_local_path behoben, der Gste (z. B. in der Bar) beim ziellosen Eintreten (Vector2.INF) an den hintersten verfgbaren Punkt (hinter den Tresen) fhrte. Gste bleiben nun wie vorgesehen an der Tr stehen, bis sie ein konkretes Ziel haben.
- **GuestActor Bar Loop:** Logik in _decide_next_action erweitert: Gste whlen nicht mehr ihren aktuellen POI als nchstes Ziel, um Endlos-Schleifen im selben Raum zu vermeiden.


### 23.08.2026 - Pathfinding Fixes (End of Session)
- **Bugfix:** GuestActor teleportiert bei fehlendem Pfad zur Zimmertür.
- **Bugfix:** Room.gd ersetzt bei INF-Zielen das Ziel durch einen gültigen AStar Punkt im Raum, um Gäste-Wand-Clipping in der Lobby zu verhindern.
- **Logs:** `push_warning` für Pfad-Fehlschläge zu regulärem `print` geändert.
- **Logs:** GuestActor loggt nun reguläre Status-Wechsel (`_change_state`) analog zum StaffActor.
- **Debug:** MapGrid gibt nun bei AStar-Fehlschlägen auf derselben X-Achse die Tile-Solidity für jedes Tile auf der Achse aus.
- **Translation:** Fehlender Key `roomdef.name.long.lobby` in `language.csv` ergänzt.

### 25.08.2026 - Pathfinding Root-Cause Fix & Debug-System

#### Bugfixes
- **Notfall-Teleport Root-Cause behoben:** Gäste, die nach dem Essen am Snackautomaten zurück in ihr Zimmer wollten, wurden mit `_current_poi_id = "lobby"` gespeichert. Die Bedingung `_current_poi_id != "lobby"` in `_get_logical_start_tile()` übersprang den POI-Door-Lookup, sodass die physische Position (tief im soliden Lobby-Körper) als Start genutzt wurde → Pfadfehler → Notfall-Teleport.
  - **Fix:** Bedingung auf `not _current_poi_id.is_empty()` reduziert (kein Lobby-Ausschluss mehr). Damit liefert `lobby.get_target_tile()` korrekt die Lobby-Innentür `(4, 39)` als Start.
- **Safety-Fallback eingebaut:** `_get_logical_start_tile()` prüft nach der Tile-Berechnung, ob das Ergebnis solid ist. Falls ja, wird als letzter Ausweg die Lobby-Innentür genutzt (loggt `[GuestActor] Safety fallback: ...`).
- **`_get_closest_walkable_tile` Limitation:** Funktion sucht nur Radius 1–2; falls Gast tief im Lobby-Körper sitzt, wird das solid Original-Tile zurückgegeben → kein Pfad. Safety-Fallback fängt diesen Zustand nun ab.

#### Debug-System (MapGrid & GuestActor)
- **MapGrid `_debug_paths` Format:** Von `Array[Array]` auf `Array[Dictionary]` umgestellt (`{path, label}`), um den auslösenden Akteur pro Pfad zu speichern.
- **`get_path_between_tiles()` Debug-Label:** Neuer optionaler Parameter `debug_label: String = ""`. Alle `GuestActor`-Aufrufe übergeben `_guest_member.get("name")` als Label.
- **Visuelle Pfad-Beschriftung:** `MapGrid._draw()` zeichnet jeden Pfad mit grünem Startkreis, rotem Zielkreis und weißem Label-Text (Gastnamen) direkt auf der Map.
- **Konsolen-Log pro Pfad:** Jeder erfolgreiche Pfad loggt `[MapGrid] Path OK: <Name> | <start> -> <end> len=<N>`.
- **`DebugOverlay.gd` deaktiviert:** Das veraltete `DebugOverlay._draw()` (nutzte alten `WALK_W * TILE_PX` Offset = ursprünglicher Overlay-Bug) ist nun leer. `MapGrid._draw()` übernimmt das gesamte Debug-Rendering mit korrekter `to_local(tile_to_world())` Transformation.
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
