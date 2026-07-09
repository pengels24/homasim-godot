# Changelog v0.1.38gd-td
Datum: 2026-07-09

## Features & Verbesserungen
- Bar: Jeder Gast-Besuch gibt nun +10 EXP (visit_exp-System) - sichtbar als blauer Floating-Text uber der Bar.
- visit_exp ist ein neues optionales Property fur alle POIs, erweiterbar fur zukunftige Raume (Spa, Restaurant etc.).
- Tagesabschluss: Neue Zeile Sonstige Einnahmen zeigt Level-Up-Boni und Quest-Belohnungen korrekt an.
- Tagesabschluss: Kategorie Gastro wird nun korrekt unter Restaurant summiert.
- Checkout-Karten in der Rezeption zeigen nun den echten Auszahlungsbetrag (Nightly Price x Nachte x Zufriedenheit).
- HUD: Geldanzeige wird rot, wenn das Konto ins Minus rutscht.
- Toast-Nachrichten sind 80 Pixel nach unten verschoben - verdecken nicht mehr den Schliessen-Button von Modals.
- Floating Income-Text erscheint nun uber dem Zentrum des POI-Raums statt an der Gastposition.
- Tutorial-Tipp Vorlauf nutzen erscheint nach 15 echten Minuten auf Normalgeschwindigkeit.

## Bugfixes
- Kritischer Absturz beim Tageswechsel behoben: GameState.hotel_level existiert nicht als Property - auf selected_hotel.get() umgestellt.
- Surcharge-Toast zeigte beide Wurfelwerte identisch an - Platzhalter in language.csv korrigiert.
- Bar-Indikator aktualisiert sich nach Barkeeper-Zuweisung korrekt ohne Reload.
- Bar-Service-Indikator nach Tageswechsel zeigt Nachschub-Bedarf wieder korrekt an.
- Personal-Softlock behoben: Unerreichbare Aufgaben werden ans Ende der Warteschlange geschoben.
- Cash-Sound der Bar wird beim Rauszoomen stummgeschaltet.

## Technische Aenderungen
- GuestManager.calculate_payout() als oeffentliche Funktion verfuegbar.
- Populate-Signatur von GuestCard um optionalen guest_mgr-Parameter erweitert.
