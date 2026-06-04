extends CanvasLayer
## ANG-191 – Spawnt animierte Ressourcen-Labels (Kapital, XP, FP).
## Aufruf: FloatingValues.spawn("−500 €", -500.0, world_pos, target_node)
## Positiver Betrag = grün, negativer = rot.

const SCENE := preload("res://scenes/shared/FloatingValue.tscn")

const COLOR_POS := Color(0.20, 0.88, 0.38, 1.0)  # grün
const COLOR_NEG := Color(0.95, 0.28, 0.28, 1.0)  # rot


# =============================================================================
func _ready() -> void:
	layer = 99


# =============================================================================
## world_pos: Position in Weltkoordinaten (MapGrid-Raum).
## target_node: HUD-Control zu dem das Label fliegt.
## screen_offset: Versatz des Startpunkts in Bildschirmkoordinaten (z.B. für nebeneinander).
func spawn(text: String, amount: float, world_pos: Vector2, target_node: Control, screen_offset: Vector2 = Vector2.ZERO) -> void:
	if not is_instance_valid(target_node):
		return
	var color      := COLOR_POS if amount >= 0.0 else COLOR_NEG
	var from_screen := _world_to_screen(world_pos) + screen_offset
	var to_screen   := target_node.get_global_rect().get_center()
	var fv: Node2D  = SCENE.instantiate()
	add_child(fv)
	fv.spawn(text, color, from_screen, to_screen)


# =============================================================================
func _world_to_screen(world_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform() * world_pos
