# gd-0.1.34 – 2026-07-03

## Features & Verbesserungen
- **Save/Load:** Sicherheitsabfrage vor dem Laden/Überschreiben von Spielständen hinzugefügt
- **UX:** Nach dem Speichern schließt sich das Menü nun automatisch
- **UX:** Schnellvorlauf bietet nun auch Geschwindigkeiten x30 und x50 an
- **UX:** Scroll-Zoom Empfindlichkeit (Mausrad) ist nun in den Einstellungen anpassbar (ANG-223)
- **Tooltips:** Raum-Tooltips zeigen nun Belegung und nötigen Service gleichzeitig an
- **Kassenbuch:** Details zu Bau- und Abrisskosten werden nun detaillierter aufgeschlüsselt
- **Rezeption:** Gäste-Tooltip zeigt nun den genauen Grund fürs Warten (Check-In/Check-Out) an
- **Einstellungen:** Fenstermodus wählbar (Vollbild / Rahmenlos)
- **Einstellungen:** Monitor-Auswahl – Spiel startet direkt auf dem gewählten Monitor

## Bugfixes
- **Quests:** Exploit behoben, bei dem das Abreißen von Räumen fälschlicherweise Bau-Quests abschließen konnte
- **Personal:** Optische Überlappungen behoben, wenn mehrere Mitarbeiter zeitgleich am selben Ort arbeiten
- **Rezeption:** Gäste-Ablehnen-Dialog (Confirm Modal) zentriert und Fehler mit Platzhaltern (Gastname, Ruf-Kosten) behoben
- **Intro:** Musik läuft jetzt über den korrekten Bus und respektiert die Lautstärke-Einstellung
- **Disclaimer:** Haken „Nicht mehr anzeigen" wird nun korrekt gespeichert
- **BugReporter:** Sprache wechselt live mit der Spracheinstellung und startet in der richtigen Sprache
- **BugReporter:** Umlaute in den deutschen Texten korrigiert
- **Monitor:** Fenster bleibt beim Wechsel von Vollbild zu Rahmenlos auf dem aktuellen Monitor

## Technische Änderungen
- Security: secrets.cfg wird nicht mehr in den Build exportiert (Linear API Key + Discord Webhook geschützt)
- BugReporter: Webhook-URL als Fallback im Binary hinterlegt bis PHP-Proxy verfügbar ist
- Export-Presets: SVG- und JSON-Dateien zum Include-Filter hinzugefügt (fehlende Assets im Build)
- Fenstermodus/Monitor: Startup-Anwendung deferred (3 Frames) damit Godots eigene Initialisierung zuerst abschliesst
