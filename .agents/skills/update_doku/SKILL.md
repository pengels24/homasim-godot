---
name: update_doku
description: Aktualisiert nach einer Session automatisch den Alpha-Backlog, den Status Quo und schreibt ein neues Changelog.
---

# Update Doku Workflow

Wenn der User diesen Skill aufruft, führe folgende Schritte **streng sequenziell** aus:

1. **Backlog prüfen und aktualisieren:**
   - Lies `wiki/_dev/alpha_backlog.md` (bzw. `wiki/alpha_backlog.md`).
   - Hake alle in der aktuellen Session gelösten Aufgaben ab.
   - Füge neu entstandene, ungeplante Bugs/Fixes unter "Ungeplante Fixes der Session" hinzu.
   - Erhöhe die Versionsnummer unter "Aktuell: vX.Y.Z" entsprechend der neuen Changelog-Version.

2. **Linear-Issues prüfen:**
   - Führe `python _dev/linear_cli.py list` aus und prüfe, ob abgehakte Dinge auch in Linear auf "Done" gesetzt werden müssen (optional, falls vom User gewünscht).

3. **Status Quo aktualisieren:**
   - Falls eine Datei `wiki/status_quo.md` existiert, aktualisiere sie mit den wichtigsten strukturellen Änderungen der Session.

4. **Neues Changelog erstellen:**
   - Prüfe im Ordner `changelog/` welches die höchste Versionsnummer `gd-0.1.X.md` ist.
   - Erstelle eine NEUE Datei für die nächsthöhere Version (z.B. `gd-0.1.45.md`).
   - Schreibe alle Änderungen dieser Session sauber formatiert als Bullet-Points hinein. Benutze Kategorien wie "Bugfixes", "Neue Features", "Refactoring".
   - **WICHTIG:** Lies die vorherige Changelog-Datei nicht ein und überschreibe sie nicht. Lege immer eine NEUE Datei an.

5. **Abschlussbericht:**
   - Antworte dem User mit einer kurzen Zusammenfassung der aktualisierten Dokumente.
