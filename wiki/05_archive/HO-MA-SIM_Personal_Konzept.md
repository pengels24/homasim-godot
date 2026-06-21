# HO·MA·SIM – Personal & Schulungssystem Konzept

*Planungsdokument – Basis-Design*
*Erstellt: 12.04.2026*
*Hinweis: Alle Berufsbezeichnungen sind bewusst geschlechtsneutral gehalten.*

---

## Grundprinzip

- **Level 2**: Personalbüro (hr_office) baubar → Personal einstellen möglich
- **Kein Techtree-Gate** für Basis-Personal – einstellen ist immer möglich
- **Techtree beschleunigt/verbessert** – aber blockiert nie den Grundbetrieb
- Personal hat Fähigkeiten die durch Arbeit + Schulung wachsen
- Mitarbeiter-Zufriedenheit beeinflusst Leistung

---

## Personaltypen & Verfügbarkeit

### Sofort ab Personalbüro (Level 2) – kein Techtree
| Typ | Aufgabe | Relevant für |
|---|---|---|
| Servicekraft (Housekeeping) | Zimmer reinigen (`cleanliness`) | Alle Zimmer |
| Haustechnik | Zimmer reparieren (`condition`) | Alle Zimmer |
| Rezeptionsfachkraft | Check-in/out Unterstützung, Wartezeit ↓ | Lobby |

### Freigeschaltet durch Techtree / Raumtypen
| Typ | Voraussetzung | Aufgabe |
|---|---|---|
| Küchenfachkraft / Küchenhilfe | Küche gebaut (G1.1) | Gastronomie-Satisfaction |
| Servicepersonal (Restaurant) | Restaurant gebaut (G1.2) | Service-Geschwindigkeit |
| Barfachkraft | Bar gebaut (G1.3) | Bar-Einnahmen |
| Fitnesstraining | Fitnessstudio gebaut (W1.1) | Wellness-Satisfaction |
| Schwimmaufsicht | Pool gebaut (W2.1) | Sicherheit + Satisfaction |
| Wellnessfachkraft | Spa gebaut (W3.1) | Wellness-Satisfaction |
| Concierge | Lobby-Upgrade (P2.3) | Gäste-Sonderwünsche |
| Nachtrezeption | Management (M1.4) | Nacht-Sicherheit | *(Add-on)* |

### Management-Personal (spät, Techtree Tier 2–3)
| Typ | Voraussetzung | Effekt |
|---|---|---|
| Restaurantleitung | Gourmet-Küche (G2.2) | +Gastro-Effizienz für alle Gastronomie-Mitarbeiter |
| Housekeeping-Leitung | Personalentwicklung (M3.2) | +Housekeeping-Effizienz für Servicekräfte |
| Hotelleitung | Prozessoptimierung II (M3.1) | Globaler Effizienz-Bonus |

---

## Fähigkeiten-System

### Grundfähigkeiten (alle Mitarbeiter, immer aktiv)
- **Charisma** – Gäste-Satisfaction bei Interaktion
- **Motivation** – Arbeitsgeschwindigkeit
- **Stressresistenz** – Leistungsabfall bei Überlastung
- **Teamfähigkeit** – Synergien mit anderen Mitarbeitern

### Abteilungs-Fähigkeiten (Auswahl, relevant für Gameplay)

**Housekeeping:**
- `Reinigungseffizienz` → Zimmer schneller reinigen
- `Detailgenauigkeit` → Höheres `cleanliness`-Maximum
- `Reparaturkenntnisse` → Haustechnik kann kleinere Schäden beheben

**Rezeption:**
- `Geduld` → Weniger Satisfaction-Verlust bei langen Wartezeiten
- `Verkaufstalent` → Höhere Aufpreis-Akzeptanzrate beim Würfelwurf (ANG-131)
- `Sprachkenntnisse` → Internationale Gästetypen bevorzugen das Hotel

**Gastronomie:**
- `Kochkunst` → Gastronomie-Satisfaction steigt
- `Servicegeschwindigkeit` → Kürzere Wartezeiten im Restaurant
- `Hygienebewusstsein` → Verhindert Gastro-Negative-Events

**Wellness:**
- `Fachkenntnisse` → Spa/Massage-Satisfaction
- `Erste Hilfe` → Pflicht für Schwimmaufsicht (Pool-Betrieb erlaubt)

---

## Skill-Wachstum

### Durch Arbeit (passiv)
- Jede Aktion der Servicekraft gibt minimale XP auf relevante Skills
- Langsam aber stetig – eine Servicekraft die täglich arbeitet wird besser

### Durch Schulung (aktiv)
- Spieler wählt Mitarbeiter + Skill + Schulungstyp
- Kostet Zeit (Mitarbeiter nicht verfügbar) + Geld
- Drei Schulungsstufen:

