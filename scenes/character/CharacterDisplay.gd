extends Control

## ANG-148 – Spielfigur-Vorschau: geometrische Placeholder-Shapes
## Außenschnittstelle bleibt gleich wenn später echte Sprites kommen.

var gender  := "m"
var skin    := Color(0.95, 0.82, 0.70)
var hair    := Color(0.45, 0.30, 0.15)
var outfit  := Color(0.12, 0.12, 0.16)

# Feste Farben für Gesichts-Details
const C_DARK    := Color(0.15, 0.10, 0.08)
const C_WHITE   := Color(0.95, 0.95, 0.95)
const C_SHADOW  := Color(0.0,  0.0,  0.0, 0.18)


func update_appearance(p_gender: String, p_skin: Color, p_hair: Color, p_outfit: Color) -> void:
	gender = p_gender
	skin   = p_skin
	hair   = p_hair
	outfit = p_outfit
	queue_redraw()


func _draw() -> void:
	var cx := size.x / 2.0
	var is_female := gender == "w"

	# ── Haar (hinten) ────────────────────────────────────────────────────────
	var is_diverse  := gender == "d"
	var hair_w      := 74.0
	var hair_top    := 18.0
	var hair_back_h := 34.0 if is_female else (28.0 if is_diverse else 22.0)

	draw_rect(Rect2(cx - hair_w / 2.0, hair_top, hair_w, hair_back_h), hair)

	# Seitenhaar: lang bei Frauen, mittel bei Divers, kurz bei Männern
	var side_hair_h := 42.0 if is_female else (26.0 if is_diverse else 0.0)
	if side_hair_h > 0.0:
		draw_rect(Rect2(cx - hair_w / 2.0, hair_top + hair_back_h, 10.0, side_hair_h), hair)
		draw_rect(Rect2(cx + hair_w / 2.0 - 10.0, hair_top + hair_back_h, 10.0, side_hair_h), hair)

	# ── Kopf ─────────────────────────────────────────────────────────────────
	var head_w := 68.0
	var head_h := 74.0
	var head_x := cx - head_w / 2.0
	var head_y := 28.0

	draw_rect(Rect2(head_x, head_y, head_w, head_h), skin)

	# Leichter Schatten auf Stirn
	draw_rect(Rect2(head_x, head_y, head_w, 6.0), C_SHADOW)

	# ── Haar (vorne / Pony) ───────────────────────────────────────────────────
	var pony_h := 12.0 if is_female else 8.0
	draw_rect(Rect2(head_x - 2.0, head_y, head_w + 4.0, pony_h), hair)

	# Seitensträhnen (bedecken Kopfrand)
	draw_rect(Rect2(head_x - 4.0, head_y + pony_h, 8.0, 28.0), hair)
	draw_rect(Rect2(head_x + head_w - 4.0, head_y + pony_h, 8.0, 28.0), hair)

	# ── Augen ─────────────────────────────────────────────────────────────────
	var eye_y   := head_y + 30.0
	var eye_w   := 12.0
	var eye_h   := 10.0
	var eye_gap := 16.0

	# Augenweiß
	draw_rect(Rect2(cx - eye_gap - eye_w, eye_y, eye_w, eye_h), C_WHITE)
	draw_rect(Rect2(cx + eye_gap,         eye_y, eye_w, eye_h), C_WHITE)
	# Iris
	draw_rect(Rect2(cx - eye_gap - eye_w + 3.0, eye_y + 1.0, 6.0, 8.0), C_DARK)
	draw_rect(Rect2(cx + eye_gap + 3.0,         eye_y + 1.0, 6.0, 8.0), C_DARK)

	# ── Nase ──────────────────────────────────────────────────────────────────
	var nose_color := skin.darkened(0.18)
	draw_rect(Rect2(cx - 3.0, head_y + 48.0, 6.0, 8.0), nose_color)

	# ── Mund ──────────────────────────────────────────────────────────────────
	var mouth_color := skin.darkened(0.30)
	draw_rect(Rect2(cx - 10.0, head_y + 60.0, 20.0, 5.0), mouth_color)

	# ── Hals ──────────────────────────────────────────────────────────────────
	var neck_w := 22.0
	var neck_y := head_y + head_h
	draw_rect(Rect2(cx - neck_w / 2.0, neck_y, neck_w, 18.0), skin)

	# ── Schultern + Torso ─────────────────────────────────────────────────────
	var shoulder_w := 140.0 if not is_female and not is_diverse else (118.0 if is_female else 128.0)
	var torso_w    := 96.0  if not is_female and not is_diverse else (82.0  if is_female else 88.0)
	var torso_y    := neck_y + 14.0

	# Schulter-Balken
	draw_rect(Rect2(cx - shoulder_w / 2.0, torso_y, shoulder_w, 22.0), outfit)
	# Torso
	draw_rect(Rect2(cx - torso_w / 2.0, torso_y + 18.0, torso_w, 72.0), outfit)

	# Outfit-Detail: dünne Linie als Kragen
	var collar_color := outfit.lightened(0.25)
	draw_rect(Rect2(cx - 14.0, torso_y + 2.0, 28.0, 4.0), collar_color)

	# Hände (Hautfarbe, unten an den Schultern)
	var hand_y := torso_y + 22.0
	draw_rect(Rect2(cx - shoulder_w / 2.0 - 2.0, hand_y, 14.0, 18.0), skin)
	draw_rect(Rect2(cx + shoulder_w / 2.0 - 12.0, hand_y, 14.0, 18.0), skin)
