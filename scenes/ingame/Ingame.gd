extends Node2D

## ANG-148 – Ingame-Grundgerüst
## Hotel-Grid (5×5 Parzellen, je 16×16 Tiles) mit Kenney-Tiles.
## Kamera: WASD pan, Scrollrad/+− zoom, RMB drag.
## HUD: TopBar (glassmorphism) + BottomBar (schwebend) + ContextBar (R/T/Z, versteckt)

@onready var floor_layer: TileMapLayer = $WorldRoot/FloorLayer
@onready var wall_layer:  TileMapLayer = $WorldRoot/WallLayer
@onready var camera:      Camera2D     = $Camera2D

@onready var hotel_name_lbl: Label        = $HUD/TopBar/HBox/HotelSection/HotelName
@onready var level_lbl:      Label        = $HUD/TopBar/HBox/HotelSection/LevelLbl
@onready var stat_day_val:   Label        = $HUD/TopBar/HBox/StatsSection/StatDay/Value
@onready var stat_money_val: Label        = $HUD/TopBar/HBox/StatsSection/StatMoney/Value
@onready var stat_guests_val:Label        = $HUD/TopBar/HBox/StatsSection/StatGuests/Value
@onready var stat_ap_val:    Label        = $HUD/TopBar/HBox/StatsSection/StatAP/Value
@onready var stat_exp_bar:   ProgressBar  = $HUD/TopBar/HBox/StatsSection/StatEXP/Bar
@onready var stat_exp_lbl:   Label        = $HUD/TopBar/HBox/StatsSection/StatEXP/ValueLbl
@onready var stat_ruf_bar:   ProgressBar  = $HUD/TopBar/HBox/StatsSection/StatRUF/Bar
@onready var stat_fp_val:    Label        = $HUD/TopBar/HBox/StatsSection/StatFP/Value
@onready var time_lbl:       Label        = $HUD/TopBar/HBox/TimeSection/TimeLbl
@onready var btn_pause:      Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPause
@onready var btn_play:       Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPlay
@onready var btn_ff:         Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnFF
@onready var bottom_anchor:  Control   = $HUD/BottomBarAnchor
@onready var context_bar:    HBoxContainer = $HUD/ContextBar

## Tile-Konstanten – Source-IDs entsprechen der Reihenfolge in _build_tileset()
const TILE_STREET  := 0
const TILE_GRASS   := 1
const TILE_FLOOR   := 2
const TILE_LOBBY   := 3
const TILE_WALL    := 4

## Grid-Konfiguration
const PARCELS    := 5        # 5×5 Parzellen
const PARCEL_SZ  := 16       # 16×16 Tiles pro Parzelle
const STREET_W   := 3        # Straßenrand außerhalb des Parzellengrids (Tiles)
const TILE_PX    := 16       # Physische Tile-Größe in Px
const SCALE      := 2.0      # Anzeige-Skalierung → 32px/Tile sichtbar

## Raum-Konfiguration (gilt für alle Raumtypen inkl. Lobby)
## Jeder Raum = ROOM_FLOOR × ROOM_FLOOR Bodentiles + 1-Tile-Wandring
const ROOM_FLOOR := 2        # Innenfläche pro Raum (2×2 Tiles)
const ROOM_OUTER := 4        # Gesamtfußabdruck inkl. Wandring (ROOM_FLOOR + 2)

## HUD-Fontgrößen – alle GDScript-gebauten Nodes nutzen diese Konstanten.
## Später: HUD-Scale (ANG-152) multipliziert diese Werte.
const HF_XS   := 10   # Subtext
const HF_SM   := 12   # Key-Labels (TAG, KAPITAL, AP …)
const HF_MD   := 14   # BottomBar-Buttons, Hints, ContextBar
const HF_LG   := 16   # Stat-Values
const HF_XL   := 18   # Hotel-Name
const HF_TIME := 22   # Spielzeit-Anzeige
const HF_LOGO := 22   # (Logo ist jetzt ein Bild – Konstante bleibt für Fallback)

## Kamera-Steuerung
const PAN_SPEED  := 100.0    # Tiles/s (×SCALE für globale Pixel)
const ZOOM_MIN   := 0.5
const ZOOM_MAX   := 4.0
const ZOOM_STEP  := 0.15

