# Core Game Loop (Final)

## 1. Zeit & Phasen
-   **Session-basiert**: Die Zeit läuft nur, wenn der Spieler aktiv spielt.
-   **Der Tag**: Ein Spieltag geht von 06:00 bis 23:00 Uhr.
-   **Tagesende**: Um 23:00 Uhr stoppt die Zeit automatisch. Abrechnung erfolgt.
-   **Pause-Modus**: Bauen, Einstellen und Management sind **nur** im Pause-Modus möglich.

## 2. Der Zyklus (The Loop)
1.  **Planungs-Phase (Pause)**: 
    -   Spieler baut Räume.
    -   Spieler stellt Personal ein.
    -   **Zuweisung**: Personal wird Bereichen (z.B. "Etage 1") oder Räumen fest zugewiesen.
2.  **Aktions-Phase (Play)**:
    -   Zeit läuft (Simulation im Frontend).
    -   Gäste kommen, nutzen Räume, verursachen Schmutz/Verbrauch.
    -   Spieler schaut zu, greift aber nur bei **Events** ein (z.B. Rohrbruch -> Haustechnik schicken).
3.  **Abschluss-Phase (End of Day)**:
    -   Finanz-Report.
    -   Ruf-Update.

## 3. Architektur-Implikationen
-   **Frontend (JS)**: Hält den kompletten "Live-State" (Wo ist welcher Gast? Wie dreckig ist Raum 101?).
-   **Backend (PHP)**:
    -   Speichert den "Startzustand" des Tages.
    -   Speichert das "Ergebnis" des Tages.
    -   Validiert Bau-Aktionen (Genug Geld?).

## 4. Visualisierung
-   Vorerst abstrakt/tabellarisch, aber Architektur muss bereit sein für visuelle Darstellung (Koordinaten/Grid speichern).
