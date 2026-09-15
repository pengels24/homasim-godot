# Changelog v0.1.56 (Pre-Alpha)

## Features & Polishing
- **Migration System:** Altsystem-Spielstände (TechDemo) werden nun erkannt und der Spieler kann entscheiden ob diese behalten oder gelöscht werden sollen. Das Pre-Alpha-Savegame-System nutzt ab sofort einen eigenen Ordner (v2_hotels, v2_saves), um Konflikte zu vermeiden.
- **Hauptmenü:** "Pre-Alpha Info" Button im Hauptmenü unter "Tutorial" hinzugefügt, um den Disclaimer jederzeit manuell aufrufen zu können.

## Bugfixes & Tweaks
- **Demo-Ende:** Der Demo-Ende-Screen verarbeitet das Beenden per ESC / Outside-Click nun absolut fehlerfrei, wodurch der EXP-Freeze (für Stern 1) garantiert behoben ist.
- **Autosave:** Beim Schließen des Demo-Ende-Screens wird nun automatisch gespeichert.
- **Translation:** Audit durchgeführt und ca. 400 harte Strings im Code identifiziert, welche noch ins System (GameState.T) überführt werden müssen.

## Refactoring / Internal
- SaveManager verwendet nun konsequent die v2_-Präfixe für Ordner.
