## Version: 0.1.19d
**Datum: 2026-04-30**

### Features & Verbesserungen
- **ANG-166** – SimBrowser Shell komplett implementiert: F7 öffnet simulierten In-Game-Browser auf `home.sim`. Enthält 7 Kacheln (HotelCheck, HotelBooking, SimNews, Lieferanten, Michelin, angelus2010, Claude) mit farbigen Abkürzungs-Icons, Titel, Beschreibung und Schloss-Hinweis. Zwei Easter Eggs (angelus2010.sim, claude.sim) zeigen personalisierten Toast. Fenster 1500×880, minimale Titelbar ohne Label, 3-spaltige horizontale Kartenlayout. ESC und X schließen den Browser, Spieluhr pausiert während Browser offen.
- **Hauptmenü** – Button-Bereich erhält halbtransparente Hintergrundbox (α=0.28, heller als Subtitle-Box), linke Spalte linksbündig, rechte Spalte rechtsbündig, „Beenden" bleibt zentriert darunter. Wirkt weniger verloren auf dem großen Hintergrundbild.

### Bugfixes
- **Toast über Modals**: `ToastNotification.gd._ready()` setzte `layer = 10` und überschrieb damit den in der .tscn definierten Wert `layer = 200`. Zeile entfernt – Toast rendert jetzt korrekt über SimBrowser-Overlay (80), PauseMenu (90), InGameSaveModal (95) und DevConsole (127).

### Technische Änderungen
- `scenes/ingame/SimBrowser.tscn` + `SimBrowser.gd` neu: CanvasLayer 80, vollständige Browser-Chrome-Struktur (TitleBar, NavBar, TabStrip, ContentScroll), `open()`/`close()` API, `_apply_styles()`, `_build_home_sim()`, `_make_tile()`, `_on_tile_pressed()`
- `scenes/ingame/Ingame.gd`: SimBrowser instanziiert, F7→`_open_sim_browser()`, Guard in `_unhandled_input()`, `_update_map_grid_mode()` erweitert
- `scenes/shared/ToastNotification.tscn`: layer 10 → 200
- `scenes/main_menu/MainMenu.tscn`: neue `StyleBoxFlat_menu_bg` Sub-Resource; `MenuBox` PanelContainer + `MenuVBox` VBoxContainer wrappen jetzt Buttons und BtnQuit; Buttons nutzen `size_flags_horizontal=3` + `horizontal_alignment` für Links/Rechts-Ausrichtung
- `scenes/main_menu/MainMenu.gd`: `@onready`-Pfade auf neuen MenuBox/MenuVBox-Pfad aktualisiert

### Offene Backlog-Issues
- **ANG-186** – Occupancy Grid: globales Bool-Grid ersetzt `_occupied` Array + alle Tür-Formeln (Parzelle.gd, MapGrid.gd, BuildCursor.gd)
- **ANG-187** – Baukosten beim Platzieren von Räumen abziehen
- **ANG-188** – Abrissmodus mit konfigurierbarem Erstattungs-Prozentsatz (0–100 %)
