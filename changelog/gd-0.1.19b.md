## Version: 0.1.19b
**Datum: 2026-04-29**

### Features & Verbesserungen

- **ANG-176** – PauseMenu + InGameSaveModal vollständig implementiert, getestet und visuell poliert.
  - `PauseMenu.tscn/.gd` (CanvasLayer 90): 5 Buttons (Weiterspielen, Speichern, Laden, Einstellungen, Zum Hauptmenü), ESC schließt; Weiterspielen-Button grün mit dunkler Schrift (fix über `font_focus_color`-Override in `_ready()`), Nav-Buttons blau, Beenden rot.
  - `InGameSaveModal.tscn/.gd` (CanvasLayer 95): Unified Modal für Save- und Load-Modus. Save: 5 manuelle Slots, Name-Eingabefeld, grüner Speichern-Button. Load: 5 manuelle + 5 Autosave-Slots, grüner Laden-Button. Leere/unbefüllte Slots: Button disabled + CURSOR_ARROW; Slot gewählt: enabled + CURSOR_POINTING_HAND. Name-Eingabefeld: `editable=false` + `focus_mode=FOCUS_NONE` solange kein Slot gewählt.
  - `Ingame.gd`: ESC-Handler öffnet PauseMenu; alle Overlays über `_update_map_grid_mode()` koordiniert. Beenden-Flow: PauseMenu wird ausgeblendet bevor ConfirmModal erscheint (z-Order-Fix: ConfirmModal läuft als HUD-Kind ohne eigenen CanvasLayer).

### Bugfixes / Design-Fixes

- **ConfirmModal unter PauseMenu** – ConfirmModal (`$HUD`-Kind, kein CanvasLayer) wurde hinter PauseMenu (layer=90) gerendert. Fix: PauseMenu vor ConfirmModal-Öffnen ausblenden; `cancelled`-Signal stellt PauseMenu wieder her.
- **Grüner Button weiße Schrift bei Fokus** – Godot wechselt bei `grab_focus()` zu `font_focus_color` (Default weiß), nicht zu `font_color`. Fix: `add_theme_color_override("font_focus_color", dark)` in `PauseMenu._ready()`.
- **Name-Eingabefeld fokussierbar ohne Slot** – `editable = false` allein verhindert Fokus nicht. Fix: zusätzlich `focus_mode = Control.FOCUS_NONE` setzen; beim Slot-Wählen wieder auf `FOCUS_ALL`.

### Design-Polish

- **Modal-Stil vereinheitlicht** – Alle Modals (PauseMenu, InGameSaveModal, SettingsModal) teilen jetzt identischen Panel-Stil: `border_color = Color(0.918, 0.702, 0.031, 0.40)` (Gold), `shadow_color = Color(0.918, 0.702, 0.031, 0.15)` (Gold-Glow), `shadow_size = 12`. Kein blauer Panel-Glow mehr.
- **Close-Button (✕)** – Einheitlich in allen Modals: `Color(0.14,0.14,0.18)` normal, `Color(0.24,0.24,0.30)` hover, Grauton Schrift.
- **Hover-Feedback auf alle Buttons** – Gold-Border auf allen Hover-StyleBoxes der PauseMenu-Buttons (grün, blau, rot).
- **Titel in Normal Case** – Modal-Titel: "Pause", "Spiel speichern", "Spiel laden" (nicht GROSSBUCHSTABEN). Werte in `de.csv` angepasst.
- **Nav-Buttons Gold→Blau** – PauseMenu-Navigation (Speichern, Laden, Einstellungen) von Gold auf Blau geändert (Button-Farbkonvention: Gold=Navigation Hauptmenü, Blau=Sekundär-Navigation).

### Technische Änderungen

- `scenes/ingame/PauseMenu.gd` + `PauseMenu.tscn`: neu angelegt
- `scenes/ingame/InGameSaveModal.gd` + `InGameSaveModal.tscn`: neu angelegt
- `scenes/ingame/Ingame.gd`: ESC-Handler, PauseMenu/SaveModal-Verdrahtung, `_update_map_grid_mode()` Helfer
- `scenes/ingame/Ingame.tscn`: PauseMenu + InGameSaveModal als CanvasLayer-Kinder eingebunden
- `translations/de.csv`: Keys `saveslots.save.title`, `saveslots.load.title`, `pausemenu.btn.quit` aktualisiert
- `_dev/docs/ui-style-guide.md`: neu angelegt – verbindliche Referenz für alle UI-Komponenten (Modal-Panel, Titel, Close-Button, Button-Typen, Slot-Zeilen, Typografie, Canvas-Layer-Reihenfolge)
- `CLAUDE.md`: Button-Farbkonzept-Tabelle entfernt; Style-Guide-Direktive ergänzt

### Offene Backlog-Issues

- **ANG-180** – MainMenu Footer (Version + „Made with Godot 4") – noch offen
