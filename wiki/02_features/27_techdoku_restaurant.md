# TechDoku: Restaurant (Kleine Variante)
*Stand: v0.1.42*

Das `RestaurantSmall` fungiert als der zentrale Gastro-POI für Gäste, in dem Speisen (via GastroManager) bestellt und von Bedienungen (Waitern) an den Tisch gebracht werden.

## 1. Rollen & Personal
- **Erforderliche Rolle:** `waiter` (Bedienung).
- Ohne eine aktive Bedienung nimmt das Restaurant keine Essensbestellungen an.
- Das Restaurant benötigt zwingend eine funktionsfähige Küche (`kitchen_small`), die mit einem Koch besetzt ist, um Speisen anbieten zu können.

## 2. Sitzplatz-Management (`_seats`)
Das Skript scannt beim Start alle Kinder unter `Interior/Furniture/Chairs`. Jeder Stuhl ist ein Sitzplatz.
- **Zustände eines Platzes:** `clean` (Frei & Sauber), `dirty` (Schmutzig), `occupied` (Belegt).
- Ein Gast beansprucht über `claim_interaction()` (Smart-Room API) einen sauberen Platz.
- Steht der Gast auf (`release_interaction()`), wird der Platz `dirty` und das Restaurant generiert über den `TaskManager` einen `clean_table` Task für die Bedienung.

## 3. Bestellablauf (Order Logic)
1. **Bestellung aufgeben:** Wenn der Gast sitzt, ruft er `place_order_for_seat()` auf.
   - **Prüfung 1:** Ist eine Bedienung (`waiter`) anwesend und nicht in Schulung?
   - **Prüfung 2:** Ist die Küche geöffnet UND besetzt (`StaffManager.is_poi_staffed`)?
   - **Ergebnis:** Wenn beides zutrifft, wird eine `FoodOrder` im `GastroManager` für die Küche platziert.
2. **Servieren:** Das Restaurant prüft jede Sekunde (via `_process`), ob fertige Gerichte für seine `_room_id` im `GastroManager` vorliegen.
   - Falls ja, wird ein Task `serve_meal` für die Bedienung erstellt.
   - Die Bedienung läuft zum Tresen (oder Küche), holt das Essen und bringt es zum Stuhl (`serve_order_to_seat()`).

## 4. Einschränkungen
Ist die Küche unbesetzt (Koch fehlt oder ist im Training) oder fehlt die Bedienung, lehnt das Restaurant Bestellungen ab. Der Gast verweilt kurz, trinkt ggf. nur eine Kleinigkeit und verlässt den Ort, ohne dass seine Sättigung maßgeblich steigt.
