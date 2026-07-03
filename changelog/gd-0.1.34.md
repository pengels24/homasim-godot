# gd-0.1.34 - (in Arbeit)

## Features & Verbesserungen
- **Save/Load:** Sicherheitsabfrage vor dem Laden/Überschreiben von Spielständen hinzugefügt
- **UX:** Nach dem Speichern schließt sich das Menü nun automatisch
- **Tooltips:** Raum-Tooltips zeigen nun Belegung und nötigen Service gleichzeitig an
- **Kassenbuch:** Details zu Bau- und Abrisskosten werden nun detaillierter aufgeschlüsselt
- **Rezeption:** Gäste-Tooltip zeigt nun den genauen Grund fürs Warten (Check-In/Check-Out) an

## Bugfixes
- **Quests:** Exploit behoben, bei dem das Abreißen von Räumen fälschlicherweise Bau-Quests abschließen konnte
- **Personal:** Optische Überlappungen behoben, wenn mehrere Mitarbeiter zeitgleich am selben Ort arbeiten
- **Rezeption:** Gäste-Ablehnen-Dialog (Confirm Modal) zentriert und Fehler mit Platzhaltern (Gastname, Ruf-Kosten) behoben

## Technische Änderungen
- Security: secrets.cfg wird nicht mehr in den Build exportiert (Linear API Key + Discord Webhook geschützt)
- BugReporter: Webhook-URL als Fallback im Binary hinterlegt bis PHP-Proxy verfügbar ist
- Export-Presets: SVG- und JSON-Dateien zum Include-Filter hinzugefügt (fehlende Assets im Build)
