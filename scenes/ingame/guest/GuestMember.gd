## Eine Einzelperson innerhalb einer GuestParty.
## Eigener Name, Rolle, und (später) eigener Sprite auf der Karte.
class_name GuestMember

var id:       String = ""
var party_id: String = ""
var name:     String = ""
var role:     String = "primary"   # "primary" | "partner" | "child"
var sprite:   Node2D = null        # animierter Charakter, wird bei Spawn gesetzt


# =============================================================================
func _init(p_id: String, p_party_id: String, p_name: String, p_role: String) -> void:
	id       = p_id
	party_id = p_party_id
	name     = p_name
	role     = p_role


# =============================================================================
func is_primary() -> bool:
	return role == "primary"


# =============================================================================
func to_dict() -> Dictionary:
	return {"id": id, "party_id": party_id, "name": name, "role": role}


# =============================================================================
static func from_dict(d: Dictionary) -> GuestMember:
	return GuestMember.new(
		d.get("id",       ""),
		d.get("party_id", ""),
		d.get("name",     ""),
		d.get("role",     "primary"),
	)
