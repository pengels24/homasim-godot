extends Button

signal sig_play_requested(hotel_id: int)
signal sig_delete_requested(hotel_id: int, card_ref: Control)

var hotel_id: int = -1

@onready var texture_rect: TextureRect = %TextureRect
@onready var label_name: Label = %LabelName
@onready var label_level: Label = %LabelLevel
@onready var label_day: Label = %LabelDay
@onready var label_guests: Label = %LabelGuests
@onready var label_money: Label = %LabelMoney
@onready var label_rep: Label = %LabelRep
@onready var btn_delete: Button = %BtnDelete

func _ready() -> void:
	self.pressed.connect(func(): sig_play_requested.emit(hotel_id))
	btn_delete.pressed.connect(func(): sig_delete_requested.emit(hotel_id, self))

func setup(hotel: Dictionary) -> void:
	hotel_id = hotel.get("id", -1)
	label_name.text = hotel.get("name", "Unbekannt")
	label_level.text = str(int(hotel.get("level", 1)))
	label_day.text = str(int(hotel.get("day", 1)))
	label_guests.text = str(int(hotel.get("guests_active", 0)))
	label_money.text = "€ " + _format_money(int(hotel.get("money", 0)))
	label_rep.text = str(int(hotel.get("rep", 0)))
	
	var thumb = SaveManager.load_thumbnail(hotel_id)
	if thumb:
		texture_rect.texture = thumb
	else:
		texture_rect.texture = preload("res://assets/images/home/home-background-001.png")

func _format_money(amount: int) -> String:
	var s := str(amount)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
