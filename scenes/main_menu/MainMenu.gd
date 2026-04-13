extends Control

@onready var play_button: Button = $CenterContainer/VBoxContainer/PlayButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_play_pressed() -> void:
	if GameState.is_logged_in():
		get_tree().change_scene_to_file("res://scenes/hotel_select/HotelSelect.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/login/Login.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
