Führe den Session-Abschluss für das HO·MA·SIM Godot-Projekt durch. Gehe Schritt für Schritt vor und warte nicht auf Bestätigung – führe alles durch.

## Schritt 1 – Version lesen
Lies `version.txt` im Projektstamm. Format: `gd-x-x-x`. Das ist die aktuelle Version für diesen Changelog.

## Schritt 2 – Änderungen ermitteln
- Führe `git log --oneline` aus um zu sehen ob es bereits Commits gibt
- Lies die letzte Changelog-Datei in `/changelog/` (alphabetisch letzte) um zu wissen was bereits dokumentiert ist
- Schau dir alle Änderungen seit dem letzten Commit an (`git diff HEAD` oder `git status`)
- Prüfe welche Linear-Issues (ANG-xxx) heute bearbeitet wurden – nutze dazu dein Gesprächsgedächtnis dieser Session

## Schritt 3 – Changelog schreiben
Erstelle `/changelog/gd-x-x-x.md` (mit der aktuellen Version aus version.txt) nach diesem Format:

```
## Version: x.x.x
**Datum: YYYY-MM-DD**

### Features & Verbesserungen
- **ANG-xxx** – Beschreibung was gebaut wurde, warum, wie es funktioniert

### Bugfixes
- Beschreibung des Fixes

### Technische Änderungen
- Refactoring, neue Autoloads, strukturelle Änderungen

### Offene Backlog-Issues
- **ANG-xxx** – Kurzbeschreibung (noch offen)
```

Nur Abschnitte aufführen die tatsächlich Inhalt haben. Beschreibungen präzise und technisch – wie in der Vorlage `0-1-1-vorlage.md`.

## Schritt 4 – Linear aktualisieren
- Issues die heute abgeschlossen wurden: Status auf "Done" setzen
- Neue Issues die heute besprochen aber noch nicht angelegt wurden: anlegen

## Schritt 5 – Git Commit
```bash
git add .
git commit -m "gd-x-x-x – [kurze Zusammenfassung: fix, feature, refactor]

[Vollständiger Changelog-Inhalt, bei mehr als 20 Zeilen auf die wichtigsten Punkte kürzen]"
git tag gd-x-x-x
```

## Schritt 6 – Memory & CLAUDE.md aktualisieren
- Prüfe ob neue Direktiven, Entscheidungen oder wichtige Patterns aus dieser Session in den Memory-Dateien fehlen
- Falls eine `CLAUDE.md` im Projekt existiert: relevante Projektkonventionen ergänzen

## Schritt 7 – Version erhöhen
Erhöhe die letzte Ziffer in `version.txt` um 1 (z.B. `gd-0.1.0` → `gd-0.1.1`).

## Abschluss
Gib eine kurze Zusammenfassung aus:
- Changelog-Datei: `changelog/gd-x-x-x.md`
- Git-Commit: Hash + Message
- Git-Tag: `gd-x-x-x`
- Linear: welche Issues geschlossen/angelegt
- Neue Version: `gd-x-x-x`
