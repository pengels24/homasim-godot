class_name BuildMenu
extends Control

# Signal an deinen Baumodus/Manager, wenn ein Raum final ausgewählt wird
signal sig_room_selected(room_scene: PackedScene)
signal sig_tool_selected(action_id: String)
signal sig_build_cancelled()
signal sig_build_mode_requested(active: bool)

@export_group("Vorlagen & Daten")
## WICHTIG: Ziehe hier im Inspektor deine NEUE, skriptlose 'BuildMenuButton.tscn' rein!
@export var button_template: PackedScene
## Hier wirfst du im Inspektor deine Zimmer-TSCNs rein
# @export var room_scenes: Array[PackedScene]

@onready var category_grid: Container = $MarginContainer/VBoxContainer/CategoryGrid
@onready var item_grid: Container = $MarginContainer/VBoxContainer/ItemGrid

var _categories: Dictionary = {}
var _category_btns: Dictionary = {}
var _room_btns: Array = []
var _current_category: String = ""
@onready var _breadcrumb: Label = $MarginContainer/VBoxContainer/BreadcrumbLabel

# =============================================================================
func _ready() -> void:
	_sort_rooms_into_categories()
	_display_category_buttons()
	_set_breadcrumb("")
		
	visibility_changed.connect(_on_visibility_changed)


# =============================================================================
func _on_visibility_changed() -> void:
	if visible and _current_category != "":
		_show_category(_current_category)

# =============================================================================
func _set_btn_active(btn: Button, active: bool) -> void:
	if active:
		var s: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if s:
			s.bg_color = Color("#694f06")
			s.border_color = Color("#e3ae08")
			btn.add_theme_stylebox_override("normal", s)
			btn.add_theme_stylebox_override("hover", s)
			btn.add_theme_stylebox_override("pressed", s)
			btn.add_theme_stylebox_override("focus", s)
	else:
		btn.remove_theme_stylebox_override("normal")
		btn.remove_theme_stylebox_override("hover")
		btn.remove_theme_stylebox_override("pressed")
		btn.remove_theme_stylebox_override("focus")


# =============================================================================
func _sort_rooms_into_categories() -> void:
	_categories.clear()

	# Wir iterieren über das zentrale Registry aus dem GameState
	for room_id in GameState.room_registry:
		var registry_entry: Dictionary = GameState.room_registry[room_id]
		var def: Dictionary = registry_entry.get("def", {})
		var scene_path: String = registry_entry.get("scene_path", "")

		# Nur Räume aufnehmen, die auch im Baumenü sichtbar sein sollen
		if not def.get("in_build_menu", false):
			continue

		var cat_name: String = def.get("category", "sonstiges").to_lower()

		if not _categories.has(cat_name):
			_categories[cat_name] = []

		# Wir speichern nur noch den Pfad zur Szene, nicht die geladene Szene
		_categories[cat_name].append({
			"is_tool": false,
			"scene_path": scene_path,
			"def": def
		})

	# --- NEU: Werkzeuge (Tools) laden ---
	for tool_id in GameState.tool_registry:
		var registry_entry: Dictionary = GameState.tool_registry[tool_id]
		var def: Dictionary = registry_entry.get("def", {})

		# Nur Tools aufnehmen, die auch im Baumenü sichtbar sein sollen
		if not def.get("in_build_menu", true) or tool_id == "demolish":
			continue

		var cat_name: String = def.get("category", "werkzeuge").to_lower()

		if not _categories.has(cat_name):
			_categories[cat_name] = []

		_categories[cat_name].append({
			"is_tool": true,
			"def": def
		})


