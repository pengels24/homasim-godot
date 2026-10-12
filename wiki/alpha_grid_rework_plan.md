# Alpha-Start: Pre-Alpha einfrieren & Unified-Nav-Grid
> Status: **PLANUNG – noch nicht freigegeben, KEIN Code geschrieben** | Stand: 12.10.2026 | Basis: v0.2.2
> Baut auf `ang364_nav_rework.md` auf (siehe Abgrenzung). Linear: ANG-364 (Pathfinding), ANG-314 (Actor-States, Done).
> **Dieses Dokument ist verbindlich.** Wo es dem älteren `ang364_nav_rework.md` widerspricht, gilt dieses Dokument.

---

## 0. LESEN VOR DER ARBEIT (für jedes Modell / jeden Agenten)

### 0.1 Verbindlichkeit
- Alle Einträge in **Abschnitt 3 (Getroffene Entscheidungen)** sind **entschieden**. Nicht erneut diskutieren, nicht umdeuten, keine „besseren“ Alternativen einbauen. Hast du Bedenken: **Peter fragen**, nicht eigenmächtig ändern.
- Es wurde **noch nichts umgesetzt**. Der Ist-Zustand im Code ist der Pre-Alpha-Stand v0.2.2 (zwei getrennte Nav-Systeme, siehe 0.3).
- Eine Phase (Abschnitt 4) wird **erst begonnen, wenn Peter sie ausdrücklich freigibt**. Phasen nicht überspringen, nicht mehrere gleichzeitig starten.
- Peter liest Schritt für Schritt: pro Schritt kurz erklären **was** und **warum**. Keine großen Code-Dumps.

### 0.2 Pflichtregeln aus `.agents/AGENTS.md` (Kurzfassung, Original gilt)
- Vor Aussagen „X fehlt / existiert“: per `grep_search`/`list_dir` im Code verifizieren (Anti-Halluzination). Nicht aus dem Gedächtnis behaupten.
- Vor neuem Linear-Ticket: `python _dev/linear_cli.py list` (Duplikate vermeiden). ANG-Nummern in Code-Kommentaren, Commits, Changelog.
- Alle Dateien **UTF-8**; Python-Skripte immer `encoding='utf-8'`.
- Godot 4 API, statische Typisierung. `Object.get()` hat **ein** Argument (zwei nur bei `Dictionary.get()`).
- Eigene Signale beginnen mit `sig_`. Alle Texte über `GameState.T("key")`, neue Texte sofort in `language.csv` (DE+EN). UI in `.tscn`, nicht per `Node.new()`.
- **.tscn-Regel:** *Visuelle* Änderungen (Position, Größe, Layout, Farben, Z-Order, Sprites) nur nach Freigabe – Peter macht sie im Editor. *Rein technische* Änderungen (Skripte anhängen, Gruppen/Signale, Node-Struktur ohne optische Wirkung, Footprint-/Nav-Nodes) darf der Agent selbst machen. Bei Unsicherheit fragen.
- Keine Rezeptionisten als NPC (Spieler checkt selbst ein/aus). Personalflure sind **nicht** Teil der Alpha.
- Kein Push ohne Test durch Peter. Nach erfolgreichem Test: Wiki-Techdoku aktualisieren. Session-Ende: `alpha_backlog.md` aktualisieren, dann Changelog.
- Helfer-Skripte in `_dev` oder `_work`, nicht im Root.

