## Version: 0.1.5
**Datum: 2026-04-16**

### Features & Verbesserungen
- **ANG-148 (Fortsetzung)** – TopBar HUD vollständig überarbeitet:
  - Höhe 80px (PNG 50px + Margins 15px oben/unten)
  - `StatDay` aus StatsSection entfernt – TAG nur noch in TimeSection
  - `NameSection` + `LevelSection` als konsistente Key/Value-Paare (wie alle anderen Stats)
  - Hotel-Name: `size_flags_h = EXPAND_FILL` + `text_overrun_behavior = TRIM_ELLIPSIS`
  - KAPITAL: min 150px, Value rechtsbündig
  - GÄSTE: drei Labels (WaitLbl grün / ActiveLbl gold / OutLbl rot) in HBoxContainer
  - AP: `"x / 100"` Format, min 90px
  - RUF: programmatische Gradient-Bar (5 ColorRect-Segmente rot→grün) + weißer Indikator, `x / 1000`-Label
  - FP: min 70px
  - Font-Größen: Key-Labels 13px, Stat-Values 18px, TimeLbl 30px, Buttons 50×50 / font 20px
  - Alle vertikalen Separatoren entfernt
  - Value-Felder mit `_apply_value_box()` (dunkler Bg + grauer Border, Radius 3)
  - Gäste-Badges via `_apply_guest_badge()` (farbig-transparenter Bg + Border)

- **ANG-148 (Fortsetzung)** – BottomBar komplett neu gebaut als Icon-Bar:
  - 8 Icon-Buttons (F1–F7 + ALT+S) + Exit-Button (ESC), 70×70px
  - Lucide SVGs von `external-assets/` nach `res://assets/icons/` kopiert (`stroke="white"` statt `currentColor`)
  - Verfügbare Icons: Help, Buildmode, Reception, Staff, Techtree, Browser, Settings, Logout
  - Button-Mapping: F1 Hilfe, F2 Bauen, F3 Rezeption, F4 Personal (gesperrt), F5 – (gesperrt/unbelegt), F6 Forschung (gesperrt), F7 SIM-Browser, ALT+S Einstellungen, ESC Hauptmenü
  - 3 States: normal (grauer Border), hover (gold Border), active (gold Hintergrund)
  - Gesperrte Buttons: Icon + Label auf 0.38 Opacity gedämpft, zentriertes 🔒-Emoji (22px), kein dunkles Overlay
  - Runde Dot-Indikatoren (8×8px Panel + StyleBoxFlat Radius 4): F3 grün, F7 grün
  - Tooltip: schwebt zentriert über Button (nach process_frame positioniert), 14px, Gold-Border
  - Toggle-Verhalten: gleichen Button nochmal klicken schließt Submenü + deaktiviert
  - ALT+S über `_unhandled_input` abgefangen (da Modifier-Key)
  - `_set_btn_active(idx)` überschreibt normal/hover StyleBox für aktiven Button
  - `CenterContainer` als Wrapper in `bottom_anchor` für zuverlässige Zentrierung

### Bugfixes
- `_ruf_indicator` nil-Crash: `_build_ruf_bar()` muss vor `_setup_hud()` laufen – Reihenfolge in `_ready()` korrigiert
- `_active_submenu_idx` war am Ende der Datei als lose var deklariert – in den Deklarationsblock verschoben
- Alter `_on_bottom_button()`-Bug: `_active_submenu = null` vor dem `idx`-Vergleich → Toggle-Check schlug immer fehl. Fix: Toggle-Check vor `queue_free()`

### Technische Änderungen
- `scenes/ingame/Ingame.gd`: Neue vars `_active_btn_idx`, `_bb_sb_*`, `_tooltip_*`, `_bb_btn_defs[]`
- `scenes/ingame/Ingame.gd`: `_make_bottom_button()` ersetzt durch `_make_icon_btn(idx, def)` + `_set_btn_active()` + `_show_tooltip()` + `_hide_tooltip()`
- `scenes/ingame/Ingame.tscn`: TopBar-Struktur überarbeitet (Nodes umbenannt/entfernt/ergänzt)
- `assets/icons/`: Neues Verzeichnis mit 8 Lucide-SVGs (white stroke)
- `translations/de.csv`: `ingame.btn.help`, `ingame.btn.empty`, `ingame.btn.research`, `ingame.btn.settings`, `ingame.btn.simbrowser` hinzugefügt

### Offene Backlog-Issues
- **ANG-149** – Tutorial-Szene
- **ANG-150** – Credits + Social Links
- **ANG-151** – Button-Font-Polishing
- **ANG-152** – Settings-Screen (ALT+S): Gameplay, Audio, Oberfläche
- **ANG-153** – Lucide-Icons: Restliche Buttons (F7 SIM-Browser hat noch Text-Fallback ★)
