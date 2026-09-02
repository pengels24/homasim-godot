# Übergabeprotokoll

**Datum:** 01.09.2026
**Version:** v0.1.50

## Letzter Stand
Der User musste die Session wegen seines RL-Jobs beenden. Wir haben mehrere Fehler im `dev` Branch repariert. Der Stand ist nun sauber kompiliert und committed. 

## Bearbeitete Systeme & Bugfixes
- **Pathfinding / GuestActor:** Wenn Gäste abgereist sind (`start_checkout`), liefen sie als Geister durch die Wände ihres Hotelzimmers, weil die `_current_poi_id` fälschlicherweise *vor* der Generierung des Raumpfades auf "lobby" gesetzt wurde. Dies wurde gefixt.
- **QuestManager:** Gäste haben bisher nie das Signal `QuestManager.on_poi_used` beim Eintreffen am POI gesendet. Wir haben das Signal in `GuestActor._on_poi_arrived` integriert. Generische Quests (mit leerem `target_id`) zählen nun ebenfalls korrekt hoch, da der Bug in der Wildcard-Validierung (`_increment_quest_progress`) behoben wurde.
- **Quests Definition:** In `quests.json` wurde das Requirement für den Konferenzraum von der veralteten Forschung `B1.1` auf den korrekten Knoten `P1.2` angepasst.
- **Staff-Raum Kapazität:** Die Berechnung für `has_free_seat()` in `StaffSmall.gd` war kaputt und wurde auf `get_definition("capacity")` repariert.
- **UI / Tooltips:** `CustomTooltip.gd` bereinigt. Bei Räumen mit `min_staff == 0` (z.B. Gästeräume) wird nicht länger "Anwesende Mitarbeiter: 0" angezeigt. Ebenfalls wird bei Räumen mit `is_guest_poi: false` (z.B. Küche) kein Gästezähler mehr im Tooltip gerendert.

## Sofortige nächste Schritte
- Keine brennenden Hotfixes mehr offen aus dieser Session. Der User kann bei der Rückkehr ganz normal mit seinem Spiel-Testing fortfahren.
- Falls Probleme im Quest-Tracking (POI-Benutzung) auftauchen, in `QuestManager.gd` und `GuestActor.gd` nachschauen.
- `update_doku` Skill wurde ausgeführt, Changelog ist aktuell, Backlog up to date und der Code ist in Git (core) gesichert.
