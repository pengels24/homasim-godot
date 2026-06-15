# 🌐 Autoload: Toast.gd

### 🎯 Zweck (TL;DR)

Der globale "Ausrufer" für kurze System-Benachrichtigungen. Der `Toast`-Manager spawnt kleine Pop-ups (wie z.B. "Spiel gespeichert" oder "Fehler beim Login"). Durch unsere jüngsten Architektur-Updates verfügt er nun über eine intelligente Warteschlange (Queue), um sicherzustellen, dass keine wichtige Benachrichtigung überschrieben wird.

### 🛡️ Zuständigkeiten

- **Szenen-Instanziierung:** Lädt die grafische Szene (`ToastNotification.tscn`) und wirft sie in den obersten Szenenbaum.
- **Warteschlangen-Management (Queue):** Verhindert, dass Benachrichtigungen den Bildschirm überfluten oder sich gegenseitig überschreiben. Wenn ein Toast läuft, werden neue Toasts in eine Liste (`_toast_queue`) eingereiht und automatisch nacheinander abgespielt.
- **Szenenübergreifende Logik:** Bietet einen Mechanismus, um eine Nachricht "vorzumerken", falls gerade das gesamte Level/Menü gewechselt wird (`show_after_scene_change`).
- _(Nicht zuständig für: Das Design, die Farben oder die Ein/Ausblend-Animation. Das regelt das Skript der Instanz `ToastNotification.gd` selbst)._

### 💾 Zentrale Variablen (State)

- `TOAST_SCENE` _(PackedScene)_: Vorgeladene Referenz auf die physische UI-Szene.
- `_active` _(ToastNotification)_: Hält die Referenz auf den _aktuell_ sichtbaren Toast. Ist diese Variable `null`, wird die Queue geprüft.
- `_toast_queue` _(Array)_: Speichert ausstehende Strings. Sobald `_active` verschwindet, rückt der nächste String nach.
- `_pending` _(String)_: Ein temporärer Puffer. Speichert eine Nachricht zwischen, bis eine neue Szene vollständig geladen wurde.

### 📡 Wichtige Signale

- **Keine eigenen Signale!** Der Toast funkt nicht nach draußen. Er _lauscht_ allerdings auf ein sehr wichtiges internes Godot-Signal: `get_tree().node_added` (um zu erkennen, wann ein Szenenwechsel abgeschlossen ist).

### ⚙️ Kern-Funktionen

- **`show(message)`:** Die Standard-Funktion, die von überall im Code (z.B. `Toast.show("Erfolg!")`) gerufen wird.
    1. Prüft, ob gerade ein Toast (`_active`) läuft.
    2. Wenn ja: Packt die `message` ans Ende der `_toast_queue`.
    3. Wenn nein: Spawnt die Szene sofort, hängt sie ans `get_root()` und registriert sie als `_active`.
    4. Verbindet das `tree_exited`-Signal der neuen Node mit `_on_toast_finished`, um den nächsten Toast aus der Queue zu holen.
- **`show_after_scene_change(message)`:** Speichert den String nur in `_pending` ab.
- **`_on_node_added(node)`:** Die Automatik für `show_after_scene_change`. Sobald Godot eine neue Root-Node (also eine neue Szene) in den Baum hängt, prüft das Skript, ob noch eine Nachricht in `_pending` schlummert. Wenn ja, wird sie jetzt erst per `show()` abgefeuert.

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Das Root-Problem bei Szenenwechseln:** Godots Befehl `change_scene_to_file()` löscht radikal alle Nodes, die direkt am Root (`get_tree().get_root()`) hängen – und damit auch laufende Toasts! Wenn du also z.B. nach dem Klick auf "Zurück ins Hauptmenü" einen Toast "Spiel gespeichert" zeigen willst, _musst_ du zwingend `Toast.show_after_scene_change()` nutzen. Ein normales `Toast.show()` würde im Bruchteil einer Sekunde durch den Szenenwechsel direkt wieder gelöscht werden.
2. **Die neue Warteschlange (Update aus v0.1.26gd):** Früher hat ein `Toast.show()` den laufenden Toast sofort gekillt ("Anti-Stacking"). In der Bugfix-Session v0.1.26gd haben wir dies korrigiert, da am Tagesende (z.B. 22:00 Uhr) oft zwei Events gleichzeitig feuerten und Toasts verschluckt wurden. Jetzt ist garantiert, dass jeder gesendete Toast auch wirklich vom Spieler gesehen wird!
