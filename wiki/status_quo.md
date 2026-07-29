# Status Quo - HO·MA·SIM Godot

## 1. Aktueller Stand (Architektur & Core-Features)
*   **Version:** Alpha v0.1.49 (Branch: `dev`)
*   **Game-Loop:** Funktioniert. Gäste kommen, mieten Zimmer, schlafen, gehen zu POIs (Restaurant, Bar, Lobby) und checken wieder aus.
*   **Personal-System:** Funktioniert. Personal hat Schichten, wird müde, nutzt Personalräume zur Erholung (Moral-System aktiv). Zuweisung zu POIs (Küche, Bar, Restaurant) klappt.
*   **Gastro-System:** Kompletter Loop intakt (Küche nimmt Bestellungen an, Koch kocht, Bedienung liefert ans Restaurant/die Bar, Gäste essen und zahlen).
*   **Wirtschaft:** Einnahmen (Gäste, Gastro) und Ausgaben (Gehalt, Baukosten) laufen stabil über den `FinanceManager`.

## 2. Bekannte "Baustellen" (Works in Progress)
*   **Lobby / Pathfinding (TOP URGENT - ANG-327):** 
    *   *Problem:* Das 16x16 globale Navigations-Grid kollidiert stark mit der Inneneinrichtung der Lobby (Tische, Automaten).
    *   *Lösung:* Die Lobby muss aus dem `MapGrid` ausgegliedert und wie ein normales Zimmer mit eigenem lokalem `RoomNavigator` ausgestattet werden. Das ermöglicht pixelgenaues Pathfinding im Raum.
*   **Gäste-Verhalten (Wegfindung):**
    *   Gäste nutzen nun korrekt die Lobby-Türen zum Warten (inklusive Scatter/Jitter-Effekt) und gehen beim Checkout über die Vordertür raus. Das Pathfinding innerhalb der Lobby und am Snack-Automaten wurde durch einen sauberen Übergang von `local_path_out` und `path_tiles` stark verbessert (Teleport-Bugs behoben).
*   **Techtree (Phase 4):**
    *   Die Freischalt-Knoten für Level 1-10 sind implementiert. Es fehlen noch die Inhalte für die Gourmet-Sterne, das Management und weitere Prestige-Events.
*   **Parzellen-System:**
    *   Der Kauf von neuen Parzellen (Expansion) ist voll funktionsfähig. Die Kosten steigen exponentiell an (4k, 8k, 16k...).
    *   Ein Level-Cap (Max Parzellen abhängig vom Hotel-Level) ist aktiv. Das HUD beim Bau der Parzellen nutzt nun saubere `.tscn` (Tooltip-Style) mit Camera-Zoom-Kompensation für gestochen scharfes Pixel-Rendering.

## 3. Direktiven & Workflow
*   **Linear-Tickets:** Keine neuen Features ohne Ticket!
*   **Changelog:** Nach jeder Session in `changelog/` protokollieren.
*   **Backlog:** `wiki/alpha_backlog.md` ist die Master-Liste der aktuellen Phase.
