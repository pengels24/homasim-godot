extends VBoxContainer

# Signal, das wir später in Ingame.gd abfangen, um den Ladevorgang abzuschließen
signal sig_load_completed(hotel_id: int)

const GAME_SLOT_SCENE = preload("res://scenes/ingame/hud/modals/content/GameSlot.tscn")

@onready var manual_slot_container: VBoxContainer = %ManualSlotContainer
@onready var auto_slot_container: VBoxContainer = %AutoSlotContainer
@onready var load_button: Button = %LoadButton

var slots_manual_ui: Array = []
var slots_auto_ui: Array = []

var selected_type: String = "" # "manual" oder "auto"
var selected_slot_index: int = -1
var active_hotel_id: int = -1

# =============================================================================
func _ready() -> void:
	load_button.pressed.connect(_on_load_button_pressed)

	# Start-Zustand: Lade-Button aus
	load_button.disabled = true
	active_hotel_id = GameState.active_hotel_id
	_generate_slots()

	# NEU: Harte UI-Texte übersetzen
	%Subtitle1.text = GameState.T("modal.load.manual.title")
	%Subtitle2.text = GameState.T("modal.load.auto.title")
	load_button.text = GameState.T("modal.load.button.load")


# =============================================================================
func _generate_slots() -> void:
	# 1. Container aufräumen
	for child in manual_slot_container.get_children():
		child.queue_free()
	for child in auto_slot_container.get_children():
		child.queue_free()
	slots_manual_ui.clear()
	slots_auto_ui.clear()

	# 2. Echte Daten holen
	var save_data = SaveManager.get_save_slots(active_hotel_id)
	var manual_saves = save_data.get("manual", [])
	var auto_saves = save_data.get("auto", [])

	# 3. Manuelle Slots generieren (immer 5 Stück)
	for i in range(1, 6):
		var array_index = i - 1
		var snap = manual_saves[array_index] if array_index < manual_saves.size() else null
		_create_slot_instance(manual_slot_container, slots_manual_ui, i, snap, "manual")

	# 4. Autosave Slots generieren (nur so viele wie existieren, max 5)
	for i in range(1, auto_saves.size() + 1):
		var snap = auto_saves[i - 1]
		_create_slot_instance(auto_slot_container, slots_auto_ui, i, snap, "auto")


# =============================================================================
# Hilfsfunktion zum Instanziieren und Konfigurieren eines Slots
func _create_slot_instance(parent_container: Node, ui_array: Array, visual_index: int, snap, slot_type: String) -> void:
	var slot_instance = GAME_SLOT_SCENE.instantiate()
	parent_container.add_child(slot_instance)
	ui_array.append(slot_instance)

	var is_empty = (snap == null)
	var save_name = "— " + GameState.T("modal.save.slot.empty") + " —"
	var info_text = "" if slot_type == "auto" else GameState.T("modal.save.slot.new")

	if not is_empty:
		save_name = snap.get("name", "Unbenannt")
		var ts = snap.get("timestamp", 0)
		info_text = GameState.format_timestamp(ts)

	slot_instance.setup(visual_index, save_name, info_text, is_empty)

	# .bind(slot_type) gibt dem Signal heimlich den Typ mit (manual oder auto)
	slot_instance.sig_slot_clicked.connect(_on_slot_clicked.bind(slot_type))


# =============================================================================
# Wird aufgerufen, wenn IRGENDEIN Slot geklickt wurde
func _on_slot_clicked(index: int, type: String) -> void:
	selected_slot_index = index
	selected_type = type

	# Optisches Feedback für Manuelle Slots
	for slot in slots_manual_ui:
		var is_selected = (type == "manual" and slot.slot_index == index)
		slot.set_selected(is_selected)

	# Optisches Feedback für Auto Slots
	for slot in slots_auto_ui:
		var is_selected = (type == "auto" and slot.slot_index == index)
		slot.set_selected(is_selected)

	# Lade-Button Logik (Nur aktivieren, wenn der Slot NICHT leer ist)
	var active_array = slots_manual_ui if type == "manual" else slots_auto_ui
	var clicked_slot = active_array[index - 1]
	load_button.disabled = clicked_slot.is_empty


# =============================================================================
# Klick auf "Laden"
func _on_load_button_pressed() -> void:
	var loaded = false
	var array_index = selected_slot_index - 1

	if selected_type == "manual":
		loaded = SaveManager.load_manual(active_hotel_id, array_index)
	elif selected_type == "auto":
		loaded = SaveManager.load_auto(active_hotel_id, array_index)

	if loaded:
		print("=> [ModalContentLoad] Spielstand erfolgreich geladen!")
		sig_load_completed.emit(active_hotel_id)
	else:
		print("=> [ModalContentLoad] Fehler beim Laden des Spielstands!")

