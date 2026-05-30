class_name BuildMenu
extends Control

# Signal an deinen Baumodus/Manager, wenn ein Raum final ausgewählt wird
signal sig_room_selected(room_scene: PackedScene)

@export_group("Vorlagen & Daten")
## WICHTIG: Ziehe hier im Inspektor deine NEUE, skriptlose 'BuildMenuButton.tscn' rein!
@export var button_template: PackedScene
## Hier wirfst du im Inspektor deine Zimmer-TSCNs rein
@export var room_scenes: Array[PackedScene]

@onready var category_grid: Container = $MarginContainer/VBoxContainer/CategoryGrid
@onready var item_grid: Container = $MarginContainer/VBoxContainer/ItemGrid

var _categories: Dictionary = {}

# =============================================================================
func _ready() -> void:
	top_level = true

	_sort_rooms_into_categories()
	_display_category_buttons()

	# Zeige beim ersten Öffnen direkt die erste Kategorie an (falls vorhanden)
	if _categories.keys().size() > 0:
		_show_category(_categories.keys()[0])

	visible = false

	InputHandler.sig_hotkey_build_menu_requested.connect(func():
		visible = (InputHandler.current_mode == InputHandler.InputMode.BUILD)

		if visible and get_parent() is Control:
			var parent_ctrl := get_parent() as Control
			global_position = parent_ctrl.global_position + Vector2(140, -160)
	)

# =============================================================================
func _sort_rooms_into_categories() -> void:
	_categories.clear()

	for scene in room_scenes:
		if not scene: continue

		# 1. Wir instanziieren kurz, um an das Root-Skript zu kommen
		var temp_room = scene.instantiate()
		var script: Script = temp_room.get_script()

		# 2. In Godot 4 nutzen wir has_method statt has_script_method
		if script and script.has_method("get_definition"):
			var def: Dictionary = script.call("get_definition")
			var cat_name: String = def.get("category", "Sonstiges")

			if not _categories.has(cat_name):
				_categories[cat_name] = []

			_categories[cat_name].append({
				"scene": scene,
				"def": def
			})

		# 3. Direkt wieder aufräumen
		temp_room.free()


# =============================================================================
# =============================================================================
## Erstellt die oberen Knöpfe für die Kategorien (Zimmer, Gastro etc.)
func _display_category_buttons() -> void:
	# Mapping: Kategorie-Name -> Pfad zum Icon
	var category_icons := {
		"zimmer": "res://assets/icons/HUDTop/house.svg",
		"gastro": "res://assets/icons/HUDBottom/utensils.svg",
		"service": "res://assets/icons/HUDBottom/brush-cleaning.svg",
		"management": "res://assets/icons/HUDBottom/laptop-minimal.svg",
		"sonstiges": "res://assets/icons/HUDBottom/wrench.svg"
	}

	for child in category_grid.get_children():
		child.queue_free()

	for cat_name in _categories.keys():
		var new_instance = button_template.instantiate()
		category_grid.add_child(new_instance)

		var btn: Button = new_instance.get_node("%MenuButton") as Button

		# Wähle das passende Icon aus dem Dictionary (Fallback auf 'house.svg', falls Name unbekannt)
		var icon_path = category_icons.get(cat_name.to_lower(), "res://assets/icons/HUDTop/house.svg")
		btn.icon = load(icon_path)

		btn.text = "" # Text weg, Fokus auf Icon
		btn.tooltip_text = "Kategorie: " + cat_name.capitalize()

		# Gold-Style wie gehabt
		var style: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
		if style:
			style.bg_color = Color("#694f06")
			style.border_color = Color("#e3ae08")
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_stylebox_override("focus", style)

		btn.pressed.connect(func(): _show_category(cat_name))


# =============================================================================
func _show_category(cat_name: String) -> void:
	for child in item_grid.get_children():
		child.queue_free()

	for room_data in _categories[cat_name]:
		var def: Dictionary = room_data["def"]
		var scene: PackedScene = room_data["scene"]

		var new_instance = button_template.instantiate()
		item_grid.add_child(new_instance)

		# WICHTIG: Auch hier suchen wir nach %MenuButton
		var btn: Button = new_instance.get_node("%MenuButton") as Button
		btn.icon = load(def.get("icon", ""))
		btn.tooltip_text = "%s\nKosten: %d €" % [def.get("name", "Raum"), def.get("build_cost", 0)]

		btn.pressed.connect(func(): sig_room_selected.emit(scene))
