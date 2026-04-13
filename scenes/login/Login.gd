extends Control

@onready var username_field: LineEdit = $CenterContainer/VBoxContainer/UsernameField
@onready var password_field: LineEdit = $CenterContainer/VBoxContainer/PasswordField
@onready var login_button: Button = $CenterContainer/VBoxContainer/LoginButton
@onready var error_label: Label = $CenterContainer/VBoxContainer/ErrorLabel


const _SAVE_PATH := "user://session.cfg"

func _ready() -> void:
	login_button.pressed.connect(_on_login_pressed)
	# Enter-Taste in den Feldern triggert auch Login
	username_field.text_submitted.connect(func(_t): _on_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_login_pressed())
	error_label.text = ""
	# Gespeicherten Username vorausfüllen
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) == OK:
		username_field.text = cfg.get_value("session", "username", "")


func _on_login_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text

	if username.is_empty() or password.is_empty():
		_show_error(GameState.T("login.error.data_invalid"))
		return

	login_button.disabled = true
	error_label.text = ""

	Api.post_form("/api/auth/login", {"username": username, "password": password}, _on_login_response)


func _on_login_response(success: bool, data: Dictionary) -> void:
	login_button.disabled = false

	if not success:
		var msg: String = data.get("error", data.get("message", GameState.T("login.error.data_invalid")))
		_show_error(msg)
		return

	if not data.get("success", false):
		_show_error(data.get("message", GameState.T("login.error.data_invalid")))
		return

	# Username für nächsten Start speichern
	var cfg := ConfigFile.new()
	cfg.load(_SAVE_PATH)
	cfg.set_value("session", "username", username_field.text.strip_edges())
	cfg.save(_SAVE_PATH)

	GameState.login(data)
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _show_error(msg: String) -> void:
	error_label.text = msg
