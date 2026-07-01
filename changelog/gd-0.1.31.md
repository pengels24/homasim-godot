# Changelog gd-0.1.31

Datum: 2026-06-29

## Features & Verbesserungen
- **Neues Design für den SimBrowser:** Die App-Karten wurden komplett überarbeitet und erstrahlen nun in einem edlen, einheitlichen "Corporate Look" (Dunkelblau mit gelben Akzenten und weichen Schatten).
- **Landscape-Layout für Apps:** Die Kacheln im Browser nutzen jetzt ein horizontales Layout (Logo links, Texte rechts) für bessere Lesbarkeit und optimale Platznutzung. 
- **CTA-Buttons integriert:** Jede App-Kachel besitzt nun am unteren Rand einen klaren Button zum Aufrufen der jeweiligen Funktion.
- **Markenrechtliche Anpassungen:** Die App "Michelin" wurde in "Gourmet-Sterne" (Abkürzung: GS) umbenannt, inklusive angepasster URLs und Übersetzungen.
- **Tutorial-System:** Alle finalen Tutorial-Texte wurden geschrieben und in die mehrsprachigen Übersetzungsdateien implementiert.
- **Tutorial-Popup:** Das Layout des Ingame-Tutorials wurde drastisch vergrößert (1200x900px), um Screenshot-Bildern mehr Raum zu geben und lästiges Scrollen zu minimieren. Die Platzhalter-Bilder wurden gegen spezifische Screenshots für jedes Thema ausgetauscht.
- **Credits:** Die `credits.txt` wurde aktualisiert. Fremd-Asset-Einträge von Kenney wurden entfernt, da alle Tiles nun vollständig selbst gezeichnet sind. Sämtliche verwendeten Soundeffekte und Grafiken (Mond, Pixabay, FilmCow SFX, UI Sounds) wurden sauber lizenziert und aufgeführt.

## Bugfixes
- Fix: Ein Fehler beim Importieren, der Zeilenumbrüche in den Tutorial-Texten abschnitt, wurde behoben.
- Fix: Der deaktivierte "Tutorial"-Button im Hauptmenü hat nun dasselbe saubere Design wie andere inaktive Buttons und keinen grauen Standard-Hintergrund mehr.

## Technische Änderungen
- Anpassung des Grid-Layouts im SimBrowser (Reduzierung auf 3 Spalten zur optimalen Darstellung der neuen Landscape-Karten).
- Entfernung der alten dynamischen Farb-Logik für SimBrowser-Tiles aus dem Code.
- Einrichtung der `export_presets.cfg` mit eigenem Windows `.ico` Logo für den Standalone-Build.
- Entwicklung eines automatischen Deployment-Skripts (`deploy.bat`) zur Veröffentlichung der Builds via itch.io Butler.
- Ausschluss der riesigen Windows-Build-Dateien (`.exe`/`.pck`) in der `.gitignore` zur Beachtung des GitHub-Limits.
- Erweiterung des Deployment-Skripts und der `.gitignore` für automatische macOS- und Linux-Releases via itch.io.
- Konfiguration der macOS-Export-Vorgaben in der `export_presets.cfg` (Aktivierung der ETC2/ASTC-Texturkompression für Apple Silicon und Fix des Bundle-Identifiers).
