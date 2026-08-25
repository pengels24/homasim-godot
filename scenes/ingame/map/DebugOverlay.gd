extends Node2D

# DebugOverlay ist deaktiviert – MapGrid._draw() übernimmt das gesamte Debug-Rendering
# direkt mit korrekter to_local(tile_to_world()) Koordinatentransformation.

func _process(_delta: float) -> void:
	pass

func _draw() -> void:
	pass
