class_name MissionValidator
extends RefCounted

## MissionValidator.gd - Strict validation engine for engineering submissions and mission milestones.

# STRICT RULE: A player must manually complete and submit engineering calculations.
# The validator evaluates the submission, but NEVER automatically completes unanswered tasks.

static func validate_task_submission(task: Dictionary, player_submission: Variant) -> Dictionary:
	var result: Dictionary = {
		"is_valid": false,
		"task_id": task.get("id", ""),
		"error_margin_percent": 0.0,
		"message": ""
	}
	
	if player_submission == null:
		result["message"] = "Submission rejected: No calculation or input provided. Manual calculation required."
		return result
		
	var task_type: String = task.get("task_type", "calculation")
	
	if task_type == "selection":
		var submitted_str: String = str(player_submission).strip_edges()
		var target_str: String = str(task.get("target_value", "")).strip_edges()
		var acceptable_options: Array = task.get("acceptable_options", [])
		
		if submitted_str.is_empty():
			result["message"] = "Selection required: Please select an architecture option."
			return result
			
		if submitted_str == target_str or acceptable_options.has(submitted_str):
			result["is_valid"] = true
			result["message"] = "Architecture selection validated: " + submitted_str
		else:
			result["message"] = "Selection invalid for primary scientific profile."
		return result

	# For numerical calculations
	var player_val: float = 0.0
	if typeof(player_submission) == TYPE_STRING:
		var s: String = (player_submission as String).strip_edges()
		if s.is_empty() or not s.is_valid_float():
			result["message"] = "Submission rejected: Value must be a valid numerical calculation."
			return result
		player_val = s.to_float()
	elif typeof(player_submission) in [TYPE_FLOAT, TYPE_INT]:
		player_val = float(player_submission)
	else:
		result["message"] = "Invalid submission data format."
		return result
		
	var target_val: float = float(task.get("target_value", 0.0))
	var tolerance: float = float(task.get("tolerance", 0.05)) # Default ±5%
	
	if target_val == 0.0:
		result["message"] = "Invalid task configuration."
		return result
		
	var abs_error: float = abs(player_val - target_val)
	var rel_error: float = abs_error / abs(target_val)
	var error_percent: float = rel_error * 100.0
	result["error_margin_percent"] = error_percent
	
	if rel_error <= tolerance:
		result["is_valid"] = true
		result["message"] = "Calculation validated! Error: %.2f%% (within acceptable ±%.1f%% tolerance)." % [error_percent, tolerance * 100.0]
	else:
		result["is_valid"] = false
		result["message"] = "Calculation out of tolerance (Error: %.2f%%, Allowed: ±%.1f%%). Check your formula and recalculate." % [error_percent, tolerance * 100.0]
		
	return result

static func validate_spacecraft_readiness(spacecraft_config: Dictionary, launch_vehicle: Dictionary) -> Dictionary:
	var total_mass_kg: float = spacecraft_config.get("wet_mass_kg", 0.0)
	var max_launcher_tmi_kg: float = launch_vehicle.get("payload_tmi_capacity_kg", 0.0)
	var delta_v_ms: float = spacecraft_config.get("total_delta_v_ms", 0.0)
	var required_dv_ms: float = spacecraft_config.get("required_delta_v_ms", 1600.0)
	
	var errors: Array[String] = []
	
	if total_mass_kg <= 0.0:
		errors.append("Spacecraft dry/wet mass has not been calculated.")
	elif total_mass_kg > max_launcher_tmi_kg:
		errors.append("Spacecraft wet mass (%.1f kg) exceeds launch vehicle TMI payload capacity (%.1f kg)." % [total_mass_kg, max_launcher_tmi_kg])
		
	if delta_v_ms < required_dv_ms:
		errors.append("Total Delta-V (%.1f m/s) is insufficient for Mars transfer and orbital insertion (Requires %.1f m/s)." % [delta_v_ms, required_dv_ms])
		
	return {
		"is_ready": errors.is_empty(),
		"errors": errors
	}

