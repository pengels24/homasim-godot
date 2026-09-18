# Übergabeprotokoll: HO·MA·SIM Alpha (Branch: dev)

## Letzter Stand (v0.1.59)
- **Erledigt in dieser Session:**
  - Parzellen-Bau-Timer Bug gefixt (Timer wurden beim Savegame Restore fälschlicherweise auf 720 Minuten blockiert, Wände wurden nicht neu generiert).
  - Hardcoded Toast-String ("xxx wütend abgereist") durch `GameState.T("toast.guest.angry_leave")` inkl. `%s` in `language.csv` ersetzt.
  - Neues Feature: Animierter Schraffur-Shader (`construction_hatch.gdshader`) für Parzellen, die sich im Bau befinden.

- **Was GERADE untersucht wird (Offener Bug):**
  - **Der Koch (Küche) und der Barkeeper (Bar) gehen nach Schließung (22:00 bzw. 23:30) NICHT mehr in den Personalraum.**
  - Sie bleiben in den geschlossenen Räumen stehen.
  - Das hat laut User in der Vergangenheit funktioniert und ist nun kaputt.
  - WICHTIG: Der User hat explizit angewiesen, **NICHT** mit "GastroManager.active_orders (Geisterbestellungen)" oder "Savegames" zu argumentieren. Der Bug liegt im Ablauf ab dem Punkt "POI schließt".
  - Vermutung: Pathfinding/AStar-Logic für StaffActor (evtl. in `_is_shift_over` oder `_process_idle`), bzw. die Evaluierung von `is_night` für Backend-Räume wie die Küche (die keine harten `open_to`-Zeiten im JSON haben).

## Sofortige nächste Schritte
1. Lies den Code von `StaffActor.gd`, insb. `_is_shift_over()` und `_process_idle()`.
2. Finde heraus, warum der Pathfinding-Fallback (Lobby) oder das reguläre Staff-Room Pathing fehlschlägt oder warum `is_night` nicht korrekt ausgelöst wird.
3. Behebe den Logikfehler, damit Koch und Barkeeper nach Schichtende wieder in den Personalraum laufen.