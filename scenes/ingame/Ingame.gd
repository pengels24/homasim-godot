extends Node2D

## ANG-148 – Ingame-Grundgerüst
## HUD: TopBar (glassmorphism) + BottomBar (schwebend) + ContextBar (R/T/Z, versteckt)
## ANG-153 – Map-Grid und Kamera ausgelagert nach scenes/ingame/map/MapGrid.gd

# ── Nodes ─────────────────────────────────────────────────────────────────────
@onready var map_grid: Node2D = $MapGrid

@onready var hotel_name_lbl: Label        = $HUD/TopBar/HBox/NameSection/Value
@onready var level_lbl:      Label        = $HUD/TopBar/HBox/LevelSection/Value
@onready var stat_day_val:        Label   = $HUD/TopBar/HBox/TimeSection/TagBox/Value
@onready var stat_money_val:      Label   = $HUD/TopBar/HBox/StatsSection/StatMoney/Value
@onready var stat_guests_wait:    Label   = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/WaitLbl
@onready var stat_guests_active:  Label   = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/ActiveLbl
@onready var stat_guests_out:     Label   = $HUD/TopBar/HBox/StatsSection/StatGuests/GuestsBox/OutLbl
@onready var stat_ap_val:         Label   = $HUD/TopBar/HBox/StatsSection/StatAP/Value
@onready var stat_exp_bar:        ProgressBar = $HUD/TopBar/HBox/StatsSection/StatEXP/Bar
@onready var stat_exp_lbl:        Label   = $HUD/TopBar/HBox/StatsSection/StatEXP/ValueLbl
@onready var stat_ruf_root:       Control = $HUD/TopBar/HBox/StatsSection/StatRUF/RufBarRoot
@onready var stat_ruf_lbl:        Label   = $HUD/TopBar/HBox/StatsSection/StatRUF/RufValueLbl
@onready var stat_fp_val:         Label   = $HUD/TopBar/HBox/StatsSection/StatFP/Value
@onready var time_lbl:       Label        = $HUD/TopBar/HBox/TimeSection/TimeLbl
@onready var btn_pause:      Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPause
@onready var btn_play:       Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnPlay
@onready var btn_ff:         Button    = $HUD/TopBar/HBox/TimeSection/GameControls/BtnFF
@onready var bottom_anchor:  Control   = $HUD/BottomBarAnchor
@onready var context_bar:    HBoxContainer = $HUD/ContextBar

# ── HUD-Fontgrößen ────────────────────────────────────────────────────────────
## Alle GDScript-gebauten Nodes nutzen diese Konstanten.
## Später: HUD-Scale (ANG-152) multipliziert diese Werte.
const HF_XS   := 10   # Subtext
const HF_SM   := 12   # Key-Labels (TAG, KAPITAL, AP …)
const HF_MD   := 14   # BottomBar-Buttons, Hints, ContextBar
const HF_LG   := 16   # Stat-Values
const HF_XL   := 18   # Hotel-Name
const HF_TIME := 22   # Spielzeit-Anzeige
const HF_LOGO := 22   # (Logo ist jetzt ein Bild – Konstante bleibt für Fallback)

# ── BottomBar Fächer-Konstanten ───────────────────────────────────────────────
const BB_RING1_RADIUS := 108.0   # Radius innerer Knopfring
const BB_RING2_RADIUS := 160.0   # Radius äußerer Knopfring
const BB_RING1_COUNT  := 3       # Anzahl Buttons im inneren Ring
const BB_BTN_SIZE     := 46.0    # Einheitsgröße aller Fan-Buttons
const BB_FAN_SIZE     := 192.0   # Y-Position des Fächer-Ursprungs (= Höhe des Anchors)
const BB_ANGLE_MIN    := 14.0    # Start-Winkel in Grad (Abstand vom Bodenrand)
const BB_ANGLE_MAX    := 76.0    # End-Winkel in Grad (Abstand vom Seitenrand)

# ── Zustand ───────────────────────────────────────────────────────────────────
var _hotel: Dictionary = {}   # aktives Hotel aus SaveManager
var _ruf_indicator: ColorRect

