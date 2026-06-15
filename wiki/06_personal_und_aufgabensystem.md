# HO·MA·SIM – Personal & Aufgabensystem Konzept

_Planungsdokument – Basis-Design & Systemarchitektur_
_Stand: 15.06.2026_

_Hinweis: Alle Berufsbezeichnungen sind bewusst geschlechtsneutral gehalten._

## 1. Grundprinzip

- **Level 2**: Freischaltung durch Vertrag mit Personaldienstleister (Kein physisches Personalbüro mehr nötig, siehe ANG-201) → Personal einstellen möglich.
- **Kein Techtree-Gate** für Basis-Personal – Einstellen ist immer möglich.
- **Techtree beschleunigt/verbessert** – blockiert aber nie den Grundbetrieb.
- Personal hat Fähigkeiten, die durch Arbeit + Schulung wachsen.
- Mitarbeiter-Zufriedenheit beeinflusst Leistung.

## 2. Personaltypen & Verfügbarkeit

### Sofort ab Level 2 (Dienstleister) – kein Techtree

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
| Nachtrezeption | Management (M1.4) | Nacht-Sicherheit _(Add-on)_ |

### Management-Personal (spät, Techtree Tier 2–3)

| Typ | Voraussetzung | Effekt |
|---|---|---|
| Restaurantleitung | Gourmet-Küche (G2.2) | +Gastro-Effizienz für alle Gastronomie-Mitarbeiter |
| Housekeeping-Leitung | Personalentwicklung (M3.2) | +Housekeeping-Effizienz für Servicekräfte |
| Hotelleitung | Prozessoptimierung II (M3.1) | Globaler Effizienz-Bonus |

## 3. Fähigkeiten-System

### Grundfähigkeiten (alle Mitarbeiter, immer aktiv)

- **Charisma** – Gäste-Satisfaction bei Interaktion
- **Motivation** – Arbeitsgeschwindigkeit
- **Stressresistenz** – Leistungsabfall bei Überlastung
- **Teamfähigkeit** – Synergien mit anderen Mitarbeitern

### Abteilungs-Fähigkeiten (Auswahl)

**Housekeeping:**
- `Reinigungseffizienz` → Zimmer schneller reinigen
- `Detailgenauigkeit` → Höheres `cleanliness`-Maximum
- `Reparaturkenntnisse` → Haustechnik kann kleinere Schäden beheben

**Rezeption:**
- `Geduld` → Weniger Satisfaction-Verlust bei langen Wartezeiten
- `Verkaufstalent` → Höhere Aufpreis-Akzeptanzrate beim Würfelwurf
- `Sprachkenntnisse` → Internationale Gästetypen bevorzugen das Hotel

_(Gastronomie & Wellness Analog nach Fachgebiet)_

## 4. Skill-Wachstum

### Durch Arbeit (passiv)
- Jede Aktion der Servicekraft gibt minimale XP auf relevante Skills.
- Langsam aber stetig – tägliche Arbeit verbessert das Personal.

### Durch Schulung (aktiv)
- Spieler wählt Mitarbeiter + Skill + Schulungstyp.
- **Wichtig:** Kostet Zeit (Mitarbeiter nicht verfügbar) + Geld.

| Stufe | Dauer | Kosten | Skill-Gewinn |
|---|---|---|---|
| Grundschulung | 1 Spieltag | 200 € | +1 Skill-Level |
| Fortgeschritten | 3 Spieltage | 600 € | +2 Skill-Level |
| Experten-Kurs | 7 Spieltage | 1.500 € | +4 Skill-Level |

_(Techtree M3.2 "Personalentwicklung" senkt Dauer um 30%, Kosten um 20%)_

## 5. Mitarbeiter-Zufriedenheit (Morale)

Jeder Mitarbeiter hat einen `morale`-Wert (0–100). Dieser beeinflusst:

