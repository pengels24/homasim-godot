extends PanelContainer
class_name CustomTooltip

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var guests_label: Label = %GuestsLabel
@onready var stay_progress: ProgressBar = %StayProgress
@onready var stay_progress_label: Label = %StayProgressLabel
@onready var stay_spacer: Control = %StaySpacer

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
	if _target_room.get("room_number") != null and str(_target_room.get("room_number")) != "":
		room_name += " " + str(_target_room.get("room_number"))
	title_label.text = "🏨 " + room_name
	
	# Status
	var status = "Frei"
	guests_label.text = ""
	guests_label.hide()
	if is_instance_valid(stay_progress):
		stay_progress.hide()
		if stay_spacer: stay_spacer.hide()
	
	if _target_room.is_service_requested or _target_room.maintenance_level < 50:
		status = "🧹 Service benötigt"
	elif def.get("is_poi", false):
		var room_id = GuestManager._room_key(_target_room)
		var is_staffed = StaffManager.is_poi_staffed(def, room_id)
		if is_staffed:
			status = "🍺 Geöffnet"
		else:
			status = "🔴 Unterbesetzt (Geschlossen)"
			
		var current_visitors = 0
		var ingame = get_tree().get_root().get_node_or_null("Ingame")
		if is_instance_valid(ingame):
			var ctrl = ingame.get("_guest_controller")
			if ctrl:
				for actor in ctrl._actors.values():
					if actor.current_state == actor.State.IN_POI and actor._current_poi_id == room_id:
						current_visitors += 1
			
		guests_label.text = "Aktuelle Gäste: %d" % current_visitors
		guests_label.show()
	else:
		# GuestManager direkt befragen (nicht mehr über room._guest_mgr)
		var ingame = get_tree().get_root().get_node_or_null("Ingame")
		var mgr = ingame.get("_guest_mgr") if is_instance_valid(ingame) else null
		if mgr:
			var party = mgr.get_party_in_room(_target_room)
			if party:
				# Präsenz prüfen via GuestController
				var ctrl = ingame.get("_guest_controller") if is_instance_valid(ingame) else null
				var presence = "🚶 Gast unterwegs"
				if ctrl:
					for member in party.members:
						var guest_id = member.id  # Stabile ID – überlebt Save/Load!
						var actor = ctrl._actors.get(guest_id, null)
						if is_instance_valid(actor):
							if actor.current_state == actor.State.IN_ROOM:
								presence = "📍 Gast anwesend"
								break
							elif actor.current_state == actor.State.IN_POI:
								presence = "📍 Gast in der " + actor._current_poi_id.capitalize()
								break
							elif actor.current_state == actor.State.LEAVING or actor.current_state == actor.State.AWAITING_CHECKOUT or (actor.current_state == actor.State.WALKING and actor._is_checkout_walk):
								presence = "🧳 Abreisend"
								break
				status = "👥 Belegt: " + presence
				var names = ["Gäste im Zimmer:"]
				for m in party.members:
					var display_role = GameState.T("guest.member.type." + str(m.role))
					names.append("👤 " + m.name + " (" + display_role + ")")
				guests_label.text = "\n".join(names)
				guests_label.show()
				if is_instance_valid(stay_progress):
					stay_progress.max_value = party.total_stay_days
					stay_progress.value = party.stay_days
					
					if party.stay_days <= 0:
						stay_progress_label.text = "Abreise"
					else:
						stay_progress_label.text = "Übrige Nächte: %d / %d" % [party.stay_days, party.total_stay_days]
					stay_progress.show()
					if stay_spacer: stay_spacer.show()
				
	var final_status = ""
	if _target_room.get("is_pending_demolish"):
		final_status += "🔨 Raum zum Löschen vorgemerkt\n"
		
	final_status += status + "\nSauberkeit: %d%% | Zustand: %d%%" % [_target_room.cleanliness_level, _target_room.maintenance_level]
	status_label.text = final_status
	
	# Zwingt das Tooltip-Panel zum Schrumpfen, falls vorher mehr Text da war
	size = Vector2.ZERO
