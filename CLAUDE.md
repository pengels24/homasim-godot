# HO·MA·SIM Godot – Claude Direktiven

## Projekt
Hotel-Management-Simulationsspiel. Godot 4.6 GDScript Desktop-Client.
PHP-Backend unter `localhost:8848` bleibt API-Quelle (wird nicht angefasst).
Linear-Projekt: **Angelus2010 / ANG-** für alle Issues.

## Kommunikation
- **Du**-Form, entspannt aber zielorientiert
- Kleine Dinge direkt umsetzen, große Dinge zuerst besprechen
- Kein Corporate-Sprech
- Peter liest langsamer – nicht zu viel auf einmal

## Erklärbär-Modus (immer aktiv)
- Bei jeder Umsetzung kurz erklären **was** gemacht wird und **warum** – nicht erst auf Nachfrage
- Ziel: Peter soll den Code selbst verstehen und validieren können, nicht nur ausführen lassen
- Erklärungen in einfacher Sprache, mit Analogien wenn hilfreich
- Nicht überladen – ein kurzer Satz pro Konzept reicht oft
- Wenn dein Sohn (Webentwickler, Godot-Erfahrung) Fragen stellt: gerne einbeziehen und aus Webentwickler-Perspektive erklären

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
- **UI immer in .tscn** – keine `Node.new()`-UI-Bauten in Scripts; Scripts befüllen nur Daten und verbinden Signale. So bleibt die UI im Godot-Editor bearbeitbar.
- **Geteilte UI-Komponenten in `scenes/shared/`** – Jedes UI-Element das an mehr als einer Stelle vorkommt (Modals, Dialoge, gemeinsame Panels) wird als eigene `.tscn` + `.gd` unter `scenes/shared/` angelegt und per `instance=ExtResource(...)` eingebunden. Nie inline duplizieren. Beispiele: `ConfirmModal.tscn`, zukünftige Toast-Notifications, Info-Popups.
- Kommentare erklären das *Warum*, nicht das *Was*
- Keine Fehlerbehandlung für unmögliche Szenarien
- Keine ungenutzten Parameter ohne `_`-Prefix

## Projektstruktur
```
res://
├── autoload/       # Singletons: Api, GameState (SessionManager kommt noch)
├── scenes/         # Feature-basiert: main_menu/, login/, dashboard/, ingame/
├── assets/         # fonts/, images/
├── translations/   # de.csv + kompilierte .translation Dateien
└── _dev/           # Arbeitsdateien, Docs, nicht im Build
```

## Autoloads
- **`Api`** – alle HTTP-Requests, Cookie-Persistenz (`user://session.cfg`)
- **`GameState`** – User/Hotel-State, `T()` Translation-Helper, `check_session()`

## API-Konventionen
- Login: `POST /api/auth/login` (Form-Data)
- Session-Check: `GET /api/auth/me`
- Hotels: `GET /api/hotels`, `POST /api/hotels`, `POST /api/hotel/delete`
- Auth via PHP-Session-Cookie

## Design
- **Farben**: Gold `#EAB308`, Dark Background `#0f172a`/`#141416`, Weiß `#fafafa`
- **Fonts**: Outfit-Bold (Headlines/Buttons), Inter Regular (Fließtext)
- **Modals**: Dunkles Panel (0.95 Alpha), 12px Radius, Schlagschatten

## Button-Farbkonzept (verbindlich)
| Farbe | Bedeutung | Beispiele |
|-------|-----------|-----------|
| **Gold** `#EAB308` | Navigation / Menü | Hauptmenü, Spiel starten, Einstellungen |
| **Grün** `#16a34a` | Bestätigen / Speichern / Anlegen | Anlegen, Speichern, OK |
| **Rot** `#dc2626` | Abbrechen / Löschen / Zurück | Abbrechen, Löschen, Zurück |
| **Blau** `#2563eb` | Info / Details | Tooltip-Aktionen, Detail-Ansichten |

- Jeder Button-Typ hat normal/hover/disabled StyleBoxFlat (6px Radius)
- Hover = aufgehellte Variante der Grundfarbe
- Disabled = 35% Alpha

## Assets
- **Kenney – Roguelike Modern City** – `external-assets/roguelike-modern-city/` (gitignored)
  - 1036 Einzel-PNGs in `Tiles/` (tile_0000.png … tile_1035.png), Topdown 2D, Public Domain
  - **Primäre Grafik-Quelle für die Ingame-Szene** – Boden, Wände, Möbel, Straßen, Gebäude
  - Verwendete Tiles nach `res://assets/tiles/` kopieren (nur was wirklich benutzt wird)
  - Austauschbar durch eigene Grafiken – Kenney ist Platzhalter bis Custom-Art verfügbar

## Workflow
- **Issues vor der Umsetzung anlegen** – Linear-Issue (ANG-xxx) anlegen bevor mit der Implementierung begonnen wird
- ANG-xxx Referenz im Code (Kommentare), Commits und Changelog verwenden

## Session-Abschluss
`/update-doku` ausführen:
1. Changelog in `/changelog/gd-x-x-x.md` schreiben
2. Git commit + Tag
3. Linear Issues aktualisieren
4. Memory + CLAUDE.md updaten
5. Version in `version.txt` erhöhen (letzte Ziffer)
