# 🎯 Wie pflege ich Quests (Aufgaben)?

Das Quest-System ist kategorisiert nach Räumen/Features und Rängen (Tiers). Es wird über die `config/quests.json` und die Übersetzungs-Datei gesteuert.

## 1. Neue Quest anlegen
Öffne `config/quests.json`. Such dir die richtige Kategorie (z.B. `zimmer`) und den richtigen Rang (z.B. `1`) aus und füge im `targets`-Array einen Block hinzu:

```json
{
  "id": "q_build_pool_1",
  "name": "quest.pool.1.name",
  "description": "quest.pool.1.desc",
  "type": "build_room",
  "target_id": "pool",
  "target_count": 1,
  "reward_fp": 150,
  "reward_money": 1500,
  "requires_tech": "F2.1"
}
```
*Wichtig: Wenn eine Quest an den Techtree gebunden sein soll, trage bei `requires_tech` die Tech-Node ID ein. Wenn sie von Anfang an verfügbar sein soll, lass das Feld leer `""`.*

## 2. Texte übersetzen
Öffne `translations/de.csv` und ergänze:
```csv
"quest.pool.1.name","Pool-Party!",""
"quest.pool.1.desc","Baue deinen ersten Pool, um Gäste glücklich zu machen.",""
```

## 3. Fortschritt / Ränge
Jeder Rang (`1`, `2`, `3` etc.) hat auch nochmal eigene Abschluss-Belohnungen (`reward_fp` und `reward_money`), wenn ALLE Quests dieses Ranges erledigt wurden. Vergiss nicht, diese für neue Ränge anzupassen!
