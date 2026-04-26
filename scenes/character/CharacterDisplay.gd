extends Control
class_name CharacterDisplay
## ANG-148 – Spielfigur-Vorschau als wiederverwendbare Szene.
## Struktur liegt in CharacterDisplay.tscn; dieses Script setzt nur Farben
## und passt bei Geschlechtswechsel einige Node-Größen an.

const CX           := 90.0
const COLOR_GOLD   := Color(0.918, 0.702, 0.031, 1.0)

@onready var _hair_back:       ColorRect = $HairBack
@onready var _ear_left:        ColorRect = $EarLeft
@onready var _ear_right:       ColorRect = $EarRight
@onready var _side_hair_left:  ColorRect = $SideHairLeft
@onready var _side_hair_right: ColorRect = $SideHairRight
@onready var _hair_pony:       ColorRect = $HairPony
@onready var _strand_left:     ColorRect = $StrandLeft
@onready var _strand_right:    ColorRect = $StrandRight
@onready var _brow_left:       ColorRect = $BrowLeft
@onready var _brow_right:      ColorRect = $BrowRight
@onready var _head:            ColorRect = $Head
@onready var _nose:            ColorRect = $Nose
@onready var _mouth:           ColorRect = $Mouth
@onready var _neck:            ColorRect = $Neck
@onready var _shoulders:       ColorRect = $Shoulders
@onready var _torso:           ColorRect = $Torso
@onready var _belt:            ColorRect = $Belt
@onready var _collar:          ColorRect = $Collar
@onready var _hand_left:       ColorRect = $HandLeft
@onready var _hand_right:      ColorRect = $HandRight


# ── Öffentliche API ───────────────────────────────────────────────────────────

func update_appearance(p_gender: String, p_skin: Color, p_hair: Color, p_outfit: Color) -> void:
	_hair_back.color       = p_hair
	_ear_left.color        = p_skin
	_ear_right.color       = p_skin
	_side_hair_left.color  = p_hair
	_side_hair_right.color = p_hair
	_hair_pony.color       = p_hair
	_strand_left.color     = p_hair
	_strand_right.color    = p_hair
	_brow_left.color       = p_hair.darkened(0.20)
	_brow_right.color      = p_hair.darkened(0.20)
	_head.color            = p_skin
	_nose.color            = p_skin.darkened(0.18)
	_mouth.color           = p_skin.darkened(0.30)
	_neck.color            = p_skin
	_shoulders.color       = p_outfit
	_torso.color           = p_outfit
	_belt.color            = p_outfit.darkened(0.40)
	_collar.color          = p_outfit.lightened(0.25)
	_hand_left.color       = p_skin
	_hand_right.color      = p_skin
	_apply_gender(p_gender)


# ── Privat ────────────────────────────────────────────────────────────────────

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
