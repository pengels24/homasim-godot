extends Control

## ANG-145 – Registrierung: 3-stufiger Flow
## Schritt 1: Account-Daten → Schritt 2: E-Mail-Code → Schritt 3: Charakter

const BG_IMAGE := "res://assets/images/home/home-background-002.png"

# Schritt-Nodes
@onready var step_register:  Control = $Center/Card/VBox/StepRegister
@onready var step_verify:    Control = $Center/Card/VBox/StepVerify
@onready var step_character: Control = $Center/Card/VBox/StepCharacter

# Schritt 1 – Registrierung
@onready var field_username:         LineEdit = $Center/Card/VBox/StepRegister/FieldUsername
@onready var field_email:            LineEdit = $Center/Card/VBox/StepRegister/FieldEmail
@onready var field_password:         LineEdit = $Center/Card/VBox/StepRegister/FieldPassword
@onready var field_password_confirm: LineEdit = $Center/Card/VBox/StepRegister/FieldPasswordConfirm
@onready var btn_close:              Button   = $Center/Card/VBox/HeaderRow/BtnClose
@onready var btn_register:           Button   = $Center/Card/VBox/StepRegister/BtnRegister
@onready var btn_to_login:           Button   = $Center/Card/VBox/StepRegister/BtnToLogin
@onready var error_register:         Label    = $Center/Card/VBox/StepRegister/ErrorLabel

# Schritt 2 – Verifizierung
@onready var field_code:    LineEdit = $Center/Card/VBox/StepVerify/FieldCode
@onready var btn_verify:    Button   = $Center/Card/VBox/StepVerify/BtnVerify
@onready var error_verify:  Label    = $Center/Card/VBox/StepVerify/ErrorLabel

# Schritt 3 – Charakter
@onready var field_manager_name: LineEdit    = $Center/Card/VBox/StepCharacter/HBox/Options/FieldManagerName
@onready var btn_create:         Button      = $Center/Card/VBox/StepCharacter/BtnCreate
@onready var error_character:    Label       = $Center/Card/VBox/StepCharacter/ErrorLabel
@onready var avatar_bg:          ColorRect   = $Center/Card/VBox/StepCharacter/HBox/Preview/AvatarBg
@onready var avatar_initials:    Label       = $Center/Card/VBox/StepCharacter/HBox/Preview/AvatarBg/Initials
@onready var preview_name:       Label       = $Center/Card/VBox/StepCharacter/HBox/Preview/PreviewName
@onready var preview_sub:        Label       = $Center/Card/VBox/StepCharacter/HBox/Preview/PreviewSub
@onready var bg_image:           TextureRect = $Bg

# Charakter-Optionen (Button-Gruppen)
@onready var gender_buttons: Array[Button] = []
@onready var skin_buttons:   Array[Button] = []
@onready var hair_buttons:   Array[Button] = []
@onready var outfit_buttons: Array[Button] = []

# Gewählte Werte
var _gender  := "m"
var _skin    := "hell"
var _hair    := "braun"
var _outfit  := "anzug_schwarz"

const SKIN_COLORS := {
	"hell":   Color(0.95, 0.82, 0.70),
	"mittel": Color(0.76, 0.57, 0.38),
	"dunkel": Color(0.40, 0.26, 0.16),
}


func _ready() -> void:
	var tex := load(BG_IMAGE) as Texture2D
	if tex:
		bg_image.texture = tex

	_collect_option_buttons()
	_connect_signals()
	_apply_translations()
	_show_step(1)
	_update_avatar()


func _collect_option_buttons() -> void:
	var g := $Center/Card/VBox/StepCharacter/HBox/Options/GenderRow
	var s := $Center/Card/VBox/StepCharacter/HBox/Options/SkinRow
	var h := $Center/Card/VBox/StepCharacter/HBox/Options/HairRow
	var o := $Center/Card/VBox/StepCharacter/HBox/Options/OutfitRow
	for btn in g.get_children():
		if btn is Button:
			gender_buttons.append(btn)
	for btn in s.get_children():
		if btn is Button:
			skin_buttons.append(btn)
	for btn in h.get_children():
		if btn is Button:
			hair_buttons.append(btn)
	for btn in o.get_children():
		if btn is Button:
			outfit_buttons.append(btn)