var _drag_active := false
var _drag_origin := Vector2.ZERO
var _cam_origin  := Vector2.ZERO

var _tile_set: TileSet

## BottomBar-Referenzen – gebaut in _build_bottom_bar()
var _bottom_panel: PanelContainer
var _bottom_buttons: Array[Button] = []
var _active_submenu: PanelContainer = null

## Spielzeit (lokal – nicht von API)
var _game_hour:   int = 10
var _game_minute: int = 0
var _game_paused: bool = true
var _game_speed:  float = 1.0   # 1× oder 3× (FF)
var _time_accum:  float = 0.0
const SECONDS_PER_GAME_MINUTE := 2.0  # 1 Spielminute = 2 Sekunden Realzeit


func _ready() -> void:
	_build_tileset()
	_setup_layers()
	_build_map()
	_setup_hud()
	_build_bottom_bar()
	_build_context_bar()
	_position_camera()
	_connect_game_controls()


## TileSet aus den Kenney-Einzeltiles aufbauen (programmatisch)
func _build_tileset() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(TILE_PX, TILE_PX)

	var paths := [
		"res://assets/tiles/outside_street.png",  # 0 TILE_STREET
		"res://assets/tiles/outside_grass.png",   # 1 TILE_GRASS
		"res://assets/tiles/floor_hotel.png",     # 2 TILE_FLOOR
		"res://assets/tiles/floor_lobby.png",     # 3 TILE_LOBBY
		"res://assets/tiles/wall_brick.png",      # 4 TILE_WALL
	]

	for path in paths:
		var src := TileSetAtlasSource.new()
		src.texture = load(path)
		src.texture_region_size = Vector2i(TILE_PX, TILE_PX)
		src.create_tile(Vector2i(0, 0))
		_tile_set.add_source(src)


func _setup_layers() -> void:
	floor_layer.tile_set = _tile_set
	wall_layer.tile_set  = _tile_set


## Startparzelle aus hotel["unlocked_plots"] lesen (JSON-Array [[x,y], ...])
func _get_entry_plot() -> Vector2i:
	var raw: Variant = GameState.selected_hotel.get("unlocked_plots", null)
	if raw is String and raw != "":
		var parsed: Variant = JSON.parse_string(raw)
		if parsed is Array and not parsed.is_empty() and parsed[0] is Array:
			return Vector2i(int(parsed[0][0]), int(parsed[0][1]))
	return Vector2i(2, 0)


## Karte aufbauen:
## – Straßenrand (STREET_W Tiles) außerhalb des 5×5 Parzellengrids
## – Parzellenflächen bleiben leer (dunkler Hintergrund = freies Land)
## – Lobby-Raum als kleines Gebäude an der Straßenseite der Startparzelle
func _build_map() -> void:
	var entry   := _get_entry_plot()
	var total_w := PARCELS * PARCEL_SZ + STREET_W * 2
	var total_h := PARCELS * PARCEL_SZ + STREET_W * 2

	# Straße + Parzellenbelag zeichnen
	for ty in total_h:
		for tx in total_w:
			var in_street := (tx < STREET_W or tx >= total_w - STREET_W or
							  ty < STREET_W or ty >= total_h - STREET_W)
			if in_street:
				floor_layer.set_cell(Vector2i(tx, ty), TILE_STREET, Vector2i(0, 0))
			else:
				# Parzellenfläche = neutraler dunkler Boden (bebaubar)
				floor_layer.set_cell(Vector2i(tx, ty), TILE_FLOOR, Vector2i(0, 0))

	# Lobby-Raum platzieren
	var raw_dir: String = GameState.selected_hotel.get("entrance_direction", "")
	var direction: String = raw_dir if raw_dir != "" else _derive_direction(entry.x, entry.y)
	_place_room(entry.x, entry.y, direction, TILE_LOBBY)


## Türrichtung aus Parzellenposition ableiten (Fallback wenn API-Feld fehlt)
func _derive_direction(px: int, py: int) -> String:
	if py == 0:             return "top"
	if py == PARCELS - 1:  return "bottom"
	if px == 0:             return "left"
	return "right"


