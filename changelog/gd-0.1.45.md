# Changelog: HO·MA·SIM v0.1.45

**Datum:** 2026-07-28

In dieser Version wurde das Pathfinding innerhalb der Lobby und anderer POIs massiv verbessert. Gäste navigieren nun optisch sauber und nachvollziehbar zwischen Automaten, Tischen und den Raumausgängen. Zahlreiche Altlasten und Workarounds, die zu "Teleportations"-Fehlern geführt haben, wurden in diesem Zuge eliminiert.

## ✨ Neue Features & Architektur
- **Lobby-Architektur Rework (ANG-327):** Die Lobby wurde massiv umgebaut und ist nun kein abstrakter Bestandteil des `MapGrid` mehr. Stattdessen agiert sie ab sofort als vollwertige, eigenständige `Room`-Instanz, die von `Room.gd` erbt. Sie hat dadurch Zugriff auf alle Raum-Features, inklusive eines eigenen `RoomNavigator` für pixelgenaues Pathfinding im Raum (Ausweichen von Tischen, Stühlen und dem Snack-Automaten).

## 🐛 Bugfixes & Verbesserungen
- **GuestActor Wegfindung (Kollision in Räumen):** Ein Fehler wurde behoben, bei dem Gäste nach dem Beenden einer POI-Interaktion (z.B. am Snack-Automat) diagonal durch das gesamte Mobiliar liefen. Der `GuestActor` unterscheidet bei der Wegberechnung nun präzise, ob der nächste Schritt im selben Raum stattfindet (direkter Weg) oder den Raum verlässt (Weg zur Innentür).
- **GuestActor Wegfindung (Teleport-Bug 1):** Die Funktion `_walk_to_room` hat irrtümlich den physischen Koordinaten-Mittelpunkt des Gastes (der im globalen Raster als kollidierend markiert war) als Startpunkt der Heimreise verwendet, was zum Fehlschlag der Wegfindung und in der Folge zu einem "Notfall-Teleport" in den Flur führte. Die Funktion ruft nun korrekterweise `_get_logical_start_tile()` auf.
- **GuestActor Wegfindung (Teleport-Bug 2):** Ein alter Workaround aus der Zeit vor der lokalen Wegfindung, der Gäste bei Ablauf des POI-Timers manuell auf das Tür-Tile teleportiert und ihr "Gedächtnis" (welches POI sie gerade besucht haben) gelöscht hat, wurde restlos entfernt. Die neue, dynamische Wegfindung generiert stattdessen einen sauberen animierten Weg aus dem POI heraus zur Tür.
- **Fehlerhaftes Lobby-Tür-Target:** Der Ziel-Tile der Lobby wurde in `Lobby.gd` (`get_target_tile`) so korrigiert, dass er nicht mehr "Out of Bounds" auf der ungenutzten Straßen-Parzelle liegt, sondern konsistent auf die Innentür im Flur verweist.
- **Absturz bei Tastendruck (Dev-Keys):** Ein verbliebener Entwickler-Hotkey für `dev_reload` auf der F5-Taste wurde entfernt, da er ohne definierte InputMap zum sofortigen Spielabsturz führte, sobald irgendeine Taste gedrückt wurde.
- **MapGrid Debug-Linien:** Das Einzeichnen von erfolgreichen Wegfindungspfaden (`_debug_paths`) im `MapGrid` wurde reaktiviert, sodass rote Linien nun den geplanten Weg visualisieren.
