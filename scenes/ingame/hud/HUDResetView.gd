extends Control

const ICON_DEFAULT = preload("res://assets/icons/HUDBottom/square-square.svg")
const ICON_MAP_PIN = preload("res://assets/icons/HUDBottom/map-pin.svg")

@onready var reset_button: Button = %ResetView


# =============================================================================
func _ready() -> void:
	# Beim Start den Zustand aus dem InputHandler holen
	_apply_state(InputHandler.is_view_saved)

	# Der Button leitet den Klick an den InputHandler weiter
	reset_button.pressed.connect(func():
		if not InputHandler.is_view_saved:
			InputHandler.sig_camera_save_view_requested.emit()
		else:
			InputHandler.sig_camera_restore_view_requested.emit()
	)

	# Sobald das Save-Signal gefeuert wird (egal ob von Taste oder UI)
	InputHandler.sig_camera_save_view_requested.connect(func():
		await get_tree().process_frame
		_apply_state(InputHandler.is_view_saved)
		Toast.show(GameState.T("hud.button.reset_view.save_toast"))
	)

	# Sobald das Restore-Signal gefeuert wird (egal ob von Taste oder UI)
	InputHandler.sig_camera_restore_view_requested.connect(func():
		await get_tree().process_frame
		_apply_state(InputHandler.is_view_saved)
		Toast.show(GameState.T("hud.button.reset_view.restore_toast"))
	)


# =============================================================================
func set_view_saved_state(has_saved_view: bool) -> void:
	_apply_state(has_saved_view)


# =============================================================================
func _apply_state(has_saved_view: bool) -> void:
	if has_saved_view:
		reset_button.icon = ICON_MAP_PIN
		reset_button.tooltip_text = GameState.T("hud.button.reset_view.restore_tt")
	else:
		reset_button.icon = ICON_DEFAULT
		reset_button.tooltip_text = GameState.T("hud.button.reset_view.save_tt")
