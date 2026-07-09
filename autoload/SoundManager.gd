extends Node

const CONFIG_PATH = "res://config/sounds.json"

var _sounds: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
const POOL_SIZE = 8

func _ready() -> void:
	# Make sure it always processes, even when paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_config()
	_init_pool()
	
	# Globales Binding für alle zukünftigen Buttons
	get_tree().node_added.connect(_on_node_added)
	
	# Binde alle bereits existierenden Buttons (falls SoundManager nach anderen Nodes geladen wird)
	bind_buttons(get_tree().root)

func _on_node_added(node: Node) -> void:
	if node is Button:
		if not node.pressed.is_connected(play_button_click):
			node.pressed.connect(play_button_click)

func _load_config() -> void:
	if not FileAccess.file_exists(CONFIG_PATH):
# 		push_warning("SoundManager: Config not found at %s" % CONFIG_PATH)
		return
		
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	
	if typeof(data) == TYPE_DICTIONARY:
		for key in data.keys():
			var path = data[key]
			if ResourceLoader.exists(path):
				var stream = load(path)
				if stream:
					_sounds[key] = stream
			else:
				pass
# 				push_warning("SoundManager: Sound file missing -> %s" % path)

func _init_pool() -> void:
	for i in range(POOL_SIZE):
		var player = AudioStreamPlayer.new()
		player.bus = "Sound"
		add_child(player)
		_players.append(player)

func play(sound_name: String) -> void:
	if not _sounds.has(sound_name):
		return
		
	var stream = _sounds[sound_name]
	
	# Find an available player
	var selected_player: AudioStreamPlayer = null
	for p in _players:
		if not p.playing:
			selected_player = p
			break
			
	# If all players are busy, take the oldest one (the first one)
	# and force it to play the new sound. Alternatively, create a new one dynamically.
	if selected_player == null:
		selected_player = _players.pop_front()
		_players.append(selected_player)
		
	selected_player.stream = stream
	selected_player.volume_db = 0.0
	
	if sound_name == "cash":
		var cam = get_viewport().get_camera_2d()
		if cam and cam.zoom.x < 1.4:
			selected_player.volume_db = -80.0
			
	selected_player.play()

# Hilfsfunktionen für Buttons, damit man das easy connecten kann
func play_button_click() -> void:
	play("button_click")

func bind_buttons(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			if not child.pressed.is_connected(play_button_click):
				child.pressed.connect(play_button_click)
		bind_buttons(child)
