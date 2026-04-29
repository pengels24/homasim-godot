extends Control

const BG_IMAGES := [
	"res://assets/images/home/home-background-001.png",
	"res://assets/images/home/home-background-002.png",
	"res://assets/images/home/home-background-003.png",
]
const SLIDE_INTERVAL := 5.0
const FADE_DURATION  := 1.2

@onready var bg_nodes: Array[TextureRect] = [
	$BgSlideshow/Bg1,
	$BgSlideshow/Bg2,
	$BgSlideshow/Bg3,
]
@onready var btn_login:    Button   = $Content/Buttons/BtnLogin
@onready var btn_settings: Button   = $Content/Buttons/BtnSettings
@onready var btn_play:     Button   = $Content/Buttons/BtnPlay
@onready var btn_quit:     Button   = $Content/BtnQuit
@onready var logo:         TextureRect = $Content/Logo
@onready var title_label:  Label    = $Content/Title
@onready var subtitle:     Label    = $Content/Subtitle

# Login-Modal
@onready var login_modal:     ColorRect = $LoginModal
@onready var username_field:  LineEdit  = $LoginModal/Center/Card/VBox/UsernameField
@onready var password_field:  LineEdit  = $LoginModal/Center/Card/VBox/PasswordField
@onready var login_button:    Button    = $LoginModal/Center/Card/VBox/LoginButton
@onready var error_label:     Label     = $LoginModal/Center/Card/VBox/ErrorLabel
@onready var remember_checkbox:  CheckBox  = $LoginModal/Center/Card/VBox/RememberCheck
@onready var btn_close_modal:    Button    = $LoginModal/Center/Card/VBox/BtnClose
@onready var btn_to_register:   Button    = $LoginModal/Center/Card/VBox/BtnToRegister
@onready var btn_manager:       Button       = $Content/Buttons/BtnManager
@onready var btn_tutorial:      Button       = $Content/Buttons/BtnTutorial
@onready var btn_credits:       Button       = $Content/Buttons/BtnCredits
@onready var _manager_modal:    Control      = $ManagerModal
@onready var _settings_modal:   SettingsModal = $SettingsModal
@onready var _version_lbl:      Label        = $Footer/VersionLbl
@onready var _godot_icon:       TextureRect  = $Footer/GodotIcon

var _current_bg := 0
var _slide_timer := 0.0


func _ready() -> void:
	_load_assets()
	_setup_modal()
	_try_restore_last_profile()
	_update_manager_state()
	btn_login.pressed.connect(_on_login_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	_settings_modal.closed.connect(_on_settings_closed)
	btn_manager.pressed.connect(_on_manager_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	_manager_modal.closed.connect(_on_manager_modal_closed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_quit.pressed.connect(get_tree().quit)


func _process(delta: float) -> void:
	_slide_timer += delta
	if _slide_timer >= SLIDE_INTERVAL:
		_slide_timer = 0.0
		_next_slide()


func _load_assets() -> void:
	for i in bg_nodes.size():
		var tex := load(BG_IMAGES[i]) as Texture2D
		if tex:
			bg_nodes[i].texture = tex

	var logo_tex := load("res://assets/images/logo.png") as Texture2D
	if logo_tex:
		logo.texture = logo_tex

	var font_outfit := load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	var font_inter  := load("res://assets/fonts/Inter_18pt-Regular.ttf") as FontFile
	if font_outfit:
		title_label.add_theme_font_override("font", font_outfit)
		for btn in [btn_login, btn_settings, btn_play, btn_quit, btn_tutorial, btn_manager, btn_credits, login_button]:
			btn.add_theme_font_override("font", font_outfit)
	if font_inter:
		subtitle.add_theme_font_override("font", font_inter)

	title_label.text = GameState.T("home.hero.title")
	subtitle.text    = GameState.T("home.hero.subtitle")
	btn_settings.text  = GameState.T("menu.btn.settings")
	btn_play.text      = GameState.T("menu.btn.play")
	btn_quit.text      = GameState.T("menu.btn.quit")
	login_button.text  = GameState.T("login.btn.submit")
	btn_login.text     = GameState.T("menu.btn.account_bind")
	btn_login.disabled = true

	var vf := FileAccess.open("res://version.txt", FileAccess.READ)
	if vf:
		_version_lbl.text = "v" + vf.get_line().strip_edges().trim_prefix("gd-")
		vf.close()
	var godot_tex := load("res://icon.svg") as Texture2D
	if godot_tex:
		_godot_icon.texture = godot_tex


func _setup_modal() -> void:
	login_button.pressed.connect(_on_modal_login_pressed)
	btn_close_modal.pressed.connect(_close_modal)
	btn_to_register.pressed.connect(_on_to_register_pressed)
	username_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	username_field.text = SessionManager.saved_username
	remember_checkbox.button_pressed = SessionManager.saved_username != ""


func _try_restore_last_profile() -> void:
	var last_id := SettingsManager.last_profile_id
	if last_id < 0:
		return
	var profile := SaveManager.get_profile(last_id)
	if profile.is_empty():
		SettingsManager.last_profile_id = -1
		SettingsManager.save()
		return
	GameState.select_profile(profile)


func _update_manager_state() -> void:
	btn_play.disabled = GameState.active_profile_id < 0
	btn_play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if GameState.active_profile_id >= 0 else Control.CURSOR_FORBIDDEN
	if GameState.active_profile_id >= 0:
		btn_manager.text = GameState.T("menu.btn.manager_change")
	else:
		btn_manager.text = GameState.T("menu.btn.manager")


func _next_slide() -> void:
	var next := (_current_bg + 1) % bg_nodes.size()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(bg_nodes[next], "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(bg_nodes[_current_bg], "modulate:a", 0.0, FADE_DURATION)
	_current_bg = next


func _on_login_pressed() -> void:
	if GameState.is_logged_in():
		GameState.logout()
		_update_manager_state()
	else:
		_open_modal()


func _open_modal() -> void:
	error_label.text = ""
	password_field.text = ""
	login_modal.visible = true
	username_field.grab_focus()


func _close_modal() -> void:
	login_modal.visible = false


func _on_modal_login_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text
	if username.is_empty() or password.is_empty():
		error_label.text = GameState.T("login.error.data_invalid")
		return
	login_button.disabled = true
	error_label.text = ""
	Api.post_form("/api/auth/login", {"username": username, "password": password}, _on_login_response)


func _on_login_response(success: bool, data: Dictionary) -> void:
	login_button.disabled = false
	if not success:
		error_label.text = data.get("error", data.get("message", GameState.T("login.error.data_invalid")))
		return
	if not data.get("success", false):
		error_label.text = data.get("message", GameState.T("login.error.data_invalid"))
		return

	if remember_checkbox.button_pressed:
		SessionManager.save_username(username_field.text.strip_edges())
	GameState.login(data)
	_close_modal()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_S and ke.alt_pressed:
			_on_settings_pressed()


func _on_settings_pressed() -> void:
	btn_quit.visible = false
	_settings_modal.open()


func _on_settings_closed() -> void:
	btn_quit.visible = true


func _on_manager_pressed() -> void:
	btn_quit.visible = false
	_manager_modal.open()


func _on_manager_modal_closed() -> void:
	_manager_modal.visible = false
	btn_quit.visible = true
	_update_manager_state()


func _on_tutorial_pressed() -> void:
	pass # TODO: Tutorial-Szene (ANG-xxx)


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits/Credits.tscn")


func _on_to_register_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register/Register.tscn")
