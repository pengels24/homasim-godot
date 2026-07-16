extends Control

const BG_IMAGES := [
	"res://assets/images/home/home-background-001.png",
	"res://assets/images/home/home-background-002.png",
	"res://assets/images/home/home-background-003.png",
]
const SLIDE_INTERVAL := 5.0
const FADE_DURATION  := 1.2

# MainMenu

@onready var bg_nodes: Array[TextureRect] = [%Bg1, %Bg2, %Bg3]
@onready var logo: TextureRect = %Logo
@onready var title_label: Label = %Title
@onready var subtitle: Label = %Subtitle
@onready var btn_play: Button = %BtnPlay
@onready var btn_settings: Button = %BtnSettings
@onready var btn_login: Button = %BtnLogin
@onready var btn_tutorial: Button = %BtnTutorial
@onready var btn_credits: Button = %BtnCredits
@onready var btn_close_game: Button = %BtnCloseGame

@onready var btn_idcard: Button = %BtnIDCard
@onready var _idcard_box: PanelContainer = %IDCardBox
@onready var lbl_idcard_name: Label = %LblName
@onready var lbl_idcard_info: Label = %LblInfo
@onready var avatar_display: CharacterDisplay = %AvatarDisplay

# footer
@onready var _version_lbl:      Label        = %VersionLbl
@onready var _godot_icon:       TextureRect  = %GodotIcon

# Login-Modal
@onready var login_modal:     ColorRect = $LoginModal
@onready var username_field:  LineEdit  = $LoginModal/Center/Card/VBox/UsernameField
@onready var password_field:  LineEdit  = $LoginModal/Center/Card/VBox/PasswordField
@onready var login_button:    Button    = $LoginModal/Center/Card/VBox/LoginButton
@onready var error_label:     Label     = $LoginModal/Center/Card/VBox/ErrorLabel
@onready var remember_checkbox:  CheckBox  = $LoginModal/Center/Card/VBox/RememberCheck
@onready var btn_close_modal:    Button    = $LoginModal/Center/Card/VBox/BtnClose
@onready var btn_to_register:   Button    = $LoginModal/Center/Card/VBox/BtnToRegister

# other modals
@onready var _manager_modal:    Control      = $ManagerModal
@onready var _settings_modal:   StandardModal = $SettingsModal
@onready var _dashboard_modal:  Control      = $DashboardModal
@onready var _disclaimer_modal: StandardModal = $DisclaimerModal

var _confirm_modal: ConfirmModal

var _current_bg := 0
var _slide_timer := 0.0

var _original_idcard_style: StyleBox
var _hover_idcard_style: StyleBox


