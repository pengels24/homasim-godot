extends PanelContainer
class_name CustomTooltip

@onready var title_label: Label = %TitleLabel
@onready var status_label: Label = %StatusLabel
@onready var guests_label: Label = %GuestsLabel
@onready var stay_progress: ProgressBar = %StayProgress
@onready var stay_progress_label: Label = %StayProgressLabel
@onready var stay_spacer: Control = %StaySpacer
@onready var clean_progress: ProgressBar = %CleanProgress
@onready var clean_label: Label = %CleanLabel
@onready var maintain_progress: ProgressBar = %MaintainProgress
@onready var maintain_label: Label = %MaintainLabel

var _target_room: Node2D = null
# Refresh-Interval: Inhalt alle X Sekunden neu laden (nicht jeden Frame)
const REFRESH_INTERVAL := 0.5
var _refresh_timer: float = 0.0

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
func _process(delta: float) -> void:
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
		if final_x < 10:
			final_x = pos_on_screen.x + width_on_screen + 10
			
		# Oben und unten im Viewport halten
		var vp_rect = get_viewport_rect().size
		if final_y < 10:
			final_y = 10
		elif final_y + size.y > vp_rect.y - 10:
			final_y = vp_rect.y - size.y - 10
			
		position = Vector2(final_x, final_y)

		# Inhalt periodisch aktualisieren – nicht jeden Frame (zu teuer)
		_refresh_timer -= delta
		if _refresh_timer <= 0.0:
			_refresh_timer = REFRESH_INTERVAL
			_update_content()

