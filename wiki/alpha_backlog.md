# HO·MA·SIM – Alpha Backlog & Roadmap
> Branch: `dev` | Start: v0.1.40 | Aktuell: v0.1.43 | Stand: 2026-07-27
> Bibel für die Alpha-Phase. Vor jeder Umsetzung hier nachschlagen!

---

## ⚠️ Getroffene Design-Entscheidungen (nicht mehr diskutieren!)

- **Personalflure:** Kommen NICHT in die Alpha. Grund: würde auf altem 1-Layer-Nav aufbauen → Brückencode. Kommen zusammen mit dem Nav-Rework (3 Layer: Gäste / Personal / Rauminneres + feineres Grid).
- **Küche/Restaurant Alpha:** Nur eine Tür (Gäste-Eingang). Zweite Tür (Personaleingang) kommt mit Personalflur-Feature.
- **Branching:** `master` = TechDemo-Bugfixes. `dev` = Alpha-Entwicklung. Nach TechDemo-Fix immer kurz `git merge master` in `dev`.

---

## 🧱 Phase 1 – Fundament (v0.1.40–41)
*Zuerst, weil alles andere darauf aufbaut.*

### 1.1 Max-Level auf 10 + Balancing
**Status:** ✅ Erledigt (Max-Level ist 15, `get_xp_needed_for_level` ist bis Lvl 10 exponentiell ausgebaut, `UNLOCK_LEVELS` aktiv).

- Level-Kurve von aktuell 5 auf 10 verlängern (`wiki/22_balancing_levelkurve.md` als Basis)
- EXP-Bedarf exponentiell weiterrechnen (ca. Faktor 1.5x pro Level)
- `UNLOCK_LEVELS` in `GameState.gd` für alle neuen Features vorbereiten
- Techtree: Tier-2-Gate (`req_level: 10, req_stars: 1`) bereits in `techtree.json` vorhanden – muss nur mit Content gefüllt werden
- **Abhängigkeit:** Alles andere (Techtree, Küche, Gourmetsterne) braucht definierte Level-Gates

### 1.2 Starteinstellung EXP-Boost
**Status:** ✅ Erledigt (`NewHotelModal` hat Schwierigkeitsgrade und übermittelt Multiplikatoren für EXP, Geld und Rückerstattung an Savegame).

- Im "Neues Hotel"-Dialog: Schwierigkeitsgrad wählbar
- **Casual:** +50% EXP | **Standard:** 100% | **Hard:** -25% EXP (ggf. weniger Startkapital)
- Multiplikator wird im Savegame gespeichert, beeinflusst alle EXP-Quellen global
- (`wiki/23_balancing_cash.md` enthält bereits Startkapital-Staffelung: 100k / 50k / 25k)

### 1.3 Mitarbeiter-Moralwerte aktivieren
**Status:** ✅ Erledigt (`StaffManager._process_morale` triggert jeden Mitternacht; `StaffActor.gd` rechnet bis zu 30% Strafe auf Arbeitszeit bei Moral < 50; Kündigung bei Moral <= 0).

Konzept aus `wiki/02_features/06_personal_und_aufgabensystem.md`:
- **`morale`** (0–100): Beeinflusst Arbeitsgeschwindigkeit und Fehlerrate
- **Auswirkungen:** `morale < 20` → Mitarbeiterkündigt; `morale < 50` → Arbeitsgeschwindigkeit –30%
- **Morale sinkt durch:** Überstunden / zu viele Tasks ohne Pause
- **Morale steigt durch:** Personalraum-Besuch (+5 Basis), Schulungen, regelmäßiges Gehalt
- Anzeige im Staff-Modal (Balken oder Wert)
- **Hinweis:** Personalraum-Logik (was morale.raise auslöst) kommt in Phase 3

---

## 🍳 Phase 2 – Küche & Restaurant (v0.1.42–43)
*Größtes Feature-Paket. Braucht Phase 1 (Level-Gates definiert).*

### 2.1 Szenen bauen (Workflow)
**Status:** ✅ Erledigt. `RestaurantSmall` und `KitchenSmall` sind gebaut und im Spiel. Pixel-Assets integriert.

### 2.2 Ins Spiel integrieren
**Status:** ✅ Erledigt. Erlaubte POIs eingetragen, Techtree integriert.

