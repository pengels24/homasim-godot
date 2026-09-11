# Changelog - v0.1.52
> Branch: `dev` | Datum: 11.09.2026

## Bugfix: Reachability-Check (Insel-Erkennung) reaktiviert

Der Bau-Validierungscheck fuer raeumlich isolierte Zimmer war seit seiner Einfuehrung
dead code - der Check lief nie durch, weshalb Platzierungen die Raeume abkappen
immer als gruen markiert wurden.

### Root Causes (beide gleichzeitig aktiv)

**Root Cause 1 - Falscher Startpunkt:**
lobby_tile zeigte auf die Lobby-Koerper-Mitte (val=1 = solid).
astar.is_point_solid(lobby_tile) war IMMER true - Early-Return - Check tot.

**Root Cause 2 - Lobby in active_rooms:**
Die Lobby ist in active_rooms enthalten. Ihr externer Exit-Tile liegt ausserhalb
der Parzelle (col -1, global). Von innen nie erreichbar - Check 1 schlug fuer die
Lobby IMMER fehl - alle Ghost-Positionen faelschlich rot.

### Fix (MapGrid.gd)

- Check 1 startet jetzt vom Ghost-Exit-Tile (nicht Lobby-Tile).
  Ankerpunkt: Sind alle Raeume von der Ghost-Tuer aus erreichbar?
  Wenn nicht - Raum wird isoliert - rot.
- Lobby wird in der Check-1-Schleife uebersprungen (id == "lobby").
- Check 2 (Ghost selbst erreichbar) verwendet entrance_dir-abhaengiges
  internes Corridor-Tile neben der Lobby.

### Ergebnis
- Ghost zeigt rot wenn er einen Raum isolieren wuerde
- Ghost zeigt gruen bei valider Platzierung
- Alle anderen Placement-Checks unveraendert
