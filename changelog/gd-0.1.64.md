# Changelog v0.1.64

## Bugfixes & Improvements
- **Checkout-Flow nach Savegame-Load gefixt:** Abreisende Gäste (`_checkout`-Liste) erhalten nun beim Spawnen (`GuestController`) bedingungslos ein `start_checkout()`, anstatt den eingefrorenen `State.SLEEPING` aus dem Savegame zu laden. Dadurch wandern sie ordnungsgemäß aus dem Hotel ab, anstatt im `IN_ROOM`-State steckenzubleiben und für Chaos zu sorgen.
- **Wachwerd-Phase (06:00 - 06:15) korrigiert:** Gäste, die sich zu Tagesbeginn noch im Bett befinden, bleiben nun für 15 Minuten im `IN_ROOM` bzw. `SLEEPING` Zustand und rennen nicht sofort los, um POIs zu blockieren.
- **Hunger-Toleranzen optimiert:** Hungerschwelle bei Konferenz-Pausen und am Abreisetag (Total Stay = 0) flexibler gestaltet, um Frustration (Teardrop-Icon) zu verringern.
- **Code-Bereinigung (Warnungen):** Diverse Godot-Warnungen behoben:
  - Float/Int Typ-Mismatches in ternären Operatoren (`TimeManager.SECONDS_PER_GAME_MINUTE`) durch `float()`-Casts repariert.
  - Redundante Scope-Deklarationen (`party`, `is_event_guest`) in `GuestActor.gd` korrigiert.
  - Unbenutzte Debug-Variablen (`g_name`, `poi_info`) entfernt.
  - Signal-Warnung (`sig_settings_changed`) in `SettingsManager.gd` durch Wrapper-Methode behoben.
