extends Control
class_name NewHotelModal

## ANG-179 – Neues-Hotel-Dialog als eigenständiges Modal.

signal confirmed(hotel_id: int)
signal cancelled

# ── Grid-Konstanten ───────────────────────────────────────────────────────────
const GRID_COLS := 5
const GRID_ROWS := 5
const CELL_PX   := 44

const C_SELECTABLE := Color(0.14, 0.48, 0.20)
const C_SEL_HOVER  := Color(0.24, 0.78, 0.34)
const C_SELECTED   := Color(0.918, 0.702, 0.031)
const C_LOCKED     := Color(0.09, 0.09, 0.12)

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var _title_lbl:    Label         = $Overlay/Center/Card/VBox/Header/TitleLbl
@onready var _btn_close:    Button        = $Overlay/Center/Card/VBox/Header/BtnClose
@onready var _name_sublbl:  Label         = $Overlay/Center/Card/VBox/Content/Left/NameLabel
@onready var _name_field:   LineEdit      = $Overlay/Center/Card/VBox/Content/Left/HotelNameField
@onready var _entrance_lbl: Label         = $Overlay/Center/Card/VBox/Content/Left/EntranceLbl
@onready var _error_lbl:    Label         = $Overlay/Center/Card/VBox/Content/Left/ErrorLbl
@onready var _grid_sublbl:  Label         = $Overlay/Center/Card/VBox/Content/Right/GridLabel
@onready var _grid_holder:  GridContainer = $Overlay/Center/Card/VBox/Content/Right/GridWrapper/GridMargin/GridHolder
@onready var _btn_create:   Button        = $Overlay/Center/Card/VBox/BtnRow/BtnCreate

var _selected_x := 2
var _selected_y := 0


func _ready() -> void:
	_title_lbl.text              = GameState.T("dashboard.new_hotel.title")
	_name_sublbl.text            = GameState.T("dashboard.new_hotel.name.label")
	_name_field.placeholder_text = GameState.T("dashboard.new_hotel.placeholder")
	_btn_create.text             = GameState.T("dashboard.new_hotel.btn.create")
	_grid_sublbl.text            = GameState.T("dashboard.new_hotel.grid.section")
	_btn_close.pressed.connect(_on_close_pressed)
	_btn_create.pressed.connect(_on_create_pressed)
	_name_field.text_submitted.connect(func(_t: String) -> void: _on_create_pressed())
	_build_grid()
	_update_grid()
	visible = false


func open() -> void:
	_name_field.text = ""
	_error_lbl.text  = ""
	_selected_x = 2
	_selected_y = 0
	_update_grid()
	visible = true
	_name_field.grab_focus()


# ── Signal-Handler ────────────────────────────────────────────────────────────

func _on_close_pressed() -> void:
	visible = false
	cancelled.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
			_on_close_pressed()


func _on_create_pressed() -> void:
	var hotel_name := _name_field.text.strip_edges()
	if hotel_name.is_empty():
		_error_lbl.text = GameState.T("dashboard.new_hotel.error.name_empty")
		return
	if not SaveManager.can_create_hotel(GameState.active_profile_id):
		_error_lbl.text = GameState.T("dashboard.new_hotel.error.limit_reached")
		return
	var hotel_id := SaveManager.create_hotel(GameState.active_profile_id, hotel_name)
	SaveManager.set_plot_built(hotel_id, _selected_x, _selected_y, _derive_entrance_dir(_selected_x, _selected_y))
	visible = false
	confirmed.emit(hotel_id)


# ── Grid ──────────────────────────────────────────────────────────────────────

func _build_grid() -> void:
	for py in GRID_ROWS:
		for px in GRID_COLS:
			var cell := ColorRect.new()
			cell.custom_minimum_size = Vector2(CELL_PX, CELL_PX)
			_grid_holder.add_child(cell)
			if _is_selectable(px, py):
				cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
				cell.mouse_entered.connect(_on_cell_hover.bind(px, py, true))
				cell.mouse_exited.connect(_on_cell_hover.bind(px, py, false))
				cell.gui_input.connect(_on_cell_click.bind(px, py))


func _update_grid() -> void:
	var dir := _derive_entrance_dir(_selected_x, _selected_y)
	_entrance_lbl.text = GameState.T("dashboard.new_hotel.grid.label") + " " + GameState.T("dashboard.new_hotel.dir." + dir)
	for py in GRID_ROWS:
		for px in GRID_COLS:
			var cell := _grid_holder.get_child(_cell_index(px, py)) as ColorRect
			if px == _selected_x and py == _selected_y:
				cell.color = C_SELECTED
			elif _is_selectable(px, py):
				cell.color = C_SELECTABLE
			else:
				cell.color = C_LOCKED


func _on_cell_hover(px: int, py: int, entered: bool) -> void:
	if px == _selected_x and py == _selected_y:
		return
	var cell := _grid_holder.get_child(_cell_index(px, py)) as ColorRect
	cell.color = C_SEL_HOVER if entered else C_SELECTABLE


func _on_cell_click(event: InputEvent, px: int, py: int) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
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
