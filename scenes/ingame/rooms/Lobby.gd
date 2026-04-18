extends "res://scenes/ingame/rooms/Room.gd"
## Lobby – Eingangsbereich, 4×4 Tiles. Wird automatisch mit der Startparzelle platziert.
## Kein R/T/Z – Türrichtung kommt aus entrance_dir des Plots.

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var door: TileMapLayer = $Door

# ── Zustand ───────────────────────────────────────────────────────────────────
var entrance_dir: String = "top"


func _ready() -> void:
	room_type_id = "lobby"


# ── Public API ────────────────────────────────────────────────────────────────

func configure(data: Dictionary) -> void:
	entrance_dir = data.get("entrance_dir", entrance_dir)
	super.configure(data)


# ── Visuals ───────────────────────────────────────────────────────────────────

func _apply_visuals() -> void:
	if not is_node_ready():
		return
	# TODO: set_cell für "bottom"/"left"/"right" wenn Peter die Tiles gemalt hat
	# Für "top" ist die Door-Layer bereits korrekt vorbemalt
