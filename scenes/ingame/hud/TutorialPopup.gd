extends CanvasLayer

@onready var title_label: Label = %Title
@onready var desc_label: RichTextLabel = %Desc
@onready var texture_rect: TextureRect = %TextureRect
@onready var close_btn: Button = %CloseBtn

func _ready() -> void:
	$Dim.mouse_filter = Control.MOUSE_FILTER_STOP
	close_btn.text = GameState.T("ui.tutorial.btn_ok")
	close_btn.pressed.connect(queue_free)
	get_tree().paused = true
	
	# Try to find OK sound
	if MusicManager and MusicManager.has_method("play_sfx"):
		close_btn.pressed.connect(func():
			MusicManager.play_sfx("ui_click")
			get_tree().paused = false
		)
	else:
		close_btn.pressed.connect(func():
			get_tree().paused = false
		)

func set_content(data: Dictionary) -> void:
	var category = data.get("category", "tutorial")
	
	# Dynamische Skalierung für große Screenshots vs. kleine Icons
	if category == "codex":
		texture_rect.custom_minimum_size = Vector2(0, 150)
	else:
		texture_rect.custom_minimum_size = Vector2(0, 400)
		
	var title_key = data.get("title_key", "")
	var desc_key = data.get("desc_key", "")
	var image_path = data.get("image", "")
	
	if GameState:
		title_label.text = GameState.T(title_key)
		desc_label.text = GameState.T(desc_key)
	else:
		title_label.text = title_key
		desc_label.text = desc_key
		
	if image_path != "":
		texture_rect.texture = load(image_path)
		texture_rect.show()
	else:
		texture_rect.hide()

func _unhandled_input(event: InputEvent) -> void:
	# Block ALL unhandled inputs from falling through to the game/InputHandler
	if event is InputEventKey or event is InputEventMouseButton:
		get_viewport().set_input_as_handled()
