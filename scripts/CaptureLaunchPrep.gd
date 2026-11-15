extends SceneTree

func _init() -> void:
	print("[Capture] Starting LaunchPreparation Screenshot Capture...")
	var scene = load("res://scenes/LaunchPreparation.tscn")
	var instance = scene.instantiate()
	root.add_child(instance)
	
	# Wait for rendering frames
	for i in range(15):
		await process_frame
		
	var img = root.get_viewport().get_texture().get_image()
	var err = img.save_png("screenshots/launch_prep_rework_d.png")
	if err == OK:
		print("[Capture] Successfully saved screenshots/launch_prep_rework_d.png")
	else:
		print("[Capture] Failed to save screenshot. Error: ", err)
	quit(0)
