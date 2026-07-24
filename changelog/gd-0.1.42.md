# Changelog v0.1.42gd (2026-07-25)

## Features & Verbesserungen
- **Personalraum Überarbeitung:** Der Tooltip und die Live-Detailansicht zeigen nun zuverlässig die anwesenden Mitarbeiter und deren Beruf anstelle von fehlerhaften 'Frei'-Anzeigen.
- **Sauberere UI:** Das Format der Mitarbeiter-Anzeige wurde aufgewertet (z.B. 'Bereit | Wartet - Moral: 100%'), wodurch der 'Klammersalat' der Vergangenheit angehört.
- **Gast-Codex Updates:** Wenn ein neuer Gasttyp das Hotel betritt, zeigen die aufpoppenden Info-Tutorials nun die originalen, hochauflösenden Pixel-Art-Grafiken anstatt veralteter Platzhalter-Icons.

## Bugfixes
- **Farben froh:** Ein Fehler wurde behoben, bei dem der Colorpicker im Personalraum die ausgewählte Farbe ignorierte und die Listeneinträge weiß blieben.
- **Keine schwarzen Kästen mehr:** Ein visueller Fehler wurde korrigiert, bei dem über arbeitendem Personal nach Beendigung der Arbeit ein leeres schwarzes Kästchen (Artefakt) in der Welt zurückblieb.
- **Wegpunkt System:** Es gab Korrekturen an den Wegpunkten, sodass sich Personal nun sicherer und gezielter in den Räumen bewegt.

## Technische Änderungen
- **Staff POIs:** Die Code-Architektur wurde um die Eigenschaft is_staff_poi erweitert. Zukünftige Personalräume lassen sich damit viel leichter in das System integrieren.
