# Changelog v0.1.27b – Economy Balancing & Demolish-Fixes

**Datum: 2026-06-22**

## Features & Verbesserungen

### Economy & Cash Balancing (Variante A)
Das Spiel wurde auf einen deutlich strafferen Cashflow ausbalanciert, um das 50.000 € Startkapital in den Leveln 1 bis 4 wirkungsvoll abzuschöpfen.
- **Baukosten drastisch erhöht:**
  - Standardzimmer: 500 € ➔ **2.000 €**
  - Doppelzimmer: 800 € ➔ **3.500 €**
  - Familienzimmer: 1.500 € ➔ **6.000 €**
  - Superior-Zimmer: 8.000 € ➔ **15.000 €**
- **Übernachtungspreise angepasst:**
  - Standardzimmer: 60 € ➔ **80 €**
  - Doppelzimmer: 120 € ➔ **130 €**
  - Familienzimmer: 250 € ➔ **200 €**
  - Superior-Zimmer: (fehlt zuvor) ➔ **400 €**
- **Personalkosten gesenkt:**
  - Tagesgehalt für Housekeeping und Haustechnik von 80 € auf **60 €** reduziert, um im Early Game (Level 2) nicht sofort Bankrott zu gehen.
- **Tech-Tree Restriktion:**
  - Das Superior-Zimmer (`Z1.3`) wurde im Tech-Tree mit `"demo_locked": true` versehen und ist für die Tech-Demo deaktiviert.
- **Code Fixes in Room Definitions:**
  - `type: "room"` zu `BedDouble.gd` und `BedFamily.gd` hinzugefügt, da es dort in der `get_definition()` gefehlt hatte.

### Raum-Abriss (Demolish) System
- **Instant Demolish nach Checkout:** Ein Raum, der zum Abriss markiert ist (`is_demolish_requested == true`), wird beim Auszug des Gastes (`_finalize_checkout` im `GuestManager`) sofort abgerissen. Dadurch wird verhindert, dass der Raum erst noch in den Status "Schmutzig" wechselt und fälschlicherweise noch ein Housekeeping-Ticket generiert.
- **Debug Clicks entfernt:** Ein alter Debug-Code im `Room.gd` (Mausklick zum sofortigen Schmutzig-/Reparieren-Status) wurde entfernt, da er versehentlich echte Housekeeping-Tickets im TaskManager gelöscht oder überschrieben hatte.

### UI & UX Verbesserungen
- **Tooltips für den RoomStatusIndicator:** Die kleinen Service-Icons über den Räumen (Besen, Schraubenschlüssel, Abrissbirne) haben jetzt saubere Tooltips. 
  - *Reinigung läuft*
  - *Reparatur läuft*
  - *Wird abgerissen*
- **CustomTooltip Styling:** `CustomTooltip.tscn` und zugehörige Skripte wurden verfeinert, um das transparente Panel-Styling des Styleguides (`StyleBoxFlat` mit `#0f172a` und Rand) sauber auf alle dynamischen Tooltips (inkl. RoomStatusIndicator) anzuwenden.
- **Demolish-Dialog Text:** Der Bestätigungstext im "Raum abreißen" Popup wurde klarer formuliert, um zu signalisieren, dass der Abriss erst nach dem Checkout des aktuellen Gastes erfolgt, wenn der Raum aktuell belegt ist.

### Konzepte & Dokumentation (Wiki)
- **POI-Cash Vorbereitung:** Die `Bar.gd` wurde um `"min_staff": 1` und `"max_staff": 2` erweitert, um das kommende POI-Personal-System vorzubereiten.
- **3 neue Wiki-Dokumente erstellt:**
  - `wiki/22_balancing_levelkurve.md` (Detaillierte Erklärung der EXP-Mechanik und wie schnell Spieler leveln).
  - `wiki/23_balancing_cash.md` (Dokumentation der oben genannten "Variante A" Preisstruktur).
  - `wiki/24_balancing_poi_cash.md` (Konzept für Pay-Per-Visit Einnahmen und Betriebskosten bei zukünftigen POIs).
