extends VBoxContainer

var _tech_buttons: Dictionary = {}

@onready var tabs: TabContainer = %TabContainer
@onready var grid_zimmer: GridContainer = %GridZimmer
@onready var grid_gastro: GridContainer = %GridGastronomie
@onready var grid_wellness: GridContainer = %GridWellness
@onready var grid_manage: GridContainer = %GridManagement
@onready var grid_prestige: GridContainer = %GridPrestige


# =============================================================================
func _ready() -> void:
	if not TechtreeManager:
		push_error("[Techtree UI] TechtreeManager Autoload fehlt!")
		return
		
	TechtreeManager.sig_tech_unlocked.connect(_on_tech_unlocked)
	_build_ui()


# =============================================================================
func _build_ui() -> void:
	# Alle Grids leeren (falls wir neu laden)
	for grid in [grid_zimmer, grid_gastro, grid_wellness, grid_manage, grid_prestige]:
		for child in grid.get_children():
			child.queue_free()
	
	_tech_buttons.clear()
	
	# Aus der Registry aufbauen
	var registry = TechtreeManager.tech_registry
	for tech_id in registry.keys():
		var tech = registry[tech_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(200, 80)
		btn.text = GameState.T(tech.get("name", "Unknown"))
		btn.tooltip_text = "FP: %d | €: %d" % [tech.get("cost_fp", 0), tech.get("cost_money", 0)]
		
		# Klick-Event
		btn.pressed.connect(func():
			if TechtreeManager.unlock_tech(tech_id):
				Toast.show("Freigeschaltet: " + GameState.T(tech.get("name", "Unknown")))
			else:
				Toast.show("Bedingungen nicht erfüllt!")
		)
		
		_tech_buttons[tech_id] = btn
		
		# Dem passenden Tab zuordnen
		var cat = tech.get("category", "")
		if cat == "zimmer":
			grid_zimmer.add_child(btn)
		elif cat == "gastronomie":
			grid_gastro.add_child(btn)
		elif cat == "wellness":
			grid_wellness.add_child(btn)
		elif cat == "management":
			grid_manage.add_child(btn)
		elif cat == "prestige":
			grid_prestige.add_child(btn)
		else:
			grid_zimmer.add_child(btn) # Fallback
			
	update_button_states()


# =============================================================================
func update_button_states() -> void:
	if not TechtreeManager: return
	
	for tech_id in _tech_buttons.keys():
		var btn: Button = _tech_buttons[tech_id]
		
		if TechtreeManager.is_tech_unlocked(tech_id):
			btn.disabled = true
			btn.modulate = Color(1.0, 0.84, 0.0) # Gold
			btn.text = btn.text.replace(" (Erforscht)", "") + " (Erforscht)"
		elif TechtreeManager.is_tech_available(tech_id):
			btn.disabled = false
			btn.modulate = Color.WHITE
		else:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)


# =============================================================================
func _on_tech_unlocked(_tech_id: String) -> void:
	update_button_states()
