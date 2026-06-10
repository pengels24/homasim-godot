extends "res://scenes/ingame/rooms/Room.gd"
## Lobby – Eingangsbereich, 4×4 Tiles. Wird automatisch mit der Startparzelle platziert.
## Kein R/T/Z – Türrichtung kommt aus entrance_dir des Plots.
## Jede Door/*-Layer enthält Eingangstür + gegenüberliegende Innentüren als fertiges Paar.
## Wände zeigen sich nur auf der Eingangs-Achse (top/bottom → N+S-Wände, left/right → W+E-Wände).

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _door_container: Node2D      = $Door
@onready var _wall_top:       TileMapLayer = $Ground/Top
@onready var _wall_right:     TileMapLayer = $Ground/Right
@onready var _wall_left:      TileMapLayer = $Ground/Left
@onready var _wall_bottom:    TileMapLayer = $Ground/Bottom

# ── Zustand ───────────────────────────────────────────────────────────────────
var entrance_dir: String = "top"


# =============================================================================
static func get_definition() -> Dictionary:
	return {
		"id":            "lobby",
		"build_cost":    0,
		"xp_reward":     0,
		"prefix":        "R",
		"label":         "Lobby",
		"name":          "Lobby / Rezeption",
		"category":      "management",
		"icon":          "",
		"nightly_price": 0,
		"locked":        false,
		"in_build_menu": false,
		"req_level": 0,
		"req_tech": "",
		"max_beds": 0,
		"open_from": 420,
		"open_to": 1320,
	}


# =============================================================================
func _ready() -> void:
	room_type_id = "lobby"


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
func configure(data: Dictionary) -> void:
	entrance_dir = data.get("entrance_dir", entrance_dir)
	super.configure(data)


# ── Visuals ───────────────────────────────────────────────────────────────────

# =============================================================================
func _apply_visuals() -> void:
	if not is_node_ready():
		return
	# Nur die passende Eingangs-Door-Layer anzeigen
	for child in _door_container.get_children():
		child.visible = (child.name.to_lower() == entrance_dir)
	# Nur die Eingangs-Wand einblenden – gegenüberliegende Innentür ist im Door-Layer
	_wall_top.visible    = (entrance_dir == "top")
	_wall_bottom.visible = (entrance_dir == "bottom")
	_wall_left.visible   = (entrance_dir == "left")
	_wall_right.visible  = (entrance_dir == "right")
