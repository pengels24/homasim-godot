# Übergabe-Protokoll – 08.09.2026 (Session Ende, Nachmittag)

## Was wurde heute gemacht?

### Morgen: Wellness-Overhaul (Pool/Gym/Spa) – siehe auch Changelog
- Session-Timer-Reset, Doppelbelegung, Sofort-Wechsel, Gast-bleibt-im-Raum: alle behoben
- Cooldown-System in Pool/Gym/Spa implementiert
- Live-Monitor: Badet/Entspannt (Pool), Liegt/Entspannt (Spa), Geht gleich, Sortierung

### Nachmittag: Tests & Fixes

**Erfolgreich getestet (alle grün):**
- Bar Gastro-Flow (Studiert → Küche → Serviert → Trinkt) ✅
- Restaurant Gastro-Flow (identisch, teilt Küche korrekt) ✅
- Küche (beliefert Bar + Restaurant parallel) ✅
- Zimmer DZ (Check-in, Wander/Schlafen, Checkout ohne Ghost-Walking) ✅
- Personalraum (Smart Room API korrekt, Legacy Staff-API bewusst erhalten) ✅

**Implementiert:**
- **Check-in POI-Sperre (60 Ingame-Min):** Gäste bleiben nach Check-in 60 Min im Zimmer
  - `start_checkin()` setzt `_checkin_poi_block_until = now + 60`
  - `_decide_next_action()` cleared `open_pois` solange Sperre aktiv
  - Bug behoben: War fälschlich in `setup()` → alle geladenen Gäste bekamen Sperre beim Spielstart
- **Autosave ignoriert Setting:**
  - `_on_timed_autosave()`: Guard `if not SettingsManager.autosave_enabled: return`
  - `_on_day_ended()`: Guard hinzugefügt
  - `sig_settings_changed` neu in SettingsManager + IngameSaveController stoppt/startet Timer live

**Linear:**
- ANG-343 angelegt: StaffActor Smart-Room-Unification (Prio: Medium)
  StaffActor nutzt noch Legacy `claim_seat/leave_seat/has_free_seat` + hardcoded `"staff_small"` String.
  Refactoring analog GuestActor v0.1.50 – vor dem nächsten neuen Staff-Raum-Typ.

## Sofortige nächste Schritte (morgen)

### 1. Konferenz testen (PRIORITÄT)
- Speaker-Swap nach ~15 Min (prüfen ob nach dem SITTING-Fix stabil)
- Zuhörer-Zucken (soll weg sein seit SITTING-Fix)
- Mittagspause: TG-Gäste gehen in Restaurant/Bar → Rückkehr
- End of Day: 50% direkt nach Hause, 50% noch Gastro

### 2. ANG-340: [Space] kollabiert fokussierten Live-Monitor
- Niedrige Prio aber störend beim Testen

## Architektur-Wissen (wichtig!)

### GuestActor
- `_action_timer = 0.0` NIEMALS von außen setzen (L212 Guard friert Gast ein)
- `_checkin_poi_block_until` = 0 bedeutet kein Block aktiv
- `start_checkin()` für Neuankömmlinge, `setup()` für Save-Load → unterschiedliche Initialisierung

### IngameSaveController
- `_autosave_timer` (Timer-Referenz gespeichert) → `_setup_autosave_timer()` kann ihn stoppen/ersetzen
- `sig_settings_changed` von SettingsManager → live Reaktion auf Setting-Änderung

### Wellness-Räume
- Session-Ende ≠ Spot-Wechsel: `release_interaction()` unterscheidet intern
- `is_guest_allowed()` = Cooldown-Check (60 Min nach Session-Ende)
- Alle drei Räume: `_guest_session_end[id]` + `_guest_cooldown_end[id]`

## Relevante Dateien

- `scenes/ingame/guest/GuestActor.gd` – `start_checkin()` POI-Block, `_decide_next_action()` Block-Check
- `scenes/ingame/scripts/managers/IngameSaveController.gd` – Autosave-Fix, Timer-Management
- `autoload/SettingsManager.gd` – `sig_settings_changed` Signal (neu)
- `scenes/ingame/hud/modals/content/ModalContentSettings.gd` – Signal-Emit in `_on_autosave_changed()`
- `scenes/ingame/rooms/pool_small/PoolSmall.gd` – Cooldown-System, Live-Monitor
- `scenes/ingame/rooms/gym_small/GymSmall.gd` – Cooldown-System, Live-Monitor
- `scenes/ingame/rooms/spa_small/SpaSmall.gd` – Cooldown-System, Alternation, Live-Monitor
