# HO·MA·SIM Godot - Changelog v0.1.66

## 🐛 Bugfixes
- **GuestActor Crash Fix:** Behebung eines Absturzes beim Öffnen des GuestPipMonitors (Fehlerhafter Zugriff auf Zufriedenheits-Werte repariert).
- **Lobby Guest Clicks:** Gäste können nun in der Lobby problemlos angeklickt werden. `ClickArea` hat nun `priority = 100` und ist auch im Status `AWAITING_CHECKOUT` klickbar (zuvor wurde `input_pickable` auf `false` gesetzt).

## ✨ Features & Verbesserungen
- **POI-Sperre bei Verschmutzung:** Gäste betreten keine POIs mehr, wenn Sauberkeit oder Zustand unter 10 % sinken. 
- **Tooltip-Anpassung:** CustomTooltip und RoomDetailsMonitor zeigen geschlossene Räume wegen Reinigung/Wartung nun korrekt in rot als "Geschlossen (Wartung/Reinigung)" an (statt grün/offen).
- **Organisches Aufwachen:** Gäste wachen morgens nicht mehr zeitgleich auf, sondern haben individuelle `_my_wake_up_time` Offsets erhalten.
- **Asynchrones Zimmer-Wandern:** Die starren 15-Ingame-Minuten-Intervalle für Bewegungen innerhalb des Raumes wurden durch ein individuelles `_my_wander_interval` (4–10 Ingame-Minuten) ersetzt. Gäste wuseln nun natürlich und asynchron, anstatt sich im Gleichschritt zu bewegen.
