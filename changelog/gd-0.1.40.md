# Update v0.1.40

In dieser Version startet offiziell die Alpha-Phase. Der Fokus lag auf den Feinheiten des Hotelbetriebs, der Behebung von Restaurant-Bugs und UI-Verbesserungen.

## Features & Verbesserungen
* **Proportionen:** Gäste und Personal wurden etwas kleiner skaliert (Erwachsene auf 0.8, Kinder auf 0.55), damit sie besser in die Räume passen und nicht mehr wie Riesen wirken.
* **Aushilfen:** Da die echten Sprites für Köche und Bedienungen noch fehlen, helfen unsere Barkeeper vorübergehend als Platzhalter aus. Niemand muss unsichtbar arbeiten!

## Bugfixes
* **Pünktlich zum Dienst:** Köche und Bedienungen begeben sich nun bei Arbeitsbeginn brav auf ihre Posten in Küche und Restaurant, anstatt unsichtbar in der Lobby festzuhängen.
* **Guten Appetit:** Der "letzte Handschlag" der Bedienung hat gefehlt. Das Essen wird nun korrekt am Tisch übergeben, sodass die Gäste endlich speisen können.
* **Zoom-Fix:** Das Scrollen im neuen Detailfenster zoomt nun nicht mehr versehentlich die Kamera im Hintergrund.
* **KI-Crash:** Ein Skriptfehler (`is_night` Konflikt) in der Personal-Routine wurde behoben.
* **Ghost-Walking durch Wände behoben:** Eine zu großzügige Toleranzzone beim Betreten von Räumen (`r_rect.grow`) wurde entfernt. Das Personal läuft nun sauber durch den Flur, anstatt schräg durch benachbarte Raumwände abzukürzen.
* **Gäste saßen endlos fest:** Ein Fehler wurde behoben, bei dem Gäste nach dem Essen für immer am Tisch sitzen blieben. Der `IDLE`-Status tickt nun korrekt runter, sodass sie aufstehen und Platz für neue Gäste machen.
* **Restaurant Gäste im Tooltip:** Restaurant-Gäste werden nun korrekt bei "Aktuelle Gäste" im Raum-Tooltip mitgezählt (berücksichtigt nun auch die Essens-Status statt nur den generischen POI-Status).

## Technische Änderungen & UI
* **Küchen Live-Monitor & Lokalisierung:** "Burger-Sprites" wurden aus der Küche entfernt. Stattdessen wird nun ordentlich "Status: Abholbereit" im Live-Monitor angezeigt. Alle festen Texte der Küche wurden sauber in die `language.csv` ausgelagert.
* **Floating Cash beim Essen:** Wenn Gäste ihr Essen serviert bekommen, fliegt nun (zusätzlich zu den EXP) auch der gezahlte Geldbetrag visuell über ihren Köpfen nach oben.
* **UI Aufräumarbeiten:** Irrelevante Debug-Infos ("Bedienung Status") wurden aus dem Restaurant-Live-Monitor entfernt. Ebenso wurde die unsinnige Anzeige "Aktuelle Gäste: 0" aus dem Küchen-Tooltip entfernt.
