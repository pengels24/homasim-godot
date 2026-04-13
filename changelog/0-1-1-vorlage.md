## Version: 0.1.21
**Datum: 2026-04-12**

### Features & Verbesserungen
- **ANG-131** – Zimmer-Aufpreis Dialog: State-Machine-Mechanik im Check-In-Flow. Gast in Nicht-Präferenz-Zimmer → Button wechselt zu "Aufpreis – Gast fragen" → Würfelwurf basierend auf `patience`-Wert → akzeptiert (Check-In) oder abgelehnt ("Anderes Zimmer wählen"). Kein Dialog-Popup – alles über Button-Status sichtbar.
- **Checkout-Abrechnung** – Einnahmen pro Aufenthalt: `price_per_night × stay_duration`. Kontostand im HUD wird sofort nach Checkout aktualisiert. Einnahmen im Checkout-Log-Eintrag sichtbar.
- **Checkout-Karte UI** – Zimmernummer + Einnahmen ("Zimmer Z028 · 360 €") + Satisfaction-Smiley auf der Checkout-Kachel in der Rezeption.
- **"Zahlt mehr"-Badge** – Aktive Gäste in Nicht-Präferenz-Zimmern zeigen ein goldenes `circle-dollar-sign`-Icon im Namen. Tooltip beim Hover auf der Kachel erklärt den Aufpreis.
- **Tagesabschluss-Finanzen (reload-sicher)** – `daily_income`, `daily_checkins`, `daily_checkouts` werden direkt bei jeder Aktion in der DB akkumuliert (`checkOutGuest` / `checkInGuest`). Reset in `prepareDayEnd()`. Unabhängig vom Autosave-Intervall, überlebt jeden Seitenreload.
- **Ruf-Leiste Tooltip** – Hover auf der Reputationsleiste im HUD zeigt "x / 1000" als Tooltip. Wert wird bei jedem JS-Update mitgepflegt. Cursor wechselt zu Pointer.
- **Log-Filter** – Checkout-Einträge erscheinen jetzt unter dem "Gäste"-Tab (zusätzlich zu "Alle").
- **ANG-134** – FastForward: Pause-Button stoppt die Zeit sofort auch während FF aktiv ist. FF wird automatisch deaktiviert.
- **ANG-135** – Kachel-Puls in der Rezeption respektiert jetzt den konfigurierten Settings-Timeout. Neuer Wert "Immer" im Slider ergänzt.
- **ANG-128** – Level-Up Modal zeigt ab Level 6 wieder korrekte Freischaltungen.
- **Michelin-Konzept-Doc** – `docs/wiki/HO-MA-SIM_Michelin_Konzept.md` erstellt: 3 Sterne als Tier-Gate, 5 Kriterien je Stufe (Satisfaction, Ruf, Ausstattung, Personal, Konsistenz). Basis für Techtree-Redesign (ANG-105/106).

### Bugfixes
- **ANG-136** – Gast mit `type=group` und 0 Nächten in Warteliste trotz deaktiviertem Gasttyp vollständig behoben. `rand(null, null)` in `spawnGuest()` abgefangen, ungültige Typen werden konsequent übersprungen.
- **ANG-137** – Grid zeigt Zimmer von `ready_for_checkout`-Gästen nicht mehr als frei (grün). Korrekt: gelber Indikator solange `room_id` gesetzt.
- **ANG-133** – Gäste-Spawn zählt `ready_for_checkout`-Zimmer nicht mehr als belegt → Warteliste füllt sich korrekt auch wenn viele Gäste auf Checkout warten.
- **Dev Console Fix** – Doppelte Instanz durch zweifache `new DevConsole()`-Initialisierung behoben (einmal in `main.js`, einmal in `grid.php`). X-Button benötigte dadurch zwei Klicks zum Schließen. Überflüssige Instanz in `grid.php` entfernt.
- **Bottom HUD Opacity** – `main-action-bar` war zu transparent. `background: rgba(15, 23, 42, 0.92)` + `box-shadow` gesetzt.

### Neue Migrations-Dateien
- `add_daily_stats.sql` – Spalten `daily_income`, `daily_checkins`, `daily_checkouts INT DEFAULT 0` in `hotels`-Tabelle.

### Einstellungen
- **Autosave-Intervall** – Maximum von 30 Min. auf 15 Min. gesenkt. Neue Abstufung: 5 / 10 / 15 Min.

### Neue Backlog-Issues
- **ANG-138** – concept: Zimmer-Attribute & Gast-Wünsche System (near_exit, has_window, has_desk, etc.)
- **ANG-139** – feat: Game-Event – Der anonyme Michelin-Inspektor
- **ANG-140** – feat: In-Game-Postfach (Mailsystem)
- **ANG-141** – feat: Online-Buchungssystem & eigene Hotelwebseite (hotelbooking.sim)
- **ANG-142** – feat: In-Game Browser – Simuliertes Webbrowser-Modal (.sim-Seiten per Techtree freigeschaltet)
