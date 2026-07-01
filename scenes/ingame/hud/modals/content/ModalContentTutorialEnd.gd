extends VBoxContainer

signal sig_close_requested

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var btn_ok: Button = %BtnOk
@onready var btn_discord: Button = %BtnDiscord
@onready var btn_bluesky: Button = %BtnBluesky

func _ready() -> void:
	btn_ok.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")
	)
	btn_discord.pressed.connect(func(): OS.shell_open("https://discord.gg/hYSvUqmhcw"))
	btn_bluesky.pressed.connect(func(): OS.shell_open("https://bsky.app/profile/angelus2010.bsky.social"))
	
	rich_text_label.text = GameState.T("tutorial.end.headline")
	btn_ok.text = GameState.T("tutorial.end.button")
