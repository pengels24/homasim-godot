extends MarginContainer

signal sig_close_requested

@onready var result_label: RichTextLabel = %ResultLabel

@onready var val_sat: Label = %ValSat
@onready var req_sat: Label = %ReqSat
@onready var val_avg_sat: Label = %ValAvgSat
@onready var req_avg_sat: Label = %ReqAvgSat
@onready var val_clean: Label = %ValClean
@onready var req_clean: Label = %ReqClean
@onready var val_rep: Label = %ValRep
@onready var req_rep: Label = %ReqRep
@onready var val_rooms: Label = %ValRooms
@onready var req_rooms: Label = %ReqRooms
@onready var btn_close: Button = %BtnClose
@onready var signature_label: RichTextLabel = %SignatureLabel

func _ready() -> void:
	btn_close.pressed.connect(func(): sig_close_requested.emit())
	# Modal auf 80% Breite / 75% Hoehe skalieren
	var vp_size := get_viewport().get_visible_rect().size
	custom_minimum_size = Vector2(vp_size.x * 0.8, vp_size.y * 0.75)

func setup(stats: Dictionary) -> void:
	val_sat.text = str(stats.inspector_sat) + "%"
	req_sat.text = str(stats.req_inspector_sat) + "%"
	if stats.inspector_sat < stats.req_inspector_sat: val_sat.add_theme_color_override("font_color", Color.RED)
	
	# Float-Werte: max 1 Nachkommastelle
	val_avg_sat.text = "%.1f%%" % stats.avg_sat
	req_avg_sat.text = str(stats.req_avg_sat) + "%"
	if stats.avg_sat < stats.req_avg_sat: val_avg_sat.add_theme_color_override("font_color", Color.RED)
	
	val_clean.text = "%.1f%%" % stats.avg_clean
	req_clean.text = str(stats.req_clean) + "%"
	if stats.avg_clean < stats.req_clean: val_clean.add_theme_color_override("font_color", Color.RED)
	
	val_rep.text = str(stats.rep)
	req_rep.text = str(stats.req_rep)
	if stats.rep < stats.req_rep: val_rep.add_theme_color_override("font_color", Color.RED)
	
	val_rooms.text = str(stats.rooms)
	req_rooms.text = str(stats.req_rooms)
	if stats.rooms < stats.req_rooms: val_rooms.add_theme_color_override("font_color", Color.RED)
	
	if stats.result == "up":
		result_label.text = "[center][color=green]" + GameState.T("event.inspector.result_up") + "[/color][/center]"
	elif stats.result == "down":
		result_label.text = "[center][color=red]" + GameState.T("event.inspector.result_down") + "[/color][/center]"
	elif stats.get("stars_before", 0) >= 1:
		result_label.text = "[center][color=yellow]" + GameState.T("event.inspector.result_held") + "[/color][/center]"
	else:
		result_label.text = "[center][color=yellow]" + GameState.T("event.inspector.result_none") + "[/color][/center]"

	# Signatur unten links mit Pruefernamen (kursiv, groesser)
	var inspector_name: String = stats.get("inspector_name", "Unbekannt")
	signature_label.text = "[font_size=26][i]Gez. " + inspector_name + "[/i][/font_size]"

