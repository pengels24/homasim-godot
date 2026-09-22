# Übergabeprotokoll (Session: v0.1.66)
**Datum:** 21.09.2026

## 1. Letzter Stand & Bearbeitete Systeme
- **GuestActor (Gäste-Verhalten):** Wir haben den massiven `GuestActor`-Codeblock, insbesondere die `_wander_in_room()`-Logik überarbeitet. Das synchrone, künstliche Wandern im exakten 15-Minuten-Takt wurde durch ein individuelles `_my_wander_interval` (4-10 Min) pro Gast ersetzt, das in `setup()` generiert wird.
- **Aufwach-Verhalten (Staggered Wake-Up):** Ähnlich wie beim Wandern wachen Gäste nun abhängig von einem zufälligen `_my_wake_up_time` Offset auf, um Auslastungsspitzen (alle um Punkt 06:15) zu verhindern.
- **Klickbarkeit (Lobby):** Ein großes Problem war, dass Gäste in der Lobby nicht angeklickt werden konnten, um das PiP-Fenster zu öffnen. Das lag an einem hardcodierten `input_pickable = false` im Status `AWAITING_CHECKOUT`. Dies wurde auf `true` geändert und die `priority` der `ClickArea` auf `100` gesetzt, um TileMap-Kollisionen zu überstimmen. Gäste können jetzt auch während der Wartezeit auf den Checkout ganz normal inspiziert werden.
- **POI-Sperre:** Gäste ignorieren Räume in ihrer `_get_open_pois()` Suche, deren Sauberkeit (`cleanliness`) oder Zustand (`condition`) unter 10 % gefallen ist. Die Tooltips (`CustomTooltip`, `RoomDetailsMonitor`) zeigen geschlossene POIs nun rot als "Geschlossen (Wartung/Reinigung)" an, statt grün "Offen".
- **Bugfix (Crash):** Ein fehlender Objekt-Zugriff (`GuestParty`) beim Öffnen des GuestPipMonitors auf Gäste im State `AWAITING_CHECKOUT` wurde durch sauberes Referenz-Checking gefixt.

## 2. Nächste Sofortige Schritte
- **HUD Event-Panel bleibt 2-zeilig:** Dies ist ein offener Fehler auf dem Backlog, der noch untersucht werden muss. Das Panel für Events schrumpft nach Abschluss eines Tagungs-Events nicht wieder in seine ursprüngliche Größe zurück. (Siehe ANG-362 etc. im Alpha-Backlog).
- **Inspektor & Gastronomie:** Peter wird weiter am Balancing arbeiten und testen, ob die gestaffelten Aufwach-Zeiten in der Gastronomie den "Mega-Rush" effektiv genug verhindern. Falls er dort erneut ansetzt, muss evtl. das `_my_wake_up_time` Delta in den `GuestDefinitions` weiter gestreckt werden.

## 3. Hinweis an den nächsten Agenten
- Alle Änderungen sind bereits committed (`v0.1.66`). 
- Die TechDoku für `GuestActor` (`wiki/02_features/25_techdoku_guestactor.md`) ist auf dem neuesten Stand.
- Denke daran, strikt die in `AGENTS.md` definierten Regeln zu befolgen (Keine Rezeptionisten einplanen, sauberes Event-Handling ohne Over-Engineering).