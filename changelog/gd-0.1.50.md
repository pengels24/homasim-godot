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
- **Rezeptions-UI Check-In:** Logik im Check-In-Modal aufgeteilt (`ask_price` vs `ask_requirements`) und neuen Tooltip (`Kompromiss - Gast fragen`) für fehlende Voraussetzungen / falschen Zimmertyp integriert.
- **Pool-Patrouille Bademeister:** `get_patrol_target()` in `PoolSmall.gd` implementiert, sodass der Bademeister (`StaffActor`) nun sicher am Beckenrand patrouilliert, statt durchs Wasser zu laufen.
- **Debugger-Cleanup:** Godot-Warnings beim Start behoben (Shadowed Variables `is_active`/`ready`, Unused Signals in GameState/GuestManager, Integer Division in ParzelleBuildUI, sowie leere Tween-Errors in GuestActor gefixt).
- **GuestActor Teleport Fix:** Fehlerhaftes Teleportieren (Hide/Fade) von Gästen im Restaurant behoben. Das versehentliche Töten von Tweens im State-Change durch `call_deferred` unterbunden.
- **StaffActor Patrouillen Fix:** Die Kellner blieben am Restaurant-Rand stecken (bzw. liefen durch Tische). Fallback-Mittelpunkte werden nun rotiert `to_global()` ausgewertet und die Such-Logik für AStar-begehbare Punkte nutzt nun korrekt das bereits gelieferte globale Ergebnis `get_random_walkable_local_pos()`.
