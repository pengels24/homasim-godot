# HO·MA·SIM – Alpha Backlog & Roadmap
> Branch: `dev` | Start: v0.1.40 | Aktuell: v0.1.50 | Stand: 2026-07-29
> Bibel für die Alpha-Phase. Vor jeder Umsetzung hier nachschlagen!

---

## ⚠️ Getroffene Design-Entscheidungen (nicht mehr diskutieren!)

- **Personalflure:** Kommen NICHT in die Alpha. Grund: würde auf altem 1-Layer-Nav aufbauen → Brückencode. Kommen zusammen mit dem Nav-Rework (3 Layer: Gäste / Personal / Rauminneres + feineres Grid).
- **Küche/Restaurant Alpha:** Nur eine Tür (Gäste-Eingang). Zweite Tür (Personaleingang) kommt mit Personalflur-Feature.
- **Branching:** `master` = TechDemo-Bugfixes. `dev` = Alpha-Entwicklung. Nach TechDemo-Fix immer kurz `git merge master` in `dev`.

---

## 🛠 Ungeplante Fixes & Features (Aktuelle Session)
- **Upgrade-Persistenz Fix (acquired_traits):** Tief verwurzelter Bug behoben, durch den gekaufte Zimmer-Upgrades (WLAN, Klima) nach dem Speichern und Neuladen verloren gingen. Ursache: `Ingame.gd` rief nach dem Laden nochmals `configure({guest_manager: ...})` auf alle Räume auf und wischte damit die bereits geladenen Traits weg. Lösung: `configure()` in `Room.gd` setzt `acquired_traits` nur noch zurück, wenn der Key `acquired_traits` tatsächlich im übergebenen Dictionary enthalten ist.
- **POI Tooltip – Öffnungszeiten:** Der Tooltip geöffneter POIs zeigt nun die Öffnungszeiten an ("🍺 Geöffnet (08:00 - 22:00 Uhr)") statt nur "Geöffnet".
- **DevConsole & EventManager:** Savegame-Support für Events und manuelle Trigger (set-conference) für Testzwecke in DevConsole.
- **Assets:** Neue Pixel-Art Icons für Räume und Overlay-Tools hinzugefügt.
- **Dokumentation:** `AGENTS.md` um Dokumentationspflicht erweitert.
- **POI Need-Restoration:** `need_restoration` für POI-Aufenthalte implementiert. Gäste erhalten nach Besuch im Spa, Pool, Gym, Bar Stat-Veränderungen (energy, fun, saturation, thirst). Negative Werte (z.B. Energie sinkt nach Schwimmen) werden korrekt angewandt.
- **SpaSmall Kapazität & Patrouille:** Max. Gäste von 4 auf 6 erhöht. Patrol-Intervall auf 20 Sekunden gesetzt.
- **Gast Spawn-Fix (Lobby):** `Path failed: SOLID`-Fehler beim Gäste-Spawn vollständig behoben. Ursache: Reception-Waypoints liegen physisch ausserhalb der Lobby-Clearance (= im globalen AStar solid). Lösung: Gäste werden beim Spawn direkt an einem Reception-Waypoint platziert (kein Walk-Pfad nötig, da Rezeptionsmodal alles verdeckt). Nach Check-in nutzen sie lokale Lobby-Navigation zur Innentür, dann globaler AStar zum Zimmer.
- **GuestActor _execute_walk:** `WAITING_IN_LINE` in den Check für lokalen Pfad-aus-Raum aufgenommen, damit Lobby-LOCAL-Navigation beim Check-in korrekt triggert.
- **MapGrid Hilfsfunktionen:** `is_tile_walkable()` und `find_nearest_walkable_tile()` als public Hilfsmethoden ergänzt (für zukünftige Fallback-Szenarien).
- **GuestActor Logging:** SPA-ENTRY Debug-Prints (energy/fun/sat/thirst bei Eintritt) hinzugefügt für Needs-Verifikation.
- **POI-Verhalten & Wellness-Logik:** Rekursions-Bug in `GuestActor.gd` behoben, durch den Gäste den Pool sofort wieder verließen. Tiefere Logik für Wellness-Aufenthalte implementiert (1-3 Ingame-Stunden Dauer, alle 15-30 Minuten Platzwechsel). POI-Limitierung für Gäste hinzugefügt (`max_guests`). Schließzeiten der POIs werden beim Aufenthalt berücksichtigt.
- **Konferenzraum-Logik:** Chair12 als dediziertes Rednerpult konfiguriert. Gäste rotieren nun dynamisch ans Pult (10-15 Min Vortrag) und räumen den Platz danach für den nächsten.
- **Bademeister-Sitzposition:** `PoolSmall.gd` Rotation des Hochsitzes korrigiert (`+ PI/2.0`). Die optische Fehlplatzierung im Wasser liegt am Sprite-Offset.
- **Gym & Spa Initialisierung:** `claim_seat` in `GymSmall.gd` und `SpaSmall.gd` ergänzt, um fehlgeschlagene Sitzplatzsuche der Gäste zu verhindern.
- **Küchenpersonal Pathfinding:** Interne Grid-Auflösung (`LOCAL_NAV_CELL_SIZE`) in Räumen von 8 auf 4 Pixel erhöht. Damit wurde behoben, dass das Küchen-Wegenetz durch große NavBlocker (Herd/Fritteusen) im 8x8-Raster komplett unterbrochen wurde.
- **NavBlocker Debug-Overlay:** Das interne Debug-Overlay (`SHOW_DEBUG_PATHS`) zeichnet rote Kollisionsboxen und AStar-Punkte nun maßstabsgetreu auf einem CanvasLayer (`z_index = 100`) über den Möbeln und respektiert Raumrotationen korrekt.
- **Lokale Wegfindung Fixes:** Bug behoben, bei dem kurze Wege die Start-/Endpunkte überschrieben haben (`path_world[0]`). Die Wegfindung fügt Start- und Endpunkte nun korrekt ein.
- **StaffActor Wegfindung:** Mitarbeiter nutzen nun korrekt das interne AStar-Netz des Raumes, um zu ihrem `get_work_position`-Ziel zu navigieren, anstatt die Möbel auf einer geraden Luftlinie zu durchqueren.
- **KitchenSmall WorkArea:** `%ChefWorkArea` Marker wird nun korrekt ausgelesen und als dynamischer Arbeitsplatz mit Fallback (Raummitte) genutzt.
- **ServicePoint System:** Neues `%ServicePoint` Marker-System für Räume eingeführt (`Room.get_service_position()`). Reinigungskräfte und Hausmeister laufen nun in das Zimmer hinein zum Marker (oder in die Raummitte), anstatt von außen durch die Tür zu wischen.
- **ANG-324:** Abriss-Blockade für Pausenräume eingebaut (Max. Kapazität vs. Staff-Count).
- **ANG-325 / ANG-326:** Gäste-Quests für jeden Gasttyp eingebaut (10, 25, 50, 100).
- Float-Rundungsfehler bei Forschungspunkten gefixt & Währungssymbole ergänzt.
- ✅ **ParzelleBuildUI – Komplettüberarbeitung:** Panel auf CanvasLayer (Screen-Space) umgestellt, Theme-Variations wie CustomTooltip, `process_mode = ALWAYS` für Pause-Support, `build_overlay` (world-space, blockierend) entfernt, Zoom-Fix in `exit_buy_mode` (`_buy_overlay_root = null`).
- ✅ **Techtree-Texte automatisiert:** Kosten, Voraussetzungen und "Schaltet frei" generieren sich nun komplett dynamisch für Tooltips und den Codex aus der `techtree.json`.
- ✅ **CSV-Reparatur:** Fehlerhaftes Parsing durch rohe Zeilenumbrüche behoben. Hardcodierte Voraussetzungen aus `language.csv` entfernt.
- ✅ **UI-Fixes:** Float-Werte für Level und FP-Kosten zu sauberen Integern konvertiert. Leerzeichen bei Level-Strings gefixt.
- ✅ **GuestActor Pool Exit:** Bug behoben (Geisterschweben), durch den Gäste beim Verlassen des Pools fälschlicherweise den Restaurant-AStar für den Pool-Raum nutzten.
- ✅ **Bademeister Patrouille:** Radius-Berechnung in `StaffActor.gd` korrigiert (Plot-Tiles x 32px), damit er das gesamte Pool-Areal nutzt und nicht nur das obere linke Viertel und dadurch in Möbel navigiert.
- ✅ **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) für fehlende Voraussetzungen / falschen Zimmertyp integriert.
- ✅ **Multi-Tile-Room Nav-Bug:** Fehlerhafte Registrierung von Möbeln (Betten) in gedrehten Räumen (Portrait) in `Room.gd` behoben, die Gäste fälschlicherweise durch die Wand auf den Flur schlafen schickte.
- checkmark **Lobby Check-In Flow (2026-08-14):** Gaeste erscheinen sofort sichtbar an receptionX (WAITING_IN_LINE). Nach Check-in: lokale Lobby-Navigation zur Innentuer, dann globaler Korridor-AStar zum Zimmer. Root Cause: _change_state(WALKING) in _walk_to_room ueberschrieb previous_state vor _execute_walk. Fix: save/restore. Reload-Fix: spawn_active_guests() iteriert nun auch _waiting.

