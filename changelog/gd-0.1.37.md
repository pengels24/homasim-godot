# Changelog v0.1.37gd-td
Datum: 2026-07-06

## Features & Verbesserungen
- Umfassende Lokalisierungs-Updates (Deutsch/Englisch) in der Rezeption (GuestCard, RoomCardAvailable, ModalContentReception).
- Übersetzungen für Gast-Tooltips (Gruppe, Budget, Präferenzen) implementiert.
- ActivityLog-Einträge für Gast-Aktionen (Check-in, Check-out, Wut-Verlassen) vollständig dynamisch übersetzt.
- Questbook: Der Button "Rang abschließen" ist nun auch im deaktivierten Zustand lokalisiert.
- SimBrowser-Apps zeigen nun ein rotes "Bald verfügbar" statt "Verfügbar", inklusive Lokalisierung.

## Bugfixes
- UI-Fix: Fortschrittsbalken im Raum-Tooltip (Sauberkeit & Wartung) verwenden nun das Theme-Original und haben dieselben abgerundeten Ecken wie der Nächte-Balken.

## Technische Änderungen
- Zahlreiche harte Strings im Code durch `GameState.T()` Aufrufe ersetzt.
- `language.csv` um diverse Schlüssel (ActivityLog, Tooltips, Browser) erweitert.
