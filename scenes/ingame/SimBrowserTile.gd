extends Button
class_name SimBrowserTile

@onready var avatar_panel: Panel = %AvatarPanel
@onready var lbl_abbr: Label = %LblAbbr
@onready var lbl_title: Label = %LblTitle
@onready var lbl_desc: Label = %LblDesc
@onready var lbl_status: Label = %LblStatus
@onready var lbl_cta: Label = %LblCTA

var site_data: Dictionary = {}

func setup(data: Dictionary) -> void:
	site_data = data
	lbl_abbr.text = data.get("abbr", "")
	lbl_title.text = GameState.T(data.get("title", ""))
	lbl_desc.text = GameState.T(data.get("desc", ""))
	
	# Fixes Styling wie vom User gewünscht: Dunkelblau, gelber Rahmen, gelbe Schrift
	var _dark_blue = Color(0.1, 0.12, 0.18, 1)
	var _yellow = Color(0.85, 0.7, 0.2, 1)
	
	lbl_cta.text = "▶ " + data.get("url", "app.sim")
	
	# Hover effekt (heller machen)
	mouse_entered.connect(func():
		modulate = Color(1.2, 1.2, 1.2)
	)
	mouse_exited.connect(func():
		modulate = Color(1.0, 1.0, 1.0)
	)

func set_locked(locked: bool) -> void:
	disabled = locked
	if locked:
		lbl_status.text = GameState.T("browser.status.locked")
		lbl_status.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		lbl_cta.text = GameState.T("browser.cta.denied")
		modulate = Color(0.5, 0.5, 0.5)
	else:
		lbl_status.text = GameState.T("browser.status.coming_soon")
		lbl_status.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		modulate = Color(1.0, 1.0, 1.0)
