extends VBoxContainer
class_name NewHotelModal

signal confirmed(hotel_id: int)
signal cancelled

# ── Konstanten ───────────────────────────────────────────────────────────
const GRID_COLS := 5
const GRID_ROWS := 5

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _name_field:   LineEdit      = $Content/Left/NameBox/HotelNameField
@onready var _error_lbl:    Label         = $Content/Left/NameBox/ErrorLbl

@onready var _btn_easy:     Button        = $Content/Left/SettingsBox/DiffButtons/BtnEasy
@onready var _btn_normal:   Button        = $Content/Left/SettingsBox/DiffButtons/BtnNormal
@onready var _btn_hard:     Button        = $Content/Left/SettingsBox/DiffButtons/BtnHard
@onready var _btn_custom:   Button        = $Content/Left/SettingsBox/DiffButtons/BtnCustom

@onready var _lbl_money:    Label         = $Content/Left/SettingsBox/ParamGrid/OptMoney/ValueLbl
@onready var _btn_money_l:  Button        = $Content/Left/SettingsBox/ParamGrid/OptMoney/LeftBtn
@onready var _btn_money_r:  Button        = $Content/Left/SettingsBox/ParamGrid/OptMoney/RightBtn

@onready var _lbl_refund:   Label         = $Content/Left/SettingsBox/ParamGrid/OptRefund/ValueLbl
@onready var _lbl_exp:      Label         = $Content/Left/SettingsBox/ParamGrid/OptExp/ValueLbl

@onready var _viewport:     SubViewport   = $Content/Right/MapContainer/SubViewportContainer/SubViewport
@onready var _click_grid:   GridContainer = $Content/Right/MapContainer/ClickGridWrapper/ClickGrid
@onready var _entrance_lbl: Label         = $Content/Right/EntranceLbl

@onready var _btn_cancel:   Button        = $BtnRow/BtnCancel
@onready var _btn_create:   Button        = $BtnRow/BtnCreate

var _map_grid: Node2D = null

var _selected_x := 2
var _selected_y := 0

# Werte-Arrays
var _money_values := [25000, 50000, 100000]
var _money_labels := ["25.000 €", "50.000 €", "100.000 €"]
var _money_idx := 1

var _refund_labels := ["100 %", "75 %", "50 %", "25 %", "0 %"]
var _refund_idx := 3

var _exp_labels := ["+25 %", "+10 %", "+5 %", "0 %"]
var _exp_idx := 3

# ── Lifecycle ─────────────────────────────────────────────────────────────────
func _ready() -> void:
	_btn_cancel.pressed.connect(_on_close_pressed)
	_btn_create.pressed.connect(_on_create_pressed)
	_name_field.text_submitted.connect(func(_t: String) -> void: _on_create_pressed())
	
	_btn_easy.pressed.connect(_set_difficulty.bind(0))
	_btn_normal.pressed.connect(_set_difficulty.bind(1))
	_btn_hard.pressed.connect(_set_difficulty.bind(2))
	_btn_custom.pressed.connect(_set_difficulty.bind(3))
	
	_btn_money_l.pressed.connect(_change_money.bind(-1))
	_btn_money_r.pressed.connect(_change_money.bind(1))
	
	_setup_map_grid()
	_build_click_grid()
	
	open()

func open() -> void:
	_name_field.text = ""
	_error_lbl.text  = ""
	_selected_x = 2
	_selected_y = 0
	_set_difficulty(1) # Standard
	_update_grid()
	_name_field.grab_focus()

# ── Options & Settings ───────────────────────────────────────────────────────
func _change_money(dir: int) -> void:
	_money_idx = (_money_idx + dir + _money_values.size()) % _money_values.size()
	_update_labels()

func _update_labels() -> void:
	_lbl_money.text = _money_labels[_money_idx]
	_lbl_refund.text = _refund_labels[_refund_idx]
	_lbl_exp.text = _exp_labels[_exp_idx]

func _set_difficulty(level: int) -> void:
	_btn_easy.modulate = Color(1.2, 1.2, 0.4) if level == 0 else Color(1, 1, 1)
	_btn_normal.modulate = Color(1.2, 1.2, 0.4) if level == 1 else Color(1, 1, 1)
	_btn_hard.modulate = Color(1.2, 1.2, 0.4) if level == 2 else Color(1, 1, 1)
	_btn_custom.modulate = Color(1.2, 1.2, 0.4) if level == 3 else Color(1, 1, 1)
	
	# Inputs nur in "Angepasst" aktivieren
	_btn_money_l.disabled = (level != 3)
	_btn_money_r.disabled = (level != 3)
	
	match level:
		0: # Easy
			_money_idx = 2
			_refund_idx = 0
			_exp_idx = 0
		1: # Normal
			_money_idx = 1
			_refund_idx = 3
			_exp_idx = 3
		2: # Hard
			_money_idx = 0
			_refund_idx = 4
			_exp_idx = 3
		3: # Custom
			pass # Werte beibehalten
			
	_update_labels()

