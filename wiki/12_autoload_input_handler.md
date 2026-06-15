# 🌐 Autoload: InputHandler.gd

### 🎯 Zweck (TL;DR)

Der Türsteher für Tastatur und Maus. Der `InputHandler` fängt jegliche Eingaben ab, prüft, in welchem Spiel-Zustand (Modus) sich der Spieler gerade befindet, und leitet die Eingaben als Signale an die entsprechenden Systeme (z.B. Kamera oder UI) weiter.

### 🛡️ Zuständigkeiten

- **Modus-Verwaltung (`InputMode`):** Verwaltet die exklusiven Zustände (`NORMAL`, `BUILD`, `MODAL`, `PAUSE`, `CONSOLE`).
- **Kamerasteuerung:** Verarbeitet WASD, Mausrad-Zoom, Tastatur-Zoom und das rechte-Maus-Dragging für die Kamera (gibt es als reine Richtungsvektoren weiter).
- **Hotkey-Routing:** Lauscht auf globale Hotkeys (`ESC`, `B`, `R`, Quicksave/Load) und alarmiert das HUD oder den Orchestrator.
- **Pin-Logik (Kamera-Reset):** Steuert das intelligente System für die "Kamera zurücksetzen"-Taste (Pos1). Setzt und "killt" den Pin basierend auf spezifischen User-Eingaben.
- _(Nicht zuständig für: Die tatsächliche Bewegung der Nodes (macht `MapGrid.Camera2D`), das Bauen von Objekten oder das Öffnen der UI-Fenster. Er ist nur der Bote!)_

### 💾 Zentrale Variablen (State)

- `current_mode` _(InputMode)_: Das absolute Gesetz. Bestimmt, welche Tasten gerade funktionieren dürfen. Ist ein Modal offen (`InputMode.MODAL`), blockiert der InputHandler _alles_ außer der `ESC`-Taste.
- `is_view_saved` _(bool)_: Merkt sich, ob der Spieler aktuell eine Kamera-Position "gepinnt" hat (für die Pos1-Logik).
- `_reset_frame_lock` _(int)_: Ein Sicherheits-Schloss (Debouncer), der verhindert, dass die "Pos1"-Taste in einem einzigen Frame doppelt triggert.

### 📡 Wichtige Signale

- **Kamera-Signale:** `sig_camera_pan_requested`, `sig_camera_zoom_requested`, `sig_camera_drag_started`, `..._moved`, `..._ended`. Das `MapGrid` lauscht exklusiv auf diese Signale, um sich zu bewegen.
- **Pin-Signale:** `sig_kill_reset_pin_requested`, `sig_camera_save_view_requested`, `sig_camera_restore_view_requested`.
- **Hotkey-Signale:** `sig_hotkey_build_menu_requested`, `sig_hotkey_reception_requested`, `sig_hotkey_escape_pressed`, etc.

### ⚙️ Kern-Funktionen

- **`_process(delta)`:** Behandelt kontinuierliche Eingaben (Tasten _gedrückt halten_). Rechnet WASD- und Tasten-Zoom (Numpad +/-) in flüssige Richtungs-Vektoren (`Vector2`) um. Blockiert rigoros, wenn ein Menü offen ist.
- **`_unhandled_input(event)`:** Behandelt diskrete Eingaben (Tasten _einmalig drücken_, Mausklicks, Mausrad).
    - Beinhaltet die **"Türsteher"**-Logik ganz oben: Modals lassen nur `ESC` durch.
    - Löst alle Hotkeys (definiert in Godots `InputMap`) auf.
    - Behandelt das Maus-Dragging für die Karte.

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Das `set_input_as_handled()`-Prinzip:** Wann immer der `InputHandler` einen Hotkey (wie `ESC` oder `B` für Bauen) erkennt, ruft er `get_viewport().set_input_as_handled()` auf. Dadurch "schluckt" er die Taste – das verhindert, dass Hintergrund-Elemente (z.B. ein Texteingabefeld oder das Bausystem) versehentlich auf dieselbe Taste reagieren.
2. **Die strenge Pin-Kill-Regel:** Das Kamera-Reset-System (Pos1-Taste) verzeiht nichts. Fast jede aktive Bewegung (WASD, Linksklick auf die Karte, Tastatur-Zoom) feuert sofort `sig_kill_reset_pin_requested.emit()`. **Ausnahme:** Das Mausrad zum Zoomen darf den Pin ausdrücklich _nicht_ killen!
3. **Modus-Umschaltung erfolgt von außen:** Der `InputHandler` ändert seinen `current_mode` niemals selbst. Die UI-Manager (z.B. `IngameUIManager` oder `HUD`) müssen ihm sagen: _"Hey, ich hab gerade das Rezeptions-Fenster geöffnet, stell dich auf MODAL!"_
