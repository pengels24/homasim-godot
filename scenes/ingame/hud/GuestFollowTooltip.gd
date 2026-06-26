extends PanelContainer

var _target_guest: GuestActor
var _timer: float = 5.0

@onready var label_name: Label = %NameLabel
@onready var label_target: Label = %TargetLabel
@onready var label_satisfaction: Label = %SatisfactionLabel

func setup(guest: GuestActor) -> void:
	_target_guest = guest
	if not is_instance_valid(guest):
		queue_free()
		return
		
	var member = guest.get("_guest_member")
	if member:
		label_name.text = member.name
		
		var p: GuestParty = null
		var ingame = get_tree().get_root().get_node_or_null("Ingame")
		if ingame:
			var mgr = ingame.get("_guest_mgr")
			if mgr:
				for party in mgr._active + mgr._checkout + mgr._waiting:
					if party.id == member.party_id:
						p = party
						break
						
		if p:
			var sat = int(p.satisfaction)
			var emoji = "🙂"
			if sat > 80: emoji = "😁"
			elif sat > 50: emoji = "🙂"
			elif sat > 25: emoji = "😐"
			else: emoji = "😠"
			label_satisfaction.text = "Zufriedenheit: %d%% %s" % [sat, emoji]
			var c = Color.GREEN
			if sat < 25: c = Color.RED
			elif sat < 50: c = Color.ORANGE
			elif sat < 80: c = Color.YELLOW
			label_satisfaction.add_theme_color_override("font_color", c)
	else:
		label_name.text = "Unbekannt"
		
	_update_target_text()
	_update_pos()

func _process(delta: float) -> void:
	if not is_instance_valid(_target_guest):
		queue_free()
		return
		
	_timer -= delta
	if _timer <= 0.0:
		queue_free()
		return
		
	_update_target_text()
	_update_pos()

func _update_pos() -> void:
	if not is_instance_valid(_target_guest):
		return
	var cam = get_viewport().get_camera_2d()
	if cam:
		var screen_pos = _target_guest.get_global_transform_with_canvas().origin
		position = screen_pos + Vector2(20, -size.y - 10)

func _update_target_text() -> void:
	if not is_instance_valid(_target_guest):
		return
	var state = _target_guest.current_state
	var t = "Ziel: "
	if state == GuestActor.State.IN_ROOM:
		t += "Zimmer"
	elif state == GuestActor.State.IN_POI:
		t += _target_guest._current_poi_id.capitalize()
	elif state == GuestActor.State.WALKING:
		if _target_guest.get("_is_checkout_walk"):
			t += "Unterwegs (Rezeption)"
		elif _target_guest._current_poi_id != "" and _target_guest._current_poi_id != "room":
			t += "Unterwegs (%s)" % _target_guest._current_poi_id.capitalize()
		else:
			t += "Unterwegs (Zimmer)"
	elif state == GuestActor.State.AWAITING_CHECKOUT:
		t += "Rezeption"
	elif state == GuestActor.State.LEAVING:
		t += "Abreise"
	else:
		t += "Warten"
		
	label_target.text = t
	
	# Budget des Members anzeigen
	var member = _target_guest.get("_guest_member")
	if member and member.daily_budget > 0:
		label_target.text += "\n💰 Budget: %d € / %d €" % [member.spending_budget, member.daily_budget]
