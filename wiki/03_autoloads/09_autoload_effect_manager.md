# 🌐 Autoload: EffectManager.gd

### 🎯 Zweck (TL;DR)

Der visuelle Zeremonienmeister für Feedback. Der `EffectManager` steuert die "Juiciness" deines Spiels: Er kümmert sich darum, dass schwebende Zahlen (Geld, EXP, FP) vom Spielfeld ins UI fliegen, und stellt globale Animations-Helfer (wie den goldenen Puls bei neuen Gästen) zur Verfügung.

### 🛡️ Zuständigkeiten

- **Animations-Routing:** Merkt sich, wo genau im HUD die Icons für Geld, EXP und FP sitzen, damit Partikel wissen, wohin sie fliegen müssen.
- **Floating Text Spawner:** Nimmt rohe Zahlen aus der Spielwelt und formatiert sie in visuelles Feedback (z.B. rotes "-50 €" oder grünes "+15 EXP").
- **UI-Tweens:** Stellt universell nutzbare Funktionen bereit, um UI-Elemente sanft pulsieren zu lassen.
- _(Nicht zuständig für: Das Verwalten von Ressourcen oder die komplexe Flugkurven-Mathematik der Partikel – Letzteres lagert er an die Szene `FloatingValues.gd` aus)._

### 💾 Zentrale Variablen (State)

- `ui_money_node` _(Control)_: Der Ankerpunkt im HUD (meist in der TopBar), an dem die Geld-Partikel andocken.
- `ui_exp_node` _(Control)_: Das Ziel für fliegende Erfahrungspunkte.
- `ui_fp_node` _(Control)_: Das Ziel für fliegende Forschungspunkte.
- **Wichtig:** Da das HUD beim Starten des Spiels oft neu gebaut wird, starten diese Variablen als `null`. Sie müssen vom UI-System (z.B. `HUD.gd` oder `IngameUIManager`) bei Initialisierung explizit zugewiesen werden!
- `process_mode` _(Enum)_: Wird in `_ready()` hart auf `Node.PROCESS_MODE_ALWAYS` gesetzt. Das macht den EffectManager immun gegen die Godot-Pause (z.B. wenn das PauseMenu offen ist).

### 📡 Wichtige Signale

- **Keine!** Dieser Manager führt rein visuelle Kommandos aus und muss dem Spiel nicht mitteilen, dass ein Effekt beendet wurde. Er ist ein reiner Befehlsempfänger.

### ⚙️ Kern-Funktionen

- **`spawn_money_text()`, `spawn_exp_text()`, `spawn_fp_text()`:** Diese Funktionen werden getriggert, wenn in der 2D-Welt etwas passiert (z.B. Gast bezahlt an Parzelle X/Y). Sie formatieren den String (z.B. Vorzeichen setzen) und feuern den Befehl `FloatingValues.spawn()` ab – aber nur, wenn die Ziel-UI-Nodes registriert sind!
- **`start_ui_pulse(target_node, duration)`:** Erzeugt einen `Tween`, der endlos (`set_loops()`) loopt und die Transparenz (`modulate:a`) des übergebenen Nodes zwischen 100% und 40% weich (`TRANS_SINE`) hin und her blendet. Gibt diesen Tween an den Aufrufer zurück.
- **`stop_ui_pulse(target_node, tween)`:** Bricht den laufenden Puls (`tween.kill()`) sofort ab und – extrem wichtig – setzt das Element wieder auf volle Sichtbarkeit zurück, damit es nicht in einem unsichtbaren Status "steckenbleibt".

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Tween-Besitzverhältnisse:** `start_ui_pulse` speichert den Tween _nicht_ intern. Der Aufrufer (z.B. deine `GuestCard.gd`) ist verpflichtet, sich den zurückgegebenen Tween in einer eigenen Variable zu merken und ihn später an `stop_ui_pulse` zurückzugeben. Das verhindert Chaos, wenn 10 Karten gleichzeitig pulsieren.
2. **Defensive Programmierung:** Funktionen wie `start_ui_pulse` prüfen über `is_instance_valid()`, ob der Node überhaupt noch existiert. Das verhindert Abstürze, falls ein UI-Element gelöscht wird, während der Puls-Effekt starten oder enden will.
3. **Starke Kopplung an `FloatingValues`:** Dieses Skript baut auf dem Autoload `FloatingValues` auf und fungiert als eine Art komfortabler Wrapper, der sich um das String-Formatting und die UI-Offsets (`Vector2(48.0, 0.0)`) kümmert.