## BottomBar-Referenzen – gebaut in _build_bottom_bar()
var _bottom_panel:    PanelContainer  # ungenutzt im Fächer-Modus, bleibt für Kompatibilität
var _fan_mode_btn:    Button          # Modus-Indikator in der Ecke
var _bottom_buttons: Array[Button] = []
var _active_btn_idx: int = -1
var _active_submenu: PanelContainer = null
var _active_submenu_idx: int = -1
var _bb_sb_normal: StyleBoxFlat
var _bb_sb_hover: StyleBoxFlat
var _bb_sb_active: StyleBoxFlat
var _tooltip_panel: PanelContainer
var _tooltip_lbl: Label
var _bb_btn_defs: Array[Dictionary] = []

## Spielzeit (lokal – nicht von API)
var _game_hour:   int = 10
var _game_minute: int = 0
var _game_paused: bool = true
var _game_speed:  float = 1.0   # 1× oder 3× (FF)
var _time_accum:  float = 0.0
const SECONDS_PER_GAME_MINUTE := 2.0  # 1 Spielminute = 2 Sekunden Realzeit


func _ready() -> void:
	_start_map()
	_build_ruf_bar()
	_setup_hud()
	_build_bottom_bar()
	_build_context_bar()
	_connect_game_controls()


# ── Map-Start ─────────────────────────────────────────────────────────────────

func _start_map() -> void:
	_hotel = _load_hotel()
	var built: Array = SaveManager.get_built_plots(_hotel.get("id", -1))
	if built.is_empty():
		built = [{ "x": 1, "y": 0, "is_built": true, "entrance_dir": "" }]
	var entry     := Vector2i(built[0]["x"], built[0]["y"])
	var enter_dir : String = built[0].get("entrance_dir", "")
	if enter_dir == "":
		enter_dir = _derive_direction(entry.x, entry.y)
	map_grid.build_map(built, entry, enter_dir)


func _load_hotel() -> Dictionary:
	if GameState.active_hotel_id >= 0:
		return SaveManager.get_hotel(GameState.active_hotel_id)
	var hotels: Array = SaveManager.get_hotels(1)
	if not hotels.is_empty():
		return hotels[0]
	return { "name": "Hotel", "day": 1, "money": 50000.0, "id": -1 }


func _derive_direction(px: int, py: int) -> String:
	if py == 0: return "top"
	if py == 4: return "bottom"
	if px == 0: return "left"
	return "right"


func _setup_hud() -> void:
	hotel_name_lbl.text     = _hotel.get("name", "Hotel")
	level_lbl.text          = "LVL 1"
	stat_day_val.text       = str(int(_hotel.get("day", 1)))
	stat_money_val.text     = "€ " + _format_money(int(_hotel.get("money", 0)))
	stat_guests_wait.text   = "0"
	stat_guests_active.text = "0"
	stat_guests_out.text    = "0"
	stat_ap_val.text        = "0 / 100"
	stat_exp_bar.max_value  = 100
	stat_exp_bar.value      = 0
	stat_exp_lbl.text       = "0 / 100"
	stat_fp_val.text        = "0"
	var game_time_min: int = int(_hotel.get("game_time", 600))
	_game_hour   = game_time_min / 60
	_game_minute = game_time_min % 60
	_update_time_label()
	_update_ruf_display(500)
	_apply_value_box(stat_money_val)
	_apply_value_box(stat_ap_val)
	_apply_value_box(stat_fp_val)
	_apply_value_box(stat_day_val)
	_apply_guest_badge(stat_guests_wait,   Color(0.20, 0.78, 0.35))
	_apply_guest_badge(stat_guests_active, Color(0.918, 0.702, 0.031))
	_apply_guest_badge(stat_guests_out,    Color(0.85, 0.20, 0.20))


## Subtiler Rahmen + hellerer Hintergrund für Wertfelder (KAPITAL, AP, FP, TAG)
func _apply_value_box(lbl: Label) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                    = Color(0.11, 0.15, 0.21, 1.0)
	sb.border_width_left           = 1
	sb.border_width_right          = 1
	sb.border_width_top            = 1
	sb.border_width_bottom         = 1
	sb.border_color                = Color(0.28, 0.30, 0.38, 0.65)
	sb.corner_radius_top_left      = 3
	sb.corner_radius_top_right     = 3
	sb.corner_radius_bottom_left   = 3
	sb.corner_radius_bottom_right  = 3
	sb.content_margin_left         = 8.0
	sb.content_margin_right        = 8.0
	sb.content_margin_top          = 3.0
	sb.content_margin_bottom       = 3.0
	lbl.add_theme_stylebox_override("normal", sb)


