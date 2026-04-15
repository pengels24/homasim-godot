extends Control

## ANG-145 – Registrierung: 2-stufiger Flow (Account → E-Mail-Verify)
## Schritt 3 (Charakter) liegt in scenes/character/CharacterEdit.tscn

const BG_IMAGE := "res://assets/images/home/home-background-002.png"

@onready var step_register: Control     = $Center/Card/VBox/StepRegister
@onready var step_verify:   Control     = $Center/Card/VBox/StepVerify

@onready var field_username:         LineEdit = $Center/Card/VBox/StepRegister/FieldUsername
@onready var field_email:            LineEdit = $Center/Card/VBox/StepRegister/FieldEmail
@onready var field_password:         LineEdit = $Center/Card/VBox/StepRegister/FieldPassword
@onready var field_password_confirm: LineEdit = $Center/Card/VBox/StepRegister/FieldPasswordConfirm
@onready var btn_register:           Button   = $Center/Card/VBox/StepRegister/BtnRegister
@onready var btn_close:              Button   = $Center/Card/VBox/HeaderRow/BtnClose
@onready var btn_to_login:           Button   = $Center/Card/VBox/StepRegister/BtnToLogin
@onready var error_register:         Label    = $Center/Card/VBox/StepRegister/ErrorLabel

@onready var field_code:   LineEdit = $Center/Card/VBox/StepVerify/FieldCode
@onready var btn_verify:   Button   = $Center/Card/VBox/StepVerify/BtnVerify
@onready var error_verify: Label    = $Center/Card/VBox/StepVerify/ErrorLabel

@onready var bg_image: TextureRect = $Bg


func _ready() -> void:
	var tex := load(BG_IMAGE) as Texture2D
	if tex:
		bg_image.texture = tex
	_connect_signals()
	_apply_translations()
	_show_step(1)


func _connect_signals() -> void:
	btn_register.pressed.connect(_on_register_pressed)
	btn_close.pressed.connect(_on_to_login_pressed)
	btn_to_login.pressed.connect(_on_to_login_pressed)
	btn_verify.pressed.connect(_on_verify_pressed)
	field_password_confirm.text_submitted.connect(func(_t): _on_register_pressed())
	field_code.text_submitted.connect(func(_t): _on_verify_pressed())


func _apply_translations() -> void:
	field_username.placeholder_text         = GameState.T("register.field.username")
	field_email.placeholder_text            = GameState.T("register.field.email")
	field_password.placeholder_text         = GameState.T("register.field.password")
	field_password_confirm.placeholder_text = GameState.T("register.field.password_confirm")
	btn_register.text = GameState.T("register.btn.submit")
	btn_to_login.text = GameState.T("register.link.login")
	field_code.placeholder_text = GameState.T("register.verify.field.code")
	btn_verify.text   = GameState.T("register.verify.btn.submit")


func _show_step(step: int) -> void:
	step_register.visible = step == 1
	step_verify.visible   = step == 2


func _on_register_pressed() -> void:
	var username := field_username.text.strip_edges()
	var email    := field_email.text.strip_edges()
	var password := field_password.text
	var confirm  := field_password_confirm.text

	if username.is_empty() or email.is_empty() or password.is_empty():
		error_register.text = GameState.T("login.error.data_invalid")
		return
	if password != confirm:
		error_register.text = GameState.T("register.error.passwords_mismatch")
		return

	btn_register.disabled = true
	error_register.text = ""
	Api.post_json("/api/auth/register", {
		"username": username, "email": email,
		"password": password, "password_confirm": confirm
	}, _on_register_response)


func _on_register_response(success: bool, data: Dictionary) -> void:
	btn_register.disabled = false
	if not success or not data.get("success", false):
		var errors: Array = data.get("errors", [])
		if "username_in_use" in errors:
			error_register.text = GameState.T("register.error.username_in_use")
		else:
			error_register.text = data.get("message", GameState.T("api.error.network"))
		return
	_show_step(2)
	field_code.grab_focus()


func _on_verify_pressed() -> void:
	var code := field_code.text.strip_edges()
	if code.is_empty():
		error_verify.text = GameState.T("login.error.data_invalid")
		return
	btn_verify.disabled = true
	error_verify.text = ""
	Api.post_json("/api/auth/verify", {"code": code}, _on_verify_response)


func _on_verify_response(success: bool, data: Dictionary) -> void:
	btn_verify.disabled = false
	if not success or not data.get("success", false):
		var msg: String = data.get("message", "")
		if msg == "code_invalid":
			error_verify.text = GameState.T("register.verify.error.code_invalid")
		else:
			error_verify.text = GameState.T("api.error.network")
		return
	get_tree().change_scene_to_file("res://scenes/character/CharacterEdit.tscn")


func _on_to_login_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
