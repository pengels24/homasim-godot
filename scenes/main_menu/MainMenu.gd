extends Control

const BG_IMAGES := [
	"res://assets/images/home/home-background-001.png",
	"res://assets/images/home/home-background-002.png",
	"res://assets/images/home/home-background-003.png",
]
const SLIDE_INTERVAL := 5.0
const FADE_DURATION  := 1.2
const _SAVE_PATH     := "user://session.cfg"

@onready var bg_nodes: Array[TextureRect] = [
	$BgSlideshow/Bg1,
	$BgSlideshow/Bg2,
	$BgSlideshow/Bg3,
]
@onready var btn_login:    Button   = $Content/Buttons/BtnLogin
@onready var btn_settings: Button   = $Content/Buttons/BtnSettings
@onready var btn_play:     Button   = $Content/Buttons/BtnPlay
@onready var btn_quit:     Button   = $Content/Buttons/BtnQuit
@onready var logo:         TextureRect = $Content/Logo
@onready var title_label:  Label    = $Content/Title
@onready var subtitle:     Label    = $Content/Subtitle

# Login-Modal
@onready var login_modal:     ColorRect = $LoginModal
@onready var username_field:  LineEdit  = $LoginModal/Center/Card/VBox/UsernameField
@onready var password_field:  LineEdit  = $LoginModal/Center/Card/VBox/PasswordField
@onready var login_button:    Button    = $LoginModal/Center/Card/VBox/LoginButton
@onready var error_label:     Label     = $LoginModal/Center/Card/VBox/ErrorLabel
@onready var btn_close_modal: Button    = $LoginModal/Center/Card/VBox/BtnClose

var _current_bg := 0
var _slide_timer := 0.0


func _ready() -> void:
	_load_assets()
	_setup_modal()
	GameState.check_session(func(_logged_in: bool):
		_update_login_state()
	)
	btn_login.pressed.connect(_on_login_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
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
		for btn in [btn_login, btn_settings, btn_play, btn_quit, login_button]:
			btn.add_theme_font_override("font", font_outfit)
	if font_inter:
		subtitle.add_theme_font_override("font", font_inter)

	title_label.text = GameState.T("home.hero.title")
	subtitle.text    = GameState.T("home.hero.subtitle")
	btn_settings.text = GameState.T("menu.btn.settings")
	btn_play.text     = GameState.T("menu.btn.play")
	btn_quit.text     = GameState.T("menu.btn.quit")
	login_button.text = GameState.T("login.btn.submit")


func _setup_modal() -> void:
	login_button.pressed.connect(_on_modal_login_pressed)
	btn_close_modal.pressed.connect(_close_modal)
	username_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	var cfg := ConfigFile.new()
	if cfg.load(_SAVE_PATH) == OK:
		username_field.text = cfg.get_value("session", "username", "")


func _update_login_state() -> void:
	if GameState.is_logged_in():
		btn_login.text = GameState.T("menu.btn.logout")
		btn_play.disabled = false
	else:
		btn_login.text = GameState.T("menu.btn.login_register")
		btn_play.disabled = true


func _next_slide() -> void:
	var next := (_current_bg + 1) % bg_nodes.size()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(bg_nodes[next], "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(bg_nodes[_current_bg], "modulate:a", 0.0, FADE_DURATION)
	_current_bg = next


func _on_login_pressed() -> void:
	if GameState.is_logged_in():
		GameState.logout()
		_update_login_state()
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

	var cfg := ConfigFile.new()
	cfg.load(_SAVE_PATH)
	cfg.set_value("session", "username", username_field.text.strip_edges())
	cfg.save(_SAVE_PATH)

	_close_modal()
	GameState.login(data)
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _on_settings_pressed() -> void:
	pass # TODO: Settings-Szene
