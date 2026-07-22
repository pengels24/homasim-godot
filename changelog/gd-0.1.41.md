# HO·MA·SIM Changelog gd-0.1.41
Datum: 2026-07-22

## Features & Verbesserungen
- **Sättigungs-System (Hunger):** Gäste haben nun einen funktionierenden Sättigungs-Wert, der stündlich sinkt. Ab einem Wert von 50 gehen sie in die Gastro (Restaurant/Bar), um etwas passendes zu bestellen.
- **Nacht-Hunger:** Bei Tagesbeginn (06:00 Uhr) verlieren alle aktiven Gäste sofort 25 Sättigung, damit sie pünktlich hungrig zum Frühstück erscheinen.
- **Zufälliger Start-Hunger:** Neue Gäste spawnen nun mit einem zufälligen Sättigungsgrad (40-100), da manche nach einer "langen Anfahrt" direkten Hunger mitbringen.
- **Hunger-Indikator:** Ein kleines, passendes Icon (roter Kochtopf) erscheint mittig über dem Gast, solange sein Hunger-Wert unter 50 liegt, um den Spieler optisch darauf hinzuweisen.
- **Köpfe statt Partys:** Das Top-HUD sowie die Rezeption zeigen ab sofort die tatsächliche Anzahl der Personen (Köpfe) an, statt der gebuchten Zimmer/Partys, um Verwirrung mit den Tooltip-Zahlen zu vermeiden.
- **Sättigungs-Balken UI:** Der Gäste-Tooltip (Lobby/Zimmer) zeigt nun den "Sättigung"-Balken in Farbe und Stil analog zu den Sauberkeitsbalken.
- **Neues Getränk:** Softdrinks stehen jetzt für den schmalen Geldbeutel auf der Karte
- **Schlaue Gäste:** Gäste haben jetzt ihr Budget im Blick und bestellen nur, was sie sich leisten können (Gastro-Eintritt erfordert min. 5€ Budget)
- **Klare Übersicht:** Die Gästeliste zeigt jetzt den korrekten Status an, wenn Gäste essen oder an der Bar trinken
- **Smarte Gastro:** Das Restaurant nimmt keine Bestellungen mehr an, wenn keine Bedienung da ist
- **Gäste-Liste UI:** Die aktuelle Aktivität/Ort der Gäste wird in der Listen-Ansicht nun kompakt ("in Restaurant") und in den Details ausführlich mit Zimmernummer angezeigt
- **Zustands-Feedback:** Fällt die Sauberkeit oder der Zustand eines Zimmers auf 0%, wird das entsprechende Warn-Icon (Besen/Schlüssel) nun auffällig rot eingefärbt
- **Personal-Moral Aktiviert:** Mitarbeiter erholen sich nun automatisch (bis max 50%), wenn sie im Leerlauf sind (Idle). Zudem gibt es in der Personal-Übersicht nun einen "Bonus zahlen"-Button, um die Moral aktiv durch eine Geldzahlung hochzuhalten.
- **Neue Gäste-Icons:** Die Gästetypen "Budgetreisender" und "Event-Teilnehmer" haben frische, neue Icons erhalten.

## Bugfixes
- **Ghost-Icons im UI:** Ein Fehler wurde behoben, bei dem das "Kein Personal"-Warn-Icon unberechtigterweise in POI-Räumen (wie der Bar) neben dem Fortschrittsbalken auftauchte, wenn Mitarbeiter dort eine Aufgabe (z.B. Putzen) ausführten.
- **Timer & Fast Forward:** Der Fehler wurde behoben, durch den das Spiel nach Schließen der Rezeption am Tagesanfang ungewollt in den extremen Vorlauf schoss
- **Farb-Picker Absturz:** Alte Savegames verursachen beim Öffnen des Zimmermenüs keinen Absturz mehr (Invalid color name Bug gefixt)
- **Küche nicht gefunden:** Ein Bug wurde behoben, bei dem das Restaurant die Küche nicht finden konnte (weil das MapGrid nicht korrekt in der Godot-Gruppe registriert war) und Bestellungen deshalb abgebrochen wurden
- **Crash-Verhinderung:** Ein Fehler (Division by Zero) wurde verhindert, der auftrat, wenn Gäste genug Budget für einen Restaurantbesuch, aber nicht genug Geld für das günstigste Gericht hatten
- **Debugger-Warnungen:** Schatten-Variablen, ungenutzte Parameter und ungültige UIDs wurden bereinigt, um das Debug-Log sauber zu halten

## Technische Änderungen
- **Code Cleanup:** Nerviger Debugger-Spam vom TimeManager wurde restlos entfernt
- **Formatierung:** Strikte Tabulator-Einrückungen in den Kern-Skripten wiederhergestellt
- **Linear Issue Tracker:** ANG-315 für das zukünftige "Gäste-Gedanken-Log"-Feature als UX-Alternative zu überladenen Sprechblasen angelegt
