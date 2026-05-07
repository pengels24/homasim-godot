extends PanelContainer
## ANG-195 – BuildPanel: horizontale Kategorie-Tabs + Item-Grid.
## Öffnet sich über der BottomBar. Kategorien auto-discovered aus ROOM_REGISTRY.

signal room_selected(room_type_id: String)

const ROOM_REGISTRY: Array[GDScript] = [
	preload("res://scenes/ingame/rooms/bed_standard/BedStandard.gd"),
	preload("res://scenes/ingame/rooms/bed_double/BedDouble.gd"),
]

const CATEGORIES: Array[Dictionary] = [
	{"id": "zimmer",     "icon": "res://assets/icons/bed.svg",            "label": "Zimmer"},
	{"id": "gastro",     "icon": "res://assets/icons/cooking-pot.svg",    "label": "Gastronomie"},
	{"id": "service",    "icon": "res://assets/icons/brush-cleaning.svg", "label": "Service"},
	{"id": "management", "icon": "res://assets/icons/laptop-minimal.svg", "label": "Management"},
]

const CAT_BTN_SIZE  := 46.0
const ITEM_BTN_SIZE := 52.0
const ICON_SIZE     := 26.0

# ── Zustand ───────────────────────────────────────────────────────────────────
var _room_items:        Dictionary = {}   # category_id → Array[Dictionary]
var _selected_category: String     = ""
var _cat_buttons:       Dictionary = {}   # category_id → Button
var _active_item_btn:   Button     = null

var _sb_cat_normal:  StyleBoxFlat
var _sb_cat_active:  StyleBoxFlat
var _sb_item_normal: StyleBoxFlat
var _sb_item_hover:  StyleBoxFlat
var _sb_item_active: StyleBoxFlat
var _tooltip_panel:  PanelContainer
var _tooltip_lbl:    Label

@onready var _category_tabs: HBoxContainer = $Margin/VBox/CategoryTabs
@onready var _item_grid:     GridContainer  = $Margin/VBox/ItemGrid


## Gibt die Definition eines Raums aus der Registry zurück.
static func find_definition(room_type_id: String) -> Dictionary:
	for script: GDScript in ROOM_REGISTRY:
		var def: Dictionary = script.get_definition()
		if def.get("id", "") == room_type_id:
			return def
	return {}


func _ready() -> void:
	_apply_panel_style()
	_build_room_items()
	_build_styleboxes()
	_build_tooltip()
	_build_category_tabs()
	_select_first_category()


# ── Aufbau ────────────────────────────────────────────────────────────────────

func _apply_panel_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.03, 0.06, 0.12, 0.95)
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_top           = 1
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_bottom        = 1
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.38)
	add_theme_stylebox_override("panel", sb)


func _build_room_items() -> void:
	for script: GDScript in ROOM_REGISTRY:
		var def: Dictionary = script.get_definition()
		if not def.get("in_build_menu", false):
			continue
		var cat: String = def.get("category", "")
		if cat == "":
			continue
		if not _room_items.has(cat):
			_room_items[cat] = []
		_room_items[cat].append(def)


func _build_styleboxes() -> void:
	var cr := int(CAT_BTN_SIZE * 0.5)
	_sb_cat_normal = _make_sb(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55), cr)
	_sb_cat_active = _make_sb(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0), cr)
	_sb_item_normal = _make_sb(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55), 8)
	_sb_item_hover  = _make_sb(Color(0.10, 0.16, 0.26, 0.96), Color(0.918, 0.702, 0.031, 0.70), 8)
	_sb_item_active = _make_sb(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0), 8)


func _build_category_tabs() -> void:
	for cat: Dictionary in CATEGORIES:
		var cat_id: String = cat["id"]
		if not _room_items.has(cat_id):
			continue
		var btn := _make_icon_btn(cat.get("icon", ""), cat.get("label", ""), CAT_BTN_SIZE, false)
		btn.add_theme_stylebox_override("normal",  _sb_cat_normal)
		btn.add_theme_stylebox_override("hover",   _sb_cat_normal)
		btn.add_theme_stylebox_override("pressed", _sb_cat_active)
		var cat_label: String = cat.get("label", "")
		btn.pressed.connect(func() -> void: _select_category(cat_id))
		btn.mouse_entered.connect(func() -> void: _show_tooltip(cat_label, btn))
		btn.mouse_exited.connect(_hide_tooltip)
		_category_tabs.add_child(btn)
		_cat_buttons[cat_id] = btn


func _select_first_category() -> void:
	for cat: Dictionary in CATEGORIES:
		if _room_items.has(cat["id"]):
			_select_category(cat["id"])
			return


# ── Interaktion ───────────────────────────────────────────────────────────────

func _select_category(cat_id: String) -> void:
	_selected_category = cat_id
	_refresh_cat_tabs()
	_refresh_item_grid()


func _refresh_cat_tabs() -> void:
	for cat_id: String in _cat_buttons:
		var btn: Button = _cat_buttons[cat_id]
		var active := cat_id == _selected_category
		btn.add_theme_stylebox_override("normal", _sb_cat_active if active else _sb_cat_normal)
		btn.add_theme_stylebox_override("hover",  _sb_cat_active if active else _sb_cat_normal)


