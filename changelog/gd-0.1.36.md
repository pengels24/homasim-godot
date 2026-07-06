# Changelog

## Version: v0.1.36gd-td
**Datum:** 2026-07-06

### Features & Verbesserungen
- **Mehrfachbau-Option:** Neues Dropdown in den Gameplay-Einstellungen hinzugefügt, um beim Bauen von Räumen festzulegen, ob der Bau-Modus (Cursor) beibehalten werden soll ("Aus", "An", "Mit Shift") (ANG-253).
- **Zimmer-Tooltip:** Ampel-System (Grün/Gelb/Rot) für Zustand & Sauberkeit eingefügt und Tooltip-Größe dynamisch an Inhalt angepasst.
- **Service & Personal:** Magisches Auto-Säubern entfernt. Service-Tickets warten nun regulär auf eingestelltes Personal, begleitet von passenden Ingame-Hinweisen (ANG-260). Personal hat nun zwischen 22:00 und 07:00 Uhr Nachtruhe und nimmt keine neuen Aufgaben an.
- **Verschmutzungs-Logik:** POIs verdrecken nun realistisch basierend auf Gäste-Besuchen. Hotelzimmer-Sauberkeit fällt beim Checkout komplett auf 0%.
- **Wartungs-Logik:** Neuer Flow für Raum-Abnutzung. Räume verlieren nun unregelmäßig an Zustand (Chance abhängig von neuer Hotel-Einstellung "Raum-Zustandsverringerung" und täglicher Auslastung). Auto-Reparatur ist bis Level 100 gesperrt (ANG-257).
- **Warn-Icons:** Räume zeigen das Besen/Schraubenschlüssel-Icon ab sofort automatisch bei unter 50% Zustand, um Wartungsbedarf rechtzeitig zu signalisieren.
- **Tages-Scheduler:** Spawns an der Rezeption exakt an die tatsächlich verfügbaren (und heute freiwerdenden) Zimmer gekoppelt, um künstliche Dauer-Bestrafung zu vermeiden.

### Bugfixes
- **UI:** PiP-Kameras (Bild-in-Bild) in Gästeliste, Raumliste und Personal-Ansicht werden wieder gestochen scharf gerendert (ANG-244).

### Technische Änderungen
- **Code-Cleanup:** Überflüssige Magic-Cleans und automatische Ticket-Erstellungen vor Level-Freischaltungen entfernt.
