extends CanvasLayer
class_name SimBrowser
## ANG-166 – SimBrowser Shell: F7 öffnet simulierten In-Game-Browser mit home.sim.

signal sig_closed

@onready var btn_close: Button = %BtnClose
@onready var btn_home: Button = %BtnHome
@onready var address_bar: LineEdit = %AddressBar
@onready var grid: GridContainer = %Grid
@onready var header_box: VBoxContainer = %HeaderBox
@onready var lbl_tip: Label = %LblTip

const TILE_SCENE = preload("res://scenes/ingame/SimBrowserTile.tscn")
const SITES_CONFIG_PATH = "res://config/browser_sites.json"

# =============================================================================
func _ready() -> void:
	lbl_tip.text = GameState.T("sim.tip")
	$Margin/Window/VBox/ContentBg/Margin/Scroll/VBox/HeaderBox/LblSub.text = GameState.T("sim.title.sub")
	btn_home.icon = preload("res://assets/icons/HUDTop/house.svg")
	btn_home.expand_icon = true
	btn_close.pressed.connect(close)
	btn_home.pressed.connect(func() -> void: _load_url("home.sim"))
	address_bar.text_submitted.connect(_load_url)
	_build_home_sim()

# =============================================================================
func open() -> void:
	visible = true
	SoundManager.play("modal_open")

# =============================================================================
func close() -> void:
	if not visible: return
	visible = false
	SoundManager.play("modal_close")
	sig_closed.emit()

# =============================================================================
func _load_url(url: String) -> void:
	url = url.strip_edges().to_lower()
	address_bar.text = url
	
	if url == "home.sim" or url == "":
		address_bar.text = "home.sim"
		_build_home_sim()
	elif url == "angelus2010.sim":
		_show_message(GameState.T("sim.easter.angelus"))
	elif url == "claude.sim":
		_show_message(GameState.T("sim.easter.claude"))
	else:
		var text = GameState.T("sim.error.404")
		_show_message(text.replace("%s", url))

# =============================================================================
func _show_message(msg: String) -> void:
	header_box.visible = false
	lbl_tip.visible = false
	grid.visible = false
	
	var vbox = grid.get_parent()
	for child in vbox.get_children():
		if child.name == "MessageLabel":
			child.queue_free()
		
	var lbl = Label.new()
	lbl.name = "MessageLabel"
	lbl.theme_type_variation = &"HeaderLarge"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.custom_minimum_size = Vector2(800, 400)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.text = msg
	vbox.add_child(lbl)

# =============================================================================
func _build_home_sim() -> void:
	header_box.visible = true
	lbl_tip.visible = true
	grid.visible = true
	
	var vbox = grid.get_parent()
	for child in vbox.get_children():
		if child.name == "MessageLabel":
			child.queue_free()
	
	for child in grid.get_children():
		child.queue_free()
		
	var sites = _load_sites_from_json()
	for site in sites:
		var tile = TILE_SCENE.instantiate() as SimBrowserTile
		grid.add_child(tile)
		tile.setup(site)
		tile.pressed.connect(func() -> void: _load_url(site.get("url", "unknown.sim")))

# =============================================================================
func _load_sites_from_json() -> Array:
	if not FileAccess.file_exists(SITES_CONFIG_PATH):
		push_error("Config file not found: " + SITES_CONFIG_PATH)
		return []
		
	var file = FileAccess.open(SITES_CONFIG_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.parse_string(content)
	
	if typeof(json) == TYPE_ARRAY:
		return json
	return []
