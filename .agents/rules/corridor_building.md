# Regel: Keine Flure bauen

**WICHTIG FÜR ALLE AGENTEN:** In diesem Spiel können keine "Flur"-Räume gebaut werden.
Das Spiel funktioniert ähnlich wie *Two Point Hospital*:
1. Die gesamte graue Fläche (die Parzelle) ist frei bebaubar.
2. Räume werden auf diese freie Fläche gesetzt.
3. **Flure entstehen organisch** aus den Freiflächen, die zwischen den gebauten Räumen übrig bleiben.
4. Gäste können über die gesamte freie graue Fläche laufen, um vom Eingang (z. B. der Lobby) zu den Zimmern zu gelangen. Der AStar berechnet automatisch den Weg über diese freien Flächen.

Versuche NIEMALS, Code zu schreiben, der "Flur"-Räume oder "Corridor"-Nodes generiert, platziert oder als eigenen Raumtyp behandelt. Flure sind schlichtweg das Fehlen von Räumen auf der Parzelle.
