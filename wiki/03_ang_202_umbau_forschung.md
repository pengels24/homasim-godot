# ANG-202 - Umbau Forschung / Techtree

_Planungsdokument_
_Stand: 15.06.2026_

## Konzept
- **Kein physisches Forschungsbüro:** Das alte "Forschungsbüro" (bzw. "Planungsbüro") als baubarer Raum wird überflüssig und daher entfernt. Der Raum wird später umbenannt und für andere Gameplay-Mechaniken (z.B. echtes Büro für den Spieler) verwendet.
- **Level-basierte Freischaltung:** Die Forschung selbst wird ab **Level 5** des Hotels vollautomatisch freigeschaltet und markiert damit auch das "Tier 1 Gate" für den Techtree und den Beginn der FP-Generierung.
- **Narrative Integration:** Der Zugang zur Forschung wird dem Spieler als **Vertrag mit einem Forschungsinstitut** kommuniziert.
- **Einführungs-Szene:** Der allererste Aufruf der Forschung (bzw. das Erreichen von Level 5) triggert eine kleine Einführungs-Szene, in der das FP-System und der Techtree erklärt werden.

## Technische Implikationen
- Die Generierung von FP (Forschungspunkten) im Ingame-Ticker beginnt nicht mehr mit dem Bau eines Raumes, sondern sobald `GameState.Level >= 5`.
- Die Freischaltbedingung für den Forschungs-Button im Haupt-HUD wird auf `GameState.Level >= 5` umgestellt.
- Ein Flag für das Abspielen der Einführungs-Szene wird im Savegame gespeichert, damit sie nicht bei jedem Neuladen ausgelöst wird.
