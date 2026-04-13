extends Control

@onready var username_field: LineEdit = $CenterContainer/VBoxContainer/UsernameField
@onready var password_field: LineEdit = $CenterContainer/VBoxContainer/PasswordField
@onready var login_button: Button = $CenterContainer/VBoxContainer/LoginButton
@onready var error_label: Label = $CenterContainer/VBoxContainer/ErrorLabel


func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	# Enter-Taste in den Feldern triggert auch Login
	username_field.text_submitted.connect(func(_t): _on_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_login_pressed())
	error_label.text = ""


func _on_login_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text

	if username.is_empty() or password.is_empty():
		_show_error("Bitte Benutzername und Passwort eingeben.")
		return

	login_button.disabled = true
	error_label.text = ""

	Api.post_form("/login", {"username": username, "password": password}, _on_login_response)


func _on_login_response(success: bool, data: Dictionary) -> void:
	login_button.disabled = false

	if not success:
		var msg: String = data.get("error", data.get("message", "Login fehlgeschlagen."))
		_show_error(msg)
		return

	# Erwartet: {"success": true, "user": {...}} oder {"id": ..., "name": ...}
	var user_data: Dictionary = data.get("user", data)
	if user_data.is_empty() or not (data.get("success", true)):
		_show_error(data.get("message", "Login fehlgeschlagen."))
		return

	GameState.login(user_data)
	get_tree().change_scene_to_file("res://scenes/hotel_select/HotelSelect.tscn")


func _show_error(msg: String) -> void:
	error_label.text = msg
