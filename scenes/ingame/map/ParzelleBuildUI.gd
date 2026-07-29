extends PanelContainer

@onready var build_progress: ProgressBar = %BuildProgress
@onready var time_label: Label = %TimeLabel
@onready var title_label: Label = %TitleLabel

func _ready() -> void:
	title_label.text = GameState.T("plot.under_construction", "Parzelle im Bau")

func update_progress(progress: float, remaining_time: int) -> void:
	build_progress.value = progress * 100
	var r_h = remaining_time / 60
	var r_m = remaining_time % 60
	time_label.text = "%d%%  |  %dh %dm" % [int(progress * 100), r_h, r_m]
