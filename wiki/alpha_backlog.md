# HOÂ·MAÂ·SIM â€“ Alpha Backlog & Roadmap
> Branch: `dev` | Start: v0.1.40 | Aktuell: v0.1.50 | Stand: 2026-07-29
> Bibel fÃ¼r die Alpha-Phase. Vor jeder Umsetzung hier nachschlagen!

---

## âš ï¸ Getroffene Design-Entscheidungen (nicht mehr diskutieren!)

- **Personalflure:** Kommen NICHT in die Alpha. Grund: wÃ¼rde auf altem 1-Layer-Nav aufbauen â†’ BrÃ¼ckencode. Kommen zusammen mit dem Nav-Rework (3 Layer: GÃ¤ste / Personal / Rauminneres + feineres Grid).
- **KÃ¼che/Restaurant Alpha:** Nur eine TÃ¼r (GÃ¤ste-Eingang). Zweite TÃ¼r (Personaleingang) kommt mit Personalflur-Feature.
- **Branching:** `master` = TechDemo-Bugfixes. `dev` = Alpha-Entwicklung. Nach TechDemo-Fix immer kurz `git merge master` in `dev`.

---

## ðŸ›  Ungeplante Fixes & Features (Aktuelle Session)
- **Smart-Room API Integration:** `Room.gd` Basisklasse um generische Methoden (`get_available_interactions`, `claim_interaction`, `release_interaction`) erweitert. `GuestActor._wander_in_room` und `_change_state` darauf umgestellt, um alte Hardcoded-Logik (Betten/Sitze) aufzulösen und Race-Conditions bei der Freigabe von Interaktionen zu vermeiden.
- **Vending Machine Walk-Target Fix:** Bug in `GuestActor._walk_to_poi` behoben, der dazu führte, dass Gäste den Getränkeautomaten-POI mit freien Sitzplätzen in der Lobby (Lobby als Room hat `has_free_room_seat() == true` geerbt) verwechselten und sich stattdessen unten rechts auf einen Sofa-Platz setzten, um dort die Automat-Interaktion (und Animation) abzuspielen. Vending Machine hat nun Priorität vor der Sitzplatz-Suche.
- **Lobby Special Nodes:** `_find_special_nodes` in `Lobby.gd` präzisiert, sodass Container wie `Chairs` oder `Deskchairs` nicht mehr fälschlicherweise als `SnackPoint` registriert werden.
- **Smart Room / GuestActor State Machine Fix (2026-08-16):** Schwerwiegender Bug in `GuestActor._process_waiting` behoben. Der "Toter Gast"-Fehler nach dem Laden eines Spielstands entstand, weil der ablaufende Action-Timer im Status `IN_ROOM` oder `IDLE` komplett ignoriert wurde, was zu einem ewigen Early-Return im nächsten Frame führte. Es wurde eine Fallback-Logik (else-Branch) hinzugefügt, die `_decide_next_action()` korrekt aufruft.
- **Upgrade-Persistenz Fix (acquired_traits):** Tief verwurzelter Bug behoben, durch den gekaufte Zimmer-Upgrades (WLAN, Klima) nach dem Speichern und Neuladen verloren gingen. Ursache: `Ingame.gd` rief nach dem Laden nochmals `configure({guest_manager: ...})` auf alle RÃ¤ume auf und wischte damit die bereits geladenen Traits weg. LÃ¶sung: `configure()` in `Room.gd` setzt `acquired_traits` nur noch zurÃ¼ck, wenn der Key `acquired_traits` tatsÃ¤chlich im Ã¼bergebenen Dictionary enthalten ist.
- **POI Tooltip â€“ Ã–ffnungszeiten:** Der Tooltip geÃ¶ffneter POIs zeigt nun die Ã–ffnungszeiten an ("ðŸ º GeÃ¶ffnet (08:00 - 22:00 Uhr)") statt nur "GeÃ¶ffnet".
- **DevConsole & EventManager:** Savegame-Support fÃ¼r Events und manuelle Trigger (set-conference) fÃ¼r Testzwecke in DevConsole.
- **Assets:** Neue Pixel-Art Icons fÃ¼r RÃ¤ume und Overlay-Tools hinzugefÃ¼gt.
- **Dokumentation:** `AGENTS.md` um Dokumentationspflicht erweitert.
- **POI Need-Restoration:** `need_restoration` fÃ¼r POI-Aufenthalte implementiert. GÃ¤ste erhalten nach Besuch im Spa, Pool, Gym, Bar Stat-VerÃ¤nderungen (energy, fun, saturation, thirst). Negative Werte (z.B. Energie sinkt nach Schwimmen) werden korrekt angewandt.
- **SpaSmall KapazitÃ¤t & Patrouille:** Max. GÃ¤ste von 4 auf 6 erhÃ¶ht. Patrol-Intervall auf 20 Sekunden gesetzt.
- **Gast Spawn-Fix (Lobby):** `Path failed: SOLID`-Fehler beim GÃ¤ste-Spawn vollstÃ¤ndig behoben. Ursache: Reception-Waypoints liegen physisch ausserhalb der Lobby-Clearance (= im globalen AStar solid). LÃ¶sung: GÃ¤ste werden beim Spawn direkt an einem Reception-Waypoint platziert (kein Walk-Pfad nÃ¶tig, da Rezeptionsmodal alles verdeckt). Nach Check-in nutzen sie lokale Lobby-Navigation zur InnentÃ¼r, dann globaler AStar zum Zimmer.
- **GuestActor _execute_walk:** `WAITING_IN_LINE` in den Check fÃ¼r lokalen Pfad-aus-Raum aufgenommen, damit Lobby-LOCAL-Navigation beim Check-in korrekt triggert.
- **MapGrid Hilfsfunktionen:** `is_tile_walkable()` und `find_nearest_walkable_tile()` als public Hilfsmethoden ergÃ¤nzt (fÃ¼r zukÃ¼nftige Fallback-Szenarien).
- **GuestActor Logging:** SPA-ENTRY Debug-Prints (energy/fun/sat/thirst bei Eintritt) hinzugefÃ¼gt fÃ¼r Needs-Verifikation.
- **POI-Verhalten & Wellness-Logik:** Rekursions-Bug in `GuestActor.gd` behoben, durch den GÃ¤ste den Pool sofort wieder verlieÃŸen. Tiefere Logik fÃ¼r Wellness-Aufenthalte implementiert (1-3 Ingame-Stunden Dauer, alle 15-30 Minuten Platzwechsel). POI-Limitierung fÃ¼r GÃ¤ste hinzugefÃ¼gt (`max_guests`). SchlieÃŸzeiten der POIs werden beim Aufenthalt berÃ¼cksichtigt.
- **Konferenzraum-Logik:** Chair12 als dediziertes Rednerpult konfiguriert. GÃ¤ste rotieren nun dynamisch ans Pult (10-15 Min Vortrag) und rÃ¤umen den Platz danach fÃ¼r den nÃ¤chsten.
- **Bademeister-Sitzposition:** `PoolSmall.gd` Rotation des Hochsitzes korrigiert (`+ PI/2.0`). Die optische Fehlplatzierung im Wasser liegt am Sprite-Offset.
- **Gym & Spa Initialisierung:** `claim_seat` in `GymSmall.gd` und `SpaSmall.gd` ergÃ¤nzt, um fehlgeschlagene Sitzplatzsuche der GÃ¤ste zu verhindern.
- **KÃ¼chenpersonal Pathfinding:** Interne Grid-AuflÃ¶sung (`LOCAL_NAV_CELL_SIZE`) in RÃ¤umen von 8 auf 4 Pixel erhÃ¶ht. Damit wurde behoben, dass das KÃ¼chen-Wegenetz durch groÃŸe NavBlocker (Herd/Fritteusen) im 8x8-Raster komplett unterbrochen wurde.
- **NavBlocker Debug-Overlay:** Das interne Debug-Overlay (`SHOW_DEBUG_PATHS`) zeichnet rote Kollisionsboxen und AStar-Punkte nun maÃŸstabsgetreu auf einem CanvasLayer (`z_index = 100`) Ã¼ber den MÃ¶beln und respektiert Raumrotationen korrekt.
- **Lokale Wegfindung Fixes:** Bug behoben, bei dem kurze Wege die Start-/Endpunkte Ã¼berschrieben haben (`path_world[0]`). Die Wegfindung fÃ¼gt Start- und Endpunkte nun korrekt ein.
- **StaffActor Wegfindung:** Mitarbeiter nutzen nun korrekt das interne AStar-Netz des Raumes, um zu ihrem `get_work_position`-Ziel zu navigieren, anstatt die MÃ¶bel auf einer geraden Luftlinie zu durchqueren.
- **KitchenSmall WorkArea:** `%ChefWorkArea` Marker wird nun korrekt ausgelesen und als dynamischer Arbeitsplatz mit Fallback (Raummitte) genutzt.
- **ServicePoint System:** Neues `%ServicePoint` Marker-System fÃ¼r RÃ¤ume eingefÃ¼hrt (`Room.get_service_position()`). ReinigungskrÃ¤fte und Hausmeister laufen nun in das Zimmer hinein zum Marker (oder in die Raummitte), anstatt von auÃŸen durch die TÃ¼r zu wischen.
- **ANG-324:** Abriss-Blockade fÃ¼r PausenrÃ¤ume eingebaut (Max. KapazitÃ¤t vs. Staff-Count).
- **ANG-325 / ANG-326:** GÃ¤ste-Quests fÃ¼r jeden Gasttyp eingebaut (10, 25, 50, 100).
- Float-Rundungsfehler bei Forschungspunkten gefixt & WÃ¤hrungssymbole ergÃ¤nzt.
- âœ… **ParzelleBuildUI â€“ KomplettÃ¼berarbeitung:** Panel auf CanvasLayer (Screen-Space) umgestellt, Theme-Variations wie CustomTooltip, `process_mode = ALWAYS` fÃ¼r Pause-Support, `build_overlay` (world-space, blockierend) entfernt, Zoom-Fix in `exit_buy_mode` (`_buy_overlay_root = null`).
- âœ… **Techtree-Texte automatisiert:** Kosten, Voraussetzungen und "Schaltet frei" generieren sich nun komplett dynamisch fÃ¼r Tooltips und den Codex aus der `techtree.json`.
- âœ… **CSV-Reparatur:** Fehlerhaftes Parsing durch rohe ZeilenumbrÃ¼che behoben. Hardcodierte Voraussetzungen aus `language.csv` entfernt.
- âœ… **UI-Fixes:** Float-Werte fÃ¼r Level und FP-Kosten zu sauberen Integern konvertiert. Leerzeichen bei Level-Strings gefixt.
- âœ… **GuestActor Pool Exit:** Bug behoben (Geisterschweben), durch den GÃ¤ste beim Verlassen des Pools fÃ¤lschlicherweise den Restaurant-AStar fÃ¼r den Pool-Raum nutzten.
- âœ… **Bademeister Patrouille:** Radius-Berechnung in `StaffActor.gd` korrigiert (Plot-Tiles x 32px), damit er das gesamte Pool-Areal nutzt und nicht nur das obere linke Viertel und dadurch in MÃ¶bel navigiert.
- âœ… **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) fÃ¼r fehlende Voraussetzungen / falschen Zimmertyp integriert.
- âœ… **Multi-Tile-Room Nav-Bug:** Fehlerhafte Registrierung von MÃ¶beln (Betten) in gedrehten RÃ¤umen (Portrait) in `Room.gd` behoben, die GÃ¤ste fÃ¤lschlicherweise durch die Wand auf den Flur schlafen schickte.
- âœ… **Lobby Check-In Flow (2026-08-14):** GÃ¤ste erscheinen sofort sichtbar an `receptionX` (`WAITING_IN_LINE`). Nach Check-in: lokale Lobby-Navigation zur InnentÃ¼r, dann globaler Korridor-AStar zum Zimmer. Root Cause: `_change_state(WALKING)` in `_walk_to_room` Ã¼berschrieb `previous_state` vor `_execute_walk`. Fix: save/restore. Reload-Fix: `spawn_active_guests()` iteriert nun auch `_waiting`.
- âœ… **Conference Flow & Tweens (2026-08-14):** Instant-Teleport zum Rednerpult (`Chair12`) durch animierten `_execute_poi_move()` Tween ersetzt. Cooldown von 10-15 Ingame-Minuten nach dem Reden eingebaut, damit der Redner nach dem ZurÃ¼cktreten nicht sofort wieder ans Pult rennt.
- âœ… **POI Leave Pathing Fix (2026-08-14):** GÃ¤ste, die im Status `STUDYING_MENU` oder `WAITING_FOR_FOOD` einen POI verlieÃŸen (z.B. weil dieser schlieÃŸt), ignorierten das lokale AStar-Grid und liefen Luftlinie durch WÃ¤nde (`Skipped local_path_out`). Diese Gastro-States wurden in `_execute_walk` zur lokalen Pfadgenerierung hinzugefÃ¼gt.
- ✅ **Unbestätigter Fix (jetzt bestätigt):** Der Notfall-Teleport-Bug (Wolfgang/Anton-Bug) beim Verlassen von Lobby-POIs (Snackautomat) ist durch den Root-Cause-Fix in `_get_logical_start_tile()` behoben. `_current_poi_id = "lobby"` wird nun korrekt über `lobby.get_target_tile()` aufgelöst.
- ✅ **Safety-Fallback:** `_get_logical_start_tile()` fängt verbleibende Edge-Cases ab (solid Start-Tile trotz Berechnung) → Lobby-Innentür als Notfall-Start.
- ✅ **Debug-System MapGrid:** Pfade haben nun Gastnamen-Labels (visuell + Konsole). `DebugOverlay.gd` deaktiviert (veralteter Overlay-Code). `IN_POI` State-Log zeigt nun den POI-Namen.
---

