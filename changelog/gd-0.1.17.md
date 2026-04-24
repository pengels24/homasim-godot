## Version: 0.1.17
**Datum: 2026-04-24**

### Technische Änderungen

- **ANG-170** – `Ingame.gd` God-File aufgeteilt: 790 Zeilen → 162 Zeilen Orchestrator + 3 Subsystem-Scripts.
  - **`IngameClock.gd`** (`class_name IngameClock`, ~110 Z.) – Spieluhr-Logik: Pause/Play/FF, Tagesübergang, `_game_hour/_minute/_speed`, `SECONDS_PER_GAME_MINUTE`. Signals: `day_ended(new_day: int)`, `save_requested(game_time: int)`. Eigener `_process()`.
  - **`IngameHud.gd`** (`class_name IngameHud`, ~516 Z.) – TopBar-Setup, BottomBar Radial-Fächer, Tooltip, Ruf-Bar, ContextBar. Signal: `bottom_button_pressed(idx: int)`. Public API: `set_btn_active`, `show_context_bar`, `update_day`, `trigger_button`, `get_bottom_button`.
  - **`IngameBuild.gd`** (`class_name IngameBuild`, ~165 Z.) – BuildMenu + BuildCursor Koordination, Submenü-Verwaltung. Public API: `on_button_pressed(idx)`, `close_all() -> bool`.
  - **`Ingame.gd`** – schlanker Orchestrator: lädt Hotel, startet Map, erzeugt Subsysteme via `ClassName.new()` + `configure()`, verbindet Signals.
- Subsysteme kommunizieren ausschließlich via Signals und `configure()`-Referenzen – keine Kreisabhängigkeiten.
- `_hotel`-Dict als Referenztyp an alle Subsysteme weitergegeben – Tag-Updates in `IngameClock` sofort in `Ingame._save_progress` sichtbar.
- `IngameBuild.close_all()` schließt Layer-weise (Cursor → Menü → Submenü) und wird von `Ingame._on_exit_pressed()` (ESC) genutzt.
- `IngameHud.trigger_button(idx)` führt Locked-Check durch und emittiert Signal – wird für Tastatur-Hotkeys aus `Ingame._handle_hotkey()` aufgerufen.
