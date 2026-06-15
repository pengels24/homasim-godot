extends VBoxContainer

@onready var quest_list: VBoxContainer = %QuestList

# =============================================================================
func _ready() -> void:
	_populate_quests()


# =============================================================================
func _populate_quests() -> void:
	# Alte Einträge löschen
	for c in quest_list.get_children():
		c.queue_free()
	
	var all_quests = []
	
	# Zuerst die einlösbaren (claimable)
	var claimable = QuestManager.get_quests_by_state("claimable")
	for q in claimable:
		q["is_claimable"] = true
		all_quests.append(q)
		
	# Dann die aktiven
	var active = QuestManager.get_quests_by_state("active")
	for q in active:
		q["is_claimable"] = false
		all_quests.append(q)
	
	if all_quests.is_empty():
		var lbl = Label.new()
		lbl.text = "Aktuell keine Aufgaben verfügbar."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		quest_list.add_child(lbl)
		return
		
	for q in all_quests:
		var panel = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		# Info Block
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var title = Label.new()
		title.text = q.get("name", "Quest")
		title.add_theme_font_size_override("font_size", 24)
		title.add_theme_color_override("font_color", Color.GOLD if q.get("is_claimable", false) else Color.WHITE)
		vbox.add_child(title)
		
		var desc = Label.new()
		desc.text = q.get("description", "")
		vbox.add_child(desc)
		
		var prog_lbl = Label.new()
		var prog_val = q.get("progress", 0)
		var max_val = q.get("target_count", 1)
		prog_lbl.text = "Fortschritt: %d / %d" % [prog_val, max_val]
		vbox.add_child(prog_lbl)
		
		# Belohnung
		var reward_lbl = Label.new()
		reward_lbl.text = "Belohnung: %s FP | %s €" % [q.get("reward_fp", 0), GameState.format_money(q.get("reward_money", 0))]
		reward_lbl.add_theme_color_override("font_color", Color.PALE_GREEN)
		vbox.add_child(reward_lbl)
		
		# Action Button
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 0)
		btn.focus_mode = Control.FOCUS_NONE
		
		if q.get("is_claimable", false):
			btn.text = "Belohnung abholen"
			btn.add_theme_color_override("font_color", Color.GOLD)
			btn.pressed.connect(func():
				_on_claim_pressed(q.get("id", ""))
			)
		else:
			btn.text = "In Bearbeitung..."
			btn.disabled = true
			
		hbox.add_child(btn)
		quest_list.add_child(panel)

# =============================================================================
func _on_claim_pressed(quest_id: String) -> void:
	QuestManager.claim_quest(quest_id)
	_populate_quests() # Liste aktualisieren