## ðŸ§± Phase 1 â€“ Fundament (v0.1.40â€“41)
*Zuerst, weil alles andere darauf aufbaut.*

### 1.1 Max-Level auf 10 + Balancing
**Status:** âœ… Erledigt (Max-Level ist 15, `get_xp_needed_for_level` ist bis Lvl 10 exponentiell ausgebaut, `UNLOCK_LEVELS` aktiv).

- Level-Kurve von aktuell 5 auf 10 verlÃ¤ngern (`wiki/22_balancing_levelkurve.md` als Basis)
- EXP-Bedarf exponentiell weiterrechnen (ca. Faktor 1.5x pro Level)
- `UNLOCK_LEVELS` in `GameState.gd` fÃ¼r alle neuen Features vorbereiten
- Techtree: Tier-2-Gate (`req_level: 10, req_stars: 1`) bereits in `techtree.json` vorhanden â€“ muss nur mit Content gefÃ¼llt werden
- **AbhÃ¤ngigkeit:** Alles andere (Techtree, KÃ¼che, Gourmetsterne) braucht definierte Level-Gates

### 1.2 Starteinstellung EXP-Boost
**Status:** âœ… Erledigt (`NewHotelModal` hat Schwierigkeitsgrade und Ã¼bermittelt Multiplikatoren fÃ¼r EXP, Geld und RÃ¼ckerstattung an Savegame).