| Stufe | Dauer | Kosten | Skill-Gewinn |
|---|---|---|---|
| Grundschulung | 1 Spieltag | 200 € | +1 Skill-Level |
| Fortgeschritten | 3 Spieltage | 600 € | +2 Skill-Level |
| Experten-Kurs | 7 Spieltage | 1.500 € | +4 Skill-Level |

### Techtree-Verknüpfung
- **M3.2 Personalentwicklung** (Tier 3): Schulungsdauer –30%, Kosten –20%
- Ohne Techtree: Schulungen sind möglich, aber teurer/langsamer

---

## Mitarbeiter-Zufriedenheit (Morale)

Jeder Mitarbeiter hat einen `morale`-Wert (0–100). Dieser beeinflusst:
- Arbeitsgeschwindigkeit (niedrige Moral → langsamer)
- Fehlerrate (niedrige Moral → mehr Schäden, schlechtere Reinigung)
- Kündigungsrisiko (unter 20 → Mitarbeiter kündigt)

### Morale-Faktoren
| Faktor | Effekt |
|---|---|
| Regelmäßiges Gehalt | +Stabilität |
| Überstunden / Überlastung | –Moral |
| Personalräume vorhanden | +5 Basis-Moral |
| Schulungen erhalten | +Moral-Boost |
| Gute Gäste-Bewertungen | +kleiner Bonus |
| Kein eigenes Zimmer (Personalraum voll) | –Moral |

---

## Gehälter & Kosten

Gehälter werden täglich vom Kontostand abgezogen (Tagesabschluss).

| Personaltyp | Tagesgehalt (Vorschlag) |
|---|---|
| Servicekraft (Housekeeping) / Haustechnik | 80 € |
| Rezeptionsfachkraft | 100 € |
| Küchenfachkraft | 120 € |
| Servicepersonal / Küchenhilfe | 70 € |
| Barfachkraft | 90 € |
| Fitnesstraining / Schwimmaufsicht | 95 € |
| Concierge | 130 € |
| Wellnessfachkraft | 110 € |
| Nachtrezeption | 100 € |
| Management-Personal | 180–250 € |

*Alle Werte sind Vorschläge, werden im Balancing angepasst.*

---

## Verknüpfung mit anderen Systemen

| System | Verbindung |
|---|---|
| Zimmer-Condition (ANG-57) | Haustechnik verbessert `condition`, Servicekraft verbessert `cleanliness` |
| Gäste-Satisfaction | Skills beeinflussen direkt die Satisfaction-Berechnung |
| Michelin-Kriterien | ⭐⭐ mind. 1 Servicekraft + 1 Haustechnik; ⭐⭐⭐ mind. 2 Servicekräfte + 1 Haustechnik + 1 Rezeption + 1 Concierge |
| Techtree M3.2 | Schulungen schneller + günstiger |
| Lieferanten-System (M3.3) | Verhandlungskompetenz der Hotelleitung beeinflusst Lieferanten-Konditionen |
| `.sim`-Newsfeed | *"[Hotel X] hat eine neue Hotelleitung eingestellt"* (optional) |
| Erfolge | "Erstes Personal eingestellt", "Alle Abteilungen besetzt", "Experten-Team" |

---

## Offene Punkte

- [x] Max. Mitarbeiteranzahl → **Begrenzt durch Personalräume: je Raum max. 4 Mitarbeiter.** Mehr Personal = mehr Räume bauen.
- [x] Schichten / Nachtdienst → **Kein Schichtsystem in Release 1.** Spieltag 06:00–23:59, alles läuft automatisch. Nachtrezeption als Personaltyp → Add-on.
- [x] Kündigung → **Instant. "You're fired."** Gehalt wird nur bis zum Kündigungstag gezogen.
- [x] Mitarbeiter-Namen & Porträts → Namen aus `docs/wiki/data/staff/Mitarbeiter Namen.md`. Porträts: **neutrale Silhouetten** (kein KI-generiertes Bildmaterial). Upgrade später möglich.
- [x] Skill-Cap → **Max. Level 10 pro Skill.** Progression langsam aber spürbar. Level 10 = "Senior"-Status mit Badge auf der Mitarbeiter-Karte.
- [x] Urlaub / Krankheit → **Ja, als Random-Event.** Mitarbeiter fällt X Tage aus → Spieler muss vorher für Vertretung gesorgt haben.
  - Gleiches gilt für Schulungen: Mitarbeiter in Ausbildung ist **nicht verfügbar** – kein Einsatz, kein Notfall-Rückruf.
  - Strategische Konsequenz: nie den letzten Spezialisten einer Abteilung schulen ohne Backup.

---

*Dieses Dokument ist Planungsbasis. Details werden bei der Implementierung konkretisiert.*
