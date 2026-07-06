extends HBoxContainer

@onready var cat_list: VBoxContainer = %CategoryList
@onready var rank_list: VBoxContainer = %RankList
@onready var quest_list: VBoxContainer = %QuestList
@onready var rank_label: Label = %RankLabel
@onready var rank_reward_label: Label = %RankRewardLabel
@onready var rank_claim_btn: Button = %RankClaimBtn

var _active_cat: String = ""
var _active_rank_id: String = ""

var SB_BLUE = preload("res://assets/UI/menu_button_blue.tres")
var SB_BLUE_HOVER = preload("res://assets/UI/menu_button_blue_hover.tres")
var SB_BLUE_PRESSED = preload("res://assets/UI/menu_button_blue_pressed.tres")

var SB_DARK = preload("res://assets/UI/menu_button_darkblue.tres")
var SB_DARK_HOVER = preload("res://assets/UI/menu_button_darkblue_hover.tres")

var SB_GREEN = preload("res://assets/UI/menu_button_green.tres")
var SB_GREEN_HOVER = preload("res://assets/UI/menu_button_green_hover.tres")
var SB_GREEN_PRESSED = preload("res://assets/UI/menu_button_green_pressed.tres")

var SB_DISABLED = preload("res://assets/UI/menu_button_darkblue_disabled.tres")

var SB_QUEST_PANEL: StyleBoxFlat

func _style_toggle_btn(btn: Button) -> void:
	btn.add_theme_stylebox_override("normal", SB_DARK)
	btn.add_theme_stylebox_override("hover", SB_DARK_HOVER)
	btn.add_theme_stylebox_override("pressed", SB_BLUE)
	btn.add_theme_stylebox_override("focus", SB_DARK)

func _style_action_btn(btn: Button, type: String) -> void:
	if type == "green":
		btn.add_theme_stylebox_override("normal", SB_GREEN)
		btn.add_theme_stylebox_override("hover", SB_GREEN_HOVER)
		btn.add_theme_stylebox_override("pressed", SB_GREEN_PRESSED)
		btn.add_theme_stylebox_override("focus", SB_GREEN)
		btn.add_theme_stylebox_override("disabled", SB_GREEN)
	elif type == "blue":
		btn.add_theme_stylebox_override("normal", SB_BLUE)
		btn.add_theme_stylebox_override("hover", SB_BLUE_HOVER)
		btn.add_theme_stylebox_override("pressed", SB_BLUE_PRESSED)
		btn.add_theme_stylebox_override("focus", SB_BLUE)
		btn.add_theme_stylebox_override("disabled", SB_BLUE)
	elif type == "disabled":
		btn.add_theme_stylebox_override("normal", SB_DISABLED)
		btn.add_theme_stylebox_override("hover", SB_DISABLED)
		btn.add_theme_stylebox_override("pressed", SB_DISABLED)
		btn.add_theme_stylebox_override("focus", SB_DISABLED)
		btn.add_theme_stylebox_override("disabled", SB_DISABLED)

# =============================================================================
func _ready() -> void:
	SB_QUEST_PANEL = StyleBoxFlat.new()
	SB_QUEST_PANEL.bg_color = Color(0.1, 0.12, 0.15, 0.8)
	SB_QUEST_PANEL.border_color = Color(0.3, 0.3, 0.3, 1.0)
	SB_QUEST_PANEL.set_border_width_all(1)
	SB_QUEST_PANEL.set_corner_radius_all(6)
	
	rank_label.theme_type_variation = &"HeaderMedium"
	rank_reward_label.theme_type_variation = &"ValueLabel"
	_build_categories()
	if cat_list.get_child_count() > 0:
		_select_category("zimmer")

