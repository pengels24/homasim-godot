## Version: 0.1.19e
**Datum: 2026-04-30**

### Features & Verbesserungen
- **ANG-186** – Occupancy-Grid auf 4-Wert-System umgestellt (0=frei, 1=Body, 2=Exit, 3=Wand). Tür-zu-Tür-Platzierungen korrekt erlaubt (Exit überschreibt Exit), Raum-Body blockiert fremde Exits, Wandtiles (Wert 3) sind permanent und werden nie überschrieben. `_occ_mark_wall()`, `_occ_mark_exit()`, `_occ_exit_free()` als dedizierte Hilfsmethoden in `MapGrid.gd`.
- **Hintergrundmusik-System** – Neuer `MusicManager`-Autoload: erkennt `menu_music_*.mp3` und `ingame_music_*.mp3` automatisch per sequenziellem Scan (funktioniert auch in Exports). Zwei `AudioStreamPlayer`-Kinder auf je eigenem Bus (`Menu Music` / `Music`). Fade-In (1,5s) und Fade-Out (1,0s) bei jedem Track-Start/-Stop. Shuffelt die Playlist bei jedem `play_menu()` / `play_ingame()`-Aufruf neu. API: `play_menu()`, `play_ingame()`, `stop()`, `toggle_pause()`, `next_track()`, Signal `playback_changed`.
- **MusicControls-HUD** – Neues Widget `scenes/ingame/hud/MusicControls.tscn` unten rechts im Ingame-HUD: Pause/Resume-Toggle (`II` / `▶`) und Next-Track-Button (`▶▶`). Stil entspricht den Fan-Buttons (dunkler Hintergrund, Gold-Border, Radius 10). Aktualisiert sich über `MusicManager.playback_changed`-Signal.
- **SettingsManager + SettingsModal** – Neue Property `menu_music_volume` (Bus `Menu Music`) mit eigenem Volume-Slider „Menü-Musik" zwischen Music- und Sound-Slider.

### Bugfixes
- **CSV-Duplikate** – 5 doppelte Translation-Keys aus `translations/de.csv` entfernt (`dashboard.title`, `register.title`, `register.error.username_in_use`, `settings.title`, `settings.btn.save`). Behoben den `bucket_table_size == 0` Parse-Error beim Laden.
- **Parzelle.tscn UIDs** – UIDs der 4 Eck-Wand-Texturen (`wall_top_left/right`, `wall_bottom_left/right`) korrigiert auf die tatsächlichen `.import`-UIDs. Vermeidung der Fallback-Warnings beim Szenenwechsel.
- **Credits-Musik-Überlappung** – `Credits.gd` ruft jetzt `MusicManager.stop()` vor `_start_music()`, sodass Menü-Musik und Credits-Musik nicht gleichzeitig spielen.

### Technische Änderungen
- `autoload/MusicManager.gd` – neu; registriert in `project.godot`
- `autoload/SettingsManager.gd` – `menu_music_volume` + `_ensure_bus("Menu Music")` in `_apply_audio()`
- `scenes/shared/SettingsModal.gd` – Menü-Musik-Slider ergänzt
- `scenes/main_menu/MainMenu.gd` + `scenes/dashboard/Dashboard.gd` – `MusicManager.play_menu()` in `_ready()`
- `scenes/ingame/Ingame.gd` – `MusicManager.play_ingame()` in `_ready()`, `MusicControls` instanziiert in `$HUD`
- `scenes/ingame/hud/MusicControls.tscn` + `MusicControls.gd` – neu

### Offene Backlog-Issues
- **ANG-187** – Baukosten beim Platzieren von Räumen abziehen; Konzept für Kapital, XP, AP, FP ausarbeiten
- **ANG-188** – Abrissmodus mit konfigurierbarem Erstattungs-Prozentsatz