## Farbiger Badge für Gäste-Zähler (wartend/aktiv/checkout)
func _apply_guest_badge(lbl: Label, tint: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color                    = Color(tint.r, tint.g, tint.b, 0.12)
	sb.border_width_left           = 1
	sb.border_width_right          = 1
	sb.border_width_top            = 1
	sb.border_width_bottom         = 1
	sb.border_color                = Color(tint.r, tint.g, tint.b, 0.35)
	sb.corner_radius_top_left      = 3
	sb.corner_radius_top_right     = 3
	sb.corner_radius_bottom_left   = 3
	sb.corner_radius_bottom_right  = 3
	sb.content_margin_left         = 5.0
	sb.content_margin_right        = 5.0
	sb.content_margin_top          = 2.0
	sb.content_margin_bottom       = 2.0
	lbl.add_theme_stylebox_override("normal", sb)


## RUF-Gradient-Bar aufbauen: 5 farbige Segmente + weißer Indikator.
## Wird einmal in _ready() aufgerufen, _update_ruf_display() aktualisiert nur den Indikator.
func _build_ruf_bar() -> void:
	var colors: Array[Color] = [
		Color(0.82, 0.15, 0.15),   # rot        0–200
		Color(0.88, 0.48, 0.08),   # orange    200–400
		Color(0.84, 0.74, 0.08),   # gelb      400–600
		Color(0.30, 0.74, 0.22),   # hellgrün  600–800
		Color(0.08, 0.50, 0.12),   # dunkelgrün 800–1000
	]
	var bar_w  := 130.0
	var bar_h  := 10.0
	var seg_w  := bar_w / colors.size()

	for i in colors.size():
		var seg := ColorRect.new()
		seg.color    = colors[i]
		seg.position = Vector2(i * seg_w, 2.0)
		seg.size     = Vector2(seg_w, bar_h)
		# Abgerundete Ecken am ersten und letzten Segment simulieren via Überlapp – ColorRect hat keine Radius-Option
		stat_ruf_root.add_child(seg)

	# Indikator: schmaler weißer Strich der über die volle Bar-Höhe geht
	_ruf_indicator = ColorRect.new()
	_ruf_indicator.color = Color(1, 1, 1, 0.90)
	_ruf_indicator.size  = Vector2(2, 14)
	_ruf_indicator.position = Vector2(0, 0)
	stat_ruf_root.add_child(_ruf_indicator)

	await get_tree().process_frame
	_update_ruf_display(500)


func _update_ruf_display(rep: int) -> void:
	stat_ruf_lbl.text = "%d / 1000" % rep
	var bar_w := stat_ruf_root.size.x
	if bar_w == 0:
		bar_w = 130.0
	_ruf_indicator.position.x = clampf((rep / 1000.0) * bar_w - 1.0, 0.0, bar_w - 2.0)


## BottomBar als radialer Fächer aus der unteren linken Ecke.
## Hintergrund: StyleBoxFlat mit großem corner_radius_top_right → Viertelkreis-Form.
## Ring 1: BB_RING1_COUNT Buttons, Ring 2: verbleibende Buttons.
func _build_bottom_bar() -> void:
	# Ring 1 (idx 0–2): häufig genutzte Aktionen
	# Ring 2 (idx 3–6): erweiterte/gesperrte Features
	_bb_btn_defs = [
		{"icon": "+",  "icon_path": "res://assets/icons/ic_buildmode.svg",  "label": GameState.T("ingame.btn.build"),       "key": "F2",    "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "★",  "icon_path": "res://assets/icons/ic_browser.svg",    "label": GameState.T("ingame.btn.simbrowser"),  "key": "F7",    "locked": false, "dot_color": Color(0.20, 0.78, 0.35, 1)},
		{"icon": "⚙",  "icon_path": "res://assets/icons/ic_settings.svg",   "label": GameState.T("ingame.btn.settings"),    "key": "ALT+S", "locked": false, "dot_color": Color.TRANSPARENT},
		{"icon": "R",  "icon_path": "res://assets/icons/ic_reception.svg",  "label": GameState.T("ingame.btn.reception"),   "key": "F3",    "locked": false, "dot_color": Color(0.20, 0.78, 0.35, 1)},
		{"icon": "P",  "icon_path": "res://assets/icons/ic_staff.svg",      "label": GameState.T("ingame.btn.staff"),       "key": "F4",    "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "–",  "icon_path": "",                                       "label": GameState.T("ingame.btn.empty"),       "key": "F5",    "locked": true,  "dot_color": Color.TRANSPARENT},
		{"icon": "★",  "icon_path": "res://assets/icons/ic_techtree.svg",   "label": GameState.T("ingame.btn.research"),    "key": "F6",    "locked": true,  "dot_color": Color.TRANSPARENT},
	]

	_bb_sb_normal = _make_fan_stylebox(Color(0.06, 0.10, 0.18, 0.90), Color(0.20, 0.24, 0.35, 0.55))
	_bb_sb_hover  = _make_fan_stylebox(Color(0.10, 0.16, 0.26, 0.96), Color(0.918, 0.702, 0.031, 0.70))
	_bb_sb_active = _make_fan_stylebox(Color(0.22, 0.16, 0.02, 1.0),  Color(0.918, 0.702, 0.031, 1.0))

	# Fächer-Fläche: großer top-right Radius ergibt organische Viertelkreis-Form
	var sb_bg := StyleBoxFlat.new()
	sb_bg.bg_color                = Color(0.03, 0.06, 0.12, 0.93)
	sb_bg.corner_radius_top_right = 192
	sb_bg.border_width_top        = 1
	sb_bg.border_width_right      = 1
	sb_bg.border_color            = Color(0.918, 0.702, 0.031, 0.38)
	var fan_bg := Panel.new()
	fan_bg.add_theme_stylebox_override("panel", sb_bg)
	fan_bg.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	fan_bg.layout_mode   = 1
	fan_bg.anchor_right  = 1.0
	fan_bg.anchor_bottom = 1.0
	bottom_anchor.add_child(fan_bg)

	# Gloss-Schicht: leicht hellerer innerer Bereich simuliert Tiefe/Glanz
	var sb_gloss := StyleBoxFlat.new()
	sb_gloss.bg_color                = Color(0.22, 0.38, 0.65, 0.045)
	sb_gloss.corner_radius_top_right = 140
	var gloss := Panel.new()
	gloss.add_theme_stylebox_override("panel", sb_gloss)
	gloss.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	gloss.layout_mode   = 1
	gloss.anchor_right  = 1.0
	gloss.anchor_bottom = 1.0
	bottom_anchor.add_child(gloss)

	# Trennringe – Panel-Trick: size=(R,R), pos=(0, BB_FAN_SIZE-R) → corner arc am fan origin
	for sep_r: int in [75, int((BB_RING1_RADIUS + BB_RING2_RADIUS) * 0.5)]:
		var sb_sep := StyleBoxFlat.new()
		sb_sep.bg_color                = Color(0, 0, 0, 0)
		sb_sep.corner_radius_top_right = sep_r
		sb_sep.border_width_top        = 1
		sb_sep.border_width_right      = 1
		sb_sep.border_color            = Color(0.918, 0.702, 0.031, 0.22)
		var ring_sep := Panel.new()
		ring_sep.add_theme_stylebox_override("panel", sb_sep)
		ring_sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ring_sep.layout_mode  = 0
		ring_sep.size         = Vector2(sep_r, sep_r)
		ring_sep.position     = Vector2(0.0, BB_FAN_SIZE - sep_r)
		bottom_anchor.add_child(ring_sep)

	# Buttons auf Kreisbögen – origin ist die untere linke Ecke des Anchors
	var origin := Vector2(0.0, BB_FAN_SIZE)
	for i in _bb_btn_defs.size():
		var ring       := 0 if i < BB_RING1_COUNT else 1
		var ring_idx   := i - (BB_RING1_COUNT if ring == 1 else 0)
		var ring_total := BB_RING1_COUNT if ring == 0 else (_bb_btn_defs.size() - BB_RING1_COUNT)
		var radius     := BB_RING1_RADIUS if ring == 0 else BB_RING2_RADIUS
		var t          := float(ring_idx) / float(max(ring_total - 1, 1))
		var angle_rad  := deg_to_rad(lerp(BB_ANGLE_MIN, BB_ANGLE_MAX, t))
		var center     := origin + Vector2(cos(angle_rad) * radius, -sin(angle_rad) * radius)
		var btn        := _make_fan_btn(i)
		btn.layout_mode = 0
		btn.position    = center - Vector2(BB_BTN_SIZE, BB_BTN_SIZE) * 0.5
		bottom_anchor.add_child(btn)
		_bottom_buttons.append(btn)

	# Modus-Indikator: goldener Kreis in der Ecke zeigt aktiven Modus
	_fan_mode_btn             = _make_mode_indicator()
	_fan_mode_btn.layout_mode = 0
	_fan_mode_btn.position    = Vector2(5.0, BB_FAN_SIZE - 52.0)
	bottom_anchor.add_child(_fan_mode_btn)

	# Geteiltes Tooltip-Panel
	_tooltip_panel = PanelContainer.new()
	_tooltip_panel.visible = false
	var sb_tip := StyleBoxFlat.new()
	sb_tip.bg_color                   = Color(0.04, 0.06, 0.10, 0.96)
	sb_tip.corner_radius_top_left     = 6
	sb_tip.corner_radius_top_right    = 6
	sb_tip.corner_radius_bottom_left  = 6
	sb_tip.corner_radius_bottom_right = 6
	sb_tip.border_width_top           = 1
	sb_tip.border_color               = Color(0.918, 0.702, 0.031, 0.30)
	sb_tip.content_margin_left        = 14.0
	sb_tip.content_margin_right       = 14.0
	sb_tip.content_margin_top         = 8.0
	sb_tip.content_margin_bottom      = 8.0
	_tooltip_panel.add_theme_stylebox_override("panel", sb_tip)
	_tooltip_lbl = Label.new()
	_tooltip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip_lbl.add_theme_font_size_override("font_size", 14)
	_tooltip_lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
	_tooltip_panel.add_child(_tooltip_lbl)
	($HUD as CanvasLayer).add_child(_tooltip_panel)


func _make_fan_stylebox(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = bg
	sb.corner_radius_top_left     = 23
	sb.corner_radius_top_right    = 23
	sb.corner_radius_bottom_left  = 23
	sb.corner_radius_bottom_right = 23
	sb.border_width_left          = 1
	sb.border_width_right         = 1
	sb.border_width_top           = 1
	sb.border_width_bottom        = 1
	sb.border_color               = border
	sb.shadow_color               = Color(0.0, 0.0, 0.0, 0.55)
	sb.shadow_size                = 4
	sb.shadow_offset              = Vector2(0.0, 2.0)
	return sb


## Kompakter Fan-Button (nur Icon, kein Label – Label erscheint im Tooltip).
func _make_fan_btn(idx: int) -> Button:
	var def := _bb_btn_defs[idx]

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(BB_BTN_SIZE, BB_BTN_SIZE)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal",   _bb_sb_normal)
	btn.add_theme_stylebox_override("hover",    _bb_sb_hover)
	btn.add_theme_stylebox_override("pressed",  _bb_sb_active)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", _bb_sb_normal)

	# Icon-Node (SVG oder Text-Fallback) – Referenz behalten zum Dimmen bei Lock
	var icon_node: Control
	# Icons fix zentriert positionieren (nicht auf volle Buttongröße skaliert)
	const ICON_D := 22.0
	const ICON_OFF := (BB_BTN_SIZE - ICON_D) * 0.5
	var icon_path: String = def.get("icon_path", "")
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var tex := TextureRect.new()
		tex.texture             = load(icon_path)
		tex.expand_mode         = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode        = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.layout_mode         = 0
		tex.size                = Vector2(ICON_D, ICON_D)
		tex.position            = Vector2(ICON_OFF, ICON_OFF)
		tex.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		btn.add_child(tex)
		icon_node = tex
	else:
		var lbl := Label.new()
		lbl.text                 = def.get("icon", "?")
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1))
		lbl.layout_mode  = 0
		lbl.size         = Vector2(BB_BTN_SIZE, BB_BTN_SIZE)
		lbl.position     = Vector2(0, 0)
		lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lbl)
		icon_node = lbl

	# Dot-Indikator oben rechts
	var dot_color: Color = def.get("dot_color", Color.TRANSPARENT)
	if dot_color.a > 0.0:
		var dot_sb := StyleBoxFlat.new()
		dot_sb.bg_color                   = dot_color
		dot_sb.corner_radius_top_left     = 4
		dot_sb.corner_radius_top_right    = 4
		dot_sb.corner_radius_bottom_left  = 4
		dot_sb.corner_radius_bottom_right = 4
		var dot := Panel.new()
		dot.add_theme_stylebox_override("panel", dot_sb)
		dot.custom_minimum_size = Vector2(8, 8)
		dot.layout_mode  = 1
		dot.anchor_left   = 1.0
		dot.anchor_right  = 1.0
		dot.offset_left   = -12.0
		dot.offset_right  = -4.0
		dot.offset_top    = 4.0
		dot.offset_bottom = 12.0
		dot.mouse_filter  = Control.MOUSE_FILTER_IGNORE
		btn.add_child(dot)

	# Gesperrt: nur Icon dimmen, Schloss-Emoji bleibt voll sichtbar
	if def.get("locked", false):
		btn.disabled          = true
		icon_node.modulate    = Color(1, 1, 1, 0.35)
		var lock_lbl          := Label.new()
		lock_lbl.text                = "🔒"
		lock_lbl.layout_mode         = 1
		lock_lbl.anchor_right        = 1.0
		lock_lbl.anchor_bottom       = 1.0
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment  = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 14)
		lock_lbl.mouse_filter        = Control.MOUSE_FILTER_IGNORE
		btn.add_child(lock_lbl)

	btn.pressed.connect(func(): _on_bottom_button(idx))
	btn.mouse_entered.connect(func(): _show_tooltip("%s · %s" % [def["key"], def["label"]], btn))
	btn.mouse_exited.connect(func():  _hide_tooltip())

	return btn