### 0.3 Begriffe (eindeutig)
| Begriff | Bedeutung |
|---|---|
| **Tile** | Bau-Einheit, **16×16 px** (`TILE_PX = 16`). Räume sind Vielfache davon (z. B. Einzelzimmer 2×2 Tiles = 32×32 px). Bleibt unverändert. |
| **Parzelle** | 16×16 Tiles = 256×256 px. Maximum der Map: 5×5 Parzellen = 80×80 Tiles = 1280×1280 px. |
| **Nav-Zelle** | **4×4 px** = 1/16 Tile. Auflösung des neuen einheitlichen Nav-Grids. 5×5 Parzellen = **320×320 = 102.400 Nav-Zellen**. |
| **Welt-Grid (alt)** | `MapGrid.astar` (`AStarGrid2D`, 16 px pro Zelle, ohne Diagonalen). Raumkörper = solid, nur Tür-Tile frei. |
| **Raum-Grid (alt)** | `Room._local_astar` (`AStar2D`, 4 px, mit Diagonalen), pro Raum, aus `Obstacles`-TileMapLayer + `NavBlocker`-Nodes. |
| **Unified Grid (neu)** | **ein** `AStarGrid2D` mit 4-px-Zellen für die ganze Map; Räume stempeln ihre Maske hinein. |
| **Stempeln** | Beim Bau/Laden schreibt ein Raum seine Begehbarkeit (Wandring + Möbel-Fußabdrücke) ins Unified Grid. Immer **ganzen Raum neu** (Fläche leeren, dann stempeln). |
| **Footprint** | `TileMapLayer` (4-px-Tiles) in einer Möbel-Szene; markiert die Zellen des Möbels als „gesperrt“ oder „begehbar langsam“. |
| **Slot** | Ziel einer Interaktion (Bett, Sitz, Service-Punkt, Staff-Sitz). Heute: Node, per Namenssuche gefunden. |
| **LookTarget** | `Marker2D`, auf den ein Gast beim Sitzen/Schlafen blickt (Tisch, Speakertable, Bettfußende). |
| **Ghost** | Vorschau-Raum beim Bauen (`BuildCursor._ghost`). Wird nie ins Grid gestempelt. |
| **Flur** | Entsteht von selbst: freie Fläche zwischen Räumen, mindestens 1 Tile (16 px) breit. Kein Bauteil, wird nie gestempelt. |

### 0.4 Geprüfte Code-Fakten (Stand v0.2.2, mit Fundstelle – bei Zweifel erneut prüfen)
- Welt-AStar: `scenes/ingame/map/MapGrid.gd` `_setup_astar()` (~Z. 1094): `DIAGONAL_MODE_NEVER`, `HEURISTIC_MANHATTAN`; Belegung `_occ` (0 frei, 1 Raumkörper, 2 Tür, 3 Wand), `_sync_astar_cell()` (~Z. 1108). Wegsuche `get_path_between_tiles()` (~Z. 125) entsperrt Start/Ziel kurz (Hack).
- Raum-AStar: `scenes/ingame/rooms/Room.gd` `_build_local_nav()` (~Z. 1023), `LOCAL_NAV_CELL_SIZE = 4.0`, `get_local_path()` (~Z. 1098) mit Luftlinien-Fallback `[start, end]`; Aufrufe in `_ready()` (~Z. 386) sowie ~Z. 672 und ~Z. 910.
- Ghost: `scenes/ingame/build/BuildCursor.gd` ~Z. 65 `_room_scene.instantiate()` → `_ready()` baut heute auch für Ghosts Nav (Verschwendung).
- Slots: `Room.gd` ~Z. 100–106 `_find_furniture_recursive` (Namen mit `chair`/`bed`); Claims über IDs `bed_N`/`seat_N`/`staff_seat_N`; `claim_interaction()` (~Z. 250) liefert `target_pos`, `look_at_pos`/`look_at_dir`, `duration`. `get_service_position()` (~Z. 482) = `Marker2D` `ServicePoint`.
- `GuestActor` ignoriert `claim.look_at_pos` und sucht den Tisch selbst (`%Table` / `find_children("Table")`, ~Z. 2194–2212).
- Drehung: Gast `avatar.rotation = angle_to_point(...)` **sofort, freier Winkel** (GuestActor ~Z. 1997, 2186; GuestAvatar ~Z. 56); Staff `_sprite.rotation = direction.angle() + PI/2` (Sprite zeigt bei Rotation 0 nach oben; StaffActor ~Z. 1079). Zwei verschiedene Winkelkonventionen.
- Skalierung: Gast Erwachsener 0,8 / Kind 0,55 (`GuestAvatar.gd` ~Z. 29–33); Staff-Spawn-Skalierung noch nicht gefunden.
- Boden-Kürzung zwischen Nachbarräumen ist **rein visuell**: `set_floor_neighbors()` streckt das Boden-Sprite um 1 px je Nachbarseite (z. B. `BedStandard.gd` ~Z. 40–52); in Spa, Pool, Gym, Conference, Superior, Standard, Family, Double. Hat keinen Einfluss auf die Navigation.
- Geometrie in Pixeln: Wand 2 px dick; Tür 1 px dick, meist 5 px breit (Slots wie `L1`, `L2`, `T1` in `valid_door_slots`); Gast-Sprite-Fläche 16×16 px (sichtbarer Körper kleiner).
- Zeit: `TimeManager.SECONDS_PER_GAME_MINUTE = 4.0`. Gast-Wander-Intervall 4–10 Spielminuten.
- Savegame: `SaveManager` nutzt `user://v2_*`-Ordner; **kein** Versionsfeld im Save gefunden. `GuestActor.get_save_state()` (~Z. 1557) und `StaffActor.get_save_state()` (~Z. 146) speichern `pos_x/pos_y` (Welt-Pixel), State, Timer. `restore_save_state()` nutzt `astar.is_point_solid()` zur Raum-Erkennung (muss ersetzt werden). Staff-Position wird beim Laden nicht restauriert.
- Engine: Godot 4.6.2.

