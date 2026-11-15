class_name ResourceCalculator
extends RefCounted

## ResourceCalculator.gd - Aerospace engineering physics calculations for MARS DEEP.

const MissionConfigRef = preload("res://scripts/MissionConfig.gd")

# 1. ORBITAL & ASTRONOMICAL DYNAMICS
static func calculate_mean_orbital_radius(r_peri_au: float, r_aph_au: float) -> float:
	return (r_peri_au + r_aph_au) / 2.0

static func calculate_light_delay_seconds(distance_km: float) -> float:
	if distance_km <= 0.0:
		return 0.0
	return distance_km / MissionConfigRef.SPEED_OF_LIGHT

static func calculate_solar_irradiance(distance_au: float) -> float:
	if distance_au <= 0.0:
		return 0.0
	return MissionConfigRef.SOLAR_CONSTANT_EARTH / (distance_au * distance_au)

# 2. PROPULSION & DELTA-V (Tsiolkovsky Rocket Equation)
static func calculate_delta_v(isp_s: float, initial_mass_kg: float, final_mass_kg: float) -> float:
	if initial_mass_kg <= 0.0 or final_mass_kg <= 0.0 or final_mass_kg > initial_mass_kg:
		return 0.0
	return isp_s * MissionConfigRef.STANDARD_GRAVITY * log(initial_mass_kg / final_mass_kg)

static func calculate_required_propellant_mass(dry_mass_kg: float, delta_v_ms: float, isp_s: float) -> float:
	if dry_mass_kg <= 0.0 or isp_s <= 0.0:
		return 0.0
	var mass_ratio: float = exp(delta_v_ms / (isp_s * MissionConfigRef.STANDARD_GRAVITY))
	return dry_mass_kg * (mass_ratio - 1.0)

# 3. ELECTRICAL POWER & BATTERY SIZING
static func calculate_solar_array_area(power_needed_w: float, irradiance_w_m2: float, cell_efficiency: float, dust_factor: float) -> float:
	var effective_flux: float = irradiance_w_m2 * cell_efficiency * dust_factor
	if effective_flux <= 0.0:
		return 0.0
	return power_needed_w / effective_flux

static func calculate_battery_capacity_wh(power_draw_w: float, hours: float, max_depth_of_discharge: float) -> float:
	if max_depth_of_discharge <= 0.0:
		return 0.0
	return (power_draw_w * hours) / max_depth_of_discharge

# 4. THERMAL EQUILIBRIUM & RADIATOR SIZING
static func calculate_radiator_area(heat_load_w: float, temperature_k: float, emissivity: float = 0.90) -> float:
	if temperature_k <= 0.0 or emissivity <= 0.0:
		return 0.0
	var t4: float = pow(temperature_k, 4)
	return heat_load_w / (emissivity * MissionConfigRef.STEFAN_BOLTZMANN * t4)

# 5. ENTRY, DESCENT & LANDING (EDL) AERODYNAMICS
static func calculate_terminal_velocity(mass_kg: float, gravity_ms2: float, atm_density_kg_m3: float, area_m2: float, drag_coeff: float) -> float:
	var denom: float = atm_density_kg_m3 * area_m2 * drag_coeff
	if denom <= 0.0:
		return 0.0
	return sqrt((2.0 * mass_kg * gravity_ms2) / denom)

static func calculate_retro_burn_time(v_initial: float, v_touchdown: float, net_retro_accel: float) -> float:
	if net_retro_accel <= 0.0:
		return 0.0
	return (v_initial - v_touchdown) / net_retro_accel

