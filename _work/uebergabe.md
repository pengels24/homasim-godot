# Uebergabeprotokoll - Session 11.09.2026 (v0.1.51)

## Was war der letzte Stand?

Session sauber abgeschlossen. Ein einziger Bugfix, aber mit komplexer Root-Cause-Analyse.
Alle Commits auf dev. Kein offener Dirty-State.

## Bearbeitetes System

### Reachability-Check (Insel-Erkennung) - MapGrid.gd

Der Bau-Validierungscheck fuer raeumlich abgekappte Zimmer (get_placement_error) war
seit seiner Einfuehrung dead code - zwei unabhaengige Bugs ueberlagerten sich:

Root Cause 1: lobby_tile wurde als Mitte des Lobby-Koerpers berechnet (val=1 = solid).
-> astar.is_point_solid(lobby_tile) war IMMER true -> Early-Return -> Check nie ausgefuehrt.

Root Cause 2: Die Lobby ist in active_rooms. Ihr externer Exit-Tile liegt
ausserhalb der Parzelle (col -1, global col 15 bei Parzelle 1,0).
-> von innen nie erreichbar -> get_path_between_tiles() gab immer [] zurueck
-> alle Ghost-Positionen faelschlich rot (auch wenn Check lief).

Fix:
- Check 1 startet vom Ghost-Exit-Tile als Ankerpunkt (nicht Lobby-Tile)
- Lobby wird in der Check-1-Schleife uebersprungen (id == 'lobby')
- Check 2 (Ghost selbst erreichbar) nutzt entrance_dir-abhaengiges internes Corridor-Tile
  z.B. bei 'left': Tile rechts neben der Lobby = Vector2i(lx + lw, ly + lh/2)

Verhalten nach Fix:
- Ghost zeigt rot wenn er einen Raum isolieren wuerde
- Ghost zeigt gruen bei valider Platzierung
- Alle anderen Checks unveraendert (Tuer blockiert, Tuer ins Nichts, etc.)

## Sofortige naechste Schritte

1. Offene Baustellen aus wiki/alpha_backlog.md auflisten
2. Reachability-Check weiter beobachten - Edge-Cases koennen noch auftauchen
   (z.B. Raeume mit Exit-Tiles an Parzellenraendern)
3. Naechstes Ticket aus alpha_backlog.md pruefen - python _dev/linear_cli.py list
4. Offene Baustellen aus letzter Session:
   - Camera/Look-Direction Event-Start (noch nicht getestet)

## Geaenderte Dateien (Commit-Referenzen)

| Datei | Commits |
|---|---|
| scenes/ingame/map/MapGrid.gd | f36fda2, 5893f99, 694be19, 014d66e |
| changelog/gd-0.1.51.md | 014d66e |
| wiki/alpha_backlog.md | 014d66e |
