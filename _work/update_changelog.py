import os

file_path = "changelog/gd-0.1.50.md"
content = """
### 01.09.2026 - Pathfinding Fixes, Quests & UI Tooltips
- **Pathfinding Fix (Ghost Walking):** Behoben, dass Gäste bei der Abreise (`start_checkout`) geradlinig durch Wände vom Bett zur Tür liefen. Das Problem lag daran, dass `_current_poi_id` auf `"lobby"` gesetzt wurde, bevor der Pfad berechnet wurde. Dadurch dachte das Spiel, der Gast sei bereits in der Lobby und übersprang die Berechnung des lokalen Weges aus dem Hotelzimmer heraus.
- **Quest-Tracking (POI-Nutzung):** Die Methode `QuestManager.on_poi_used` wurde zwar definiert, aber von `GuestActor` nie aufgerufen. Gäste informieren nun den QuestManager, wenn sie an einem POI eintreffen, sodass Quests wie "Kühles Nass" oder "Aufwärmen" korrekt hochzählen.
- **Quest-Tracking (Wildcards):** Fix im `QuestManager._increment_quest_progress`, damit generische Quests (ohne festes Ziel, d.h. `target_id == ""`), korrekt hochzählen. Die Prüfung vergleicht nun sauber, ob die Quest-Definition überhaupt ein `target_id` vorgibt.
- **Konferenzraum-Quest (Benötigt Forschung):** Die Quest zum Bau des Konferenzraums in `quests.json` setzte fälschlicherweise noch die veraltete Forschung `"B1.1"` voraus. Da dieser Knoten nicht mehr existiert, stockte der Quest-Fortschritt (und zeigte "Benötigt Forschung: ???"). Dies wurde auf den korrekten Knoten `"P1.2"` aktualisiert.
- **Staff-Raum Kapazität:** Fix in `StaffSmall.gd`. Die `has_free_seat` Methode liest die Kapazität nun korrekt aus der Definition aus, was Clipping-Probleme in vollen Pausenräumen verhindert.
- **Raum-Tooltips (UI):** Tooltips (`CustomTooltip.gd`) bereinigt: Bei Räumen ohne Personalbedarf (`min_staff == 0`) verschwindet der Eintrag "Anwesende Mitarbeiter: 0" nun komplett (sofern kein Putzpersonal o.ä. anwesend ist). Räume, die nicht für Gäste gedacht sind (z.B. Küche, `is_guest_poi == false`), zeigen keinen Platzhalter mehr für anwesende Gäste an.
"""

with open(file_path, "a", encoding="utf-8") as f:
    f.write(content)
print("Changelog updated.")
