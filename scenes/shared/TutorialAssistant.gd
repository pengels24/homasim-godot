extends PanelContainer
class_name TutorialAssistant

signal sig_next_clicked

@onready var label: Label = $Margin/HBox/VBox/TextLabel
@onready var btn_next: Button = $Margin/HBox/VBox/BtnNext

func _ready() -> void:
	btn_next.pressed.connect(func(): sig_next_clicked.emit())

func set_text(text: String, show_next_btn: bool = false) -> void:
	label.text = text
	btn_next.visible = show_next_btn
