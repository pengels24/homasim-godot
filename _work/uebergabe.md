# Übergabeprotokoll

## Letzter Stand
In dieser Session haben wir tiefgreifende Bugfixes am Guest-Flow und Gastro-Loop vorgenommen:
1. **Trennung von is_open() und is_functional():** Basis-Räume trennen nun zwischen reiner Uhrzeit-Öffnung und Personal-Verfügbarkeit. Die Bar überschreibt is_functional() und fordert sowohl Bartender als auch Waiter, damit Bestellungen an Tischen möglich sind.
2. **POI Warteschleifen:** Gäste betreten Räume nicht mehr blind und fliegen sofort raus, wenn Personal fehlt. Stattdessen haben sie beim Menu-Studieren eine Wartezeit-Konstante (POI_WAIT_TIME_MINUTES = 3.0) in GuestActor.gd (aktuell noch TODO für die Settings). Nach Ablauf greifen Fallbacks (z.B. Solo-Modus in der Bar).
3. **Food-Timeout:** Wenn der Gast erfolgreich bestellt, das Essen aber (z.B. wegen Waiter-Pause) nicht kommt, läuft in WAITING_FOR_FOOD nun ein harter Timer (FOOD_WAIT_TIME_MINUTES = 45.0). Danach storniert der Gast die Bestellung wütend (-15 Satisfaction) und verlässt den Platz.
4. **Order-Cancellation:** GastroManager.cancel_order() wurde hinzugefügt und in release_interaction von RestaurantSmall.gd und Bar.gd eingebunden.

## Bearbeitete Systeme
- scenes/ingame/guest/GuestActor.gd (State-Machine WAITING_FOR_FOOD, STUDYING_MENU)
- scenes/ingame/rooms/Room.gd (Base class is_functional)
- scenes/ingame/rooms/bar/Bar.gd (Solo-Modus, is_functional Override)
- scenes/ingame/rooms/restaurant_small/RestaurantSmall.gd (Order cancellation)
- autoload/GastroManager.gd (Cancellation Endpoint)

## Nächste Schritte
- Die Konstanten POI_WAIT_TIME_MINUTES und FOOD_WAIT_TIME_MINUTES in GuestActor.gd sollten ins globale Settings-Menü ausgelagert werden, damit der Spieler die Toleranzgrenze seiner Gäste manipulieren kann (entsprechende TODO-Kommentare existieren).
- Den Gastro-Loop ausgiebig im laufenden Spiel mit Personal-Pausen testen.
- Offene Punkte aus dem wiki/alpha_backlog.md bearbeiten.
