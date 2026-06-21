# HO·MA·SIM – Technologiebaum: Konzept & Design

---

## 1. Grundprinzip

Der Technologiebaum ist das zentrale Freischaltungssystem des Spiels. Er steuert, welche Raumtypen, Verbesserungen und Features dem Spieler zur Verfügung stehen. Wichtig:

- **Freischalten ≠ Bauen**: Eine Technologie zu erforschen bedeutet, dass man etwas *bauen darf* – Geld und Platz auf dem Grundstück werden trotzdem benötigt.
- **Sichtbarkeit**: Der gesamte Baum ist von Anfang an sichtbar. Noch nicht verfügbare Technologien sind ausgegraut. Per Tooltip sieht der Spieler, was er noch benötigt.
- **Strategische Entscheidungen**: Der Spieler investiert FP gezielt und baut seinen Fokus auf (z.B. Luxushotel vs. Konferenzzentrum vs. Wellness-Resort).

---

## 2. Zwei-Phasen-System

### Phase 1 – Vor dem Forschungsbüro
- Kein Technologiebaum, keine FP
- Rudimentäre Freischaltungen **nur nach Hotel-Level** (z.B. ab Level 3: Superior-Zimmer)
- Hält den Einstieg einfach – neuer Spieler wird nicht überwältigt
- Technologiebaum-UI ist noch nicht sichtbar

### Phase 2 – Nach dem Forschungsbüro
- Technologiebaum wird freigeschaltet und vollständig sichtbar
- FP-System startet bei **0** (kein rückwirkender Bonus)
- Level bleibt weiterhin als **zusätzliche Bedingung** für Technologien erhalten
- Passive FP-Rate aktiv, Aktionen generieren FP

### Voraussetzungen für das Forschungsbüro
| Bedingung | Beschreibung |
|---|---|
| Lobby/Rezeption | Automatisch beim Hotelbau vorhanden |
| Büro (Servicebereich) | Muss explizit gebaut werden (ANG-45) |

Das Büro ist der **physische Raum** – das Forschungsbüro ist die **Funktion**, die darin aktiviert wird.

---

## 3. Forschungspunkte (FP)

### Quellen (Kombination)
| Quelle | Beschreibung |
|---|---|
| ⏱️ Passiv / Zeit | Kleine Menge FP pro Spielstunde (Online-Zeit) |
| ✅ Aktionen | Check-in/Check-out, Zimmer bauen, Gäste zufriedenstellen |
| ⭐ Level-Up | Bonus-FP bei jedem Level-Aufstieg |
| 🏢 Verwaltungsbüro | Erhöht die passive FP-Rate als Multiplikator (je höher die Büro-Stufe, desto mehr) |

### FP im HUD
FP sind jederzeit sichtbar im HUD – ähnlich wie XP. Der Spieler sieht immer seinen aktuellen FP-Stand und wie nah er an der nächsten Freischaltung ist.

### Kosten-Staffelung pro Ast-Stufe
| Stufe | FP-Kosten |
|---|---|
| Stufe 1 | 100 FP |
| Stufe 2 | 250 FP |
| Stufe 3 | 500 FP |
| Stufe 4 | 1.000 FP |

Die Kosten sind im Backend konfigurierbar – für späteres Balancing ohne Code-Änderungen.

---

## 3. Freischaltungsbedingungen

Jede Technologie kann mehrere Bedingungen haben (alle müssen erfüllt sein):

- **FP-Kosten**: Pflicht für jede Technologie
- **Hotel-Level**: Mindest-Level des Spielers (z.B. Level 5)
- **Ast-Abhängigkeit**: Vorherige Technologie im selben Ast muss erforscht sein
- **Quer-Abhängigkeit**: Technologie aus einem anderen Ast als Voraussetzung (z.B. Gourmetrestaurant benötigt *Küche Stufe 3* UND *Gastronomie Stufe 2*)

Alle Bedingungen sind im Backend konfigurierbar (Datenbank-Tabelle), damit das Balancing nachträglich angepasst werden kann.

---

## 4. Die fünf Äste

### 🛏️ Ast 1: Zimmer & Unterbringung
Schaltet neue Zimmertypen und Ausstattungsoptionen frei.

| Stufe | Technologie | Freischaltet | Bedingung |
|---|---|---|---|
| 1 | Komfort-Grundlagen | Superior-Zimmer, Familienzimmer | Level 2 |
| 2 | Gehobene Unterbringung | Deluxe-Zimmer, Apartments | Level 5, Stufe 1 |
| 3 | Luxus-Standard | Suite, Themenzimmer | Level 10, Stufe 2 |
| 4 | Premium-Prestige | Penthouse-Suite (zukünftig) | Level 18, Stufe 3 |

---

### 🍽️ Ast 2: Gastronomie & Service
Schaltet Gastronomie-Räume und Küchen-Upgrades frei.

| Stufe | Technologie | Freischaltet | Bedingung |
|---|---|---|---|
| 1 | Basis-Gastronomie | Restaurant (Basis), Küche | Level 1 |
| 2 | Erweiterte Gastronomie | Bar/Lounge, Kühlraum, Lagerraum | Level 4, Stufe 1 |
| 3 | Gehobene Küche | Gourmetrestaurant, Wäscherei | Level 8, Stufe 2 |
| 4 | Kulinarische Exzellenz | Fine-Dining (zukünftig) | Level 14, Stufe 3 |

