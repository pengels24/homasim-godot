extends Control
class_name CharacterDisplay
## ANG-148 – Spielfigur-Vorschau als wiederverwendbare Szene.
## Struktur liegt in CharacterDisplay.tscn; dieses Script setzt nur Farben
## und passt bei Geschlechtswechsel einige Node-Größen an.

const CX           := 90.0
const COLOR_GOLD   := Color(0.918, 0.702, 0.031, 1.0)

@onready var _hair_back:       Panel = $HairBack
@onready var _ear_left:        Panel = $EarLeft
@onready var _ear_right:       Panel = $EarRight
@onready var _side_hair_left:  Panel = $SideHairLeft
@onready var _side_hair_right: Panel = $SideHairRight
@onready var _hair_pony:       Panel = $HairPony
@onready var _strand_left:     Panel = $StrandLeft
@onready var _strand_right:    Panel = $StrandRight
@onready var _brow_left:       Panel = $BrowLeft
@onready var _brow_right:      Panel = $BrowRight
@onready var _head:            Panel = $Head
@onready var _nose:            Panel = $Nose
@onready var _mouth:           Panel = $Mouth
@onready var _neck:            Panel = $Neck
@onready var _shoulders:       Panel = $Shoulders
@onready var _torso:           Panel = $Torso
@onready var _belt:            Panel = $Belt
@onready var _collar:          Panel = $Collar
@onready var _hand_left:       Panel = $HandLeft
@onready var _hand_right:      Panel = $HandRight


# ── Öffentliche API ───────────────────────────────────────────────────────────

func update_appearance(p_gender: String, p_skin: Color, p_hair: Color, p_outfit: Color) -> void:
	_set_color(_hair_back, p_hair)
	_set_color(_ear_left, p_skin)
	_set_color(_ear_right, p_skin)
	_set_color(_side_hair_left, p_hair)
	_set_color(_side_hair_right, p_hair)
	_set_color(_hair_pony, p_hair)
	_set_color(_strand_left, p_hair)
	_set_color(_strand_right, p_hair)
	_set_color(_brow_left, p_hair.darkened(0.20))
	_set_color(_brow_right, p_hair.darkened(0.20))
	_set_color(_head, p_skin)
	_set_color(_nose, p_skin.darkened(0.18))
	_set_color(_mouth, p_skin.darkened(0.30))
	_set_color(_neck, p_skin)
	_set_color(_shoulders, p_outfit)
	_set_color(_torso, p_outfit)
	_set_color(_belt, p_outfit.darkened(0.40))
	_set_color(_collar, p_outfit.lightened(0.25))
	_set_color(_hand_left, p_skin)
	_set_color(_hand_right, p_skin)
	_apply_gender(p_gender)


# ── Privat ────────────────────────────────────────────────────────────────────

func _set_color(node: Panel, color: Color) -> void:
	var sb: StyleBoxFlat
	if not node.has_meta("unique_stylebox"):
		sb = node.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		node.add_theme_stylebox_override("panel", sb)
		node.set_meta("unique_stylebox", true)
	else:
		sb = node.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = color

func _apply_gender(gender: String) -> void:
	var is_female  := gender == "w"
	var is_diverse := gender == "d"

	_hair_back.size.y = 34.0 if is_female else (28.0 if is_diverse else 22.0)

	var side_h := 42.0 if is_female else (26.0 if is_diverse else 0.0)
	_side_hair_left.visible  = side_h > 0.0
	_side_hair_right.visible = side_h > 0.0
	if side_h > 0.0:
		_side_hair_left.size.y      = side_h
		_side_hair_right.size.y     = side_h
		_side_hair_left.position.y  = 18.0 + _hair_back.size.y
		_side_hair_right.position.y = 18.0 + _hair_back.size.y

	_hair_pony.size.y = 12.0 if is_female else 8.0

	var shoulder_w := 140.0 if not is_female and not is_diverse else (118.0 if is_female else 128.0)
	var torso_w    := 96.0  if not is_female and not is_diverse else (82.0  if is_female else 88.0)

	_shoulders.size.x      = shoulder_w
	_shoulders.position.x  = CX - shoulder_w / 2.0
	_torso.size.x          = torso_w
	_torso.position.x      = CX - torso_w / 2.0
	_belt.size.x           = torso_w
	_belt.position.x       = CX - torso_w / 2.0
	_hand_left.position.x  = CX - shoulder_w / 2.0 - 2.0
	_hand_right.position.x = CX + shoulder_w / 2.0 - 12.0
