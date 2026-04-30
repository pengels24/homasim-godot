extends Node2D
## ANG-191 – Animiertes Ressourcen-Label.
## Wird von FloatingValues.gd instantiiert. Nie direkt verwenden.

func spawn(text: String, color: Color, from_pos: Vector2, to_pos: Vector2) -> void:
	position    = from_pos
	modulate.a  = 0.0
	$Lbl.text   = text
	$Lbl.add_theme_color_override("font_color", color)
	$Lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.85))
	$Lbl.add_theme_constant_override("outline_size", 3)
	$Lbl.add_theme_font_size_override("font_size", 15)

	# Positions-Tween: einblenden → steigen → halten → zur HUD fliegen
	var pos_tween := create_tween()
	pos_tween.tween_property(self, "modulate:a", 1.0, 0.15)
	pos_tween.tween_property(self, "position", from_pos + Vector2(0.0, -36.0), 0.40) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pos_tween.tween_interval(0.35)
	pos_tween.tween_property(self, "position", to_pos, 1.5) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	pos_tween.tween_callback(queue_free)

	# Fade-Tween: startet erst 0.8s in den Flug hinein (letztes Drittel)
	# Gesamtzeit bis Fade-Start: 0.15 + 0.40 + 0.35 + 0.80 = 1.70s
	var fade_tween := create_tween()
	fade_tween.tween_interval(1.70)
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.70)