# # =============================================================================
# func _sort_rooms_into_categories() -> void:
# =============================================================================
## Erstellt die oberen Knöpfe für die Kategorien (Zimmer, Gastro etc.)
func _display_category_buttons() -> void:
	for child in category_grid.get_children():
		child.queue_free()

	for cat_name in _categories.keys():
		var new_instance = button_template.instantiate()
		category_grid.add_child(new_instance)

		var btn: Button = new_instance.get_node("%MenuButton") as Button
		btn.focus_mode = Control.FOCUS_NONE

		# Daten aus dem GameState holen (mit Fallback-Werten zur Sicherheit)
		var cat_data: Dictionary = GameState.room_category_registry.get(cat_name.to_lower(), {})
		var icon_path: String = cat_data.get("icon", "res://assets/icons/HUDTop/house.svg")
		var _raw_label: String = cat_data.get("label", cat_name.capitalize())
		var label_text: String = GameState.T("room_category." + cat_name.to_lower())

		btn.icon = load(icon_path)
		btn.text = "" # Text weg, Fokus auf Icon
		btn.tooltip_text = GameState.T("ui.buildmenu.category", label_text)

		_category_btns[cat_name] = btn

		btn.pressed.connect(func(): _show_category(cat_name))

	# NEU: Abriss-Button ganz rechts
	var dem_inst = button_template.instantiate()
	category_grid.add_child(dem_inst)
	var dem_btn: Button = dem_inst.get_node("%MenuButton") as Button
	dem_btn.focus_mode = Control.FOCUS_NONE
	dem_btn.icon = load("res://assets/icons/HUDBottom/hammer.svg")
	dem_btn.text = ""
	dem_btn.tooltip_text = GameState.T("ui.buildmenu.demolish", "Abriss")
	_category_btns["demolish"] = dem_btn
	dem_btn.pressed.connect(func(): _show_category("demolish"))

# # =============================================================================
# ## Erstellt die oberen Knöpfe für die Kategorien (Zimmer, Gastro etc.)
# func _display_category_buttons() -> void:
# 	# Mapping: Kategorie-Name -> Pfad zum Icon
# 	# todo - category-list extern auslagern - wg modding
# 	var category_icons := {
# 		"zimmer": "res://assets/icons/HUDTop/house.svg",
# 		"gastro": "res://assets/icons/HUDBottom/utensils.svg",
# 		"service": "res://assets/icons/HUDBottom/brush-cleaning.svg",
# 		"management": "res://assets/icons/HUDBottom/laptop-minimal.svg",
# 		"sonstiges": "res://assets/icons/HUDBottom/wrench.svg"
# 	}

# 	for child in category_grid.get_children():
# 		child.queue_free()

# 	for cat_name in _categories.keys():
# 		var new_instance = button_template.instantiate()
# 		category_grid.add_child(new_instance)

# 		var btn: Button = new_instance.get_node("%MenuButton") as Button

# 		var icon_path = category_icons.get(cat_name.to_lower(), "res://assets/icons/HUDTop/house.svg")
# 		btn.icon = load(icon_path)




