extends VBoxContainer

var _tech_buttons: Dictionary = {}
var _glow_tweens: Dictionary = {}

@onready var tabs: TabContainer = %TabContainer
@onready var fp_label: Label = %FPLabel

const CATEGORIES = ["zimmer", "gastronomie", "wellness", "management", "prestige"]
const CAT_NAMES = {
	"zimmer": "room_category.zimmer",
	"gastronomie": "room_category.gastronomie",
	"wellness": "room_category.wellness",
	"management": "room_category.management",
	"prestige": "room_category.prestige"
}

var btn_scene = preload("res://scenes/ingame/hud/modals/content/TechNodeButton.tscn")
var confirm_scene = preload("res://scenes/shared/ConfirmModal.tscn")

# =============================================================================
func _ready() -> void:
	if not TechtreeManager:
		push_error("[Techtree UI] TechtreeManager Autoload fehlt!")
		return
		
	TechtreeManager.sig_tech_unlocked.connect(_on_tech_unlocked)
	TechtreeManager.sig_tier_unlocked.connect(_on_tier_unlocked)
	GameState.sig_hotel_fp_changed.connect(_on_fp_changed)
	
	_on_fp_changed(GameState.selected_hotel.get("fp", 0))
	_build_ui()

# =============================================================================
func _on_fp_changed(new_fp: int) -> void:
	if fp_label:
		var icon_lbl = fp_label.get_parent().get_node_or_null("FPIcon")
		if icon_lbl:
			icon_lbl.text = GameState.T("ui.techtree.current_fp") + ": "
		fp_label.text = str(new_fp)
	update_button_states()

# =============================================================================
func _build_ui() -> void:
	for child in tabs.get_children():
		child.queue_free()
	
	_tech_buttons.clear()
	
	var tiers_config = TechtreeManager.tiers_config
	var tier_keys = tiers_config.keys()
	tier_keys.sort_custom(func(a, b): return int(a) < int(b))
	
	for tier_id in tier_keys:
		var tier_data = tiers_config[tier_id]
		
		var scroll = ScrollContainer.new()
		scroll.name = "Tier " + tier_id
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		tabs.add_child(scroll)
		
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 20)
		margin.add_theme_constant_override("margin_top", 20)
		margin.add_theme_constant_override("margin_right", 20)
		margin.add_theme_constant_override("margin_bottom", 20)
		margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		margin.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.add_child(margin)
		
		if not TechtreeManager.is_tier_unlocked(tier_id):
			_build_tier_gate(margin, tier_id, tier_data)
		else:
			_build_tier_content(margin, tier_id, tier_data)
			
	update_button_states()

# =============================================================================
func _build_tier_gate(parent: Control, tier_id: String, tier_data: Dictionary) -> void:
	var gate_def = tier_data.get("gate", {})
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(vbox)
	
	var title = Label.new()
	title.text = GameState.T("ui.techtree.tier_locked", tier_id)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var hs = HSeparator.new()
	vbox.add_child(hs)
	
	var lbl_req = Label.new()
	lbl_req.text = GameState.T("ui.techtree.unlock_reqs")
	lbl_req.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(lbl_req)
	
	# Bedingungen auflisten
	var can_unlock = true
	var req_level = gate_def.get("req_level", 0)
	if req_level > 0:
		var ok = GameState.selected_hotel.get("level", 1) >= req_level
		var l = Label.new()
		l.text = ("✔" if ok else "✖") + GameState.T("ui.techtree.req.level", req_level)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
		vbox.add_child(l)
		if not ok: can_unlock = false
		
	var req_stars = gate_def.get("req_stars", 0)
	if req_stars > 0:
		var ok = GameState.selected_hotel.get("stars", 0) >= req_stars
		var l = Label.new()
		l.text = ("✔" if ok else "✖") + GameState.T("ui.techtree.req.stars", req_stars)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
		vbox.add_child(l)
		if not ok: can_unlock = false
		
	var cost_fp = gate_def.get("cost_fp", 0)
	if cost_fp > 0:
		var ok = GameState.selected_hotel.get("fp", 0) >= cost_fp
		var l = Label.new()
		l.text = ("✔" if ok else "✖") + GameState.T("ui.techtree.req.fp", cost_fp)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
		vbox.add_child(l)
		if not ok: can_unlock = false
		
	var req_items = gate_def.get("req_items_unlocked", 0)
	if req_items > 0:
		var unlocked_in_prev_tier = 0
		var prev_tier_id = str(int(tier_id) - 1)
		var prev_tier_data = TechtreeManager.tiers_config.get(prev_tier_id, {})
		var prev_nodes = prev_tier_data.get("nodes", [])
		for n in prev_nodes:
			if TechtreeManager.is_tech_unlocked(n.get("id", "")):
				unlocked_in_prev_tier += 1
		
		var ok = unlocked_in_prev_tier >= req_items
		var l = Label.new()
		l.text = ("✔" if ok else "✖") + GameState.T("ui.techtree.req.prev_tier", unlocked_in_prev_tier, req_items)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_color_override("font_color", Color.GREEN if ok else Color.RED)
		vbox.add_child(l)
		if not ok: can_unlock = false

	# Unlock Button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(300, 60)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.text = GameState.T("ui.techtree.btn.unlock_tier", tier_id)
	btn.disabled = not can_unlock
	btn.pressed.connect(func():
		if TechtreeManager.unlock_tier(tier_id):
			Toast.show(GameState.T("toast.techtree.tier_unlocked", tier_id), "research")
	)
	vbox.add_child(btn)

