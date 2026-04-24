extends Control
## ANG-172 – Manager-Auswahl als Modal über dem Hauptmenü.
## Slots sind vollständig in ManagerSelect.tscn definiert.
## Dieses Script befüllt nur die Daten und sendet Signale.

signal closed()

const MAX_SLOTS     := 3
const SLOT_PATH_TPL := "Center/Card/Margin/VBox/Slots/Slot%d/SlotMargin/SlotVBox"

var _profiles: Array = []

@onready var _btn_back: Button = $Center/Card/Margin/VBox/BtnBack


func _ready() -> void:
	for i in MAX_SLOTS:
		var base := SLOT_PATH_TPL % i
		(get_node(base + "/Empty/BtnCreate") as Button).pressed.connect(_on_create_slot)
		(get_node(base + "/Filled/BtnSelect") as Button).pressed.connect(_on_select_slot.bind(i))
	_btn_back.pressed.connect(_on_back)


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


# ── Handler ───────────────────────────────────────────────────────────────────

func _on_select_slot(i: int) -> void:
	if i < _profiles.size():
		GameState.select_profile(_profiles[i])
	closed.emit()


func _on_create_slot() -> void:
	get_tree().change_scene_to_file("res://scenes/character/CharacterEdit.tscn")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		accept_event()
		_on_back()


func _on_back() -> void:
	closed.emit()
