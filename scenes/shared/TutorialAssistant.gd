extends PanelContainer
class_name TutorialAssistant

signal sig_next_clicked

@onready var label: Label = $Margin/HBox/VBox/TextLabel
@onready var btn_next: Button = $Margin/HBox/VBox/BtnNext
@onready var progress_bar: ProgressBar = $Margin/HBox/VBox/ProgressBar

func _ready() -> void:
	btn_next.pressed.connect(func(): sig_next_clicked.emit())
	btn_next.text = GameState.T("tutorial.btn.next")

func set_text(text: String, show_next_btn: bool = false) -> void:
	label.text = text
	btn_next.visible = show_next_btn
	progress_bar.visible = false

func set_progress(value: float, max_value: float = 100.0) -> void:
	progress_bar.visible = true
	progress_bar.max_value = max_value
	progress_bar.value = value
