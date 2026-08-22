---
name: update_doku
description: Aktualisiert nach einer Session automatisch den Alpha-Backlog, den Status Quo, das Changelog und die Tech-Doku. Unterstützt den Parameter "+v" für Versionserhöhungen.
---

# Update Doku Workflow

Wenn der User diesen Skill aufruft, arbeite folgende Schritte **streng sequenziell** ab. 
**Achtung:** Vermeide PowerShell-Befehle wie `Add-Content` oder `echo >>`, da diese oft das Datei-Encoding (UTF-8) zerstören. Nutze stattdessen deine nativen Code-Edit-Tools (`replace_file_content` etc.) oder Python-Skripte!
**Wichtig:** Wenn du Python-Skripte zur Textverarbeitung oder Fehlerbehebung erstellst, speichere diese **immer** im Ordner `_work/` (und nicht einfach lose im Workspace oder im `scratch/` Ordner).

1. **Versionierung prüfen:**
   - Hole die aktuelle Version aus der Datei `version.txt` (z.B. `v0.1.50`).
   - Wenn der Parameter `+v` beim Aufruf des Skills übergeben wurde, erhöhe die Ziffer am Ende (Patch-Version) um +1 (z.B. auf `v0.1.51`) und überschreibe die `version.txt`.
   - Speichere dir diese finale Version (entweder die alte oder die durch `+v` neu generierte) für die nächsten Schritte.

2. **Changelog schreiben:**
   - Öffne (oder erstelle) im Ordner `changelog/` die Zieldatei, die zur aktuellen Version passt (z.B. `gd-0.1.50.md` bzw. die neue Version).
   - Schreibe alle Änderungen, Bugfixes und neuen Features der aktuellen Session sauber formatiert als Bullet-Points (aufgeteilt in Kategorien) in diese Datei.
   - Falls die Datei schon existiert, hänge die Änderungen unten an.

3. **Alpha-Backlog pflegen:**
   - Lies `wiki/alpha_backlog.md` ein.
   - Hake Aufgaben ab, die in dieser Session gelöst wurden.
   - Ergänze ungeplante Tasks, die du repariert hast, in der entsprechenden Sektion.
   - Ergänze offene/neue Punkte, die während der Session aufgetaucht sind, auf die ToDo-Liste.

4. **Status Quo aktualisieren:**
   - Prüfe, ob in der Session **neue Core-Systeme, Akteure oder Räume komplett fertiggestellt** wurden.
   - Trage **NUR DIESE** (fertigen Dinge) in `wiki/status_quo.md` ein. Keine halben Sachen, keine Bugfixes.

5. **Wiki Tech-Doku pflegen (Lebenswichtig!):**
   - Gehe gedanklich die Dateien durch, die du in der Session verändert hast.
   - Prüfe den Ordner `wiki/` (z.B. `wiki/rooms/` oder `wiki/04_maintenance/`), ob es dort Dokumentationen gibt, die zu diesen Änderungen passen.
   - Aktualisiere die entsprechenden `.md`-Dateien (z.B. `bar.md`, wenn du Logik an der Bar geändert hast).
   - Lege neue `.md`-Dateien an, falls völlig neue Mechaniken oder Räume erschaffen wurden, die noch keine Doku haben.

6. **Git Commit (Sauberer Cut):**
   - Führe `git add .` aus.
   - Führe einen `git commit -m "core: gd-<version> changelog + session changes (<Kurze Zusammenfassung>)"` aus.
   - Dies sorgt für den sauberen Cut, wie vom User gewünscht.

7. **Übergabeprotokoll erstellen (Für den nächsten Agenten/Chat):**
   - Erstelle oder überschreibe die Datei `_work/uebergabe.md`.
   - Verfasse dort eine extrem präzise Zusammenfassung der gerade beendeten Session:
     - Was war der exakte letzte Stand?
     - Welche Systeme wurden bearbeitet oder refactored?
     - Was sind die **sofortigen nächsten Schritte** für den nächsten Agenten?
   - Formuliere es so, dass ein neuer Agent, der diesen Text beim Onboarding liest, sofort nahtlos weiterarbeiten kann.

8. **Abschlussbericht:**
   - Fasse dem User kurz und knapp in einer Antwort zusammen, was alles geschrieben, dokumentiert und committed wurde.
