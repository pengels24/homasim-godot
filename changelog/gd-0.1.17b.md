## Version: 0.1.17b
**Datum: 2026-04-24**

### Features & Verbesserungen

- **ANG-171** – View-Reset-Button im Fächermenü (◆-Icon, unten links).
  - Erster Klick: aktuelle Kameraposition + Zoom speichern → Lobby mittig, Zoom 1.0 → Icon wechselt zu rotate-ccw
  - Zweiter Klick (Jump-Back): gespeicherte Position wiederherstellen → Icon zurück zu ◆
  - Auto-Clear: WASD/Drag/Zoom nach dem Reset verwirft die gespeicherte View automatisch
  - `MapGrid`: `_entry_plot`, `reset_view()`, `_clear_saved_view()`, Signal `view_saved_changed(has_saved: bool)`
  - `IngameHud`: Signal `view_reset_requested`, zwei Icon-Nodes im Mode-Button, `set_mode_btn_saved(saved: bool)`
  - Neues Asset: `assets/icons/ic_rotate_ccw.svg`

- **ANG-172/173** – Lokaler Manager-Flow (API-unabhängig).
  - Neue Szene `scenes/manager_select/ManagerSelect.tscn+.gd`: 3 Profil-Slots (belegt = Auswählen, leer = Neu erstellen → CharacterEdit)
  - `GameState`: `active_profile_id: int`, `active_profile: Dictionary`, `select_profile(profile)`
  - `SaveManager`: `delete_hotel(hotel_id)` ergänzt
  - `MainMenu`: BtnCharacter → BtnManager; BtnPlay aktiviert wenn `active_profile_id >= 0` (nicht mehr Login-abhängig)
  - `Dashboard`: alle API-Calls durch SaveManager ersetzt (Hotels laden/erstellen/löschen); `_derive_entrance_dir()` lokal
  - `CharacterEdit`: create-Modus ruft `SaveManager.create_profile()` + `GameState.select_profile()` auf, navigiert direkt zu Dashboard
  - Neue Translation-Keys: `manager_select.title/empty_slot/btn.create/btn.select`, `menu.btn.manager`, `menu.btn.back`

- Tooltip-Position im Fächermenü: fix oben links über dem Fächer (nicht mehr über jeweiligem Button zentriert)

### Bugfixes (ANG-170 Verifikation)

- **Hotel-Name** zeigte "Hotel" statt Spielername: `Ingame._ready()` liest `GameState.selected_hotel.get("name")` nach und überschreibt SaveManager-Eintrag; `_load_hotel()` mit `is_empty()`-Guard gegen leere SaveManager-Rückgabe
- **Tagesübergang**: Uhr lief nach Mitternacht weiter statt zu stoppen → Auto-Pause + Reset auf 06:00 in `IngameClock._tick_game_clock()`
- **Spieluhr-Buttons**: StyleBoxFlat für active/normal State; Button-Texte "⏸"/"⏩" → "II">>" (Color-Emoji ignoriert `font_color`-Override)
- **Warning**: `show`-Parameter in `IngameHud.show_context_bar()` schattet `CanvasItem.show()` → umbenannt zu `shown`

### Technische Änderungen

- Ghost-Farbe: weiß/rot → grün/rot (`Color(0.35, 1.0, 0.45, 0.70)` / `Color(1.0, 0.35, 0.35, 0.65)`)
- Stamp-Mode im BuildCursor: Ghost bleibt nach Platzierung aktiv (`_spawn_ghost()` statt `queue_free()`), Rechtsklick beendet Platzierung
- PHP-API ist jetzt vollständig optional – Basis-Spielfluss funktioniert ohne laufenden Server