## Einen Raum in einer Parzelle platzieren – zentriert an der straßenseitigen Kante.
## Gilt für alle Raumtypen (Lobby, Zimmer, Büro …).
## entrance_dir bestimmt an welcher Parzellenecke der Raum liegt + wo die Tür ist.
func _place_room(px: int, py: int, entrance_dir: String, floor_tile: int) -> void:
	var ox := STREET_W + px * PARCEL_SZ
	var oy := STREET_W + py * PARCEL_SZ

	# Raum zentriert an der Eingangsseite der Parzelle positionieren
	var side_offset := (PARCEL_SZ - ROOM_OUTER) / 2  # Zentrierung auf der Nicht-Eingangs-Achse
	var bx: int
	var by: int
	match entrance_dir:
		"top":
			bx = ox + side_offset
			by = oy
		"bottom":
			bx = ox + side_offset
			by = oy + PARCEL_SZ - ROOM_OUTER
		"left":
			bx = ox
			by = oy + side_offset
		_:  # "right"
			bx = ox + PARCEL_SZ - ROOM_OUTER
			by = oy + side_offset

	# Bodentiles (ROOM_FLOOR × ROOM_FLOOR innerhalb des Wandrings)
	for iy in ROOM_FLOOR:
		for ix in ROOM_FLOOR:
			floor_layer.set_cell(Vector2i(bx + 1 + ix, by + 1 + iy), floor_tile, Vector2i(0, 0))

	# Wandring mit 2-Tile-Türöffnung (zentriert auf der Eingangsseite)
	var door_a := ROOM_OUTER / 2 - 1   # erster Türtile-Index
	var door_b := ROOM_OUTER / 2       # zweiter Türtile-Index
	for i in ROOM_OUTER:
		var is_door := (i == door_a or i == door_b)
		if not (entrance_dir == "top"    and is_door):
			wall_layer.set_cell(Vector2i(bx + i, by),                  TILE_WALL, Vector2i(0, 0))
		if not (entrance_dir == "bottom" and is_door):
			wall_layer.set_cell(Vector2i(bx + i, by + ROOM_OUTER - 1), TILE_WALL, Vector2i(0, 0))
		if not (entrance_dir == "left"   and is_door):
			wall_layer.set_cell(Vector2i(bx,              by + i),      TILE_WALL, Vector2i(0, 0))
		if not (entrance_dir == "right"  and is_door):
			wall_layer.set_cell(Vector2i(bx + ROOM_OUTER - 1, by + i), TILE_WALL, Vector2i(0, 0))


func _setup_hud() -> void:
	var hotel := GameState.selected_hotel
	hotel_name_lbl.text  = hotel.get("name", "Hotel")
	level_lbl.text       = "LVL " + str(int(hotel.get("level", 1)))
	stat_day_val.text    = str(int(hotel.get("day_counter", 1)))
	stat_money_val.text  = "€ " + _format_money(int(hotel.get("money", 0)))
	stat_guests_val.text = str(int(hotel.get("guests", 0)))
	stat_ap_val.text     = "–"  # kein AP-Feld in API – Platzhalter

	# EXP: xp + xp_needed kommen beide aus /api/hotels
	var xp: int        = int(hotel.get("xp",        0))
	var xp_max: int    = int(hotel.get("xp_needed", 100))
	stat_exp_bar.max_value = xp_max
	stat_exp_bar.value     = xp
	stat_exp_lbl.text      = "%d / %d" % [xp, xp_max]

	# Reputation: 0–1000
	var rep: int = int(hotel.get("reputation", 0))
	stat_ruf_bar.max_value = 1000
	stat_ruf_bar.value     = rep

	# Forschungspunkte
	stat_fp_val.text = str(int(hotel.get("research_points", 0)))

	# Spielzeit aus API-Feld initialisieren (Minuten seit Mitternacht, 600 = 10:00)
	var game_time_min: int = int(hotel.get("game_time", 600))
	_game_hour   = game_time_min / 60
	_game_minute = game_time_min % 60
	_update_time_label()