---

## 1. Ziel
- Pre-Alpha (v0.2.x) einfrieren, damit Tester-Feedback (itch.io, Streamer) weiter eingearbeitet werden kann.
- Alpha-Linie (`dev`) beginnt mit dem **Zusammenführen von Welt-Grid und Raum-Grid** zu **einem** Nav-Grid.
- Folge: Kein Systemwechsel mehr an der Tür → Wegfall der Luftlinien-Bugs, der Closest-Point-Rundung und der Start-/Ziel-Entsperr-Hacks.

## 2. Abgrenzung zu `ang364_nav_rework.md`
Das ältere Dokument (19.09.) beschreibt einen größeren Umbau. Unsere Planung (12.10.) ist **enger geschnitten**:

| Thema | ANG-364-Dokument | Dieser Plan |
|---|---|---|
| Nav-Raster | 4×4 px einheitlich | 4×4 px einheitlich (gleich) |
| **Bau-Raster** | frei auf 4×4-Tiles, flexible Flurbreiten (4/8/12/20) | **bleibt 16 px**, Flur min. 1 Tile (16 px) |
| Positions-Speicherung | `tile_id` | **Raum-ID + Slot-ID** (stationär), Position + Ziel (laufend) |
| Save-Ordner | v2_ → v3_ | **kein v3_ nötig**, dafür `save_format`-Feld |
| Zeitpunkt | Post-Alpha | erster Alpha-Schritt |
| Zählung | „6.400 Tiles“ | 5×5 Parzellen = 320×320 = **102.400 Nav-Zellen** (6.400 sind die 16-px-Tiles) |

> **ENTSCHIEDEN (Peter, 12.10.2026):** Die Unterschiede zum älteren Dokument bleiben bestehen. Dieses Dokument gilt. Das **freie 4-px-Bausystem ist nicht Teil der Alpha** (Bau-Raster bleibt 16 px). Nicht „nachrüsten“, nicht vorbereiten, außer Peter fordert es ausdrücklich.

## 3. Getroffene Entscheidungen
| # | Thema | Entscheidung |
|---|---|---|
| 1 | Nav-Zellgröße | 4 px (kein 2-px-Raster) |
| 1 | Wand/Möbel-Rasterung | konservativ: Zelle gesperrt, sobald berührt. Wandring 4 px, unabhängig von der 1-px-Boden-Kürzung (`set_floor_neighbors`) |
| 1 | Tür | 1 Zelle (4 px), Mitte auf Zellmitte; Türslot-Positionen aufs 4-px-Raster |
| 2 | Bewegung | keine Diagonalen, Manhattan, Weg auf Abbiegepunkte reduzieren |
| 3 | Daten-Layer | Kollision / Oberfläche / Slots als getrennte Layer |
| 3 | Reihenfolge | zuerst Kollision + Oberfläche, Slots erst später |
| 3 | Datenquelle | **Möbel als eigene Szenen** mit `Footprint`-TileMapLayer (4 px); Raum stempelt Union aus globalen Transformationen |
| 3 | Savegame | Masken werden nicht gespeichert, beim Laden neu gestempelt |
| 3 | Szenen-Regel | technische .tscn-Änderungen durch KI erlaubt (AGENTS.md angepasst); Fußabdruck-Passung zum Sprite prüft Peter |
| 4 | Benutzbare Möbel | Bett/Stuhl/Sofa **begehbar mit hohem Gewicht**; Tisch/TV/Bad gesperrt |
| 4 | Kein Pfad | **keine Luftlinie, kein Teleport**: Fehler loggen, Aktion überspringen, Gast wählt neu (+ Sperrliste, + sicherer Rückfall) |
| 4 | Validator | prüft beim Stempeln: jeder Slot auf begehbarer, erreichbarer Zelle |
| 4 | Blickrichtung | `LookTarget`-Marker (Tisch, Speakertable, Bettfußende); `claim.look_at_pos` statt Namenssuche (`%Table`) |
| 4 | Drehung | sanftes Drehen (`lerp_angle`, ca. 0,1–0,15 s) statt Sprung; Winkelkonvention Gast/Staff vereinheitlichen |
| 5 | Ghost | Geister-Räume stempeln **nie** |
| 5 | Performance | Flächenfüllung statt Zellschleife; Frame-Budget-Warteschlange für Pfadanfragen; **`jumping_enabled` nicht nutzen** (deaktiviert Gewichte) |
| 6 | Save | Feld `save_format`; Position beim Laden prüfen → nächste begehbare Zelle, sonst Lobby-Tür; jede Reparatur loggen |
| 6 | Save-Ziel | exakte Wiederherstellung (Bett, Sitz, laufend), Ladebild mit echtem Fortschritt |
| – | Personalflure | nicht Teil der Alpha; Grid-Struktur muss Layer pro Akteurstyp erlauben (2 AStarGrid2D auf gleicher Basis) |

