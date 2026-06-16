extends Control

## Dashboard – Hotel-Übersicht mit Manager-Panel und Hotel-Kacheln

signal closed

@onready var character_display: Control   = $Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/CharacterDisplay
@onready var manager_name_lbl:  Label     = $Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/ManagerName
@onready var manager_role_lbl:  Label     = $Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/ManagerRole
@onready var hotel_count_lbl:   Label     = $Center/Card/VBox/MainArea/ManagerPanel/PanelVBox/HotelCount

@onready var title_label:       Label     = $Center/Card/VBox/Header/TitleLabel
@onready var btn_close:         Button    = $Center/Card/VBox/Header/BtnCloseModal
@onready var btn_new_hotel:     Button    = %BtnNewHotelCard
@onready var status_label:      Label     = $Center/Card/VBox/MainArea/HotelSection/StatusLabel
@onready var hotel_container:   GridContainer = $Center/Card/VBox/MainArea/HotelSection/Scroll/HotelMargin/HotelContainer
@onready var _confirm_modal:    ConfirmModal  = $ConfirmModal

const NEW_HOTEL_SCENE    := preload("res://scenes/shared/NewHotelModal.tscn")
const HOTEL_CARD_SCENE   := preload("res://scenes/dashboard/DashboardHotelCard.tscn")

var _new_hotel_modal:  NewHotelModal  = null
var _hotels:           Array          = []
var _pending_delete_id: int           = -1

const SKIN_COLORS := {
	"hell":   Color(0.95, 0.82, 0.70),
	"mittel": Color(0.76, 0.57, 0.38),
	"dunkel": Color(0.40, 0.26, 0.16),
}
const HAIR_COLORS := {
	"blond":     Color(0.95, 0.85, 0.40),
	"braun":     Color(0.45, 0.30, 0.15),
	"schwarz":   Color(0.12, 0.10, 0.10),
	"hellblond": Color(0.98, 0.95, 0.72),
	"rot":       Color(0.72, 0.22, 0.10),
	"grau":      Color(0.65, 0.65, 0.65),
}
const OUTFIT_COLORS := {
	"anzug_schwarz": Color(0.12, 0.12, 0.16),
	"anzug_grau":    Color(0.42, 0.42, 0.46),
	"casual":        Color(0.22, 0.45, 0.72),
	"uniform":       Color(0.10, 0.38, 0.22),
}


func _ready() -> void:
	if get_parent() == get_tree().root:
		visible = true
		
	btn_close.pressed.connect(close)
	btn_new_hotel.pressed.connect(_on_new_hotel_pressed)
	_confirm_modal.confirmed.connect(_on_delete_confirmed)
	title_label.text   = GameState.T("dashboard.title")
	_setup_manager_panel()
	_load_hotels()

func open() -> void:
	visible = true
	_setup_manager_panel()
	_load_hotels()

func close() -> void:
	visible = false
	closed.emit()
	if get_parent() == get_tree().root:
		get_tree().change_scene_to_file("res://scenes/main_menu/MainMenu.tscn")


func _setup_manager_panel() -> void:
	var profile := GameState.active_profile
	manager_name_lbl.text = profile.get("name", "Manager")
	manager_role_lbl.text = "MANAGER · LEVEL 1"
	character_display.update_appearance(
		profile.get("gender", "m"),
		SKIN_COLORS.get(profile.get("appearance_skin",   "hell"),          SKIN_COLORS["hell"]),
		HAIR_COLORS.get(profile.get("appearance_hair",   "braun"),         HAIR_COLORS["braun"]),
		OUTFIT_COLORS.get(profile.get("appearance_outfit", "anzug_schwarz"), OUTFIT_COLORS["anzug_schwarz"])
	)


func _load_hotels() -> void:
	for child in hotel_container.get_children():
		if child.name != "BtnNewHotelCard":
			child.queue_free()
	_hotels = SaveManager.get_hotels(GameState.active_profile_id)
	hotel_count_lbl.text = "%d Hotel%s" % [_hotels.size(), "s" if _hotels.size() != 1 else ""]
	status_label.text = GameState.T("dashboard.status.no_hotels") if _hotels.is_empty() else ""
	for i in _hotels.size():
		var card = _create_hotel_card(_hotels[i], i)
		hotel_container.add_child(card)
		card.setup(_hotels[i])

func _create_hotel_card(_hotel: Dictionary, _index: int) -> Control:
	var card = HOTEL_CARD_SCENE.instantiate()
	card.sig_play_requested.connect(_start_hotel_by_id)
	card.sig_delete_requested.connect(_delete_hotel)
	return card

func _on_new_hotel_pressed() -> void:
	if not is_instance_valid(_new_hotel_modal):
		_new_hotel_modal = NEW_HOTEL_SCENE.instantiate() as NewHotelModal
		add_child(_new_hotel_modal)
		_new_hotel_modal.confirmed.connect(_on_new_hotel_confirmed)
	_new_hotel_modal.open()


func _on_new_hotel_confirmed(_hotel_id: int) -> void:
	_load_hotels()


func _delete_hotel(hotel_id: int, _btn: Button) -> void:
	_pending_delete_id = hotel_id
	_confirm_modal.ask(
		GameState.T("dashboard.delete_hotel.title"),
		GameState.T("dashboard.delete_hotel.message"),
		GameState.T("dashboard.delete_hotel.confirm"),
		GameState.T("dashboard.cancel"),
		GameState.T("dashboard.delete_hotel.ack"),
		true)


func _on_delete_confirmed() -> void:
	if _pending_delete_id == -1:
		return
	SaveManager.delete_hotel(_pending_delete_id)
	_pending_delete_id = -1
	_load_hotels()


func _start_hotel_by_id(hotel_id: int) -> void:
	GameState.active_hotel_id = hotel_id
	get_tree().change_scene_to_file("res://scenes/ingame/Ingame.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			close()
