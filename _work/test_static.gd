extends SceneTree

func _init():
	var test = load("res://scenes/ingame/rooms/conference_small/ConferenceSmall.gd").new()
	print("Has method get_definition: ", test.has_method("get_definition"))
	print("Can call get_definition: ", test.call("get_definition"))
	quit()
