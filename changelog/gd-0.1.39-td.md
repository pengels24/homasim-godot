# Update v0.1.39gd-td

In dieser Session haben wir tief in die Mechaniken der Wegfindung (Pathfinding) eingegriffen, um blockierte Wege und hängengebliebenes Personal zu befreien.

## Features & Verbesserungen
* **Visualisiertes Pathfinding:** Bei fehlgeschlagenen Wegen zeichnet das Personal nun eine rote Debug-Linie zum unerreichbaren Ziel, um blockierte Wege sofort sichtbar zu machen (für Devs).
* **Verbesserte Raumerkennung:** Die Bounding-Boxen der Räume berücksichtigen nun die globale Map-Skalierung, sodass sich das Personal nicht mehr "verlaufen" kann, wenn es am Rand eines Raumes steht.

## Bugfixes
* **Kollisions-Bug an Türen:** Türen (Exits) stanzen sich jetzt beim Bauen wieder korrekt durch die Wände, sodass neu gebaute Räume alte Türen nicht versehentlich zumauern.
* **Telefax-Lieferung behoben:** Die Bedienung findet nun endlich den physischen Weg in die Küche, um das Essen abzuholen, anstatt in Endlosschleifen festzustecken.
* **Chillen ohne Pause:** Ein Logikfehler wurde behoben, bei dem die Bedienung nach einem entspannten Herumschlendern (Chillen) fälschlicherweise für 20 Sekunden in eine imaginäre Arbeits-Phase ("working") wechselte und so echte Bestellungen ignorierte.
* **Ghost-Walking durch Wände behoben:** Eine zu großzügige Toleranzzone beim Betreten von Räumen (`r_rect.grow`) wurde entfernt. Das Personal läuft nun sauber durch den Flur, anstatt schräg durch benachbarte Raumwände abzukürzen.
* **Gäste saßen endlos fest:** Ein Fehler wurde behoben, bei dem Gäste nach dem Essen für immer am Tisch sitzen blieben. Der `IDLE`-Status tickt nun korrekt runter, sodass sie aufstehen und Platz für neue Gäste machen.
* **Restaurant Gäste im Tooltip:** Restaurant-Gäste werden nun korrekt bei "Aktuelle Gäste" im Raum-Tooltip mitgezählt (berücksichtigt nun auch die Essens-Status statt nur den generischen POI-Status).

## Technische Änderungen & UI
* **Küchen Live-Monitor & Lokalisierung:** "Burger-Sprites" wurden aus der Küche entfernt. Stattdessen wird nun ordentlich "Abholbereit" im Live-Monitor angezeigt. Alle festen Texte der Küche wurden sauber in die `language.csv` ausgelagert.
* **Floating Cash beim Essen:** Wenn Gäste ihr Essen serviert bekommen, fliegt nun (zusätzlich zu den EXP) auch der gezahlte Geldbetrag visuell über ihren Köpfen nach oben.
* **UI Aufräumarbeiten:** Irrelevante Debug-Infos ("Bedienung Status") wurden aus dem Restaurant-Live-Monitor entfernt. Ebenso wurde die unsinnige Anzeige "Aktuelle Gäste: 0" aus dem Küchen-Tooltip entfernt.
