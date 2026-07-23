# TechDoku: GuestActor (Gäste-Verhalten)
*Stand: v0.1.42*

Der `GuestActor` steuert die visuelle und logische Repräsentation eines einzelnen Hotelgastes auf der Karte. Jeder `GuestActor` ist an ein `GuestMember`-Datenobjekt gekoppelt, welches die eigentlichen Werte (Sättigung, Geduld, Geldbeutel, Budget) hält.

## 1. Lebenszyklus & Setup
- **Spawn**: Wird vom `GuestManager` instantiiert, sobald eine neue `GuestParty` (Gästegruppe) anreist oder aus einem Savegame geladen wird.
- **Setup**: `setup(member, map_grid, start_room, guest_manager)` verknüpft den Actor mit dem Datenmodell und setzt den initialen Zustand.
- **Despawn**: Wenn der Checkout abgeschlossen ist und der Gast das Grundstück verlässt (`LEAVING`), wird der Actor aus dem Tree entfernt.

## 2. State-Machine (Zustände)
Der Ablauf eines Gastes wird über die Enum `State` gesteuert:
- `IDLE`: Der Gast überlegt, was er als Nächstes tut. Sucht nach offenen POIs, geht aufs Zimmer (Sättigung/Müdigkeit abbauen) oder wartet.
- `WALKING`: Bewegt sich entlang eines AStar-Pfads zu einem Ziel (`_target_room`).
- `IN_ROOM`: Befindet sich im eigenen gebuchten Zimmer (meist zum Schlafen oder Erholen).
- `IN_POI`: Befindet sich in einem besuchbaren Raum (Lobby, Restaurant, Bar, etc.).
- `AWAITING_CHECKOUT`: Steht in der Lobby und wartet darauf, dass die Rezeption öffnet, um das Hotel zu verlassen.
- `LEAVING`: Hat ausgecheckt und läuft zum Ausgang der Karte.
- `STUDYING_MENU` / `WAITING_FOR_FOOD` / `EATING`: Spezielle Gastro-States (siehe unten).

## 3. Die Idle-Entscheidungslogik
In `_process_idle()` fällt der Gast Entscheidungen basierend auf seinen Werten und der Tageszeit:
1. **Checkout**: Ist der Abreisetag erreicht, will der Gast auschecken.
2. **Hunger / Gastro**: Wenn Sättigung < 100%, wird primär nach Gastro-POIs (Restaurant) gesucht.
3. **Schlafen**: Nachts (ca. 22:00 - 06:00 Uhr) tendieren Gäste stark dazu, auf ihr Zimmer zu gehen.
4. **Freizeit**: Befindet sich der Gast nicht im Zimmer und hat kein zwingendes Bedürfnis, wählt er zufällig einen geöffneten POI.
*(Gäste verbringen intern ca. 15 Ingame-Minuten in einem POI, bevor sie weiterziehen oder pausieren).*

## 4. Gastronomie-Integration
Ist ein Gast im Restaurant oder an der Bar, durchläuft er eine Mini-State-Machine:
- **Studying Menu**: Setzt sich hin und braucht einige Sekunden, um das Menü zu lesen. Generiert dann eine `FoodOrder` im `GastroManager`.
- **Waiting for Food**: Wartet auf die Lieferung. Dauert es zu lange (oder gibt es kein Personal), sinkt die Zufriedenheit stetig (`_process_impatient`).
- **Eating**: Wenn das Essen geliefert wurde, wird der Sättigungsbalken aufgefüllt und das Geld abgezogen.

## 5. Zufriedenheit (Satisfaction) & Bedürfnisse
Die `satisfaction` ist ein zentraler Wert der **gesamten Gästegruppe** (`GuestParty`).
- **Sinkt durch**: Lange Wartezeiten, Hunger (0%), dreckige/kaputte Zimmer, nicht erfüllte Requirements (z.B. fehlendes WLAN).
- **Steigt durch**: Erfolgreiche Besuche von POIs.
  - Basis-Gewinn für bezahlten POI-Besuch: **+2%**
  - Raum bietet WLAN: **+1%**
  - Raum bietet Klima: **+1%**
  *(Balancing-Bremse: maximal +4% pro Besuch, um Perm-100%-Zufriedenheit zu vermeiden).*

## 6. Bewegung & Pathfinding
Gäste nutzen das `MapGrid`-Skript, um Wege zu finden (`get_path_astar`).
Die Geschwindigkeit (`_base_speed`) ist abhängig vom Gästetyp (z.B. Geschäftsreisende laufen schneller als Familien). Die Animations-Geschwindigkeit skaliert synchron zur Laufgeschwindigkeit und zur aktuellen Ingame-Vorspul-Geschwindigkeit (`TimeManager.user_speed`).
