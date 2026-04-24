extends CanvasLayer
## ANG-168 – Kreismenü Baumodus.
## Öffnet sich rechts am Bildschirmrand. Klick auf Kategorie → Ring 2 zeigt passende Räume.
## Schließen: ESC, F2 oder Klick auf den Overlay-Hintergrund.

signal room_selected(room_type_id: String)
signal category_changed(cat_id: String)

## Wird von Ingame.gd gesetzt – letzte Kategorie wird beim Öffnen direkt aktiv
var initial_category: String = ""

# ── Geometrie-Konstanten ──────────────────────────────────────────────────────
const CM_BTN_SIZE    := 52.0   # Buttons in Ring 1 + 2
const CM_CENTER_SIZE := 64.0   # Zentraler Bau-Button
const CM_RING1_R     := 115.0  # Radius Kategorie-Ring
const CM_RING2_R     := 195.0  # Radius Raum-Ring
const CM_SEP1_R      := 82.0   # Innerer Trennring
const CM_SEP2_R      := 157.0  # Äußerer Trennring
const CM_BG_R        := 238.0  # Hintergrund-Kreisradius

# ── Kategorie-Definitionen ────────────────────────────────────────────────────
const CATEGORIES: Array[Dictionary] = [
	{"id": "zimmer",     "icon": "res://assets/icons/bed.svg",            "label": "Zimmer",       "angle": 270.0},
	{"id": "gastro",     "icon": "res://assets/icons/cooking-pot.svg",    "label": "Gastronomie",  "angle": 0.0},
	{"id": "service",    "icon": "res://assets/icons/brush-cleaning.svg", "label": "Service",      "angle": 90.0},
	{"id": "management", "icon": "res://assets/icons/laptop-minimal.svg", "label": "Management",   "angle": 180.0},
]

# ── Raum-Definitionen je Kategorie (aus RoomDefinitions) ─────────────────────
# "label" = Kurztext (Icon-Fallback), "name" = Langtext (Tooltip) – später via GameState.T()
const ROOM_ITEMS: Dictionary = {
	"zimmer": [
		{"id": "bed_standard", "icon": "res://assets/icons/bed-single.svg", "label": "EZ",  "name": "Einzelzimmer",    "cost": 500,  "locked": false},
		{"id": "bed_double",   "icon": "res://assets/icons/bed-double.svg", "label": "DZ",  "name": "Doppelzimmer",    "cost": 800,  "locked": false},
		{"id": "bed_family",   "icon": "res://assets/icons/users.svg",      "label": "FZ",  "name": "Familienzimmer",  "cost": 1300, "locked": true},
		{"id": "bed_superior", "icon": "res://assets/icons/star.svg",       "label": "Sup", "name": "Superior Zimmer", "cost": 1000, "locked": true},
	],
	"gastro": [
		{"id": "kitchen",    "icon": "res://assets/icons/chef-hat.svg",  "label": "Küche", "name": "Küche",      "cost": 1500, "locked": true},
		{"id": "restaurant", "icon": "res://assets/icons/utensils.svg",  "label": "Rest.", "name": "Restaurant", "cost": 2000, "locked": true},
		{"id": "bar",        "icon": "res://assets/icons/wine.svg",      "label": "Bar",   "name": "Bar",        "cost": 1800, "locked": true},
	],
	"service": [
		{"id": "bathroom",   "icon": "res://assets/icons/bath.svg",        "label": "Bad",  "name": "Badezimmer",    "cost": 400,  "locked": false},
		{"id": "fitness",    "icon": "res://assets/icons/dumbbell.svg",    "label": "Fit",  "name": "Fitnessraum",   "cost": 2500, "locked": true},
		{"id": "conference", "icon": "res://assets/icons/presentation.svg","label": "Konf", "name": "Konferenzraum", "cost": 3000, "locked": true},
	],
	"management": [
		{"id": "hr_office", "icon": "res://assets/icons/users-round.svg", "label": "Pers", "name": "Personalbüro",  "cost": 800,  "locked": true},
		{"id": "pl_office", "icon": "res://assets/icons/briefcase.svg",   "label": "Plan", "name": "Planungsbüro",  "cost": 1200, "locked": true},
	],
}

# ── Zustand ───────────────────────────────────────────────────────────────────
var _selected_category: String = ""
var _root:             Control
var _ring2_container:  Control
var _sep_ring2:        Panel            # äußerer Trennring – nur sichtbar wenn Ring 2 aktiv
var _cat_buttons:      Dictionary = {}   # category_id → Button

# Gemeinsame StyleBoxen – einmal erstellen, überall renutzen
var _sb_normal: StyleBoxFlat
var _sb_hover:  StyleBoxFlat
var _sb_active: StyleBoxFlat


