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

## Translation & UI (Session Fortführung)
- **Settings:** Fehlende Übersetzungen im Tab "Gameplay" (Mehrfachbau) ergänzt.
- **Settings:** Audio "Door Sounds" in Übersetzung aufgenommen.
- **Controls:** Die Tastenbelegung im "User Interface"-Tab wurde nach F-Tasten (F1-F10) sortiert; das Build Menu wurde thematisch korrekt in den Bereich "Build Mode" verschoben.
- **Übersetzungs-Audit:** Weitere hartkodierte Strings in Dashboard, HUD und den Demo-End-Screens durch GameState.T-Aufrufe ersetzt.
- **Disclaimer:** Eine persönliche Signatur ("Peter aka Angelus2010") wurde dem Pre-Alpha Disclaimer hinzugefügt.
- **Bugfix (Translation):** Einen Encoding-Fehler (PowerShell-Artefakte) in der language.csv korrigiert, der das Laden neuer Strings in Godot blockiert hatte.

## Translation & Bugfixes (Current Session)
- **UI & Tooltips:** Added translations for guest needs in PIP monitors, CustomTooltips ("Anwesende Mitarbeiter").
- **POI/Rooms:** Fixed hardcoded "Gast" and "Wartet" strings in Lobby and Bar.
- **Conference Room:** Fixed fallback "Gast" string to use proper translation key.
- **Bugfix (Kitchen):** Fixed a bug in `KitchenSmall.gd` where guest names for cooking orders were always displayed as "Gast" because of an invalid property access. Kitchen Live Monitor now correctly shows the guest's name.
- **Build Mode / Demolish:** Converted hardcoded German confirm dialogs and toasts for room demolition into proper translation keys in `DemolishCursor.gd` and added them to `language.csv`.
- **Build Mode / Plots:** Validated that the Plot Purchase UI and dialogs are fully utilizing the translation system.