## BottomBar programmatisch aufbauen – schwebendes Panel mit F1-F7 + Exit
func _build_bottom_bar() -> void:
	var sb_panel := StyleBoxFlat.new()
	sb_panel.bg_color             = Color(0.04, 0.06, 0.10, 0.92)
	sb_panel.corner_radius_top_left    = 14
	sb_panel.corner_radius_top_right   = 14
	sb_panel.corner_radius_bottom_left = 14
	sb_panel.corner_radius_bottom_right= 14
	sb_panel.border_width_top     = 1
	sb_panel.border_color         = Color(0.918, 0.702, 0.031, 0.25)
	sb_panel.content_margin_left  = 12.0
	sb_panel.content_margin_right = 12.0
	sb_panel.content_margin_top   = 10.0
	sb_panel.content_margin_bottom= 10.0

	_bottom_panel = PanelContainer.new()
	_bottom_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_bottom_panel.add_theme_stylebox_override("panel", sb_panel)
	bottom_anchor.add_child(_bottom_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	_bottom_panel.add_child(hbox)

	# Hauptaktions-Buttons: Label + Funktionstaste
	var btn_defs: Array[Dictionary] = [
		{"label": GameState.T("ingame.btn.build"),    "key": "F2"},
		{"label": GameState.T("ingame.btn.reception"),"key": "F3"},
		{"label": GameState.T("ingame.btn.staff"),    "key": "F4"},
		{"label": GameState.T("ingame.btn.rooms"),    "key": "F5"},
		{"label": GameState.T("ingame.btn.finance"),  "key": "F6"},
		{"label": GameState.T("ingame.btn.events"),   "key": "F7"},
	]

	for i in btn_defs.size():
		var def: Dictionary = btn_defs[i]
		var btn := _make_bottom_button(def["label"], def["key"])
		hbox.add_child(btn)
		_bottom_buttons.append(btn)
		var idx := i  # Kopie für Closure
		btn.pressed.connect(func(): _on_bottom_button(idx))

	# Separator
	var sep := ColorRect.new()
	sep.custom_minimum_size = Vector2(1, 0)
	sep.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sep.color = Color(0.918, 0.702, 0.031, 0.20)
	hbox.add_child(sep)

	# Exit-Button → zurück zum Dashboard
	var btn_exit := _make_bottom_button(GameState.T("menu.btn.main_menu"), "ESC")
	btn_exit.add_theme_color_override("font_color",          Color(0.863, 0.149, 0.149, 1))
	btn_exit.add_theme_color_override("font_hover_color",    Color(1.0,   0.3,   0.3,   1))
	btn_exit.add_theme_color_override("font_pressed_color",  Color(0.7,   0.1,   0.1,   1))
	hbox.add_child(btn_exit)
	btn_exit.pressed.connect(_on_exit_pressed)


func _make_bottom_button(label_text: String, key_text: String) -> Button:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.bg_color              = Color(0.10, 0.14, 0.20, 0.85)
	sb_normal.corner_radius_top_left    = 6
	sb_normal.corner_radius_top_right   = 6
	sb_normal.corner_radius_bottom_left = 6
	sb_normal.corner_radius_bottom_right= 6
	sb_normal.content_margin_left  = 12.0
	sb_normal.content_margin_right = 12.0
	sb_normal.content_margin_top   = 6.0
	sb_normal.content_margin_bottom= 6.0

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = Color(0.15, 0.21, 0.30, 1.0)

	var btn := Button.new()
	btn.text = "%s  [%s]" % [label_text, key_text]
	btn.add_theme_font_size_override("font_size", HF_MD)
	btn.add_theme_stylebox_override("normal",  sb_normal)
	btn.add_theme_stylebox_override("hover",   sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_hover)
	btn.add_theme_color_override("font_color",       Color(0.80, 0.80, 0.80, 1))
	btn.add_theme_color_override("font_hover_color", Color(0.95, 0.95, 0.95, 1))
	return btn


## ContextBar befüllen – R/T/Z Shortcuts (nur im Baumodus sichtbar)
func _build_context_bar() -> void:
	var hints: Array[Dictionary] = [
		{"key": "R", "label": GameState.T("ingame.ctx.rotate_door")},
		{"key": "T", "label": GameState.T("ingame.ctx.move_door")},
		{"key": "Z", "label": GameState.T("ingame.ctx.flip_room")},
	]

	for hint in hints:
		var key_lbl := Label.new()
		key_lbl.text = "[%s]" % hint["key"]
		key_lbl.add_theme_font_size_override("font_size", HF_MD)
		key_lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 1))

		var desc_lbl := Label.new()
		desc_lbl.text = hint["label"]
		desc_lbl.add_theme_font_size_override("font_size", HF_MD)
		desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65, 1))

		context_bar.add_child(key_lbl)
		context_bar.add_child(desc_lbl)

		# Trenner zwischen Hints (nicht nach dem letzten)
		if hint != hints.back():
			var sep := Label.new()
			sep.text = "·"
			sep.add_theme_font_size_override("font_size", HF_MD)
			sep.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35, 1))
			context_bar.add_child(sep)