func _ready() -> void:
	layer = 2
	_sb_normal = _make_btn_sb(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55))
	_sb_hover  = _make_btn_sb(Color(0.10, 0.16, 0.26, 0.96), Color(0.918, 0.702, 0.031, 0.70))
	_sb_active = _make_btn_sb(Color(0.22, 0.16, 0.02, 1.00),  Color(0.918, 0.702, 0.031, 1.00))
	_build_menu()
	if initial_category != "":
		_on_category_pressed(initial_category)


# ── Aufbau ───────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	# Halbtransparenter Overlay – Klick darauf schließt das Menü
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.45)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	add_child(overlay)

	# Zentraler Root – (0,0) liegt rechts, vertikal mittig, mit 24px Rand
	_root = Control.new()
	_root.anchor_left   = 1.0
	_root.anchor_right  = 1.0
	_root.anchor_top    = 0.5
	_root.anchor_bottom = 0.5
	_root.offset_left   = -(CM_BG_R + 24.0)
	_root.offset_right  = -(CM_BG_R + 24.0)
	add_child(_root)

	_add_background()
	_add_separator_rings()
	_add_center_button()

	# Ring 2 wird dynamisch befüllt; Container schon jetzt anlegen
	_ring2_container = Control.new()
	_ring2_container.visible  = false
	_ring2_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_ring2_container)

	_add_ring1_buttons()


func _add_background() -> void:
	# Drei gestapelte Kreise erzeugen einen Stufen-Gradienten: außen dunkel → innen heller
	var zones: Array[Array] = [
		[CM_BG_R,   Color(0.02, 0.05, 0.10, 0.95), Color(0.918, 0.702, 0.031, 0.38)],
		[CM_SEP2_R, Color(0.05, 0.09, 0.18, 0.95), Color(0, 0, 0, 0)],
		[CM_SEP1_R, Color(0.08, 0.14, 0.26, 0.95), Color(0, 0, 0, 0)],
	]
	for zone: Array in zones:
		var rad: float  = zone[0]
		var ri:  int    = int(rad)
		var sb := StyleBoxFlat.new()
		sb.bg_color                   = zone[1]
		sb.corner_radius_top_left     = ri
		sb.corner_radius_top_right    = ri
		sb.corner_radius_bottom_left  = ri
		sb.corner_radius_bottom_right = ri
		sb.border_width_left   = 1
		sb.border_width_right  = 1
		sb.border_width_top    = 1
		sb.border_width_bottom = 1
		sb.border_color = zone[2]
		var panel := Panel.new()
		panel.add_theme_stylebox_override("panel", sb)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.size         = Vector2(rad * 2.0, rad * 2.0)
		panel.position     = Vector2(-rad, -rad)
		_root.add_child(panel)


func _add_separator_rings() -> void:
	for sep_r: float in [CM_SEP1_R, CM_SEP2_R]:
		var r := int(sep_r)
		var sb := StyleBoxFlat.new()
		sb.bg_color                   = Color(0, 0, 0, 0)
		sb.corner_radius_top_left     = r
		sb.corner_radius_top_right    = r
		sb.corner_radius_bottom_left  = r
		sb.corner_radius_bottom_right = r
		sb.border_width_left   = 1
		sb.border_width_right  = 1
		sb.border_width_top    = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.918, 0.702, 0.031, 0.22)
		var ring := Panel.new()
		ring.add_theme_stylebox_override("panel", sb)
		ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring.size         = Vector2(sep_r * 2.0, sep_r * 2.0)
		ring.position     = Vector2(-sep_r, -sep_r)
		_root.add_child(ring)
		if sep_r == CM_SEP2_R:
			ring.visible = false
			_sep_ring2 = ring


func _add_center_button() -> void:
	var half := CM_CENTER_SIZE * 0.5
	var r    := int(half)
	var sb   := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.07, 0.13, 0.96)
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_left  = r
	sb.corner_radius_bottom_right = r
	sb.border_width_left   = 2
	sb.border_width_right  = 2
	sb.border_width_top    = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.918, 0.702, 0.031, 0.85)

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CM_CENTER_SIZE, CM_CENTER_SIZE)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.disabled            = true
	btn.position            = Vector2(-half, -half)
	for state in ["normal", "hover", "pressed", "disabled"]:
		btn.add_theme_stylebox_override(state, sb)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())

	var icon_path := "res://assets/icons/ic_buildmode.svg"
	if ResourceLoader.exists(icon_path):
		var tex := TextureRect.new()
		tex.texture      = load(icon_path)
		tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size         = Vector2(28, 28)
		tex.position     = Vector2((CM_CENTER_SIZE - 28) * 0.5, (CM_CENTER_SIZE - 28) * 0.5)
		tex.modulate     = Color(0.918, 0.702, 0.031, 1)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)

	_root.add_child(btn)


