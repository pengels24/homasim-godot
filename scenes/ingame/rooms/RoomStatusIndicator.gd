extends Node2D
class_name RoomStatusIndicator

enum RoomState { FREE, OCCUPIED, CHECKOUT, SERVICE }

# Die Farben (Hex-Codes für einen schönen, modernen Look)
const COLOR_FREE     = Color("2ecc71") # sattes Grün
const COLOR_OCCUPIED = Color("e74c3c") # klares Rot
const COLOR_CHECKOUT = Color("e67e22") # Orange
const COLOR_SERVICE  = Color("f1c40f") # Warn-Gelb

var current_state: RoomState = RoomState.FREE
var _pulse_tween: Tween


# =============================================================================
func set_state(new_state: RoomState) -> void:
	if current_state == new_state:
		return # Nichts tun, wenn wir schon in diesem Status sind

	current_state = new_state
	queue_redraw() # Zwingt Godot, die _draw() Funktion im nächsten Frame neu aufzurufen

	# Alten Tween stoppen, falls einer lief
	if _pulse_tween:
		_pulse_tween.kill()

	# Alpha-Wert (Transparenz) wieder auf 100% setzen
	modulate.a = 1.0

	# Wenn Service, dann starte das Pulsieren
	if current_state == RoomState.SERVICE:
		_start_pulse()


# =============================================================================
func _start_pulse() -> void:
	# Endlos-Loop für weiches Ein- und Ausblenden der Transparenz (Alpha)
	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate:a", 0.3, 0.6).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(self, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


# Godot's interne Zeichen-Funktion
func _draw() -> void:
	var color: Color
	match current_state:
		RoomState.FREE:     color = COLOR_FREE
		RoomState.OCCUPIED: color = COLOR_OCCUPIED
		RoomState.CHECKOUT: color = COLOR_CHECKOUT
		RoomState.SERVICE:  color = COLOR_SERVICE

	# Für scharfe Pixel-Art zeichnen wir am besten zwei Kreise übereinander,
	# statt "draw_arc" zu nutzen. Das verhindert Vektor-Artefakte.

	# 1. Der schwarze Rand (etwas größer)
	draw_circle(Vector2.ZERO, 5.0, Color("#111111"))

	# 2. Der farbige Kern (etwas kleiner = dünner Rand)
	draw_circle(Vector2.ZERO, 4.0, color)