# =============================================================================
func _update_content() -> void:
	if not is_instance_valid(_target_room): return
	
	var def = _target_room.call("get_definition")
	var room_name = GameState.T(def.get("name", "Raum"))
	if _target_room.get("room_number") != null and str(_target_room.get("room_number")) != "":
		room_name += " " + str(_target_room.get("room_number"))
	title_label.text = "🏨 " + room_name
	
	# Status
	var status = GameState.T("room.tooltip.free")
	guests_label.text = ""
	guests_label.hide()
	if is_instance_valid(stay_progress):
		stay_progress.hide()
		if stay_spacer: stay_spacer.hide()
	if is_instance_valid(clean_progress):
		clean_progress.hide()
	if is_instance_valid(maintain_progress):
		maintain_progress.hide()
	
	var service_status = ""
	if _target_room.is_service_requested or _target_room.maintenance_level < 50:
		service_status = GameState.T("room.tooltip.service_needed") + "\n"

	if def.get("is_poi", false):
		var room_id = GuestManager._room_key(_target_room)
		var is_staffed = StaffManager.is_poi_staffed(def, room_id)
		var is_open_now = GameState.is_facility_open(def)
		if is_staffed and is_open_now:
			var open_from: int = def.get("open_from", 0)
			var open_to: int = def.get("open_to", 0)
			var opens_str = GameState.format_game_time(open_from) if open_from > 0 else "00:00"
			var closes_str = GameState.format_game_time(open_to) if open_to > 0 else "24:00"
			status = GameState.T("room.tooltip.open") % [opens_str, closes_str]
		elif is_staffed and not is_open_now:
			var open_from: int = def.get("open_from", 0)
			var opens_at := GameState.format_game_time(open_from) if open_from > 0 else "?"
			status = GameState.T("room.tooltip.closed_until") % opens_at
		else:
			status = GameState.T("room.tooltip.understaffed")
			
		if def.get("is_poi", false):
			var current_visitors = 0
			var visitor_names = []
			var ingame = get_tree().get_root().get_node_or_null("Ingame")
			if is_instance_valid(ingame):
				var ctrl = ingame.get("_guest_controller")
				if ctrl:
					for actor in ctrl._actors.values():
						var valid_states = [actor.State.IN_POI, actor.State.STUDYING_MENU, actor.State.WAITING_FOR_FOOD, actor.State.EATING, actor.State.AWAITING_CHECKOUT]
						if actor.current_state in valid_states and actor._current_poi_id == def.get("id", ""):
							current_visitors += 1
							if is_instance_valid(actor._guest_member):
								visitor_names.append("👤 " + actor._guest_member.name)
				
			var txt = GameState.T("room.tooltip.current_visitors") % current_visitors
			if current_visitors > 0:
				var display_names = visitor_names.slice(0, 5)
				txt += "\n" + "\n".join(display_names)
				if visitor_names.size() > 5:
					var more_count = visitor_names.size() - 5
					txt += "\n" + (GameState.T("room.tooltip.and_more") % more_count)
			guests_label.text = txt
			guests_label.show()
		else:
			guests_label.hide()
	elif def.get("is_staff_poi", false) and _target_room.has_method("get_live_details"):
		status = "" # Remove "Frei" for staff rooms
		var details = _target_room.get_live_details()
		if details.size() > 0:
			var txt_trans = GameState.T("room.tooltip.staff_present")
			if txt_trans == "room.tooltip.staff_present":
				txt_trans = "Personal anwesend: %d"
			var txt = txt_trans % details.size()
			var staff_names = []
			for row in details:
				staff_names.append("👤 " + row.get("left", ""))
			
			var display_names = staff_names.slice(0, 5)
			txt += "\n" + "\n".join(display_names)
			if staff_names.size() > 5:
				txt += "\n" + (GameState.T("room.tooltip.and_more") % (staff_names.size() - 5))
			
			guests_label.text = txt
			guests_label.show()
		else:
			guests_label.hide()
	else:
		# GuestManager direkt befragen (nicht mehr über room._guest_mgr)
		var ingame = get_tree().get_root().get_node_or_null("Ingame")
		var mgr = ingame.get("_guest_mgr") if is_instance_valid(ingame) else null
		if mgr:
			var party = mgr.get_party_in_room(_target_room)
			if party:
				# Präsenz prüfen via GuestController
				var ctrl = ingame.get("_guest_controller") if is_instance_valid(ingame) else null
				var presence = GameState.T("room.tooltip.guest_walking")
				if ctrl:
					for member in party.members:
						var guest_id = member.id  # Stabile ID – überlebt Save/Load!
						var actor = ctrl._actors.get(guest_id, null)
						if is_instance_valid(actor):
							if actor.current_state == actor.State.IN_ROOM:
								presence = GameState.T("room.tooltip.guest_present")
								break
							elif actor.current_state in [actor.State.IN_POI, actor.State.STUDYING_MENU, actor.State.WAITING_FOR_FOOD, actor.State.EATING]:
								var poi_name = actor._current_poi_id.capitalize()
								if actor.has_method("_get_poi_def"):
									var poi_def = actor._get_poi_def(actor._current_poi_id)
									if poi_def.has("name"):
										poi_name = GameState.T(poi_def["name"])
								presence = GameState.T("room.tooltip.guest_in_poi") % poi_name
								break
							elif actor.current_state == actor.State.LEAVING or actor.current_state == actor.State.AWAITING_CHECKOUT or (actor.current_state == actor.State.WALKING and actor._is_checkout_walk):
								presence = GameState.T("room.tooltip.guest_leaving")
								break
				status = GameState.T("room.tooltip.occupied") % presence
				var names = [GameState.T("room.tooltip.guests_in_room")]
				for m in party.members:
					var display_role = GameState.T("guest.member.type." + str(m.role))
					names.append("👤 " + m.name + " (" + display_role + ")")
				guests_label.text = "\n".join(names)
				guests_label.show()
				if is_instance_valid(stay_progress):
					stay_progress.max_value = party.total_stay_days
					stay_progress.value = party.stay_days
					
					if party.stay_days <= 0:
						stay_progress_label.text = GameState.T("room.tooltip.departure")
					else:
						stay_progress_label.text = GameState.T("room.tooltip.nights_left") % [party.stay_days, party.total_stay_days]
					stay_progress.show()
					if stay_spacer: stay_spacer.show()
				
	status = service_status + status
	var final_status = ""
	if _target_room.get("is_pending_demolish"):
		final_status += GameState.T("room.tooltip.pending_demolish")
	final_status += status
	if _target_room.has_method("has_trait"):
		var eq := []
		if _target_room.has_trait("telefon"): eq.append("Telefon")
		if _target_room.has_trait("tv"): eq.append("TV")
		if _target_room.has_trait("desk"): eq.append("Schreibtisch")
		if _target_room.has_trait("wlan"): eq.append("WLAN")
		if _target_room.has_trait("klima"): eq.append("Klima")
		
		if not eq.is_empty():
			eq.sort()
			final_status += "\n" + GameState.T("room.tooltip.equipment", "Ausstattung:") + " " + ", ".join(eq)

	status_label.text = final_status

	# ANG-211: Lobby ist Systemraum – Sauberkeit/Wartung nicht anzeigen
	if _target_room.get("room_type_id") != "lobby":
		if is_instance_valid(clean_progress):
			clean_progress.max_value = 100
			clean_progress.value = _target_room.cleanliness_level
			clean_label.text = GameState.T("room.tooltip.cleanliness") + ": " + str(int(_target_room.cleanliness_level)) + "%"
			_set_progress_color(clean_progress, _target_room.cleanliness_level)
			clean_progress.show()
			
		if is_instance_valid(maintain_progress):
			maintain_progress.max_value = 100
			maintain_progress.value = _target_room.maintenance_level
			maintain_label.text = GameState.T("room.tooltip.maintenance") + ": " + str(int(_target_room.maintenance_level)) + "%"
			_set_progress_color(maintain_progress, _target_room.maintenance_level)
			maintain_progress.show()
			
		if stay_spacer: stay_spacer.show()

	# Zwingt das Tooltip-Panel zum Schrumpfen, falls vorher mehr Text da war
	reset_size()
	size = Vector2.ZERO

func _set_progress_color(pb: ProgressBar, val: float) -> void:
	var base_sb = pb.get_theme_stylebox("fill", "TooltipProgressBar")
	var sb: StyleBoxFlat
	if base_sb and base_sb is StyleBoxFlat:
		sb = base_sb.duplicate() as StyleBoxFlat
	else:
		sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_detail = 6
		sb.content_margin_left = 2.0
		sb.content_margin_top = 2.0
		sb.content_margin_right = 2.0
		sb.content_margin_bottom = 2.0
		
	if val >= 75:
		sb.bg_color = Color(0.0, 0.42, 0.11) # Grün
	elif val >= 50:
		sb.bg_color = Color("b59616") # Gelb
	else:
		sb.bg_color = Color("9e2a2b") # Rot
		
	pb.add_theme_stylebox_override("fill", sb)