## 4. Phasen

### Phase 0 – Einfrieren (vor jedem Code)
- **Status: AUSGEFÜHRT am 12.10.2026** (siehe `_work/uebergabe.md`). Ergebnis:
  - Tag `v0.2.2-prealpha` auf dem eingefrorenen Stand (Code = itch.io-Build v0.2.2).
  - Branch **`prealpha`** = Pre-Alpha-Linie (Versionen **v0.2.x**): nur Feedback-Fixes, itch.io-Builds. `version.txt` bleibt dort `v0.2.x`.
  - Branch **`dev`** = Alpha-Linie (Versionen **v0.3.0 und höher**). `version.txt` auf `dev` = `v0.3.0` ab dem ersten Alpha-Commit.
  - **`master` bleibt unberührt** (alter Stand, nicht verwenden).
- Feedback-Fixes zuerst auf `prealpha` (Version v0.2.3 usw.), danach `git merge prealpha` in `dev`.
- Pathfinding-Bugs auf `prealpha` nur minimal (Workaround) – saubere Lösung kommt mit dem Rework.
- Rework läuft auf Feature-Branch `alpha/grid-rework`, nicht direkt auf `dev`.
- **Abnahme:** Pre-Alpha-Build aus `prealpha` funktioniert unabhängig.

### Phase 1 – Stresstest auf aktuellem Stand (unabhängig vom Rework)
- **Befund (12.10.2026, im Code geprüft):** `DevConsole`-Befehl `spawn-guests N` (`DevConsole.gd` ~Z. 389 → `GuestManager.spawn_guests()` ~Z. 463) erzeugt nur **Parteien in der Warteschlange der Rezeption**. Peter muss sie per Klick einchecken, und es werden freie Zimmer gebraucht. Damit sind 300/600/1000 aktive Gäste **nicht** erreichbar (so viele Zimmer gibt es nicht, und 1000 Klicks sind unrealistisch). Der ursprüngliche Satz „Per DevConsole 300/600/1000 Gäste erzeugen“ ist deshalb mit dem vorhandenen Befehl nicht umsetzbar.
- **Stufe 1a – Baseline ohne Code (Peter, ca. 5 Min):** Teststand mit 53 Gästen laden. Frame-Zeit (Godot Debugger → Monitors/Profiler für ms-Werte; alternativ das Tech-Overlay `TechOverlay.gd`, das **nicht per Taste**, sondern über die Einstellungen (`SettingsManager.show_tech_info`) ein-/ausgeblendet wird und in Release-Builds nur FPS zeigt) bei Speed 1x und 10x notieren; zum Vergleich einen Stand mit wenigen/keinen Gästen. Ergebnis: ungefähre Kosten pro Akteur → Hochrechnung auf 1000.
- **Ergebnis Stufe 1a (12.10.2026, Editor-Debug, V-Sync aus, Teststand 53 Gäste + 9 Staff, 2 Parzellen):**

  | Zustand | FPS | Frame-Zeit (Monitor / Overlay) | Physik | Draw Calls | Gezeichnete Objekte |
  |---|---|---|---|---|---|
  | Pausiert | ca. 500–550 | 3,6 ms / 2,9 ms | 0,05–0,07 ms | ca. 706 | 2.690 |
  | Speed 1x | ca. 260 | 5,0 ms / 6,6 ms | 0,6–2,2 ms | ca. 812 | 4.209 |
  | Speed 5x (Play-Stufe 2) | ca. 274–279 | 10,9 ms / 12,0 ms | 0,7–0,9 ms | ca. 709–713 | 2.623 |
  | Speed 10x | ca. 267–288 | 5,7 ms / 5,0 ms | 0,9–2,1 ms | ca. 709–721 | 2.648 |

  Nodes ≈ 6.200 (fast alle Räume/Möbel), Navigation ≈ 0,00 ms. **Akteurskosten ≈ Differenz laufend − pausiert ≈ 1,3–3,7 ms für 62 Akteure ≈ 0,02–0,06 ms pro Akteur.** Naive lineare Hochrechnung auf ca. 1000 Akteure: ca. 20–60 ms zusätzlich zu den festen Kosten von ca. 3–4 ms. Das ist eine **grobe Obergrenze** (nicht alle Gäste sind gleichzeitig aktiv, Release-Build ist schneller), zeigt aber: **Die Akteurszahl ist ein reales Risiko, die Wegsuche (≈ 0 ms) nicht.** Auffällig: laufend werden ca. 1.500 mehr Objekte und ca. 100 mehr Draw Calls gezeichnet als pausiert (Hinweis auf viele CanvasItems pro Akteur; Ursache noch nicht untersucht).
  **Befund Speed 5x/10x (korrigiert):** Die Kosten steigen **nicht** linear mit der Spielgeschwindigkeit: 10x (5,7 ms) war günstiger als 5x (10,9 ms). Die Frame-Zeit schwankt je nach momentaner Aktivität (wie viele Akteure laufen/Aktionen ausführen). Physik und Navigation bleiben klein (≤ 2 ms bzw. ≈ 0 ms). Die Einzelmessungen sind Momentaufnahmen; eine Hochrechnung auf 1000 Akteure ist daher sehr grob (Größenordnung 20–100 ms). Belastbare Zahlen liefert erst Stufe 1b (`stress-actors`) mit gleichbleibender Last.
  Hinweis: `project.godot` enthält für die Messung lokal `window/vsync/vsync_mode=0` – **nicht committen**, danach zurücksetzen.