func _refresh_item_grid() -> void:
	_hide_tooltip()
	for child in _item_grid.get_children():
		child.queue_free()
	var items: Array = _room_items.get(_selected_category, [])
	for item: Dictionary in items:
		_item_grid.add_child(_make_item_btn(item))


func _make_item_btn(item: Dictionary) -> Button:
	var locked: bool = item.get("locked", false)
	var btn := _make_icon_btn(item.get("icon", ""), item.get("label", "?"), ITEM_BTN_SIZE, locked)
	btn.add_theme_stylebox_override("normal",   _sb_item_normal)
	btn.add_theme_stylebox_override("hover",    _sb_item_hover)
	btn.add_theme_stylebox_override("pressed",  _sb_item_active)
	btn.add_theme_stylebox_override("disabled", _sb_item_normal)
	var tip_text := "%s · %d €" % [item.get("name", item.get("label", "?")), item.get("build_cost", 0)]
	btn.mouse_entered.connect(func() -> void: _show_tooltip(tip_text, btn))
	btn.mouse_exited.connect(_hide_tooltip)
	if not locked:
		var room_id: String = item["id"]
		btn.pressed.connect(func() -> void:
			_set_active_item(btn)
			room_selected.emit(room_id)
		)
	return btn


func _set_active_item(btn: Button) -> void:
	if is_instance_valid(_active_item_btn):
		_active_item_btn.add_theme_stylebox_override("normal", _sb_item_normal)
		_active_item_btn.add_theme_stylebox_override("hover",  _sb_item_hover)
	_active_item_btn = btn
	if is_instance_valid(btn):
		btn.add_theme_stylebox_override("normal", _sb_item_active)
		btn.add_theme_stylebox_override("hover",  _sb_item_active)


## Aufgerufen von IngameBuild wenn der Cursor abbricht – Button-Highlight zurücksetzen.
func clear_active_item() -> void:
	_set_active_item(null)


# ── Tooltip ───────────────────────────────────────────────────────────────────

func _build_tooltip() -> void:
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible      = false
	_tooltip_panel.z_index      = 100
	_tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.06, 0.10, 0.96)
	sb.corner_radius_top_left     = 6
	sb.corner_radius_top_right    = 6
	sb.corner_radius_bottom_left  = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_top           = 1
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.30)
	sb.content_margin_left        = 12.0
	sb.content_margin_right       = 12.0
	sb.content_margin_top         = 7.0
	sb.content_margin_bottom      = 7.0
	_tooltip_panel.add_theme_stylebox_override("panel", sb)
	_tooltip_lbl = Label.new()
	_tooltip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip_lbl.add_theme_font_size_override("font_size", 13)
	_tooltip_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	_tooltip_panel.add_child(_tooltip_lbl)
	# Tooltip als Geschwister-Node in der CanvasLayer – überlappt Build-Panel
	get_parent().add_child(_tooltip_panel)
	tree_exiting.connect(func() -> void:
		if is_instance_valid(_tooltip_panel):
			_tooltip_panel.queue_free()
	)


func _show_tooltip(text: String, source_btn: Control) -> void:
	_tooltip_lbl.text       = text
	_tooltip_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_tooltip_panel.visible  = true
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(_tooltip_panel) or not _tooltip_panel.visible:
		return
	var br := source_btn.get_global_rect()
	_tooltip_panel.position = Vector2(br.position.x, br.position.y - _tooltip_panel.size.y - 6.0)
	_tooltip_panel.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _hide_tooltip() -> void:
	if is_instance_valid(_tooltip_panel):
		_tooltip_panel.visible = false


# ── Button-Factory ────────────────────────────────────────────────────────────

func _make_icon_btn(icon_path: String, fallback_label: String, btn_size: float, locked: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(btn_size, btn_size)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.disabled            = locked
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var icon_node: Control
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex := TextureRect.new()
		tex.texture      = load(icon_path)
		tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size         = Vector2(ICON_SIZE, ICON_SIZE)
		tex.position     = Vector2((btn_size - ICON_SIZE) * 0.5, (btn_size - ICON_SIZE) * 0.5)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)
		icon_node = tex
	else:
		var lbl := Label.new()
		lbl.text                 = fallback_label
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.size                 = Vector2(btn_size, btn_size)
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
		lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)
		icon_node = lbl

	if locked:
		icon_node.modulate = Color(1.0, 1.0, 1.0, 0.35)
		var lock_lbl := Label.new()
		lock_lbl.text                 = "🔒"
		lock_lbl.anchor_right         = 1.0
		lock_lbl.anchor_bottom        = 1.0
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 14)
		lock_lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)

	return btn


func _make_sb(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.corner_radius_top_left     = radius
	sb.corner_radius_top_right    = radius
	sb.corner_radius_bottom_left  = radius
	sb.corner_radius_bottom_right = radius
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = border
	sb.shadow_color               = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size                = 4
	sb.shadow_offset              = Vector2(0.0, 2.0)
	return sb
