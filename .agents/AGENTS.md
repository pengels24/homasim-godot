# UI Design Rules

**STRIKTE DIREKTIVE: Immer den Style Guide beachten!**
Bevor du UI-Änderungen durchführst, musst du zwingend das Dokument `wiki/06_ui_style_guide.md` lesen und die dortigen Designvorgaben strikt einhalten.

- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. Das wirkt visuell zu unruhig ("too much"). Für innere Detail-Panels oder Tabellenköpfe stattdessen das `InnerPanel`-Theme oder transparente/schlichte Container verwenden.

---

# Changelog-Workflow

**Am Ende jeder Session oder auf explizite Aufforderung** einen Changelog erstellen:

- Datei: `changelog/gd-0.1.XX.md` (nächste freie Versionsnummer)
- Format: wie `changelog/gd-0.1.10.md` – Abschnitte: `Features & Verbesserungen`, `Bugfixes`, `Technische Änderungen`
- **Kein Abschnitt „Offene Backlog-Issues"** – der bleibt weg
- Datum im Format `YYYY-MM-DD` (tagesbezogen)
- Der Changelog dient als Grundlage für Social Media Posts → prägnant, auf Deutsch, spielernah formulieren
- Nach dem Changelog: `git add -A && git commit -m "chore: gd-0.1.XX changelog + session changes" && git push`

---

# Allgemeine Regeln

- **Einzelne Schritte**: Peter liest genau und versteht lieber Schritt für Schritt als zu viel auf einmal.
- **Clean Code**: Debug-Prints (`[BAR_TEST]`, `[DEBUG]` etc.) nach erfolgreichem Test entfernen. Debug-Visualizer (Overlays, Linien) bleiben als Toggle erhalten, werden aber standardmäßig deaktiviert.
- **Keine Dopplungen**: Logik die an mehreren Stellen gebraucht wird zentral implementieren (z. B. `StaffManager.is_poi_staffed()`).
