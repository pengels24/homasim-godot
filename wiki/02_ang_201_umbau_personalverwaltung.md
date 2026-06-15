# ANG-201 - Umbau Personalverwaltung

_Planungsdokument_
_Stand: 15.06.2026_

## Konzept
- **Kein physisches Personalbüro:** Das alte "Personalbüro" als physisch baubarer Raum wird überflüssig und daher aus dem Baumenü entfernt. Der Raum-Typ (ID) wird später umbenannt und für andere Gameplay-Elemente verwendet.
- **Level-basierte Freischaltung:** Die Personalverwaltung selbst wird ab **Level 2** des Hotels vollautomatisch freigeschaltet.
- **Narrative Integration:** Dies wird dem Spieler nicht einfach als UI-Unlock präsentiert, sondern narrativ als **Vertrag mit einem Personaldienstleister** kommuniziert. 
- **Einführungs-Szene:** Der allererste Aufruf der Personalverwaltung nach Erreichen von Level 2 zeigt eine kleine Einführungs-Szene (z.B. ein Dialog oder Pop-up mit der Agentur), um das neue Feature vorzustellen.

## Technische Implikationen
- Die Freischaltbedingung für den Personal-Button im Haupt-HUD wird von `Raum "Personalbüro" existiert` auf `GameState.Level >= 2` umgestellt.
- Ein Flag für das Abspielen der Einführungs-Szene muss im Savegame (`GameState`) gespeichert werden, damit die Szene nur einmalig beim ersten Öffnen abgespielt wird.
