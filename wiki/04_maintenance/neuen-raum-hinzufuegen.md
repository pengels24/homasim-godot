# Howto: Neuen Raumtyp hinzufügen

## Übersicht

Jeder Raum besteht aus drei Dateien:
- `MeinRaum.tscn` – das visuelle Layout (Wände, Tür, Floor, Möbel)
- `MeinRaum.gd` – die Logik (erbt von `Room.gd`)
- Ordner unter `scenes/ingame/rooms/mein_raum/`

**Zwei Raumtypen:**
- **Einfacher Raum** (z.B. EZ): eine Orientierung, Tür wandert per room_rotation → Vorlage: `bed_standard/`
- **Flip-Raum** (z.B. DZ): zwei Orientierungen (Landscape/Portrait) per F-Taste → Vorlage: `bed_double/`

---

## Schritt 1 – Ordner und Dateien anlegen

```
scenes/ingame/rooms/
└── mein_raum/
    ├── MeinRaum.tscn
    └── MeinRaum.gd
```

---

## Schritt 2 – Szenen-Struktur (.tscn)

### Einfacher Raum (EZ-Stil, N×M Tiles)

```
MeinRaum (Node2D) ← Script: MeinRaum.gd
├── Ground (Node2D)
│   ├── BaseFloor (Sprite2D)   ← GradientTexture1D, volle Raumgröße
│   ├── WallLeft  (Sprite2D)   ← position=(1, cy), rotation=PI
│   ├── WallRight (Sprite2D)   ← position=(w-1, cy)
│   ├── WallTop   (Sprite2D)   ← position=(cx, 1), rotation=-PI/2
│   └── WallBottom(Sprite2D)   ← position=(cx, h-1), rotation=PI/2
├── Interior (Node2D)           ← wird per room_rotation gedreht
│   ├── Floor (Sprite2D)        ← GradientTexture1D, Teppich/Boden-Farbe
│   └── Furniture (Node2D)      ← Möbel hier rein
└── Door (Sprite2D)             ← einzelner Tür-Sprite, per DOOR_CONFIGS positioniert
```

**Wandmaße** (alle Sprite2D mit GradientTexture1D, Textur-Breite=256px):
- Horizontale Wand (WallTop/Bottom): `scale = Vector2(0.008, room_width_px)`, rotiert
- Vertikale Wand (WallLeft/Right): `scale = Vector2(0.008, room_height_px)`
- Wand-Pixel = `scale.x * 256 ≈ 2px`

**Floor-Sprite** (GradientTexture1D, Textur=256px breit, 1px hoch):
- `scale.x = (room_width_px - 4) / 256` → 2px Abstand je Seite
- `scale.y = room_height_px - 4`
- `position = (cx, cy)` (Raummitte)

Für einen 2×2-Tile-Raum (32×32px): `scale=(0.109375, 28)`, `position=(16,16)` ✓

### Flip-Raum (DZ-Stil, Landscape/Portrait)

```
MeinRaum (Node2D) ← Script: MeinRaum.gd
├── Landscape (Node2D)          ← sichtbar wenn room_flip=0
│   ├── Ground (Node2D)         ← Wände für Landscape-Größe
│   ├── Interior (Node2D)       ← Floor + Möbel
│   └── Door (Node2D)           ← Container: Kinder = je eine Türposition (siehe unten)
├── Portrait (Node2D)           ← sichtbar wenn room_flip=1
│   ├── Ground (Node2D)
│   ├── Interior (Node2D)
│   └── Door (Node2D)           ← Container: Kinder = je eine Türposition
└── Door (Sprite2D)             ← Platzhalter solange Door-Sub-Baum fehlt
```

---

## Schritt 3 – Türpositionen (Slot-System)

Türpositionen werden **nicht mehr manuell als Pixel-Koordinaten** eingetragen.
`Room.gd` berechnet sie automatisch aus Raumgröße und einem benannten Slot-System.

### Slot-Namensschema

Jede Wand hat bis zu 5 Slots, nummeriert in Uhrzeigersinn-Richtung:

```
T1–T5  obere Wand,   von links nach rechts
R1–R5  rechte Wand,  von oben nach unten
B1–B5  untere Wand,  von rechts nach links
L1–L5  linke Wand,   von unten nach oben
```

