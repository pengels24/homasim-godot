extends Node2D

const FADE_TIME := 0.5 # Wie lange dauert das Ausblenden in Sekunden?

# var _current_tween: Tween


# =============================================================================
## Wird beim Spawnen aufgerufen, um Aussehen und Größe festzulegen
func setup(member: GuestMember) -> void:
	var is_male: bool = (member.gender == "male")

	# 1. Geschlecht ein/ausblenden
	%Male.visible = is_male
	%Female.visible = not is_male

	# 2. Farben aus dem Member-Objekt lesen
	var chosen_hair: Color = Color(member.hair_color)
	var chosen_shirt: Color = Color(member.shirt_color)

	# 3. Farbeimer auf die richtigen Nodes anwenden
	if is_male:
		%MaleHair.modulate = chosen_hair
		%MaleBody.modulate = chosen_shirt
	else:
		%FemaleHair.modulate = chosen_hair
		%FemaleBody.modulate = chosen_shirt

	# 4. Kinder schrumpfen
	if member.is_child:
		scale = Vector2(0.6, 0.6)
	else:
		scale = Vector2(0.9, 0.9)


# =============================================================================
func walk_path(path: Array[Vector2], door_pos: Vector2, delay: float = 0.0, speed_offset: float = 0.0) -> void:
	var tween = create_tween()

	# 1. Der Entenmarsch-Warte-Trick
	if delay > 0.0:
		visible = false
		tween.tween_interval(delay)
		tween.tween_callback(func(): visible = true)

	# 2. Die Wegpunkte flüssig ablaufen
	var current_pos = global_position
	# Basis-Speed 40.0 plus individueller Offset
	var individual_speed = max(10.0, 40.0 + speed_offset) 
	
	for point in path:
		var dist = current_pos.distance_to(point)
		var duration = dist / individual_speed 

		# Vor dem Loslaufen in die richtige Richtung drehen
		tween.tween_callback(func(): rotation = global_position.angle_to_point(point))

		tween.tween_property(self, "global_position", point, duration)
		current_pos = point

	# 3. Am Ziel: Zur Tür drehen
	tween.tween_callback(func():
		rotation = global_position.angle_to_point(door_pos)
	)

	# 4. In die Tür treten (kurz warten, ausblenden, Node löschen)
	tween.tween_interval(0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.4) # Alpha auf 0 (wirkt sich auf alle Kinder aus!)
	tween.tween_callback(queue_free)



# extends Node2D

# const SPEED := 20.0 # Pixel pro Sekunde
# const FADE_TIME := 0.5 # Wie lange dauert das Ausblenden in Sekunden?

# @onready var sprite: Sprite2D = $Sprite2D
# var _current_tween: Tween


# # =============================================================================
# func walk_path(path: Array[Vector2], door_pos: Vector2, delay: float = 0.0) -> void:
#   var tween = create_tween()

#   # 1. Der Entenmarsch-Warte-Trick
#   if delay > 0.0:
#     # Wusel wartet unsichtbar (damit nicht 3 Wusel am Startpunkt übereinanderliegen)
#     visible = false
#     tween.tween_interval(delay)
#     tween.tween_callback(func(): visible = true)

#   # 2. Die Wegpunkte flüssig ablaufen
#   var current_pos = global_position
#   for point in path:
#     var dist = current_pos.distance_to(point)
#     var duration = dist / 40.0 # Laufgeschwindigkeit (40 Pixel pro Sekunde, bei Bedarf anpassen)

#     # Vor dem Loslaufen in die richtige Richtung drehen
#     tween.tween_callback(func(): rotation = global_position.angle_to_point(point))

#     tween.tween_property(self, "global_position", point, duration)
#     current_pos = point

#   # 3. Am Ziel: Zur Tür drehen
#   tween.tween_callback(func():
#     rotation = global_position.angle_to_point(door_pos)
#   )

#   # 4. In die Tür treten (kurz warten, ausblenden, Node löschen)
#   tween.tween_interval(0.3)
#   tween.tween_property(self, "modulate:a", 0.0, 0.4) # Alpha auf 0
#   tween.tween_callback(queue_free)


# # =============================================================================
# ## Diese Funktion baust du schon mal ein für deinen Plan mit den getrennten Sprites!
# func setup_colors(body_color: Color, skin_color: Color) -> void:
#   # Sobald du das Sprite aufteilst, machst du hier einfach:
#   # $BodySprite.modulate = body_color
#   # $HeadSprite.modulate = skin_color
#   pass
