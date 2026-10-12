# HO·MA·SIM Godot – Agenten-Direktiven (gelten für ALLE Modelle/Agenten)

## 🚨 Anti-Halluzinations-Protokoll (NEU & ZWINGEND)
1. **Code-Verifizierung (Kein Spekulieren):** Bevor du behauptest, ein Feature, Raum oder eine Logik fehle, **MUSST** du per `grep_search` oder `list_dir` prüfen (z.B. in `scenes/ingame/rooms/`), ob es wirklich fehlt.
2. **Linear-Check:** Bevor du ein neues Ticket anlegst, **MUSST** du `python _dev/linear_cli.py list` ausführen, um Duplikate zu vermeiden.
3. **Status Quo lesen:** Vor weitreichenden Aussagen oder Feature-Vorschlägen immer den aktuellen Stand im Code prüfen oder `wiki/status_quo.md` konsultieren (sofern vorhanden).

---

## 📄 Encoding-Direktive (ZWINGEND – IMMER UTF-8!)
- **ALLE Dateien** in diesem Projekt sind **UTF-8**. Ohne Ausnahme.
- Python-Skripte die Dateien lesen/schreiben: **IMMER** `encoding='utf-8'` angeben. Niemals `cp1252`, `latin-1` oder kein Argument.
- Korrekt: `open('datei.md', 'w', encoding='utf-8')` | Falsch: `open('datei.md', 'w')` oder `encoding='cp1252'`
- Das PowerShell-Terminal gibt Zeichen als cp1252 aus – das ist **nur das Terminal**, nicht die Datei!
- Bei Problemen: `_work/fix_encoding.py` verwenden.

---


- **STRIKTE DIREKTIVE: Style Guide beachten!** Bevor du UI-Änderungen durchführst, zwingend `wiki/06_ui_style_guide.md` lesen.
- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. (Stattdessen `InnerPanel` oder transparent).
- **Design:** Farben: Gold `#EAB308`, Dark BG `#0f172a`/`#141416`, Weiß `#fafafa`. Fonts: Outfit-Bold (Titel/Buttons), Inter Regular (Text).
- **UI immer in .tscn**: Keine `Node.new()` UI-Bauten in Scripts. Geteilte UI-Komponenten (Modals etc.) immer als eigene `.tscn` in `scenes/shared/` ablegen.
- **Alle Texte via `GameState.T("key")`**: Nie Strings hardcoden. NEUE TEXTE, die erstellt werden, sind SOFORT in die language.csv (DE und EN) einzutragen. Feste Auflösung 1920×1080 (`layout_mode=0`).

---

## 🛠️ Workflow & Linear
- **Issues vor Umsetzung anlegen:** Linear-Issue via `python _dev/linear_cli.py create ...` anlegen (erst nach Check via `list`!).
- **ANG-xxx Referenz:** In Code (Kommentare), Commits und Changelog verwenden.
- **Kein Push ohne Test:** Code muss vorher von Peter getestet werden.
- **Alpha-Backlog (`wiki/alpha_backlog.md`):** Das ist die Bibel für den `dev`-Branch. Prio-Reihenfolge strikt einhalten. Keine Spekulationen ohne Absprache.
- **Verbindlicher Plan für den Alpha-Start (`wiki/alpha_grid_rework_plan.md`):** Vor jeder Arbeit am Nav-/Grid-/Slot-/Save-Thema **vollständig lesen** (v. a. Abschnitt 0). Alle Entscheidungen darin gelten als getroffen – nicht neu diskutieren, nicht eigenmächtig ändern. **Phasen erst nach ausdrücklichem Go von Peter beginnen**, keine Phasen überspringen. Bei Widerspruch zu `wiki/ang364_nav_rework.md` gilt der Plan.
- **Changelog:** Am Ende jeder Session Changelog erstellen (`changelog/gd-<version>.md`, z.B. `gd-0.3.1.md`). ZUERST `wiki/alpha_backlog.md` aktualisieren (erledigte Punkte abhaken/ergänzen), DANN Changelog committen.
- **Versions-Regel (ZWINGEND):** Eine Dev-Session = eine Version. Tagesstart: bestehende Version weiterführen. Tagesende: `/update_doku +v` ausführen → Patch-Version bumpen, Changelog abschließen. Niemals mehrere Tage/Sessions in derselben Version sammeln. Niemals mittendrin bumpen.
- **Dokumente ablegen:** Dateien, die versioniert werden sollen, **nie** in einen Ordner namens `_dev/` legen (steht in `.gitignore`, also auch `wiki/_dev/`). Pläne/Doku gehören nach `wiki/`.

---

