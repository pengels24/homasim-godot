extends VBoxContainer

signal sig_save_completed

const GAME_SLOT_SCENE = preload("res://scenes/ingame/hud/modals/content/GameSlot.tscn")

@onready var slot_container: VBoxContainer = %SlotContainer
@onready var save_name_input: LineEdit = %SaveNameInput
@onready var save_button: Button = %SaveButton

var slots_ui: Array = []
var selected_slot_index: int = -1
var active_hotel_id: int = -1

# =============================================================================
func _ready() -> void:
	# Signale verknüpfen
	save_button.pressed.connect(_on_save_button_pressed)
	save_name_input.text_changed.connect(_on_name_input_changed)

	# Start-Zustand
	save_button.disabled = true
	save_name_input.clear()

	# Aktuelle Hotel-ID aus dem GameState holen
	active_hotel_id = GameState.active_hotel_id
	_generate_slots()

	# NEU: Harte UI-Texte übersetzen
	%Subtitle.text = GameState.T("modal.save.subtitle") # "Manuelle Spielstände"
	%Subtitle.theme_type_variation = &"HeaderMedium"
	%InputLabel.text = GameState.T("modal.save.input_label") # "Name:"
	%InputLabel.theme_type_variation = &"DescLabel"
	%SaveNameInput.placeholder_text = GameState.T("modal.save.input_placeholder") # "Spielstand benennen..."
	save_button.text = GameState.T("modal.save.button.save") # "Spielstand speichern"


# =============================================================================
# Generiert die 5 Speicher-Slots aus den echten Daten
func _generate_slots() -> void:
	# Vorher aufräumen
	for child in slot_container.get_children():
		child.queue_free()
	slots_ui.clear()

	# Echte Save-Daten laden
	var save_data = SaveManager.get_save_slots(active_hotel_id)
	var manual_saves = save_data.get("manual", [])

	for i in range(1, 6):
		var slot_instance = GAME_SLOT_SCENE.instantiate()
		slot_container.add_child(slot_instance)
		slots_ui.append(slot_instance)

		# Array-Index ist i - 1 (0 bis 4)
		var array_index = i - 1
		var snap = manual_saves[array_index] if array_index < manual_saves.size() else null

		var is_empty = (snap == null)
		var save_name = "— " + GameState.T("modal.save.slot.empty") + " —"
		var info_text = GameState.T("modal.save.slot.new")

		# Wenn ein Savegame existiert, Daten überschreiben
		if not is_empty:
			save_name = snap.get("name", "Unbenannt")
			var ts = snap.get("timestamp", 0)
			info_text = GameState.format_timestamp(ts)

		slot_instance.setup(i, save_name, info_text, is_empty)
		slot_instance.sig_slot_clicked.connect(_on_slot_clicked)


# =============================================================================
# Wird aufgerufen, wenn ein GameSlot geklickt wurde
func _on_slot_clicked(index: int) -> void:
	selected_slot_index = index

	# Visuelles Feedback aktualisieren
	for slot in slots_ui:
		slot.set_selected(slot.slot_index == index)

	# Textfeld füllen
	var clicked_slot = slots_ui[index - 1]
	if clicked_slot.is_empty:
		save_name_input.text = GameState.T("modal.save.save_name.empty") + " " + str(index)
	else:
		save_name_input.text = clicked_slot.label_name.text

	save_button.disabled = false


# =============================================================================
# Wird aufgerufen, wenn der Spieler tippt
func _on_name_input_changed(new_text: String) -> void:
	if selected_slot_index != -1:
		save_button.disabled = new_text.strip_edges().is_empty()


# =============================================================================
# Wird aufgerufen, wenn auf "Speichern" geklickt wird
func _on_save_button_pressed() -> void:
	var final_save_name = save_name_input.text.strip_edges()
	var slot_index = selected_slot_index - 1
	var clicked_slot = slots_ui[slot_index]
	
	if not clicked_slot.is_empty:
		# Slot belegt -> Warnung anzeigen
		var confirm = preload("res://scenes/shared/ConfirmModal.tscn").instantiate()
		get_tree().current_scene.add_child(confirm)
		
		confirm.ask(
			GameState.T("modal.save.overwrite.title", "Spielstand überschreiben?"),
			GameState.T("modal.save.overwrite.message", "Möchtest du den Spielstand wirklich überschreiben?"),
			GameState.T("btn.save.overwrite", "Überschreiben"),
			GameState.T("btn.cancel", "Abbrechen"),
			"",
			true # roter Button
		)
		
		confirm.confirmed.connect(func():
			_execute_save(slot_index, final_save_name)
			confirm.queue_free()
		)
		confirm.cancelled.connect(func():
			confirm.queue_free()
		)
	else:
		_execute_save(slot_index, final_save_name)

func _execute_save(index: int, final_name: String) -> void:
	# WICHTIG: Bevor wir speichern, müssen wir das laufende Spiel zwingen,
	# seinen aktuellsten Zustand (Zeit, Geld, Gäste) in den SaveManager zu schreiben!
	TimeManager.sig_save_requested.emit(TimeManager.get_game_time())

	# Speichern über den SaveManager
	SaveManager.save_manual(active_hotel_id, index, final_name)
	Toast.show(GameState.T("toast.quicksave"))

	# Visueller Reset nach dem Speichern (Liste neu generieren, damit neues Datum sichtbar wird)
	_generate_slots()
	save_button.disabled = true
	save_name_input.clear()
	
	sig_save_completed.emit()

