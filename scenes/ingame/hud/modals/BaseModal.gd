extends Control
class_name BaseModal

## Signal, um dem Modal-Manager mitzuteilen, dass es geschlossen wurde
signal sig_modal_closed

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var dimmer: ColorRect = $Dimmer


# =============================================================================
func _ready() -> void:
	# Initialer Zustand: Modal ist unsichtbar und blockiert keine Eingaben
	visible = false
	dimmer.gui_input.connect(_on_dimmer_input)


# =============================================================================
## Öffnet das Modal mit Einblende-Animation
func open() -> void:
	visible = true
	animation_player.play("fade_in")


# =============================================================================
## Schließt das Modal mit Ausblende-Animation
func close() -> void:
	animation_player.play("fade_out")
	await animation_player.animation_finished
	visible = false
	sig_modal_closed.emit()


# =============================================================================
## Schließt das Modal, wenn man auf den abgedunkelten Bereich klickt
func _on_dimmer_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		close()
