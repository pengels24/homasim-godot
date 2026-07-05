# UI Design Rules

**STRIKTE DIREKTIVE: Immer den Style Guide beachten!**
Bevor du UI-Änderungen durchführst, musst du zwingend das Dokument `wiki/06_ui_style_guide.md` lesen und die dortigen Designvorgaben strikt einhalten.

- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. Das wirkt visuell zu unruhig ("too much"). Für innere Detail-Panels oder Tabellenköpfe stattdessen das `InnerPanel`-Theme oder transparente/schlichte Container verwenden.

---

# Changelog-Workflow

**Am Ende jeder Session oder auf explizite Aufforderung** einen Changelog erstellen:

- Datei: `changelog/gd-0.1.XX.md` – Versionsnummer **immer aus `/version.txt` lesen** (nie raten, nie selbst erhöhen – es sei denn Peter sagt explizit „Version erhöhen")
- Changelog-Nummer = aktuelle Version (z.B. `v0.1.28gd` → `gd-0.1.28.md`)
- Format: Abschnitte: `Features & Verbesserungen`, `Bugfixes`, `Technische Änderungen`
- **WICHTIG:** Ab sofort kurze, prägnante Stichpunkte! Nicht zu detailliert, da der Changelog direkt als Upload-Notice bei itch.io verwendet wird.
- **Kein Abschnitt „Offene Backlog-Issues"** – der bleibt weg
- Datum im Format `YYYY-MM-DD` (tagesbezogen)
- Der Changelog dient als Grundlage für Social Media Posts und itch.io Updates → prägnant, auf Deutsch, spielernah formulieren
- Nach dem Changelog: `git add -A; git commit -m "core: gd-0.1.XX changelog + session changes"`

---

# Allgemeine Regeln

- **Einzelne Schritte**: Peter liest genau und versteht lieber Schritt für Schritt als zu viel auf einmal.
- **Clean Code**: Debug-Prints (`[BAR_TEST]`, `[DEBUG]` etc.) nach erfolgreichem Test entfernen. Debug-Visualizer (Overlays, Linien) bleiben als Toggle erhalten, werden aber standardmäßig deaktiviert.
- **Keine Dopplungen**: Logik die an mehreren Stellen gebraucht wird zentral implementieren (z. B. `StaffManager.is_poi_staffed()`).


# HO·MA·SIM Godot – Claude Direktiven

## Projekt
Hotel-Management-Simulationsspiel. Godot 4.6 GDScript Desktop-Client.
Das Spiel arbeitet aktuell komplett lokal. Daten kommen aus Savegames (siehe `SaveManager` Autoload) und JSON-Dateien im Ordner `/config`. 
Ein PHP-Backend für Multiplayer/Leaderboards wird erst später in der Zukunft angebunden.
Linear-Projekt: **Angelus2010 / ANG-** für alle Issues.

## Aktueller Stand (TechDemo)
- Die TechDemo ist fast fertig.
- **EXP-Balancing / Unlocks**: Wurden kürzlich überarbeitet. Core-Features haben harte Level-Voraussetzungen, die jetzt zentral in `GameState.UNLOCK_LEVELS` (Level 2 = Personal, Level 3 = Techtree) gesteuert werden.
- Gäste generieren EXP beim Check-In und Check-Out. Zimmer geben einen Erst-Bau-EXP-Bonus.
- Savegame & Load System wurde stark stabilisiert (Tween-Bugs gefixt).
  
## Kommunikation
- **Du**-Form, entspannt aber zielorientiert
- ausschliesslich in deutsch antworten
- Kleine Dinge direkt umsetzen (Typos, etc.)
- Sonst immer zuerst besprechen -> lösen -> coden
- Kein Corporate-Sprech
- Peter liest genauer um zu verstehen – nicht zu viel auf einmal - einzelne Schritte

## Erklärbär-Modus (immer aktiv)
- Bei jeder Umsetzung kurz erklären **was** gemacht wird und **warum** – nicht erst auf Nachfrage
- Ziel: Peter soll den Code selbst verstehen und validieren können, nicht nur ausführen lassen
- Erklärungen in einfacher Sprache, mit Analogien wenn hilfreich
- Nicht überladen – ein kurzer Satz pro Konzept reicht oft
- **Ehrliche Meinung:** Sag Peter nicht einfach nach dem Mund. Wenn eine Idee aus Game-Design- oder Architektur-Sicht "Blödsinn" ist oder überladen wirkt, lege dein Veto ein und mach einen besseren Vorschlag.

## Godot-Direktiven
- **Immer Godot 4 API** – kein Godot 3 Syntax. Bei Unsicherheit Docs lesen, nicht halluzinieren.
- **Alle Texte via `GameState.T("key")`** – nie Strings hardcoden (außer als TODO-Platzhalter)
- **Feste Auflösung 1920×1080** – kein Scaling, `layout_mode=0` für manuelle Positionierung
- **Kein `tr()` in static func** – stattdessen `TranslationServer.translate(key)`

## Code-Direktiven
- **Keine God-Files** – jede Datei hat eine einzige Verantwortlichkeit
- **KISS** – kein Over-Engineering, kein spekulatives Abstrahieren
- **DRY** – wiederverwendbare Logik in eigene Autoloads/Klassen
- **Lesbarer, sauberer Weg** – nicht den schnellen Weg gehen; Code so schreiben wie ein erfahrener Senior Game Developer
- Klare Abschnitt-Trennung mit `# ── Name ──` Headern in langen Dateien
- Sprechende Funktionsnamen; lange Funktionen in benannte Sub-Funktionen aufteilen
- Keine Magic Numbers – alle Werte in benannten Konstanten
- **Godot 4 Best Practices**: statische Typisierung überall, Ressourcen in `.tscn` definieren (nicht im Code bauen), `_ready()` nur für Node-Setup
- **Signale** – Eigene Signale beginnen immer mit dem Präfix `sig_` zur besseren Unterscheidbarkeit (z.B. `sig_room_built`).
- **UI immer in .tscn** – keine `Node.new()`-UI-Bauten in Scripts; Scripts befüllen nur Daten und verbinden Signale. So bleibt die UI im Godot-Editor bearbeitbar.
- **Geteilte UI-Komponenten in `scenes/shared/`** – Jedes UI-Element das an mehr als einer Stelle vorkommt (Modals, Dialoge, gemeinsame Panels) wird als eigene `.tscn` + `.gd` unter `scenes/shared/` angelegt und per `instance=ExtResource(...)` eingebunden. Nie inline duplizieren. Beispiele: `ConfirmModal.tscn`, zukünftige Toast-Notifications, Info-Popups.
- Kommentare erklären das *Warum*, nicht das *Was*
- Keine Fehlerbehandlung für unmögliche Szenarien
- Keine ungenutzten Parameter ohne `_`-Prefix
- Keine Brücken um Fehler zu umgehen

## Projektstruktur
```
res://
├── autoload/       # Singletons: Api, GameState
├── scenes/         # Feature-basiert: main_menu/, login/, dashboard/, ingame/
├── assets/         # fonts/, images/
├── translations/   # language.csv + kompilierte .translation Dateien
├── wiki/           # aktuelle konzepte und grundlageen
└── _dev/           # Arbeitsdateien, Docs, nicht im Build
```

## Autoloads
- **`SaveManager`** – Zentrale Schnittstelle für lokales Speichern/Laden von Spielständen und Lesen der `/config` JSONs.
- **`GameState`** – User/Hotel-State, `T()` Translation-Helper.
- **`Api`** – (Zukünftig) für HTTP-Requests, Cookie-Persistenz (`user://session.cfg`).
- vor dem coden neuer dinge zuerst schauen ob es schon lösungen via autoload gibt

## Zukünftige API-Konventionen (aktuell ungenutzt)
- Login: `POST /api/auth/login` (Form-Data)
- Session-Check: `GET /api/auth/me`
- Hotels: `GET /api/hotels`, `POST /api/hotels`, `POST /api/hotel/delete`
- Auth via PHP-Session-Cookie

## Design
- **Farben**: Gold `#EAB308`, Dark Background `#0f172a`/`#141416`, Weiß `#fafafa`
- **Fonts**: Outfit-Bold (Headlines/Buttons), Inter Regular (Fließtext)
- **Style-Guide**: `wiki\06_ui_style_guide.md` – **verbindliche Referenz** für alle Modal-Panels, Buttons, Titel, Close-Button, Slot-Zeilen. Exakte Color-Werte und StyleBox-Definitionen dort nachschlagen, nicht aus dem Kopf schreiben.
- **Style-Guide pflegen**: Jede neue reusable UI-Komponente die als `.tscn` gebaut wird → Muster sofort im Style-Guide dokumentieren. Nur so bleibt Konsistenz über alle Szenen.

## Workflow
- **Issues vor der Umsetzung anlegen** – Linear-Issue (ANG-xxx) anlegen bevor mit der Implementierung begonnen wird
- ANG-xxx Referenz im Code (Kommentare), Commits und Changelog verwenden

- **WICHTIG: Kein Push ohne Test!** `git push` darf NUR ausgefuehrt werden, wenn der Code vorher erfolgreich durch Peter getestet wurde oder explizit das Go gegeben wurde.
- **Unfertige Features (Feature Flags):** Da wir primär linear auf dem `master`-Branch arbeiten, müssen unfertige neue Features stets über **Feature Flags** (Schalter im Code) oder versteckte UI-Elemente (`visible = false`) deaktiviert/verborgen werden. So bleibt der `master`-Branch jederzeit "deployable" (veröffentlichungsfähig), falls spontan ein kritischer Bugfix für die Live-Version eingeschoben werden muss. Diese Flags und Work-In-Progress-Stellen (WIP) müssen im Code sauber dokumentiert werden (z.B. `# TODO: WIP Feature - Remove Flag when done`).
## Temporäre Skripte & KI-Tools
- **Mülle das Root-Verzeichnis nicht zu!** Wenn du Python-Skripte oder andere temporäre Helfer-Skripte schreibst (z.B. für Batch-Ersetzungen in `.tscn` Dateien), speichere diese zwingend in einem separaten Arbeitsordner (z.B. im `_dev` Ordner oder einem neuen `_work` Ordner). Lege niemals `_temp*.py`, `fix_*.py` oder ähnliche Einweg-Skripte direkt in den Godot-Root-Ordner (`res://`).

## Linear Issue Access
- Zugriff auf Linear erfolgt zwingend �ber das Skript _dev/linear_cli.py in Verbindung mit dem API-Key aus secrets.cfg in der Root des Projekts. python _dev/linear_cli.py get ANG-xxx zeigt die Ticketdetails an.