---

### 🧘 Ast 3: Wellness & Freizeit
Schaltet Freizeitbereiche und Wellness-Einrichtungen frei.

| Stufe | Technologie | Freischaltet | Bedingung |
|---|---|---|---|
| 1 | Aktiv & Fit | Fitnessstudio/Sportbereich | Level 5 |
| 2 | Außenbereich | Terrasse/Garten, Schwimmbad | Level 8, Stufe 1 |
| 3 | Wellness | Wellnessbereich/Spa, Spielzimmer/Kinderbereich | Level 12, Stufe 2 |
| 4 | Luxus-Wellness | Privat-Spa (zukünftig) | Level 18, Stufe 3 |

---

### 📋 Ast 4: Management & Betrieb
Schaltet Service-Räume, Büros und Effizienzverbesserungen frei.

| Stufe | Technologie | Freischaltet | Bedingung |
|---|---|---|---|
| 1 | Betriebsgrundlagen | Personalräume, Lobby-Verbesserung | Level 2 |
| 2 | Strukturiertes Management | Büros (Verwaltung), Parkplatz/Garage | Level 5, Stufe 1 |
| 3 | Prozessoptimierung | Automatisierungen, schnellerer Check-in/out | Level 10, Stufe 2 |
| 4 | Hotel-Konzern-Management | Mehrhotel-Verwaltung (zukünftig) | Level 20, Stufe 3 |

---

### 🎪 Ast 5: Prestige & Extras
Schaltet hochwertige Sonderbereiche mit großem Einnahmepotenzial frei.

| Stufe | Technologie | Freischaltet | Bedingung |
|---|---|---|---|
| 1 | Veranstaltungen | Konferenzräume/Tagungsräume | Level 6 |
| 2 | Großveranstaltungen | Veranstaltungsräume/Ballsaal, Geschäfte/Boutiquen | Level 10, Stufe 1 |
| 3 | Unterhaltung | Casino/Nachtclub | Level 15, Stufe 2 + Management Stufe 3 |
| 4 | Ikonisches Hotel | Dachterrassen-Bar (zukünftig) | Level 22, Stufe 3 |

---

## 5. Beispiel: Quer-Abhängigkeiten

```
Gourmetrestaurant bauen:
  ✅ Gastronomie Stufe 3 erforscht
  ✅ Küche (Raum) bereits gebaut
  ✅ Hotel-Level ≥ 8
  ✅ Genug Geld
  ✅ Freier Platz auf dem Grundstück

Casino bauen:
  ✅ Prestige Stufe 3 erforscht
  ✅ Management Stufe 3 erforscht (Quer-Abhängigkeit)
  ✅ Hotel-Level ≥ 15
  ✅ Genug Geld
  ✅ Freier Platz auf dem Grundstück
```

---

## 6. UI / Darstellung

- **Gesamter Baum sichtbar** von Anfang an
- **Ausgegraut** = noch nicht verfügbar (fehlende Bedingungen)
- **Hervorgehoben** = verfügbar und leistbar (FP vorhanden, Level OK)
- **Abgehakt** = bereits erforscht
- **Tooltip** bei jedem Knoten zeigt:
  - Beschreibung der Technologie
  - FP-Kosten
  - Alle Bedingungen mit ✅/❌ Status
  - Was die Technologie freischaltet
- **FP-Anzeige im HUD** neben XP/Level (immer sichtbar)

---

## 7. Datenbank-Struktur (Vorschlag)

```sql
-- Technologien
CREATE TABLE technologies (
  id INT PRIMARY KEY,
  key VARCHAR(50) UNIQUE,          -- z.B. 'gastronomie_3'
  name_de VARCHAR(100),
  description_de TEXT,
  branch VARCHAR(50),              -- 'zimmer' | 'gastronomie' | 'wellness' | 'management' | 'prestige'
  level INT,                       -- Stufe innerhalb des Astes (1-4)
  fp_cost INT,                     -- Forschungspunkte-Kosten
  min_hotel_level INT,             -- Mindest-Hotel-Level
  required_tech_id INT,            -- Vorherige Technologie im Ast (FK)
  cross_required_tech_id INT       -- Quer-Abhängigkeit (FK, nullable)
);

-- Freischaltungen pro Spieler
CREATE TABLE player_technologies (
  player_id INT,
  technology_id INT,
  unlocked_at DATETIME,
  PRIMARY KEY (player_id, technology_id)
);

-- Was eine Technologie freischaltet (n:m)
CREATE TABLE technology_unlocks (
  technology_id INT,
  room_type_key VARCHAR(50)        -- z.B. 'suite', 'casino', 'spa'
);
```

---

## 8. Offene Punkte / Nächste Schritte

- [ ] Technologiebaum-UI im Baumodus implementieren
- [ ] FP-System in Datenbank anlegen und in XP-System integrieren
- [ ] FP-HUD-Anzeige implementieren
- [ ] Verwaltungsbüro als FP-Multiplikator implementieren
- [ ] Raumtyp-Freischaltung im Baumodus an Technologie-Status knüpfen
- [ ] Alle Bedingungen konfigurierbar in DB hinterlegen (kein Hardcoding)
- [ ] Tooltip-System für Technobaum-UI

---

*Dokument erstellt: März 2026 | HO·MA·SIM Entwicklungsdokumentation*