- Im "Neues Hotel"-Dialog: Schwierigkeitsgrad wÃ¤hlbar
- **Casual:** +50% EXP | **Standard:** 100% | **Hard:** -25% EXP (ggf. weniger Startkapital)
- Multiplikator wird im Savegame gespeichert, beeinflusst alle EXP-Quellen global
- (`wiki/23_balancing_cash.md` enthÃ¤lt bereits Startkapital-Staffelung: 100k / 50k / 25k)

### 1.3 Mitarbeiter-Moralwerte aktivieren
**Status:** âœ… Erledigt (`StaffManager._process_morale` triggert jeden Mitternacht; `StaffActor.gd` rechnet bis zu 30% Strafe auf Arbeitszeit bei Moral < 50; KÃ¼ndigung bei Moral <= 0).

Konzept aus `wiki/02_features/06_personal_und_aufgabensystem.md`:
- **`morale`** (0â€“100): Beeinflusst Arbeitsgeschwindigkeit und Fehlerrate
- **Auswirkungen:** `morale < 20` â†’ MitarbeiterkÃ¼ndigt; `morale < 50` â†’ Arbeitsgeschwindigkeit â€“30%
- **Morale sinkt durch:** Ãœberstunden / zu viele Tasks ohne Pause
- **Morale steigt durch:** Personalraum-Besuch (+5 Basis), Schulungen, regelmÃ¤ÃŸiges Gehalt
- Anzeige im Staff-Modal (Balken oder Wert)
- **Hinweis:** Personalraum-Logik (was morale.raise auslÃ¶st) kommt in Phase 3

