# Changelog â gd-0.1.50
> Datum: 2026-07-29 | Branch: `dev`

---

## ð Bugfixes

- **Parzelle â Rechtsklick/Pan geblockt:** Der `build_overlay` (world-space `ColorRect` mit `mouse_filter = STOP`) lag Ã¼ber der gesamten Parzelle und fraÃ alle Mouse-Events. Behoben durch vollstÃ¤ndiges Entfernen des Overlays.
- **Parzelle â Panel skalierte mit Zoom:** `build_overlay` war in World-Space und wuchs mit dem Kamera-Zoom. Behoben durch Entfernen des Overlays; Panel verbleibt auf dem CanvasLayer (Screen-Space) und skaliert nie.
- **Parzelle â Panel unsichtbar nach Parzellenkauf:** `_process` lief nicht wÃ¤hrend Godots Pause-Modus (`PROCESS_MODE_INHERIT`). Dadurch wurde die Panel-Visibility nie auf `true` gesetzt. Behoben durch `process_mode = Node.PROCESS_MODE_ALWAYS` in `Parzelle._ready()`.
- **MapGrid â Zoom nach Buy-Modus geblockt:** `exit_buy_mode()` rief `queue_free()` auf `_buy_overlay_root` auf, setzte die Variable aber nicht auf `null`. Da `is_instance_valid()` fÃ¼r queue_free'd Nodes noch `true` liefert, war `_on_input_camera_zoom()` weiterhin geblockt. Behoben durch `_buy_overlay_root = null` direkt nach `queue_free()`.
- **MapGrid â `_show_built_parcels`:** Veralteter Zugriff auf `p.build_overlay` (existiert nicht mehr) entfernt. Panel-Visibility wird jetzt vollstÃ¤ndig von `Parzelle._process` Ã¼bernommen.

---

## â¨ Verbesserungen

- **ParzelleBuildUI â Theme-konform:** `ParzelleBuildUI.tscn` komplett auf Standard-Theme-Variations umgestellt:
  - `theme_type_variation = "TooltipPanel"` (Hintergrund)
  - `theme_type_variation = "TooltipHeader"` (Titel-Label)
  - `theme_type_variation = "TooltipProgressBar"` (Fortschrittsbalken)
  - `theme_type_variation = "TooltipText"` (Zeit-Label)
  - Struktur identisch zu `CustomTooltip.tscn` (MarginContainer â VBoxContainer â HSeparator)
  - Alle hardcodierten Farben, FontgrÃ¶Ãen und StyleBoxes entfernt

- **ParzelleBuildUI â Zentralisierte Visibility-Logik:** Statt verstreuter `visible`-Calls in `set_buy_mode`, `start_construction` und `buy` steuert jetzt ausschlieÃlich `_process` die Panel-Sichtbarkeit (`is_constructing AND NOT _in_buy_mode`). Kein Timing-Problem mehr.

- **ParzelleBuildUI â CanvasLayer Screen-Space:** Panel verbleibt in Screen-Space (CanvasLayer layer=10), nie verwaschen bei Zoom, identische GrÃ¶Ãe unabhÃ¤ngig vom Kamera-Zoom.

---

## ðï¸ GeÃ¤nderte Dateien

| Datei | Art der Ãnderung |
|---|---|
| `scenes/ingame/map/Parzelle.gd` | `build_overlay` entfernt, `process_mode = ALWAYS`, Visibility-Logik zentralisiert in `_process` |
| `scenes/ingame/map/ParzelleBuildUI.tscn` | Komplett neu â Theme-Variations, MarginContainer, kein Custom-Style |
| `scenes/ingame/map/MapGrid.gd` | `exit_buy_mode`: `_buy_overlay_root = null` nach `queue_free()`; `_show_built_parcels`: `build_overlay`-Referenz entfernt |

### UI / Tutorials / Texte (Aktuelle Session)
- **Tutorial-Bilder:** Bilder fÃ¼r Kategorien GÃ¤ste, RÃ¤ume und Forschung um 30% verkleinert.
- **Tutorial-Texte RÃ¤ume:** Formatierung mit echten ZeilenumbrÃ¼chen in language.csv via Python-Skript eingefÃ¼gt.
- **Codex-Tabs:** Alten Codex-Tab in GÃ¤ste umbenannt, PrÃ¤fix Neuer GÃ¤stetyp: entfernt, neuen leeren Codex-Tab angehÃ¤ngt.
- **Techtree-Texte:** Python-Skript geschrieben, um abgeschnittene Techtree-Texte in language.csv zu reparieren (Kommas maskiert) und zerstÃ¶rte Umlaute zu korrigieren. Doppelte Keys entfernt.
- **Issue angelegt:** Issue fÃ¼r Automatisierung der Techtree-Texte in den Backlog aufgenommen.

### UI & QoL
- Techtree-Texte automatisiert: Voraussetzungen, Kosten und Freischaltungen generieren sich nun automatisch für Tooltip und Codex.
- Float-Rundungsfehler (z.B. Level 3.0 statt 3) im Techtree gefixt.
- CSV-Import repariert (versteckte Zeilenumbrüche).

### Codex & Techtree Tooltips (Aktuelle Session)
- **POI-Codex:** Neuen Codex-Eintrag für 'Point of Interest (POI)' in 	utorials.json und language.csv angelegt.
- **Tutorials UI:** Platzhalter-Text aus dem 'Codex'-Reiter (ModalContentTutorials.gd) entfernt, sodass jetzt echte Einträge aus der Datenbasis geladen werden.
- **Techtree Tooltips:** Die Tooltips im Forschungsbaum (ModalContentTechtree.gd) ignorieren nun nicht mehr die schönen Beschreibungstexte, sondern zeigen sie ganz oben an. Der generische 'Schaltet neue Inhalte frei'-Platzhalter wurde dafür komplett entfernt.
- **Tooltip Word-Wrap:** Ein manueller Word-Wrap (_wrap_text) für die Techtree-Tooltips wurde implementiert, um den Godot 4 Bug zu umgehen, bei dem Tooltip-Panels bei extrem langen einzeiligen Texten (wie bei G1.2/G1.3) die Proportionen des Hintergrunds zerstören.
- **Tutorial-Texte:** Die harten Techtree-Voraussetzungen in den Tutorial-Beschreibungen wurden per Skript um die tatsächlichen Namen erweitert (z.B. 'Techtree Z1.2 (Familienzimmer)').