- **Stufe 1b – neuer Dev-Befehl (nur Dev/Debug-Build, nie in Release):** z. B. `stress-actors N`, erzeugt N Dummy-`GuestActor` (ohne Partei/Zimmer-Buchung), die zufällige Ziele im Hotel ansteuern. Messen: FPS und Frame-Zeit bei N = 300 / 600 / 1000, jeweils 1x und 10x. Offene Detailfrage für die Umsetzung: Wie viel Setup braucht ein `GuestActor` minimal (`_guest_member`, `_map_grid`, Ziel-Raum)? Vorher `GuestActor.setup()` und `GuestController` lesen.
- Frage: Ist die Akteurzahl (Nodes, Tweens, Klickflächen) oder die Wegsuche der Engpass? Bei Stufe 1b auf dem **alten** Nav-System ist die Wegsuche nur indirekt aussagekräftig; der eigentliche Pfad-Test folgt im Spike (Phase 3).
- Ergebnis entscheidet, ob eine eigene Skalierungsstrategie nötig ist (z. B. schlafende Gäste ohne Node).
- Referenz: Teststand 53 Gäste / 9 Staff / 2 Parzellen läuft flüssig; Endgame-Annahme ≈ 1000 Gäste.

### Phase 2 – Inventur (nur lesen, Wiki-Dokument)
- Alle Stellen mit Welt↔Lokal-Umrechnung (`get_target_tile`, `get_room_entry_pos`, `get_door_world_*`, `get_local_path`, `to_global`-Brücken, `_get_logical_start_tile`, `_get_closest_walkable_tile`).
- Alle Räume: Slots (Namenssuche), `NavBlocker`, `Obstacles`-Layer, `ServicePoint`, Tür-Slot-Pixelpositionen, Staff-Spawn-Skalierung.
- GuestActor/StaffActor: Stellen mit Phase-1/Phase-2-Wegen, `_current_poi_id`-Abhängigkeiten, Rotationslogik.
- **Abnahme:** Liste mit Umfang je Datei, Risiko-Einschätzung, grober Zeitplan.

### Phase 3 – Spike (Wegwerf-Szene)
- Worst Case: 320×320 Nav-Zellen, ca. 1000 Akteure (≈30 % gleichzeitig unterwegs).
- Testräume: Lobby-Layout (Empfangsblock), enge Zimmerreihen mit Bädern, Restaurant.
- Prüfen: Türregel (1 Zelle), Wandring, Treppeneffekt/Abbiegepunkte, sanfte Drehung, Stempel-/Abriss-Zeit.
- **Messgrenzen (von mir gesetzt, anpassbar):**

