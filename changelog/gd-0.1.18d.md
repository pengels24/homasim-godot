## Version: 0.1.18d
**Datum: 2026-04-27**

### Features & Verbesserungen

- **ANG-178** – Toast-Notification: Visuelles Feedback bei F5/F9/Autosave
  - Neuer globaler Autoload `Toast.gd`: `Toast.show("msg")` von jeder Szene aufrufbar
  - `ToastNotification.tscn` / `.gd` als CanvasLayer (layer=10): Fade-in 0.25s, Hold 2.2s, Fade-out 0.4s, dann `queue_free()`
  - `Toast.show_after_scene_change()` löst den Toast nach dem Szenenwechsel aus (F9-Quickload) – `_pending`-String überlebt den Szenenwechsel im Autoload, wird via `node_added`-Signal der neuen Root-Szene angezeigt
  - Position: Bottom-zentriert (offset_top=930, 88px Höhe), Gold-Schrift auf dunklem Hintergrund
  - Neue Translation-Keys: `toast.quicksave`, `toast.quickload.ok`, `toast.quickload.empty`

- **ANG-182** – Auto-Restore: Zuletzt genutzter Manager beim Spielstart
  - `SettingsManager`: neue Variable `last_profile_id` (int, default -1), persistiert in `[session]`-Block der `settings.cfg`
  - `GameState.select_profile()` setzt und speichert `last_profile_id` bei jeder Profilwahl
  - `MainMenu._try_restore_last_profile()`: läuft vor `_update_manager_state()`, stellt Profil sofort wieder her – wenn Profil inzwischen gelöscht wurde, wird ID zurückgesetzt und neu gespeichert

- **Settings UX-Verbesserungen** (im Rahmen von ANG-178)
  - ESC schließt das SettingsModal (`_unhandled_input`)
  - Dirty-Detection via Snapshot-Vergleich: Bei ungespeicherten Änderungen erscheint ein Verwerfen-Dialog (ConfirmModal) bevor das Modal schließt
  - `SettingsManager.reload()`: Lädt Disk-Stand neu und wendet Audio-Busse an (für Discard-Flow)
  - Neue Translation-Keys: `settings.discard.title/message/confirm/cancel`

- **Ingame ESC-Bestätigung** (im Rahmen von ANG-178)
  - ESC im Ingame öffnet jetzt ConfirmModal „Wirklich beenden?" statt sofort zur Dashboard-Szene zu wechseln
  - Neue Translation-Keys: `ingame.quit.title/message/confirm/cancel`

### Bugfixes

- **WASD/Zoom aktiv während Settings-Modal offen**: `MapGrid._process()` pollt `Input.is_key_pressed()` direkt, umgeht das Event-System. Fix: `map_grid.process_mode = PROCESS_MODE_DISABLED` beim Öffnen, `PROCESS_MODE_INHERIT` beim Schließen. Zusätzlich: `_unhandled_input`-Guard in `Ingame.gd` wenn Modal sichtbar (verhindert auch ALT+S-Doppelauslösung).
- **Settings-Modal ignoriert Kamera-Zoom**: Beim Hinzufügen als Kind von `get_tree().get_root()` (Window) wurden Window-Pixelkoordinaten statt des 1920×1080-Spielraums genutzt – Modal erschien riesig bei gezoomter Kamera. Fix: `$HUD.add_child(_settings_modal)` – HUD ist CanvasLayer, immer in Bildschirmkoordinaten.
- **Stack Overflow bei F9 (Toast-Rekursion)**: `_on_node_added` rief `show(_pending)` auf, das eine neue Node zur Root hinzufügte → `node_added` feuerte erneut → `_pending` noch gesetzt → Endlosrekursion. Fix: `_pending` zuerst in lokale Variable kopieren und auf `""` setzen, dann `show(msg)` aufrufen.

### Technische Änderungen

- `autoload/Toast.gd` – neuer globaler Singleton (in `project.godot` eingetragen)
- `scenes/shared/ToastNotification.tscn` + `.gd` – neue geteilte UI-Komponente
- `scenes/shared/SettingsModal.gd` – Snapshot-basierte Dirty-Detection, ESC-Handler, Discard-Flow
- `scenes/ingame/Ingame.gd` – Toast-Aufrufe, MapGrid process_mode, ESC-Bestätigung via ConfirmModal
- `scenes/main_menu/MainMenu.gd` – `_try_restore_last_profile()` beim Start

### Offene Backlog-Issues

- **ANG-174** – Dev-Konsole Ingame
- **ANG-175** – Save-System: Raum-Persistenz + Save-Slots
- **ANG-179** – Neues-Hotel-Dialog Redesign: Zweispaltig, Modal-Stil
- **ANG-180** – MainMenu Footer: Version + „Made with Godot"
- **ANG-181** – Toast-Position als Einstellung (oben/mitte/unten) in Settings
