# Übergabeprotokoll (Session 12.10.2026 – Planung Alpha-Start)

## ⭐ ZUERST LESEN
Lies **vollständig** `wiki/alpha_grid_rework_plan.md` (insbesondere Abschnitt 0). Es ist **verbindlich**; alle Entscheidungen in Abschnitt 3 sind getroffen und nicht neu zu diskutieren. Das ältere `wiki/ang364_nav_rework.md` ist teilweise überholt.

## Git-/Versionsschema (seit 12.10.2026)
- Tag **`v0.2.2-prealpha`** = eingefrorener Pre-Alpha-Stand (itch.io-Build v0.2.2).
- Branch **`prealpha`** = Pre-Alpha-Linie, Versionen **v0.2.x** (nur Feedback-Fixes, itch.io-Updates).
- Branch **`dev`** = Alpha-Linie, Versionen **v0.3.0+**. `version.txt` auf `dev` = `v0.3.0`.
- `master` ist alt/unberührt – nicht verwenden.
- Fixes für die Pre-Alpha zuerst auf `prealpha`, dann `git merge prealpha` in `dev`.

## Stand
- Es wurde in dieser Session **kein Spielcode geändert**. Geändert wurden nur Dokumente: `.agents/AGENTS.md` (.tscn-Regel: visuell = Freigabe, rein technisch = erlaubt), neuer Plan `wiki/alpha_grid_rework_plan.md`, Hinweis im alten `wiki/ang364_nav_rework.md` (beide aus dem nicht versionierten `wiki/_dev/` in das versionierte `wiki/` verschoben).
- Thema: Pre-Alpha (v0.2.2, auf itch.io, Streamer Sullivan hat sie; sein Ersteindruck-Video steht aus) einfrieren und die Alpha mit dem Zusammenführen von Welt-Grid und Raum-Grid zu **einem 4-px-Nav-Grid** beginnen.
- **Phase 0 (Einfrieren) ist ausgeführt:** Tag `v0.2.2-prealpha`, Branch `prealpha`, `dev` auf `v0.3.0` (siehe Git-/Versionsschema oben). Feature-Branch `alpha/grid-rework` wird erst bei Start der Umsetzung angelegt.

## Nächste Schritte (nur nach ausdrücklichem Go von Peter)
1. ~~Phase 0 – Einfrieren~~ (erledigt).
2. Phase 1 – Stresstest 300/600/1000 Gäste auf dem aktuellen Stand (unabhängig vom Rework, kein Risiko).
3. Phase 2 – Inventur (nur lesen), Ergebnis als Wiki-Dokument.
4. Erst danach Spike, Möbel-Szenen, Migration (siehe Plan).
Linear: vor neuen Tickets `python _dev/linear_cli.py list`; relevant sind ANG-364 (Backlog) und ANG-314 (Done).

## Wichtige Eigenheiten von Peter
- Du-Form, kurze Schritte, erst erklären was/warum. Ehrliche Meinung/Veto erwünscht.
- Beim Planen wurde Punkt für Punkt gesprochen; Peter möchte alles verstehen, bevor er ein Go gibt.

---

# Übergabeprotokoll (Ende v0.2.2 Session, früher)

## Status Quo
Die Version v0.2.2 ist nun vollständig fertig für den Alpha-Test. Letzte Anpassungen betrafen Bugfixes, Logik-Lücken im Balancing und UI-Polishing:
- Erste Gästeankunft (Tag 1) fest auf 07:00-07:30 gelegt.
- Bar öffnet jetzt von 12:00 bis 23:30 (vorher falsch auf 00:00).
- Business-Gäste werden streng an `bed_superior` gekoppelt und generieren sich nur, wenn das Zimmer existiert. Typo bei Digitale Nomaden (Level 5) korrigiert.
- Status-Indikatoren auf Räumen (Reinigung, Wartung) haben nun dynamische Tooltips je nach Zustand/Farbe. Alle dazugehörigen Strings und auch "Personal eingestellt" wurden in `language.csv` aufgenommen.
- Tutorial-Tipp für Reinigung/Wartung triggert nun verlässlich beim ersten dreckigen Raum oder beim Bau des ersten Personalraums.
- Störende Godot-Warnings (Vector2i-Mismatches, ungenutzte _room Parameter) wurden eliminiert.
- Sämtliche Code-Änderungen sind im Changelog `gd-0.2.2.md` vermerkt und das Backlog `alpha_backlog.md` wurde aktualisiert.

## Nächste Schritte
Peter testet die v0.2.2 (Tutorial & komplett neues Hotel).
Es sind vorerst KEINE weiteren Code-Änderungen geplant, außer es tauchen akute Bugs bei diesem finalen Check auf!
Warte auf Peters Feedback oder Go für Version 0.2.3.