---

## ðŸ³ Phase 2 â€“ KÃ¼che & Restaurant (v0.1.42â€“43)
*GrÃ¶ÃŸtes Feature-Paket. Braucht Phase 1 (Level-Gates definiert).*

### 2.1 Szenen bauen (Workflow)
**Status:** âœ… Erledigt. `RestaurantSmall` und `KitchenSmall` sind gebaut und im Spiel. Pixel-Assets integriert.

### 2.2 Ins Spiel integrieren
**Status:** âœ… Erledigt. Erlaubte POIs eingetragen, Techtree integriert.

### 2.3 Neue Jobs
**Status:** âœ… Erledigt. Koch und Bedienung sind definiert und funktionieren im Gastronomie-Ablauf.

### 2.4 KÃ¼chen-Logik & Balancing
**Status:** âœ… Erledigt. Bestell-Queue, KÃ¶che und Bedienungen arbeiten zusammen. GÃ¤ste erhalten Essen und zahlen. Income-Kategorie "Gastro" ist im Code verankert.

---

## ðŸ›‹ï¸ Phase 3 â€“ Personal & Wohlbefinden (v0.1.44)
*Baut auf Moral-System aus Phase 1 auf.*

### 3.1 Personalraum (Staff Room)
**Status:** âœ… Erledigt (Szene existiert, Mitarbeiter nutzen StÃ¼hle, Tooltips und Zuweisungen funktionieren).

