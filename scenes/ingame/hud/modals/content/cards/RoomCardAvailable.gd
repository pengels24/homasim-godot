extends PanelContainer

# Wir nutzen das exakt gleiche Namensschema wie bei der GuestCard
signal sig_clicked(room: Node2D)

var current_room: Node2D = null

@onready var _name_label: Label = %RoomName
@onready var _details_label: Label = %RoomDetails
@onready var _icon: TextureRect = %Icon

# Dein neuer edler Auswahlrahmen
@onready var _selection_border: Panel = %SelectionBorder


# =============================================================================
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_selection_border.hide()


# =============================================================================
# DATEN BEFÜLLEN
func populate(room: Node2D) -> void:
	current_room = room

	# Definition dynamisch aus dem Skript holen
	var def: Dictionary = {}
	if room.get_script().has_method("get_definition"):
		def = room.get_script().get_definition()

	# 1. Namen und ID zusammenbauen (z.B. "EZ | Z0001")
	var label: String = def.get("label", "Zimmer")
	var prefix: String = def.get("prefix", "")
	var r_num: String = room.room_number if "room_number" in room else "????"

	# Falls das Prefix 'Z' nicht eh schon in der Nummer gespeichert ist:
	var display_id: String = r_num
	if prefix != "" and not r_num.begins_with(prefix):
		display_id = prefix + r_num

	_name_label.text = label + " | " + display_id

	# 2. Details zusammenbauen (z.B. "Einzelzimmer | 60 € / Nacht")
	var full_name: String = def.get("name", "Raum")
	var price: int = def.get("nightly_price", 0)
	_details_label.text = full_name + " | " + str(price) + " € / Nacht"

	# 3. Icon laden
	var icon_path: String = def.get("icon", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_icon.texture = load(icon_path)


# =============================================================================
# INTERAKTION
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		sig_clicked.emit(current_room)


# =============================================================================
func set_highlight(active: bool) -> void:
	# Die edle Methode: Nur den Rahmen umschalten!
	_selection_border.visible = active
