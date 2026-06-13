extends CanvasLayer
class_name DayTransition

# Dieses Signal feuern wir, wenn der Bildschirm dunkel ist,
# damit das Backend in Ruhe den Tagesabschluss berechnen kann.
signal sig_midnight_hidden

@onready var _anim_player: AnimationPlayer = $AnimationPlayer

# =============================================================================
func _ready() -> void:
  # Sobald die Szene geladen wird, starten wir sofort die Animation
  _anim_player.play("night_sequence")

  # Wenn die Animation fertig ist, räumen wir die Szene auf
  _anim_player.animation_finished.connect(_on_animation_finished)

# =============================================================================
## Diese Funktion wird AUS DEM ANIMATION PLAYER über einen Call Method Track aufgerufen
func trigger_backend_update() -> void:
  sig_midnight_hidden.emit()

# =============================================================================
func _on_animation_finished(_anim_name: String) -> void:
  queue_free()