---

## 🧱 Phase 1 – Fundament (v0.1.40–41)
*Zuerst, weil alles andere darauf aufbaut.*

### 1.1 Max-Level auf 10 + Balancing
**Status:** ✅ Erledigt (Max-Level ist 15, `get_xp_needed_for_level` ist bis Lvl 10 exponentiell ausgebaut, `UNLOCK_LEVELS` aktiv).

- Level-Kurve von aktuell 5 auf 10 verlängern (`wiki/22_balancing_levelkurve.md` als Basis)
- EXP-Bedarf exponentiell weiterrechnen (ca. Faktor 1.5x pro Level)
- `UNLOCK_LEVELS` in `GameState.gd` für alle neuen Features vorbereiten
- Techtree: Tier-2-Gate (`req_level: 10, req_stars: 1`) bereits in `techtree.json` vorhanden – muss nur mit Content gefüllt werden
- **Abhängigkeit:** Alles andere (Techtree, Küche, Gourmetsterne) braucht definierte Level-Gates

### 1.2 Starteinstellung EXP-Boost
**Status:** ✅ Erledigt (`NewHotelModal` hat Schwierigkeitsgrade und übermittelt Multiplikatoren für EXP, Geld und Rückerstattung an Savegame).

- Im "Neues Hotel"-Dialog: Schwierigkeitsgrad wählbar
- **Casual:** +50% EXP | **Standard:** 100% | **Hard:** -25% EXP (ggf. weniger Startkapital)
- Multiplikator wird im Savegame gespeichert, beeinflusst alle EXP-Quellen global
- (`wiki/23_balancing_cash.md` enthält bereits Startkapital-Staffelung: 100k / 50k / 25k)

