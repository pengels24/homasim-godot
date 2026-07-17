# Update v0.1.40

In dieser Session haben wir den Restaurant-Besuch der Gäste und die UI der Gastronomie verbessert, sowie Bugfixes vorgenommen.

## Bugfixes
* **Ghost-Walking durch Wände behoben:** Eine zu großzügige Toleranzzone beim Betreten von Räumen (`r_rect.grow`) wurde entfernt. Das Personal läuft nun sauber durch den Flur, anstatt schräg durch benachbarte Raumwände abzukürzen.
* **Gäste saßen endlos fest:** Ein Fehler wurde behoben, bei dem Gäste nach dem Essen für immer am Tisch sitzen blieben. Der `IDLE`-Status tickt nun korrekt runter, sodass sie aufstehen und Platz für neue Gäste machen.
* **Restaurant Gäste im Tooltip:** Restaurant-Gäste werden nun korrekt bei "Aktuelle Gäste" im Raum-Tooltip mitgezählt (berücksichtigt nun auch die Essens-Status statt nur den generischen POI-Status).

## Technische Änderungen & UI
* **Küchen Live-Monitor & Lokalisierung:** "Burger-Sprites" wurden aus der Küche entfernt. Stattdessen wird nun ordentlich "Status: Abholbereit" im Live-Monitor angezeigt. Alle festen Texte der Küche wurden sauber in die `language.csv` ausgelagert.
* **Floating Cash beim Essen:** Wenn Gäste ihr Essen serviert bekommen, fliegt nun (zusätzlich zu den EXP) auch der gezahlte Geldbetrag visuell über ihren Köpfen nach oben.
* **UI Aufräumarbeiten:** Irrelevante Debug-Infos ("Bedienung Status") wurden aus dem Restaurant-Live-Monitor entfernt. Ebenso wurde die unsinnige Anzeige "Aktuelle Gäste: 0" aus dem Küchen-Tooltip entfernt.
