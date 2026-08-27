# Übergabeprotokoll

## Letzter Stand
In dieser Session haben wir tiefgreifende Bugfixes am Guest-Flow und Gastro-Loop vorgenommen:
1. **Trennung von is_open() und is_functional():** Basis-Räume trennen nun zwischen reiner Uhrzeit-Öffnung und Personal-Verfügbarkeit. 
2. **Bar Solo vs. Gastro-Loop:** Die Bar unterscheidet nun sauber zwischen Solo-Modus (nur Barkeeper) und Gastro-Loop (Barkeeper + Bedienung). Echte Tisch-Bestellungen à la carte gibt es *nur*, wenn beide da sind. Fehlt die Bedienung, läuft der Solo-Modus (Gäste holen sich Getränke direkt am Tresen und zahlen sofort pauschalen Eintritt).
3. **POI Warteschleifen:** Gäste betreten Räume nicht mehr blind und fliegen sofort raus, wenn Personal fehlt. Stattdessen warten sie beim Menu-Studieren eine Konstante (POI_WAIT_TIME_MINUTES = 3) in GuestActor.gd (als int, konform zum float-less Design; aktuell noch TODO für die Settings). Nach Ablauf greifen Fallbacks (z.B. Solo-Modus in der Bar).
4. **Food-Timeout:** Wenn der Gast erfolgreich an einem Tisch bestellt, das Essen aber (z.B. wegen Waiter-Pause) nicht geliefert wird, greift nun ein Timeout-Timer (FOOD_WAIT_TIME_MINUTES = 45). Danach storniert der Gast die Bestellung wütend (-15 Satisfaction) und verlässt den Platz.
5. **Order-Cancellation:** GastroManager.cancel_order() wurde hinzugefügt und in release_interaction von RestaurantSmall.gd und Bar.gd eingebunden.

## Bearbeitete Systeme
- scenes/ingame/guest/GuestActor.gd (State-Machine WAITING_FOR_FOOD, STUDYING_MENU)
- scenes/ingame/rooms/Room.gd (Base class is_functional)
- scenes/ingame/rooms/bar/Bar.gd (Solo-Modus Fallback, is_functional Override)
- scenes/ingame/rooms/restaurant_small/RestaurantSmall.gd (Order cancellation)
- autoload/GastroManager.gd (Cancellation Endpoint)

## Nächste Schritte
- Die int-Konstanten POI_WAIT_TIME_MINUTES (3) und FOOD_WAIT_TIME_MINUTES (45) in GuestActor.gd sollten ins globale Settings-Menü ausgelagert werden, damit der Spieler die Toleranzgrenze seiner Gäste manipulieren kann (entsprechende TODO-Kommentare existieren).
- Den Gastro-Loop ausgiebig im laufenden Spiel mit Personal-Pausen testen.
- Offene Punkte aus dem wiki/alpha_backlog.md bearbeiten.