# =============================================================================
func _show_category(cat_name: String) -> void:
	if _current_category == cat_name:
		close_build_menu()
		return

	_current_category = cat_name
	sig_build_cancelled.emit()
	sig_build_mode_requested.emit(true)
	
	for child in item_grid.get_children():
		child.queue_free()
	_room_btns.clear()

	for btn_cat in _category_btns:
		_set_btn_active(_category_btns[btn_cat], btn_cat == cat_name)
		
	if cat_name == "demolish":
		_set_breadcrumb(" > " + GameState.T("ui.buildmenu.demolish", "Abriss"))
		sig_tool_selected.emit("demolish")
		return

	var cat_label = GameState.T("room_category." + cat_name.to_lower())
	_set_breadcrumb(GameState.T("ui.buildmenu.category", cat_label))

	# Aktuelles Hotel-Level abfragen (Fallback auf 1, falls noch nichts geladen ist)
	var current_level: int = GameState.selected_hotel.get("level", 1)

	for room_data in _categories[cat_name]:
		var def: Dictionary = room_data["def"]
		var is_tool: bool = room_data.get("is_tool", false)
		var scene_path: String = room_data.get("scene_path", "") # Pfad statt Szene

		var new_instance = button_template.instantiate()
		item_grid.add_child(new_instance)

		var btn: Button = new_instance.get_node("%MenuButton") as Button
		btn.focus_mode = Control.FOCUS_NONE
		btn.icon = load(def.get("icon", ""))
		btn.set_meta("room_id", def.get("id", ""))
		_room_btns.append(btn)

		var req_level: int = def.get("req_level", 1)
		var req_tech: String = def.get("req_tech", "")

		var level_ok: bool = current_level >= req_level
		var tech_ok: bool = req_tech == "" or TechtreeManager.is_tech_unlocked(req_tech)

		if level_ok and tech_ok:
			btn.disabled = false
			var item_name = GameState.T(def.get("name", "Raum"))
			btn.tooltip_text = GameState.T("tt.build.room.cost", item_name, def.get("build_cost", 0))

			# Die Szene wird erst per load() geladen, wenn der Button geklickt wird
			btn.pressed.connect(func():
					for rb in _room_btns:
						_set_btn_active(rb, rb == btn)
					_set_breadcrumb(cat_label + " / " + GameState.T(def.get("name", "Raum")))
					
					if is_tool:
						sig_tool_selected.emit(def.get("action", ""))
					else:
						var loaded_scene = load(scene_path) as PackedScene
						if loaded_scene:
							sig_room_selected.emit(loaded_scene)
			)

		else:
			btn.disabled = true
			var room_name = GameState.T(def.get("name", "Raum"))
			
			if not level_ok and not tech_ok:
				btn.tooltip_text = GameState.T("tt.build.room.locked_both", room_name, req_level)
				
			elif not level_ok:
				btn.tooltip_text = GameState.T("tt.build.room.locked", room_name, req_level)
				
			else:
				btn.tooltip_text = GameState.T("tt.build.room.locked_tech", room_name)

	# for room_data in _categories[cat_name]:
	# 	var def: Dictionary = room_data["def"]
	# 	var scene: PackedScene = room_data["scene"]

	# 	var new_instance = button_template.instantiate()
	# 	item_grid.add_child(new_instance)

	# 	# WICHTIG: Auch hier suchen wir nach %MenuButton
	# 	var btn: Button = new_instance.get_node("%MenuButton") as Button
	# 	btn.icon = load(def.get("icon", ""))

	# 	# --- NEU: Sperr-Logik (Level & Tech) ---
	# 	var req_level: int = def.get("req_level", 1)

	# 	if current_level >= req_level:
	# 		# Raum ist freigeschaltet
	# 		btn.disabled = false
	# 		btn.tooltip_text = GameState.T("tt.build.room.cost", def.get("name", "Raum"), def.get("build_cost", 0))
	# 		# Klick-Event nur verbinden, wenn freigeschaltet!
	# 		btn.pressed.connect(func(): sig_room_selected.emit(scene))

	# 	else:
	# 		# Raum ist noch gesperrt
	# 		btn.disabled = true
	# 		btn.tooltip_text = GameState.T("tt.build.room.locked", def.get("name", "Raum"), req_level)

func get_room_button(room_id: String) -> Button:
	for btn in _room_btns:
		if is_instance_valid(btn) and btn.get_meta("room_id") == room_id:
			return btn
	return null

func get_category_button(cat_name: String) -> Button:
	if _category_btns.has(cat_name):
		return _category_btns[cat_name]
	return null

func set_locked(is_locked: bool) -> void:
	for btn in _category_btns.values():
		if is_instance_valid(btn):
			btn.disabled = is_locked

func close_build_menu() -> void:
	if _current_category != "":
		_current_category = ""
		_set_breadcrumb("")
		for child in item_grid.get_children():
			child.queue_free()
		_room_btns.clear()
		for btn in _category_btns.values():
			_set_btn_active(btn, false)
		sig_build_cancelled.emit()
		sig_build_mode_requested.emit(false)

func clear_active_button() -> void:
	for rb in _room_btns:
		_set_btn_active(rb, false)
		
	if _current_category == "demolish":
		_set_breadcrumb(" > " + GameState.T("ui.buildmenu.demolish", "Abriss"))
	elif _current_category != "":
		var cat_label = GameState.T("room_category." + _current_category.to_lower())
		_set_breadcrumb(GameState.T("ui.buildmenu.category", cat_label))
	else:
		_set_breadcrumb("")

func _set_breadcrumb(text: String) -> void:
	_breadcrumb.text = text
	_breadcrumb.visible = (text != "")