### 2.3 Neue Jobs
**Status:** ✅ Erledigt. Koch und Bedienung sind definiert und funktionieren im Gastronomie-Ablauf.

### 2.4 Küchen-Logik & Balancing
**Status:** ✅ Erledigt. Bestell-Queue, Köche und Bedienungen arbeiten zusammen. Gäste erhalten Essen und zahlen. Income-Kategorie "Gastro" ist im Code verankert.

---

## 🛋️ Phase 3 – Personal & Wohlbefinden (v0.1.44)
*Baut auf Moral-System aus Phase 1 auf.*

### 3.1 Personalraum (Staff Room)
**Status:** ✅ Erledigt (Szene existiert, Mitarbeiter nutzen Stühle, Tooltips und Zuweisungen funktionieren).

**Konzept:** Aus `wiki/02_features/06_personal_und_aufgabensystem.md`

- Neuer Raumtyp: Mitarbeiter wechseln in `IDLE`-State → suchen nächsten freien Personalraum
- **Slot-System:** Jeder Personalraum hat 4 Plätze ("Take the next free place")
- Mitarbeiter im Personalraum: `morale` steigt pro Minute um X
- Balancing: Wie oft / wie lang geht jemand rein? (abhängig von morale-Schwellenwert)
- **Auswirkung auf 1.3:** `morale`-Anstieg durch Personalraum erst hier vollständig implementieren

### 3.2 Tiefere Gästewerte / Gästebedürfnisse
**Status:** ✅ Erledigt (Check-In prüft Raum-Traits, UI Tooltip zeigt rot/grün Status, täglicher Zufriedenheits-Abzug greift).

Zimmer-Typen bekommen Eigenschaften (z.B. `"wlan"`, `"desk"`). Wenn Gäste einchecken, wird abgeglichen, ob das Zimmer ihre Anforderungen erfüllt. Fehlt etwas (z.B. WLAN für den Geschäftsreisenden), sinkt die Zufriedenheit und wir zeigen das im UI an. Die Basisdaten dafür (z.B. `"wlan"` beim Geschäftsreisenden) existieren bereits im Code.

**Ungeplante Fixes der Session:**
- ✅ **GuestActor Wegfindung:** Bug behoben, durch den Gäste beim Verlassen des Zimmers geradewegs durch Wände liefen (Status-Machine Bug mit `previous_state` behoben).
- ✅ **CustomTooltip:** Position wird nun auf den Viewport geclempt, sodass der Tooltip nicht mehr oben aus dem Bild rutscht.

---

## 🌳 Phase 4 – Techtree mit Leben füllen (v0.1.45)

### 4.1 Bestehende Nodes mit Inhalt versehen

Aktuell gesperrte Nodes ohne Inhalt:

| ID | Kategorie | Geplanter Inhalt |
|---|---|---|
| `G1.4` | Gastronomie | Gourmetküche (Vorstufe Gourmetsterne) |
| `W1.1` | Wellness | Spa / Massage |
| `W1.2` | Wellness | Pool / Außenbereich |
| `W1.3` | Wellness | Wellness-Paket (Kombination) |
| ~~`M1.2`~~ | ~~Management~~ | ~~Personalentwicklung (Schulungsbonus)~~ ✅ Erledigt |
| ~~`M1.3`~~ | ~~Management~~ | ~~Prozessoptimierung (Effizienz-Bonus)~~ ✅ Erledigt |
| `M1.4` | Management | Hotelleitung (Globaler Effizienz-Bonus) |
| `P1.1` | Prestige | Events (Konzerte, Messen etc.) |
| `P1.2` | Prestige | Veranstaltungszentrum |
| `P1.3` | Prestige | Prestige-Paket |
| Tier 2 | Alle | Req: Level 10 + 1 Stern – Tier-2-Nodes definieren |

- Für jeden Node: Was genau schaltet er frei? Raum? Feature? Bonus?
- Translation-Keys für alle Namen in `language.csv` nachtragen
- Level-Gates pro Node sauber definieren

---

## ⭐ Phase 5 – Events & Prestige (v0.1.46–47)

### 5.1 Zufallsereignisse
- Event-System: Zufällige Ereignisse nach Zeit/Wahrscheinlichkeit
- Beispiele: Rohrbruch, TV-Ausfall, Stromausfall, Schädlingsbefall
- Jedes Event: Dauer + Reparaturkosten + Impact auf `satisfaction` betroffener Gäste
- Benachrichtigung: Toast + Activity-Log-Eintrag + Raum-Indikator
- Spieler-Reaktion: Haustechnik schicken oder selbst bestätigen

