# HomaSim Godot - Changelog v0.1.41
**Datum:** 2026-07-20

## Features & Verbesserungen
- **Bedürfnis-System:** Gäste prüfen beim Check-In die Zimmerausstattung (Traits). Fehlende Merkmale reduzieren die Zufriedenheit.
- **Zimmer-Ausstattungen:** Die Schlafräume besitzen nun spezifische Traits (Telefon, TV, Schreibtisch, Komfort, Platzangebot), passend zu den Gästetypen.
- **Manuelle Zimmer-Upgrades:** Bereits gebaute Zimmer können im Zimmer-Menü manuell geupgradet werden (WLAN für 50$, Klima für 150$), sofern im Techtree erforscht.
- **Automatische Upgrades:** Neu gebaute Zimmer erhalten freigeschaltete Upgrades (WLAN/Klima) direkt.
- **Wartezeit-Strafe:** Die Zufriedenheit sinkt, wenn Gäste zu lange auf Essen oder den Checkout warten müssen.
- **Dynamischer Check-Out:** Bezahlung, Trinkgeld, Rabatte, Erfahrungspunkte und Ruf skalieren nun mit der Zufriedenheit der Gäste.

## Bugfixes
- Keine in diesem Patch.

## Technische Änderungen
- `Room.gd` wurde um `acquired_traits` zur Speicherung individueller Raum-Upgrades erweitert.
- `GuestParty.gd` beinhaltet jetzt die `satisfaction`-Logik für dynamische Gästezufriedenheit.
- Techtree-JSON um `tech_wlan` und `tech_klima` erweitert.
