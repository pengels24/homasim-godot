extends Control
## Neue Musik-Steuerung im Ingame-HUD: Play/Stop + Next.

# Die drei SVG-Icons als Konstanten vorgeladen
const ICON_PLAY    = preload("res://assets/icons/HUDTop/play.svg")
const ICON_STOP    = preload("res://assets/icons/HUDTop/square.svg")
const ICON_FORWARD = preload("res://assets/icons/HUDTop/fast-forward.svg")

@onready var music_stop_play: Button = %MusicStopPlay
@onready var music_next: Button = %MusicNext

# =============================================================================
func _ready() -> void:
	# Buttons mit Unique-Names verdrahten
	music_stop_play.pressed.connect(_on_stop_play_pressed)
	music_next.pressed.connect(_on_next_pressed)

	# Lokalisierte Tooltips zuweisen
	music_stop_play.tooltip_text = GameState.T("hud.music.play_stop.tooltip")
	music_next.tooltip_text      = GameState.T("hud.music.next.tooltip")

	# Dem globalen MusicManager lauschen
	if MusicManager.has_signal("playback_changed"):
		MusicManager.playback_changed.connect(_update_ui)

	# Startzustand der Symbole erzwingen
	_update_ui()


# =============================================================================
func _on_stop_play_pressed() -> void:
	MusicManager.toggle_pause()


# =============================================================================
func _on_next_pressed() -> void:
	MusicManager.next_track()


# =============================================================================
func _update_ui() -> void:
	var is_paused: bool = MusicManager.is_paused()

	if is_paused:
		# Musik pausiert/gestoppt -> Zeige PLAY-Symbol
		music_stop_play.icon = ICON_PLAY
	else:
		# Musik läuft -> Zeige STOP-Symbol
		music_stop_play.icon = ICON_STOP