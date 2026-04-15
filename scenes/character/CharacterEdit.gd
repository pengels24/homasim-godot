extends Control

## ANG-148 – Charakter-Editor (standalone, Create + Update)
## Zugang: nach Registrierung / Verify, nach Login ohne Manager, Debug-Button MainMenu

const BG_IMAGE := "res://assets/images/home/home-background-002.png"

@onready var title_label:        Label       = $Center/Card/VBox/Title
@onready var field_manager_name: LineEdit    = $Center/Card/VBox/HBox/Options/FieldManagerName
@onready var btn_save:           Button      = $Center/Card/VBox/BtnSave
@onready var btn_back:           Button      = $Center/Card/VBox/BtnBack
@onready var error_label:        Label       = $Center/Card/VBox/ErrorLabel
@onready var character_display:  Control     = $Center/Card/VBox/HBox/Preview/CharacterDisplay
@onready var preview_name:       Label       = $Center/Card/VBox/HBox/Preview/PreviewName
@onready var preview_sub:        Label       = $Center/Card/VBox/HBox/Preview/PreviewSub
@onready var bg_image:           TextureRect = $Bg

@onready var gender_buttons: Array[Button] = []
@onready var skin_buttons:   Array[Button] = []
@onready var hair_buttons:   Array[Button] = []
@onready var outfit_buttons: Array[Button] = []

var _gender := "m"
var _skin   := "hell"
var _hair   := "braun"
var _outfit := "anzug_schwarz"
var _mode   := "create"  # "create" | "update"

# Vom Aufrufer setzen bevor change_scene – wohin "Zurück" navigiert
static var return_scene := "res://scenes/main_menu/MainMenu.tscn"

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
	var tex := load(BG_IMAGE) as Texture2D
	if tex:
		bg_image.texture = tex
	_collect_option_buttons()
	_connect_signals()
	_prefill_from_manager()
	_update_preview()


func _collect_option_buttons() -> void:
	var g := $Center/Card/VBox/HBox/Options/GenderRow
	var s := $Center/Card/VBox/HBox/Options/SkinRow
	var h := $Center/Card/VBox/HBox/Options/HairRow
	var o := $Center/Card/VBox/HBox/Options/OutfitRow
	for btn in g.get_children():
		if btn is Button: gender_buttons.append(btn)
	for btn in s.get_children():
		if btn is Button: skin_buttons.append(btn)
	for btn in h.get_children():
		if btn is Button: hair_buttons.append(btn)
	for btn in o.get_children():
		if btn is Button: outfit_buttons.append(btn)


func _connect_signals() -> void:
	btn_save.pressed.connect(_on_save_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	field_manager_name.text_changed.connect(func(_t): _update_preview())
	field_manager_name.text_submitted.connect(func(_t): _on_save_pressed())

	for btn in gender_buttons:
		btn.pressed.connect(_on_gender_selected.bind(btn))
	for btn in skin_buttons:
		btn.pressed.connect(_on_skin_selected.bind(btn))
	for btn in hair_buttons:
		btn.pressed.connect(_on_hair_selected.bind(btn))
	for btn in outfit_buttons:
		btn.pressed.connect(_on_outfit_selected.bind(btn))

	_set_option_active(gender_buttons, gender_buttons[0])
	_set_option_active(skin_buttons,   skin_buttons[0])
	_set_option_active(hair_buttons,   hair_buttons[1])
	_set_option_active(outfit_buttons, outfit_buttons[0])


func _prefill_from_manager() -> void:
	if not GameState.has_manager():
		_mode = "create"
		title_label.text = GameState.T("register.character.title")
		btn_back.visible = false
		return

	_mode = "update"
	title_label.text = GameState.T("character.edit.title")
	btn_save.text = GameState.T("character.edit.btn.save")

	var m := GameState.current_manager
	field_manager_name.text = m.get("name", "")
	_gender = m.get("gender", "m")
	_skin   = m.get("appearance_skin",   "hell")
	_hair   = m.get("appearance_hair",   "braun")
	_outfit = m.get("appearance_outfit", "anzug_schwarz")

	_activate_button_by_value(gender_buttons, _gender)
	_activate_button_by_value(skin_buttons,   _skin)
	_activate_button_by_value(hair_buttons,   _hair)
	_activate_button_by_value(outfit_buttons, _outfit)


func _activate_button_by_value(group: Array[Button], value: String) -> void:
	for btn in group:
		if btn.get_meta("value", "") == value:
			_set_option_active(group, btn)
			return


func _on_gender_selected(btn: Button) -> void:
	_gender = btn.get_meta("value")
	_set_option_active(gender_buttons, btn)
	_update_preview()


func _on_skin_selected(btn: Button) -> void:
	_skin = btn.get_meta("value")
	_set_option_active(skin_buttons, btn)
	_update_preview()


func _on_hair_selected(btn: Button) -> void:
	_hair = btn.get_meta("value")
	_set_option_active(hair_buttons, btn)
	_update_preview()


func _on_outfit_selected(btn: Button) -> void:
	_outfit = btn.get_meta("value")
	_set_option_active(outfit_buttons, btn)
	_update_preview()


func _update_preview() -> void:
	var name_text := field_manager_name.text.strip_edges()
	preview_name.text = name_text if name_text != "" else "—"
	preview_sub.text  = "MANAGER · LEVEL 1"
	if is_instance_valid(character_display) and character_display.has_method("update_appearance"):
		character_display.update_appearance(
			_gender,
			SKIN_COLORS.get(_skin,   Color(0.95, 0.82, 0.70)),
			HAIR_COLORS.get(_hair,   Color(0.45, 0.30, 0.15)),
			OUTFIT_COLORS.get(_outfit, Color(0.12, 0.12, 0.16))
		)


func _on_save_pressed() -> void:
	var name_text := field_manager_name.text.strip_edges()
	if name_text.is_empty():
		error_label.text = GameState.T("login.error.data_invalid")
		return
	btn_save.disabled = true
	error_label.text = ""

	var endpoint := "/api/manager/update" if _mode == "update" else "/api/manager/create"
	Api.post_json(endpoint, {
		"name":              name_text,
		"gender":            _gender,
		"appearance_skin":   _skin,
		"appearance_hair":   _hair,
		"appearance_outfit": _outfit,
		"appearance_hat":    null
	}, _on_save_response)


func _on_save_response(success: bool, data: Dictionary) -> void:
	btn_save.disabled = false
	if not success or not data.get("success", false):
		error_label.text = data.get("message", GameState.T("api.error.network"))
		return
	SessionManager.check_session(func(_logged_in: bool):
		get_tree().change_scene_to_file(return_scene)
	)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(return_scene)


func _set_option_active(group: Array[Button], active: Button) -> void:
	for btn in group:
		btn.button_pressed = (btn == active)
