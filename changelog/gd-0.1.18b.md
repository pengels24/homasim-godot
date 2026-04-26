## Version: 0.1.18b
**Datum: 2026-04-26**

### Features & Verbesserungen

- **ANG-152** – Einstellungs-Modal vollständig implementiert.
  - `scenes/shared/SettingsModal.tscn` + `SettingsModal.gd`: Modal mit 4 Tabs (Gameplay / Audio / Oberfläche / Steuerung), 1000×600 px, dunkles Design mit Goldrand (konsistent mit ManagerSelect)
  - `autoload/SettingsManager.gd`: Neuer Singleton; speichert `autosave_enabled`, `autosave_interval_minutes`, `ff_speed`, `music_volume`, `sound_volume`, `ui_scale` in `user://settings.cfg`
  - Gameplay-Tab: Autosave-Toggle + Intervall-Slider (5/10/15/30 Min.), Schnellvorlauf-Slider (×5/×10/×20)
  - Audio-Tab: Hintergrundmusik + Sound je 0–100 % kontinuierlich
  - Oberfläche-Tab: UI-Skalierung 75/100/125/150 %
  - Öffnen: `btn_settings` im MainMenu + Alt+S Hotkey; `btn_quit` wird dabei ausgeblendet (wie beim ManagerSelect)
  - `project.godot`: SettingsManager als Autoload registriert

- **ANG-176** – ManagerSelect UX-Überarbeitung für Modal-Konsistenz.
  - Titelzeile mit goldener Schrift (32pt), zentriert; ✕-Button oben rechts ersetzt den alten Zurück-Button
  - Feste Kartengröße 1000×600 px (wie SettingsModal)
  - Avatar-Vorschau (CharacterDisplay, 50 % Skalierung) in belegten Slots über dem Manager-Namen
  - Avatar-Layout via `AvatarBox`-Wrapper (`clip_contents`, `custom_minimum_size = 90×120`) + `CharacterDisplay`-Instanz (`layout_mode = 0`, `offset_right/bottom = 180/240`) – umgeht Minimum-Size-Override-Problem von PackedScene-Instanzen in VBoxContainer
  - `ManagerSelect.gd`: Farb-Konstanten `SKIN_COLORS`, `HAIR_COLORS`, `OUTFIT_COLORS` als `const`-Dictionaries

### Bugfixes

- `translations/de.csv`: Doppelte Settings-Keys (Zeilen 509–513) enthielten Großschreibung (`GAMEPLAY`, `AUDIO`, `OBERFLÄCHE`, `STEUERUNG`, `SPEICHERN`) und überschrieben die korrekten Einträge. Behoben auf `Gameplay`, `Audio`, `Oberfläche`, `Steuerung`, `Speichern`.
- `SettingsModal.gd`: `find_child("Slider", true, false)` statt `get_node("Slider")` für dynamisch erstellte Slider-Reihen – `get_node` sucht nur direkte Kinder, `find_child` mit `owned=false` findet auch dynamisch erzeugte Nodes rekursiv.
- `MainMenu.tscn`: UID-Mismatch `uid://settingsmodal` → `uid://cw7c5frsdut8j` für SettingsModal-Ressource korrigiert.
- `SettingsModal.tscn`: Alle ungültigen `add_theme_*_override(...)`-Methodenaufrufe durch korrekte `theme_override_*/name = value`-Properties ersetzt (Godot tscn-Parser bricht bei Zeilen ohne `=` ab, alle nachfolgenden Nodes waren nicht erreichbar → 15+ „Node not found"-Fehler).

### Offene Backlog-Issues

- **ANG-174** – Dev-Konsole Ingame (Todo)
- **ANG-175** – Save-System: Raum-Persistenz + Save-Slots (In Progress)