## Goldener Kreis-Button in der Ecke – zeigt den aktiven Modus an.
func _make_mode_indicator() -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(46, 46)
	btn.focus_mode          = Control.FOCUS_NONE
	btn.disabled            = true

	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.07, 0.13, 0.96)
	sb.corner_radius_top_left     = 23
	sb.corner_radius_top_right    = 23
	sb.corner_radius_bottom_left  = 23
	sb.corner_radius_bottom_right = 23
	sb.border_width_left          = 2
	sb.border_width_right         = 2
	sb.border_width_top           = 2
	sb.border_width_bottom        = 2
	sb.border_color               = Color(0.918, 0.702, 0.031, 0.85)
	btn.add_theme_stylebox_override("normal",   sb)
	btn.add_theme_stylebox_override("hover",    sb)
	btn.add_theme_stylebox_override("pressed",  sb)
	btn.add_theme_stylebox_override("focus",    StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("disabled", sb)

	var lbl := Label.new()
	lbl.text                 = "◆"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 14)
	lbl.add_theme_color_override("font_color", Color(0.918, 0.702, 0.031, 0.75))
	lbl.layout_mode  = 1
	lbl.anchor_right  = 1.0
	lbl.anchor_bottom = 1.0
	lbl.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	btn.add_child(lbl)

	return btn


