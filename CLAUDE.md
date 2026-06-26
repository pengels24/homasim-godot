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
- **Nächste Schritte**: 
  1. Das POI-Cash-System final testen (Werte, Abrechnung, Kassenbuch, etc.) siehe /wiki/24_balancing_poi_cash.md
  2. Letztes UI-Refactoring: Die Rezeption (F3/Rezeption) prüfen und ggf. an das neue UI-System (InnerPanel, etc.) anpassen.
  
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
├── translations/   # de.csv + kompilierte .translation Dateien
├── wiki/           # aktuelle konzepte und grundlageen
└── _dev/           # Arbeitsdateien, Docs, nicht im Build
```

## Autoloads
- **`SaveManager`** – Zentrale Schnittstelle für lokales Speichern/Laden von Spielständen und Lesen der `/config` JSONs.
- **`GameState`** – User/Hotel-State, `T()` Translation-Helper.
- **`Api`** – (Zukünftig) für HTTP-Requests, Cookie-Persistenz (`user://session.cfg`).
- vo dem coden neuer dinge zuerst schauen ob es schon lösungen via autoload gibt

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

## Session-Abschluss
`/update-doku` ausführen:
1. Changelog in `/changelog/gd-x-x-x.md` schreiben
2. Git commit + Tag
3. Linear Issues aktualisieren
4. Memory + CLAUDE.md updaten
5. NUR WENN EXPLIZIT GENANNT - Version in `version.txt` erhöhen (letzte Ziffer)
