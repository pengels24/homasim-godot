# 🔬 Wie pflege ich den Techtree?

Der Techtree regelt, wann welche Räume oder Features freigeschaltet werden. Das System nutzt Grid-Positionen, um die UI-Linien automatisch zu zeichnen.

## 1. Neuen Forschungs-Knoten anlegen
Öffne `config/techtree.json`. Ein Eintrag besteht immer aus seiner ID (z.B. `Z1.1`) und seinen Daten.
```json
{
  "name_key": "techtree.zimmer.z11.name",
  "desc_key": "techtree.zimmer.z11.desc",
  "icon": "res://assets/UI/hud_build_item_button.aseprite",
  "grid_pos": [0, 0],
  "dependencies": [],
  "cost_fp": 1000,
  "category": "zimmer",
  "unlocks": ["bed_standard", "bed_double"]
}
```
* **grid_pos**: [X, Y]. X ist die Spalte (von links nach rechts), Y ist die Zeile (von oben nach unten).
* **dependencies**: Ein Array von IDs, die vorher erforscht sein müssen (z.B. `["Z1.1"]`).
* **unlocks**: Welche `room_id`s dadurch im Baumenü freigeschaltet werden (müssen mit den IDs aus `rooms.json` übereinstimmen).

## 2. Texte übersetzen
Öffne `translations/de.csv` und ergänze die Namen und Beschreibungen:
```csv
"techtree.zimmer.z11.name","Grundlegende Zimmer",""
"techtree.zimmer.z11.desc","Schaltet das Einzel- und Doppelzimmer frei.",""
```

## 3. Demo-Locking (Spezialfall für die Techdemo)
Wenn du einen Techtree-Knoten einbauen willst, den der Spieler zwar *sehen*, aber in der Demo *noch nicht freischalten* darf, setze in der `techtree.json` im entsprechenden Knoten:
```json
"demo_lock": true
```
Dann wird im Spiel ein "Nicht in der Demo verfügbar" Tooltip angezeigt und der Kaufen-Button bleibt grau!