**Konzept:** Aus `wiki/02_features/06_personal_und_aufgabensystem.md`

- Neuer Raumtyp: Mitarbeiter wechseln in `IDLE`-State â†’ suchen nÃ¤chsten freien Personalraum
- **Slot-System:** Jeder Personalraum hat 4 PlÃ¤tze ("Take the next free place")
- Mitarbeiter im Personalraum: `morale` steigt pro Minute um X
- Balancing: Wie oft / wie lang geht jemand rein? (abhÃ¤ngig von morale-Schwellenwert)
- **Auswirkung auf 1.3:** `morale`-Anstieg durch Personalraum erst hier vollstÃ¤ndig implementieren

### 3.2 Tiefere GÃ¤stewerte / GÃ¤stebedÃ¼rfnisse
**Status:** âœ… Erledigt (Check-In prÃ¼ft Raum-Traits, UI Tooltip zeigt rot/grÃ¼n Status, tÃ¤glicher Zufriedenheits-Abzug greift).

Zimmer-Typen bekommen Eigenschaften (z.B. `"wlan"`, `"desk"`). Wenn GÃ¤ste einchecken, wird abgeglichen, ob das Zimmer ihre Anforderungen erfÃ¼llt. Fehlt etwas (z.B. WLAN fÃ¼r den GeschÃ¤ftsreisenden), sinkt die Zufriedenheit und wir zeigen das im UI an. Die Basisdaten dafÃ¼r (z.B. `"wlan"` beim GeschÃ¤ftsreisenden) existieren bereits im Code.
- [x] **Room Hover Bug:** Moebelstuecke (speziell in Multi-Tile-Raeumen) blockieren keine Mauseingaben mehr fuer den Raum-Tooltip.
- [x] **Techtree Nodes:** Funktionale Phase-4-Nodes aus dem Demo-Lock befreit und Platzhalter entfernt.
- [x] **Techtree UI:** Tooltips zeigen nun echte Raumbeschreibungen und nutzen manuelles Word-Wrapping, um Layout-Bugs von Godot zu umgehen.
- [x] **Codex:** POI-Eintrag hinzugefÃ¼gt und Tutorial-UI auf Echt-Daten-Binding umgestellt.
- [x] **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch Ã¼ber `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **GuestActor Teleport Fix:** Fehlerhaftes Teleportieren (Hide/Fade) von GÃ¤sten im Restaurant behoben. Das versehentliche TÃ¶ten von Tweens im State-Change durch `call_deferred` unterbunden.
- [x] **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik fÃ¼r AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- [x] **StaffActor Bademeister Fix:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- âœ… ANG-324: Exploit-Fix â€“ PausenrÃ¤ume kÃ¶nnen nicht mehr abgerissen werden, wenn dadurch das KapazitÃ¤tslimit unter die Anzahl des eingestellten Personals fÃ¤llt.
- âœ… ANG-320: Tutorial-Texte ergÃ¤nzt, RÃ¤ume-Kategorie im Codex hinzugefÃ¼gt, Wiki-Dokumentation fÃ¼r RÃ¤ume samt Navigation Points erstellt.
- âœ… Fix: Crash beim Laden von leeren PersonalrÃ¤umen.
- âœ… Fix: Lobby war nicht korrekt als Nav-Raum definiert.
- âœ… **GuestActor Wegfindung:** Bug behoben, durch den GÃ¤ste beim Verlassen des Zimmers geradewegs durch WÃ¤nde liefen (Status-Machine Bug mit `previous_state` behoben).
- âœ… **CustomTooltip:** Position wird nun auf den Viewport geclempt, sodass der Tooltip nicht mehr oben aus dem Bild rutscht.
- âœ… **ANG-332:** Feature-Issue fÃ¼r "Weitere Parzelle" Reward im LevelUp-Screen angelegt.
- âœ… **Parzellen-Kauf-UI:** Progressbar komplett auf `ParzelleBuildUI.tscn` (Tooltip-Style) umgestellt. Inklusive 3.0-Scaling auf dem CenterContainer, um den Kamera-Zoom (0.33) exakt auszugleichen und pixel-perfect Font-Rendering zu garantieren.
- âœ… **MapGrid:** Beim Beenden des Parzellen-Kauf-Modus wird die Kamera jetzt via `center_on_entry()` zentriert (identisch zur HOME-Taste).
- âœ… **Loca-Fix:** Die fehlenden Ãœbersetzungen (`tx.plot_buy`, `ui.confirm.plot_buy_title`, `ui.confirm.plot_buy_desc`) fÃ¼r den Parzellenkauf wurden in `language.csv` nachgetragen. Floating-Value-Anzeige nach Kauf integriert.
- âœ… **MapGrid-Erweiterung:** Verschmelzung der Parzellen-Grids implementiert, sodass gekaufte Parzellen zu einem groÃŸen nahtlosen Grid zusammengefÃ¼gt werden (Verschiebung des Nullpunkts entfÃ¤llt, Koordinaten sind global eindeutig).
- âœ… **MapGrid.tscn:** Z-Index des `FloorLayer` (Rasen) auf -2 gesetzt, damit dieser nicht mehr durch die Beton-BÃ¶den wÃ¤chst.
- âœ… **Loca-Fix:** Die Kategorie `room_category.business` in `language.csv` ergÃ¤nzt.
- âœ… **Techtree:** Demo-Lock fÃ¼r den Raum P1.2 (Konferenzraum) entfernt.
- âœ… **Codex:** Die Raum-Liste in "Tutorials & Codex" generiert sich nun dynamisch aus dem `room_registry`, statt manuell gepflegt werden zu mÃ¼ssen. Vorschaubilder und Tooltip-Beschreibungen werden sauber verknÃ¼pft (mit Fallbacks).
- âœ… **Bugfixes & Warnings:** Fehlerhaften Icon-Pfad fÃ¼r `map-pin.svg` korrigiert sowie diverse Godot-Warnungen (Integer-Division, Ternary-KompatibilitÃ¤t, ungenutzte Parameter) in `MapGrid.gd` behoben.

---

## ðŸŒ³ Phase 4 â€“ Techtree mit Leben fÃ¼llen (v0.1.45)

### 4.1 Bestehende Nodes mit Inhalt versehen

Aktuell gesperrte Nodes ohne Inhalt:

| ID | Kategorie | Geplanter Inhalt |
|---|---|---|
| `G1.4` | Gastronomie | GourmetkÃ¼che (Vorstufe Gourmetsterne) |
| `W1.1` | Wellness | Spa / Massage |
| `W1.2` | Wellness | Pool / AuÃŸenbereich |
| `W1.3` | Wellness | Wellness-Paket (Kombination) |
| ~~`M1.2`~~ | ~~Management~~ | ~~Personalentwicklung (Schulungsbonus)~~ âœ… Erledigt |
| ~~`M1.3`~~ | ~~Management~~ | ~~Prozessoptimierung (Effizienz-Bonus)~~ âœ… Erledigt |
| `M1.4` | Management | Hotelleitung (Globaler Effizienz-Bonus) |
| `P1.1` | Prestige | Events (Konzerte, Messen etc.) |
| `P1.2` | Prestige | Veranstaltungszentrum |
| `P1.3` | Prestige | Prestige-Paket |
| Tier 2 | Alle | Req: Level 10 + 1 Stern â€“ Tier-2-Nodes definieren |

- FÃ¼r jeden Node: Was genau schaltet er frei? Raum? Feature? Bonus?
- Translation-Keys fÃ¼r alle Namen in `language.csv` nachtragen
- Level-Gates pro Node sauber definieren

---

## â­ Phase 5 â€“ Events & Prestige (v0.1.46â€“47)

### 5.1 Zufallsereignisse
- Event-System: ZufÃ¤llige Ereignisse nach Zeit/Wahrscheinlichkeit
- Beispiele: Rohrbruch, TV-Ausfall, Stromausfall, SchÃ¤dlingsbefall
- Jedes Event: Dauer + Reparaturkosten + Impact auf `satisfaction` betroffener GÃ¤ste
- Benachrichtigung: Toast + Activity-Log-Eintrag + Raum-Indikator
- Spieler-Reaktion: Haustechnik schicken oder selbst bestÃ¤tigen

### 5.2 Gourmetsterne
- Voraussetzung: `G1.4` (GourmetkÃ¼che) erforscht
- Bewertungs-Logik: Restaurant-QualitÃ¤t (KÃ¼chen-Skills) + Ã˜ GÃ¤stezufriedenheit Ã¼ber Zeit â†’ 0â€“3 Sterne
- **Inspektor-Event:** Seltenes Zufallsevent (1x pro ~30 Tage). Inspektor besucht â†’ bewertet anonym â†’ Toast mit Ergebnis
- Sterne geben Boni: +Reputation, +Einnahmen-Multiplikator Restaurant, neue GÃ¤stetypen

---

## ðŸ“Š AbhÃ¤ngigkeits-Ãœbersicht (Schnellreferenz)

```
Phase 1: Fundament
â”œâ”€â”€ 1.1 Max-Level 10          â† ZUERST (Level-Gates fÃ¼r alles andere)
â”œâ”€â”€ 1.2 EXP-Boost Starteinstellung
â””â”€â”€ 1.3 Morale aktivieren     â† Basis fÃ¼r Phase 3

