extends VBoxContainer

signal sig_close_requested

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var btn_ok: Button = %BtnOk
@onready var btn_discord: Button = %BtnDiscord
@onready var btn_bluesky: Button = %BtnBluesky

func _ready() -> void:
	btn_ok.pressed.connect(func(): sig_close_requested.emit())
	btn_discord.pressed.connect(func(): OS.shell_open("https://discord.gg/hYSvUqmhcw"))
	btn_bluesky.pressed.connect(func(): OS.shell_open("https://bsky.app/profile/angelus2010.bsky.social"))
	
	rich_text_label.text = "[center][b]Herzlichen Glückwunsch![/b]\n\nDu hast das maximale Level erreicht und damit den gesamten aktuellen Inhalt der TechDemo freigeschaltet.\n\nWir würden uns riesig über dein kurzes Feedback freuen! Wenn dir das Spiel gefallen hat (oder auch nicht), besuch uns auf [color=#eab308]Discord[/color] oder folge uns auf [color=#eab308]Bluesky[/color]!\n\n[color=#aaaaaa][i](Bitte nutze für konkrete Bugs/Fehlerberichte weiterhin ausschließlich den roten Käfer-Button am rechten Bildschirmrand)[/i][/color]\n\nDu kannst dein Hotel nun beliebig lange weiter verwalten und ausbauen.\n\n[color=#eab308]Vielen Dank fürs Spielen und Testen![/color][/center]"
	btn_ok.text = "Weiterspielen"
