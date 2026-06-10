## Eine Hotel-Buchung: ein Zimmer, eine Rechnung, eine Patience-Bar.
## Enthält 1–5 GuestMember je nach Gast-Typ.
class_name GuestParty

var id:            String = ""
var type:          String = ""        # Schlüssel aus GuestDefinitions.ALL
var members:       Array  = []        # Array[GuestMember]
var room_id:       String = ""        # leer bis Check-in (= room_number)
var stay_days:     int    = 1
var base_price:    float  = 0.0
var satisfaction:  float  = 1.0       # 0.0–1.0
var patience:      float  = 1.0       # 0.0–1.0; startet bei 1.0
var arrived_day:   int    = 1
var arrived_time:  int    = 0         # Spielminuten
var state:         String = "waiting" # "waiting"|"active"|"checkout"|"gone"
var checkout_days: int    = 0         # Tage die der Gast bereits in checkout-Spalte wartet
var has_been_seen: bool = false
var pays_surcharge: bool = false


# =============================================================================
func _init(p_id: String, p_type: String) -> void:
	id   = p_id
	type = p_type


# =============================================================================
func get_primary() -> GuestMember:
	for m: GuestMember in members:
		if m.is_primary():
			return m
	return members[0] if not members.is_empty() else null


# =============================================================================
func get_display_name() -> String:
	var primary := get_primary()
	return primary.name if primary != null else "?"


# =============================================================================
func get_type_def() -> Dictionary:
	return GuestDefinitions.ALL.get(type, {})


# =============================================================================
func get_type_name() -> String:
	return GuestDefinitions.ALL.get(type, {}).get("name", type)


# =============================================================================
func to_dict() -> Dictionary:
	var member_arr: Array = []
	for m: GuestMember in members:
		member_arr.append(m.to_dict())
	return {
		"id":            id,
		"type":          type,
		"members":       member_arr,
		"room_id":       room_id,
		"stay_days":     stay_days,
		"base_price":    base_price,
		"satisfaction":  satisfaction,
		"patience":      patience,
		"arrived_day":   arrived_day,
		"arrived_time":  arrived_time,
		"state":         state,
		"checkout_days": checkout_days,
		"has_been_seen": has_been_seen,
		"pays_surcharge": pays_surcharge,
	}


# =============================================================================
static func from_dict(d: Dictionary) -> GuestParty:
	var p := GuestParty.new(d.get("id", ""), d.get("type", ""))
	p.room_id       = d.get("room_id",       "")
	p.stay_days     = d.get("stay_days",     1)
	p.base_price    = d.get("base_price",    0.0)
	p.satisfaction  = d.get("satisfaction",  1.0)
	p.patience      = d.get("patience",      1.0)
	p.arrived_day   = d.get("arrived_day",   1)
	p.arrived_time  = d.get("arrived_time",  0)
	p.state         = d.get("state",         "waiting")
	p.checkout_days = d.get("checkout_days", 0)
	p.has_been_seen = d.get("has_been_seen", false)
	p.pays_surcharge = d.get("pays_surcharge", false)

	for md: Dictionary in d.get("members", []):
		p.members.append(GuestMember.from_dict(md))
	return p