static func validate_spacecraft_design(selected_comps: Array, selected_insts: Array, comps_data: Dictionary, insts_data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	
	# 1. Structural Bus
	var has_bus: bool = false
	var bus_payload_limit: float = 0.0
	var cats: Dictionary = comps_data.get("categories", {})
	var structures: Array = cats.get("structure", [])
	for s in structures:
		if selected_comps.has(s.get("id", "")):
			has_bus = true
			bus_payload_limit = float(s.get("max_payload_kg", 0.0))
			break
	if not has_bus:
		errors.append("Primary Bus: You must select a primary spacecraft structural bus.")

	# 2. Power System
	var power_count: int = 0
	var power_items: Array = cats.get("power", [])
	for p in power_items:
		if selected_comps.has(p.get("id", "")):
			power_count += 1
	if power_count == 0:
		errors.append("Power System: Exactly one primary power source (UltraFlex Solar or MMRTG) is required.")
	elif power_count > 1:
		errors.append("Power System Conflict: You cannot mount both Solar Arrays and an MMRTG simultaneously.")

	# 3. Main Propulsion / RCS
	var has_prop: bool = false
	var prop_items: Array = cats.get("propulsion", [])
	for pr in prop_items:
		if selected_comps.has(pr.get("id", "")):
			has_prop = true
			break
	if not has_prop:
		errors.append("Propulsion: At least one propulsion subsystem (Bi-propellant Main Engine or RCS Thrusters) is required.")

	# 4. Telecommunications
	var has_telecom: bool = false
	var telecom_items: Array = cats.get("telecom", [])
	for tc in telecom_items:
		if selected_comps.has(tc.get("id", "")):
			has_telecom = true
			break
	if not has_telecom:
		errors.append("Telecommunications: Deep space antenna (High-Gain Reflector or UHF Relay) is required for mission telemetry.")

	# 5. Thermal Control
	var has_thermal: bool = false
	var thermal_items: Array = cats.get("thermal", [])
	for th in thermal_items:
		if selected_comps.has(th.get("id", "")):
			has_thermal = true
			break
	if not has_thermal:
		errors.append("Thermal Regulation: Thermal radiator / heat pipe array is required to survive space vacuum temperatures.")

	# 6. Scientific Instruments
	if selected_insts.is_empty():
		errors.append("Scientific Payload: Mission requires at least one scientific instrument to achieve science goals.")

	# 7. Mass & Power Budget Constraints
	var payload_mass: float = 0.0
	var inst_list: Array = insts_data.get("instruments", [])
	for inst in inst_list:
		if selected_insts.has(inst.get("id", "")):
			payload_mass += float(inst.get("mass_kg", 0.0))
			
	if has_bus and payload_mass > bus_payload_limit:
		errors.append("Mass Overload: Selected payload mass (%.1f kg) exceeds structural bus capacity (%.1f kg)." % [payload_mass, bus_payload_limit])
	elif has_bus and bus_payload_limit > 0.0 and (payload_mass / bus_payload_limit) > 0.85:
		warnings.append("High Mass: Science payload is utilizing >85% of structural capacity.")

	# Power balance check
	var ResourceCalculatorRef = preload("res://scripts/ResourceCalculator.gd")
	var power_summary: Dictionary = ResourceCalculatorRef.calculate_design_power(selected_comps, selected_insts, comps_data, insts_data)
	if power_summary.get("balance_w", 0.0) < 0.0:
		errors.append("Power Deficit: Spacecraft subsystems & instruments consume more electrical power (%.1f W) than generated (%.1f W)." % [
			power_summary.get("consumed_w", 0.0),
			power_summary.get("generated_w", 0.0)
		])
	elif power_summary.get("margin_percent", 0.0) < 15.0:
		warnings.append("Low Power Margin: Operating power reserve is under recommended 15% safety buffer.")

	return {
		"is_valid": errors.is_empty(),
		"errors": errors,
		"warnings": warnings
	}