### 1.3 Mitarbeiter-Moralwerte aktivieren
**Status:** ✅ Erledigt (`StaffManager._process_morale` triggert jeden Mitternacht; `StaffActor.gd` rechnet bis zu 30% Strafe auf Arbeitszeit bei Moral < 50; Kündigung bei Moral <= 0).

Konzept aus `wiki/02_features/06_personal_und_aufgabensystem.md`:
- **`morale`** (0–100): Beeinflusst Arbeitsgeschwindigkeit und Fehlerrate
- **Auswirkungen:** `morale < 20` → Mitarbeiterkündigt; `morale < 50` → Arbeitsgeschwindigkeit –30%
- **Morale sinkt durch:** Überstunden / zu viele Tasks ohne Pause
- **Morale steigt durch:** Personalraum-Besuch (+5 Basis), Schulungen, regelmäßiges Gehalt
- Anzeige im Staff-Modal (Balken oder Wert)
- **Hinweis:** Personalraum-Logik (was morale.raise auslöst) kommt in Phase 3

---

## 🍳 Phase 2 – Küche & Restaurant (v0.1.42–43)
*Größtes Feature-Paket. Braucht Phase 1 (Level-Gates definiert).*

### 2.1 Szenen bauen (Workflow)
**Status:** ✅ Erledigt. `RestaurantSmall` und `KitchenSmall` sind gebaut und im Spiel. Pixel-Assets integriert.

### 2.2 Ins Spiel integrieren
**Status:** ✅ Erledigt. Erlaubte POIs eingetragen, Techtree integriert.

### 2.3 Neue Jobs
**Status:** ✅ Erledigt. Koch und Bedienung sind definiert und funktionieren im Gastronomie-Ablauf.

### 2.4 Küchen-Logik & Balancing
**Status:** ✅ Erledigt. Bestell-Queue, Köche und Bedienungen arbeiten zusammen. Gäste erhalten Essen und zahlen. Income-Kategorie "Gastro" ist im Code verankert.