Phase 2: KÃ¼che & Restaurant   â† Braucht 1.1 (Level-Gates)
â”œâ”€â”€ 2.1 Szenen (Peter + Workflow)
â”œâ”€â”€ 2.2 Integration + Techtree G1.2/G1.3 entsperren
â”œâ”€â”€ 2.3 Neue Jobs
â””â”€â”€ 2.4 KÃ¼chen-Logik

Phase 3: Personal & GÃ¤ste     â† Braucht 1.3 (Morale-System)
â”œâ”€â”€ 3.1 Personalraum           â† Braucht 1.3 (Morale-Raise-Logik)
â””â”€â”€ 3.2 GÃ¤stebedÃ¼rfnisse       â† Requirements-Array bereits vorhanden!

Phase 4: Techtree-Content      â† Braucht 2.x (RÃ¤ume mÃ¼ssen existieren)
â””â”€â”€ 4.1 Alle demo_locked Nodes mit Inhalt

Phase 5: Events & Prestige     â† Braucht 4.1 (G1.4 GourmetkÃ¼che)
â”œâ”€â”€ 5.1 Zufallsereignisse
â””â”€â”€ 5.2 Gourmetsterne + Inspektor
```

---

## ðŸ”® SpÃ¤tere Features (nach Alpha / Beta)

- **Savegames - Actor-State-Serialisierung (ANG-314):** Beim Laden eines Spielstands exakte Positionen, Pathfinding und Timer (GÃ¤ste & Staff), offene Putz-Tasks und Gastro-Bestellungen wiederherstellen, um Immersion-Breaks zu verhindern. Erst implementieren, wenn alle State-Machines feature-complete sind.
- **Rework: New Game UI (Erweiterte Spieleinstellungen / Seite 2):** VergrÃ¶ÃŸerung des Fensters (ggf. mit Tabs oder 2. Seite) um feinere Anpassungen von Startkapital, Mitarbeiter-Schwellenwerten (Pausenverhalten) und anderen Startbedingungen zu ermÃ¶glichen.
- **Personalflure:** Kommt mit Nav-Rework (3 Ebenen: GÃ¤ste / Personal / Rauminneres + feineres Grid)
- **Begehbare RÃ¤ume:** AbhÃ¤ngig von Nav-Rework
- **Zoning:** Mitarbeiter-Zonen auf der Karte (im Wiki skizziert)
- **Sicherheitszentrale:** PiP-Kamera recyceln als Ãœberwachungssystem (ab Level 20, Wiki-Konzept vorhanden)
- **Connecting Rooms:** Zimmer mit VerbindungstÃ¼r (Familie-Segment)
- **Krankheits-System:** Mitarbeiter werden krank (Wiki-Konzept vorhanden)

---

## ðŸ“ Relevante Dateien (Schnellreferenz)

| Was | Datei |
|---|---|
| GÃ¤ste-Typen & Requirements | `data/GuestDefinitions.gd` |
| Mitarbeiter-Dict (morale) | `autoload/StaffManager.gd` |
| GÃ¤ste-Werte (satisfaction, patience) | `scenes/ingame/guest/GuestParty.gd` |
| Techtree-Struktur | `config/techtree.json` |
| Level-Kurve Konzept | `wiki/22_balancing_levelkurve.md` |
| Cash-Balancing Konzept | `wiki/23_balancing_cash.md` |
| Personal-System Konzept | `wiki/02_features/06_personal_und_aufgabensystem.md` |
| Techtree-Architektur Konzept | `wiki/02_features/01_architektur_techtree_und_fp.md` |
| Raumtypen-Referenz | `wiki/02_features/22_raumtypen_referenz.md` |
- **Kassenbuch Gastro-Namen:** Fehlende Rezeptnamen in Gastro-Kassenbucheinträgen repariert (Key name_key statt name verwendet).
- **Kassenbuch Checkout-Details:** Checkout-Logs um Zimmertyp und Aufenthaltsdauer erweitert. ModalContentFinances.gd unterstützt nun beliebig viele Platzhalter in der Übersetzung.
- **GuestActor Navigation-Refactoring:** `_get_logical_start_tile()` komplett überarbeitet und das Flickwerk hardcodierter Status-Checks (EATING, STUDYING_MENU etc.) entfernt. Start-Kachel-Ermittlung aus POIs funktioniert nun generisch und robust über `_current_poi_id`, was SOLID-Fehler bei unerwarteten Statuswechseln (z. B. Bettzeit um 23:00 Uhr während Wartezeit) verhindert.
- **SmartRoom Bar Migration:** Gast-Sitzplatz-Zuweisung repariert. Gäste stapeln sich nicht mehr auf dem Fallback-Punkt, sondern blockieren Sitzplätze sauber über `claim_interaction`, bevor sie loslaufen.
- **GuestActor State-Flow (Bar):** State EATING ruft nun korrekt `release_interaction` auf, damit SmartRoom-Plätze wieder freigegeben werden.
- **StaffActor Z-Index & Map Sichtbarkeit:** `StaffActor` Z-Index auf 100 erhöht, damit Personal über dem NavGrid gerendert wird. `configure()` Methode angepasst, damit `spawn_room` beim Start übergeben und gespeichert wird, was den verbuggten Lobby-Teleport direkt nach dem Spawn (und das Flackern auf der Karte) verhindert.
- **StaffActor Logging & State-Machine Bereinigung:** Die Log-Ausgaben im Stil von `GuestActor` in `StaffActor` mittels eines zentralen `_set_state`-Wrappers komplett wiederhergestellt (mit korrektem Vornamen/Nachnamen Parsing). Einen redundanten Mikrosekunden-Switch auf `working` während des "Chillings" (`walking`) behoben.
- **StaffActor Idle Timer:** Den Timer für den Sitzplatzwechsel im Pausenraum (`_process_resting`) von 2% auf realistische 10% (alle 2 Sekunden) erhöht, damit das Personal lebendiger wirkt.
- **StaffSmall & Raumsitze-Kapazität:** Kapazitäts-Check `has_free_seat()` bei Personal-Räumen gefixt, um zu verhindern, dass Staff-Actors in einen überfüllten Pausenraum spawnen. Smart-Room Interaktionen in `Room.gd` und `StaffSmall.gd` überprüft.
- **Staff-Aufgaben Annahme:** Validierung und Logging des Service-Rufen Buttons. Die Wegfindung zu Zielräumen wurde stabilisiert, und Tasks (`clean_room`, `repair_room`) werden zuverlässig angenommen und ausgeführt.

### Session Bugfixes
- [x] Lobby: Guest clipping / standing in walls
- [x] MapGrid: Pathfinding debug output for straight-line corridor failures
- [x] SmartRoom: Guests instantly aborting Bar visit due to dirty tables in Solo-Loop
- [x] GuestActor: Starving guests ignoring food POIs in favor of random POIs
