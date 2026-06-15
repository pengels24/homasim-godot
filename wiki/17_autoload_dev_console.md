# 🌐 Autoload: DevConsole.gd

### 🎯 Zweck (TL;DR)

Das Kommandozentrum für den "Gott-Modus" während der Entwicklung. Die `DevConsole` ist ein In-Game-Terminal (aufrufbar via F12), das es dem Entwickler ermöglicht, durch einfache Textbefehle tiefgreifende Spielwerte (Geld, Zeit, Tage, Gäste) zu manipulieren, ohne das Spiel neu starten oder sich durch Menüs klicken zu müssen.

### 🛡️ Zuständigkeiten

- **Befehls-Parsing (`Parser`):** Zerlegt Text-Eingaben (z.B. `set-money:50000`) in Befehl und Wert und führt die entsprechende Logik aus.
- **Fenster-Management:** Kümmert sich um die eigene Sichtbarkeit und ermöglicht es, das Konsolen-Fenster per Maus am Header (Drag & Drop) über den Bildschirm zu ziehen.
- **Log-Historie:** Protokolliert eingegebene Befehle sowie Erfolgs- oder Fehlermeldungen in einer scrollbaren Liste mit farblichem Feedback (Grün für OK, Rot für Fehler).
- **Spiel-Unterbrechung:** Pausiert die Simulation automatisch beim Öffnen und stellt sicher, dass Tastatureingaben ins Textfeld nicht versehentlich das Spiel steuern.
- _(Nicht zuständig für: Die eigentliche Ausführung komplexer Befehle wie das Spawnen von Gästen – hier triggert die Konsole nur Signale oder ruft andere Manager auf)._

### 💾 Zentrale Variablen (State)

- `_hotel` _(Dictionary)_ / `_hud` _(Node)_: Referenzen auf die aktuellen Spieldaten und das HUD, die beim Start über `configure()` injiziert werden.
- `_was_paused` _(bool)_: Ein extrem wichtiges Gedächtnis. Merkt sich, ob das Spiel _vor_ dem Öffnen der Konsole bereits pausiert war.
- `_dragging` / `_drag_offset`: Tracking-Variablen, um das Fenster flüssig mit der Maus verschieben zu können.

### 📡 Wichtige Signale

- **Keine eigenen Signale!** Die Konsole sendet ihre Befehle direkt an die zuständigen Autoloads (`TimeManager`, `SaveManager`) oder nutzt globale Signale wie `GameState.sig_dev_spawn_guests.emit(count)`.

### ⚙️ Kern-Funktionen

- **`configure(hotel, hud)`:** Das Setup. Die Konsole braucht zwingend die Referenz zum aktuellen Hotel-Datenpaket und zum HUD, da sie (z.B. bei `set-money`) die Werte direkt ändern und das HUD zum Update zwingen muss.
- **`toggle() / _open() / _close()`:** Steuert das Öffnen und Schließen. Wechselt den Status des `InputHandler` auf `CONSOLE`, damit das Spiel im Hintergrund alle anderen Hotkeys blockiert.
- **`_execute(cmd)`:** Das Herzstück. Nutzt einen `match`-Block, um Befehle abzuarbeiten:
    - `help`: Listet alle Befehle auf.
    - `set-money` / `set-day` / `set-time`: Manipuliert den State und überschreibt sofort die Werte via `SaveManager.update_hotel`.
    - `save`: Erzwingt sofort einen Quicksave.
    - `spawn-guests`: Triggert den globalen Guest-Spawner.
- **`_log(text, color)`:** Generiert dynamisch neue `Label`-Nodes für das Protokoll und scrollt die Ansicht automatisch ganz nach unten (`_scroll_to_bottom`).

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Schutz vor Spielern:** Der Hotkey zum Öffnen (F12) ist durch `if OS.is_debug_build()` gesichert. Das bedeutet: In der finalen, exportierten Version deines Spiels, die du veröffentlichst, kann kein normaler Spieler diese Konsole öffnen und sich Geld ercheaten!
2. **Die intelligente Pause (`_was_paused`):** Wenn der Spieler das Spiel pausiert, dann die Konsole öffnet und wieder schließt, darf die Konsole das Spiel danach _nicht_ versehentlich weiterlaufen lassen. Die Variable `_was_paused` verhindert genau diesen Bug.
3. **Synchronisation bei Manipulation:** Wenn du `set-money:100` eintippst, passieren in `_execute` drei Dinge gleichzeitig: Das RAM-Dictionary `_hotel` wird aktualisiert, der `SaveManager` schreibt es sofort auf die Festplatte, und das `_hud` wird optisch geupdatet. Vergisst man einen dieser drei Schritte, kommt es zu Asynchronität.
