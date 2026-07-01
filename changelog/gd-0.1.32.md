# Changelog gd-0.1.32

Datum: 2026-07-01

## Features & Verbesserungen
- **Vollständiges In-Game Tutorial:** Die interaktive Einführungs-Sequenz (TechDemo Tutorial) wurde massiv erweitert und abgeschlossen. Der Spieler lernt nun schrittweise:
  - Kameraführung (Bewegen und Zoomen)
  - Das Bauen von Einzel- und Doppelzimmern
  - Den Start der Simulation / Zeit
  - Das erfolgreiche Einchecken von Gästen an der Rezeption
  - Das Einstellen von Personal (Housekeeping und Maintenance) in der Personal-Agentur nach dem ersten Level-Up.
- **Tutorial Abschluss-Fenster:** Ist das Tutorial nach 26 Schritten abgeschlossen, wird der Spieler mit einem neuen übersichtlichen Modal beglückwünscht. Von dort kann er sauber in das Hauptmenü zurückkehren (das Spiel wird dabei korrekt entpausiert).
- **Mehrsprachigkeit:** Sämtliche 26 Schritte des Tutorials, alle Dialog-Buttons, sowie die neuen Modals wurden vollständig in das zentrale Sprach-System (language.csv) integriert und auf DE und EN übersetzt.
- **UI-Polishing im Tutorial:** Der Assistent macht intelligent Platz auf dem Bildschirm (z.B. rutscht er zur Seite, um das Rezeptions-Fenster nicht zu verdecken, und wieder in die Mitte, um den "Einstellen"-Button im Personal-Bereich freizugeben). Knöpfe wie das Bau-Menü oder der Personal-Button fangen an passenden Stellen an zu pulsieren, um den Fokus des Spielers zu lenken.

## Bugfixes
- Fix: Die fehlerhafte Anzeige von Sonderzeichen/Umlauten im Personal-Einstellungs-Popup (Arbeitsvertrag) wurde repariert, das Layout lädt jetzt sauberes UTF-8.
- Fix: Wenn im Tutorial das Spiel neu geladen wird, erkennt das System nun sauber, ob Modals schon geöffnet sind und fängt asynchrone Fehler ab (Schritt 21).
- Fix: Buttons im Hauptmenü waren nach Abschluss des Tutorials nicht anklickbar, da der Pause-Status des Engine-Trees nicht korrekt zurückgesetzt wurde. Dies ist nun behoben.
- Fix: Bei Rückkehr aus dem Tutorial ins Hauptmenü wurde der Ingame-Status nicht korrekt zurückgesetzt, weshalb der Sprachen-Umschalter in den Settings gesperrt blieb.
- Fix: Pulsierende Buttons (z.B. Rezeption) werden nun zuverlässig gestoppt, sobald die geforderte Aktion erfolgreich beendet wurde.
- Fix: Den veralteten "Tutorial abgeschlossen (Vorschau)" Toast am Ende des Tutorials entfernt.
