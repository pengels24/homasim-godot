extends Node
## Verwaltet Hintergrundmusik für Menü und Ingame.
## Tracks werden automatisch erkannt: menu_music_01.mp3 … bis erste fehlende Nummer.
## Neue Tracks einfach ins Verzeichnis legen – kein Code-Update nötig.

const AUDIO_DIR      := "res://assets/audio/"
const MENU_PREFIX    := "menu_music_"
const INGAME_PREFIX  := "ingame_music_"
const FADE_IN_SEC    := 1.5
const FADE_OUT_SEC   := 1.0

var _menu_player:    AudioStreamPlayer
var _ingame_player:  AudioStreamPlayer
var _menu_tracks:    Array[AudioStream] = []
var _ingame_tracks:  Array[AudioStream] = []
var _menu_idx:       int = 0
var _ingame_idx:     int = 0
var _menu_tween:     Tween = null
var _ingame_tween:   Tween = null
var _paused:         bool  = false

signal playback_changed  ## Wird emittiert wenn pause/resume/next ausgelöst wird


# =============================================================================
func _ready() -> void:
	_menu_player = AudioStreamPlayer.new()
	_menu_player.bus = "Menu Music"
	add_child(_menu_player)
	_menu_player.finished.connect(_on_menu_finished)

	_ingame_player = AudioStreamPlayer.new()
	_ingame_player.bus = "Music"
	add_child(_ingame_player)
	_ingame_player.finished.connect(_on_ingame_finished)

	_menu_tracks   = _discover(MENU_PREFIX)
	_ingame_tracks = _discover(INGAME_PREFIX)


# ── Public API ────────────────────────────────────────────────────────────────

# =============================================================================
func play_menu() -> void:
	if _menu_player.playing:
		return
	_paused = false
	_ingame_tween = _fade_out(_ingame_player, _ingame_tween)
	_menu_tracks.shuffle()
	_menu_idx = 0
	_play_menu_track()


# =============================================================================
func play_ingame() -> void:
	if _ingame_player.playing:
		return
	_paused = false
	_menu_tween = _fade_out(_menu_player, _menu_tween)
	_ingame_tracks.shuffle()
	_ingame_idx = 0
	_play_ingame_track()


# =============================================================================
func stop() -> void:
	_paused = false
	_menu_tween   = _fade_out(_menu_player,   _menu_tween)
	_ingame_tween = _fade_out(_ingame_player, _ingame_tween)


# =============================================================================
func toggle_pause() -> void:
	_paused = not _paused
	_menu_player.stream_paused   = _paused
	_ingame_player.stream_paused = _paused
	playback_changed.emit()


# =============================================================================
func next_track() -> void:
	if _ingame_player.playing or _ingame_player.stream_paused:
		_ingame_tween = _fade_out(_ingame_player, _ingame_tween)
		_ingame_idx = (_ingame_idx + 1) % max(_ingame_tracks.size(), 1)
		_play_ingame_track()
	elif _menu_player.playing or _menu_player.stream_paused:
		_menu_tween = _fade_out(_menu_player, _menu_tween)
		_menu_idx = (_menu_idx + 1) % max(_menu_tracks.size(), 1)
		_play_menu_track()
	if _paused:
		_paused = false
	playback_changed.emit()


# =============================================================================
func is_paused() -> bool:
	return _paused


# ── Intern ────────────────────────────────────────────────────────────────────

# =============================================================================
func _discover(prefix: String) -> Array[AudioStream]:
	var tracks: Array[AudioStream] = []
	for i in range(1, 100):
		var path := AUDIO_DIR + prefix + "%02d.mp3" % i
		if not ResourceLoader.exists(path):
			break
		tracks.append(load(path) as AudioStream)
	tracks.shuffle()
	return tracks


# =============================================================================
func _play_menu_track() -> void:
	if _menu_tracks.is_empty():
		return
	_kill_tween(_menu_tween)
	_menu_player.stream_paused = false
	_menu_player.stream = _menu_tracks[_menu_idx]
	_menu_player.play()
	_menu_tween = _fade_in(_menu_player)


# =============================================================================
func _play_ingame_track() -> void:
	if _ingame_tracks.is_empty():
		return
	_kill_tween(_ingame_tween)
	_ingame_player.stream_paused = false
	_ingame_player.stream = _ingame_tracks[_ingame_idx]
	_ingame_player.play()
	_ingame_tween = _fade_in(_ingame_player)


# =============================================================================
func _fade_in(player: AudioStreamPlayer) -> Tween:
	player.volume_db = -80.0
	var tw := create_tween()
	tw.tween_property(player, "volume_db", 0.0, FADE_IN_SEC)
	return tw


# =============================================================================
func _fade_out(player: AudioStreamPlayer, old_tween: Tween) -> Tween:
	if not player.playing:
		return null
	_kill_tween(old_tween)
	var tw := create_tween()
	tw.tween_property(player, "volume_db", -80.0, FADE_OUT_SEC)
	tw.tween_callback(player.stop)
	tw.tween_callback(func(): player.volume_db = 0.0)
	return tw


# =============================================================================
func _kill_tween(tw: Tween) -> void:
	if is_instance_valid(tw):
		tw.kill()


# =============================================================================
func _on_menu_finished() -> void:
	_menu_idx = (_menu_idx + 1) % _menu_tracks.size()
	_play_menu_track()


# =============================================================================
func _on_ingame_finished() -> void:
	_ingame_idx = (_ingame_idx + 1) % _ingame_tracks.size()
	_play_ingame_track()
