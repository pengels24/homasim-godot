extends VBoxContainer

@onready var tab_bar: HBoxContainer = %TabBar
@onready var item_list: VBoxContainer = %TutorialList
@onready var title_label: Label = %Title
@onready var desc_label: RichTextLabel = %Desc
@onready var texture_rect: TextureRect = %TextureRect

var _tutorials: Array = []
var _tabs: Array = ["tutorial", "tipps", "codex"]
var _tab_labels: Array = ["ui.tutorial.tab.tutorial", "ui.tutorial.tab.tipps", "ui.tutorial.tab.codex"]
var _current_tab: String = "tutorial"
var _tab_buttons: Array[Button] = []

var SB_BLUE = preload("res://assets/UI/menu_button_blue.tres")
var SB_BLUE_HOVER = preload("res://assets/UI/menu_button_blue_hover.tres")
var SB_BLUE_PRESSED = preload("res://assets/UI/menu_button_blue_pressed.tres")

var SB_DARK = preload("res://assets/UI/menu_button_darkblue.tres")
var SB_DARK_HOVER = preload("res://assets/UI/menu_button_darkblue_hover.tres")
var SB_DARK_PRESSED = preload("res://assets/UI/menu_button_darkblue_pressed.tres")

func _ready() -> void:
	_setup_tabs()
	_load_data()

func _setup_tabs() -> void:
	for i in _tabs.size():
		var btn = Button.new()
		btn.text = GameState.T(_tab_labels[i]) if GameState else _tab_labels[i]
		btn.custom_minimum_size = Vector2(150, 40)
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		btn.pressed.connect(_on_tab_selected.bind(_tabs[i]))
		tab_bar.add_child(btn)
		_tab_buttons.append(btn)

func _on_tab_selected(tab_id: String) -> void:
	_current_tab = tab_id
	_load_data()

func _load_data() -> void:
	if TutorialManager:
		_tutorials = TutorialManager.get_unlocked_data(_current_tab)
	else:
		_tutorials = []
		
	_populate_list()
	
	if _tutorials.size() > 0:
		_on_item_selected(0)
	else:
		_clear_display()
		
	# Style tabs
	for i in _tabs.size():
		if _tabs[i] == _current_tab:
			_set_btn_style(_tab_buttons[i], SB_BLUE, SB_BLUE_HOVER, SB_BLUE_PRESSED)
		else:
			_set_btn_style(_tab_buttons[i], SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)

func _set_btn_style(btn: Button, normal, hover, pressed) -> void:
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_stylebox_override("focus", normal)

func _populate_list() -> void:
	for c in item_list.get_children():
		c.queue_free()
	var idx = 0
	for tut in _tutorials:
		var title_key = tut.get("title_key", "")
		var text = GameState.T(title_key) if GameState else title_key
		var btn = Button.new()
		btn.text = text
		_set_btn_style(btn, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_item_selected.bind(idx))
		item_list.add_child(btn)
		idx += 1

func _on_item_selected(index: int) -> void:
	if index < 0 or index >= _tutorials.size(): return
	var tut = _tutorials[index]
	
	var title_key = tut.get("title_key", "")
	var desc_key = tut.get("desc_key", "")
	var image_path = tut.get("image", "")
	
	title_label.text = GameState.T(title_key) if GameState else title_key
	desc_label.text = GameState.T(desc_key) if GameState else desc_key
	
	if image_path != "":
		texture_rect.texture = load(image_path)
		texture_rect.show()
	else:
		texture_rect.hide()
		
	var i = 0
	for c in item_list.get_children():
		if c.is_queued_for_deletion():
			continue
		if c is Button:
			if i == index:
				_set_btn_style(c, SB_BLUE, SB_BLUE_HOVER, SB_BLUE_PRESSED)
			else:
				_set_btn_style(c, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
			i += 1

func _clear_display() -> void:
	title_label.text = GameState.T("ui.tutorial.empty", "Noch keine Einträge freigeschaltet.")
	desc_label.text = ""
	texture_rect.hide()
