extends Control

signal sig_resume_requested
signal sig_save_requested
signal sig_load_requested
signal sig_settings_requested
signal sig_quit_requested

# =============================================================================
func _ready() -> void:
	%ButtonContinue.pressed.connect(func(): sig_resume_requested.emit())
	%ButtonSave.pressed.connect(func(): sig_save_requested.emit())
	%ButtonLoad.pressed.connect(func(): sig_load_requested.emit())
	%ButtonSettings.pressed.connect(func(): sig_settings_requested.emit())
	%ButtonMainMenu.pressed.connect(func(): sig_quit_requested.emit())

	%ButtonContinue.text = GameState.T("modal.pause.button.continue")
	%ButtonSave.text = GameState.T("modal.pause.button.save")
	%ButtonLoad.text = GameState.T("modal.pause.button.load")
	%ButtonSettings.text = GameState.T("modal.pause.button.settings")
	%ButtonMainMenu.text = GameState.T("modal.pause.button.mainmenu")
