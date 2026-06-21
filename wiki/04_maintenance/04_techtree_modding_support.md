# HO·MA·SIM – Techtree Architektur (Modding-Zusatz)

_Zusatzdokument: Externe Datenstruktur & Mod-Support_ 
_Stand: 15.06.2026_

## 1. Datenarchitektur: Core vs. Mod

Der Techtree ist vollständig datengetrieben. Die Knotenpunkte werden beim Spielstart aus der `TechRegistry` generiert.

- **Core-Daten (`is_core: true`):** Die Basis-Items des Hauptspiels.
- **Mod-Daten (`is_core: false`):** Externe JSON-Dateien aus Mod-Paketen.

## 2. Struktur einer externen Techtree-JSON (`tech.json`)

Mods können sich nahtlos in den bestehenden Techtree einklinken, indem sie als `dependencies` (Voraussetzungen) bestehende Core-IDs oder eigene Mod-IDs angeben.

**Beispiel-JSON (Mod):**

```json
{
  "mod_id": "my_spa_expansion",
  "tech_items": [
    {
      "id": "W_MOD_YOGA_1",
      "name": "Yoga-Studio",
      "category": "wellness",
      "tier": 2,
      "cost_fp": 350,
      "dependencies": ["W1.1"], 
      "unlocks": [
        "room_yoga_studio",
        "staff_yoga_instructor"
      ]
    }
  ]
}
```

_Hinweis: Im Beispiel nutzt die Mod die Core-ID `W1.1` (Fitnessstudio) als Voraussetzung. Der neue Knoten wird im UI also nach dem Fitnessstudio angehängt._

## 3. Systemverhalten & Rendering

1. **Dynamisches Rendering:** Das UI zeichnet Techtree-Bahnen dynamisch basierend auf der Eigenschaft `category`. Existiert die Kategorie bereits (z.B. `wellness`), wird das Mod-Item dort eingereiht. Ist es eine neue Kategorie, entsteht eine neue, zusätzliche Bahn.
2. **Verwaiste Knoten (Orphan-Check):** Wenn eine Mod als Dependency eine ID angibt, die weder im Core noch in anderen aktiven Mods existiert, wird das Item vom System ausgeblendet, um Dead-Ends zu vermeiden.
3. **Savegame-Sicherheit:** Wird eine Mod deinstalliert, verbleiben die erforschten Mod-IDs als "Ghost-Data" im Savegame-Array `unlocked_techs`, haben aber keine Auswirkungen mehr auf das UI oder das Bausystem (Crash-Prävention).
