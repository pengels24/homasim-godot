# TechDoku: Küche (Kleine Variante)
*Stand: v0.1.42*

Die `KitchenSmall` ist das Herzstück der Speisenzubereitung. Sie empfängt keine eigenen Gäste (POI = false), sondern arbeitet rein im Hintergrund (Backoffice) für andere POIs wie Restaurant und Bar.

## 1. Rollen & Personal
- **Erforderliche Rolle:** `chef` (Koch).
- **Optionale Rolle:** `kitchen_helper` (Küchenhilfe).
- Die Küche ignoriert Mitarbeiter, die in Schulung (`training_state == "in_training"`) sind.

## 2. Der Koch-Prozess (`_process`)
Die Küche horcht sekündlich beim `GastroManager`, ob neue Bestellungen (`FoodOrder` mit Zustand `pending`) vorliegen.
1. **Ressourcen & Logik:**
   Die Küche ermittelt die kombinierte Geschwindigkeit (`chef_speed`) aller anwesenden, verfügbaren Köche. 
   - Ein Koch gibt seine Basis-Geschwindigkeit (z.B. +0.5 pro Skillpunkt).
   - Eine Küchenhilfe erhöht den Speed passiv nochmal zusätzlich (+50% Boost).
2. **Gleichzeitiges Kochen (`max_concurrent`):**
   Normalerweise kocht ein Koch ein Gericht nach dem anderen. Jeder *zusätzliche* anwesende Koch erhöht das Cap, sodass Gerichte parallel zubereitet werden können.
3. **Zubereitung (Cooking):**
   Das Gericht wechselt in den Zustand `cooking`. Ein Timer zählt rückwärts, basierend auf der Schwierigkeit/Basiszeit des Rezepts und dem `chef_speed`.
4. **Fertigstellung:**
   Ist der Timer bei 0, wird das Essen auf `ready` gesetzt. Der `GastroManager` feuert das Signal `sig_order_ready`, wodurch das Restaurant (oder die Bar) erfährt, dass die Bedienung das Essen abholen muss.

## 3. Fehlerquellen & Balancing
- Fehlt ein Koch, bleibt die Liste auf `pending` hängen. 
- Das Restaurant blockiert Bestellungen allerdings schon im Vorfeld, wenn die Küche unbesetzt ist.
- Die Effizienz der Küche wächst enorm durch das Level-Up der Köche sowie den Einsatz von Küchenhilfen, wodurch Staus zur Rush-Hour (Frühstück, Abendessen) vermieden werden.
