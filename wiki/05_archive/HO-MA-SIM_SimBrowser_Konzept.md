# HO·MA·SIM – .sim-Browser Konzept

*Planungsdokument für ANG-142 (In-Game Browser)*
*Erstellt: 12.04.2026*

---

## Grundidee

Der `.sim`-Browser ist ein simulierter Webbrowser im Spiel. Er öffnet sich als Modal und zeigt interne `.sim`-Webseiten – eine eigene fiktive Internetwelt innerhalb von HO·MA·SIM. Seiten werden schrittweise via Techtree freigeschaltet. Nicht freigeschaltete Seiten sind sichtbar aber gesperrt – der Spieler sieht was ihn erwartet.

**Doppelte Funktion:**
1. **Für den Spieler**: Informationsquelle, Buchungskanal, soziales Fenster zur Konkurrenz
2. **Für den Entwickler**: Einfach erweiterbar – neue Seiten = neuer Content ohne neue UI

---

## UI – Browser-Shell (Phase 1)

### Aufbau des Modals
```
┌─────────────────────────────────────────────────────────┐
│  ◀  ▶  🏠  │  🔒 hotelnews.sim          │  [×]        │
│─────────────────────────────────────────────────────────│
│  [home.sim] [booking.sim ×] [news.sim ×]                │  ← Tabs
│─────────────────────────────────────────────────────────│
│                                                         │
│                   Seiten-Inhalt                         │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### UI-Elemente
- **Adressleiste** – zeigt aktuelle `.sim`-URL, nicht editierbar in Phase 1
- **Zurück / Vor / Home** – Navigation zwischen besuchten Seiten
- **Tabs** – mehrere Seiten gleichzeitig offen (max. 5)
- **Schloss-Icon** – 🔒 gesperrt / ✅ freigeschaltet
- **Schließen-Button** – Modal schließen

### Öffnen des Browsers
- Button im HUD (kleines Browser-Icon, immer sichtbar ab Techtree-Freischaltung)
- Keyboard-Shortcut (TBD)
- Direktlink aus anderen Modals (z.B. Tagesabschluss → "Alle News lesen")

---

## home.sim – Startseite (Phase 1)

Die Startseite zeigt alle verfügbaren `.sim`-Seiten als Kacheln:

```
┌──────────────────────────────────────────────────────┐
│  🌐 home.sim – Dein .sim-Portal                      │
│──────────────────────────────────────────────────────│
│                                                      │
│  ✅ [📰 hotelnews.sim]    🔒 [🏨 hotelbooking.sim]  │
│     Branchen-News              Deine Buchungsseite   │
│     Jetzt lesen                Tier 2 erforderlich   │
│                                                      │
│  🔒 [⭐ michelin.sim]     🔒 [🚚 lieferanten.sim]   │
│     Michelin-Bewertungen       Lieferanten-Portal     │
│     Tier 3 erforderlich        Tier 3 erforderlich   │
│                                                      │
│  🔒 [🎰 events.sim]       🔒 [📊 markt.sim]         │
│     Event-Buchungen            Marktanalyse           │
│     Tier 4 erforderlich        Tier 4 erforderlich   │
│                                                      │
└──────────────────────────────────────────────────────┘
```

Gesperrte Kacheln zeigen:
- Seiten-Name + Icon
- Kurzbeschreibung was die Seite bietet
- Welcher Techtree-Unlock nötig ist
- Kein Klick möglich – Tooltip erklärt den Unlock-Pfad

---

## Phasen-Plan

### Phase 1 – Browser-Shell (sofort baubar, Devlog-Preview)
**Ziel:** Spielbare Hülle, sieht vollständig aus, macht im Devlog-Video Eindruck.

| Was | Details |
|---|---|
| Browser-Modal | UI-Shell mit Adressleiste, Tabs, Navigation |
| `home.sim` | Kachel-Übersicht aller Seiten (gesperrt/frei) |
| Alle anderen Seiten | "🔒 Inhalt noch nicht verfügbar" + Techtree-Hinweis |
| Öffnen-Button im HUD | Immer sichtbar ab Techtree-Start (Level 5) |

**Technisch:** Reines PHP-View + JS-Modal, keine DB-Abhängigkeiten. Neue Seiten = neue PHP-Partial.

---

### Phase 2 – Erste echte Inhalte (Tier 2, ~Level 10–15)

#### `hotelbooking.sim` – Eigene Buchungsseite (ANG-141)
- Spieler gestaltet seine eigene Hotelseite (.sim-Welt)
- Andere Spieler können dort buchen (Multiplayer)
- Inhalt: Hotelname, Beschreibung, Zimmertypen, Preise, Bewertungen
- Freigeschaltet durch: `M2.3 Online-Buchungssystem`

---

### Phase 3 – Multiplayer-News (Tier 3, ~Level 20–25)

#### `hotelnews.sim` – Globaler Newsfeed ⚠️ Multiplayer
- **Globaler Feed** – alle Spieler sehen die gleichen News
- Automatisch generierte Meldungen aus Spiel-Events:

| Event | Meldung |
|---|---|
| Spieler erhält ⭐ | *"[Hotel X] erhält ersten Michelin-Stern – Glückwunsch!"* |
| Spieler verliert ⭐⭐ | *"[Hotel Y] verliert zweiten Stern nach Qualitätsmängeln"* |
| Michelin-Runde angekündigt | *"Michelin-Inspektoren unterwegs – Branche in Alarmbereitschaft"* |
| Casino eröffnet | *"[Hotel Z] eröffnet erstes Casino der Region"* |
| Neues Hotel eröffnet | *"3 neue Hotels haben heute eröffnet"* |
| Marktbericht | *"Durchschnittliche Auslastung diese Woche: 74%"* |

- Freigeschaltet durch: `P3.3 Hotelwebseite (hotelbooking.sim)` + Tier 3

#### `michelin.sim` – Michelin-Portal
- Offizielle Stern-Vergaben und Aberkennnungen als formatierter Artikel
- Kriterien-Übersicht (was braucht man für welchen Stern)
- Eigener Stern-Status sichtbar
- Freigeschaltet durch: ⭐⭐ 2 Sterne erreicht

---

### Phase 4 – Vollausbau (Tier 4, ~Level 30–40)

#### `lieferanten.sim` – Lieferanten-Portal
- Verträge abschließen, Preise vergleichen, Qualitätsstufen wählen
- Verknüpft mit `M3.3 Lieferanten-System`

#### `events.sim` – Event-Buchungsplattform
- Externe Events buchen (Hochzeiten, Konferenzen, Gala-Abende)
- Verknüpft mit `P4.1 Gala-Event-System`

#### `markt.sim` – Marktanalyse
- Preisvergleich mit anderen Hotels (anonymisiert)
- Auslastungsstatistiken der Region
- Trend-Analyse (welche Gästetypen sind gerade besonders aktiv)

---

## Technische Umsetzung (Phase 1)

### Dateistruktur
```
src/Views/hotel/parts/
  modal_simbrowser.php       ← Browser-Modal-Shell
  simbrowser/
    home.php                 ← home.sim
    hotelbooking.php         ← hotelbooking.sim (Phase 2)
    hotelnews.php            ← hotelnews.sim (Phase 3)
    michelin.php             ← michelin.sim (Phase 3)
    lieferanten.php          ← lieferanten.sim (Phase 4)
    locked.php               ← Generische "gesperrt"-Seite
