extends VBoxContainer

@onready var tab_bar: HBoxContainer = %TabBar
@onready var item_list: VBoxContainer = %TutorialList
@onready var title_label: Label = %Title
@onready var desc_label: RichTextLabel = %Desc
@onready var texture_rect: TextureRect = %TextureRect

var _tutorials: Array = []
var _tabs: Array = ["tutorial", "tipps", "codex", "forschung"]
var _tab_labels: Array = ["ui.tutorial.tab.tutorial", "ui.tutorial.tab.tipps", "ui.tutorial.tab.codex", "ui.tutorial.tab.forschung"]
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
	if _current_tab == "forschung":
		_tutorials = []
	elif TutorialManager:
		_tutorials = TutorialManager.get_unlocked_data(_current_tab)
	else:
		_tutorials = []
		
	_populate_list()
	
	if _current_tab == "forschung":
		_clear_display()
		title_label.text = GameState.T("ui.tutorial.tab.forschung", "Forschung")
		desc_label.text = GameState.T("ui.tutorial.forschung.intro", "Wähle links eine Kategorie, um alle Forschungs-Projekte zu sehen.")
		texture_rect.texture = preload("res://assets/icons/HUDBottom/flask-conical.svg")
		texture_rect.show()
	elif _tutorials.size() > 0:
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
		
	if _current_tab == "forschung":
		_populate_techtree_list()
		return
		
	var idx = 0
	for tut in _tutorials:
		var title_key = tut.get("title_key", "")
		var text = GameState.T(title_key) if GameState else title_key
		var btn = Button.new()
		btn.text = text
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_set_btn_style(btn, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
		btn.add_theme_font_size_override("font_size", 22)
		btn.pressed.connect(_on_item_selected.bind(idx))
		item_list.add_child(btn)
		idx += 1

func _populate_techtree_list() -> void:
	if not TechtreeManager: return
	
	var categories = {}
	for tech_id in TechtreeManager.tech_registry:
		var node = TechtreeManager.tech_registry[tech_id]
		var cat = node.get("category", "allgemein")
		if not categories.has(cat):
			categories[cat] = []
		categories[cat].append(node)
		
	var cat_order = ["zimmer", "gastronomie", "wellness", "management", "prestige"]
	for cat in cat_order:
		if not categories.has(cat): continue
		var nodes = categories[cat]
		nodes.sort_custom(func(a, b): return a.get("id", "") < b.get("id", ""))
		
		var cat_btn = Button.new()
		var cat_name = GameState.T("techtree.category." + cat, cat.capitalize())
		cat_btn.text = "▶ " + cat_name
		cat_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		_set_btn_style(cat_btn, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
		cat_btn.add_theme_font_size_override("font_size", 22)
		item_list.add_child(cat_btn)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.visible = false
		item_list.add_child(margin)
		
		var inner_vbox = VBoxContainer.new()
		inner_vbox.add_theme_constant_override("separation", 5)
		margin.add_child(inner_vbox)
		
		cat_btn.pressed.connect(func():
			margin.visible = not margin.visible
			if margin.visible:
				cat_btn.text = "▼ " + cat_name
			else:
				cat_btn.text = "▶ " + cat_name
		)
		
		for node in nodes:
			var tech_btn = Button.new()
			var tech_name = GameState.T(node.get("name", node.get("id", "")))
			tech_btn.text = node.get("id", "") + " - " + tech_name
			tech_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			_set_btn_style(tech_btn, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
			tech_btn.add_theme_font_size_override("font_size", 20)
			inner_vbox.add_child(tech_btn)
			
			tech_btn.pressed.connect(func():
				_on_tech_selected(node)
				for c in item_list.get_children():
					if c is Button:
						_set_btn_style(c, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
					elif c is MarginContainer:
						for b in c.get_child(0).get_children():
							if b is Button:
								_set_btn_style(b, SB_DARK, SB_DARK_HOVER, SB_DARK_PRESSED)
				# Highlight clicked button and its parent category
				_set_btn_style(tech_btn, SB_BLUE, SB_BLUE_HOVER, SB_BLUE_PRESSED)
				_set_btn_style(cat_btn, SB_BLUE, SB_BLUE_HOVER, SB_BLUE_PRESSED)
			)

func _on_tech_selected(node: Dictionary) -> void:
	var tech_id = node.get("id", "")
	var title_key = node.get("name", tech_id)
	var desc_key = title_key + ".desc"
	
	title_label.text = GameState.T(title_key) if GameState else title_key
	
	var desc_text = GameState.T(desc_key) if GameState else desc_key
	if desc_text == desc_key:
		desc_text = "Keine Beschreibung verfügbar."
		
	desc_label.text = desc_text
	texture_rect.texture = preload("res://assets/icons/angelus2010/HUDBottom/ang-flask.aseprite")
	texture_rect.show()

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

func open_tech(tech_id: String) -> void:
	if _current_tab != "forschung":
		_on_tab_selected("forschung")
		
	for i in range(item_list.get_child_count()):
		var margin = item_list.get_child(i)
		if margin is MarginContainer:
			var vbox = margin.get_child(0)
			for tech_btn in vbox.get_children():
				if tech_btn is Button and tech_btn.text.begins_with(tech_id + " -"):
					var cat_btn = item_list.get_child(i - 1)
					if not margin.visible:
						cat_btn.pressed.emit()
					tech_btn.pressed.emit()
					return