---

## 🛋️ Phase 3 – Personal & Wohlbefinden (v0.1.44)
*Baut auf Moral-System aus Phase 1 auf.*

### 3.1 Personalraum (Staff Room)
**Status:** ✅ Erledigt (Szene existiert, Mitarbeiter nutzen Stühle, Tooltips und Zuweisungen funktionieren).

**Konzept:** Aus `wiki/02_features/06_personal_und_aufgabensystem.md`

- Neuer Raumtyp: Mitarbeiter wechseln in `IDLE`-State → suchen nächsten freien Personalraum
- **Slot-System:** Jeder Personalraum hat 4 Plätze ("Take the next free place")
- Mitarbeiter im Personalraum: `morale` steigt pro Minute um X
- Balancing: Wie oft / wie lang geht jemand rein? (abhängig von morale-Schwellenwert)
- **Auswirkung auf 1.3:** `morale`-Anstieg durch Personalraum erst hier vollständig implementieren

### 3.2 Tiefere Gästewerte / Gästebedürfnisse
**Status:** ✅ Erledigt (Check-In prüft Raum-Traits, UI Tooltip zeigt rot/grün Status, täglicher Zufriedenheits-Abzug greift).

Zimmer-Typen bekommen Eigenschaften (z.B. `"wlan"`, `"desk"`). Wenn Gäste einchecken, wird abgeglichen, ob das Zimmer ihre Anforderungen erfüllt. Fehlt etwas (z.B. WLAN für den Geschäftsreisenden), sinkt die Zufriedenheit und wir zeigen das im UI an. Die Basisdaten dafür (z.B. `"wlan"` beim Geschäftsreisenden) existieren bereits im Code.
- [x] **Room Hover Bug:** Moebelstuecke (speziell in Multi-Tile-Raeumen) blockieren keine Mauseingaben mehr fuer den Raum-Tooltip.
- [x] **Techtree Nodes:** Funktionale Phase-4-Nodes aus dem Demo-Lock befreit und Platzhalter entfernt.
- [x] **Techtree UI:** Tooltips zeigen nun echte Raumbeschreibungen und nutzen manuelles Word-Wrapping, um Layout-Bugs von Godot zu umgehen.
- [x] **Codex:** POI-Eintrag hinzugefügt und Tutorial-UI auf Echt-Daten-Binding umgestellt.
- [x] **RoomStatusIndicator Fix:** ProgressBar-Mindestbreite in `RoomStatusIndicator.tscn` auf 24 Pixel gesetzt, um das Kollabieren auf eine 0-Pixel schwarze Linie zu verhindern, falls keine Icons sichtbar sind.
- **Max Guests POI Limits:** Physische Bestuhlungslimits in `RestaurantSmall.gd` (20) und `Bar.gd` (8) programmatisch über `max_guests` im `get_data()` Dictionary formalisiert.
- **POI Checkliste:** `25_checklist_neuer_poi.md` im Wiki angelegt.
- **Bar Pathfinding & Logik-Fixes:** Barkeeper-Luftlinien-Wegfindung in `StaffActor.gd` auf korrektes Raumnavi (`get_local_path()`) umgestellt. `NavBlocker` in der Bar um 1 Pixel verschoben, um 4-Pixel-Korridor freizumachen. Rotations-Fehler in `Bar.gd` durch `to_global()` proaktiv gepatcht.
- **GuestActor Teleport Fix:** Fehlerhaftes Teleportieren (Hide/Fade) von Gästen im Restaurant behoben. Das versehentliche Töten von Tweens im State-Change durch `call_deferred` unterbunden.
- [x] **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik für AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
- [x] **StaffActor Bademeister Fix:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- ✅ ANG-324: Exploit-Fix – Pausenräume können nicht mehr abgerissen werden, wenn dadurch das Kapazitätslimit unter die Anzahl des eingestellten Personals fällt.
- ✅ ANG-320: Tutorial-Texte ergänzt, Räume-Kategorie im Codex hinzugefügt, Wiki-Dokumentation für Räume samt Navigation Points erstellt.
- ✅ Fix: Crash beim Laden von leeren Personalräumen.
- ✅ Fix: Lobby war nicht korrekt als Nav-Raum definiert.
- ✅ **GuestActor Wegfindung:** Bug behoben, durch den Gäste beim Verlassen des Zimmers geradewegs durch Wände liefen (Status-Machine Bug mit `previous_state` behoben).
- ✅ **CustomTooltip:** Position wird nun auf den Viewport geclempt, sodass der Tooltip nicht mehr oben aus dem Bild rutscht.
- ✅ **ANG-332:** Feature-Issue für "Weitere Parzelle" Reward im LevelUp-Screen angelegt.
- ✅ **Parzellen-Kauf-UI:** Progressbar komplett auf `ParzelleBuildUI.tscn` (Tooltip-Style) umgestellt. Inklusive 3.0-Scaling auf dem CenterContainer, um den Kamera-Zoom (0.33) exakt auszugleichen und pixel-perfect Font-Rendering zu garantieren.
- ✅ **MapGrid:** Beim Beenden des Parzellen-Kauf-Modus wird die Kamera jetzt via `center_on_entry()` zentriert (identisch zur HOME-Taste).
- ✅ **Loca-Fix:** Die fehlenden Übersetzungen (`tx.plot_buy`, `ui.confirm.plot_buy_title`, `ui.confirm.plot_buy_desc`) für den Parzellenkauf wurden in `language.csv` nachgetragen. Floating-Value-Anzeige nach Kauf integriert.
- ✅ **MapGrid-Erweiterung:** Verschmelzung der Parzellen-Grids implementiert, sodass gekaufte Parzellen zu einem großen nahtlosen Grid zusammengefügt werden (Verschiebung des Nullpunkts entfällt, Koordinaten sind global eindeutig).
- ✅ **MapGrid.tscn:** Z-Index des `FloorLayer` (Rasen) auf -2 gesetzt, damit dieser nicht mehr durch die Beton-Böden wächst.
- ✅ **Loca-Fix:** Die Kategorie `room_category.business` in `language.csv` ergänzt.
- ✅ **Techtree:** Demo-Lock für den Raum P1.2 (Konferenzraum) entfernt.
- ✅ **Codex:** Die Raum-Liste in "Tutorials & Codex" generiert sich nun dynamisch aus dem `room_registry`, statt manuell gepflegt werden zu müssen. Vorschaubilder und Tooltip-Beschreibungen werden sauber verknüpft (mit Fallbacks).
- ✅ **Bugfixes & Warnings:** Fehlerhaften Icon-Pfad für `map-pin.svg` korrigiert sowie diverse Godot-Warnungen (Integer-Division, Ternary-Kompatibilität, ungenutzte Parameter) in `MapGrid.gd` behoben.

