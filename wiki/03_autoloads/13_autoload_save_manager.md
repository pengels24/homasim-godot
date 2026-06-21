# 🌐 Autoload: SaveManager.gd

### 🎯 Zweck (TL;DR)

Die absolute Festplatten-Instanz. Der `SaveManager` ist das Rückgrat der Persistenz in deinem Spiel. Er kümmert sich um das Erstellen, Lesen, Aktualisieren und Löschen (CRUD) von Profilen, Hotel-Grunddaten und echten Spielständen (Quicksaves, Autosaves, manuelle Saves) im lokalen Dateisystem.

### 🛡️ Zuständigkeiten

- **Profil- & Hotel-Verwaltung:** Legt neue Manager-Profile an und verknüpft sie mit Hotel-Instanzen. Speichert und lädt sogar Vorschaubilder (Thumbnails) der Hotels.
- **Slot-Management:** Verwaltet das Speichern in verschiedene Slots (Quick, Manual, Auto) inkl. einer automatischen Datei-Rotation für Autosaves.
- **Snapshot-Generierung:** Bündelt den aktuellen Hotelzustand (inkl. dynamischer Zähler, Raster/Plots und Gästedaten) in ein speicherbares Paket und entpackt es beim Laden wieder.
- **Migration:** Erkennt alte Speicherstände (z.B. veraltete EXP-Max-Werte) und aktualisiert sie beim Laden automatisch auf die neuen Balancing-Kurven.
- _(Nicht zuständig für: Die Entscheidung, WANN gespeichert wird. Er führt Befehle nur aus. Die Trigger kommen vom `IngameSaveController` oder von UI-Buttons)._

### 💾 Zentrale Variablen (State)

- **Pfade & Konstanten:** `PROFILES_PATH` (`.cfg`), `HOTELS_DIR`, `SAVES_DIR`. Alle arbeiten im sicheren Godot-Appdata-Verzeichnis (`user://`).
- **Limits:** `MAX_AUTOSAVES (5)`, `MAX_HOTELS (10)`, `MANUAL_SLOTS (5)`.
- `_profiles` / `_hotels` _(Array)_: Hält beim Spielstart alle Metadaten im RAM bereit, damit das Hauptmenü sie schnell anzeigen kann, ohne ständig die Festplatte lesen zu müssen.
- `_next_profile_id` / `_next_hotel_id` _(int)_: Globale Auto-Inkrement-Zähler zur Vergabe eindeutiger IDs.
- `_temp_thumbnail` _(Image)_: Zwischenspeicher für den Screenshot beim Speichern, der in `.png` umgewandelt wird.
- `process_mode` _(Enum)_: Wird in `_ready()` auf `Node.PROCESS_MODE_ALWAYS` gesetzt, damit auch beim Pausieren des Spiels gespeichert werden kann.

### 📡 Wichtige Signale

- **Keine!** Der SaveManager ist ein reiner "Service Provider". Andere Skripte rufen seine Funktionen auf und erwarten direkte Rückgabewerte (z.B. ein `bool`, ob das Laden erfolgreich war). Er agiert lautlos im Hintergrund.

### ⚙️ Kern-Funktionen

- **`create_profile()` / `create_hotel()`:** Erstellen neue Grunddatensätze, füllen sie mit Standardwerten (z.B. 50.000 Startgeld) und legen direkt die entsprechenden `.cfg`-Dateien an.
- **`save_auto(hotel_id)`:** Erstellt einen neuen Autosave. **Das Besondere:** Hier ist eine "Shift"-Logik verbaut. Wenn Limit (z.B. 5) erreicht ist, wird `auto_4` gelöscht, `auto_3` wird zu `auto_4` umbenannt, und der neue Save landet auf `auto_0`.
- **`save_room_to_plot()` / `set_plot_built()`:** Spezifische Helfer, die tief in das Array der "Plots" (Parzellen) eingreifen, um dort platzierte Räume dauerhaft zu verankern.
- **`_take_snapshot()` / `_apply_snapshot()`:** Das Herzstück der Serialisierung. Nimmt das Dictionary des laufenden Hotels und kopiert es 1:1, um daraus binäre Spielstände zu erzeugen. Erkennt automatisch dynamisch erzeugte Keys (wie `next_z_id`).

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Zwei Dateiformate:** Der Manager ist hybrid! Metadaten (Profile, Grunddaten der Hotels) werden als lesbare `ConfigFile` (`.cfg`) gespeichert. Die echten Spielstand-Snapshots werden jedoch binär über `file.store_var()` (`.sav`) gesichert. Das macht die Saves kompakter und schwerer durch Cheater zu manipulieren.
2. **`.duplicate(true)` ist Lebenswichtig:** In `_take_snapshot` und `_apply_snapshot` wird bei Arrays/Dictionaries (wie `plots` oder `guest_data`) strikt `.duplicate(true)` verwendet. Würde man das weglassen, würde Godot nur Referenzen (Pointer) übergeben – der Snapshot würde sich im Hintergrund verändern, während das Spiel weiterläuft!
3. **Regex-/String-Erkennung für Zähler:** Um nicht bei jedem neuen Zimmertyp das Save-Skript umschreiben zu müssen, nutzt der Manager eine intelligente Prüfung (`key.begins_with("next_") and key.ends_with("_id")`). Dadurch werden alle künftigen Raum-Zähler automatisch mit in das Savegame gesaugt!
