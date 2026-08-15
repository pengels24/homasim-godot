class_name GuestMember

const HAIR_COLORS: Array[String] = [
  "e8c366", # Blond
  "5c3a21", # Braun
  "1c1c1c", # Schwarz
  "a33f27", # Rot
  "b0b0b0"  # Grau
]

const SHIRT_COLORS: Array[String] = [
  "cc4747", # Rot
  "4782cc", # Blau
  "47cc5e", # Grün
  "e0d64c", # Gelb
  "8c47cc", # Lila
  "db8237", # Orange
  "ffffff", # Weiß
  "3b3b3b"  # Dunkelgrau
]

var id:       String = ""
var party_id: String = ""
var name:     String = ""
var role:     String = "primary"   # "primary" | "partner" | "child"
var gender:   String = "male"      # "male" | "female"
var is_child: bool   = false
var sprite:   Node2D = null        # animierter Charakter, wird bei Spawn gesetzt

var hair_color: String = ""
var shirt_color: String = ""
var speed_offset: float = 0.0
var daily_budget: int = 0    # Einmalig bei Check-in gewürfelt
var spending_budget: int = 0 # Aktuelles Tagesbudget (jeden Morgen reset)
var saturation: int = 100    # Sättigung / Hunger (100 = satt, <30 = hungrig)
var thirst: int = 100        # Durst
var energy: int = 100        # Energie / Schlafbedarf
var fun: int = 100           # Spaß / Erholung


# =============================================================================
func _init(p_id: String, p_party_id: String, p_name: String, p_role: String, p_gender: String = "male", p_is_child: bool = false, p_hair: String = "", p_shirt: String = "", p_speed: float = -999.0) -> void:
	id       = p_id
	party_id = p_party_id
	name     = p_name
	role     = p_role
	gender   = p_gender
	is_child = p_is_child
	
	hair_color = p_hair if p_hair != "" else HAIR_COLORS.pick_random()
	shirt_color = p_shirt if p_shirt != "" else SHIRT_COLORS.pick_random()
	speed_offset = p_speed if p_speed != -999.0 else randf_range(-10.0, 10.0)
	
	saturation = randi_range(40, 100)


# =============================================================================
func is_primary() -> bool:
	return role == "primary"


# =============================================================================
func to_dict() -> Dictionary:
	return {
		"id": id,
		"party_id": party_id,
		"name": name,
		"role": role,
		"gender": gender,
		"is_child": is_child,
		"hair_color": hair_color,
		"shirt_color": shirt_color,
		"speed_offset": speed_offset,
		"daily_budget": daily_budget,
		"spending_budget": spending_budget,
		"saturation": saturation,
	}


# =============================================================================
static func from_dict(d: Dictionary) -> GuestMember:
	var m := GuestMember.new(
		d.get("id",       ""),
		d.get("party_id", ""),
		d.get("name",     ""),
		d.get("role",     "primary"),
		d.get("gender",   "male"),
		d.get("is_child", false),
		d.get("hair_color", ""),
		d.get("shirt_color", ""),
		d.get("speed_offset", -999.0)
	)
	m.daily_budget    = int(d.get("daily_budget",    20))
	m.spending_budget = int(d.get("spending_budget", m.daily_budget))
	m.saturation      = int(d.get("saturation",      100))
	return m



# ## Eine Einzelperson innerhalb einer GuestParty.
# ## Eigener Name, Rolle, und (später) eigener Sprite auf der Karte.
# class_name GuestMember

# var id:       String = ""
# var party_id: String = ""
# var name:     String = ""
# var role:     String = "primary"   # "primary" | "partner" | "child"
# var sprite:   Node2D = null        # animierter Charakter, wird bei Spawn gesetzt


# # =============================================================================
# func _init(p_id: String, p_party_id: String, p_name: String, p_role: String) -> void:
# 	id       = p_id
# 	party_id = p_party_id
# 	name     = p_name
# 	role     = p_role


# # =============================================================================
# func is_primary() -> bool:
# 	return role == "primary"


# # =============================================================================
# func to_dict() -> Dictionary:
# 	return {"id": id, "party_id": party_id, "name": name, "role": role}


# # =============================================================================
# static func from_dict(d: Dictionary) -> GuestMember:
# 	return GuestMember.new(
# 		d.get("id",       ""),
# 		d.get("party_id", ""),
# 		d.get("name",     ""),
# 		d.get("role",     "primary"),
# 	)
