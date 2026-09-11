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

func _ready() -> void:
	btn_close.pressed.connect(func(): sig_close_requested.emit())

func setup(stats: Dictionary) -> void:
	val_sat.text = str(stats.inspector_sat) + "%"
	req_sat.text = str(stats.req_inspector_sat) + "%"
	if stats.inspector_sat < stats.req_inspector_sat: val_sat.add_theme_color_override("font_color", Color.RED)
	
	val_avg_sat.text = str(stats.avg_sat) + "%"
	req_avg_sat.text = str(stats.req_avg_sat) + "%"
	if stats.avg_sat < stats.req_avg_sat: val_avg_sat.add_theme_color_override("font_color", Color.RED)
	
	val_clean.text = str(stats.avg_clean) + "%"
	req_clean.text = str(stats.req_clean) + "%"
	if stats.avg_clean < stats.req_clean: val_clean.add_theme_color_override("font_color", Color.RED)
	
	val_rep.text = str(stats.rep)
	req_rep.text = str(stats.req_rep)
	if stats.rep < stats.req_rep: val_rep.add_theme_color_override("font_color", Color.RED)
	
	val_rooms.text = str(stats.rooms)
	req_rooms.text = str(stats.req_rooms)
	if stats.rooms < stats.req_rooms: val_rooms.add_theme_color_override("font_color", Color.RED)
	
	if stats.result == "up":
		result_label.text = "[center][color=green]Prüfung erfolgreich![/color] Die Anforderungen für den nächsten Stern wurden erfüllt.[/center]"
	elif stats.result == "down":
		result_label.text = "[center][color=red]Prüfung nicht bestanden![/color] Aufgrund gravierender Mängel wurde ein Stern aberkannt.[/center]"
	else:
		result_label.text = "[center][color=yellow]Prüfung nicht bestanden.[/color] Aktueller Stern konnte gehalten werden.[/center]"
