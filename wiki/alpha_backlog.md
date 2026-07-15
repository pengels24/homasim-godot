# HO·MA·SIM – Alpha Backlog & Roadmap
> Branch: `dev` | Start: v0.1.40 | Stand: 2026-07-15
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
**Status:** Muss neu gebaut werden.

- Level-Kurve von aktuell 5 auf 10 verlängern (`wiki/22_balancing_levelkurve.md` als Basis)
- EXP-Bedarf exponentiell weiterrechnen (ca. Faktor 1.5x pro Level)
- `UNLOCK_LEVELS` in `GameState.gd` für alle neuen Features vorbereiten
- Techtree: Tier-2-Gate (`req_level: 10, req_stars: 1`) bereits in `techtree.json` vorhanden – muss nur mit Content gefüllt werden
- **Abhängigkeit:** Alles andere (Techtree, Küche, Gourmetsterne) braucht definierte Level-Gates

### 1.2 Starteinstellung EXP-Boost
**Status:** Muss neu gebaut werden. Einfach.

- Im "Neues Hotel"-Dialog: Schwierigkeitsgrad wählbar
- **Casual:** +50% EXP | **Standard:** 100% | **Hard:** -25% EXP (ggf. weniger Startkapital)
- Multiplikator wird im Savegame gespeichert, beeinflusst alle EXP-Quellen global
- (`wiki/23_balancing_cash.md` enthält bereits Startkapital-Staffelung: 100k / 50k / 25k)

### 1.3 Mitarbeiter-Moralwerte aktivieren
**Status:** `morale`-Wert im Staff-Dict bereits vorhanden (`randi_range(80, 100)`), wird aber nirgends ausgewertet. Kein Neubau – nur Logik draufsetzen!

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
**Peter baut die Szenen im Editor.** Ich zeige den sauberen Workflow:
- Basis: Von `Room.tscn` **ableiten** (Inherit, nicht kopieren/Speichern unter!)
- Script: Eigenes `Kitchen.gd` / `Restaurant.gd` – nie das Eltern-Script ändern
- Nur eine Tür (Gäste-Eingang) – zweite Tür kommt mit Personalfluren (später)

**Pixel-Assets:** `kitchen_small.png` + `restaurant_small.png` bereits von Peter erstellt ✅

### 2.2 Ins Spiel integrieren
- `GuestDefinitions.gd`: Küche/Restaurant als erlaubte POIs für relevante Gäste eintragen
- `techtree.json`: `G1.2` (Küche) und `G1.3` (Restaurant) von `demo_locked: true` → `false`
- Level-Gate: Küche ab Level X, Restaurant ab Level Y (nach Phase 1 festlegen)
- Build-Menü: Icons + Einträge für beide Räume

### 2.3 Neue Jobs
Aus `wiki/02_features/06_personal_und_aufgabensystem.md` – bereits konzipiert:

| Job | Voraussetzung | Aufgabe |
|---|---|---|
| Küchenfachkraft | Küche gebaut (G1.2) | Produziert Gerichte |
| Küchenhilfe | Küche gebaut (G1.2) | Unterstützt Koch, erhöht Kapazität |
| Servicepersonal (Bedienung) | Restaurant gebaut (G1.3) | Nimmt Bestellungen auf, liefert Gerichte |

In `config/staff_roles.json` (oder Äquivalent) neue Einträge anlegen.

### 2.4 Küchen-Logik & Balancing
- **Bestell-Queue:** Gast betritt Restaurant → Bedienung nimmt Bestellung auf → Koch produziert → Bedienung liefert → Gast zahlt aus `spending_budget`
- **Kapazität:** 1 Koch = max. N gleichzeitige Bestellungen (N per Config, z.B. 3)
- **Wartezeit:** Zu lange Wartezeit → `satisfaction` sinkt
- **Einnahmen:** Eigene Income-Kategorie "Gastronomie" im Activity-Log
- **Balancing:** Küche muss sich ab X Gästen/Tag rentieren

---

## 🛋️ Phase 3 – Personal & Wohlbefinden (v0.1.44)
*Baut auf Moral-System aus Phase 1 auf.*

### 3.1 Personalraum (Staff Room)
**Konzept:** Aus `wiki/02_features/06_personal_und_aufgabensystem.md`

- Neuer Raumtyp: Mitarbeiter wechseln in `IDLE`-State → suchen nächsten freien Personalraum
- **Slot-System:** Jeder Personalraum hat 4 Plätze ("Take the next free place")
- Mitarbeiter im Personalraum: `morale` steigt pro Minute um X
- Balancing: Wie oft / wie lang geht jemand rein? (abhängig von morale-Schwellenwert)
- **Auswirkung auf 1.3:** `morale`-Anstieg durch Personalraum erst hier vollständig implementieren

### 3.2 Tiefere Gästewerte / Gästebedürfnisse
**Status:** `requirements`-Array in `GuestDefinitions.gd` **bereits vorhanden und befüllt!**

Bestehende Requirements (bereits im Code):
- `"wlan"` → Geschäftsreisender, Nomade
- `"desk"` → Geschäftsreisender  
- `"comfort"` → Paar
- `"space"`, `"pool"` → Familie
- `"luxury"`, `"privacy"` → Luxus-Gast

**Was gebaut werden muss:**
1. Zimmer-Typen bekommen `"provides": ["wlan", "desk"]`-Array in ihrer Config
2. Beim Check-in: Abgleich `requirements` ↔ `provides` → fehlende Requirements notieren
3. Täglich: Für jedes fehlende Requirement sinkt `satisfaction` um X Punkte
4. UI: Im Gäste-Dossier (Gästeliste-Modal) anzeigen was fehlt

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
| `M1.2` | Management | Personalentwicklung (Schulungsbonus) |
| `M1.3` | Management | Prozessoptimierung (Effizienz-Bonus) |
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
