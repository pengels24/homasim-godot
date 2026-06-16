extends Control
## ANG-172 – Manager-Auswahl als Modal über dem Hauptmenü.
## Slots sind vollständig in ManagerSelect.tscn definiert.
## Dieses Script befüllt nur die Daten und sendet Signale.

signal closed()

const MAX_SLOTS     := 3
const SLOT_PATH_TPL := "Center/Card/Margin/VBox/Slots/Slot%d/SlotMargin/SlotVBox"

var _profiles: Array = []
var _pending_delete_slot: int = -1

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

@onready var _btn_close:     Button      = $Center/Card/Margin/VBox/Header/BtnClose
@onready var _confirm_modal: ConfirmModal = $ConfirmModal


func _ready() -> void:
	for i in MAX_SLOTS:
		var base := SLOT_PATH_TPL % i
		(get_node(base + "/Empty/BtnCreate") as Button).pressed.connect(_on_create_slot)
		(get_node(base + "/Filled/ActionRow/BtnSelect") as Button).pressed.connect(_on_select_slot.bind(i))
		(get_node(base + "/Filled/ActionRow/BtnDelete") as Button).pressed.connect(_on_delete_slot.bind(i))
	_btn_close.pressed.connect(_on_back)
	_confirm_modal.confirmed.connect(_on_delete_confirmed)


# ── Öffentliche API ───────────────────────────────────────────────────────────

func open() -> void:
	refresh()
	visible = true


func refresh() -> void:
	_profiles = SaveManager.get_profiles()
	for i in MAX_SLOTS:
		_update_slot(i, _profiles[i] if i < _profiles.size() else {})


# ── Slot-Aktualisierung ───────────────────────────────────────────────────────

func _update_slot(i: int, profile: Dictionary) -> void:
	var base      := SLOT_PATH_TPL % i
	var is_empty  := profile.is_empty()
	(get_node(base + "/Empty")  as Control).visible = is_empty
	(get_node(base + "/Filled") as Control).visible = not is_empty
	if not is_empty:
		(get_node(base + "/Filled/Name") as Label).text = profile.get("name", "?")
		var hotel_count := SaveManager.get_hotels(profile.get("id", -1)).size()
		(get_node(base + "/Filled/Hotels") as Label).text = (
			"%d Hotel%s" % [hotel_count, "s" if hotel_count != 1 else ""]
		)
		var avatar := get_node(base + "/Filled/AvatarBox/AvatarDisplay") as CharacterDisplay
		avatar.update_appearance(
			profile.get("appearance_gender", "m"),
			SKIN_COLORS.get(profile.get("appearance_skin", "hell"),   Color(0.95, 0.82, 0.70)),
			HAIR_COLORS.get(profile.get("appearance_hair", "braun"),   Color(0.45, 0.30, 0.15)),
			OUTFIT_COLORS.get(profile.get("appearance_outfit", "anzug_schwarz"), Color(0.12, 0.12, 0.16))
		)


# ── Handler ───────────────────────────────────────────────────────────────────

func _on_select_slot(i: int) -> void:
	if i < _profiles.size():
		GameState.select_profile(_profiles[i])
	closed.emit()


func _on_delete_slot(i: int) -> void:
	_pending_delete_slot = i
	_confirm_modal.ask(
		"Manager löschen?",
		"Alle Hotels dieses Managers werden\nebenfalls entfernt.",
		"Löschen",
		"Abbrechen",
		GameState.T("manager_select.delete.ack"),
		true
	)


func _on_delete_confirmed() -> void:
	if _pending_delete_slot >= 0 and _pending_delete_slot < _profiles.size():
		SaveManager.delete_profile(_profiles[_pending_delete_slot].get("id", -1))
	_pending_delete_slot = -1
	refresh()


func _on_create_slot() -> void:
	get_tree().change_scene_to_file("res://scenes/character/CharacterEdit.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_back()


func _on_back() -> void:
	closed.emit()