# ── Map Grid Integration ─────────────────────────────────────────────────────
func _setup_map_grid() -> void:
	var map_scene = preload("res://scenes/ingame/map/MapGrid.tscn")
	_map_grid = map_scene.instantiate()
	_map_grid.is_miniature = true
	_viewport.add_child(_map_grid)

func _build_click_grid() -> void:
	for py in GRID_ROWS:
		for px in GRID_COLS:
			var btn := Button.new()
			btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
			btn.focus_mode = Control.FOCUS_NONE # Verhindert, dass nach dem Klick ein Godot-Focus-Rahmen stehen bleibt
			btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _is_selectable(px, py) else Control.CURSOR_ARROW
			
			if not _is_selectable(px, py):
				var sb = StyleBoxFlat.new()
				sb.bg_color = Color(0, 0, 0, 0.45)
				btn.add_theme_stylebox_override("normal", sb)
				btn.add_theme_stylebox_override("hover", sb)
				btn.add_theme_stylebox_override("pressed", sb)
				btn.add_theme_stylebox_override("focus", sb)
			else:
				btn.add_theme_stylebox_override("normal", _get_empty_style())
				btn.add_theme_stylebox_override("hover", _get_outline_style(Color(1, 1, 1, 0.3)))
				btn.add_theme_stylebox_override("pressed", _get_empty_style())
				btn.add_theme_stylebox_override("focus", _get_empty_style())
			
			_click_grid.add_child(btn)
			
			if _is_selectable(px, py):
				btn.pressed.connect(_on_cell_click.bind(px, py))

func _update_grid() -> void:
	var dir := _derive_entrance_dir(_selected_x, _selected_y)
	_entrance_lbl.text = "Eingangsseite: " + GameState.T("dashboard.new_hotel.dir." + dir)
	
	if _map_grid and _map_grid.has_method("setup_as_miniature"):
		_map_grid.setup_as_miniature(_selected_x, _selected_y)
	
	# Update borders and arrows on click grid
	for py in GRID_ROWS:
		for px in GRID_COLS:
			var btn := _click_grid.get_child(_cell_index(px, py)) as Button
			
			if px == _selected_x and py == _selected_y:
				btn.text = _get_arrow_for_dir(dir)
				btn.add_theme_font_size_override("font_size", 48)
				btn.add_theme_color_override("font_color", Color(0.9, 0.7, 0.1)) # Gelb
			else:
				btn.text = ""

func _get_empty_style() -> StyleBoxEmpty:
	return StyleBoxEmpty.new()

func _get_arrow_for_dir(dir: String) -> String:
	match dir:
		"top": return "▼"
		"bottom": return "▲"
		"left": return "▶"
		"right": return "◀"
	return ""

func _get_outline_style(color: Color) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0,0,0,0)
	sb.border_color = color
	sb.border_width_bottom = 3
	sb.border_width_top = 3
	sb.border_width_left = 3
	sb.border_width_right = 3
	return sb

func _on_cell_click(px: int, py: int) -> void:
	_selected_x = px
	_selected_y = py
	_update_grid()

func _is_selectable(px: int, py: int) -> bool:
	var on_x_edge = (px == 0 or px == GRID_COLS - 1)
	var on_y_edge = (py == 0 or py == GRID_ROWS - 1)
	return on_x_edge != on_y_edge

func _cell_index(px: int, py: int) -> int:
	return py * GRID_COLS + px

func _derive_entrance_dir(px: int, py: int) -> String:
	if py == 0:              return "top"
	if py == GRID_ROWS - 1: return "bottom"
	if px == 0:              return "left"
	return "right"

# ── Actions ──────────────────────────────────────────────────────────────────
func _on_close_pressed() -> void:
	cancelled.emit()

func _on_create_pressed() -> void:
	var hotel_name := _name_field.text.strip_edges()
	if hotel_name.is_empty():
		_error_lbl.text = GameState.T("dashboard.new_hotel.error.name_empty")
		return
	if not SaveManager.can_create_hotel(GameState.active_profile_id):
		_error_lbl.text = GameState.T("dashboard.new_hotel.error.limit_reached")
		return
	
	# Startkapital
	var money = _money_values[_money_idx]
	
	var hotel_id := SaveManager.create_hotel(GameState.active_profile_id, hotel_name)
	SaveManager.update_hotel(hotel_id, {"money": money}) # Save custom money
	
	SaveManager.set_plot_built(hotel_id, _selected_x, _selected_y, _derive_entrance_dir(_selected_x, _selected_y))
	confirmed.emit(hotel_id)
