extends SceneTree

func _init() -> void:
	var blockers = []
	var b1 = ReferenceRect.new()
	b1.position = Vector2(1, 1)
	b1.size = Vector2(3, 30) # NavBlockerBackLeft (1,1 to 4,31)
	blockers.append(b1)
	
	var b2 = ReferenceRect.new()
	b2.position = Vector2(7, 7)
	b2.size = Vector2(5, 24) # NavBlockerCounter2 (7,7 to 12,31)
	blockers.append(b2)
	
	var b3 = ReferenceRect.new()
	b3.position = Vector2(7, 7)
	b3.size = Vector2(15, 4) # NavBlockerCounter1 (7,7 to 22,11)
	blockers.append(b3)
	
	var b4 = ReferenceRect.new()
	b4.position = Vector2(1, 1)
	b4.size = Vector2(18, 3) # NavBlockerBackTop (1,1 to 19,4)
	blockers.append(b4)
	
	var p = Vector2(6, 6)
	var is_blocked = false
	
	for b in blockers:
		var p_local = b.get_global_transform().affine_inverse() * p
		if Rect2(Vector2.ZERO, b.size).has_point(p_local):
			print("Blocked by: ", b.size, " at ", b.position)
			is_blocked = true
			break
			
	print("Point (6,6) is_blocked: ", is_blocked)
	
	p = Vector2(6, 10)
	is_blocked = false
	for b in blockers:
		var p_local = b.get_global_transform().affine_inverse() * p
		if Rect2(Vector2.ZERO, b.size).has_point(p_local):
			print("Blocked by: ", b.size, " at ", b.position)
			is_blocked = true
			break
	print("Point (6,10) is_blocked: ", is_blocked)
	
	quit()
