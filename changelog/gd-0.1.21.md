## Version: 0.1.21
**Datum: 2026-05-07**

### Features & Verbesserungen

- **ANG-195 – BuildPanel (neues Baumenü)** – Radial-Fächer-Menü vollständig durch horizontales BuildPanel ersetzt. Panel öffnet sich über der BottomBar mit Kategorie-Tabs (auto-discovered aus ROOM_REGISTRY) + 5-spaltigem Item-Grid. Tabs nur sichtbar wenn Kategorie Einträge hat. Aktiver Item-Button bleibt hervorgehoben solange der Cursor aktiv ist; `clear_active_item()` setzt Highlight beim Abbrechen zurück. `BuildMenu.gd` + `BuildMenu.tscn` entfernt.
- **ANG-195 – BuildPanel-Animation** – Panel fährt beim Öffnen aus der BottomBar hoch (Slide + Fade-In, 0.20s EASE_OUT CUBIC + 0.16s Linear) und beim Schließen wieder herunter (0.16s EASE_IN + 0.12s). Tween-Callback übernimmt `queue_free()` — kein `await` nötig.
- **ANG-195 – Custom-Tooltips BuildPanel** – Item-Buttons und Kategorie-Tabs zeigen Custom-Tooltips (gleicher Stil wie IngameHud: dunkel, Gold-Border). Tooltip wird als Geschwister-Node in der CanvasLayer hinzugefügt (`get_parent().add_child()`); `tree_exiting` räumt ihn auf. Ersetzt Godot-Builtin `tooltip_text` (semi-transparent).
- **ANG-195 – Settings: HUD-Seite** – Neuer Eintrag „Menüleiste Position" im Oberfläche-Tab: 2-Button-Gruppe Links/Rechts (gleicher Stil wie Toast-Position). Wirkt sofort live via `SettingsManager.hud_side_changed` Signal — kein Save nötig für Vorschau. `IngameHud.reposition_hud()` verbindet sich auf das Signal.
- **ANG-195 – MusicControls Auto-Reposition** – Audio-Controls wechseln automatisch auf die gegenüberliegende Seite der BottomBar. HUD links → Controls unten rechts; HUD rechts → Controls unten links. Reagiert live auf `SettingsManager.hud_side_changed`.
- **HOME-Taste – Ansicht zurücksetzen** – `KEY_HOME` ruft `map_grid.reset_view()` auf (Toggle: einmal = Ansicht speichern + zum Eingang; nochmal = zurück zur gespeicherten Position). Sprung-Button-Tooltip zeigt jetzt `"HOME · Ansicht zurücksetzen"`.

### Bugfixes

- **Ghost-Korruption beim Raumwechsel** – Wenn im BuildPanel von EZ auf DZ gewechselt wurde, feuerte das `tree_exited`-Signal des alten Cursors nach dem neuen Cursor-Assign und nullte `_build_cursor`. Fix: Guard `if _build_cursor == cursor:` in der `tree_exited`-Lambda.
- **BuildCursor `_input` → `_unhandled_input`** – Klicks ins BuildPanel wurden vom Cursor konsumiert. Fix: `_unhandled_input` damit UI-Klicks Priorität haben.
- **Parcel-Bounds-Check in `_try_place()`** – Platzierung war auch außerhalb der Parzelle möglich wenn Maus knapp daneben. Fix: Bounds-Prüfung vor dem Snap-Berechnung.
- **Dummy-Panel für Settings/Browser** – idx 1 (Browser) und idx 2 (Settings) öffneten Dummy-Panel statt die echten Modals. Fix: Routing in `Ingame._on_bottom_button_pressed()`.

### Technische Änderungen

- **`SettingsManager.gd`** – Signal `hud_side_changed` hinzugefügt; wird von SettingsModal beim Button-Klick emittiert.
- **`SettingsModal.gd`** – `_make_hud_side_row()` nach Toast-Position-Pattern; `hud_side` in `_take_snapshot()` für Dirty-Detection.
- **`IngameBuild.gd`** – `_animate_panel_in()` + `_close_build_panel_animated()` Hilfsmethoden; `close_all()` nutzt animiertes Schließen.
- **`IngameHud.gd`** – `SettingsManager.hud_side_changed` → `reposition_hud` Connect in `configure()`.
- **`BuildPanel.tscn` + `BuildPanel.gd`** – Neue Dateien; ersetzen `BuildMenu.tscn` + `BuildMenu.gd` vollständig.
- **`translations/de.csv`** – Schlüssel `settings.ui.hud_side`, `.left`, `.right` hinzugefügt.

### Offene Backlog-Issues

- **ANG-192** – Versatz-Fall (Räume nicht 1:1 ausgerichtet); Möbel-Artefakt an erweiterter Wandseite
- **ANG-193** – Wall-System Refactor (TileMap-Außenkontur + Trennwände, mittelfristig)
- **ANG-191** – Abreiß-Funktion, Zimmernummern, XP-Level-Kurve, FP-Quellen
