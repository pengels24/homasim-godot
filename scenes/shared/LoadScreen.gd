extends Control
class_name LoadScreen
## ANG-175 – Load-Screen: zeigt Quick/Manual/Auto-Save-Slots für ein Hotel.
## Wird als Modal über dem Dashboard eingeblendet.

signal save_loaded(hotel_id: int)

@onready var _title_lbl:      Label        = $Overlay/Card/VBox/Header/TitleLbl
@onready var _btn_close:      Button       = $Overlay/Card/VBox/Header/BtnClose
@onready var _quick_section:  VBoxContainer = $Overlay/Card/VBox/Scroll/Sections/QuickSection
@onready var _manual_section: VBoxContainer = $Overlay/Card/VBox/Scroll/Sections/ManualSection
@onready var _auto_section:   VBoxContainer = $Overlay/Card/VBox/Scroll/Sections/AutoSection

var _hotel_id: int = -1


func open(hotel_id: int) -> void:
	_hotel_id = hotel_id
	visible   = true
	_build()


# ── Privat ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_title_lbl.text = GameState.T("saveslots.title")
	_btn_close.pressed.connect(func() -> void: visible = false)


func _build() -> void:
	var slots := SaveManager.get_save_slots(_hotel_id)
	_build_quick_section(slots.get("quick", null))
	_build_manual_section(slots.get("manual", [null, null, null]))
	_build_auto_section(slots.get("auto", []))


func _clear_section(section: VBoxContainer) -> void:
	for child in section.get_children():
		if child.name != "SectionTitle":
			child.queue_free()


func _build_quick_section(snap) -> void:
	_clear_section(_quick_section)
	_add_save_row(_quick_section, snap, GameState.T("saveslots.quick.title"), "quick", 0)


func _build_manual_section(manual: Array) -> void:
	_clear_section(_manual_section)
	for i in SaveManager.MANUAL_SLOTS:
		var snap = manual[i] if i < manual.size() else null
		_add_save_row(_manual_section, snap, "%s %d" % [GameState.T("saveslots.manual.slot"), i + 1], "manual", i)


func _build_auto_section(auto_list: Array) -> void:
	_clear_section(_auto_section)
	if auto_list.is_empty():
		var lbl := Label.new()
		lbl.text = GameState.T("saveslots.empty")
		lbl.add_theme_color_override("font_color", Color(0.45, 0.45, 0.45))
		lbl.add_theme_font_size_override("font_size", 14)
		_auto_section.add_child(lbl)
		return
	for i in auto_list.size():
		_add_save_row(_auto_section, auto_list[i], "%s %d" % [GameState.T("saveslots.auto.slot"), i + 1], "auto", i)


func _add_save_row(parent: VBoxContainer, snap, slot_label: String, slot_type: String, slot_idx: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	# Info-Block
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_lbl := Label.new()
	if snap != null:
		name_lbl.text = snap.get("name", slot_label)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.92, 0.92))
	else:
		name_lbl.text = slot_label + " — " + GameState.T("saveslots.empty")
		name_lbl.add_theme_color_override("font_color", Color(0.40, 0.40, 0.40))
	name_lbl.add_theme_font_size_override("font_size", 15)
	info.add_child(name_lbl)

	if snap != null:
		var ts: int  = snap.get("timestamp", 0)
		var day: int = snap.get("day", 1)
		var money: float = snap.get("money", 0.0)
		var meta_lbl := Label.new()
		meta_lbl.text = "Tag %d  ·  € %s  ·  %s" % [
			day,
			_format_money(int(money)),
			_format_timestamp(ts),
		]
		meta_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
		meta_lbl.add_theme_font_size_override("font_size", 12)
		info.add_child(meta_lbl)

	# Buttons
	if snap != null:
		var btn_load := Button.new()
		btn_load.text = GameState.T("saveslots.btn.load")
		btn_load.custom_minimum_size = Vector2(100, 36)
		_apply_green_style(btn_load)
		btn_load.pressed.connect(_on_load_pressed.bind(slot_type, slot_idx))
		row.add_child(btn_load)

		var btn_del := Button.new()
		btn_del.text = GameState.T("saveslots.btn.delete")
		btn_del.custom_minimum_size = Vector2(100, 36)
		_apply_danger_style(btn_del)
		btn_del.pressed.connect(_on_delete_pressed.bind(slot_type, slot_idx))
		row.add_child(btn_del)


func _on_load_pressed(slot_type: String, slot_idx: int) -> void:
	var loaded := false
	match slot_type:
		"quick":  loaded = SaveManager.load_quick(_hotel_id)
		"manual": loaded = SaveManager.load_manual(_hotel_id, slot_idx)
		"auto":   loaded = SaveManager.load_auto(_hotel_id, slot_idx)
	if loaded:
		visible = false
		save_loaded.emit(_hotel_id)


func _on_delete_pressed(slot_type: String, slot_idx: int) -> void:
	SaveManager.delete_save(_hotel_id, slot_type, slot_idx)
	_build()


func _format_money(amount: int) -> String:
	var s := str(amount)
	var result := ""
	var count  := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result


func _format_timestamp(ts: int) -> String:
	if ts == 0:
		return ""
	var dt := Time.get_datetime_dict_from_unix_time(ts)
	return "%02d.%02d.%04d %02d:%02d" % [dt["day"], dt["month"], dt["year"], dt["hour"], dt["minute"]]


func _apply_green_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.086, 0.639, 0.290)
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left        = 16.0
	s.content_margin_right       = 16.0
	s.content_margin_top         = 8.0
	s.content_margin_bottom      = 8.0
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.15, 0.78, 0.38)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))


func _apply_danger_style(btn: Button) -> void:
	var s := StyleBoxFlat.new()
	s.bg_color                   = Color(0.863, 0.149, 0.149)
	s.corner_radius_top_left     = 6
	s.corner_radius_top_right    = 6
	s.corner_radius_bottom_left  = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left        = 16.0
	s.content_margin_right       = 16.0
	s.content_margin_top         = 8.0
	s.content_margin_bottom      = 8.0
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate() as StyleBoxFlat
	h.bg_color = Color(0.98, 0.22, 0.22)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", s)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