Wie viele Slots pro Wand verfügbar sind, ergibt sich aus `get_tile_size()`:
`min(wandlänge_tiles, 5)`. Für einen 2×2-Raum: je 2 Slots pro Wand (T1/T2, R1/R2, B1/B2, L1/L2).

### get_valid_door_slots() – welche Slots nutzt dieser Raum?

```gdscript
# Leer = alle geometrisch passenden Slots sind gültig (z.B. DZ)
func get_valid_door_slots() -> Array[String]:
    return []

# Eingeschränkt = nur diese Slots (z.B. EZ: nur linke Wand)
func get_valid_door_slots() -> Array[String]:
    return ["L1", "L2"]
```

`Room.gd` übernimmt den Rest: `get_valid_door_combos()` berechnet daraus alle gültigen
`Vector2i(door_rotation, door_offset)`-Paare, und `_calc_door_transform()` errechnet
die Pixel-Position + Rotation für jeden Slot.

### _apply_visuals() – einfacher Raum

```gdscript
func _apply_visuals() -> void:
    if not is_node_ready():
        return
    var dtfm := _calc_door_transform(door_rotation, door_offset)
    ($Door as Node2D).position = dtfm["pos"]
    ($Door as Node2D).rotation = dtfm["rot"]
    var icfg := INTERIOR_TRANSFORMS.get(room_rotation, {"pos": Vector2.ZERO, "rot": 0.0})
    ($Interior as Node2D).position = icfg["pos"]
    ($Interior as Node2D).rotation = icfg["rot"]
```

Kein DOOR_CONFIGS mehr. `_calc_door_transform()` ist in `Room.gd` implementiert und kennt
alle Raum-Dimensionen über `get_tile_size()`.

### Interior-Rotation (room_rotation)

Interior dreht sich mit R-Taste um die Raummitte. Formel für N×M-Raum (W×H Pixel):

```gdscript
const INTERIOR_TRANSFORMS: Dictionary = {
    0: {"pos": Vector2(0, 0),   "rot": 0.0},
    1: {"pos": Vector2(W, 0),   "rot": PI / 2.0},
    2: {"pos": Vector2(W, H),   "rot": PI},
    3: {"pos": Vector2(0, H),   "rot": -PI / 2.0},
}
```

Für 2×2-Tile (32×32px): W=32, H=32.

---

## Flip-Raum (DZ-Stil) – Türpositionen

Beim Flip-Raum ändert `get_tile_size()` die Dimensionen je nach `room_flip`.
`_calc_door_transform()` nutzt `get_tile_size()` → Türpositionen passen sich **automatisch** an.

`get_valid_door_slots()` gibt `[]` zurück → alle geometrisch passenden Slots sind erlaubt.

```gdscript
func get_valid_door_slots() -> Array[String]:
    return []  # auto: alle Slots die in die aktuelle Orientierung passen

func _apply_visuals() -> void:
    if not is_node_ready():
        return
    $Landscape.visible = (room_flip == 0)
    $Portrait.visible  = (room_flip == 1)
    var dtfm := _calc_door_transform(door_rotation, door_offset)
    ($Door as Node2D).position = dtfm["pos"]
    ($Door as Node2D).rotation = dtfm["rot"]
```

Der `Door (Sprite2D)` liegt auf Root-Ebene (nicht unter Landscape/Portrait).

---

## Schritt 4 – get_valid_door_slots() einschränken

Wenn der Raum nur bestimmte Wände/Positionen unterstützt:

```gdscript
func get_valid_door_slots() -> Array[String]:
    return ["L1", "L2"]  # EZ: nur linke Wand, 2 Positionen
```

Default (leer = alle die passen): in `Room.gd` bereits implementiert, nichts überschreiben.

---

## Schritt 5 – set_floor_neighbors() (nur bei abweichenden Raumgrößen)

BedStandard (2×2 Tiles) wird automatisch von `Room.gd` + `BedStandard.gd` abgedeckt.

Für andere Raumgrößen die `set_floor_neighbors()` überschreiben:

