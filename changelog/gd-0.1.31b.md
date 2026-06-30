# Changelog gd-0.1.31b

Datum: 2026-06-30

## Features & Verbesserungen
- **TechDemo Ende:** Nach dem Erreichen von Level 5 und einer kurzen Zeitverzögerung (15 Ingame-Minuten) erscheint ein neuer Dankes-Dialog (`ModalContentTechDemoEnd`), der das Ende der aktuellen TechDemo-Inhalte signalisiert. Das Spiel läuft danach regulär weiter.
- **Baumodus Tooltips:** Das Platzieren von Räumen gibt nun direktes, optisch ansprechendes Feedback! Ein kleines Tooltip am Mauscursor (im scharfen CanvasLayer) erklärt genau, *warum* ein Raum rot markiert ist (z.B. "Tür blockiert / verdeckt", "Muss an das Wegenetz grenzen").

## Bugfixes
- Fix: Ein kritischer Absturz (Stack Overflow / Infinite Loop) beim Verarbeiten von EXP und Levelaufstiegen wurde behoben. Die Funktion `GameState.add_exp()` deckelt das System nach Erreichen von Level 5 nun sauber.

## Technische Änderungen
- Auslagerung des Baumodus-Tooltips in eine eigene Szene (`BuildTooltip.tscn`) mit `CanvasLayer`, um scharfe Schriften (unabhängig vom Kamera-Zoom) im korrekten UI-Design zu garantieren.
- Erweiterung von `MapGrid.gd` um `get_placement_error()`, um statt generischem true/false spezifische Bau-Einschränkungen als Text-Key zurückzugeben.
- Erweiterung der `language.csv` um `build.error.*` Übersetzungen.
- Aktualisierung der internen Agenten-Richtlinien (`.agents/AGENTS.md`) zur korrekten Verwendung von `language.csv`.