# =============================================================================
func _build_tier_content(parent: Control, _tier_id: String, tier_data: Dictionary) -> void:
	var nodes = tier_data.get("nodes", [])
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(vbox)
	
	for cat in CATEGORIES:
		var cat_nodes = []
		for n in nodes:
			if n.get("category", "") == cat:
				cat_nodes.append(n)
				
		if cat_nodes.is_empty():
			continue
			
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 20)
		vbox.add_child(hbox)
		
		# Kategorie Label
		var cat_lbl = Label.new()
		cat_lbl.custom_minimum_size = Vector2(150, 0)
		cat_lbl.text = GameState.T(CAT_NAMES.get(cat, cat))
		cat_lbl.add_theme_color_override("font_color", Color.LIGHT_STEEL_BLUE)
		cat_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(cat_lbl)
		
		var vsep = VSeparator.new()
		hbox.add_child(vsep)
		
		# Nodes nach Spalten gruppieren
		var cols = {}
		for n in cat_nodes:
			var c = n.get("col", 0)
			if not cols.has(c): cols[c] = []
			cols[c].append(n)
			
		var col_keys = cols.keys()
		col_keys.sort()
		
		for c in col_keys:
			var col_vbox = VBoxContainer.new()
			col_vbox.add_theme_constant_override("separation", 10)
			col_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
			col_vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			hbox.add_child(col_vbox)
			
			for n in cols[c]:
				var tech_id = n.get("id", "")
				var btn = btn_scene.instantiate()
				var display_name = tech_id + " " + GameState.T(n.get("name", "Unknown"))
				btn.text = display_name
				
				var cost_fp = n.get("cost_fp", 0)
				var cost_money = n.get("cost_money", 0)
				var _deps = n.get("dependencies", [])
				
				var cur_fp = int(GameState.selected_hotel.get("fp", 0))
				var cur_money = int(GameState.selected_hotel.get("money", 0))
				
				var _has_fp = cur_fp >= cost_fp
				var _has_money = cur_money >= cost_money
				var is_demo_locked = n.get("demo_locked", false)
				
				if is_demo_locked:
					btn.modulate = Color(1, 1, 1, 0.5)
				
				# Tooltip wird nun in _update_single_button() via _generate_tooltip() gesetzt
				
				btn.pressed.connect(func():
					if is_demo_locked:
						Toast.show(GameState.T("ui.techtree.tooltip.demo_alert"), "info", false)
						return
						
					if TechtreeManager.is_tech_available(tech_id):
						var confirm = confirm_scene.instantiate()
						confirm.top_level = true
						add_child(confirm)
						
						var title = GameState.T("ui.techtree.confirm.title")
						var msg = GameState.T("ui.techtree.confirm.desc", display_name, int(n.get("cost_fp", 0)), str(int(n.get("cost_money", 0))) + " €")
						
						confirm.ask(title, msg, GameState.T("ui.techtree.btn.unlock"), GameState.T("ui.techtree.btn.cancel"))
						confirm.confirmed.connect(func():
							if TechtreeManager.unlock_tech(tech_id):
								Toast.show(GameState.T("toast.techtree.unlocked", GameState.T(n.get("name", "Unknown"))), "research")
							confirm.queue_free()
						)
						confirm.cancelled.connect(func(): confirm.queue_free())
					else:
						Toast.show(GameState.T("toast.techtree.failed"), "research", false)
				)
				
				# Hover Effect
				btn.mouse_entered.connect(func(): _highlight_dependencies(tech_id, true))
				btn.mouse_exited.connect(func(): _highlight_dependencies(tech_id, false))
				
				_tech_buttons[tech_id] = btn
				col_vbox.add_child(btn)

