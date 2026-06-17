@tool
extends SceneTree

func _init():
	var dir = DirAccess.open("user://saves")
	if dir:
		print("--- SAVE FILES ---")
		for file_name in dir.get_files():
			print("- ", file_name)
		print("------------------")
	else:
		print("No saves directory found!")
	quit()
