# HO·MA·SIM – Techtree Master Plan

*Planungsdokument für das Techtree-Redesign (ANG-105/106)*
*Erstellt: 12.04.2026 | Max-Level Ziel: 30 (Run 1), erweiterbar auf 50/60 mit Add-ons*

---

## Grundprinzip (Zusammenfassung)

- **Freischalten ≠ Bauen**: Technologie erforschen = Erlaubnis. Geld + Platz trotzdem nötig.
- **Tiers als Gate**: Tier-Aufstieg = FP + Min-Level + Michelin-Stern + mind. X Items aus Vortier
- **Freie Wahl**: Innerhalb eines Tiers kann der Spieler frei wählen, was er erforscht
- **Sichtbar von Anfang an**: Alles sichtbar, ausgegraut bis verfügbar
- **Planungsbüro**: Schaltet den gesamten Techtree frei – automatisch durch Level (kein Techtree-Item)
- **Level**: Progressions-Gefühl, nicht alleiniges Gate

---

## Tier-Aufstiegs-Bedingungen

| Von → Nach | FP | Min-Level | Michelin | Items aus Vortier |
|---|---|---|---|---|
| Start → Tier 1 | Planungsbüro gebaut | Level 5 | – | – |
| Tier 1 → Tier 2 | 500 FP | Level 10 | ⭐ 1 Stern | mind. ⅓ = 5 von 15 |
| Tier 2 → Tier 3 | 1.500 FP | Level 20 | ⭐⭐ 2 Sterne | mind. ⅓ = 6 von 19 |
| Tier 3 → Tier 4 | 4.000 FP | Level 30 | ⭐⭐⭐ 3 Sterne | mind. ⅓ = 7 von 20 |
| **Run 1 abgeschlossen** | – | **Level 40** | – | alle Tier-4-Items erreichbar |
| Add-on 1: Tier 5 | 8.000 FP | Level 41 | TBD | – |
| Add-on 1 abgeschlossen | – | **Level 60** | – | – |

*Alle Werte sind Vorschläge und werden im Balancing angepasst.*

---

## Kategorien (Äste)

Der Baum hat **5 Kategorien**, die durch alle Tiers laufen:

1. 🛏️ **Zimmer & Unterbringung** – Schlafzimmertypen, Zimmer-Upgrades
2. 🍽️ **Gastronomie & Küche** – Essensbereiche, Küchen-Infrastruktur
3. 🧘 **Wellness & Freizeit** – Sport, Entspannung, Außenbereiche
4. 📋 **Management & Betrieb** – Service-Räume, Büros, Logistik, Effizienzen
5. 🎪 **Prestige & Events** – Veranstaltungen, Luxus-Extras, Sonderattraktionen

---

## TIER 1 – Komfort & Grundbetrieb
*Voraussetzung: Planungsbüro + Level 5*
*FP-Kosten pro Item: 100–200 FP*

### 🛏️ Zimmer & Unterbringung
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| Z1.1 | Familienzimmer | `bed_family` (2×3) | 100 | – |
| Z1.2 | Superior-Zimmer | `bed_superior` (2×2) | 150 | – |
| Z1.3 | Zimmer-Komfort-Paket | Bessere Basis-Satisfaction bei Check-in | 200 | Z1.1 oder Z1.2 |

### 🍽️ Gastronomie & Küche
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| G1.1 | Basis-Küche | `kitchen` (2×2) | 100 | – |
| G1.2 | Basis-Restaurant | `restaurant` (2×3) | 150 | G1.1 |
| G1.3 | Bar/Lounge | `bar` (2×2) | 150 | G1.1 |
| G1.4 | Lagerraum | `storage` (1×2) | 100 | G1.1 |

### 🧘 Wellness & Freizeit
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| W1.1 | Fitnessstudio | `fitness` (2×3) | 150 | – |
| W1.2 | Spielzimmer/Kinderbereich | `kids_room` (2×2) | 120 | Z1.1 |
| W1.3 | Fahrradverleih | Buchbares Extra, +Satisfaction bei Aktiv-Gästen | 100 | – |

