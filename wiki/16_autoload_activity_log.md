# 🌐 Autoload: ActivityLog.gd

### 🎯 Zweck (TL;DR)

Das "schwarze Brett" oder der Nachrichtenticker des Hotels. Der `ActivityLog` sammelt alle wichtigen Ereignisse (z. B. Check-ins, Beschwerden, Erfolge) chronologisch, speichert den Zeitpunkt (In-Game Tag und Zeit) und ermöglicht es, diese Nachrichten zu verwalten (lesen/ungelesen-Status).

### 🛡️ Zuständigkeiten

- **Chronik:** Hält eine Liste aller Spiel-Ereignisse im RAM.
- **Event-Broadcasting:** Informiert andere Systeme (wie ein späteres UI-Fenster) sofort über neue Einträge.
- **Status-Management:** Verwaltet den "Ungelesen"-Status (`is_read`), um dem Spieler beispielsweise eine Benachrichtigungs-Badge im UI zu zeigen.
- _(Nicht zuständig für: Die visuelle Anzeige. Das Log ist ein reiner Daten-Container; die UI-Darstellung als Liste oder Ticker ist ein separate Thema)._

### 💾 Zentrale Variablen (State)

- `_entries` _(Array)_: Die Hauptliste, die alle Log-Einträge als Dictionaries speichert.
    - Aufbau eines Eintrags: `{"type", "message", "game_day", "game_time", "is_read", "created_at"}`.

### 📡 Wichtige Signale

- `entry_added(entry: Dictionary)`: Wird jedes Mal gefeuert, wenn ein neues Event in das Log geschrieben wird. Das UI-Fenster muss sich nur mit diesem Signal verbinden, um automatisch zu aktualisieren, wenn ein neuer Eintrag reinkommt.

### ⚙️ Kern-Funktionen

- **`add(type, message, game_day, game_time)`:** Die einzige Funktion, um Events hinzuzufügen. Sie reichert die Nachricht automatisch mit einem Zeitstempel (`created_at`) an und markiert sie als "ungelesen".
- **`get_unread_count()`:** Hilfsfunktion, um herauszufinden, wie viele Nachrichten der Spieler noch nicht gesehen hat (wichtig für UI-Badges).
- **`mark_all_read()`:** Setzt den Status aller Einträge auf `true`.
- **`clear()`:** Leert den gesamten Log-Speicher (z. B. bei Spielstart oder Profilwechsel).

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Memory-Footprint:** Da das Log als `Array` im RAM lebt und keine automatische Begrenzung (z. B. "Max 100 Einträge") hat, wächst es bei sehr langen Spielsessions unendlich. Wenn du planst, das Log über sehr lange Zeiträume zu führen, solltest du in der `add()`-Funktion eine Prüfung einbauen (z. B. `if _entries.size() > 500: _entries.pop_front()`), um Speicher zu sparen.
2. **Daten-Kopplung:** Die Einträge enthalten sowohl `game_day`/`game_time` (Ingame-Kontext) als auch `created_at` (echte Systemzeit). Das ist ein kluger Schachzug für Debugging-Zwecke, da du so genau siehst, wann eine Aktion im Spiel passiert ist und wann sie der Spieler tatsächlich auf seinem PC ausgeführt hat.
3. **Persistenz-Hinweis:** Aktuell ist das Activity-Log **nicht** persistent. Wenn der Spieler das Spiel schließt, sind die Einträge verloren. Soll das Log bei einem Savegame mit gespeichert werden, muss der `SaveManager` in seinem Snapshot-System erweitert werden, um das `_entries`-Array mitzusichern.
