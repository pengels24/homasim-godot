# Changelog v0.1.44 (27.07.2026)

## Bugfixes & Wegfindung (Lobby & Gäste)
*   **Checkout-Bugfix:** Gäste despawnen nicht mehr sofort an der Zimmertür oder rennen quer durch geschlossene Wände, wenn sie zur Rezeption wollen.
*   **Lobby-Wände massiv gemacht:** Die Außenwände der Lobby wurden für das globale Pathfinding (AStarGrid2D) als massiv (`Solid`) markiert, damit Gäste nicht mehr querfeldein laufen, sondern brav außen um das Hotel herum gehen.
*   **Lobby-Türen geöffnet:** Sowohl die Haupteingangstür (zur Straße) als auch die inneren Durchgänge (zum Flur) wurden im Grid als passierbar markiert.
*   **Warteschlange beim Checkout:** Gäste warten nun *sichtbar* im inneren Bereich der Lobby auf den Checkout. Ein kleiner zufälliger Offset (Jitter) sorgt dafür, dass sich die Wartenden natürlich verteilen und nicht auf einem einzigen Pixel ineinander clippen.
*   **Lobby Tooltip Fix:** Der Tooltip der Lobby zählte bisher keine Gäste, die im Status `AWAITING_CHECKOUT` waren (zeigte "0 Gäste" an). Dieser Status wurde in `CustomTooltip.gd` ergänzt.

## Linear-Issue erstellt
*   **ANG-327 [Top Urgent]:** Lobby als echten Raum (RoomNavigator) umbauen. Das 16x16 Global-Grid kollidiert architektonisch mit feinen Innenraum-Routings (Tische, Automaten). Die Lobby muss analog zu den Gästezimmern aus der globalen Clearance gelöst und mit einem lokalen Pathfinding versehen werden.
