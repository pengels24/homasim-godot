---
name: update_doku
description: Aktualisiert nach einer Session automatisch den Alpha-Backlog, den Status Quo und das Changelog. Unterstützt Parameter wie "+v" für Versionserhöhungen.
---

# Update Doku Workflow

Wenn der User diesen Skill aufruft, prüfe sofort, ob Parameter (z.B. `+v`) mitgegeben wurden. 
Führe dann folgende Schritte **streng sequenziell** aus:

1. **Backlog prüfen und aktualisieren:**
   - Lies `wiki/_dev/alpha_backlog.md` (bzw. `wiki/alpha_backlog.md`).
   - Hake alle in der aktuellen Session gelösten Aufgaben ab.
   - Füge neu entstandene, ungeplante Bugs/Fixes unter "Ungeplante Fixes der Session" hinzu.
   - **VERSIONS-LOGIK:** Erhöhe die Versionsnummer in `wiki/alpha_backlog.md` unter "Aktuell: vX.Y.Z" **sowie in der Datei `version.txt` im Hauptverzeichnis** **NUR**, wenn der Parameter `+v` übergeben wurde! Andernfalls bleibt die Version gleich.

2. **Linear-Issues prüfen:**
   - Führe `python _dev/linear_cli.py list` aus und prüfe, ob abgehakte Dinge auch in Linear auf "Done" gesetzt werden müssen (optional, falls vom User gewünscht).

3. **Status Quo aktualisieren:**
   - Die Datei `wiki/status_quo.md` ist eine reine Inventar-Liste (Checkliste: Was gibt es und was funktioniert?). Sie ist **kein** zweites Changelog!
   - Trage hier **ausschließlich** komplett neue, fertiggestellte Räume, Akteure oder Core-Systeme der aktuellen Session ein (als `[x] **Feature:** Funktioniert`).
   - Keine Bugfixes, kein Refactoring und keine WIP-Notizen eintragen.


4. **Changelog aktualisieren:**
   - Lies IMMER zuerst die aktuelle Version aus der Datei `version.txt` (z.B. `0.1.50`).
   - Die Zieldatei im Ordner `changelog/` lautet immer `gd-<version>.md` (z.B. `gd-0.1.50.md`). Versuche NIEMALS die höchste Version über Dateinamen im Ordner zu "erraten"!
   - **MIT `+v`:** Erhöhe die Version in `version.txt` (wie in Schritt 1 beschrieben), erstelle dann eine **NEUE** Datei für die hochgesetzte Version (z.B. `gd-0.1.51.md`) und schreibe die Änderungen dort hinein.
   - **OHNE `+v`:** Öffne die **bestehende** Datei passend zur aktuellen Version aus `version.txt` und **hänge** die Änderungen der aktuellen Session unter den passenden Kategorien an.
   - Schreibe alle Änderungen sauber formatiert als Bullet-Points.

5. **Wiki Tech-Doku & Raumbeschreibungen aktualisieren:**
   - Prüfe, ob in der Session grundlegende technische Systeme (z.B. Wegfindung, State-Machines) geändert wurden. Wenn ja, aktualisiere die entsprechenden Dateien in `wiki/04_maintenance/` (z.B. Checklisten oder Modding-Guides).
   - Prüfe, ob ein neuer Raum/POI (z.B. Bar, Pool, Restaurant) oder Gasttyp erstellt/geändert wurde.
   - Falls ja, navigiere nach `wiki/rooms/` bzw. in die passenden Beschreibungen und lege dort eine neue `.md`-Datei an (bzw. aktualisiere die bestehende) mit den aktuellen Mechaniken, Navigations-Regeln und Fallbacks des Raumes/Akteurs.

6. **Abschlussbericht:**
   - Antworte dem User mit einer kurzen Zusammenfassung der aktualisierten Dokumente.
