extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = $PanelContainer/Label

func _ready() -> void:
	panel.visible = false

func _process(delta: float) -> void:
	if panel.visible:
		# get_viewport().get_mouse_position() liefert unskalierte Screen-Koordinaten!
		panel.global_position = get_viewport().get_mouse_position() + Vector2(24, 24)

func set_error(msg_key: String) -> void:
	if msg_key == "":
		panel.visible = false
		return
		
	panel.visible = true
	var translated = GameState.T(msg_key)
	
	# Fallback, falls die Übersetzung (noch) nicht im CSV-System geladen ist
	if translated == msg_key:
		match msg_key:
			"build.error.out_of_bounds": translated = "Außerhalb der Parzelle"
			"build.error.blocked": translated = "Bauplatz blockiert"
			"build.error.door_blocked": translated = "Tür blockiert / verdeckt"
			"build.error.door_out_of_bounds": translated = "Tür zeigt ins Nichts"
			"build.error.path_blocked": translated = "Blockiert Flur eines anderen Raums"
			"build.error.no_connection": translated = "Muss an das Wegenetz grenzen"
			
	label.text = translated