### 5.2 Gourmetsterne
- Voraussetzung: `G1.4` (Gourmetküche) erforscht
- Bewertungs-Logik: Restaurant-Qualität (Küchen-Skills) + Ø Gästezufriedenheit über Zeit → 0–3 Sterne
- **Inspektor-Event:** Seltenes Zufallsevent (1x pro ~30 Tage). Inspektor besucht → bewertet anonym → Toast mit Ergebnis
- Sterne geben Boni: +Reputation, +Einnahmen-Multiplikator Restaurant, neue Gästetypen

---

## 📊 Abhängigkeits-Übersicht (Schnellreferenz)

```
Phase 1: Fundament
├── 1.1 Max-Level 10          ← ZUERST (Level-Gates für alles andere)
├── 1.2 EXP-Boost Starteinstellung
└── 1.3 Morale aktivieren     ← Basis für Phase 3

Phase 2: Küche & Restaurant   ← Braucht 1.1 (Level-Gates)
├── 2.1 Szenen (Peter + Workflow)
├── 2.2 Integration + Techtree G1.2/G1.3 entsperren
├── 2.3 Neue Jobs
└── 2.4 Küchen-Logik

Phase 3: Personal & Gäste     ← Braucht 1.3 (Morale-System)
├── 3.1 Personalraum           ← Braucht 1.3 (Morale-Raise-Logik)
└── 3.2 Gästebedürfnisse       ← Requirements-Array bereits vorhanden!

Phase 4: Techtree-Content      ← Braucht 2.x (Räume müssen existieren)
└── 4.1 Alle demo_locked Nodes mit Inhalt

Phase 5: Events & Prestige     ← Braucht 4.1 (G1.4 Gourmetküche)
├── 5.1 Zufallsereignisse
└── 5.2 Gourmetsterne + Inspektor
```

---

## 🔮 Spätere Features (nach Alpha / Beta)

- **Savegames - Actor-State-Serialisierung (ANG-314):** Beim Laden eines Spielstands exakte Positionen, Pathfinding und Timer (Gäste & Staff), offene Putz-Tasks und Gastro-Bestellungen wiederherstellen, um Immersion-Breaks zu verhindern. Erst implementieren, wenn alle State-Machines feature-complete sind.
- **Rework: New Game UI (Erweiterte Spieleinstellungen / Seite 2):** Vergrößerung des Fensters (ggf. mit Tabs oder 2. Seite) um feinere Anpassungen von Startkapital, Mitarbeiter-Schwellenwerten (Pausenverhalten) und anderen Startbedingungen zu ermöglichen.
- **Personalflure:** Kommt mit Nav-Rework (3 Ebenen: Gäste / Personal / Rauminneres + feineres Grid)
- **Begehbare Räume:** Abhängig von Nav-Rework
- **Zoning:** Mitarbeiter-Zonen auf der Karte (im Wiki skizziert)
- **Sicherheitszentrale:** PiP-Kamera recyceln als Überwachungssystem (ab Level 20, Wiki-Konzept vorhanden)
- **Connecting Rooms:** Zimmer mit Verbindungstür (Familie-Segment)
- **Krankheits-System:** Mitarbeiter werden krank (Wiki-Konzept vorhanden)

---

## 📁 Relevante Dateien (Schnellreferenz)

| Was | Datei |
|---|---|
| Gäste-Typen & Requirements | `data/GuestDefinitions.gd` |
| Mitarbeiter-Dict (morale) | `autoload/StaffManager.gd` |
| Gäste-Werte (satisfaction, patience) | `scenes/ingame/guest/GuestParty.gd` |
| Techtree-Struktur | `config/techtree.json` |
| Level-Kurve Konzept | `wiki/22_balancing_levelkurve.md` |
| Cash-Balancing Konzept | `wiki/23_balancing_cash.md` |
| Personal-System Konzept | `wiki/02_features/06_personal_und_aufgabensystem.md` |
| Techtree-Architektur Konzept | `wiki/02_features/01_architektur_techtree_und_fp.md` |
| Raumtypen-Referenz | `wiki/02_features/22_raumtypen_referenz.md` |
