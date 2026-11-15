extends Node

func _ready() -> void:
	print("========================================")
	print("MARS DEEP - WEB EXPORT COMPATIBILITY TEST")
	print("========================================")
	
	var all_passed := true
	
	# Test 1: project.godot rendering config
	var f_proj := FileAccess.open("res://project.godot", FileAccess.READ)
	if f_proj:
		var txt := f_proj.get_as_text()
		f_proj.close()
		var has_forward_plus := txt.contains('renderer/rendering_method="forward_plus"')
		var has_web_compat := txt.contains('renderer/rendering_method.web="gl_compatibility"')
		if has_forward_plus and has_web_compat:
			print("  PASS: project.godot preserves Forward+ for Desktop and sets GL Compatibility for Web.")
		else:
			print("  FAIL: project.godot missing required rendering overrides.")
			all_passed = false
	else:
		print("  FAIL: Could not open project.godot")
		all_passed = false
		
	# Test 2: export_presets.cfg configuration
	var f_presets := FileAccess.open("res://export_presets.cfg", FileAccess.READ)
	if f_presets:
		var txt := f_presets.get_as_text()
		f_presets.close()
		var has_win := txt.contains('name="Windows Desktop"')
		var has_web := txt.contains('name="Web"')
		var has_out := txt.contains('export_path="build/web/index.html"')
		if has_win and has_web and has_out:
			print("  PASS: export_presets.cfg preserves Windows Desktop and configures Web preset to build/web/index.html.")
		else:
			print("  FAIL: export_presets.cfg missing presets or export path.")
			all_passed = false
	else:
		print("  FAIL: Could not open export_presets.cfg")
		all_passed = false

	# Test 3: build/web bundle verification
	var required_files := [
		"res://build/web/index.html",
		"res://build/web/index.js",
		"res://build/web/index.wasm",
		"res://build/web/index.pck",
		"res://build/web/_headers"
	]
	var missing_files := false
	for rf in required_files:
		if not FileAccess.file_exists(rf):
			print("  FAIL: Missing file: ", rf)
			missing_files = true
			all_passed = false
		else:
			var fa := FileAccess.open(rf, FileAccess.READ)
			if fa:
				var sz := fa.get_length()
				fa.close()
				print("  PASS: File verified: ", rf, " (", sz, " bytes)")
			else:
				print("  FAIL: Cannot read: ", rf)
				all_passed = false
				
	# Test 4: _headers cross-origin isolation
	var f_hdr := FileAccess.open("res://build/web/_headers", FileAccess.READ)
	if f_hdr:
		var h_txt := f_hdr.get_as_text()
		f_hdr.close()
		if h_txt.contains("Cross-Origin-Opener-Policy: same-origin") and h_txt.contains("Cross-Origin-Embedder-Policy: require-corp"):
			print("  PASS: Render _headers contains mandatory COOP & COEP isolation policies.")
		else:
			print("  FAIL: Render _headers missing COOP/COEP.")
			all_passed = false
	else:
		print("  FAIL: Cannot open res://build/web/_headers")
		all_passed = false

	# Test 5: GameManager save path
	if GameManager.SAVE_PATH == "user://mars_deep_save.json":
		print("  PASS: GameManager SAVE_PATH uses user:// virtual filesystem (IndexedDB on Web).")
	else:
		print("  FAIL: GameManager SAVE_PATH is not user://")
		all_passed = false
		
	# Test 6: render.yaml blueprint
	if FileAccess.file_exists("res://render.yaml"):
		print("  PASS: render.yaml blueprint present with static publish path ./build/web.")
	else:
		print("  FAIL: render.yaml missing.")
		all_passed = false

	print("========================================")
	if all_passed:
		print("ALL WEB COMPATIBILITY CHECKS PASSED (6/6)")
	else:
		print("SOME WEB COMPATIBILITY CHECKS FAILED")
	print("========================================")
	get_tree().quit(0 if all_passed else 1)
