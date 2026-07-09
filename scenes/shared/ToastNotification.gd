extends CanvasLayer
class_name ToastNotification
## Kurze UI-Benachrichtigung – kein OK-Button, verschwindet automatisch.
## Wird ausschliesslich von Toast.gd (Autoload) instanziiert und verwaltet.

const FADE_IN_SEC  : float = 0.25
const FADE_OUT_SEC : float = 0.40

@onready var _panel:   PanelContainer = $Panel
@onready var _msg_lbl: Label          = $Panel/Margin/MessageLbl


func _ready() -> void:
	var font := load("res://assets/fonts/Outfit-Bold.ttf") as FontFile
	if font:
		_msg_lbl.add_theme_font_override("font", font)
	_panel.modulate.a = 0.0


func play(data: Dictionary) -> void:
	if not is_inside_tree() or not is_node_ready():
		await ready
	
	var message: String = data.get("msg", "")
	var log_it: bool = data.get("log", true)
	
	_msg_lbl.text = message
	_panel.modulate.a = 0.0
	
	# Set anchors to top-left so scale and position tweens behave predictably
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	
	# Wait one frame so the PanelContainer updates its size based on the text
	await get_tree().process_frame
	
	_apply_position()
	
	var tw := create_tween()
	tw.tween_property(_panel, "modulate:a", 1.0, FADE_IN_SEC)
	
	var hold_time: float = 3.5
	if is_instance_valid(SettingsManager):
		hold_time = SettingsManager.toast_duration
	tw.tween_interval(hold_time)
	
	# Chain forces the following parallel block to wait for the interval
	tw.chain().tween_property(_panel, "modulate:a", 0.0, FADE_OUT_SEC)
	
	if log_it:
		var activity_log = get_tree().get_root().find_child("ActivityLogContainer", true, false)
		if activity_log and activity_log.is_inside_tree() and activity_log.is_visible_in_tree():
			_panel.pivot_offset = _panel.size / 2.0
			# Ziel ist die Mitte des ActivityLogContainers (wo auch der Button sitzt)
			var target_pos = activity_log.get_global_rect().get_center() - (_panel.size / 2.0)
			tw.parallel().tween_property(_panel, "position", target_pos, FADE_OUT_SEC).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
			tw.parallel().tween_property(_panel, "scale", Vector2(0.2, 0.2), FADE_OUT_SEC).set_ease(Tween.EASE_IN)
	
	tw.chain().tween_callback(queue_free)


func _apply_position() -> void:
	if not is_instance_valid(_panel):
		return
		
	var activity_log = get_tree().get_root().find_child("ActivityLogContainer", true, false)
	if activity_log and activity_log.is_inside_tree():
		var rect = activity_log.get_global_rect()
		# Position to the left of ActivityLogContainer, and shifted down by 80px to not overlap Modal close buttons
		_panel.position = Vector2(rect.position.x - _panel.size.x - 20.0, rect.position.y + 80.0)
	else:
		# Fallback if no ActivityLogContainer is found
		_panel.position = Vector2(20, 80)
