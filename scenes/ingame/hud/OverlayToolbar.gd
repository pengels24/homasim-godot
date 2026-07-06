extends MarginContainer
class_name OverlayToolbar

signal overlay_changed(overlay_type: String)

@onready var btn_dirt = %BtnDirt
@onready var btn_maint = %BtnMaint
@onready var btn_occ = %BtnOcc
@onready var btn_cat = %BtnCat
@onready var btn_val = %BtnVal

func _ready() -> void:
	btn_dirt.toggled.connect(_on_btn_toggled.bind("dirt"))
	btn_maint.toggled.connect(_on_btn_toggled.bind("maintenance"))
	btn_occ.toggled.connect(_on_btn_toggled.bind("occupancy"))
	btn_cat.toggled.connect(_on_btn_toggled.bind("category"))
	btn_val.toggled.connect(_on_btn_toggled.bind("value"))
	
	_update_visibility()

func _update_visibility() -> void:
	# Level basierte Freischaltung (vorerst alles sichtbar, bis Level-Logik eingebaut ist)
	# Todo: GameState.hotel_level einbinden
	pass

func _on_btn_toggled(button_pressed: bool, overlay_type: String) -> void:
	if button_pressed:
		overlay_changed.emit(overlay_type)
	else:
		# Prüfen ob ein anderer Button gedrückt wurde, falls nein, "none" senden
		var grp = btn_dirt.button_group
		if not is_instance_valid(grp.get_pressed_button()):
			overlay_changed.emit("none")

func set_active_overlay(overlay_type: String) -> void:
	match overlay_type:
		"none": 
			var grp = btn_dirt.button_group
			var btn = grp.get_pressed_button()
			if btn:
				btn.button_pressed = false
		"dirt": btn_dirt.button_pressed = true
		"maintenance": btn_maint.button_pressed = true
		"occupancy": btn_occ.button_pressed = true
		"category": btn_cat.button_pressed = true
		"value": btn_val.button_pressed = true