func _connect_game_controls() -> void:
	btn_pause.pressed.connect(_on_pause_pressed)
	btn_play.pressed.connect(_on_play_pressed)
	btn_ff.pressed.connect(_on_ff_pressed)
	_update_speed_buttons()


## Kamera mittig über der Lobby-Parzelle starten + Clamp-Grenzen setzen
func _position_camera() -> void:
	var entry := _get_entry_plot()
	var center_tile := Vector2(
		(STREET_W + entry.x * PARCEL_SZ + PARCEL_SZ / 2.0) * TILE_PX,
		(STREET_W + entry.y * PARCEL_SZ + PARCEL_SZ / 2.0) * TILE_PX
	)
	camera.position = center_tile * SCALE
	camera.zoom = Vector2(1.0, 1.0)

	var map_px: float = (PARCELS * PARCEL_SZ + STREET_W * 2) * TILE_PX * SCALE
	camera.limit_left   = 0
	camera.limit_top    = 0
	camera.limit_right  = int(map_px)
	camera.limit_bottom = int(map_px)


func _process(delta: float) -> void:
	_handle_pan(delta)
	_handle_zoom_keys(delta)
	_tick_game_clock(delta)


func _handle_pan(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_action_pressed("ui_left")  or Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_action_pressed("ui_down")  or Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	if Input.is_action_pressed("ui_up")    or Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if dir != Vector2.ZERO:
		camera.position += dir.normalized() * PAN_SPEED * delta / camera.zoom.x


## + / - / Numpad* für Tastatur-Zoom (gehalten = kontinuierlich)
func _handle_zoom_keys(delta: float) -> void:
	var zoom_dir := 0.0
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		zoom_dir = 1.0
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		zoom_dir = -1.0
	elif Input.is_key_pressed(KEY_KP_MULTIPLY):
		camera.zoom = Vector2(1.0, 1.0)
		return
	if zoom_dir != 0.0:
		_zoom_camera(zoom_dir * ZOOM_STEP * delta * 10.0)


## Spielzeit vorrücken lassen (lokal, nicht API)
## Ein Spieltag = 0–1439 Minuten. Bei 1440 → neuer Tag, Sync an API.
func _tick_game_clock(delta: float) -> void:
	if _game_paused:
		return
	_time_accum += delta * _game_speed
	var minutes_passed := int(_time_accum / SECONDS_PER_GAME_MINUTE)
	if minutes_passed == 0:
		return
	_time_accum -= minutes_passed * SECONDS_PER_GAME_MINUTE
	_game_minute += minutes_passed
	if _game_minute >= 60:
		_game_hour  += _game_minute / 60
		_game_minute  = _game_minute % 60
	# Tagesende bei Minute 1440 (= 24:00)
	if _game_hour >= 24:
		_game_hour   = 0
		_game_minute = 0
		_on_day_end()
	_update_time_label()


func _on_day_end() -> void:
	# Tag hochzählen (lokal im State – API bestätigt beim nächsten Login)
	var day: int = int(GameState.selected_hotel.get("day_counter", 1))
	GameState.selected_hotel["day_counter"] = day + 1
	stat_day_val.text = str(day + 1)
	_sync_time_to_api(0)  # neuer Tag beginnt bei 00:00


## Aktuelle Spielzeit an API schicken – POST /api/hotel/sync-time
func _sync_time_to_api(game_time_min: int) -> void:
	var hotel_id: Variant = GameState.selected_hotel.get("id", "")
	if hotel_id == "":
		return
	Api.post_form("/api/hotel/sync-time",
		{"hotel_id": str(hotel_id), "game_time": str(game_time_min)},
		func(_result: int, _code: int, _headers: PackedStringArray, _body: PackedByteArray): pass
	)


## Spielzeit beim Verlassen der Szene speichern
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_sync_time_to_api(_game_hour * 60 + _game_minute)


func _update_time_label() -> void:
	time_lbl.text = "%02d:%02d" % [_game_hour, _game_minute]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_zoom_camera(ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_zoom_camera(-ZOOM_STEP)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_drag_active = mb.pressed
			if _drag_active:
				_drag_origin = mb.position
				_cam_origin  = camera.position

	if event is InputEventMouseMotion and _drag_active:
		var mm := event as InputEventMouseMotion
		camera.position = _cam_origin - (mm.position - _drag_origin) / camera.zoom

	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			_handle_hotkey(ke.keycode)


func _handle_hotkey(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE: _on_exit_pressed()
		KEY_F2:     _on_bottom_button(0)  # Baumodus
		KEY_F3:     _on_bottom_button(1)  # Rezeption
		KEY_F4:     _on_bottom_button(2)  # Personal
		KEY_F5:     _on_bottom_button(3)  # Zimmer
		KEY_F6:     _on_bottom_button(4)  # Finanzen
		KEY_F7:     _on_bottom_button(5)  # Events


func _zoom_camera(delta: float) -> void:
	var new_zoom: float = clampf(camera.zoom.x + delta, ZOOM_MIN, ZOOM_MAX)
	camera.zoom = Vector2(new_zoom, new_zoom)


## Spielsteuerung
func _on_pause_pressed() -> void:
	_game_paused = true
	_game_speed  = 1.0
	_update_speed_buttons()


func _on_play_pressed() -> void:
	_game_paused = false
	_game_speed  = 1.0
	_update_speed_buttons()


func _on_ff_pressed() -> void:
	_game_paused = false
	_game_speed  = 10.0
	_update_speed_buttons()


func _update_speed_buttons() -> void:
	var gold   := Color(0.918, 0.702, 0.031, 1)
	var normal := Color(0.65,  0.65,  0.65,  1)

	btn_pause.add_theme_color_override("font_color", gold   if _game_paused         else normal)
	btn_play.add_theme_color_override( "font_color", gold   if not _game_paused and _game_speed == 1.0 else normal)
	btn_ff.add_theme_color_override(   "font_color", gold   if _game_speed == 10.0  else normal)


## BottomBar-Button-Handler – Submenüs (Inhalt kommt mit Feature-Implementierung)
func _on_bottom_button(idx: int) -> void:
	# Aktives Submenü toggeln oder schließen
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null
		if _active_submenu_idx == idx:
			_active_submenu_idx = -1
			return
	_active_submenu_idx = idx
	# Leeres Submenü-Panel nach oben – Inhalt folgt mit Feature-Implementierung
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color              = Color(0.04, 0.06, 0.10, 0.95)
	sb.corner_radius_top_left    = 10
	sb.corner_radius_top_right   = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right= 10
	sb.border_width_top    = 1
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_color        = Color(0.918, 0.702, 0.031, 0.30)
	sb.content_margin_left  = 16.0
	sb.content_margin_right = 16.0
	sb.content_margin_top   = 12.0
	sb.content_margin_bottom= 12.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = GameState.T("ingame.submenu.coming_soon")
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
	panel.add_child(lbl)

	# Submenü-Panel über dem BottomBar positionieren
	var hud: CanvasLayer = $HUD
	hud.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	await get_tree().process_frame
	var btn_pos: Vector2 = _bottom_buttons[idx].global_position
	panel.position = Vector2(btn_pos.x, btn_pos.y - panel.size.y - 8)
	_active_submenu = panel


var _active_submenu_idx: int = -1


func _on_exit_pressed() -> void:
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null
		return
	_sync_time_to_api(_game_hour * 60 + _game_minute)
	get_tree().change_scene_to_file("res://scenes/dashboard/Dashboard.tscn")


func _format_money(amount: int) -> String:
	var s := str(amount)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "." + result
		result = s[i] + result
		count += 1
	return result
