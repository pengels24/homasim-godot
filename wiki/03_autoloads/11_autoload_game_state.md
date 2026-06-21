# 🌐 Autoload: GameState.gd

### 🎯 Zweck (TL;DR)

Das globale Gedächtnis des Spiels. Der `GameState` speichert sitzungsübergreifende Daten (wer ist eingeloggt, welches Profil/Hotel ist geladen) und fungiert als zentraler Verteiler für Ressourcen-Updates (Geld, EXP, Ruf) an das UI.

### 🛡️ Zuständigkeiten

- **Session-Handling:** Speichert den aktiven User, das Manager-Profil und das geladene Hotel.
- **Ressourcen-Verwaltung:** Manipuliert die Hotel-Werte (Geld, Erfahrung, Ruf, Forschungspunkte) zentral und feuert Signale, wenn sich diese ändern.
- **Level-Up-Logik:** Berechnet benötigte EXP und wickelt Level-Ups (inkl. Übertrag von Rest-EXP) ab.
- **Config- & Registry-Loader:** Lädt beim Spielstart die globalen Konfigurationen (`rooms.json`, `room_categories.json`, `daily_schedule.json`) und hält sie im Speicher (`room_registry`, etc.).
- **Globale Formatierer:** Stellt projektweit nützliche Text-Konverter (Zeit, Datum, Währung) zur Verfügung.
- **Lokalisierung:** Stellt die zentrale Übersetzungsfunktion `T()` bereit.
- _(Nicht zuständig für: Reales Speichern auf der Festplatte (macht der `SaveManager`))._

### 💾 Zentrale Variablen (State)

- `current_user` / `current_manager` _(Dictionary)_: Authentifizierungs- und Profildaten des Spielers.
- `active_profile` / `active_profile_id`: Das aktuell bespielte Manager-Profil (Savegame-Slot).
- `selected_hotel` _(Dictionary)_: Alle Live-Daten des laufenden Hotels. **Achtung: Dient aktuell noch teilweise als Legacy-Datenbehälter.**
- `active_hotel_id` _(int)_: Die ID des Hotels für den SaveManager (-1, falls keines gewählt).
- `snap_to_grid` _(bool)_: Globale Einstellung für das Bausystem.
- **Registries:** `room_registry`, `room_category_registry`, `daily_schedule_registry` (Beinhalten alle geparsten Spieldaten).
- `process_mode` _(Enum)_: Wird in `_ready()` hart auf `Node.PROCESS_MODE_ALWAYS` gesetzt, um den GameState vor der Engine-Pause zu schützen.

### 📡 Wichtige Signale

- **Flow-Signale:** `user_logged_in`, `user_logged_out`, `hotel_selected` (Steuern den Bildschirmwechsel im Main Menu).
- **HUD-Updates:** `sig_hotel_money_changed`, `sig_hotel_exp_changed`, `sig_hotel_rep_changed`, etc. (Jedes Mal, wenn der GameState Daten ändert, lauscht das HUD auf diese Signale, um Text-Labels zu aktualisieren).
- **Gameplay-Trigger:** `sig_hotel_level_up(new_level)` (Feuert das Pop-up für den Levelaufstieg im IngameUIManager).

### ⚙️ Kern-Funktionen

- **`select_hotel(hotel_data)`:** Lädt die Hotel-Daten und triggert sofort Signale (`sig_hotel_money_changed`, `sig_hotel_exp_changed`, etc.), um das HUD zu synchronisieren. Löst auch das Laden der anderen Manager (Techtree, Tutorial, Quests) aus.
- **`add_exp(amount)`:** Fügt Erfahrungspunkte hinzu inkl. `while`-Schleife für Mehrfach-Level-Ups.
- **`add_money()`, `add_rep()`, `add_fp()`:** Manipulieren die Ressourcen und alarmieren das UI.
- **`load_room_config()`, `load_daily_schedule_config()`:** Lesen die JSON-Dateien aus `/config/` in die Registries.
- **`format_money()`, `format_game_time()`, `format_timestamp()`:** Globale Helfer.
- **`is_facility_open(def)`:** Prüft anhand der Raum-Definition, ob ein Raum zu der aktuellen Ingame-Zeit geöffnet hat.
- **`calc_checkin_exp()`, `calc_reject_rep_penalty()`:** Balancing-Funktionen für Interaktionen mit Gästen.
- **`T(key, val1, val2)`:** Holt Strings aus dem `TranslationServer` und ersetzt Platzhalter (`###`, `***`).

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Legacy-Übergang:** Die Variable `selected_hotel` ist historisch gewachsen. Datenveränderungen wie `selected_hotel["money"] += amount` ändern die Werte aktuell **nur im RAM**. Der GameState speichert _nicht_ automatisch auf die Festplatte! Das muss immer explizit über den `SaveManager` bzw. `IngameSaveController` getriggert werden.
2. **Keine direkten HUD-Zugriffe:** Der GameState kennt das Ingame-HUD nicht. Er ruft niemals Labels direkt auf. Wenn Geld hinzugefügt wird (`add_money`), brüllt der GameState das nur über das Signal `sig_hotel_money_changed` in den leeren Raum – wer auch immer sich dafür interessiert (z. B. das `HUDBottom`), muss selbst zuhören. Das ist absolut vorbildliches Decoupling!
