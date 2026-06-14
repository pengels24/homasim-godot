extends PanelContainer
class_name CustomTooltip

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var guests_label: Label = %GuestsLabel

var _target_room: Node2D = null

# =============================================================================
func _ready() -> void:
	hide()
	GameState.sig_room_hovered.connect(_on_room_hovered)

# =============================================================================
func _on_room_hovered(room: Node2D, is_hovered: bool) -> void:
	# Wenn ein Menü (Modal/Pause/Build) offen ist, zeigen wir keine Tooltips!
	if InputHandler.current_mode != InputHandler.InputMode.NORMAL:
		hide()
		return
		
	if is_hovered:
		_target_room = room
		_update_content()
		show()
	else:
		if _target_room == room:
			_target_room = null
			hide()

# =============================================================================
func _process(_delta: float) -> void:
	if InputHandler.current_mode != InputHandler.InputMode.NORMAL:
		hide()
		return
		
	if is_instance_valid(_target_room) and visible:
		# Canvas-Transformation holen (damit es auf dem HUD Layer korrekt positioniert wird)
		var canvas_trans = _target_room.get_global_transform_with_canvas()
		var pos_on_screen = canvas_trans.origin
		
		# Raum-Breite in Pixeln * aktueller Skalierung (Zoom)
		var sz = _target_room.get_tile_size()
		var width_on_screen = sz.x * 16 * canvas_trans.get_scale().x
		
		# Standard-Position: Links daneben
		var final_x = pos_on_screen.x - size.x - 10
		var final_y = pos_on_screen.y
		
		# Fallback: Wenn es links aus dem Bild ragt, packen wir es nach rechts!
		if final_x < 0:
			final_x = pos_on_screen.x + width_on_screen + 10
			
		position = Vector2(final_x, final_y)

# =============================================================================
func _update_content() -> void:
	if not is_instance_valid(_target_room): return
	
	var def = _target_room.call("get_definition")
	var room_name = def.get("name", "Raum")
	if _target_room.room_number != "":
		room_name += " " + _target_room.room_number
	title_label.text = "🏨 " + room_name
	
	# Status
	var status = "Frei"
	guests_label.text = ""
	guests_label.hide()
	
	if _target_room.is_service_requested or _target_room.maintenance_level < 50:
		status = "🧹 Service benötigt"
	else:
		var mgr = _target_room.get("_guest_mgr")
		if mgr:
			var party = mgr.get_party_in_room(_target_room)
			if party:
				status = "👥 Belegt"
				var names = ["Gäste im Zimmer:"]
				for m in party.members:
					var display_role = GameState.T("guest.member.type." + str(m.role))
					names.append("• " + m.name + " (" + display_role + ")")
				guests_label.text = "\n".join(names)
				guests_label.show()
				
	status_label.text = status