- **Arbeitsgeschwindigkeit** (niedrige Moral → langsamer)
- **Fehlerrate** (niedrige Moral → mehr Schäden, schlechtere Reinigung)
- **Kündigungsrisiko** (unter 20 → Mitarbeiter kündigt)

**Morale-Faktoren:**
- Regelmäßiges Gehalt (+Stabilität)
- Überstunden / Überlastung (–Moral)
- Personalräume vorhanden (+5 Basis-Moral)
- Schulungen erhalten (+Moral-Boost)
- Kein eigenes Zimmer / Personalraum voll (–Moral)

## 6. Das Automatisierungs- & Aufgabensystem

### 6.1 Die Raum-Erweiterung & Indikatoren

Räume erhalten in ihrer Registry neue Metadaten:
- `cleanliness_level` (0-100)
- `maintenance_level` (0-100)
- `is_service_requested` (bool)

**Visuelles Feedback (Raum-Indikator):**
- **Grün:** Frei & bewohnbar.
- **Rot:** Belegt (Gast eingebucht).
- **Orange:** Gast im Checkout.
- **Gelb (Pulsierend):** `is_service_requested` ist aktiv (Blockiert für Neuvermietung).

### 6.2 Aufgabengenerierung (Trigger)

- **Checkout (Harter Trigger):** Gast verlässt Zimmer → `cleanliness_level` sinkt → `is_service_requested = true`.
- **Zufalls-Events (Weicher Trigger):** Unregelmäßige Abzüge durch das Event-System (z. B. "Glas gefallen"). Fällt ein Wert unter die kritische Schwelle (z. B. 30), wird Service angefordert.

### 6.3 Der Task-Manager (Schwarzes Brett)

- Ein unsichtbares System sammelt Anforderungen (z. B. `[Ziel: Raum EZ-01] | [Typ: Reinigung] | [Status: Offen]`).
- Teilt Aufgaben dynamisch an die nächste freie Servicekraft zu. Status wechselt auf "In Bearbeitung".

### 6.4 Die Mitarbeiter-KI (State Machine)

Mitarbeiter befinden sich stets in einem von drei Zuständen:
1. `IDLE`: Warten im Personalraum, fragen den Task-Manager regelmäßig nach Jobs.
2. `MOVING`: Navigieren über `NavigationRegion2D` zum Zielraum.
3. `WORKING`: Arbeiten im Raum (Timer läuft, z. B. 5 Sek.). Danach Reset von `cleanliness` auf 100, Indikator wird wieder grün, Mitarbeiter wechselt zu `IDLE`.

## 7. Spezifische Edge Cases & Mechaniken

- **Krankheit & Ausfälle (Smoothed Interrupts):**
  Krankheit triggert nicht instantan mitten im Arbeitsschritt. Das Event setzt die Ausdauer/Moral des Mitarbeiters auf einen kritischen Wert (<10). Der Spieler erhält einen Toast ("Mitarbeiter XY fühlt sich nicht wohl") als Vorwarnung. Der Mitarbeiter arbeitet den Tag verlangsamt zu Ende und meldet sich erst am nächsten Ingame-Morgen offiziell für X Tage krank.
- **Pausen & Personalraum-Logik:**
  Mitarbeiter sind nicht fest an einen Personalraum gebunden. Bei Wechsel in `IDLE` wird der nächstgelegene Personalraum gesucht, der noch einen der 4 Slots frei hat ("Take the next free place").
- **Zoning (Zukünftiges Feature):**
  Es können auf der Karte Zonen gemalt und Mitarbeiter zugewiesen werden. Der Task-Manager gleicht Ticket-Zone und Mitarbeiter-Zone ab. Ungewiesene Mitarbeiter fungieren als Springer.
- **Kündigungen:** Erfolgen sofort ("You're fired"). Das Gehalt wird nur bis zum Kündigungstag gezogen.
- **Max Level:** Skill-Cap liegt bei Level 10 ("Senior"-Status mit Badge).
