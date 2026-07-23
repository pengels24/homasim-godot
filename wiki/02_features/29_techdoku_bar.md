# TechDoku: Bar & Lounge
*Stand: v0.1.42*

Die `Bar` ist ein Gastro-POI, der primär Getränke (direkte Einnahmen ohne lange Bestell-Ketten) liefert, optional aber auch als kleines "zweites Restaurant" fungieren kann.

## 1. Rollen & Personal
- **Erforderliche Rolle:** `bartender` (Barkeeper). Steht zwingend hinter dem Tresen.
- **Optionale Rolle:** `waiter` (Bedienung). Bewegt sich im Gastraum.
- Sind die Mitarbeiter im Training, gelten sie als nicht anwesend.

## 2. Der Getränke-Betrieb (Ohne Bedienung / Küche)
Ist nur der Barkeeper anwesend (oder die Küche geschlossen), nutzt die Bar eine vereinfachte Logik:
- Gäste setzen sich an einen Tisch oder an den Tresen.
- Sie bestellen *kein* aufwendiges Essen, sondern trinken nur etwas.
- Der Gast zahlt sofort den Eintritts-/Getränkepreis (`visit_income` = 15).
- Nach kurzer Verweildauer steigt die Zufriedenheit um den Basiswert (plus WLAN/Klima-Bonus) und der Gast geht wieder.
- Die Stühle werden beim Verlassen schmutzig (`dirty`).

## 3. Der Restaurant-Betrieb (Mit Bedienung & Küche)
Ist ein `waiter` anwesend **UND** die Hotelküche funktionsfähig, verhält sich die Bar identisch zum `RestaurantSmall`:
- Der Gast bestellt ein Gericht aus dem Menü, das explizit auch für die Bar zugelassen ist (`served_in` enthält `bar`).
- Der Auftrag wandert via `GastroManager` in die Küche.
- Die Bedienung (`waiter`) holt die fertige Speise ab und liefert sie an den Sitzplatz.
- Die Stühle werden auch hier vom Waiter über Tasks wieder gereinigt.

## 4. Walking Areas
Damit die Optik stimmt, definiert die Bar zwei exakte Standorte für das Personal:
- `get_bartender_stand_pos()`: Sucht nach dem Punkt `Interior/Furniture/BartenderArea` hinter dem Tresen, damit der Barkeeper nicht zwischen den Gästen steht.
- `get_waiter_stand_pos()`: Zielt auf `WaiterArea` mitten im Gastraum.
