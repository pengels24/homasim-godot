extends PanelContainer

signal clicked(room: Node2D)

var current_room: Node2D = null

@onready var _name_label: Label = %RoomName
@onready var _details_label: Label = %RoomDetails
# @onready var _icon: TextureRect = %Icon

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Den Mauszeiger auf eine Hand ändern (aus deinem alten Code übernommen, sehr gutes UX-Detail!)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# -----------------------------------------------------------------------------
# DATEN BEFÜLLEN
# -----------------------------------------------------------------------------
func populate(room: Node2D) -> void:
	current_room = room

	# Das externe Definition-Dictionary des Raums abrufen (perfekt fürs spätere Modding!)
	var def: Dictionary = {}
	if room.has_method("get_definition"):
		def = room.get_definition()

	# Namen und Raumnummer zusammensetzen (z.B. "Einzelzimmer | Z101")
	var type_label: String = def.get("label", "Zimmer")
	var room_num: String = str(room.get("room_number"))

	var title_text = type_label
	if room_num != "" and room_num != "null":
		title_text += " | " + room_num
	_name_label.text = title_text

	# Preis und Details auslesen
	var price: int = def.get("nightly_price", 0)
	var name_str: String = def.get("name", str(room.get("room_type_id")))

	if price > 0:
		_details_label.text = name_str + " | " + str(price) + " € / Nacht"
	else:
		_details_label.text = name_str

# -----------------------------------------------------------------------------
# INTERAKTION
# -----------------------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clicked.emit(current_room)

func set_highlight(active: bool) -> void:
	# Nutzt deine bestehende Highlight-Farbe aus dem alten Rezeptions-Code
	modulate = Color(0.20, 0.78, 0.35, 1.0) if active else Color.WHITE
