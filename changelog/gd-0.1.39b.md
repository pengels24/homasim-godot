# Update v0.1.39gd-b

In dieser Session lag der Fokus auf den Feinheiten des Hotelbetriebs und der Behebung von Restaurant-Bugs.

## Features & Verbesserungen
* **Proportionen:** Gäste und Personal wurden etwas kleiner skaliert (Erwachsene auf 0.8, Kinder auf 0.55), damit sie besser in die Räume passen und nicht mehr wie Riesen wirken.
* **Aushilfen:** Da die echten Sprites für Köche und Bedienungen noch fehlen, helfen unsere Barkeeper vorübergehend als Platzhalter aus. Niemand muss unsichtbar arbeiten!

## Bugfixes
* **Pünktlich zum Dienst:** Köche und Bedienungen begeben sich nun bei Arbeitsbeginn brav auf ihre Posten in Küche und Restaurant, anstatt unsichtbar in der Lobby festzuhängen.
* **Guten Appetit:** Der "letzte Handschlag" der Bedienung hat gefehlt. Das Essen wird nun korrekt am Tisch übergeben, sodass die Gäste endlich speisen können.
* **Zoom-Fix:** Das Scrollen im neuen Detailfenster zoomt nun nicht mehr versehentlich die Kamera im Hintergrund.
* **KI-Crash:** Ein Skriptfehler (`is_night` Konflikt) in der Personal-Routine wurde behoben.
