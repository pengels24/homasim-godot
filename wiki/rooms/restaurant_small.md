# Raum: Restaurant (Klein)

## 1. Identifikation
*   **ID:** `restaurant_small`
*   **Kategorie:** G1.3
*   **Grid-Size:** Mittel

## 2. Spielmechanik
Speisesaal. Gäste setzen sich, Kellner nimmt Bestellung auf, läuft in Küche, bringt Essen. Ohne Küche funktionslos! Öffnungszeiten: 07:00 - 22:00.

## 3. Technische Umsetzung & Scripting
*   **Scene:** `scenes/ingame/rooms/restaurant_small/Restaurant_Small.tscn`
*   **Script:** `scenes/ingame/rooms/restaurant_small/RestaurantSmall.gd`

### 3.1 Besonderheiten
*   **Gäste-Navigation:** Gäste teleportieren nicht mehr an ihre Plätze, sondern nutzen `Room.get_local_path()` und das `AStar2D`-Netzwerk, um (animiert über Tweens) um Hindernisse (NavBlockers) herum zum zugewiesenen Platz zu laufen. Ein `call_deferred` beim State-Wechsel (`GuestActor`) verhindert Tween-Konflikte (unsichtbar/teleport).
*   **Kellner-Patrouille:** Das Personal (Bedienung) sucht in `get_waiter_stand_pos()` nach einem `ServicePoint`-Marker (bzw. greift auf die rotierte Raummitte zurück) und wählt von dort Ziele in einem Radius von 12 Pixeln. Über `get_random_walkable_local_pos()` wird garantiert, dass diese Ziele innerhalb des befahrbaren `AStar2D`-Netzes liegen, wodurch das Laufen durch Wände und Möbel (`NavBlockers`) verhindert wird.