# =============================================================================
func _ready() -> void:
	if has_node("Watermark"):
		$Watermark.text = GameState.GAME_STAGE
	MusicManager.play_menu()
	_load_assets()
	_setup_modal()
	_try_restore_last_profile()
	_update_manager_state()
	
	_original_idcard_style = _idcard_box.get_theme_stylebox("panel")
	_hover_idcard_style = _original_idcard_style.duplicate() as StyleBoxFlat
	_hover_idcard_style.border_color = Color(0.918, 0.702, 0.031, 1.0)
	_hover_idcard_style.border_width_left = 2
	_hover_idcard_style.border_width_top = 2
	_hover_idcard_style.border_width_right = 2
	_hover_idcard_style.border_width_bottom = 2
	
	btn_login.pressed.connect(_on_login_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_settings.pressed.connect(_on_settings_pressed)
	_settings_modal.set_content("res://scenes/ingame/hud/modals/content/ModalContentSettings.tscn")
	_settings_modal.closed.connect(_on_settings_closed)
	
	_confirm_modal = preload("res://scenes/shared/ConfirmModal.tscn").instantiate()
	add_child(_confirm_modal)
	
	btn_idcard.pressed.connect(_on_manager_pressed)
	btn_idcard.mouse_entered.connect(_on_idcard_hover.bind(true))
	btn_idcard.mouse_exited.connect(_on_idcard_hover.bind(false))
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	_manager_modal.closed.connect(_on_manager_modal_closed)
	_dashboard_modal.closed.connect(_on_dashboard_closed)
	btn_credits.pressed.connect(_on_credits_pressed)
	btn_close_game.pressed.connect(_on_quit_pressed)

	if GameState.open_dashboard_next:
		GameState.open_dashboard_next = false
		_on_play_pressed()
	else:
		_check_disclaimer()


# =============================================================================
func _process(delta: float) -> void:
	_slide_timer += delta
	if _slide_timer >= SLIDE_INTERVAL:
		_slide_timer = 0.0
		_next_slide()


# =============================================================================
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not login_modal.visible and not _settings_modal.visible and not _manager_modal.visible and not _dashboard_modal.visible and not _confirm_modal.visible:
		_on_quit_pressed()
		get_viewport().set_input_as_handled()


# =============================================================================
func _load_assets() -> void:
	for i in bg_nodes.size():
		var tex := load(BG_IMAGES[i]) as Texture2D
		if tex:
			bg_nodes[i].texture = tex

	title_label.text = GameState.T("menu.hero.title")
	subtitle.text    = GameState.T("menu.hero.subtitle")
	btn_settings.text  = GameState.T("menu.btn.settings")
	btn_play.text      = GameState.T("menu.btn.play")
	btn_credits.text   = GameState.T("menu.btn.credits")
	login_button.text  = GameState.T("login.btn.submit")
	btn_login.text     = GameState.T("menu.btn.account_bind")
	btn_login.disabled = true
	btn_tutorial.disabled = false # Tutorial freigeschaltet
	var vf := FileAccess.open("res://version.txt", FileAccess.READ)
	if vf:
		_version_lbl.text = vf.get_line().strip_edges().trim_prefix("gd-")
		vf.close()
	var godot_tex := load("res://icon.svg") as Texture2D
	if godot_tex:
		_godot_icon.texture = godot_tex


# =============================================================================
func _setup_modal() -> void:
	login_button.pressed.connect(_on_modal_login_pressed)
	btn_close_modal.pressed.connect(_close_modal)
	btn_to_register.pressed.connect(_on_to_register_pressed)
	username_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	password_field.text_submitted.connect(func(_t): _on_modal_login_pressed())
	username_field.text = SessionManager.saved_username
	remember_checkbox.button_pressed = SessionManager.saved_username != ""


# =============================================================================
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


# =============================================================================
func _update_manager_state() -> void:
	btn_play.disabled = GameState.active_profile_id < 0
	btn_play.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if GameState.active_profile_id >= 0 else Control.CURSOR_FORBIDDEN
	
	if GameState.active_profile_id >= 0:
		var profile := SaveManager.get_profile(GameState.active_profile_id)
		lbl_idcard_name.text = profile.name
		
		var hotels := SaveManager.get_hotels(GameState.active_profile_id)
		if hotels.size() > 0:
			var last_hotel = hotels.back()
			lbl_idcard_info.text = "%d Hotels\nZuletzt: %s" % [hotels.size(), last_hotel.get("name", "Unbekannt")]
		else:
			lbl_idcard_info.text = "0 Hotels\n" + GameState.T("menu.idcard.change_profile", "Profil wechseln")
		
		# Avatar rendern
		var ManagerSelectScript = preload("res://scenes/manager_select/ManagerSelect.gd")
		var p_gender = profile.get("appearance_gender", "m")
		var p_skin   = ManagerSelectScript.SKIN_COLORS.get(profile.get("appearance_skin", "hell"),   Color(0.95, 0.82, 0.70))
		var p_hair   = ManagerSelectScript.HAIR_COLORS.get(profile.get("appearance_hair", "braun"),   Color(0.45, 0.30, 0.15))
		var p_outfit = ManagerSelectScript.OUTFIT_COLORS.get(profile.get("appearance_outfit", "anzug_schwarz"), Color(0.12, 0.12, 0.16))
		avatar_display.update_appearance(p_gender, p_skin, p_hair, p_outfit)
		avatar_display.visible = true
	else:
		lbl_idcard_name.text = "Kein Profil"
		lbl_idcard_info.text = GameState.T("menu.idcard.create_profile", "Neues Profil anlegen")
		avatar_display.visible = false


# =============================================================================
func _next_slide() -> void:
	var next := (_current_bg + 1) % bg_nodes.size()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(bg_nodes[next], "modulate:a", 1.0, FADE_DURATION)
	tween.tween_property(bg_nodes[_current_bg], "modulate:a", 0.0, FADE_DURATION)
	_current_bg = next


# =============================================================================
func _on_idcard_hover(is_hover: bool) -> void:
	if is_hover:
		_idcard_box.add_theme_stylebox_override("panel", _hover_idcard_style)
	else:
		_idcard_box.add_theme_stylebox_override("panel", _original_idcard_style)


# =============================================================================
func _on_login_pressed() -> void:
	if GameState.is_logged_in():
		GameState.logout()
		_update_manager_state()
	else:
		_open_modal()


# =============================================================================
func _open_modal() -> void:
	error_label.text = ""
	password_field.text = ""
	login_modal.visible = true
	username_field.grab_focus()


# =============================================================================
func _close_modal() -> void:
	login_modal.visible = false


# =============================================================================
func _on_modal_login_pressed() -> void:
	var username := username_field.text.strip_edges()
	var password := password_field.text
	if username.is_empty() or password.is_empty():
		error_label.text = GameState.T("login.error.data_invalid")
		return
	login_button.disabled = true
	error_label.text = ""
	Api.post_form("/api/auth/login", {"username": username, "password": password}, _on_login_response)


# =============================================================================
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


# =============================================================================
func _on_quit_pressed() -> void:
	if _confirm_modal.visible: return
	_confirm_modal.ask(
		GameState.T("menu.quit_confirm.title", "Zurück zum Desktop"),
		GameState.T("menu.quit_confirm.desc", "Möchtest du das Spiel wirklich beenden?")
	)
	if not _confirm_modal.confirmed.is_connected(_quit_game):
		_confirm_modal.confirmed.connect(_quit_game)
	if not _confirm_modal.cancelled.is_connected(_cancel_quit):
		_confirm_modal.cancelled.connect(_cancel_quit)

func _quit_game() -> void:
	_cleanup_quit_signals()
	get_tree().quit()

func _cancel_quit() -> void:
	_cleanup_quit_signals()

func _cleanup_quit_signals() -> void:
	if _confirm_modal.confirmed.is_connected(_quit_game):
		_confirm_modal.confirmed.disconnect(_quit_game)
	if _confirm_modal.cancelled.is_connected(_cancel_quit):
		_confirm_modal.cancelled.disconnect(_cancel_quit)


# =============================================================================
func _on_play_pressed() -> void:
	btn_close_game.visible = false
	_dashboard_modal.open()

func _on_dashboard_closed() -> void:
	btn_close_game.visible = true


# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_S and ke.alt_pressed:
			_on_settings_pressed()


# =============================================================================
func _on_settings_pressed() -> void:
	btn_close_game.visible = false
	_settings_modal.open(GameState.T("settings.title"))


# =============================================================================
func _on_settings_closed() -> void:
	btn_close_game.visible = true


# =============================================================================
func _on_manager_pressed() -> void:
	btn_close_game.visible = false
	_manager_modal.open()


# =============================================================================
func _on_manager_modal_closed() -> void:
	_manager_modal.visible = false
	btn_close_game.visible = true
	_update_manager_state()


# =============================================================================
func _on_tutorial_pressed() -> void:
	if SaveManager.get_hotel(GameState.TUTORIAL_HOTEL_ID).is_empty() and not FileAccess.file_exists("user://hotels/hotel_%d.cfg" % GameState.TUTORIAL_HOTEL_ID):
		_start_tutorial_clean()
	else:
		_confirm_modal.ask(
			GameState.T("ui.tutorial.resume.title"),
			GameState.T("ui.tutorial.resume.desc"),
			GameState.T("ui.tutorial.resume.btn.continue"),
			GameState.T("ui.tutorial.resume.btn.restart"),
			"",
			false
		)
		if not _confirm_modal.confirmed.is_connected(_resume_tutorial):
			_confirm_modal.confirmed.connect(_resume_tutorial)
		if not _confirm_modal.cancelled.is_connected(_start_tutorial_clean):
			_confirm_modal.cancelled.connect(_start_tutorial_clean)

func _resume_tutorial() -> void:
	_disconnect_confirm()
	GameState.is_tutorial_mode = true
	GameState.active_hotel_id = GameState.TUTORIAL_HOTEL_ID
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")

func _start_tutorial_clean() -> void:
	_disconnect_confirm()
	SaveManager.create_tutorial_hotel()
	GameState.is_tutorial_mode = true
	GameState.active_hotel_id = GameState.TUTORIAL_HOTEL_ID
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")

func _disconnect_confirm() -> void:
	if _confirm_modal.confirmed.is_connected(_resume_tutorial):
		_confirm_modal.confirmed.disconnect(_resume_tutorial)
	if _confirm_modal.cancelled.is_connected(_start_tutorial_clean):
		_confirm_modal.cancelled.disconnect(_start_tutorial_clean)


# =============================================================================
func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/credits/Credits.tscn")


# =============================================================================
func _on_to_register_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/register/Register.tscn")


# =============================================================================
func _check_disclaimer() -> void:
	if not SettingsManager.dont_show_disclaimer:
		_disclaimer_modal.set_content("res://scenes/main_menu/ModalContentDisclaimer.tscn")
		_disclaimer_modal.open(GameState.T("ui.disclaimer.title"))