func _connect_signals() -> void:
	btn_close.pressed.connect(_on_to_login_pressed)
	btn_register.pressed.connect(_on_register_pressed)
	btn_to_login.pressed.connect(_on_to_login_pressed)
	btn_verify.pressed.connect(_on_verify_pressed)
	btn_create.pressed.connect(_on_create_pressed)
	field_password_confirm.text_submitted.connect(func(_t): _on_register_pressed())
	field_code.text_submitted.connect(func(_t): _on_verify_pressed())
	field_manager_name.text_changed.connect(func(_t): _update_avatar())

	for btn in gender_buttons:
		btn.pressed.connect(_on_gender_selected.bind(btn))
	for btn in skin_buttons:
		btn.pressed.connect(_on_skin_selected.bind(btn))
	for btn in hair_buttons:
		btn.pressed.connect(_on_hair_selected.bind(btn))
	for btn in outfit_buttons:
		btn.pressed.connect(_on_outfit_selected.bind(btn))

	_set_option_active(gender_buttons, gender_buttons[0])
	_set_option_active(skin_buttons,   skin_buttons[0])
	_set_option_active(hair_buttons,   hair_buttons[1])
	_set_option_active(outfit_buttons, outfit_buttons[0])


func _apply_translations() -> void:
	field_username.placeholder_text         = GameState.T("register.field.username")
	field_email.placeholder_text            = GameState.T("register.field.email")
	field_password.placeholder_text         = GameState.T("register.field.password")
	field_password_confirm.placeholder_text = GameState.T("register.field.password_confirm")
	btn_register.text  = GameState.T("register.btn.submit")
	btn_to_login.text  = GameState.T("register.link.login")
	field_code.placeholder_text = GameState.T("register.verify.field.code")
	btn_verify.text    = GameState.T("register.verify.btn.submit")
	field_manager_name.placeholder_text = GameState.T("register.character.field.name")
	btn_create.text    = GameState.T("register.character.btn.submit")


func _show_step(step: int) -> void:
	step_register.visible  = step == 1
	step_verify.visible    = step == 2
	step_character.visible = step == 3


# ── Schritt 1: Registrierung ──────────────────────────────────────────────────

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


# ── Schritt 2: Verifizierung ──────────────────────────────────────────────────

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
	# Session ist jetzt gesetzt – Cookie speichern
	_show_step(3)
	field_manager_name.grab_focus()


# ── Schritt 3: Charakter ──────────────────────────────────────────────────────

func _on_gender_selected(btn: Button) -> void:
	_gender = btn.get_meta("value")
	_set_option_active(gender_buttons, btn)
	_update_avatar()


func _on_skin_selected(btn: Button) -> void:
	_skin = btn.get_meta("value")
	_set_option_active(skin_buttons, btn)
	_update_avatar()


func _on_hair_selected(btn: Button) -> void:
	_hair = btn.get_meta("value")
	_set_option_active(hair_buttons, btn)


func _on_outfit_selected(btn: Button) -> void:
	_outfit = btn.get_meta("value")
	_set_option_active(outfit_buttons, btn)
	_update_avatar()


func _update_avatar() -> void:
	var name_text := field_manager_name.text.strip_edges() if is_instance_valid(field_manager_name) else ""
	avatar_initials.text = _get_initials(name_text)
	preview_name.text    = name_text if name_text != "" else "—"
	preview_sub.text     = "MANAGER · LEVEL 1"
	if SKIN_COLORS.has(_skin):
		avatar_bg.color = SKIN_COLORS[_skin]


func _get_initials(name_text: String) -> String:
	var parts := name_text.split(" ", false)
	if parts.size() == 0 or name_text.is_empty():
		return "?"
	if parts.size() == 1:
		return parts[0].left(2).to_upper()
	return (parts[0].left(1) + parts[1].left(1)).to_upper()


func _on_create_pressed() -> void:
	var name_text := field_manager_name.text.strip_edges()
	if name_text.is_empty():
		error_character.text = GameState.T("login.error.data_invalid")
		return
	btn_create.disabled = true
	error_character.text = ""
	Api.post_json("/api/manager/create", {
		"name":              name_text,
		"gender":            _gender,
		"appearance_skin":   _skin,
		"appearance_hair":   _hair,
		"appearance_outfit": _outfit,
		"appearance_hat":    null
	}, _on_create_response)


func _on_create_response(success: bool, data: Dictionary) -> void:
	btn_create.disabled = false
	if not success or not data.get("success", false):
		error_character.text = data.get("message", GameState.T("api.error.network"))
		return
	# Session-Daten in GameState laden und zum Dashboard
	SessionManager.check_session(func(_logged_in: bool):
		get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")
	)


func _on_to_login_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


# ── Hilfsfunktionen ──────────────────────────────────────────────────────────

func _set_option_active(group: Array[Button], active: Button) -> void:
	for btn in group:
		btn.button_pressed = (btn == active)
