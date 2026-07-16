extends Node

signal sig_order_placed(order_id: String)
signal sig_order_ready(order_id: String)
signal sig_order_served(order_id: String)

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

func serve_order(order_id: String) -> void:
	if active_orders.has(order_id):
		active_orders[order_id]['status'] = 'served'
		sig_order_served.emit(order_id)
		active_orders.erase(order_id)

func get_pending_orders() -> Array:
	var pending = []
	for order_id in active_orders.keys():
		if active_orders[order_id]['status'] == 'pending':
			pending.append(order_id)
	return pending

func get_ready_orders_for_restaurant(restaurant_id: String) -> Array:
	var ready = []
	for order_id in active_orders.keys():
		var order = active_orders[order_id]
		if order['status'] == 'ready' and order['restaurant_id'] == restaurant_id:
			ready.append(order_id)
	return ready
