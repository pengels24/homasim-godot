extends Node

signal sig_order_placed(order_id: String)
signal sig_order_ready(order_id: String)
signal sig_order_served(order_id: String, guest_id: String, recipe_id: String)

# Struktur: order_id -> { guest_id, recipe_id, restaurant_id, status (pending|cooking|ready|served), kitchen_id }
var active_orders: Dictionary = {}

func place_order(guest_id: String, recipe_id: String, restaurant_id: String) -> String:
	var order_id = str(Time.get_unix_time_from_system()) + '_' + guest_id
	active_orders[order_id] = {
		'guest_id': guest_id,
		'recipe_id': recipe_id,
		'restaurant_id': restaurant_id,
		'status': 'pending',
		'kitchen_id': ''
	}
	sig_order_placed.emit(order_id)
	return order_id

func claim_order(order_id: String, kitchen_id: String) -> void:
	if active_orders.has(order_id):
		active_orders[order_id]['status'] = 'cooking'
		active_orders[order_id]['kitchen_id'] = kitchen_id

func finish_order(order_id: String) -> void:
	if active_orders.has(order_id):
		active_orders[order_id]['status'] = 'ready'
		sig_order_ready.emit(order_id)

func mark_order_serving(order_id: String) -> void:
	if active_orders.has(order_id):
		active_orders[order_id]['status'] = 'serving'

func serve_order(order_id: String) -> void:
	if active_orders.has(order_id):
		active_orders[order_id]['status'] = 'served'
		var guest_id = active_orders[order_id]['guest_id']
		var recipe_id = active_orders[order_id]['recipe_id']
		sig_order_served.emit(order_id, guest_id, recipe_id)
		active_orders.erase(order_id)

func cancel_order(order_id: String) -> void:
	if active_orders.has(order_id):
		active_orders.erase(order_id)
		print('[GastroManager] Order ', order_id, ' wurde storniert!')

func get_pending_orders() -> Array:
	var pending = []
	for order_id in active_orders.keys():
		if active_orders[order_id]['status'] == 'pending':
			pending.append(order_id)
	return pending

func has_active_orders_for_room(room_id: String) -> bool:
	for order_id in active_orders.keys():
		var order = active_orders[order_id]
		if order.get('restaurant_id', '') == room_id or order.get('kitchen_id', '') == room_id:
			if order.get('status', '') != 'served':
				return true
	return false

## Prüft ob es noch Bestellungen gibt, die GEKOCHT werden müssen (pending/cooking).
## Wird für den Überstunden-Check des Kochs verwendet.
## 'ready' und 'serving' sind Kellner-Aufgaben, die den Koch nicht aufhalten sollen.
func has_cookable_orders_for_room(kitchen_id: String) -> bool:
	for order_id in active_orders.keys():
		var order = active_orders[order_id]
		if order.get('kitchen_id', '') == kitchen_id or order.get('status', '') == 'pending':
			var status = order.get('status', '')
			if status == 'pending' or status == 'cooking':
				return true
	return false

func get_ready_orders_for_restaurant(restaurant_id: String) -> Array:
	var ready_orders_list = []
	for order_id in active_orders.keys():
		var order = active_orders[order_id]
		if order['status'] == 'ready' and order['restaurant_id'] == restaurant_id:
			ready_orders_list.append(order_id)
	return ready_orders_list

## Versucht eine Bestellung für einen Gast in einem Gastro-Raum aufzugeben.
## Gibt { "ordered": bool, "solo_mode": bool } zurück.
## "ordered" = true  → Bestellung erfolgreich, Gast wartet auf Essen (WAITING_FOR_FOOD)
## "solo_mode" = true → Kein Kellner, aber Barkeeper ist da → Gast geht in EATING (Solo-Drink)
## Beide false → Raum nicht funktional, Gast soll abbrechen
func try_gastro_order(guest_id: String, spending_budget: int, saturation: int, room_node: Node) -> Dictionary:
	var result := {"ordered": false, "solo_mode": false}
	if not is_instance_valid(room_node):
		return result

	# Ist der Raum voll funktional (Küche + Kellner)?
	var is_func := true
	if room_node.has_method("is_functional"):
		is_func = room_node.is_functional()

	print("[GASTRO TRACE] try_gastro_order: room_node.is_functional() = ", is_func)

	if not is_func:
		# Solo-Modus prüfen (z.B. Bar ohne Waiter, aber Barkeeper ist da)
		if room_node.has_method("can_serve_solo") and room_node.can_serve_solo():
			result["solo_mode"] = true
			print("[GASTRO TRACE] try_gastro_order: is_func is false, but can_serve_solo is true.")
		else:
			print("[GASTRO TRACE] try_gastro_order: is_func is false, and can_serve_solo is false. Aborting order.")
		return result

	# Raum ist funktional → Bestellung aufgeben
	if room_node.has_method("place_order_for_seat"):
		var missing_sat: int = int(max(0, 100 - saturation))
		var ordered: bool = room_node.place_order_for_seat(guest_id, spending_budget, missing_sat)
		result["ordered"] = ordered
	return result


# =============================================================================
# ANG-314: Persistenz-Methoden
# =============================================================================

## Bestellungen werden bewusst NICHT persistiert.
## Grund: Gäste werden nach Reload nicht in Gastro-States restored → Bestellungen wären
## tote Leichen die Staff-Actors nach Schichtende im Raum festhalten würden.
func to_save_dict() -> Dictionary:
	return {"active_orders": {}}


## Lädt aktive Bestellungen aus dem Save-Dict.
## ANG-314 FIX: Bestellungen werden NICHT wiederhergestellt.
## Grund: Gäste werden nach einem Reload nicht in ihren Gastro-States restored
## (kein WAITING_FOR_FOOD, kein EATING). Offene Bestellungen würden als "tote Leichen"
## in active_orders verbleiben und via has_active_orders_for_room() verhindern,
## dass Koch/Barkeeper nach Schichtende in den Personalraum gehen.
func load_from_dict(_data: Dictionary) -> void:
	active_orders.clear()
	# Bestellungen werden bewusst nicht wiederhergestellt.
