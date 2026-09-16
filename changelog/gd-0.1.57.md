# Changelog v0.1.57

## Bugfixes & Polishing
- **DevConsole (Inspektor-Cheat):** Der Befehl `start-inspector` ignoriert nicht länger die Techtree-Voraussetzungen. Wer `G1.4` noch nicht erforscht hat, kann das Event nun auch nicht mehr per Cheat auslösen (verhindert das Erhalten illegaler Sterne in pre-Gourmet-Saves).
- **GuestManager (Wellness):** Der `W1.1` (Basis-Wellness) Bonus gibt nun die korrekten +5% Start-Zufriedenheit statt der alten Test-Einstellung von +10%, inkl. Hardcap bei 100%.
- **GuestManager (City Events):** Wenn ein `P1.1` Stadt-Event läuft, entstehen nun dynamisch 1-3 gleichzeitige Buchungen pro Welle (anstelle von fix 2-3). Das hält den Stress variabler und realistischer.

## Techtree & Feature Audit (Phase 4)
- Funktionaler Audit aller Phase 4 Nodes abgeschlossen.
- Bestätigt und verifiziert: `M1.4` (Konzern-Management) senkt Geduldsverlust korrekt. `P1.1` (Events) steuert Buchungs-Präferenzen korrekt. `P1.2` (Conference) funktioniert. `P1.3` (Prestige-Paket) schaltet VIPs frei. `W1.1`, `W1.2` und `W1.3` (Wellness/Pool/Spa) sind vollständig im Spiel.

- **Tutorials & Codex Update:**
  - Added new tutorials for the "Hotel Overview" (F9) and the "Data Overlays" (left HUD edge), including triggers to unlock them upon first use.
  - Rewrote the main HUD welcome tutorial description to match the new UI layout.
  - Added a Codex entry for the "Gourmet Inspector" which unlocks automatically after the first inspection report is delivered (instead of spoiling his arrival!).
  - Repaired translation string mapping for the VIP Codex entry, fixing a truncation bug in German and removing redundant titles.
- **Bugfix (Save/Load):**
  - Fixed a critical bug where Lobby upgrades (WLAN, Klima) were not saved. The Lobby is now correctly serialized into the plot's room data upon upgrade, and its existing instance gracefully receives the data upon reload instead of creating duplicates.
