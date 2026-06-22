# Balancing: POI-Einnahmen & Betriebskosten

Geld generierende POIs (Points of Interest), wie zum Beispiel die Bar oder das Restaurant, bieten eine zweite wichtige Einnahmesäule abseits der Übernachtungskosten.

Damit sie das Wirtschaftssystem bereichern (und nicht komplett sprengen), basieren sie auf zwei zentralen Mechaniken: Einnahmen pro Besuch und täglichen Betriebskosten. Zudem erfordern sie Personal, um überhaupt öffnen zu können.

## 1. Pay-Per-Visit (Einnahmen pro Besuch)
Gäste zahlen nicht pauschal, sondern für jeden tatsächlichen Besuch im POI.
* Sobald ein Gast vom Zustand `WALKING` in `IN_POI` wechselt (also physisch ankommt), wird die Einnahme generiert.
* In der Definition des Raums wird hierfür künftig ein Wert hinterlegt (z.B. `"visit_income": 15`).
* Visuelles Feedback: Bei Ankunft ploppt ein Floating-Text auf (z.B. `+15 €`) und das Kassenbuch registriert den Umsatz.

## 2. Personalbedarf (`min_staff` / `max_staff`)
Ein POI öffnet nicht von allein. Um Einnahmen zu generieren, muss Personal vor Ort sein.
Jeder cash-generierende POI bekommt zwei neue Properties:
* `"min_staff"`: Die minimale Anzahl an zugewiesenem Personal (z.B. 1 Barkeeper), damit der Raum überhaupt als "geöffnet" gilt und Gäste ihn aufsuchen können.
* `"max_staff"`: Die maximale Anzahl an Personal, die aufgrund der Raumgröße oder Arbeitsstationen zugewiesen werden kann (z.B. 2 Barkeeper).
Ohne erreichtes `min_staff` gilt der POI für die Gäste-Wegfindung als geschlossen!

## 3. Betriebskosten (Risiko-Faktor)
Damit der Spieler nicht grundlos 10 Bars baut, haben POIs tägliche Betriebskosten.
* Das Personal generiert ohnehin Gehaltskosten (z.B. 60 € pro Tag für einen Mitarbeiter).
* Hinzu können tägliche Fixkosten für den Betrieb des Raumes kommen.
* **Das Risiko:** Wenn ein POI beispielsweise durch Personal und Fixkosten 100 € pro Tag verschlingt, ein Besuch aber nur 15 € einbringt, braucht der POI **mindestens 7 Besuche am Tag**, nur um Break-Even zu sein. Baut der Spieler die Bar zu früh im Spielverlauf (bei zu wenigen Gästen), macht er massiv Verlust.

## 4. Zufriedenheits-Booster
Der Besuch eines POIs befriedigt die Bedürfnisse des Gastes und steigert seine Zufriedenheit. Dies resultiert beim Checkout in einer deutlich höheren EXP-Ausschüttung. POIs sind also nicht nur für Geld wichtig, sondern zwingend notwendig, um die massiven EXP-Hürden in den höheren Leveln (Level 4+) zu überwinden.
