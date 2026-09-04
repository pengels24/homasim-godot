# Conference Small (Tagungsraum)
**ID:** `conference_small`
**Kategorie:** Business

## Funktionsweise (Smart Room 2.0)
Der Tagungsraum (Conference Small) bietet Platz für bis zu 12 Personen (11 Zuhörer, 1 Redner). Seit dem Update auf das Smart Room System und die Einführung des EventManagers (Tier 2/3) arbeitet der Raum im **Dual-Modus**:

1. **Event-Modus (Modus A):**
   - Wenn der `EventManager` morgens ein Event auf diesen Raum bucht (z.B. Botaniker-Tagung), erhält das Hotel sofort die Einmalzahlung pro Teilnehmer.
   - Der Raum ist in dieser Zeit **exklusiv** für die gebuchten Tagungsgäste reserviert. Reguläre Hotelgäste (VIPs, Business-Gäste ohne Event) dürfen den Raum nicht betreten.
   - Tagungsgäste haben einen strikten Tagesablauf: 07:45 bis 12:00 Uhr Konferenz, 12:00 bis 13:50 Uhr Mittagspause im Restaurant/Bar, 13:50 bis 17:00 Uhr Nachmittagssession.

2. **Regulärer Modus (Modus B):**
   - Findet kein Event statt, verhält sich der Raum wie ein regulärer POI. 
   - Business-, Luxus- und VIP-Gäste können den Raum gegen Eintrittsgeld (`visit_income`) nutzen.
   - Event-Gäste aus anderen Räumen werden geblockt.

## Interaktion & Bestuhlung
Der Raum wickelt die Sitzplätze dynamisch über `get_available_interactions` und `claim_interaction` ab:
- **Rednerpult (`ChairSpeaker`):** Der Raum erzwingt für den Gast an diesem Platz per `look_at_pos` die Blickrichtung zum `Speakertable`.
- **Zuhörer (`Chair1` bis `Chair11`):** Reguläre Sitzplätze.
- **Seat Swap (Rotation):** Der Raum misst über das Signal `TimeManager.sig_minute_passed` die Zeit des aktuellen Redners. Nach exakt 15 Ingame-Minuten wird die `_swap_speaker()` Logik ausgelöst. Der aktuelle Redner gibt seinen Platz ab und tauscht ihn logisch mit einem zufällig gewählten Zuhörer im Raum. Beide Gäste fordern im nächsten Frame eine neue Interaktion an und laufen zu ihren neuen Plätzen, ohne den Raum zu verlassen.

### Wichtig: Eigener Sitz in `get_available_interactions`
Die Bedingung für freie Sitzplätze lautet `occupied_by == "" or occupied_by == actor_id`.
**Warum:** Wenn der Timer eines sitzenden Gastes abläuft, ruft `_process_waiting` `get_available_interactions(self)` auf. Da der Gast seinen eigenen Sitz belegt, würde bei `occupied_by == ""` das Ergebnis 0 sein → Fallthrough zu `_decide_next_action()` → globaler Walk → erneutes `_on_poi_arrived()` → **EXP-Spam**. Durch das Einschließen des eigenen Sitzes bekommt der Gast seine aktuelle Position zurück, bewegt sich minimal (`_execute_poi_move`) und bleibt im Raum – ohne State-Change und ohne EXP.

### Fallthrough-Guard in `GuestActor._process_waiting`
Falls trotzdem `interactions.size() == 0` (z.B. designierter Speaker darf nicht auf Zuhörersitz), wird **vor** `_decide_next_action()` der Sitz via `release_interaction` freigegeben und `_has_claimed_seat = false` gesetzt. Verhindert, dass `_on_poi_arrived` via den `_has_claimed_seat`-Bypass EXP vergibt, obwohl der Gast nicht wirklich neu ankommt.


## Stats & Limitierungen
- **Kapazität:** max 12 Gäste (`max_guests = 12`)
- **Raumgröße:** 3x2 (bzw. 2x3 im Portrait-Modus)
- **Live-Monitor:** Zeigt den aktuellen Redner orange mit dem Status "Hält einen Vortrag" (`poi.conference.speaking`) an, während Zuhörer lila markiert bleiben (`poi.conference.attending`).