## 🌿 Git-Branches & Versionsschema (seit 12.10.2026)
- **`dev`** = **Alpha-Linie**, Versionen **v0.3.0 und höher**. Hier wird entwickelt.
- **`prealpha`** = **Pre-Alpha-Linie**, Versionen **v0.2.x** (itch.io-Updates, nur Feedback-Fixes). Tag `v0.2.2-prealpha` = eingefrorener Stand.
- **`master`** = alter Stand, **nicht verwenden**.
- Vor jeder Arbeit `git branch --show-current` prüfen. Fixes für die Pre-Alpha zuerst auf `prealpha` (Version v0.2.3 usw.), danach `git merge prealpha` in `dev`.
- Feature-Arbeit am Grid-Rework läuft auf einem Feature-Branch (`alpha/grid-rework`), nicht direkt auf `dev` (siehe Plan).
- Auf `prealpha` bleibt `version.txt` bei `v0.2.x`, auf `dev` bei `v0.3.x+`. Nie Versionen zwischen den Linien vermischen.

---

## 💬 Kommunikation & Erklärbär-Modus
- **Du-Form**, entspannt aber zielorientiert. Kurze, prägnante Stichpunkte.
- **Einzelne Schritte:** Peter liest genau und versteht lieber Schritt für Schritt als zu viel auf einmal. Keine riesigen Code-Dumps ohne Vorwarnung.
- Bei jeder Umsetzung kurz erklären **was** gemacht wird und **warum**.
- **Ehrliche Meinung:** Leg Veto ein, wenn eine Idee aus Game-Design- oder Architektur-Sicht "Blödsinn" ist.

---

## 💻 Code- & Godot-Direktiven
- **Immer Godot 4 API** (Kein Godot 3 Syntax). Statische Typisierung überall.
- **VORSICHT BEI `get()`:** In Godot 4 nimmt `Object.get("property")` exakt **EIN** Argument. Die Form `get("key", default_value)` mit zwei Argumenten ist **NUR** bei Dictionaries (`Dictionary.get()`) erlaubt! Nutze bei Objekten direkte Property-Zugriffe (z.B. `party.event_poi_id`).
- **KISS & DRY:** Kein Over-Engineering. Keine God-Files. Wiederverwendbare Logik in eigene Autoloads/Klassen.
- **Sauberer Weg:** Code schreiben wie ein Senior Game Developer. Magic Numbers in Konstanten.
- **Signale:** Eigene Signale beginnen mit dem Präfix `sig_`.
- **Clean Code:** Debug-Prints (`[DEBUG]`) nach Test entfernen.
- **Temporäre Skripte:** Helfer-Skripte (z.B. Python) in `_dev` oder `_work` speichern. Root-Verzeichnis sauber halten!

---

## 🗂️ Architektur & Autoloads
- **`SaveManager`**: Speichern/Laden und JSONs aus `/config`.
- **`GameState`**: User-State, Unlocks (Level), Translation-Helper.
- **`Api`**: Zukünftiges PHP-Backend (aktuell lokal).
- Vor dem Coden prüfen, ob es schon Lösungen via Autoload gibt.

## Status Quo Direktive
- **STRIKTE REGEL für status_quo.md**: In das Status Quo Dokument kommen NIEMALS ToDos, unfertige Punkte oder '[ ]' Boxen. Es ist eine reine Inventar-Liste von Dingen, die bereits effektiv fertiggestellt und voll funktionsfähig sind.

## 🎨 Szenen-Änderungen (.tscn)
- **STRIKTE DIREKTIVE (visuell):** Visuelle Änderungen an .tscn-Dateien (Position, Größe, Layout, Abstände, Farben, Z-Order, Sprites) nur nach ausdrücklicher Freigabe. Wenn visuelle Änderungen nötig sind, definiere klar, was getan werden muss, und der User übernimmt die Anpassung im Godot-Editor. Grund: Visuelles muss "mit den Augen" beurteilt werden, rein mathematisch platzierte Elemente sahen in der Vergangenheit schlecht aus ("Kraut und Rüben").
- **Rein technische Änderungen sind erlaubt:** Skripte anhängen, Gruppen/Signale verbinden, Node-Typen oder technische Eigenschaften ändern, Node-Struktur ohne optische Wirkung (z.B. Footprint-/Nav-Nodes anlegen, NavBlocker ersetzen). Bei Unsicherheit, ob etwas technisch oder visuell ist: kurz nachfragen.

## Dokumentationspflicht nach Tests
Sobald eine Änderung (z.B. in GuestActor.gd oder anderen Kernsystemen) erfolgreich getestet und abgeschlossen ist, MUSS die zugehörige Techdoku im wiki/-Ordner aktualisiert werden. Existiert noch keine Doku für diesen Bereich, muss aktiv beim User nachgefragt werden, ob eine angelegt werden soll.
