# Übergabeprotokoll (Ende v0.2.2 Session)

**Letzter Stand:**
- Das Spielversion wurde auf **v0.2.2** angehoben.
- Ein vollumfänglicher Test und Bugfixing-Lauf für das Ingame-Tutorial wurde durchgeführt.
- Das Tutorial (Savegame -2) sollte nun extrem robust laufen, da viele Edge-Cases (Hotkeys, unpräzise Ghosts, fehlerhaft positionierte Blaupausen) behoben wurden.

**Was wurde gemacht:**
1. **TutorialScenarioManager.gd:** 
   - Kamerabewegung (Step 2) misst nun exakte *Zeit* (5s), egal ob per Hotkey oder Maus.
   - Kamerazoom (Step 3) fordert nun das Erreichen beider Extreme (0.5 und 4.0) via Bitmask.
   - Rezeption öffnen (Step 15) fragt im `_process` kontinuierlich den State von `bottom.reception.button_pressed` ab, sodass auch Öffnungen per Hotkey (F1) sofort getriggert werden.
   - Personalraum-Bau (Step 21) nutzt nun eine eigene Variable `_target_door_offset`, um die Blaupause (`_draw_blueprint`) exakt mit der gewünschten Tür-Position (rechts unten, `offset = 1`, `rot = 2`) anzuzeigen. Der Assistent wurde nach rechts verschoben (`_slide_assistant(true)`).
2. **BuildCursor.gd:** 
   - Die restriktive "Ghost wird nur grün auf dem perfekten Spot"-Logik greift nun auch in Step 21. 
   - Sie prüft nicht mehr nur Raum-Koordinaten und -Rotation, sondern auch zwingend `door_rotation` und `door_offset`, sodass der Spieler die Tür exakt wie auf der Blaupause platzieren MUSS.
3. **Texte / Loca:**
   - Kategorie für Personalraum im Tutorial auf "Management" statt "Dienstleistung" geändert.
   - Zusatzhinweis zum Vorspulen der Zeit in Step 10 hinzugefügt.
   - Der grüne Tür-Indikator ist zu 50% transparent und permanent am Bau-Cursor aktiv.

**Sofortige nächste Schritte (für den neuen Agenten):**
- Das Tutorial ist fertiggestellt und gefixt. Der nächste Agent sollte den Nutzer fragen, ob weitere Bugfixes für v0.2.2 nötig sind oder ob mit neuen Features aus dem Alpha-Backlog (z.B. ANG-364 Pathfinding-Rework oder Personalflure) begonnen werden soll.
- Der Nutzer hatte erwähnt, dass evt. noch kleine Fixes für v0.2.1/v0.2.2 offen sein könnten. Bitte im Chat anknüpfen!