# =============================================================================
func _highlight_dependencies(tech_id: String, active: bool) -> void:
	# Den gehoverten Button selbst markieren (Solid Border, kein Pulse)
	if _tech_buttons.has(tech_id):
		var self_btn = _tech_buttons[tech_id]
		var is_available = TechtreeManager.is_tech_available(tech_id)
		self_btn.set_glow_state(active, is_available)
		if not active and _glow_tweens.has(tech_id):
			var tw = _glow_tweens[tech_id]
			tw.kill()
			_glow_tweens.erase(tech_id)

	var tech = TechtreeManager.get_tech_node(tech_id)
	if tech.is_empty(): return
	var deps = tech.get("dependencies", [])
	
	for dep in deps:
		if _tech_buttons.has(dep):
			var btn = _tech_buttons[dep]
			var is_unlocked = TechtreeManager.is_tech_unlocked(dep)
			
			btn.set_glow_state(active, is_unlocked)
			var overlay = btn.get_glow_node()
			
			if active and not is_unlocked:
				if not _glow_tweens.has(dep):
					var tw = create_tween().set_loops()
					tw.tween_property(overlay, "modulate:a", 0.3, 0.4)
					tw.tween_property(overlay, "modulate:a", 1.0, 0.4)
					_glow_tweens[dep] = tw
			else:
				if _glow_tweens.has(dep):
					var tw = _glow_tweens[dep]
					tw.kill()
					_glow_tweens.erase(dep)

# =============================================================================
func update_button_states() -> void:
	if not TechtreeManager: return
	for tech_id in _tech_buttons.keys():
		_update_single_button(tech_id)

# =============================================================================
func _update_single_button(tech_id: String) -> void:
	var btn: Button = _tech_buttons[tech_id]
	btn.tooltip_text = _generate_tooltip(tech_id)
	
	if TechtreeManager.is_tech_unlocked(tech_id):
		btn.disabled = true
		btn.modulate = Color.WHITE
		btn.add_theme_color_override("font_disabled_color", Color("#366e4d"))
		btn.set_glow_state(true, true)
		btn.get_glow_node().modulate.a = 1.0
	elif TechtreeManager.is_tech_available(tech_id):
		btn.disabled = false
		btn.modulate = Color.WHITE
		btn.remove_theme_color_override("font_disabled_color")
		btn.set_glow_state(false, true)
	else:
		btn.disabled = true
		btn.modulate = Color(0.4, 0.4, 0.4)
		btn.remove_theme_color_override("font_disabled_color")
		btn.set_glow_state(false, false)

# =============================================================================
func _generate_tooltip(tech_id: String) -> String:
	var n = TechtreeManager.get_tech_node(tech_id)
	if n.is_empty(): return ""
	
	if TechtreeManager.is_tech_unlocked(tech_id):
		var trans = GameState.T("ui.techtree.tooltip.already_unlocked")
		if trans == "ui.techtree.tooltip.already_unlocked":
			return "- Bereits erforscht -"
		return trans
		
	var cost_fp = n.get("cost_fp", 0)
	var cost_money = n.get("cost_money", 0)
	var _deps = n.get("dependencies", [])
	
	var cur_fp = int(GameState.selected_hotel.get("fp", 0))
	var cur_money = int(GameState.selected_hotel.get("money", 0))
	
	var _has_fp = cur_fp >= cost_fp
	var _has_money = cur_money >= cost_money
	var is_demo_locked = n.get("demo_locked", false)
	
	var tt = ""
	if is_demo_locked:
		tt += GameState.T("ui.techtree.demo_locked") + "\n\n"
		
	if n.has("desc") and n["desc"] != "":
		tt += GameState.T(n["desc"]) + "\n\n"
	else:
		var unlocks = []
		for t in TechtreeManager.tech_registry.values():
			if tech_id in t.get("dependencies", []):
				unlocks.append(GameState.T("ui.techtree.tooltip.unlocks.tech", GameState.T(t.get("name", t.get("id", "")))))
		
		for r in GameState.room_registry.values():
			var r_def = r.get("def", {})
			if r_def.get("req_tech", "") == tech_id:
				unlocks.append(GameState.T("ui.techtree.tooltip.unlocks.room", GameState.T(r_def.get("name", "Raum"))))
				
		var custom_features = n.get("unlocks_features", [])
		for f in custom_features:
			unlocks.append(GameState.T("ui.techtree.tooltip.unlocks.feature", GameState.T(f)))
				
		if unlocks.size() > 0:
			var joined = "\n- ".join(unlocks)
			tt += GameState.T("ui.techtree.tooltip.unlocks.desc", joined)
		else:
			tt += GameState.T("ui.techtree.tooltip.unlocks.empty")
	
	tt += ("✅ " if _has_fp else "❌ ") + "%d / %d FP\n" % [cur_fp, cost_fp]
	tt += ("✅ " if _has_money else "❌ ") + "%d / %d €\n" % [cur_money, cost_money]
	
	for d in _deps:
		var dep_name = d + " " + GameState.T(TechtreeManager.get_tech_node(d).get("name", d))
		var is_dep_unlocked = TechtreeManager.is_tech_unlocked(d)
		tt += ("✅ " if is_dep_unlocked else "❌ ") + GameState.T("ui.techtree.tooltip.requires", dep_name)
		
	return tt.strip_edges()

# =============================================================================
func _on_tech_unlocked(_tech_id: String) -> void:
	update_button_states()

# =============================================================================
func _on_tier_unlocked(_tier_id: String) -> void:
	_build_ui()
