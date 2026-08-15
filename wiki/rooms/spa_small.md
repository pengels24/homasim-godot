# Raum: Spa (Klein)

## 1. Identifikation
*   **ID:** `spa_small`
*   **Kategorie:** Wellness
*   **Techtree-Gate:** `W1.1`
*   **Grid-Size:** variabel (typisch 2×2 Parzellen)

## 2. Spielmechanik
Gäste entspannen im Spa und regenerieren Energie und Spaß. Der Raum wird als POI besucht (kein Übernachten). Gäste bleiben 1–3 Ingame-Stunden und wechseln alle 20–30 Minuten den Platz (Liege/Massagebereich).

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/spa_small/SpaSmall.tscn`
*   **Script:** `scenes/ingame/rooms/spa_small/SpaSmall.gd`

### 3.1 Kapazität & Limits
- **`max_guests`:** 6 (erhöht von ursprünglich 4)
- **Platzwechsel-Intervall:** ~20–30 Ingame-Minuten
- **Aufenthaltsdauer:** 1–3 Ingame-Stunden

### 3.2 Need-Restoration (Gästebedürfnisse)
Beim Verlassen des Spas werden folgende Stat-Veränderungen auf den Gast angewandt (definiert im `need_restoration`-Dictionary in `SpaSmall.gd`):

| Bedürfnis | Änderung | Erklärung |
|-----------|----------|-----------|
| `energy`  | `+20`    | Entspannung regeneriert Energie |
| `fun`     | `+15`    | Angenehme Erfahrung |

> **Hinweis:** Werte können im `get_data()` Dictionary von `SpaSmall.gd` unter dem Key `need_restoration` angepasst werden.

### 3.3 Navigation & Wegpunkte
Dieser Raum nutzt das Standard-`RoomNavigator`-System:

**Sitzplätze / Liegeplätze:**
- `Seat1` bis `SeatN` – Marker2D/Node2D für Gäste-Platzierung auf Liegen oder in Pools.
- `claim_seat()` wird beim Betreten aufgerufen, um einen freien Platz zu reservieren.

**NavBlocker:**
- Massageliegen, Whirlpools und Dekoelemente blockieren das lokale AStar-Netz.
- `LOCAL_NAV_CELL_SIZE = 4` Pixel für feineres Routing zwischen Möbeln.

**ServicePoint:**
- `%ServicePoint` definiert den Marker, zu dem Reinigungskräfte navigieren.

### 3.4 Personal
- **Kein dediziertes Spa-Personal** in der aktuellen Alpha.
- Reinigung: Hausmeister/Reinigungskraft nach Gästeabreise über Standard-`ServicePoint`.

### 3.5 Bekannte Eigenheiten
- `claim_seat()` muss beim `_ready` eines Gastes aufgerufen werden, da sonst die Sitzplatzsuche fehlschlägt (Initialisierungs-Bug, bereits behoben in v0.1.50).
- Der Rekursions-Bug, bei dem Gäste den Spa sofort wieder verließen, wurde in v0.1.50 behoben (Wellness-Logik mit Timer implementiert).
