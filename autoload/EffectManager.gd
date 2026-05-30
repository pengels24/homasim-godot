extends Node

# Hier merkt sich der Manager die UI-Ziele
var ui_money_node: Control = null
var ui_exp_node: Control = null
var ui_fp_node: Control = null


# =============================================================================
# Wird gerufen, wenn Geld fliegt (egal ob Plus oder Minus)
func spawn_money_text(amount: int, world_pos: Vector2) -> void:
	if ui_money_node != null:
		var text = "+%d €" % amount if amount > 0 else "%d €" % amount
		var direction = 1.0 if amount > 0 else -1.0
		FloatingValues.spawn(text, direction, world_pos, ui_money_node, Vector2(-48.0, 0.0))


# =============================================================================
# Wird gerufen, wenn man EXP bekommt
func spawn_exp_text(amount: int, world_pos: Vector2) -> void:
	if ui_exp_node != null and amount > 0:
		FloatingValues.spawn("+%d EXP" % amount, 1.0, world_pos, ui_exp_node, Vector2(48.0, 0.0))


# =============================================================================
# Wird gerufen, wenn man FP bekommt
func spawn_fp_text(amount: int, world_pos: Vector2) -> void:
	if ui_fp_node != null and amount > 0:
		FloatingValues.spawn("+%d FP" % amount, 1.0, world_pos, ui_fp_node, Vector2(48.0, 0.0))