| Messung | Zielwert |
|---|---|
| Init 320×320 (Flächenfüllung) | < ca. 50 ms (einmalig) |
| Stempeln eines Raums | < ca. 5 ms |
| Pfadanfrage (Ø, langer Weg) | < ca. 1 ms |
| Pfadsuche gesamt pro Frame (1000 Akteure) | < ca. 2 ms, sonst Warteschlange |
| Abriss + Neustempeln | < ca. 5 ms |

- **Abnahme:** Messwerte erfüllt oder begründet angepasst; Entscheidung Go/No-Go für Migration.

### Phase 4 – Möbel-Szenen & Stempel-Code
- Spezifikation je Möbelszene: Wurzelknoten, Skript, Sprite, `Footprint` (4-px-TileMapLayer, Typ „gesperrt“ / „begehbar langsam“), Gruppe, Namenskonvention.
- Start nur mit Möbeln, die heute `NavBlocker`/`Obstacles` haben.
- Fußabdruck aus bestehenden NavBlocker-Rechtecken vorbefüllen; **Peter prüft Passung im Editor**.
- Stempel-Code: Raum leeren → Wandring + Fußabdrücke aus globaler Transformation → Welt-AStarGrid.
- Validator (Slots erreichbar) + DevConsole-Befehl.

### Phase 5 – Migration in Etappen
1. Lobby + Gästezimmer (Standard, Double, Family, Superior)
2. POIs: Restaurant, Bar, Küche, Pool, Gym, Spa, Konferenz
3. Staff (Reinigung, Wartung, Gastro, Bademeister)
4. Altes 2-System-Nav entfernen (`_local_astar`, Brückenfunktionen, Closest-Point/Entsperr-Hacks)
- Pro Etappe: Test durch Peter, Doku, danach nächste.
- GuestActor: Phase-1/Phase-2-Wegelogik entfernen (größter Einzel-Eingriff).

### Phase 6 – Slots & Blickrichtung (Stufe 2)
- Typisierte Marker (`slot_type`, eindeutige IDs) statt Namenssuche (`chair`/`bed`).
- `LookTarget`-Marker, `claim.look_at_pos` im Actor nutzen (Namenssuche `%Table` entfällt).
- Sanfte Drehung, vereinheitlichte Winkelkonvention.

### Phase 7 – Exakte Save-Positionen & Ladebild
- Stationär: Raum-ID + Slot-ID + Restzeit → `claim_interaction`, Position/Blick/State setzen.
- Laufend: Position + Ziel → von dort neu routen.
- Staff: Position + Task + Raum.
- `save_format`-Feld; altes Format lädt wie bisher (Zimmertür).
- Ladebild mit echtem Fortschritt; Actors in Portionen pro Frame erzeugen; Zeit bis Fertigstellung pausiert.
- Test mit 3–4 gesicherten alten Saves (POI-Gäste, TG, Checkout, Staff); Reparaturen zählen.

## 5. Risiken
- **GuestActor/StaffActor** (> 2000 bzw. > 1100 Zeilen): größter Aufwand liegt dort, nicht im Grid.
- **Pixel-Offsets in Raumszenen** (z. B. verschobene NavBlocker) lassen sich nicht automatisch übertragen → Handarbeit je Raum.
- **Slot-IDs** hängen heute an der Reihenfolge der Namenssuche → erst mit Phase 6 stabil.
- **Merge-Konflikte** zwischen `prealpha`-Fixes und Rework in Pathfinding/GuestActor.
- **Skalierung 1000 Gäste** (Nodes) unabhängig vom Grid – Phase 1 klärt das früh.

## 6. Offene Punkte
- [x] Freies 4-px-Bausystem: **nicht Teil der Alpha** (entschieden 12.10.2026, siehe Abschnitt 2)
- [ ] Linear-Tickets: ANG-364 erweitern oder Epic + Unterpunkte anlegen (erst nach `list`-Check, aktuell nur ANG-364 relevant)
- [ ] Messgrenzen bestätigen / Akteurzahlen anpassen
- [ ] Wo sind die Tür-Pixelpositionen (`L1`, `L2`, `T1`) definiert? (Inventur)
- [ ] Staff-Spawn-Skalierung (in StaffActor nur `Vector2.ONE` gefunden) (Inventur)
