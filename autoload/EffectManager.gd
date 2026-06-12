# EffectManager

extends Node

# Hier merkt sich der Manager die UI-Ziele
var ui_money_node: Control = null
var ui_exp_node: Control = null
var ui_fp_node: Control = null


# =============================================================================
func _ready() -> void:
	# Das macht diesen Autoload immun gegen die Godot-Pause!
	process_mode = Node.PROCESS_MODE_ALWAYS


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


# =============================================================================
# UI EFFEKTE (Neu hinzugefügt)
# =============================================================================

# =============================================================================
# Startet einen weichen Transparenz-Puls und gibt den Tween zurück.
func start_ui_pulse(target_node: Control, duration: float = 0.8) -> Tween:
	# Prüfen, ob der Node (noch) existiert, um Fehler zu vermeiden
	if not is_instance_valid(target_node):
		return null

	# Tween erstellen und auf unendliche Wiederholung stellen
	var tween = create_tween().set_loops()

	# Transparenz auf 40% senken, dann wieder auf 100% erhöhen (mit weicher Sinus-Kurve)
	tween.tween_property(target_node, "modulate:a", 0.4, duration).set_trans(Tween.TRANS_SINE)
	tween.tween_property(target_node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_SINE)

	return tween


# =============================================================================
# Stoppt einen aktiven Puls-Effekt und stellt die Sichtbarkeit wieder vollständig her.
func stop_ui_pulse(target_node: Control, tween: Tween) -> void:
	if is_instance_valid(tween):
		tween.kill() # Bricht die aktuelle Animation sofort ab

	if is_instance_valid(target_node):
		target_node.modulate.a = 1.0 # Setzt das Element sicher auf 100% Sichtbarkeit zurück
