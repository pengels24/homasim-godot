extends CanvasLayer
class_name PauseMenu
## ANG-176 – Pause-Menü. ESC im Spiel öffnet dieses Overlay.

signal resume_requested
signal save_requested
signal load_requested
signal settings_requested
signal quit_requested

@onready var _btn_resume:   Button = $Overlay/Panel/VBox/BtnResume
@onready var _btn_save:     Button = $Overlay/Panel/VBox/BtnSave
@onready var _btn_load:     Button = $Overlay/Panel/VBox/BtnLoad
@onready var _btn_settings: Button = $Overlay/Panel/VBox/BtnSettings
@onready var _btn_quit:     Button = $Overlay/Panel/VBox/BtnQuit


# =============================================================================
func _ready() -> void:
	_btn_resume.text   = GameState.T("pausemenu.btn.resume")
	_btn_save.text     = GameState.T("pausemenu.btn.save")
	_btn_load.text     = GameState.T("pausemenu.btn.load")
	_btn_settings.text = GameState.T("pausemenu.btn.settings")
	_btn_quit.text     = GameState.T("pausemenu.btn.quit")
	var dark := Color(0.05, 0.18, 0.06, 1.0)
	_btn_resume.add_theme_color_override("font_color", dark)
	_btn_resume.add_theme_color_override("font_hover_color", dark)
	_btn_resume.add_theme_color_override("font_pressed_color", dark)
	_btn_resume.add_theme_color_override("font_focus_color", dark)
	_btn_resume.pressed.connect(func():   resume_requested.emit())
	_btn_save.pressed.connect(func():     save_requested.emit())
	_btn_load.pressed.connect(func():     load_requested.emit())
	_btn_settings.pressed.connect(func(): settings_requested.emit())
	_btn_quit.pressed.connect(func():     quit_requested.emit())


# =============================================================================
func open() -> void:
	visible = true
	_btn_resume.grab_focus()


# =============================================================================
func close() -> void:
	visible = false


# =============================================================================
func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			resume_requested.emit()