```

### JS-Modul
- `SimBrowserManager.js` – neues Modul (ANG-132-konform, nicht in grid.js)
- Verwaltet: aktive URL, Tab-History, Öffnen/Schließen
- Kommuniziert mit Server via AJAX für dynamische Inhalte (News, Buchungen)

### Routing
```
/ajax/simbrowser?page=home
/ajax/simbrowser?page=hotelnews
/ajax/simbrowser?page=hotelbooking
```

### Easter Eggs – Technisch
Easter Eggs werden in einer zentralen Konfigurationsdatei verwaltet – kein Hardcoding:

```php
// src/Config/SimBrowserEasterEggs.php
return [
  'google.sim'    => ['active' => true,  'view' => 'easter_google'],
  '42.sim'        => ['active' => true,  'view' => 'easter_42'],
  'peter.sim'     => ['active' => true,  'view' => 'easter_peter'],
  'anthropic.sim' => ['active' => true,  'view' => 'easter_anthropic'],
  'localhost.sim' => ['active' => true,  'view' => 'easter_localhost'],
  // active => false = deaktiviert, taucht wie normale 404.sim auf
];
```

Unbekannte URLs → generische `404.sim`: *"Diese Seite existiert nicht. Noch nicht."*

### Unlock-Check
Browser prüft beim Seitenaufruf ob der Spieler die nötige Tech erforscht hat → falls nicht: `locked.php` mit Hinweis. Kein Client-Side-Gate – immer Server-seitig prüfen.

---

## Devlog-Preview Strategie

Phase 1 ist bewusst als **vollständig wirkende Hülle** konzipiert:
- Alle Seiten-Kacheln auf `home.sim` sichtbar
- Gesperrte Seiten zeigen Vorschau-Text und Teaser
- Browser fühlt sich echt an (Tabs, Navigation, URL)
- Im Video: Browser öffnen → alle Seiten zeigen → "Das kommt alles noch"

**Botschaft an Zuschauer:** *Das Techtree-System schaltet echte Inhalte frei – dieser Browser wird mit dem Hotel wachsen.*

---

## Easter Eggs (Adressleiste editierbar)

Wenn die Adressleiste editierbar ist, können Spieler und Zuschauer URLs eintippen. Bekannte URLs führen zu Gag-Seiten:

| URL | Reaktion |
|---|---|
| `google.sim` | *"Hier gibt es keine Suchergebnisse. Du bist in der .sim-Welt – hier zählt nur dein Hotel."* |
| `facebook.sim` | *"Soziale Netzwerke? Deine Gäste warten. Und dein Ruf auch."* |
| `42.sim` | *"Die Antwort auf alles – leider hilft sie nicht beim Check-in."* |
| `cheats.sim` | *"Wirklich? … Nein."* |
| `money.sim` | *"Hier wächst kein Geld auf Bäumen. Bau mehr Suiten."* |
| `hilfe.sim` / `help.sim` | Echte Hilfeseite – Shortcuts, FAQ, Tipps |
| `about.sim` | Credits-Seite – Entwickler, Version, ein bisschen Humor |
| `peter.sim` | 🥚 Geheime Entwickler-Seite – persönliche Note, Devlog-Link |
| `hotel.sim` | Redirect auf die eigene `hotelbooking.sim`-Seite |
| `casino.sim` | *"Noch nicht verfügbar… oder doch? Forsche weiter."* (blinkt kurz) |
| `localhost.sim` | *"Du weißt zu viel."* |
| `anthropic.sim` | *"Diese Seite wurde mitgeplant von einer KI. Hallo."* 🤖 |

**Devlog-Tipp:** Im Video die Adressleiste "versehentlich" mit einer Easter-Egg-URL befüllen → Community entdeckt es und sucht nach weiteren. Perfekte Engagement-Falle.

---

## Offene Punkte

- [x] Browser-Icon für HUD → **`globe`** (Lucide)
- [x] Adressleiste editierbar → **Ja.** Easter Eggs via `SimBrowserEasterEggs.php` konfiguriert.
- [x] Design → **Modernes Look & Feel**, passend zum bestehenden Spiel-UI. Keine Retro-Schriftart.
- [x] Push-Notification → **Ja.** HUD-Badge am `globe`-Icon wie Rezeptionsindikator: 🟢 alles gelesen / 🔴 neue ungelesene News. Selbes UX-Muster, keine neue Mechanik.
- [x] `home.sim` anpassbar → **Phase 1: fix/statisch.** Anpassbarkeit (Widgets, Favoriten) für spätere Phase vorgemerkt – Struktur beim Bau so anlegen dass es erweiterbar bleibt.

---

*Dieses Dokument beschreibt Konzept und Implementierungsplan. Phase 1 ist ohne weitere Abhängigkeiten sofort umsetzbar.*
