extends VBoxContainer

signal sig_close_requested

@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var btn_ok: Button = %BtnOk

func _ready() -> void:
	btn_ok.pressed.connect(func(): sig_close_requested.emit())
	
	rich_text_label.text = "[center][b]Herzlichen Glückwunsch![/b]\n\nDu hast das maximale Level erreicht und damit den gesamten aktuellen Inhalt der TechDemo freigeschaltet.\n\nDu kannst dein Hotel nun beliebig lange weiter verwalten und ausbauen.\n\n[color=#eab308]Vielen Dank fürs Spielen und Testen![/color][/center]"
	btn_ok.text = "Weiterspielen"
