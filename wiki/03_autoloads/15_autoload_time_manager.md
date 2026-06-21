# 🌐 Autoload: TimeManager.gd

### 🎯 Zweck (TL;DR)

Der Herzschlag des Spiels. Der `TimeManager` steuert den zeitlichen Ablauf der Hotelsimulation (Ticks, Minuten- und Stundenfortschritt), verwaltet die Spielgeschwindigkeit (Pause, Normalzeit, Vorspulen) und orchestriert den harten Cutoff beim Tageswechsel.

### 🛡️ Zuständigkeiten

- **Zeit-Simulation:** Akkumuliert die reale Delta-Zeit und wandelt sie basierend auf der Skalierung in Ingame-Minuten und -Stunden um.
- **Geschwindigkeitskontrolle:** Verwaltet die Zustände Pause (`pause`), Wiedergabe (`resume`) und schnellen Vorlauf (`fast_forward`).
- **Tageswechsel-Orchestrierung:** Erhöht den Ingame-Tag, setzt die Uhrzeit auf den Standard-Startwert zurück und erzwingt eine Pause.
- **Event-Schnittstelle:** Informiert andere Systeme per Signal über das Verstreichen einer Stunde, das Ende eines Tages oder die Änderung der Geschwindigkeit.
- _(Nicht zuständig für: Die visuelle Darstellung von Uhrzeit/Datum im HUD oder die konkrete Planung von Tagesereignissen – das macht der `IngameScheduleManager`)._

### 💾 Zentrale Variablen (State)

- `SECONDS_PER_GAME_MINUTE` _(const float = 2.0)_: Das Zeitskalierungs-Verhältnis. 2 Sekunden Echtzeit entsprechen 1 Minute Ingame-Zeit.
- `_hotel_ref` _(Dictionary)_: Eine Referenz auf das aktive Hotel-Datenpaket aus dem `GameState`, um den Tag direkt im Datensatz zu manipulieren.
- `_game_hour` / `_game_minute` _(int)_: Die aktuelle Uhrzeit im laufenden Spiel.
- `_game_paused` _(bool)_ / `_game_speed` _(float)_: Der aktuelle Zustand des Zeitflusses.
- `_time_accum` _(float)_: Der interne Puffer, der die Delta-Zeitwerte (`delta`) der `_process`-Schleife sammelt, bis eine Ingame-Minute voll ist.

### 📡 Wichtige Signale

- **Gameplay- & Logik-Signale:**
    - `sig_hour_passed(hour)`: Feuert jede volle Ingame-Stunde (wird u.a. vom `GuestManager` genutzt).
    - `sig_day_ended(new_day)`: Signalisiert das Ende des aktuellen Tages.
    - `sig_save_requested(game_time)`: Fordert den `IngameSaveController` am Tagesende auf, einen Autosave anzulegen.
- **UI- & Feedback-Signale:**
    - `sig_time_updated(formatted_time)`: Sendet die Uhrzeit als fertigen String (z.B. `"08:15"`).
    - `sig_day_updated(day_str)`: Sendet die aktuelle Tagesnummer als String.
    - `sig_speed_changed(is_paused, current_speed)`: Informiert das HUD, welche Zeit-Buttons (Pause/Play/FF) visuell aktiv sein müssen.

### ⚙️ Kern-Funktionen

- **`setup(hotel)`:** Initialisiert den Manager beim Betreten des Ingame-Modus. Extrahiert die gespeicherten Minuten aus den Hotel-Daten, rechnet sie in Stunden/Minuten um und synchronisiert sofort das HUD.
- **`_tick_game_clock(delta)`:** Der Motor des Spiels in der `_process`-Schleife. Multipliziert das reale `delta` mit dem Geschwindigkeitsfaktor (`_game_speed`). Rechnet Überläufe von Minuten in Stunden um.
- **`_on_day_end()`:** Wird aufgerufen, sobald die Uhr 24:00 Uhr erreicht. Erhöht den Tag im Dictionary, setzt die Uhr hart zurück, erzwingt den Pausenmodus und triggert die Speicherung des Spielstands.

### ⚠️ Architektur-Hinweise (Gotchas)

1. **Der Mitternacht-Reset (06:00 Uhr-Cutoff):** Wenn die Uhr `24` erreicht, springt sie nicht auf `00:00`, sondern wird direkt auf **`06:00`** Uhr morgens des Folgetages gesetzt. Gleichzeitig wird das Spiel automatisch pausiert (`_game_paused = true`). Dies ist ein bewusstes Design-Pattern, um dem Spieler am Tagesende eine Abrechnung zu präsentieren, bevor der nächste Tag stressfrei per Knopfdruck gestartet wird.
2. **Sauberes UI-Decoupling:** Der Manager manipuliert keine Buttons oder TextLabels im HUD. Er bereitet die Daten intern vor und schickt sie via `sig_time_updated` oder `sig_speed_changed` raus. `ingame.gd` verbindet diese Signale direkt mit den UI-Elementen.
3. **Schutz vor Idle-Ticks:** Wenn kein Hotel geladen ist (`_hotel_ref == null`), bricht die `_process`-Schleife sofort ab. Es wird keine CPU-Zeit für Berechnungen im Hauptmenü verschwendet.