# =============================================================================
func _build_categories() -> void:
	for c in cat_list.get_children(): c.queue_free()
	
	var cats = QuestManager.quests_db.get("categories", {})
	for cat_id in cats:
		var btn = Button.new()
		var cat_name = GameState.T("room_category." + cat_id)
		btn.text = cat_name
		btn.custom_minimum_size = Vector2(0, 50)
		btn.toggle_mode = true
		_style_toggle_btn(btn)
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
		_style_toggle_btn(btn)
		
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
	rank_label.text = GameState.T("ui.quests.rank", _active_rank_id)
	
	var ranks_def = QuestManager.quests_db["categories"][_active_cat].get("ranks", {})
	var r_def = ranks_def.get(_active_rank_id)
	
	if r_def == null:
		rank_reward_label.text = GameState.T("ui.quests.all_done")
		rank_claim_btn.hide()
		return
	else:
		var curr_rank = ranks_def[_active_rank_id]
		var r_fp = curr_rank.get("reward_fp", 0)
		var r_money = curr_rank.get("reward_money", 0)
		rank_reward_label.text = GameState.T("ui.quests.reward_rank", r_fp, GameState.format_money(r_money))
	
	if cat_state.get("rank_claimable", false) and str(current_rank) == _active_rank_id:
		rank_claim_btn.show()
		rank_claim_btn.disabled = false
		rank_claim_btn.remove_theme_color_override("font_color")
		rank_claim_btn.text = GameState.T("ui.quests.btn.complete_rank")
		_style_action_btn(rank_claim_btn, "green")
		if not rank_claim_btn.pressed.is_connected(_on_rank_claim):
			rank_claim_btn.pressed.connect(_on_rank_claim)
	else:
		rank_claim_btn.show()
		rank_claim_btn.disabled = true
		rank_claim_btn.remove_theme_color_override("font_color")
		rank_claim_btn.text = GameState.T("ui.quests.btn.complete_rank")
		_style_action_btn(rank_claim_btn, "disabled")
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
		panel.add_theme_stylebox_override("panel", SB_QUEST_PANEL)
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		panel.add_child(margin)
		
		var hbox = HBoxContainer.new()
		margin.add_child(hbox)
		
		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(vbox)
		
		var title = Label.new()
		title.theme_type_variation = &"HeaderMedium"
		
		if is_locked:
			title.text = GameState.T("ui.quests.locked_tech")
			title.add_theme_color_override("font_color", Color.DIM_GRAY)
			vbox.add_child(title)
		else:
			title.text = GameState.T(t_def.get("name", "Unknown"))
			if t_state["state"] == "claimable" or t_state["state"] == "claimed":
				title.add_theme_color_override("font_color", Color.GOLD)
			else:
				title.add_theme_color_override("font_color", Color.WHITE)
			vbox.add_child(title)
			
			var desc = Label.new()
			desc.theme_type_variation = &"DescLabel"
			desc.text = GameState.T(t_def.get("description", ""))
			vbox.add_child(desc)
			
			var prog_lbl = Label.new()
			prog_lbl.theme_type_variation = &"DescLabel"
			var max_val = t_def.get("target_count", 1)
			var prog_val = max_val if is_past_rank else (0 if is_future_rank else t_state["progress"])
			prog_lbl.text = GameState.T("ui.quests.progress", int(prog_val), int(max_val))
			vbox.add_child(prog_lbl)
			
			var reward_lbl = Label.new()
			reward_lbl.theme_type_variation = &"ValueLabel"
			reward_lbl.text = GameState.T("ui.quests.reward_quest", int(t_def.get("reward_fp", 0)), GameState.format_money(t_def.get("reward_money", 0)))
			reward_lbl.add_theme_color_override("font_color", Color.PALE_GREEN)
			vbox.add_child(reward_lbl)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(180, 50)
		btn.focus_mode = Control.FOCUS_NONE
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		
		if is_locked:
			btn.text = GameState.T("ui.quests.btn.locked")
			btn.disabled = true
			_style_action_btn(btn, "disabled")
			btn.add_theme_color_override("font_color", Color.DARK_GRAY)
		elif is_future_rank:
			btn.text = GameState.T("ui.quests.btn.future")
			btn.disabled = true
			_style_action_btn(btn, "disabled")
		elif is_past_rank or t_state["state"] == "claimed":
			btn.text = GameState.T("ui.quests.btn.done")
			btn.disabled = true
			_style_action_btn(btn, "disabled")
			btn.add_theme_color_override("font_color", Color.DIM_GRAY)
		elif t_state["state"] == "claimable":
			btn.text = GameState.T("ui.quests.btn.claim")
			_style_action_btn(btn, "green")
			btn.add_theme_color_override("font_color", Color.WHITE)
			btn.pressed.connect(func(): _on_claim_pressed(t_id))
		else:
			btn.text = GameState.T("ui.quests.btn.working")
			btn.disabled = true
			_style_action_btn(btn, "disabled")
			btn.add_theme_color_override("font_color", Color.LIGHT_GRAY)
			
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
