# Changelog v0.1.42gd (2026-07-25)

## Features & Verbesserungen
- **Personalraum Überarbeitung:** Der Tooltip und die Live-Detailansicht zeigen nun zuverlässig die anwesenden Mitarbeiter und deren Beruf anstelle von fehlerhaften 'Frei'-Anzeigen.
- **Sauberere UI:** Das Format der Mitarbeiter-Anzeige wurde aufgewertet (z.B. 'Bereit | Wartet - Moral: 100%'), wodurch der 'Klammersalat' der Vergangenheit angehört.
- **Gast-Codex Updates:** Wenn ein neuer Gasttyp das Hotel betritt, zeigen die aufpoppenden Info-Tutorials nun die originalen, hochauflösenden Pixel-Art-Grafiken anstatt veralteter Platzhalter-Icons.
- **Mitarbeiter Spawns:** Mitarbeiter spawnen jetzt beim Laden des Spiels direkt sichtbar im Pausenraum und sind sofort ins Hotelgeschehen eingebunden.
- **Pausenraum KI (Sitzen):** Hausmeister und Reinigungskräfte nutzen nun zuverlässig die Stühle im Pausenraum, während sie auf neue Aufgaben warten.
- **Beine vertreten:** Personal, das längere Zeit auf Stühlen pausiert, dreht nun ab und zu eine kleine Runde durch den Pausenraum, um sich die Beine zu vertreten.

## Bugfixes
- **Gast-Lobby-Pfad:** Gäste liefen durch die optischen Wände der Lobby, wenn sie um die Tische herum navigierten. Die 4 Ecken der Lobby wurden nun im Grid als massiv markiert, sodass die Gäste durch die Türen/Lücken gehen.
- **Personal-Pfad-Bug (eingefroren):** Hausmeister blieben vor dem Pausenraum im "Wartet"-Status hängen, wenn sie exakt auf dem Start/Ziel-Tile standen, da der Pfad fälschlicherweise geleert und somit ein Fehler beim Pathfinding angenommen wurde.
- **Farben froh:** Ein Fehler wurde behoben, bei dem der Colorpicker im Personalraum die ausgewählte Farbe ignorierte und die Listeneinträge weiß blieben.
- **Keine schwarzen Kästen mehr:** Ein visueller Fehler wurde korrigiert, bei dem über arbeitendem Personal nach Beendigung der Arbeit ein leeres schwarzes Kästchen (Artefakt) in der Welt zurückblieb.
- **Wegpunkt System:** Es gab Korrekturen an den Wegpunkten, sodass sich Personal nun sicherer und gezielter in den Räumen bewegt.
- **KI-Loop Fix:** Ein Fehler wurde behoben, bei dem Hausmeister beim Versuch sich hinzusetzen in einer Endlosschleife ("Idle" -> "Unterwegs") feststeckten und immer wieder zur Tür hinausliefen.
- **Tooltip Anpassung:** Der Status von pausierendem Personal wird nun übersichtlich als "Wartet" angezeigt (statt "Bereit | Wartet").

## Technische Änderungen
- **Staff POIs:** Die Code-Architektur wurde um die Eigenschaft is_staff_poi erweitert. Zukünftige Personalräume lassen sich damit viel leichter in das System integrieren.
