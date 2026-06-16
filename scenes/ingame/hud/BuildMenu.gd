class_name BuildMenu
extends Control

# Signal an deinen Baumodus/Manager, wenn ein Raum final ausgewählt wird
signal sig_room_selected(room_scene: PackedScene)
signal sig_build_cancelled()

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
@onready var _breadcrumb: Label = $MarginContainer/VBoxContainer/BreadcrumbLabel

# =============================================================================
func _ready() -> void:
	top_level = true

	_sort_rooms_into_categories()
	_display_category_buttons()

	# Zeige beim ersten Öffnen direkt die erste Kategorie an (falls vorhanden)
	if _categories.keys().size() > 0:
		_show_category(_categories.keys()[0])

	visible = false

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
			"scene_path": scene_path,
			"def": def
		})


# # =============================================================================
# func _sort_rooms_into_categories() -> void:
# 	_categories.clear()

# 	for scene in room_scenes:
# 		if not scene: continue

# 		# 1. Wir instanziieren kurz, um an das Root-Skript zu kommen
# 		var temp_room = scene.instantiate()
# 		var script: Script = temp_room.get_script()

# 		if script and script.has_method("get_definition"):
# 			var def: Dictionary = script.call("get_definition")
# 			var cat_name: String = def.get("category", "Sonstiges")

# 			if not _categories.has(cat_name):
# 				_categories[cat_name] = []

# 			_categories[cat_name].append({
# 				"scene": scene,
# 				"def": def
# 			})

# 		temp_room.free()


# =============================================================================
## Erstellt die oberen Knöpfe für die Kategorien (Zimmer, Gastro etc.)
func _display_category_buttons() -> void:
	for child in category_grid.get_children():
		child.queue_free()

	for cat_name in _categories.keys():
		var new_instance = button_template.instantiate()
		category_grid.add_child(new_instance)

		var btn: Button = new_instance.get_node("%MenuButton") as Button

		# Daten aus dem GameState holen (mit Fallback-Werten zur Sicherheit)
		var cat_data: Dictionary = GameState.room_category_registry.get(cat_name.to_lower(), {})
		var icon_path: String = cat_data.get("icon", "res://assets/icons/HUDTop/house.svg")
		var label_text: String = cat_data.get("label", cat_name.capitalize())

		btn.icon = load(icon_path)
		btn.text = "" # Text weg, Fokus auf Icon
		btn.tooltip_text = "Kategorie: " + label_text

		_category_btns[cat_name] = btn

		btn.pressed.connect(func(): _show_category(cat_name))

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

# 		btn.text = "" # Text weg, Fokus auf Icon
# 		btn.tooltip_text = "Kategorie: " + cat_name.capitalize()

# 		# Gold-Style wie gehabt
# 		var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
# 		if style:
# 			style.bg_color = Color("#694f06")
# 			style.border_color = Color("#e3ae08")
# 			btn.add_theme_stylebox_override("normal", style)
# 			btn.add_theme_stylebox_override("hover", style)
# 			btn.add_theme_stylebox_override("pressed", style)
# 			btn.add_theme_stylebox_override("focus", style)

# 		btn.pressed.connect(func(): _show_category(cat_name))


# =============================================================================
func _show_category(cat_name: String) -> void:
	sig_build_cancelled.emit()
	
	for child in item_grid.get_children():
		child.queue_free()
	_room_btns.clear()

	for c_name in _category_btns.keys():
		_set_btn_active(_category_btns[c_name], c_name == cat_name)
		
	var cat_label = GameState.room_category_registry.get(cat_name.to_lower(), {}).get("label", cat_name.capitalize())
	_breadcrumb.text = "Kategorie: " + cat_label

	# Aktuelles Hotel-Level abfragen (Fallback auf 1, falls noch nichts geladen ist)
	var current_level: int = GameState.selected_hotel.get("level", 1)

	for room_data in _categories[cat_name]:
		var def: Dictionary = room_data["def"]
		var scene_path: String = room_data["scene_path"] # Pfad statt Szene

		var new_instance = button_template.instantiate()
		item_grid.add_child(new_instance)

		var btn: Button = new_instance.get_node("%MenuButton") as Button
		btn.icon = load(def.get("icon", ""))
		_room_btns.append(btn)

		var req_level: int = def.get("req_level", 1)
		var req_tech: String = def.get("req_tech", "")

		var level_ok: bool = current_level >= req_level
		var tech_ok: bool = req_tech == "" or TechtreeManager.is_tech_unlocked(req_tech)

		if level_ok and tech_ok:
			btn.disabled = false
			btn.tooltip_text = GameState.T("tt.build.room.cost", def.get("name", "Raum"), def.get("build_cost", 0))

			# Die Szene wird erst per load() geladen, wenn der Button geklickt wird
			btn.pressed.connect(func():
					for rb in _room_btns:
						_set_btn_active(rb, rb == btn)
					_breadcrumb.text = cat_label + " / " + GameState.T(def.get("name", "Raum"))
					
					var loaded_scene = load(scene_path) as PackedScene
					if loaded_scene:
							sig_room_selected.emit(loaded_scene)
			)

		else:
			btn.disabled = true
			var room_name = def.get("name", "Raum")
			
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
