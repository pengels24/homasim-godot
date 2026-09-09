# Regel: Skill- und Rule-Anweisungen müssen Tool-Calls erzwingen

## Kernerkenntnis (gelernt 09.09.2026)

Steps in Skills und Rules, die nur als **Text beschrieben** sind ohne eine konkrete Tool-Call-Anforderung, werden von Agenten **systematisch ignoriert** - unabhängig von Formulierungen wie `Lebenswichtig!`, `ZWINGEND` oder `IMMER`.

## Warum das passiert

Agenten handeln auf Basis von Tool-Calls. Rein textuelle Anweisungen (`Gehe gedanklich durch...`, `Pruefe ob...`) erzeugen keine Handlung und koennen ohne Konsequenz uebersprungen werden. Der Abschluss-Pull (Git Commit, Antwort schreiben) ist staerker als eine abstrakte Textanweisung.

## Die Regel

**Wenn du Skills oder Rules schreibst oder anpasst:**

Jede Anforderung, die tatsaechlich ausgefuehrt werden muss, braucht einen erzwungenen Tool-Call:
- `list_dir <pfad>` - zwingt zum Sichten einer Verzeichnisstruktur
- `view_file <datei>` - zwingt zum Lesen einer Datei vor Aenderungen
- `grep_search <begriff>` - zwingt zur aktiven Suche nach veralteten Begriffen
- `run_command <befehl>` - zwingt zur Ausfuehrung

**Falsch (ueberspringbar):**
> "Pruefe gedanklich ob die Wiki-Docs aktuell sind."

**Richtig (erzwungen):**
> "Fuehre `list_dir wiki/rooms/` aus. Oeffne dann fuer jede geaenderte Datei die passende `.md` mit `view_file`."

## Anwendung

Dieses Prinzip gilt fuer alle zukuenftigen Skill- und Rule-Aenderungen in diesem Projekt. Bevor du einen Skill schreibst: Ueberpruefe jeden Schritt - hat er einen erzwungenen Tool-Call? Wenn nicht, wird er ignoriert.