---

## 🌳 Phase 4 – Techtree mit Leben füllen (v0.1.45)

### 4.1 Bestehende Nodes mit Inhalt versehen

Aktuell gesperrte Nodes ohne Inhalt:

| ID | Kategorie | Geplanter Inhalt |
|---|---|---|
| `G1.4` | Gastronomie | Gourmetküche (Vorstufe Gourmetsterne) |
| `W1.1` | Wellness | Spa / Massage |
| `W1.2` | Wellness | Pool / Außenbereich |
| `W1.3` | Wellness | Wellness-Paket (Kombination) |
| ~~`M1.2`~~ | ~~Management~~ | ~~Personalentwicklung (Schulungsbonus)~~ ✅ Erledigt |
| ~~`M1.3`~~ | ~~Management~~ | ~~Prozessoptimierung (Effizienz-Bonus)~~ ✅ Erledigt |
| `M1.4` | Management | Hotelleitung (Globaler Effizienz-Bonus) |
| `P1.1` | Prestige | Events (Konzerte, Messen etc.) |
| `P1.2` | Prestige | Veranstaltungszentrum |
| `P1.3` | Prestige | Prestige-Paket |
| Tier 2 | Alle | Req: Level 10 + 1 Stern – Tier-2-Nodes definieren |

- Für jeden Node: Was genau schaltet er frei? Raum? Feature? Bonus?
- Translation-Keys für alle Namen in `language.csv` nachtragen
- Level-Gates pro Node sauber definieren

---

## ⭐ Phase 5 – Events & Prestige (v0.1.46–47)

### 5.1 Zufallsereignisse
- Event-System: Zufällige Ereignisse nach Zeit/Wahrscheinlichkeit
- Beispiele: Rohrbruch, TV-Ausfall, Stromausfall, Schädlingsbefall
- Jedes Event: Dauer + Reparaturkosten + Impact auf `satisfaction` betroffener Gäste
- Benachrichtigung: Toast + Activity-Log-Eintrag + Raum-Indikator
- Spieler-Reaktion: Haustechnik schicken oder selbst bestätigen

