# HO·MA·SIM Godot – Claude Direktiven

## 🚨 Anti-Halluzinations-Protokoll (NEU & ZWINGEND)
1. **Code-Verifizierung (Kein Spekulieren):** Bevor du behauptest, ein Feature, Raum oder eine Logik fehle, **MUSST** du per `grep_search` oder `list_dir` prüfen (z.B. in `scenes/ingame/rooms/`), ob es wirklich fehlt.
2. **Linear-Check:** Bevor du ein neues Ticket anlegst, **MUSST** du `python _dev/linear_cli.py list` ausführen, um Duplikate zu vermeiden.
3. **Status Quo lesen:** Vor weitreichenden Aussagen oder Feature-Vorschlägen immer den aktuellen Stand im Code prüfen oder `wiki/status_quo.md` konsultieren (sofern vorhanden).

---

## 🎨 UI & Design Rules
- **STRIKTE DIREKTIVE: Style Guide beachten!** Bevor du UI-Änderungen durchführst, zwingend `wiki/06_ui_style_guide.md` lesen.
- **Panel Nesting**: Niemals ein "Glow-Panel" (`ModalPanel`) innerhalb eines anderen Glow-Panels verwenden. (Stattdessen `InnerPanel` oder transparent).
- **Design:** Farben: Gold `#EAB308`, Dark BG `#0f172a`/`#141416`, Weiß `#fafafa`. Fonts: Outfit-Bold (Titel/Buttons), Inter Regular (Text).
- **UI immer in .tscn**: Keine `Node.new()` UI-Bauten in Scripts. Geteilte UI-Komponenten (Modals etc.) immer als eigene `.tscn` in `scenes/shared/` ablegen.
- **Alle Texte via `GameState.T("key")`**: Nie Strings hardcoden. Feste Auflösung 1920×1080 (`layout_mode=0`).

---

## 🛠️ Workflow & Linear
- **Issues vor Umsetzung anlegen:** Linear-Issue via `python _dev/linear_cli.py create ...` anlegen (erst nach Check via `list`!).
- **ANG-xxx Referenz:** In Code (Kommentare), Commits und Changelog verwenden.
- **Kein Push ohne Test:** Code muss vorher von Peter getestet werden.
- **Alpha-Backlog (`wiki/_dev/alpha_backlog.md`):** Das ist die Bibel für den `dev`-Branch. Prio-Reihenfolge strikt einhalten. Keine Spekulationen ohne Absprache.
- **Changelog:** Am Ende jeder Session Changelog erstellen (`changelog/gd-0.1.XX.md`). ZUERST `alpha_backlog.md` aktualisieren (erledigte Punkte abhaken/ergänzen), DANN Changelog committen.

---

## 💬 Kommunikation & Erklärbär-Modus
- **Du-Form**, entspannt aber zielorientiert. Kurze, prägnante Stichpunkte.
- **Einzelne Schritte:** Peter liest genau und versteht lieber Schritt für Schritt als zu viel auf einmal. Keine riesigen Code-Dumps ohne Vorwarnung.
- Bei jeder Umsetzung kurz erklären **was** gemacht wird und **warum**.
- **Ehrliche Meinung:** Leg Veto ein, wenn eine Idee aus Game-Design- oder Architektur-Sicht "Blödsinn" ist.

---

## 💻 Code- & Godot-Direktiven
- **Immer Godot 4 API** (Kein Godot 3 Syntax). Statische Typisierung überall.
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
- **STRIKTE REGEL f�r status_quo.md**: In das Status Quo Dokument kommen NIEMALS ToDos, unfertige Punkte oder '[ ]' Boxen. Es ist eine reine Inventar-Liste von Dingen, die bereits effektiv fertiggestellt und voll funktionsf�hig sind.

## 🎨 Szenen-Änderungen (.tscn)
- **STRIKTE DIREKTIVE:** Keine direkten scriptseitigen Änderungen am visuellen Aufbau von .tscn-Dateien (z.B. Nodes hinzufügen, verschieben, Eigenschaften ändern) ohne ausdrückliche Freigabe. Wenn visuelle Änderungen nötig sind, definiere klar, was getan werden muss, und der User übernimmt die Anpassung im Godot-Editor. Dies verhindert "Kraut und Rüben" im Design.

## Dokumentationspflicht nach Tests
Sobald eine �nderung (z.B. in GuestActor.gd oder anderen Kernsystemen) erfolgreich getestet und abgeschlossen ist, MUSS die zugeh�rige Techdoku im wiki/-Ordner aktualisiert werden. Existiert noch keine Doku f�r diesen Bereich, muss aktiv beim User nachgefragt werden, ob eine angelegt werden soll.
