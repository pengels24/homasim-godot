# Event Manager & Tagungsgäste (Smart Room 2.0)

## Übersicht
Der `EventManager` verwaltet globale Events (Tier 2/3), beginnend mit der "Tageskonferenz" (`P1.2`). 
Mit dem Update auf Smart Room 2.0 wurde das veraltete Legacy-System durch eine saubere, dynamische Architektur ersetzt.

## Ablauf einer Tagung (Event-Modus)

1. **Event-Modus (Modus A):**
   - Wenn der `EventManager` morgens ein Event auf diesen Raum bucht (z.B. Botaniker-Tagung), ist der Raum für diesen Tag exklusiv reserviert.
   - Die Zahlung pro Teilnehmer erfolgt erst um **07:45 Uhr** direkt über den `ConferenceSmall` Raum (Vorpuffer-Öffnung), nicht im `EventManager`.
   - Reguläre Hotelgäste (VIPs, Business-Gäste ohne Event) dürfen den Raum nicht betreten.
   - Der `EventManager` speichert die aktiven Events pro Raum-Instanz-ID in `active_conferences`.

2. **Gestaffelter Spawn (07:00 - 07:15)**
   - In `GuestManager` tickt `_on_minute_passed`. Zu bestimmten Uhrzeiten (07:00, 07:05, 07:10) spawnt er Wellen von `business`-Gästen, die speziell das Property `event_poi_id` (mit der Raum-ID als String) tragen.
   - Da sie kein reguläres Zimmer benötigen, spawnen sie direkt mit `State.IDLE` und überspringen die Rezeption (Auto-Checkin).

3. **Tagesablauf der Tagungsgäste (`GuestActor.gd`)**
   - **07:00 - 07:45:** Aufenthalt in Lobby, Restaurant oder Bar (Kaffee/Frühstück).
   - **07:45 - 12:00:** Gang zum zugewiesenen Konferenzraum. Der Konferenzraum prüft via `get_available_interactions`, ob der Gast sein "Ticket" (die `event_poi_id`) hat.
   - **12:00 - 13:50:** Mittagspause! Die Gäste verlassen den Konferenzraum (Timer wirft sie aus dem POI) und gehen essen.
   - **13:50 - 17:00:** Zweiter Teil der Konferenz.
   - **17:00:** Konferenzende. `ConferenceSmall._end_conference_day()` leert `party.event_poi_id` für alle TG-Gäste. Ab diesem Zeitpunkt erkennt `GuestController.spawn_active_guests()` diese Parties via Two-Pass-Pattern (`room_id == ""` AND `event_poi_id == ""`) und ruft `GuestManager.checkout_event_party(party)` auf → `sig_party_checked_out_physically` → Actors spawnen an ReceptionX-Waypoints der Lobby → `complete_checkout()` → `_walk_to_exit()`. Gäste laufen sichtbar durch die Lobby nach draußen. *(Detaillierte Architektur → `wiki/rooms/conference_small.md #TG-Checkout`)*

4. **Die Konferenzraum-Logik (`ConferenceSmall.gd`)**
   - Der Raum arbeitet im **Dual-Modus**:
     - **Modus A (Event):** Läuft im Raum ein Event (`EventManager.active_conferences.has(id)`), dürfen **NUR** die entsprechenden Event-Gäste interagieren.
     - **Modus B (Kein Event):** Ist der Raum leer, verhält er sich wie ein regulärer POI (für VIP, Business, Luxus) gegen Eintrittspreis. Event-Gäste von anderen Räumen werden geblockt.
   - **Speaker Rotation:** Wer die `ChairSpeaker`-Node einnimmt (Blickrichtung auf `Speakertable`), ist der Speaker. Nach exakt 15 Ingame-Minuten (`_speaker_time`) tauscht der Raum den Speaker durch einen zufälligen Zuhörer im Raum aus ("Seat Swap" ohne den Raum zu verlassen).
   - Im Live-Monitor (Click-Area) wird der Speaker mit dem Text `poi.conference.speaking` orange hervorgehoben, Zuhörer bleiben lila.

## Visuelle Identifikation
Event-Gäste tragen über dem Kopf ein dynamisches Icon (`EventOverlay`), dessen Farbe aus der `events.json` bezogen wird (z.B. grün für Botaniker). Dies ermöglicht es dem Spieler sofort zu erkennen, welche Gäste zu welcher Tagung gehören.

## Event-HUD (Top-Left Indikator)

Während ein Event aktiv ist (`EventManager.is_any_event_active()`), wird oben links im HUD ein Indikator eingeblendet:

- **Tagungsname:** Aus `active_conferences.values()[i].get("name")` (z.B. "Marketingkonferenz")
- **Restzeit-Countdown:** Wird direkt im Label angezeigt: `"Marketingkonferenz (1h30m)"` bzw. `"(45min)"`.
  - Morgensession (< 12:00): Countdown bis 12:00 (720 min)
  - Nachmittagssession (≥ 13:50): Countdown bis 17:00 (1020 min)
- **Kamera-Jump:** Klick auf den Event-Indikator springt die Kamera smooth (Tween 0.4s, Zoom 4) zum aktiven Tagungsraum. Raum-Matching via `GuestManager._room_key(room)` gegen `EventManager.active_conferences.keys()`.
  - Implementiert in `HUD.gd → _jump_to_conference_room()`
  - **Voraussetzung:** `%EventIndicator` Node in `HUD.tscn` muss ein Control-Node sein (`mouse_filter != IGNORE`).