### 5.2 Gourmetsterne
- Voraussetzung: `G1.4` (Gourmetküche) erforscht
- Bewertungs-Logik: Restaurant-Qualität (Küchen-Skills) + Ø Gästezufriedenheit über Zeit → 0–3 Sterne
- **Inspektor-Event:** Seltenes Zufallsevent (1x pro ~30 Tage). Inspektor besucht → bewertet anonym → Toast mit Ergebnis
- Sterne geben Boni: +Reputation, +Einnahmen-Multiplikator Restaurant, neue Gästetypen

---

## 📊 Abhängigkeits-Übersicht (Schnellreferenz)

```
Phase 1: Fundament
├── 1.1 Max-Level 10          ← ZUERST (Level-Gates für alles andere)
├── 1.2 EXP-Boost Starteinstellung
└── 1.3 Morale aktivieren     ← Basis für Phase 3

Phase 2: Küche & Restaurant   ← Braucht 1.1 (Level-Gates)
├── 2.1 Szenen (Peter + Workflow)
├── 2.2 Integration + Techtree G1.2/G1.3 entsperren
├── 2.3 Neue Jobs
└── 2.4 Küchen-Logik

Phase 3: Personal & Gäste     ← Braucht 1.3 (Morale-System)
├── 3.1 Personalraum           ← Braucht 1.3 (Morale-Raise-Logik)
└── 3.2 Gästebedürfnisse       ← Requirements-Array bereits vorhanden!

Phase 4: Techtree-Content      ← Braucht 2.x (Räume müssen existieren)
└── 4.1 Alle demo_locked Nodes mit Inhalt

Phase 5: Events & Prestige     ← Braucht 4.1 (G1.4 Gourmetküche)
├── 5.1 Zufallsereignisse
└── 5.2 Gourmetsterne + Inspektor
```

---

## 🔮 Spätere Features (nach Alpha / Beta)

- **Savegames - Actor-State-Serialisierung (ANG-314):** Beim Laden eines Spielstands exakte Positionen, Pathfinding und Timer (Gäste & Staff), offene Putz-Tasks und Gastro-Bestellungen wiederherstellen, um Immersion-Breaks zu verhindern. Erst implementieren, wenn alle State-Machines feature-complete sind.
- **Rework: New Game UI (Erweiterte Spieleinstellungen / Seite 2):** Vergrößerung des Fensters (ggf. mit Tabs oder 2. Seite) um feinere Anpassungen von Startkapital, Mitarbeiter-Schwellenwerten (Pausenverhalten) und anderen Startbedingungen zu ermöglichen.
- **Personalflure:** Kommt mit Nav-Rework (3 Ebenen: Gäste / Personal / Rauminneres + feineres Grid)
- **Begehbare Räume:** Abhängig von Nav-Rework
- **Zoning:** Mitarbeiter-Zonen auf der Karte (im Wiki skizziert)
- **Sicherheitszentrale:** PiP-Kamera recyceln als Überwachungssystem (ab Level 20, Wiki-Konzept vorhanden)
- **Connecting Rooms:** Zimmer mit Verbindungstür (Familie-Segment)
- **Krankheits-System:** Mitarbeiter werden krank (Wiki-Konzept vorhanden)

---

## 📁 Relevante Dateien (Schnellreferenz)

| Was | Datei |
|---|---|
| Gäste-Typen & Requirements | `data/GuestDefinitions.gd` |
| Mitarbeiter-Dict (morale) | `autoload/StaffManager.gd` |
| Gäste-Werte (satisfaction, patience) | `scenes/ingame/guest/GuestParty.gd` |
| Techtree-Struktur | `config/techtree.json` |
| Level-Kurve Konzept | `wiki/22_balancing_levelkurve.md` |
| Cash-Balancing Konzept | `wiki/23_balancing_cash.md` |
| Personal-System Konzept | `wiki/02_features/06_personal_und_aufgabensystem.md` |
| Techtree-Architektur Konzept | `wiki/02_features/01_architektur_techtree_und_fp.md` |
| Raumtypen-Referenz | `wiki/02_features/22_raumtypen_referenz.md` |
