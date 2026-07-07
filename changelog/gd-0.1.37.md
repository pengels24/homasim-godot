# Changelog v0.1.37gd-td
Datum: 2026-07-06

## Features & Verbesserungen
- UX-Verbesserung (ANG-233): Nach der Erstellung eines neuen Managers landet der Spieler nun im Hauptmenü (wo der neue Manager stolz auf der ID-Card präsentiert wird) statt direkt in der Hotel-Auswahl. Das verhindert Verwirrung durch ähnlich aussehende Menüs.
- Hauptmenü Layout-Update: Breitere Abstände, zentrierte Buttons und abgerundetes Profil-Panel.
- Hauptmenü-Avatar zeigt nun die im Profil gespeicherten Farben korrekt an.
- "Spiel beenden"-Button oben rechts (X) hinzugefügt, steuerbar via Mausklick und ESC-Taste.
- Umfassende Lokalisierungs-Updates (Deutsch/Englisch) in der Rezeption (GuestCard, RoomCardAvailable, ModalContentReception).
- Übersetzungen für Gast-Tooltips (Gruppe, Budget, Präferenzen) implementiert.
- ActivityLog-Einträge für Gast-Aktionen (Check-in, Check-out, Wut-Verlassen) vollständig dynamisch übersetzt.
- Questbook: Der Button "Rang abschließen" ist nun auch im deaktivierten Zustand lokalisiert.
- SimBrowser-Apps zeigen nun ein rotes "Bald verfügbar" statt "Verfügbar", inklusive Lokalisierung.

## Bugfixes
- Hauptmenü ID-Card verliert nach dem Hovern nicht mehr ihr Styling.
- Klon-Bug im Manager-Select behoben (Avatare teilen sich nicht mehr unfreiwillig dieselben Farb-Materialien).
- Fehlende Übersetzungs-Keys für das Quit-Bestätigungsmodal in `language.csv` nachgetragen.
- UI-Fix: Fortschrittsbalken im Raum-Tooltip (Sauberkeit & Wartung) verwenden nun das Theme-Original und haben dieselben abgerundeten Ecken wie der Nächte-Balken.

## Technische Änderungen
- `CharacterDisplay.tscn` refactored: Basis-Elemente von `ColorRect` auf `Panel` umgestellt für dynamisches `StyleBoxFlat`-Styling.
- Zahlreiche harte Strings im Code durch `GameState.T()` Aufrufe ersetzt.
- `language.csv` um diverse Schlüssel (ActivityLog, Tooltips, Browser) erweitert.
