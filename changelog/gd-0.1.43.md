# v0.1.43gd - 2026-07-26

### Features & Verbesserungen
- **Zimmer-Navigation:** Lokale Raum-Navigation wird nun synchron generiert, damit spawnende Gäste sofort korrekte Pfade finden und nicht mehr initial durch Möbel laufen.
- **Wegfindung:** Gäste nutzen beim Verlassen eines Zimmers nun konsequent die innere Raum-Navigation zur Tür, bevor sie den Flur betreten, um "Geister-Spaziergänge" durch Wände zu vermeiden.
- **Sitz-Ausrichtung:** Gäste drehen sich beim Hinsetzen an Tischen nun wieder physikalisch korrekt in die richtige Richtung, ohne künstliche 90-Grad-Korrekturen.

### Bugfixes
- **Klick-Prioritäten:** Zimmer fangen keine Klicks mehr ab, wenn man stattdessen einen Gast oder Mitarbeiter anklicken wollte (Laserstrahl-Raycast prüft nun, ob eine Person im Weg steht).
- **Gast-Erkennung:** Gäste wurden bei der Erstellung korrekterweise der Gruppe `guest_actors` hinzugefügt, damit sie von der Spiel-Physik und Klick-Logik sauber als solche erkannt werden.

### Technische Änderungen
- **ClickArea:** Gast- und Personal-Klickbereiche nutzen wieder Godots natives `_input_event`, da die Prioritätenklärung nun sauber vom Raum (`Room.gd`) übernommen wird.