### 📋 Management & Betrieb
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| M1.1 | Personalräume | `staff_room` (1×2) | 100 | – |
| M1.2 | HR-Büro | `hr_office` (bereits impl.) | – | bereits ab Level 2 |
| M1.3 | Wäscherei | `laundry` (1×2) | 150 | M1.1 |
| M1.4 | Verwaltungsbüro | `management` (bereits impl.) | – | bereits ab Level 3 |

### 🎪 Prestige & Events
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| P1.1 | Konferenzraum | `conference` (3×3) | 200 | – |
| P1.2 | Terrasse/Garten | `terrace` (Außenbereich 2×2) | 150 | – |
| P1.3 | Zeitungsservice / Lesecke | Kleiner Satisfaction-Bonus, Atmosphäre | 80 | – |

**Tier 1 Gesamt: ~15 Items**

---

## TIER 2 – Qualität & Persönlichkeit
*Voraussetzung: Tier 1 + Level 10 + ⭐ 1 Michelin-Stern + mind. 5 Tier-1-Items*
*FP-Kosten pro Item: 250–400 FP*
*Mix: 6× standalone (–), 11× verkettete Items*

### 🛏️ Zimmer & Unterbringung
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| Z2.1 | Deluxe-Zimmer | `bed_deluxe` (2×3) | 300 | Z1.2 |
| Z2.2 | Apartment | `bed_apartment` (2×4) | 350 | Z1.1 |
| Z2.3 | Zimmer-Ausstattungs-Upgrade | Fernseher, Minibar, Schreibtisch als Attribut | 250 | Z2.1 |

### 🍽️ Gastronomie & Küche
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| G2.1 | Kühlraum | `cold_storage` (1×2) | 250 | G1.1 |
| G2.2 | Gourmet-Küche Upgrade | Verbesserte Küchen-Satisfaction | 300 | G1.2 |
| G2.3 | Hotelbar Upgrade | Alkohollizenz, bessere Einnahmen | 300 | G1.3 |
| G2.4 | Frühstücksbereich | `breakfast_room` (2×2) | 280 | – |

### 🧘 Wellness & Freizeit
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| W2.1 | Schwimmbad (Innen) | `pool_indoor` (3×4) | 400 | W1.1 |
| W2.2 | Sauna / Dampfbad | `sauna` (1×2) | 280 | – |
| W2.3 | Außenanlage | Garten-Erweiterung, Liegestühle | 250 | P1.2 |

### 📋 Management & Betrieb
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| M2.1 | Parkplatz/Garage | `parking` (Außen 2×3) | 280 | – |
| M2.2 | Prozessoptimierung I | Check-in-Geschwindigkeit +20% | 350 | M1.4 |
| M2.3 | Online-Buchungssystem | ANG-141: eigene Buchungsseite freigeschaltet | 400 | M1.4 |
| M2.4 | E-Ladesäulen | Buchbares Extra am Parkplatz, zieht Business-Gäste an | 250 | M2.1 |
| M2.5 | Barrierefreiheits-Upgrade | Rollstuhl-gerechte Zimmer-Attribute, neue Gast-Zielgruppe | 300 | – |

### 🎪 Prestige & Events
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| P2.1 | Veranstaltungsraum/Ballsaal | `ballroom` (4×4) | 400 | P1.1 |
| P2.2 | Boutique/Geschäft | `shop` (1×2) | 280 | – |
| P2.3 | Lobby-Upgrade | Verbesserte Lobby-Satisfaction, Concierge-Funktion | 300 | – |
| P2.4 | Gästebewertungs-System | Checkout-Bewertung + Sterne-Anzeige pro Gast | 320 | – |

**Tier 2 Gesamt: ~19 Items**

---

## TIER 3 – Exzellenz & Luxus
*Voraussetzung: Tier 2 + Level 20 + ⭐⭐ 2 Michelin-Sterne + mind. 6 Tier-2-Items*
*FP-Kosten pro Item: 500–800 FP*
*Mix: 5× standalone (–), 11× verkettete Items*

