extends CanvasLayer
class_name ToastNotification
## Kurze UI-Benachrichtigung – kein OK-Button, verschwindet automatisch.
## Wird ausschliesslich von Toast.gd (Autoload) instanziiert und verwaltet.

const FADE_IN_SEC  : float = 0.25
const HOLD_SEC     : float = 3.50
const FADE_OUT_SEC : float = 0.40

const PANEL_LEFT   : float = 660.0
const PANEL_RIGHT  : float = 1260.0
const PANEL_HEIGHT : float = 88.0
const POS_TOP_Y    : float = 80.0
const POS_MIDDLE_Y : float = 496.0
const POS_BOTTOM_Y : float = 930.0

@onready var _panel:   PanelContainer = $Panel
@onready var _msg_lbl: Label          = $Panel/Margin/MessageLbl


func _ready() -> void:
	var font := load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	if font:
		_msg_lbl.add_theme_font_override("font", font)
	_panel.modulate.a = 0.0


func play(message: String) -> void:
	_apply_position()
	_msg_lbl.text = message
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, FADE_IN_SEC)
	tw.tween_interval(HOLD_SEC)
	tw.tween_property(_panel, "modulate:a", 0.0, FADE_OUT_SEC)
	tw.tween_callback(queue_free)


func _apply_position() -> void:
	var top_y: float
	match SettingsManager.toast_position:
		"top":    top_y = POS_TOP_Y
		"middle": top_y = POS_MIDDLE_Y
		_:        top_y = POS_BOTTOM_Y
	_panel.offset_top    = top_y
	_panel.offset_bottom = top_y + PANEL_HEIGHT
