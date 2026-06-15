# 🌐 Autoload: SessionManager.gd

### 🎯 Zweck (TL;DR)

Der lokale "Schlüsselbund" des Spiels. Er kümmert sich ausschließlich um die Persistenz des Logins (damit der Spieler nicht bei jedem Spielstart sein Passwort neu eingeben muss), indem er Session-Cookies und den Benutzernamen lokal auf der Festplatte speichert und beim Start validiert.

### 🛡️ Zuständigkeiten

- **Lokales Speichern:** Sichert den Session-Cookie und den zuletzt genutzten Usernamen in einer lokalen Konfigurationsdatei (`user://session.cfg`).
- **Session-Validierung:** Fragt beim Spielstart das Backend, ob die alte Session noch gültig ist.
- **Säuberung:** Entfernt alle lokalen Login-Spuren, wenn sich der Spieler ausloggt (`clear`).
- _(Nicht zuständig für: Den eigentlichen Login-Vorgang mit Passwort-Überprüfung (macht `Api.gd`) oder das Halten des aktiven Spielerprofils während des laufenden Spiels (macht `GameState.gd`))._

### 💾 Zentrale Variablen (State)

- `_SAVE_PATH` _(const String)_: Der Pfad zur lokalen Datei. In Godot bedeutet `user://`, dass die Datei im sicheren AppData-Verzeichnis des jeweiligen Betriebssystems landet.
- `saved_username` _(String)_: Der Name des Spielers (praktisch, um das Login-Feld beim nächsten Start schon mal vorab auszufüllen).
- **Externe Manipulation:** Setzt und löscht den Wert `Api.session_cookie` im API-Autoload.

### 📡 Wichtige Signale

- **Keine eigenen Signale!** Da Netzwerk-Anfragen asynchron ablaufen (das Spiel weiß nicht, wie lange der Server für eine Antwort braucht), nutzt dieses Skript moderne **Callbacks** (`Callable`) anstelle von Signalen.

### ⚙️ Kern-Funktionen

- **`_load()`:** Wird vollautomatisch in der `_ready()`-Funktion beim Spielstart aufgerufen. Liest die `.cfg`-Datei aus und füttert das Netzwerk-Skript (`Api`) direkt mit dem gefundenen Cookie.
- **`save_cookie(cookie)` / `save_username(username)`:** Die Schreib-Funktionen. Öffnen die Config-Datei, schreiben den neuen Wert rein und speichern sie wieder ab.
- **`clear()`:** Der "Vergessen"-Mechanismus beim Logout. Überschreibt die lokale Datei mit leeren Werten und löscht den Cookie aus dem Netzwerk-Skript.
- **`check_session(callback: Callable)`:** Der Wächter beim Start (meist aufgerufen im Login- oder Ladescreen). Fragt beim Server (`/api/auth/me`) an: _"Ist dieser Cookie noch gültig?"_
    - Wenn **Ja**, speichert er die Profildaten direkt in den `GameState` und ruft `callback.call(true)` auf.
    - Wenn **Nein** (oder kein Cookie da), ruft er `callback.call(false)` auf.

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Asynchronität beachten:** Da `check_session` auf den Server wartet, darf nach dem Aufruf im aufrufenden Skript (z.B. `Login.gd`) nicht sofort Code ausgeführt werden. Die Logik zum Bildschirmwechsel _muss zwingend_ in der übergebenen Callback-Funktion liegen!
2. **Klartext-Speicherung:** Godots `ConfigFile` speichert Daten im simplen, unverschlüsselten Textformat (`.ini`-Style). Für Session-Cookies und Usernamen ist das absolut sicher und Best Practice. Es bedeutet aber: **Hier dürfen niemals Passwörter gespeichert werden!**
3. **Dreiecks-Beziehung:** Dieses Skript funktioniert nicht isoliert. Es ist stark an `Api.gd` (für die Web-Requests) und `GameState.gd` (als Datenspeicher nach dem erfolgreichen Check) gekoppelt.
