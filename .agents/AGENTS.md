# UI Design Rules

**STRIKTE DIREKTIVE: Immer den Style Guide beachten!**
Bevor du UI-Ãnderungen durchfÃ¼hrst, musst du zwingend das Dokument `wiki/06_ui_style_guide.md` lesen und die dortigen Designvorgaben strikt einhalten.

- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. Das wirkt visuell zu unruhig ("too much"). FÃ¼r innere Detail-Panels oder TabellenkÃ¶pfe stattdessen das `InnerPanel`-Theme oder transparente/schlichte Container verwenden.

---

# Changelog-Workflow

**Am Ende jeder Session oder auf explizite Aufforderung** einen Changelog erstellen:

- Datei: `changelog/gd-0.1.XX.md` â Versionsnummer **immer aus `/version.txt` lesen** (nie raten, nie selbst erhÃ¶hen â es sei denn Peter sagt explizit âVersion erhÃ¶hen")
- Changelog-Nummer = aktuelle Version (z.B. `v0.1.28gd` â `gd-0.1.28.md`)
- Format: Abschnitte: `Features & Verbesserungen`, `Bugfixes`, `Technische Ãnderungen`
- **WICHTIG:** Ab sofort kurze, prÃ¤gnante Stichpunkte! Nicht zu detailliert, da der Changelog direkt als Upload-Notice bei itch.io verwendet wird.
- **Kein Abschnitt âOffene Backlog-Issues"** â der bleibt weg
- Datum im Format `YYYY-MM-DD` (tagesbezogen)
- Der Changelog dient als Grundlage fÃ¼r Social Media Posts und itch.io Updates â prÃ¤gnant, auf Deutsch, spielernah formulieren
- Nach dem Changelog: `git add -A; git commit -m "core: gd-0.1.XX changelog + session changes"`

---

# Allgemeine Regeln

- **Einzelne Schritte**: Peter liest genau und versteht lieber Schritt fÃ¼r Schritt als zu viel auf einmal.
- **Clean Code**: Debug-Prints (`[BAR_TEST]`, `[DEBUG]` etc.) nach erfolgreichem Test entfernen. Debug-Visualizer (Overlays, Linien) bleiben als Toggle erhalten, werden aber standardmÃ¤Ãig deaktiviert.
- **Keine Dopplungen**: Logik die an mehreren Stellen gebraucht wird zentral implementieren (z. B. `StaffManager.is_poi_staffed()`).


# HOÂ·MAÂ·SIM Godot â Claude Direktiven

## Projekt
Hotel-Management-Simulationsspiel. Godot 4.6 GDScript Desktop-Client.
Das Spiel arbeitet aktuell komplett lokal. Daten kommen aus Savegames (siehe `SaveManager` Autoload) und JSON-Dateien im Ordner `/config`. 
Ein PHP-Backend fÃ¼r Multiplayer/Leaderboards wird erst spÃ¤ter in der Zukunft angebunden.
Linear-Projekt: **Angelus2010 / ANG-** fÃ¼r alle Issues.

## Aktueller Stand (TechDemo)
- Die TechDemo ist fast fertig.
- **EXP-Balancing / Unlocks**: Wurden kÃ¼rzlich Ã¼berarbeitet. Core-Features haben harte Level-Voraussetzungen, die jetzt zentral in `GameState.UNLOCK_LEVELS` (Level 2 = Personal, Level 3 = Techtree) gesteuert werden.
- GÃ¤ste generieren EXP beim Check-In und Check-Out. Zimmer geben einen Erst-Bau-EXP-Bonus.
- Savegame & Load System wurde stark stabilisiert (Tween-Bugs gefixt).
  
## Kommunikation
- **Du**-Form, entspannt aber zielorientiert
- ausschliesslich in deutsch antworten
- Kleine Dinge direkt umsetzen (Typos, etc.)
- Sonst immer zuerst besprechen -> lÃ¶sen -> coden
- Kein Corporate-Sprech
- Peter liest genauer um zu verstehen â nicht zu viel auf einmal - einzelne Schritte

## ErklÃ¤rbÃ¤r-Modus (immer aktiv)
- Bei jeder Umsetzung kurz erklÃ¤ren **was** gemacht wird und **warum** â nicht erst auf Nachfrage
- Ziel: Peter soll den Code selbst verstehen und validieren kÃ¶nnen, nicht nur ausfÃ¼hren lassen
- ErklÃ¤rungen in einfacher Sprache, mit Analogien wenn hilfreich
- Nicht Ã¼berladen â ein kurzer Satz pro Konzept reicht oft
- **Ehrliche Meinung:** Sag Peter nicht einfach nach dem Mund. Wenn eine Idee aus Game-Design- oder Architektur-Sicht "BlÃ¶dsinn" ist oder Ã¼berladen wirkt, lege dein Veto ein und mach einen besseren Vorschlag.

## Godot-Direktiven
- **Immer Godot 4 API** â kein Godot 3 Syntax. Bei Unsicherheit Docs lesen, nicht halluzinieren.
- **Alle Texte via `GameState.T("key")`** â nie Strings hardcoden (auÃer als TODO-Platzhalter)
- **Feste AuflÃ¶sung 1920Ã1080** â kein Scaling, `layout_mode=0` fÃ¼r manuelle Positionierung
- **Kein `tr()` in static func** â stattdessen `TranslationServer.translate(key)`

## Code-Direktiven
- **Keine God-Files** â jede Datei hat eine einzige Verantwortlichkeit
- **KISS** â kein Over-Engineering, kein spekulatives Abstrahieren
- **DRY** â wiederverwendbare Logik in eigene Autoloads/Klassen
- **Lesbarer, sauberer Weg** â nicht den schnellen Weg gehen; Code so schreiben wie ein erfahrener Senior Game Developer
- Klare Abschnitt-Trennung mit `# ââ Name ââ` Headern in langen Dateien
- Sprechende Funktionsnamen; lange Funktionen in benannte Sub-Funktionen aufteilen
- Keine Magic Numbers â alle Werte in benannten Konstanten
- **Godot 4 Best Practices**: statische Typisierung Ã¼berall, Ressourcen in `.tscn` definieren (nicht im Code bauen), `_ready()` nur fÃ¼r Node-Setup
- **Signale** â Eigene Signale beginnen immer mit dem PrÃ¤fix `sig_` zur besseren Unterscheidbarkeit (z.B. `sig_room_built`).
- **UI immer in .tscn** â keine `Node.new()`-UI-Bauten in Scripts; Scripts befÃ¼llen nur Daten und verbinden Signale. So bleibt die UI im Godot-Editor bearbeitbar.
- **Geteilte UI-Komponenten in `scenes/shared/`** â Jedes UI-Element das an mehr als einer Stelle vorkommt (Modals, Dialoge, gemeinsame Panels) wird als eigene `.tscn` + `.gd` unter `scenes/shared/` angelegt und per `instance=ExtResource(...)` eingebunden. Nie inline duplizieren. Beispiele: `ConfirmModal.tscn`, zukÃ¼nftige Toast-Notifications, Info-Popups.
- Kommentare erklÃ¤ren das *Warum*, nicht das *Was*
- Keine Fehlerbehandlung fÃ¼r unmÃ¶gliche Szenarien
- Keine ungenutzten Parameter ohne `_`-Prefix
- Keine BrÃ¼cken um Fehler zu umgehen

## Projektstruktur
```
res://
âââ autoload/       # Singletons: Api, GameState
âââ scenes/         # Feature-basiert: main_menu/, login/, dashboard/, ingame/
âââ assets/         # fonts/, images/
âââ translations/   # language.csv + kompilierte .translation Dateien
âââ wiki/           # aktuelle konzepte und grundlageen
âââ _dev/           # Arbeitsdateien, Docs, nicht im Build
```

## Autoloads
- **`SaveManager`** â Zentrale Schnittstelle fÃ¼r lokales Speichern/Laden von SpielstÃ¤nden und Lesen der `/config` JSONs.
- **`GameState`** â User/Hotel-State, `T()` Translation-Helper.
- **`Api`** â (ZukÃ¼nftig) fÃ¼r HTTP-Requests, Cookie-Persistenz (`user://session.cfg`).
- vor dem coden neuer dinge zuerst schauen ob es schon lÃ¶sungen via autoload gibt

## ZukÃ¼nftige API-Konventionen (aktuell ungenutzt)
- Login: `POST /api/auth/login` (Form-Data)
- Session-Check: `GET /api/auth/me`
- Hotels: `GET /api/hotels`, `POST /api/hotels`, `POST /api/hotel/delete`
- Auth via PHP-Session-Cookie

## Design
- **Farben**: Gold `#EAB308`, Dark Background `#0f172a`/`#141416`, WeiÃ `#fafafa`
- **Fonts**: Outfit-Bold (Headlines/Buttons), Inter Regular (FlieÃtext)
- **Style-Guide**: `wiki\06_ui_style_guide.md` â **verbindliche Referenz** fÃ¼r alle Modal-Panels, Buttons, Titel, Close-Button, Slot-Zeilen. Exakte Color-Werte und StyleBox-Definitionen dort nachschlagen, nicht aus dem Kopf schreiben.
- **Style-Guide pflegen**: Jede neue reusable UI-Komponente die als `.tscn` gebaut wird â Muster sofort im Style-Guide dokumentieren. Nur so bleibt Konsistenz Ã¼ber alle Szenen.

## Workflow
- **Issues vor der Umsetzung anlegen** â Linear-Issue (ANG-xxx) anlegen bevor mit der Implementierung begonnen wird
- ANG-xxx Referenz im Code (Kommentare), Commits und Changelog verwenden

- **WICHTIG: Kein Push ohne Test!** `git push` darf NUR ausgefuehrt werden, wenn der Code vorher erfolgreich durch Peter getestet wurde oder explizit das Go gegeben wurde.
- **Unfertige Features (Feature Flags):** Da wir primÃ¤r linear auf dem `master`-Branch arbeiten, mÃ¼ssen unfertige neue Features stets Ã¼ber **Feature Flags** (Schalter im Code) oder versteckte UI-Elemente (`visible = false`) deaktiviert/verborgen werden. So bleibt der `master`-Branch jederzeit "deployable" (verÃ¶ffentlichungsfÃ¤hig), falls spontan ein kritischer Bugfix fÃ¼r die Live-Version eingeschoben werden muss. Diese Flags und Work-In-Progress-Stellen (WIP) mÃ¼ssen im Code sauber dokumentiert werden (z.B. `# TODO: WIP Feature - Remove Flag when done`).
## TemporÃ¤re Skripte & KI-Tools
- **MÃ¼lle das Root-Verzeichnis nicht zu!** Wenn du Python-Skripte oder andere temporÃ¤re Helfer-Skripte schreibst (z.B. fÃ¼r Batch-Ersetzungen in `.tscn` Dateien), speichere diese zwingend in einem separaten Arbeitsordner (z.B. im `_dev` Ordner oder einem neuen `_work` Ordner). Lege niemals `_temp*.py`, `fix_*.py` oder Ã¤hnliche Einweg-Skripte direkt in den Godot-Root-Ordner (`res://`).

## Linear Issue Access
- Zugriff auf Linear erfolgt zwingend über das Skript _dev/linear_cli.py in Verbindung mit dem API-Key aus secrets.cfg in der Root des Projekts. python _dev/linear_cli.py get ANG-xxx zeigt die Ticketdetails an.

---

## Alpha-Backlog (Prio-Direktive)

**Der Alpha-Backlog ist die verbindliche Entwicklungs-Bibel für den `dev`-Branch.**
Datei: `wiki/_dev/alpha_backlog.md` (Haupt-Referenz)

### Regeln:
- **Prio-Reihenfolge einhalten:** Phase 1 → 2 → 3 → 4 → 5. Nicht vorgreifen ohne Absprache.
- **Abweichungen erlaubt wenn:** Ein unerwarteter Bug oder eine technische Notwendigkeit es erfordert (z.B. TechDemo-Hotfix auf `master`).
- **Abweichungen dokumentieren:** Jede Abweichung vom Backlog (neue Idee, ungeplantes Feature) wird am Ende der Session in den Backlog eingetragen – entweder als neue Phase oder als Ergänzung einer bestehenden.
- **Kein spekulatives Bauen:** Nichts implementieren was nicht im Backlog steht oder explizit von Peter freigegeben wurde.
- **Getroffene Design-Entscheidungen** sind final und werden nicht erneut diskutiert (im Backlog markiert mit "Getroffene Design-Entscheidungen").

### Branching-Workflow (ab v0.1.40):
- `master` → nur TechDemo-Bugfixes. Nach jedem Fix: `git merge master` in `dev` ausführen.
- `dev` → alle Alpha-Features. Peter testet, dann Push.
- Tags: `v0.1.39-techdemo` = unveränderlicher TechDemo-Ankerpunkt.
