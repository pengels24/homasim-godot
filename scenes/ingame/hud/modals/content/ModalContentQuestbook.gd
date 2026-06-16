extends HBoxContainer

@onready var cat_list: VBoxContainer = %CategoryList
@onready var rank_list: VBoxContainer = %RankList
@onready var quest_list: VBoxContainer = %QuestList
@onready var rank_label: Label = %RankLabel
@onready var rank_reward_label: Label = %RankRewardLabel
@onready var rank_claim_btn: Button = %RankClaimBtn

var _active_cat: String = ""
var _active_rank_id: String = ""

# =============================================================================
func _ready() -> void:
	_build_categories()
	if cat_list.get_child_count() > 0:
		_select_category("zimmer")

# =============================================================================
func _build_categories() -> void:
	for c in cat_list.get_children(): c.queue_free()
	
	var cats = QuestManager.quests_db.get("categories", {})
	for cat_id in cats:
		var btn = Button.new()
		var cat_name = cat_id.capitalize()
		btn.text = cat_name
		btn.custom_minimum_size = Vector2(0, 50)
		btn.toggle_mode = true
		btn.pressed.connect(func(): _select_category(cat_id))
		cat_list.add_child(btn)
		btn.set_meta("cat_id", cat_id)

# =============================================================================
func _select_category(cat_id: String) -> void:
	_active_cat = cat_id
	
	for btn in cat_list.get_children():
		btn.button_pressed = (btn.get_meta("cat_id") == cat_id)
		
	# Ränge aufbauen
	for c in rank_list.get_children(): c.queue_free()
	
	var quest_state = QuestManager.get_quest_state()
	var cat_state = quest_state.get(cat_id)
	var current_rank = cat_state.get("current_rank", 1) if cat_state else 1
	
	var ranks_def = QuestManager.quests_db["categories"][cat_id].get("ranks", {})
	var rank_keys = ranks_def.keys()
	# Sortieren falls keys als strings vorliegen (z.B. "1", "2", "10")
	rank_keys.sort_custom(func(a, b): return int(a) < int(b))
	
	for r_id in rank_keys:
		var r_int = int(r_id)
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		btn.toggle_mode = true
		
		var txt = "Rang " + r_id
		if r_int < current_rank:
			txt += " (✔)"
			btn.add_theme_color_override("font_color", Color.DIM_GRAY)
		elif r_int == current_rank:
			btn.add_theme_color_override("font_color", Color.GOLD)
		else:
			txt += " 🔒"
			btn.add_theme_color_override("font_color", Color.DIM_GRAY)
			
		btn.text = txt
		btn.set_meta("rank_id", r_id)
		btn.pressed.connect(func(): _select_rank(r_id))
		rank_list.add_child(btn)
		
	_select_rank(str(current_rank))

# =============================================================================
func _select_rank(r_id: String) -> void:
	_active_rank_id = r_id
	
	for btn in rank_list.get_children():
		btn.button_pressed = (btn.get_meta("rank_id") == r_id)
		
	_populate_quests()