## Button als aktiv/inaktiv markieren – überschreibt normal+hover StyleBox
func _set_btn_active(idx: int) -> void:
	for i in _bottom_buttons.size():
		var b: Button = _bottom_buttons[i]
		if i == idx:
			b.add_theme_stylebox_override("normal", _bb_sb_active)
			b.add_theme_stylebox_override("hover",  _bb_sb_active)
		else:
			b.add_theme_stylebox_override("normal", _bb_sb_normal)
			b.add_theme_stylebox_override("hover",  _bb_sb_hover)
	_active_btn_idx = idx


## Tooltip über dem gegebenen Button anzeigen (nach einem Frame wenn Größe bekannt)
func _show_tooltip(text: String, anchor_btn: Button) -> void:
	_tooltip_lbl.text = text
	_tooltip_panel.modulate = Color(1, 1, 1, 0)
	_tooltip_panel.visible  = true
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(_tooltip_panel) or not _tooltip_panel.visible:
		return
	if not is_instance_valid(anchor_btn):
		return
	var pos := anchor_btn.global_position
	_tooltip_panel.position = Vector2(
		pos.x + anchor_btn.size.x * 0.5 - _tooltip_panel.size.x * 0.5,
		pos.y - _tooltip_panel.size.y - 8.0
	)
	_tooltip_panel.modulate = Color(1, 1, 1, 1)


