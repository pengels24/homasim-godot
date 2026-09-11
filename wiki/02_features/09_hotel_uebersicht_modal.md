# HO·MA·SIM – Hotelübersicht (Modal)

*Stand: 11.09.2026*

## 1. Zweck
Das Hotelübersicht-Modal (`ModalContentHotelOverview`) bietet eine kompakte "WiSim"-Darstellung des aktuellen Hotelzustands. Es ist über `F9` oder den HUD-Bottom-Button erreichbar.

## 2. Dargestellte Metriken
- **Sterne & Ruf:** Aktuelle Gourmet-Sterne und aktuelle/maximale Rufpunkte (`rep`).
- **Finanzen:** Aktueller Kontostand und die Tagesbilanz (Einnahmen - Ausgaben des aktuellen Tages, gelesen über `FinanceManager.get_daily_record(TimeManager.get_day())`).
- **Zimmer & Belegung:** Berechnet aus dem `room_registry`. Iteriert über alle Räume (Kategorie `guest_*`) und aggregiert die Anzahl der Betten (`bed_count`) sowie die Sauberkeit. Zeigt die prozentuale Auslastung und die durchschnittliche Sauberkeit.
- **Gästezufriedenheit:** Iteriert über die aktiven/wartenden/auscheckenden Gäste im `GuestManager` (`guest_parties`) und berechnet die durchschnittliche Zufriedenheit.

## 3. Aufbau
Das Modal nutzt das Standard-Layout mit vier `PanelContainer`-Elementen (vom Typ `InnerPanel`), die in einem 2-Spalten-Grid (`GridContainer`) angeordnet sind. Das Update der Werte erfolgt live in der `_process()`-Methode, solange das Modal sichtbar ist.