### 🛏️ Zimmer & Unterbringung
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| Z3.1 | Suite | `bed_suite` (3×3) | 600 | Z2.1 |
| Z3.2 | Themenzimmer | `bed_themed` (2×3, frei wählbares Design) | 650 | – |
| Z3.3 | Penthouse-Vorbereitung | Konzept-Item, schaltet Z4.1 frei | 500 | Z3.1 |
| Z3.4 | Zimmer-Attribute | near_exit, has_window, has_desk (ANG-138) | 550 | – |

### 🍽️ Gastronomie & Küche
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| G3.1 | Gourmetrestaurant | `gourmet_restaurant` (3×4) | 700 | G2.2 + G2.1 |
| G3.2 | Fine-Dining Konzept | +30% Satisfaction bei Gastronomie | 600 | G3.1 |
| G3.3 | Weinbar/Champagner-Lounge | Spezial-Bar mit Prestige-Boost | 580 | – |

### 🧘 Wellness & Freizeit
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| W3.1 | Spa-Bereich | `spa` (3×3) | 700 | W2.1 oder W2.2 |
| W3.2 | Außenpool | `pool_outdoor` (Außen 3×4) | 580 | – |
| W3.3 | Sport-Courts | Tennisplatz / Boccia-Bahn (Außen) | 500 | W2.3 |

### 📋 Management & Betrieb
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| M3.1 | Prozessoptimierung II | Smart-Reports, Tages-Statistiken erweitert | 600 | M2.2 |
| M3.2 | Personalentwicklung | Mitarbeiter-Skills steigen schneller | 700 | M2.2 |
| M3.3 | Lieferanten-System | Günstigere Betriebskosten via Lieferanten | 550 | – |
| M3.4 | Photovoltaik-Anlage | Passive Kostenreduzierung + Reputation-Bonus für Nachhaltigkeit | 600 | – |
| M3.5 | Haustier-Policy | Pet-friendly Zimmer-Attribut, neue Gast-Zielgruppe | 500 | – |

### 🎪 Prestige & Events
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| P3.1 | Casino / Nachtclub | `casino` (3×4) | 800 | P2.1 + M2.2 |
| P3.2 | Dachterrassen-Bar | `rooftop_bar` (Dach, 2×3) | 700 | P2.2 + W2.3 |
| P3.3 | Hotelwebseite (hotelbooking.sim) | ANG-141: eigene .sim-Buchungsseite | 600 | M2.3 |
| P3.4 | Hotel-Kunstgalerie | Wanderausstellungen im Lobby-Bereich, Prestige + Ruf | 650 | – |

**Tier 3 Gesamt: ~20 Items**

---

## TIER 4 – Prestige & Endgame
*Voraussetzung: Tier 3 + Level 30 + ⭐⭐⭐ 3 Michelin-Sterne + mind. 5 Tier-3-Items*
*FP-Kosten pro Item: 1.000–2.000 FP*
*Mix: 5× standalone (–), 7× verkettete Items*

### 🛏️ Zimmer & Unterbringung
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| Z4.1 | Penthouse-Suite | `bed_penthouse` (4×4, ganzes Dach) | 1.500 | Z3.3 |
| Z4.2 | Privat-Villa / Bungalow | `villa` (Außen, separates Gebäude) | 2.000 | – |

### 🍽️ Gastronomie & Küche
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| G4.1 | Michelin-Restaurant | Sterne-Gastronomie, eigene Kategorie | 1.500 | G3.2 |
| G4.2 | 24h Room Service | Rund-um-die-Uhr Zimmerservice | 1.000 | – |

### 🧘 Wellness & Freizeit
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| W4.1 | Privat-Spa (Buchbar) | Luxus-Spa als buchbare Einheit | 1.500 | W3.1 |
| W4.2 | Helikopter-Landing | Prestige-Item, Bonus-Reputation | 1.800 | – |
| W4.3 | Naturpool / Bioteich | Außen, Premium-Ästhetik, Reputation-Bonus | 1.200 | – |

### 📋 Management & Betrieb
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| M4.1 | KI-Rezeption | Automatischer Check-in/out | 1.500 | M3.1 + M3.2 |
| M4.2 | Multi-Hotel-Verwaltung | Grundstein für Add-on 1 | 2.000 | M3.3 |

