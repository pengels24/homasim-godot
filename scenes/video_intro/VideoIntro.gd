extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer
var _is_transitioning: bool = false

func _ready() -> void:
	video_player.finished.connect(_on_video_finished)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_skip()
	elif event is InputEventKey and event.pressed:
		_skip()

func _on_video_finished() -> void:
	_transition_to_ingame()

func _skip() -> void:
	_transition_to_ingame()

func _transition_to_ingame() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	
	# Kurzer Fadeout des Videos beim Skript, falls es noch hell ist.
	video_player.stop()
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")