func _hide_tooltip() -> void:
	_tooltip_panel.visible = false


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


func _process(delta: float) -> void:
	_tick_game_clock(delta)


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
	var day: int = int(_hotel.get("day", 1)) + 1
	_hotel["day"] = day
	stat_day_val.text = str(day)
	_save_progress(360)


func _save_progress(game_time_min: int) -> void:
	var hotel_id: int = _hotel.get("id", -1)
	if hotel_id < 0:
		return
	SaveManager.update_hotel(hotel_id, {
		"day":       _hotel.get("day", 1),
		"money":     _hotel.get("money", 0),
		"game_time": game_time_min,
	})


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		_save_progress(_game_hour * 60 + _game_minute)


func _update_time_label() -> void:
	time_lbl.text = "%02d:%02d" % [_game_hour, _game_minute]


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			if ke.keycode == KEY_S and ke.alt_pressed:
				_on_bottom_button(6)  # Einstellungen
			else:
				_handle_hotkey(ke.keycode)


func _handle_hotkey(keycode: int) -> void:
	match keycode:
		KEY_ESCAPE: _on_exit_pressed()
		KEY_F2:     _on_bottom_button(0)  # Bauen
		KEY_F3:     _on_bottom_button(1)  # Rezeption
		KEY_F4:     _on_bottom_button(2)  # Personalverwaltung (gesperrt)
		KEY_F5:     _on_bottom_button(3)  # unbelegt (gesperrt)
		KEY_F6:     _on_bottom_button(4)  # Forschung (gesperrt)
		KEY_F7:     _on_bottom_button(5)  # SIM-Browser


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