# 6. SPACECRAFT DESIGN & SUBSYSTEM AGGREGATION
static func calculate_design_mass(selected_comps: Array, selected_insts: Array, comps_data: Dictionary, insts_data: Dictionary) -> Dictionary:
	var bus_mass: float = 0.0
	var subsystem_mass: float = 0.0
	var payload_mass: float = 0.0
	var max_payload_capacity: float = 0.0
	
	var cats: Dictionary = comps_data.get("categories", {})
	for cat_name in cats:
		var items: Array = cats[cat_name]
		for item in items:
			var cid: String = item.get("id", "")
			if selected_comps.has(cid):
				var m: float = float(item.get("mass_kg", 0.0))
				if cat_name == "structure":
					bus_mass += m
					max_payload_capacity = float(item.get("max_payload_kg", 0.0))
				else:
					subsystem_mass += m
					
	var inst_list: Array = insts_data.get("instruments", [])
	for inst in inst_list:
		var iid: String = inst.get("id", "")
		if selected_insts.has(iid):
			payload_mass += float(inst.get("mass_kg", 0.0))
			
	var dry_mass: float = bus_mass + subsystem_mass + payload_mass
	# Standard estimated propellant budget for 1600 m/s Delta-V at 320s Isp
	var estimated_propellant: float = calculate_required_propellant_mass(dry_mass, 1600.0, 320.0)
	var wet_mass: float = dry_mass + estimated_propellant
	
	return {
		"bus_mass_kg": bus_mass,
		"subsystem_mass_kg": subsystem_mass,
		"payload_mass_kg": payload_mass,
		"dry_mass_kg": dry_mass,
		"estimated_propellant_kg": estimated_propellant,
		"wet_mass_kg": wet_mass,
		"max_payload_capacity_kg": max_payload_capacity
	}

static func calculate_design_power(selected_comps: Array, selected_insts: Array, comps_data: Dictionary, insts_data: Dictionary) -> Dictionary:
	var generated_w: float = 0.0
	var consumed_w: float = 45.0 # Base avionics / command & data handling continuous load
	
	var cats: Dictionary = comps_data.get("categories", {})
	for cat_name in cats:
		var items: Array = cats[cat_name]
		for item in items:
			var cid: String = item.get("id", "")
			if selected_comps.has(cid):
				if item.has("power_output_w"):
					generated_w += float(item.get("power_output_w", 0.0))
				if item.has("power_w"):
					consumed_w += float(item.get("power_w", 0.0))
					
	var inst_list: Array = insts_data.get("instruments", [])
	for inst in inst_list:
		var iid: String = inst.get("id", "")
		if selected_insts.has(iid):
			consumed_w += float(inst.get("power_w", 0.0))
			
	var balance_w: float = generated_w - consumed_w
	var margin_pct: float = (balance_w / generated_w * 100.0) if generated_w > 0.0 else -100.0
	
	return {
		"generated_w": generated_w,
		"consumed_w": consumed_w,
		"balance_w": balance_w,
		"margin_percent": margin_pct
	}

static func calculate_design_cost(selected_comps: Array, selected_insts: Array, comps_data: Dictionary, insts_data: Dictionary) -> float:
	var total_cost: float = 0.0
	
	var cats: Dictionary = comps_data.get("categories", {})
	for cat_name in cats:
		var items: Array = cats[cat_name]
		for item in items:
			var cid: String = item.get("id", "")
			if selected_comps.has(cid):
				total_cost += float(item.get("cost_m", 0.0))
				
	var inst_list: Array = insts_data.get("instruments", [])
	for inst in inst_list:
		var iid: String = inst.get("id", "")
		if selected_insts.has(iid):
			total_cost += float(inst.get("cost_m", 0.0))
			
	return total_cost

static func calculate_design_payload_summary(selected_insts: Array, insts_data: Dictionary) -> Dictionary:
	var total_mass: float = 0.0
	var total_science_value: int = 0
	var total_data_volume: float = 0.0
	var count: int = 0
	
	var inst_list: Array = insts_data.get("instruments", [])
	for inst in inst_list:
		var iid: String = inst.get("id", "")
		if selected_insts.has(iid):
			total_mass += float(inst.get("mass_kg", 0.0))
			total_science_value += int(inst.get("science_value", 0))
			total_data_volume += float(inst.get("data_volume_mb_per_sol", 0.0))
			count += 1
			
	return {
		"count": count,
		"total_mass_kg": total_mass,
		"total_science_value": total_science_value,
		"total_data_volume_mb_per_sol": total_data_volume
	}
