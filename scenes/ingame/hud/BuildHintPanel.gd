extends MarginContainer
class_name BuildHintPanel

@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	visible = false
	modulate.a = 0.0

func show_hints() -> void:
	visible = true
	anim_player.play("slide_in")

func hide_hints() -> void:
	anim_player.play("slide_out")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "slide_out":
		visible = false