## BottomBar-Button-Handler – aktiven Button toggeln, Submenü öffnen/schließen
func _on_bottom_button(idx: int) -> void:
	# Gesperrte Features ignorieren (auch wenn per Tastenkürzel ausgelöst)
	if idx < _bb_btn_defs.size() and _bb_btn_defs[idx].get("locked", false):
		return

	# Bestehendes Submenü schliessen
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null

	# Toggle: nochmal klicken → deaktivieren
	if _active_submenu_idx == idx:
		_set_btn_active(-1)
		_active_submenu_idx = -1
		return

	_set_btn_active(idx)
	_active_submenu_idx = idx

	# Submenü-Panel über dem Button – Inhalt folgt mit Feature-Implementierung
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color                   = Color(0.04, 0.06, 0.10, 0.95)
	sb.corner_radius_top_left     = 10
	sb.corner_radius_top_right    = 10
	sb.corner_radius_bottom_left  = 10
	sb.corner_radius_bottom_right = 10
	sb.border_width_top    = 1
	sb.border_width_left   = 1
	sb.border_width_right  = 1
	sb.border_width_bottom = 1
	sb.border_color        = Color(0.918, 0.702, 0.031, 0.30)
	sb.content_margin_left   = 16.0
	sb.content_margin_right  = 16.0
	sb.content_margin_top    = 12.0
	sb.content_margin_bottom = 12.0
	panel.add_theme_stylebox_override("panel", sb)

	var lbl := Label.new()
	lbl.text = GameState.T("ingame.submenu.coming_soon")
	lbl.add_theme_font_size_override("font_size", 13)
	lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55, 1))
	panel.add_child(lbl)

	($HUD as CanvasLayer).add_child(panel)
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	await get_tree().process_frame
	if not is_instance_valid(self) or not is_instance_valid(panel):
		return
	if idx >= _bottom_buttons.size() or not is_instance_valid(_bottom_buttons[idx]):
		panel.queue_free()
		return
	# Submenü erscheint rechts neben dem Button (Fächer ist in der linken Ecke)
	var btn_pos  := _bottom_buttons[idx].global_position
	var btn_size := _bottom_buttons[idx].size
	panel.position = Vector2(btn_pos.x + btn_size.x + 12.0, btn_pos.y)
	_active_submenu = panel


func _on_exit_pressed() -> void:
	if _active_submenu != null:
		_active_submenu.queue_free()
		_active_submenu = null
		_set_btn_active(-1)
		_active_submenu_idx = -1
		return
	_save_progress(_game_hour * 60 + _game_minute)
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
