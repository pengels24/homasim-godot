# Changelog v0.1.49 (2026-07-29)

## Features
- **ANG-332 (Linear Issue):** Ticket für "Weitere Parzelle möglich"-Belohnung im Level-Up Screen (ab Level 4, dann alle 2 Level) erstellt.

## UI & UX
- **Parzellen-Kauf-UI (Refactoring):** Die UI-Elemente für den Parzellen-Bau wurden aus dem Code in eine saubere `ParzelleBuildUI.tscn` ausgelagert, die sich architektonisch an den CustomTooltips orientiert (`PanelContainer`, eigene `StyleBoxFlat`, saubere Margins).
- **Camera-Zoom-Kompensation:** Ein Rendering-Fehler bei herausgezoomter Kamera (`zoom = 0.33`) wurde behoben, indem das Parzellen-UI über einen `CenterContainer` per `scale = Vector2(3,3)` um den Faktor 3 hochskaliert wird. Dadurch wird das UI auf dem Bildschirm exakt in nativer Auflösung (1:1) gerendert, wodurch die Pixel-Font scharf und unverwaschen bleibt.
- **Kamera-Zentrierung:** Beim Verlassen des Parzellenkauf-Modus zentriert sich die Kamera nun automatisch wieder über der Eingangsparzelle (`center_on_entry()`), identisch zum Verhalten der HOME-Taste.

## Fixes
- **Lokalisierung (language.csv):** Fehlende Sprach-Keys für den Parzellenkauf (`tx.plot_buy`, `ui.confirm.plot_buy_title`, `ui.confirm.plot_buy_desc`) hinzugefügt, wodurch `%s`-Formatierungsfehler im `FinanceManager` und Bestätigungs-Modal behoben wurden.
- **Floating Values:** Der rote negative Floating Value wird nun nach einem erfolgreichen Parzellen-Kauf korrekt über dem Mauszeiger eingeblendet.