### 🎪 Prestige & Events
| # | Item | Freischaltet | FP | Abhängigkeit |
|---|---|---|---|---|
| P4.1 | Gala-Event-System | Regelmäßige Prestige-Events mit Sonder-Einnahmen | 1.500 | P3.1 |
| P4.2 | Ikonisches Hotel-Feature | Unique-Item je Spieler (Skulptur, Dach-Pool, etc.) | 2.000 | – |
| P4.3 | In-Game Browser (.sim) | ANG-142: simulierter Webbrowser mit .sim-Seiten | 1.200 | P3.3 + M4.1 |
| P4.4 | Privat-Butler-Service | Pro Zimmer buchbar, massiver Satisfaction-Boost | 1.800 | M4.1 |

**Tier 4 Gesamt: ~13 Items**

---

## Übersicht: Gesamtanzahl Items

| Tier | Items | davon standalone | Kumulativ |
|---|---|---|---|
| Tier 1 | 15 | 10 (67%) | 15 |
| Tier 2 | 19 | 7 (37%) | 34 |
| Tier 3 | 20 | 7 (35%) | 54 |
| Tier 4 | 13 | 5 (38%) | 67 |

*Ein "First Run" auf Level 30 sollte realistische Tier 1–2 vollständig + Tier 3 angeschnitten beinhalten. Tier 4 ist bewusst als Langzeit-/Add-on-Inhalt konzipiert.*

---

## Level-Progression (Run 1: Max 40 | Add-on 1: Max 60)

| Level | Meilenstein |
|---|---|
| 1–4 | Grundbetrieb ohne Techtree (Basis-Zimmer, Lobby) |
| 5 | Planungsbüro → Tier 1 öffnet |
| 8–10 | Tier 1 aktiv, ⭐ 1 Stern anpeilen → Tier 2 |
| 10–18 | Tier 2 – Gastronomie, Wellness, Buchungssystem |
| 20 | ⭐⭐ 2 Sterne möglich → Tier 3 öffnet |
| 20–28 | Tier 3 – Luxus, Exzellenz, Spa, Gourmet |
| 30 | ⭐⭐⭐ 3 Sterne möglich → Tier 4 öffnet |
| 30–40 | Tier 4 – Endgame, alle Items erreichbar |
| **40** | **Run 1 abgeschlossen – vollständiger Techtree** |
| 41+ | Add-on 1 – Tier 5, neue Inhalte, Level bis 60 |

---

## Verknüpfung mit dem Erfolgs-System

Techtree-Meilensteine sind natürliche Achievement-Trigger – kein Extra-Aufwand, die Events sind ohnehin da.

### Tier-Achievements (Fortschritt)
| Erfolg | Bedingung | Typ |
|---|---|---|
| "Erste Schritte" | Planungsbüro gebaut, Tier 1 geöffnet | Bronze |
| "Aufstrebend" | Tier 2 freigeschaltet (⭐ 1 Stern erreicht) | Silber |
| "Etabliert" | Tier 3 freigeschaltet (⭐⭐ 2 Sterne erreicht) | Silber |
| "Exzellenz" | Tier 4 freigeschaltet (⭐⭐⭐ 3 Sterne erreicht) | Gold |
| "Vollständig" | Alle Items eines Tiers erforscht | Bronze/Silber/Gold je Tier |
| "Der vollständige Techtree" | Alle 67 Items erforscht | Platin |

### Techtree-Kategorien-Achievements
| Erfolg | Bedingung |
|---|---|
| "Kulinarische Ambitionen" | Alle Gastronomie-Items erforscht |
| "Wellness-Oase" | Alle Wellness-Items erforscht |
| "Luxushotelier" | Alle Zimmer-Items erforscht |
| "Effiziente Führung" | Alle Management-Items erforscht |
| "Schauplatz der Gesellschaft" | Alle Prestige-Items erforscht |

