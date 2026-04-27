extends CanvasLayer
class_name ToastNotification
## Kurze UI-Benachrichtigung – kein OK-Button, verschwindet automatisch.
## Wird ausschliesslich von Toast.gd (Autoload) instanziiert und verwaltet.

const FADE_IN_SEC  : float = 0.25
const HOLD_SEC     : float = 2.20
const FADE_OUT_SEC : float = 0.40

@onready var _panel:   PanelContainer = $Panel
@onready var _msg_lbl: Label          = $Panel/Margin/MessageLbl


func _ready() -> void:
	var font := load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	if font:
		_msg_lbl.add_theme_font_override("font", font)
	layer = 10
	_panel.modulate.a = 0.0


func play(message: String) -> void:
	_msg_lbl.text = message
	_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, FADE_IN_SEC)
	tw.tween_interval(HOLD_SEC)
	tw.tween_property(_panel, "modulate:a", 0.0, FADE_OUT_SEC)
	tw.tween_callback(queue_free)
