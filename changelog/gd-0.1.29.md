# Changelog gd-0.1.29
Datum: 2026-06-27

## Features & Verbesserungen
- **Lokalisierung abgeschlossen:** Zahlreiche harte, deutsche Strings in den UI-Komponenten (Techtree, Questbook, BuildMenu, Staff, GuestCard, GuestList, RoomList) wurden durch GameState.T()-Aufrufe ersetzt.
- **Techtree-Bestätigung:** Die Strings im Tech-Tree Pop-Up wurden vollständig übersetzt und Fehler mit zu vielen Parametern beim GameState.T() Aufruf gefixt.
- **Personalverwaltung übersetzt:** Alle Buttons, Tabs ("Dein Team", "Bewerber", "Zuweisung"), Attribute ("Beruf", "Gehalt", "Status") und Skills im Staff-Panel unterstützen nun die Sprachauswahl.
- **Language CSV erweitert:** Zahlreiche neue Keys und Fallbacks in die language.csv hinzugefügt und bestehende UTF-8 Fehler behoben, um eine korrekte Darstellung (insbesondere von Umlauten) zu gewährleisten.

## Bugfixes
- **Crash Fix (Techtree):** Behoben, dass das Spiel abstürzte, weil die Translation-Funktion mit zu vielen Parametern aufgerufen wurde.
- **Übersetzung-Fallbacks entfernt:** Unerwartetes Verhalten von GameState.T() (die TranslationServer ignorierte) behoben, indem hartcodierte Fallbacks aus den Argumenten der GD-Skripte entfernt wurden.
- **CSV Formatierung:** Fehler mit fehlerhaft kodierten Rechten/Zeichen (z.B. Euro-Zeichen und Umlaute) durch korrekte UTF-8 Append-Methodik in der language.csv behoben.

## Technische Änderungen
- **GameState Translation Updates:** Anpassung fast aller ModalContent- und Karten-Scripts (GuestCard, Staff, etc.), um einheitlich die korrekte Signatur von GameState.T() (4 Parameter ohne reinen Fallback) zu nutzen.