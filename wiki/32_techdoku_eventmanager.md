# Event Manager & Tagungsgäste (Smart Room 2.0)

## Übersicht
Der `EventManager` verwaltet globale Events (Tier 2/3), beginnend mit der "Tageskonferenz" (`P1.2`). 
Mit dem Update auf Smart Room 2.0 wurde das veraltete Legacy-System durch eine saubere, dynamische Architektur ersetzt.

## Ablauf einer Tagung (Event-Modus)

1. **Morning Struck (06:00)**
   - `EventManager` würfelt auf Events. Bei Treffer (Konferenz) werden 1 bis N gebaute Konferenzräume per Zufall mit einem Event belegt (aus `config/events.json`).
   - Die Event-Buchung bringt **sofort** Einnahmen: `150` pro Kopf.
   - Der `EventManager` speichert die aktiven Events pro Raum-Instanz-ID in `active_conferences`.

2. **Gestaffelter Spawn (07:00 - 07:15)**
   - In `GuestManager` tickt `_on_minute_passed`. Zu bestimmten Uhrzeiten (07:00, 07:05, 07:10) spawnt er Wellen von `business`-Gästen, die speziell das Property `event_poi_id` (mit der Raum-ID als String) tragen.
   - Da sie kein reguläres Zimmer benötigen, spawnen sie direkt mit `State.IDLE` und überspringen die Rezeption (Auto-Checkin).

3. **Tagesablauf der Tagungsgäste (`GuestActor.gd`)**
   - **07:00 - 07:45:** Aufenthalt in Lobby, Restaurant oder Bar (Kaffee/Frühstück).
   - **07:45 - 12:00:** Gang zum zugewiesenen Konferenzraum. Der Konferenzraum prüft via `get_available_interactions`, ob der Gast sein "Ticket" (die `event_poi_id`) hat.
   - **12:00 - 13:50:** Mittagspause! Die Gäste verlassen den Konferenzraum (Timer wirft sie aus dem POI) und gehen essen.
   - **13:50 - 17:00:** Zweiter Teil der Konferenz.
   - **17:00:** Ende. Die Gäste verlassen das Hotel (`State.LEAVING`).

4. **Die Konferenzraum-Logik (`ConferenceSmall.gd`)**
   - Der Raum arbeitet im **Dual-Modus**:
     - **Modus A (Event):** Läuft im Raum ein Event (`EventManager.active_conferences.has(id)`), dürfen **NUR** die entsprechenden Event-Gäste interagieren.
     - **Modus B (Kein Event):** Ist der Raum leer, verhält er sich wie ein regulärer POI (für VIP, Business, Luxus) gegen Eintrittspreis. Event-Gäste von anderen Räumen werden geblockt.
   - **Speaker Rotation:** Wer die `ChairSpeaker`-Node einnimmt (Blickrichtung auf `Speakertable`), ist der Speaker. Nach exakt 15 Ingame-Minuten (`_speaker_time`) tauscht der Raum den Speaker durch einen zufälligen Zuhörer im Raum aus ("Seat Swap" ohne den Raum zu verlassen).
   - Im Live-Monitor (Click-Area) wird der Speaker mit dem Text `poi.conference.speaking` orange hervorgehoben, Zuhörer bleiben lila.

## Visuelle Identifikation
Event-Gäste tragen über dem Kopf ein dynamisches Icon (`EventOverlay`), dessen Farbe aus der `events.json` bezogen wird (z.B. grün für Botaniker). Dies ermöglicht es dem Spieler sofort zu erkennen, welche Gäste zu welcher Tagung gehören.
