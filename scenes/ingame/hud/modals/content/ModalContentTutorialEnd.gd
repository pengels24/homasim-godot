extends VBoxContainer


@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var btn_ok: Button = %BtnOk

func _ready() -> void:
	btn_ok.pressed.connect(func():
		get_tree().paused = false
		GameState.is_tutorial_mode = false
		GameState.active_hotel_id = -1
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	)
	
	rich_text_label.text = GameState.T("tutorial.end.headline")
	btn_ok.text = GameState.T("tutorial.end.button")