func _add_ring1_buttons() -> void:
	for cat: Dictionary in CATEGORIES:
		var angle_rad := deg_to_rad(cat["angle"])
		var center    := Vector2(cos(angle_rad) * CM_RING1_R, sin(angle_rad) * CM_RING1_R)
		var btn       := _make_icon_btn(cat["icon"], cat["label"], false)
		btn.tooltip_text = cat["label"]
		btn.position     = center - Vector2(CM_BTN_SIZE, CM_BTN_SIZE) * 0.5
		btn.pressed.connect(func() -> void: _on_category_pressed(cat["id"]))
		_root.add_child(btn)
		_cat_buttons[cat["id"]] = btn


# ── Interaktion ───────────────────────────────────────────────────────────────

func _on_category_pressed(cat_id: String) -> void:
	if _selected_category == cat_id:
		_selected_category = ""
		_ring2_container.visible = false
		_sep_ring2.visible       = false
		_refresh_cat_states()
		return
	_selected_category = cat_id
	category_changed.emit(cat_id)
	_refresh_cat_states()
	_build_ring2(cat_id)
	_ring2_container.visible = true
	_sep_ring2.visible       = true


func _refresh_cat_states() -> void:
	for cat_id: String in _cat_buttons:
		var btn: Button = _cat_buttons[cat_id]
		if cat_id == _selected_category:
			btn.add_theme_stylebox_override("normal", _sb_active)
			btn.add_theme_stylebox_override("hover",  _sb_active)
		else:
			btn.add_theme_stylebox_override("normal", _sb_normal)
			btn.add_theme_stylebox_override("hover",  _sb_hover)


func _build_ring2(cat_id: String) -> void:
	for child in _ring2_container.get_children():
		child.queue_free()

	var items: Array = ROOM_ITEMS.get(cat_id, [])
	if items.is_empty():
		return

	var count      := items.size()
	var angle_step := 360.0 / float(count)

	for i in count:
		var item: Dictionary = items[i]
		var angle_rad := deg_to_rad(-90.0 + i * angle_step)
		var center    := Vector2(cos(angle_rad) * CM_RING2_R, sin(angle_rad) * CM_RING2_R)
		var btn       := _make_item_btn(item)
		btn.position    = center - Vector2(CM_BTN_SIZE, CM_BTN_SIZE) * 0.5
		_ring2_container.add_child(btn)


func _on_room_pressed(room_id: String) -> void:
	room_selected.emit(room_id)
	close()


func close() -> void:
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_F2:
			close()


# ── Button-Factories ──────────────────────────────────────────────────────────

func _make_icon_btn(icon_path: String, fallback_label: String, locked: bool) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(CM_BTN_SIZE, CM_BTN_SIZE)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.disabled            = locked
	btn.add_theme_stylebox_override("normal",   _sb_normal)
	btn.add_theme_stylebox_override("hover",    _sb_hover)
	btn.add_theme_stylebox_override("pressed",  _sb_active)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", _sb_normal)

	const ICON_D   := 26.0
	const ICON_OFF := (CM_BTN_SIZE - ICON_D) * 0.5
	var icon_node: Control
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex := TextureRect.new()
		tex.texture      = load(icon_path)
		tex.expand_mode  = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.size         = Vector2(ICON_D, ICON_D)
		tex.position     = Vector2(ICON_OFF, ICON_OFF)
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)
		icon_node = tex
	else:
		var lbl := Label.new()
		lbl.text                 = fallback_label
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.size                 = Vector2(CM_BTN_SIZE, CM_BTN_SIZE)
		lbl.position             = Vector2.ZERO
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		lbl.mouse_filter         = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)
		icon_node = lbl

	if locked:
		icon_node.modulate = Color(1, 1, 1, 0.35)
		var lock_lbl := Label.new()
		lock_lbl.text                = "🔒"
		lock_lbl.anchor_right        = 1.0
		lock_lbl.anchor_bottom       = 1.0
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 14)
		lock_lbl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)

	return btn


func _make_item_btn(item: Dictionary) -> Button:
	var locked: bool = item.get("locked", false)
	var btn := _make_icon_btn(item.get("icon", ""), item.get("label", "?"), locked)
	var name_text: String = item.get("name", item.get("label", "?"))
	var cost:      int    = item.get("cost", 0)
	btn.tooltip_text     = "%s\n%d €" % [name_text, cost]
	if not locked:
		btn.pressed.connect(func() -> void: _on_room_pressed(item["id"]))
	return btn


func _make_btn_sb(bg: Color, border: Color) -> StyleBoxFlat:
	var r  := int(CM_BTN_SIZE * 0.5)
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.corner_radius_top_left     = r
	sb.corner_radius_top_right    = r
	sb.corner_radius_bottom_left  = r
	sb.corner_radius_bottom_right = r
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_top    = 1
	sb.border_width_bottom = 1
	sb.border_color        = border
	sb.shadow_color        = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size         = 4
	sb.shadow_offset       = Vector2(0.0, 2.0)
	return sb
