## Version: 0.1.23
**Datum: 2026-05-08**

### Features & Verbesserungen

- **ANG-190 – Zimmernummern** – Persistenter Zähler `next_z_id` im Hotel-Dict, Format `Z0001`. `_next_room_number()` in `IngameBuild.gd` erhöht den Counter pro Bau und übergibt die Nummer an `MapGrid.place_room()`. Zimmernummern werden in der RezeptionModal-Card angezeigt.
- **Tagesplaner (DAILY_SCHEDULE)** – Config-Array in `Ingame.gd` ersetzt alle hardcodierten Stunden-Checks. Einträge: `day_start(06)`, `reception_open(07)`, `guest_arrival(10/15)`, `reception_close(22)`. Neue Events einfach ins Array eintragen.
- **Rezeption-Button Lock/Unlock** – Button startet gesperrt (disabled/grau), wird um 07:00 freigeschaltet wenn Zimmer vorhanden. Sofort nach Zimmerbau freigeschaltet wenn Zeit ≥07:00 und <22:00 (`room_built` Signal aus `IngameBuild`). Um 22:00 wieder gesperrt.
- **`_restore_button_states()`** – Button-States beim Laden eines Spielstands korrekt wiederherstellen (Zeit + Zimmer-Check nach `process_frame`).
- **RezeptionModal – Zimmer-Cards** – Zeigen jetzt Label (EZ/DZ), Name, Preis, Zimmernummer statt roher type_id. `nightly_price` in allen Raumdefinitionen ergänzt (BedStandard: 60 €, BedDouble: 120 €).
- **RezeptionModal – Styling** – UI Style Guide angewendet: bg `Color(0.07,0.07,0.09,0.97)`, `corner_radius=16`, Titel 32px Gold, Col-Header 13px gedimmt, Close-Button + Action-Buttons gestylt. Content-Schrift +2px.
- **RezeptionModal – Input-Handling** – ESC schließt Modal (`_unhandled_input` mit `visible`-Guard), Klick außerhalb schließt Modal nicht mehr (Background konsumiert Event still).
- **Lobby-Filter in `get_free_rooms()`** – Filtert nach `nightly_price > 0`, Lobby taucht nie in der freien Zimmerliste auf.

### Bugfixes

- **Aseprite-Texturen** – Alle 8 `.import`-Dateien hatten `importer="noop"` (kein Texture-Output). Fix: `importer="aseprite_wizard.plugin.static-texture"` + `type="PortableCompressedTexture2D"`. Betroffen: BuildPanel, BottomBar, alle HUD-Button-Assets.
- **Translation-Crash** – `bucket_table_size == 0` in `optimized_translation.cpp` durch korrupte Binary-Dateien. Fix: `de.de.translation` + `de.en.translation` gelöscht → Godot regeneriert beim nächsten Start.
- **INTEGER_DIVISION Warnings** – `get_game_time() / 60` in Ingame.gd löste Warnings aus. Fix: `get_hour() -> int` direkt in `IngameClock` exponiert.
- **Maus-Cursor** – HUD BottomBar-Buttons und BuildPanel-Buttons zeigten keinen `CURSOR_POINTING_HAND`. Fix in `_make_bar_btn()` (IngameHud) und `_make_icon_btn()` (BuildPanel).
- **UNUSED_SIGNAL `hud_side_changed`** – Signal wurde nie emittiert. Fix: `hud_side_changed.emit()` am Ende von `SettingsManager.save()`.

### Technische Änderungen

- **`IngameBuild.gd`** – Signal `room_built(room_type_id)` + `_next_room_number()`.
- **`IngameClock.gd`** – `get_hour() -> int` ergänzt.
- **`IngameHud.gd`** – `set_btn_locked(idx, locked)` Public API; Rezeption-Button startet `locked: true`.
- **`GuestManager.gd`** – `spawn_guests() -> int` (public, gibt Anzahl zurück), `has_bookable_rooms() -> bool`, `on_hour_passed` nur noch `_tick_patience()`.
- **`MapGrid.gd`** – `place_room()` nimmt `room_number: String = ""` Parameter.
- **`ToastNotification.gd`** – `HOLD_SEC`: 2.20 → 3.50.
- **`translations/de.csv`** – 4 neue Keys: `toast.rezeption.open`, `toast.rezeption.too_early`, `toast.rezeption.no_rooms`, `toast.rezeption.guests_arrived`.

### Offene Backlog-Issues

- **Rezeption-Matching** – Check-in Matching-Logik läuft noch quer (nächste Session)
- **ANG-192** – Versatz-Fall + Möbel-Artefakt an erweiterter Wandseite
- **ANG-193** – Wall-System Refactor (TileMap-Außenkontur + Trennwände)
