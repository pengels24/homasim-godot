# TechDoku: GuestActor (GÃ¤ste-Verhalten)
*Stand: v0.1.42*

Der `GuestActor` steuert die visuelle und logische ReprÃ¤sentation eines einzelnen Hotelgastes auf der Karte. Jeder `GuestActor` ist an ein `GuestMember`-Datenobjekt gekoppelt, welches die eigentlichen Werte (SÃ¤ttigung, Geduld, Geldbeutel, Budget) hÃ¤lt.

## 1. Lebenszyklus & Setup
- **Spawn**: Wird vom `GuestManager` instantiiert, sobald eine neue `GuestParty` (GÃ¤stegruppe) anreist oder aus einem Savegame geladen wird.
- **Setup**: `setup(member, map_grid, start_room, guest_manager)` verknÃ¼pft den Actor mit dem Datenmodell und setzt den initialen Zustand.
- **Despawn**: Wenn der Checkout abgeschlossen ist und der Gast das GrundstÃ¼ck verlÃ¤sst (`LEAVING`), wird der Actor aus dem Tree entfernt.

## 2. State-Machine (ZustÃ¤nde)
Der Ablauf eines Gastes wird Ã¼ber die Enum `State` gesteuert:
- `IDLE`: Der Gast Ã¼berlegt, was er als NÃ¤chstes tut. Sucht nach offenen POIs, geht aufs Zimmer (SÃ¤ttigung/MÃ¼digkeit abbauen) oder wartet.
- `WALKING`: Bewegt sich entlang eines AStar-Pfads zu einem Ziel (`_target_room`).
- `IN_ROOM`: Befindet sich im eigenen gebuchten Zimmer (meist zum Schlafen oder Erholen).
- `IN_POI`: Befindet sich in einem besuchbaren Raum (Lobby, Restaurant, Bar, etc.).
- `AWAITING_CHECKOUT`: Steht in der Lobby und wartet darauf, dass die Rezeption Ã¶ffnet, um das Hotel zu verlassen.
- `LEAVING`: Hat ausgecheckt und lÃ¤uft zum Ausgang der Karte.
- `STUDYING_MENU` / `WAITING_FOR_FOOD` / `EATING`: Spezielle Gastro-States (siehe unten).

## 3. Die Idle-Entscheidungslogik
In `_process_idle()` fÃ¤llt der Gast Entscheidungen basierend auf seinen Werten und der Tageszeit:
1. **Checkout**: Ist der Abreisetag erreicht, will der Gast auschecken.
2. **Hunger / Gastro**: Wenn SÃ¤ttigung < 100%, wird primÃ¤r nach Gastro-POIs (Restaurant) gesucht.
3. **Schlafen**: Nachts (ca. 22:00 - 06:00 Uhr) tendieren GÃ¤ste stark dazu, auf ihr Zimmer zu gehen.
4. **Freizeit**: Befindet sich der Gast nicht im Zimmer und hat kein zwingendes BedÃ¼rfnis, wÃ¤hlt er zufÃ¤llig einen geÃ¶ffneten POI.
*(GÃ¤ste verbringen intern ca. 15 Ingame-Minuten in einem POI, bevor sie weiterziehen oder pausieren).*

## 4. Gastronomie-Integration & POI-Verhalten
Ist ein Gast im Restaurant oder an der Bar, durchlÃ¤uft er eine Mini-State-Machine:
- **Studying Menu**: Setzt sich hin und braucht einige Sekunden, um das MenÃ¼ zu lesen. Generiert dann eine `FoodOrder` im `GastroManager`.
- **Waiting for Food**: Wartet auf die Lieferung. Dauert es zu lange (oder gibt es kein Personal), sinkt die Zufriedenheit stetig (`_process_impatient`).
- **Eating**: Wenn das Essen geliefert wurde, wird der SÃ¤ttigungsbalken aufgefÃ¼llt und das Geld abgezogen.

*Ausnahme:* Handelt es sich um Wellness-Einrichtungen (wie `pool_small`, `gym_small`, `spa_small`), Ã¼berspringt der Gast das Bestellen und Verzehren und verbleibt einfach fÃ¼r die POI-Dauer im Status `IN_POI`.

## 5. Zufriedenheit (Satisfaction) & BedÃ¼rfnisse
Die `satisfaction` ist ein zentraler Wert der **gesamten GÃ¤stegruppe** (`GuestParty`).
- **Sinkt durch**: Lange Wartezeiten, Hunger (0%), dreckige/kaputte Zimmer, nicht erfÃ¼llte Requirements (z.B. fehlendes WLAN).
- **Steigt durch**: Erfolgreiche Besuche von POIs.
  - Basis-Gewinn fÃ¼r bezahlten POI-Besuch: **+2%**
  - Raum bietet WLAN: **+1%**
  - Raum bietet Klima: **+1%**
  *(Balancing-Bremse: maximal +4% pro Besuch, um Perm-100%-Zufriedenheit zu vermeiden).*

## 6. Bewegung & Pathfinding
GÃ¤ste nutzen das `MapGrid`-Skript, um Wege zu finden (`get_path_astar`).
Die Geschwindigkeit (`_base_speed`) ist abhÃ¤ngig vom GÃ¤stetyp (z.B. GeschÃ¤ftsreisende laufen schneller als Familien). Die Animations-Geschwindigkeit skaliert synchron zur Laufgeschwindigkeit und zur aktuellen Ingame-Vorspul-Geschwindigkeit (`TimeManager.user_speed`).

## Smart Room System (Phase 1 Integriert)
Das Gast-Interaktionssystem wurde in Phase 1 auf das neue 'Smart Room' System umgebaut. Anstatt dass der GuestActor hartkodierte Methoden (wie `room_claim_bed` oder `claim_seat`) des Raums aufruft, werden Interaktionen nun generischer abgewickelt (`get_available_interactions`, `claim_interaction`, `release_interaction`).
Bisher sind die Standard-Räume (`bed_standard`, `bed_double`) sowie die Basis-State-Machine (`_wander_in_room`, `_change_state` mit `release_interaction`) migriert. Der `GuestActor` trackt seine aktive Interaktion über `_last_interaction_id` und gibt diese beim Verlassen des Raums oder Statuswechsels automatisch wieder frei.
Solange der Umbau für andere Räume (Phase 2: Bar/StaffRoom, Phase 3: Conference/POIs) noch läuft, nutzt der GuestActor einen sauberen Fallback auf die Legacy-Methoden.

## 7. Vending Machine (Lobby Snack-Automat)
Der Snackautomat in der Lobby ist ein Sonderfall. Er fungiert als Pseudo-POI.
Wenn der Gast hungrig ist und sich für den Automaten entscheidet (`poi_id == "vending_machine"`), hat das Navigationsziel (`VendingTargetPoint`) absolute Priorität vor der generischen Sitzplatz-Suche (`has_free_room_seat`), damit der Gast nicht fälschlicherweise zum Bezahlen auf einem Sessel Platz nimmt. Nach dem Kaufvorgang sucht der Gast sich dann dynamisch einen `SnackPoint` oder freien Sitzplatz zum Verzehr.
