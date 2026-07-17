# Update v0.1.39gd-td

In dieser Session haben wir tief in die Mechaniken der Wegfindung (Pathfinding) eingegriffen, um blockierte Wege und hängengebliebenes Personal zu befreien.

## Features & Verbesserungen
* **Visualisiertes Pathfinding:** Bei fehlgeschlagenen Wegen zeichnet das Personal nun eine rote Debug-Linie zum unerreichbaren Ziel, um blockierte Wege sofort sichtbar zu machen (für Devs).
* **Verbesserte Raumerkennung:** Die Bounding-Boxen der Räume berücksichtigen nun die globale Map-Skalierung, sodass sich das Personal nicht mehr "verlaufen" kann, wenn es am Rand eines Raumes steht.

## Bugfixes
* **Kollisions-Bug an Türen:** Türen (Exits) stanzen sich jetzt beim Bauen wieder korrekt durch die Wände, sodass neu gebaute Räume alte Türen nicht versehentlich zumauern.
* **Telefax-Lieferung behoben:** Die Bedienung findet nun endlich den physischen Weg in die Küche, um das Essen abzuholen, anstatt in Endlosschleifen festzustecken.
* **Chillen ohne Pause:** Ein Logikfehler wurde behoben, bei dem die Bedienung nach einem entspannten Herumschlendern (Chillen) fälschlicherweise für 20 Sekunden in eine imaginäre Arbeits-Phase ("working") wechselte und so echte Bestellungen ignorierte.