### Strategie-Achievements (Kombination aus Kategorien)
| Erfolg | Bedingung |
|---|---|
| "Das perfekte Resort" | Alle Wellness + alle Zimmer-Items erforscht |
| "Der Gastronom" | Alle Gastronomie + alle Prestige-Items erforscht |
| "Der Businesshotelier" | Alle Management + alle Prestige-Items erforscht |
| "Alles aus einer Hand" | Alle 5 Kategorien mind. zur Hälfte erforscht |

### Item-spezifische Achievements (Auswahl)
| Erfolg | Bedingung |
|---|---|
| "Vive la France" | Gourmetrestaurant erforscht + gebaut |
| "Grüner Hotelier" | Photovoltaik-Anlage erforscht |
| "Willkommen, Wuffi" | Haustier-Policy erforscht |
| "High Society" | Casino erforscht + gebaut |
| "Über den Wolken" | Penthouse-Suite gebaut |

*Vollständige Erfolgs-Liste gehört ins separate Erfolge-Dokument (`docs/wiki/ideas/features/Erfolge.md`). Hier nur die Techtree-relevanten Hooks.*

---

## Offene Fragen (TODO)

- [x] Werden Michelin-Sterne automatisch vergeben oder muss der Spieler aktiv "beantragen"? → **Immer über den Inspektor-Event (ANG-139)**
- [x] Kann man Sterne verlieren? → **Ja. 10–14 Tage Karenz bei unterschrittenen Kriterien, dann Inspektor-Event → Aberkennung. Inspektor arbeitet in beide Richtungen.**
- [x] Wie viele Items aus Vortier? → **⅓ des Vortiers, skaliert automatisch mit Item-Anzahl (5/6/7)**
- [x] FP-Kosten Planungsbüro → **Kein FP-Cost, nur Level-Gate (Level 5).** FP starten erst nach dem Bau des Büros – man kann nicht mit FP für das Büro zahlen das FP erst freischaltet.
- [x] Passive FP-Rate → **Aktivitätsbasierter Stunden-Bonus:**
  | Aktivität (letzte Stunde) | Passive FP/h |
  |---|---|
  | Idle (0–5 Aktionen) | 5 FP/h |
  | Moderat (6–20 Aktionen) | 10 FP/h |
  | Aktiv (21–50 Aktionen) | 20 FP/h |
  | Sehr aktiv (50+ Aktionen) | 35 FP/h |
  - Verwaltungsbüro wirkt als Multiplikator (×1.5 / ×2) zusätzlich
  - Wer ein gutes Hotel führt (viele Gäste = viele Aktionen) forscht schneller – thematisch stimmig
- [x] Michelin-Inspektor (ANG-139) als versteckter Random-Event: Sterne-Vergabe nur möglich wenn Inspektor-Besuch stattgefunden hat? → **Ja, immer. Kein Stern ohne Inspektor-Besuch.**
  - In-Game Browser (ANG-142): Verleihung + Aberkennung erscheinen als News-Artikel auf `michelin.sim` / `hotelnews.sim`
  - Vor dem Inspektions-Event: generische Meldung "Michelin kündigt Inspektionsrunde an" – ohne Zielhotel zu nennen (erzeugt Spannung)
  - **⚠️ Multiplayer-Dimension**: `.sim`-News sind **global** – alle Spieler sehen was die Konkurrenz macht. "Hotel XY hat den 2. Stern erhalten" erzeugt Wettbewerbsdruck. Aberkennung ist öffentliche Blamage. Das Newsfeed ist damit das soziale Herzstück des Multiplayer-Aspekts.
- [x] Zimmer-Attribute (ANG-138): **Separat vom Techtree.** Verknüpft mit Gästetypen:
  - **Muss-Attribut** (per Definition) → kein Würfeln, Gast lehnt Zimmer ab oder Aufpreis-Angebot
  - **Wunsch-Attribut** → Würfelwurf, Misserfolg = leichter Satisfaction-Abzug
  - Selbe State-Machine-Logik wie ANG-131 (`surchargeState`), nur auf Attribut-Ebene
- [ ] Add-on 1: Level 41–60, Tier 5 mit neuen Inhalten (Multi-Hotel, neue Raumtypen)

---

*Dieses Dokument ist die Planungsbasis für die Implementierung. Schwellenwerte und Anzahlen werden im Balancing angepasst.*
