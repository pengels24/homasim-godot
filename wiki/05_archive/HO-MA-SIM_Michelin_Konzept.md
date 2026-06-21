# HO·MA·SIM – Michelin-Konzept als Tier-System

*Planungsdokument für das Techtree-Redesign (ANG-105/106)*
*Erstellt: 12.04.2026*

---

## Realität: Michelin Key & Michelin Star

Michelin bewertet Hotels seit 2024 mit **Michelin Keys** (1–3) – unabhängig von den Restaurant-Sternen.

### Michelin Key – Die 5 offiziellen Kriterien (Hotels)
1. **Architektur & Innendesign** – Qualität und Stimmigkeit der Einrichtung
2. **Service-Qualität & Konsistenz** – Geht spürbar über den Standard hinaus
3. **Persönlichkeit & Charakter** – Das Hotel hat eine eigene Identität
4. **Preis-Leistung** – Nicht zwingend günstig, aber fair
5. **Gasterlebnis** – Bleibendes Erlebnis in der jeweiligen Umgebung

### Michelin Star – Die 5 offiziellen Kriterien (Gastronomie)
1. **Qualität der Zutaten** – Frische, Herkunft, Selektion
2. **Beherrschung der Kochtechniken** – Präzision und Können
3. **Harmonie der Aromen** – Stimmiges Gesamterlebnis
4. **Persönlichkeit der Küche** – Unverwechselbarer Stil
5. **Konsistenz** – Gleiche Qualität bei jedem Besuch, jeder Saison

**Wichtig:** Michelin bewertet Sterne *nur* an der Küche – Service, Dekoration und Atmosphäre fließen *nicht* in die Stern-Entscheidung ein (wohl aber in die Keys).

---

## Für HO·MA·SIM: Adaption als Tier-Gate-System

Michelin-Sterne dienen im Spiel als **Fortschritts-Gate** zwischen Techtree-Tiers.
Sie sind *keine* Dekoration – sie sind Voraussetzung für den Zugang zu höheren Forschungsstufen.

### Die 3 Sterne-Stufen

| Stern | Bedeutung (Real) | Bedeutung im Spiel |
|---|---|---|
| ⭐ 1 Stern | „Eine sehr gute Küche" | Solider Hotelbetrieb mit durchgehend zufriedenen Gästen |
| ⭐⭐ 2 Sterne | „Hervorragende Küche, einen Umweg wert" | Etabliertes Hotel mit Persönlichkeit und gutem Ruf |
| ⭐⭐⭐ 3 Sterne | „Außergewöhnliche Küche, eine Reise wert" | Prestige-Hotel auf höchstem Niveau |

---

## Michelin-Kriterien → Spiel-Metriken

### ⭐ 1. Stern – Grundvoraussetzungen

Orientiert an: *Konsistenz + Basis-Qualität*

| Kriterium | Spiel-Metrik | Schwellenwert (Vorschlag) |
|---|---|---|
| Service-Qualität | Ø Gäste-Satisfaction (letzte 30 Gäste) | ≥ 70% |
| Konsistenz | Kein Checkout unter X% Satisfaction | ≥ 50% |
| Sauberkeit | Ø cleanliness aller Zimmer | ≥ 75% |
| Grundausstattung | Pflicht-Raumtypen vorhanden | Lobby, mind. 1 WC, mind. 10 Zimmer |
| Ruf | Reputation-Score | ≥ 500 |

### ⭐⭐ 2. Sterne – Qualität & Persönlichkeit

Orientiert an: *Persönlichkeit + Preis-Leistung + Gasterlebnis*

| Kriterium | Spiel-Metrik | Schwellenwert (Vorschlag) |
|---|---|---|
| Höhere Zufriedenheit | Ø Satisfaction (letzte 50 Gäste) | ≥ 80% |
| Gastronomie | Restaurant vorhanden und aktiv | ✅ |
| Zimmervielfalt | Mind. 3 verschiedene Zimmertypen | ✅ |
| Personal | Mind. 1 Servicekraft (Housekeeping) + 1 Haustechnik | ✅ |
| Ruf | Reputation-Score | ≥ 1.500 |
| Condition | Ø condition aller Zimmer | ≥ 80% |

### ⭐⭐⭐ 3. Sterne – Außergewöhnlich

Orientiert an: *Unverwechselbarkeit + Exzellenz auf allen Ebenen*

| Kriterium | Spiel-Metrik | Schwellenwert (Vorschlag) |
|---|---|---|
| Spitzen-Zufriedenheit | Ø Satisfaction (letzte 100 Gäste) | ≥ 90% |
| Luxus-Gastronomie | Gourmetrestaurant oder Bar/Lounge | ✅ |
| Luxus-Zimmer | Mind. Suite oder Deluxe-Zimmer | ✅ |
| Vollständiges Personal | Mind. 2 Servicekräfte, 1 Haustechnik, 1 Rezeptionsfachkraft, 1 Concierge | ✅ |
| Wellness | Mind. 1 Wellness-/Freizeitbereich | ✅ |
| Ruf | Reputation-Score | ≥ 5.000 |
| Konsistenz | X Tage ohne Satisfaction-Einbruch | TBD |

---

## Verknüpfung mit dem Techtree

```
Forschungsbüro gebaut
        │
        ▼
  [Tier 1 – alle Kategorien verfügbar]
        │
  mind. X Items in Tier 1 + ⭐ 1. Stern
        │
        ▼
  [Tier 2 – alle Kategorien]
        │
  mind. X Items in Tier 2 + ⭐⭐ 2. Sterne
        │
        ▼
  [Tier 3 – alle Kategorien]
        │
  mind. X Items in Tier 3 + ⭐⭐⭐ 3. Sterne
        │
        ▼
  [Tier 4 – Prestige / Endgame]
```

---

## Offene Punkte für die Planungssession

- [x] Schwellenwerte → **Vorschläge stehen oben, werden im laufenden Betrieb gebalanced.** Werte werden täglich neu berechnet und in DB gespeichert.
- [x] Wie viele Items müssen pro Tier erforscht sein? → **⅓ des Vortiers** (5/6/7) – details in Techtree-Master
- [x] Werden Sterne automatisch vergeben? → **Nein. Immer über Michelin-Inspektor-Event (ANG-139).** Kein Stern ohne Besuch.
- [x] Kann man Sterne verlieren? → **Ja.** 10–14 Tage Karenz bei unterschrittenen Kriterien, dann Inspektor-Event → Aberkennung. Inspektor arbeitet in beide Richtungen.
- [x] Progress-Bar → **Ja, aber erst sichtbar ab dem ersten verliehenen Stern.** Vorher keine Anzeige – der Spieler weiß nicht wie nah er dran ist. Erhöht die Spannung vor dem ersten Inspektor-Besuch.
- [x] Gibt es einen Michelin-Inspektor als Game-Event? → **Ja (ANG-139).** Random-Event, Zeitpunkt unvorhersehbar. Vorankündigung "Inspektionsrunde läuft" ohne Zielhotel. News auf `michelin.sim` / `hotelnews.sim` (global für alle Spieler sichtbar).

---

## Quellen (Realität)
- Michelin Key Kriterien: guide.michelin.com (2024/2025)
- Michelin Star Kriterien: guide.michelin.com/en/faq

*Dieses Dokument ist Planungsbasis – alle Schwellenwerte sind Vorschläge und müssen gebalanced werden.*
