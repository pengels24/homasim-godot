# HO·MA·SIM – Raumliste (Übersichts-Modal)

_Planungsdokument – UI & Systemarchitektur_ 
_Stand: 15.06.2026_

## 1. Grundprinzip

Die Raumliste ist das Management-Gegenstück zur Gästeliste. Sie bietet dem Spieler eine Vogelperspektive über alle physisch gebauten Räume im Hotel, deren Zustand und aktuelle Belegung. Das Design orientiert sich am bestehenden Rezeptions-Modal.

## 2. Datenquelle (Active Rooms)

Das UI zieht seine Informationen aus dem globalen Raum-Manager (der Instanz, die die gebauten Räume auf der Map verwaltet). Benötigte Live-Daten pro Raum-Eintrag:

- `room_id` (z. B. "Z0015")
- `room_type_name` (z. B. "Einzelzimmer")
- `category` (Zimmer, Gastronomie, Wellness, etc.)
- `status` (Frei, Belegt, Checkout, Service Needed)
- `cleanliness_level` (0-100)
- `maintenance_level` (0-100)
- `assigned_guest_name` (Falls Status = Belegt)
- `node_reference` (Link zum Objekt in der Spielwelt)

## 3. UI-Layout (Das Modal)

Das Fenster ist in zwei funktionale Bereiche unterteilt:

### Top-Bar: Filter & Sortierung

Ein horizontaler Container (`HBoxContainer`) über der Liste:

- **Kategorie-Filter:** Dropdown oder Buttons (Alle, Nur Zimmer, Nur Personalräume, Nur Gastronomie).
- **Status-Filter:** Dropdown (Alle, Nur Freie, Nur Belegte, Nur Service benötigt).
- **Sortierung:** Nach Name/ID, nach Sauberkeit (aufsteigend), nach Zustand (aufsteigend).

### Main-Area: Die Liste

Ein `ScrollContainer`, der die einzelnen Räume als anklickbare Panels (`VBoxContainer`) untereinander auflistet.

- **Aufbau eines Listeneintrags (Zeile):**
    - _Links:_ Icon des Raumtyps + ID & Name (z. B. 🛏️ EZ | Z0015).
    - _Mitte:_ Aktueller Gast (falls belegt) oder Preis pro Nacht.
    - _Rechts:_ Zwei kleine Progress-Bars (Sauberkeit & Zustand) sowie ein Status-Icon (Orientiert an den Map-Indikatoren: Grün/Rot/Orange/Gelb).

## 4. Interaktion (Synergie mit der Map)

Wenn der Spieler auf einen Eintrag in der Raumliste klickt, gibt es zwei mögliche Aktionen:

1. **Fokus-Modus:** Das Modal schließt sich (oder wird minimiert) und die Hauptkamera zentriert sich weich auf die Koordinaten des ausgewählten Raums.
2. **Detail-Ansicht:** Es öffnet sich das Raum-Dossier (welches identisch mit dem Hover-Tooltip der Map ist, nur als festes Fenster).