# =============================================================================
func _populate_quests() -> void:
	for c in quest_list.get_children(): c.queue_free()
	
	if _active_cat == "" or _active_rank_id == "": return
	
	var quest_state = QuestManager.get_quest_state()
	var cat_state = quest_state.get(_active_cat)
	if cat_state == null: return
	
	var current_rank = cat_state.get("current_rank", 1)
	rank_label.text = "Rang " + _active_rank_id
	
	var ranks_def = QuestManager.quests_db["categories"][_active_cat].get("ranks", {})
	var r_def = ranks_def.get(_active_rank_id)
	
	if r_def == null:
		rank_reward_label.text = "Alle Ränge abgeschlossen!"
		rank_claim_btn.hide()
		return
		
	var r_fp = r_def.get("reward_fp", 0)
	var r_money = r_def.get("reward_money", 0)
	rank_reward_label.text = "Vergütung: %d FP | %s €" % [r_fp, GameState.format_money(r_money)]
	
	if cat_state.get("rank_claimable", false) and str(current_rank) == _active_rank_id:
		rank_claim_btn.show()
		rank_claim_btn.disabled = false
		rank_claim_btn.add_theme_color_override("font_color", Color.GOLD)
		if not rank_claim_btn.pressed.is_connected(_on_rank_claim):
			rank_claim_btn.pressed.connect(_on_rank_claim)
	else:
		rank_claim_btn.show()
		rank_claim_btn.disabled = true
		rank_claim_btn.remove_theme_color_override("font_color")
		if rank_claim_btn.pressed.is_connected(_on_rank_claim):
			rank_claim_btn.pressed.disconnect(_on_rank_claim)
	
	var targets_state = cat_state.get("targets", {})
	var targets_def = r_def.get("targets", [])
	var is_past_rank = int(_active_rank_id) < current_rank
	var is_future_rank = int(_active_rank_id) > current_rank
	
	for t_def in targets_def:
		var t_id = t_def["id"]
		var t_state = targets_state.get(t_id, {"progress":0, "state":"active"})
		
		# Prüfen ob erforscht
		var req_tech = t_def.get("requires_tech", "")
		var is_locked = (req_tech != "" and not TechtreeManager.is_tech_unlocked(req_tech))
		
		var panel = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_right", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var title = Label.new()
		title.add_theme_font_size_override("font_size", 22)
		
		if is_locked:
			title.text = "🔒 ??? (Benötigt Forschung)"
			title.add_theme_color_override("font_color", Color.DIM_GRAY)
			vbox.add_child(title)
		else:
			title.text = GameState.T(t_def.get("name", "Unknown"))
			title.add_theme_color_override("font_color", Color.WHITE)
			if t_state["state"] == "claimable" or t_state["state"] == "claimed":
				title.add_theme_color_override("font_color", Color.GOLD)
			vbox.add_child(title)
			
			var desc = Label.new()
			desc.text = GameState.T(t_def.get("description", ""))
			vbox.add_child(desc)
			
			var prog_lbl = Label.new()
			var max_val = t_def.get("target_count", 1)
			var prog_val = max_val if is_past_rank else (0 if is_future_rank else t_state["progress"])
			prog_lbl.text = "Fortschritt: %d / %d" % [prog_val, max_val]
			vbox.add_child(prog_lbl)
			
			var reward_lbl = Label.new()
			reward_lbl.text = "Belohnung: %s FP | %s €" % [t_def.get("reward_fp", 0), GameState.format_money(t_def.get("reward_money", 0))]
			reward_lbl.add_theme_color_override("font_color", Color.PALE_GREEN)
			vbox.add_child(reward_lbl)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 0)
		btn.focus_mode = Control.FOCUS_NONE
		
		if is_locked:
			btn.text = "Gesperrt"
			btn.disabled = true
		elif is_future_rank:
			btn.text = "Rang noch nicht erreicht"
			btn.disabled = true
		elif is_past_rank or t_state["state"] == "claimed":
			btn.text = "Erledigt"
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color.DIM_GRAY)
		elif t_state["state"] == "claimable":
			btn.text = "Belohnung abholen"
			btn.add_theme_color_override("font_color", Color.GOLD)
			btn.pressed.connect(func(): _on_claim_pressed(t_id))
		else:
			btn.text = "In Bearbeitung..."
			btn.disabled = true
			
		hbox.add_child(btn)
		quest_list.add_child(panel)

# =============================================================================
func _on_claim_pressed(t_id: String) -> void:
	QuestManager.claim_quest(t_id)
	_populate_quests()

# =============================================================================
func _on_rank_claim() -> void:
	QuestManager.claim_rank(_active_cat)
	# UI neu aufbauen (da sich der current_rank verschoben hat)
	_select_category(_active_cat)