```gdscript
const FLOOR_BASE_W := 60.0  # room_width_px - 4
const FLOOR_BASE_H := 28.0  # room_height_px - 4
const FLOOR_TEX_W  := 256.0

func set_floor_neighbors(top: bool, right: bool, bottom: bool, left: bool) -> void:
    # Bei room_rotation: Flags rotieren (wie BedStandard)
    var w: Array[bool] = [top, right, bottom, left]
    var l_top    := w[(0 + room_rotation) % 4]
    var l_right  := w[(1 + room_rotation) % 4]
    var l_bottom := w[(2 + room_rotation) % 4]
    var l_left   := w[(3 + room_rotation) % 4]
    var ext_l := 1.0 if l_left   else 0.0
    var ext_r := 1.0 if l_right  else 0.0
    var ext_t := 1.0 if l_top    else 0.0
    var ext_b := 1.0 if l_bottom else 0.0
    var f := $Interior/Floor as Sprite2D
    f.scale    = Vector2((FLOOR_BASE_W + ext_l + ext_r) / FLOOR_TEX_W, FLOOR_BASE_H + ext_t + ext_b)
    f.position = Vector2(cx + (ext_r - ext_l) * 0.5, cy + (ext_b - ext_t) * 0.5)
```

`cx`/`cy` = Raummitte in lokalen Pixeln.

---

## Schritt 6 – In Registry + MapGrid eintragen

**BuildPanel.gd** – `ROOM_REGISTRY`:
```gdscript
const ROOM_REGISTRY: Array[GDScript] = [
    preload("res://scenes/ingame/rooms/mein_raum/MeinRaum.gd"),  # ← neu
    ...
]
```

**MapGrid.gd** – `SCENE_PATHS`:
```gdscript
const SCENE_PATHS: Dictionary = {
    "mein_raum": "res://scenes/ingame/rooms/mein_raum/MeinRaum.tscn",  # ← neu
    ...
}
```

**zusätzlich in BuildCursor.gd UND IngameBuild.gd**

```gdscript
const ROOM_SCENES: Dictionary = {
	"bed_standard": preload("res://scenes/ingame/rooms/bed_standard/Bed_Standard.tscn"),
	"bed_double":   preload("res://scenes/ingame/rooms/bed_double/Bed_Double.tscn"),
}
```


Beide Einträge sind nötig: Registry = Baumenü, SCENE_PATHS = Laden beim Restore.

---

## Schritt 7 – get_definition() ausfüllen

```gdscript
static func get_definition() -> Dictionary:
    return {
        "id":            "mein_raum",
        "build_cost":    1500,
        "xp_reward":     100,
        "prefix":        "Z",       # Z/B/S/G/F/R – siehe Tabelle unten
        "label":         "MR",
        "name":          "Mein Raum",
        "category":      "zimmer",  # zimmer / gastro / service / management
        "icon":          "res://assets/icons/mein-icon.svg",
        "locked":        false,
        "in_build_menu": true,
    }

func _ready() -> void:
    room_type_id = "mein_raum"
```

### Prefix-Tabelle
| Prefix | Verwendung |
|---|---|
| Z | Bettenzimmer (EZ, DZ, Suite, …) |
| B | Bad, Dusche, WC |
| S | Serviceräume (Lager, Personal, Wäscherei, …) |
| G | Gastronomie (Restaurant, Bar, Küche, …) |
| F | Freizeit / Wellness (Pool, Spa, Fitness, …) |
| R | Rezeption / Lobby |
| V | Verwaltung | (Personalbüro, Forschung, …)

---

## Checklist

- [ ] Ordner + .tscn + .gd angelegt
- [ ] Szenen-Struktur: Ground (Wände + BaseFloor), Interior (Floor + Furniture), Door
- [ ] `get_definition()` ausgefüllt
- [ ] `room_type_id` in `_ready()` gesetzt
- [ ] `get_valid_door_slots()` implementiert (`[]` = alle passen, oder Liste z.B. `["L1","L2"]`)
- [ ] `INTERIOR_TRANSFORMS` definiert (einfacher Raum) **oder** Landscape/Portrait-Nodes (Flip-Raum)
- [ ] `_apply_visuals()` nutzt `_calc_door_transform()` aus `Room.gd`
- [ ] `set_floor_neighbors()` überschrieben wenn Raumgröße ≠ 2×2 Tiles
- [ ] Zeile in `ROOM_REGISTRY` (BuildMenu.gd) eingetragen
- [ ] Zeile in `SCENE_PATHS` (MapGrid.gd) eingetragen
- [ ] Icon unter `assets/icons/` vorhanden (oder locked=true bis Icon fertig)
