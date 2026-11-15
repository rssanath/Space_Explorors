class_name MissionScoring
extends RefCounted

## MissionScoring.gd - Evaluates engineering accuracy, science yield, timeline milestones,
## player achievements, and assigns comprehensive NASA mission grades (S, A, B, C, D, F).

static func calculate_mission_score(
	completed_tasks_count: int,
	total_tasks_count: int,
	average_error_percent: float,
	instruments_count: int,
	samples_collected: int = 0
) -> Dictionary:
	var base_score: float = 0.0
	
	# Task completion fraction (up to 5000 points)
	if total_tasks_count > 0:
		var task_ratio: float = float(completed_tasks_count) / float(total_tasks_count)
		base_score += task_ratio * 5000.0
		
	# Calculation precision bonus (up to 2500 points)
	# 0% error gives full 2500, decreasing down to 0 at 5% error
	var precision_bonus: float = maxf(0.0, 2500.0 * (1.0 - (average_error_percent / 5.0)))
	base_score += precision_bonus
	
	# Science instrument & sample yield (up to 2500 points)
	var science_points: float = (instruments_count * 250.0) + (samples_collected * 150.0)
	science_points = minf(science_points, 2500.0)
	base_score += science_points
	
	var final_score: int = int(round(base_score))
	var grade: String = "F"
	var award_title: String = "Mission Incomplete"
	
	if final_score >= 9500:
		grade = "S"
		award_title = "NASA Administrator's Distinguished Public Service Medal"
	elif final_score >= 8500:
		grade = "A"
		award_title = "NASA Exceptional Engineering Achievement Medal"
	elif final_score >= 7000:
		grade = "B"
		award_title = "Successful Mars Planetary Mission Medal"
	elif final_score >= 5000:
		grade = "C"
		award_title = "Mission Completed • Nominal Achievement"
	elif final_score >= 3500:
		grade = "D"
		award_title = "Partial Mission Objective Attainment • Structural Difficulties"
	else:
		grade = "F"
		award_title = "Mission Objective Failure"
		
	return {
		"score": final_score,
		"grade": grade,
		"award_title": award_title,
		"precision_bonus": int(round(precision_bonus)),
		"science_points": int(round(science_points)),
		"task_points": int(round(base_score - precision_bonus - science_points))
	}

# =========================================================================
# 16-STAGE CHRONOLOGICAL MISSION TIMELINE
# =========================================================================

static func get_mission_timeline(gm: Node) -> Array[Dictionary]:
	var p = gm.progress if gm else null
	var is_lvl1_done: bool = p != null and p.is_level_completed("LVL_01")
	var is_lvl2_done: bool = p != null and p.is_level_completed("LVL_02")
	var is_lvl3_done: bool = p != null and p.is_level_completed("LVL_03")
	var is_lvl4_done: bool = p != null and p.is_level_completed("LVL_04")
	var is_lvl5_done: bool = p != null and p.is_level_completed("LVL_05")
	
	var timeline: Array[Dictionary] = [
		{
			"id": 1,
			"phase": "PRE-FLIGHT",
			"title": "Spacecraft Subsystems Design",
			"description": "Constructed balanced spacecraft architecture (Structure, Power, Propulsion, Telecom, Thermal, Science).",
			"completed": is_lvl1_done,
			"status_text": "NOMINAL SPECS VERIFIED" if is_lvl1_done else "INCOMPLETE",
			"metrics": "Payload: %d Instruments • Archetype: %s" % [gm.selected_instruments.size() if gm else 0, gm.selected_archetype if gm else "Unknown"]
		},
		{
			"id": 2,
			"phase": "PRE-FLIGHT",
			"title": "Engineering Lab Certification",
			"description": "Solved 5 rigorous astrodynamics & aerospace equations (Solar irradiance, Tsiolkovsky delta-v, antenna gain, thermal balance).",
			"completed": is_lvl2_done,
			"status_text": "CERTIFIED ACCURATE" if is_lvl2_done else "PENDING FORMULAS",
			"metrics": "5/5 Level 02 Mandatory Tasks Complete" if is_lvl2_done else "Tasks Pending"
		},
		{
			"id": 3,
			"phase": "LAUNCH",
			"title": "Launch Vehicle Integration",
			"description": "Selected heavy-lift launcher matching payload mass to C3 injection energy requirements.",
			"completed": is_lvl3_done or is_lvl2_done,
			"status_text": "INTEGRATED" if (is_lvl3_done or is_lvl2_done) else "UNASSIGNED",
			"metrics": gm.get_selected_launch_vehicle().get("name", "Atlas V 541") if gm else "Atlas V 541"
		},
		{
			"id": 4,
			"phase": "LAUNCH",
			"title": "Pre-Launch Systems & Countdown",
			"description": "Executed T-10s countdown, propellant cryogenic chilldown, and hold-down clamp pre-tensioning.",
			"completed": is_lvl3_done,
			"status_text": "COUNTDOWN COMPLETE" if is_lvl3_done else "PENDING IGNITION",
			"metrics": "Pad 39A Cape Canaveral • Cryo Fill 100%"
		},
		{
			"id": 5,
			"phase": "LAUNCH",
			"title": "Main Engine Ignition",
			"description": "Hydraulic clamp release at 90% throttle with booster ignition and flame trench exhaust routing.",
			"completed": is_lvl3_done,
			"status_text": "MAIN ENGINES AT FULL POWER" if is_lvl3_done else "STANDBY",
			"metrics": "Sea-Level Thrust: Nominal • Acoustics Suppressed"
		},
		{
			"id": 6,
			"phase": "ASCENT",
			"title": "Earth Atmospheric Liftoff",
			"description": "Tower clearance, pitch maneuver, Max-Q aerodynamic barrier passage, and first-stage booster burnout.",
			"completed": is_lvl3_done,
			"status_text": "TOWER CLEARED" if is_lvl3_done else "AWAITING LIFTOFF",
			"metrics": "Max-Q Dynamic Pressure: Passed Nominal"
		},
		{
			"id": 7,
			"phase": "ORBIT",
			"title": "Low Earth Orbital Insertion",
			"description": "Circularized spacecraft in 250 km parking orbit at 7.75 km/s orbital velocity.",
			"completed": is_lvl3_done,
			"status_text": "ORBIT STABLE (250 km)" if is_lvl3_done else "SUB-ORBITAL",
			"metrics": "Altitude: 250 km • Orbital Period: 89.5 min"
		},
		{
			"id": 8,
			"phase": "TRANSIT",
			"title": "Trans-Mars Injection (TMI) Burn",
			"description": "Second-stage Centaur / Upper stage restart providing 3.6 km/s hyperbolic escape burn toward Mars.",
			"completed": is_lvl4_done,
			"status_text": "TMI BURN NOMINAL" if is_lvl4_done else "AWAITING INJECTION",
			"metrics": "Escape Velocity: 11.2 km/s • Hyperbolic C3: 16.5 km²/s²"
		},
		{
			"id": 9,
			"phase": "CRUISE",
			"title": "Interplanetary Hohmann Cruise",
			"description": "Navigated 480 million km heliocentric elliptic transit trajectory under solar radiation and microgravity.",
			"completed": is_lvl4_done,
			"status_text": "HELIOCENTRIC TRANSIT COMPLETE" if is_lvl4_done else "INACTIVE",
			"metrics": "Duration: %d Days • Trajectory: %s" % [
				gm.get_selected_mission_route().get("duration_days", 260) if gm else 260,
				gm.get_selected_mission_route().get("name", "Hohmann Transfer") if gm else "Hohmann"
			]
		},
		{
			"id": 10,
			"phase": "CRUISE",
			"title": "Mid-Course Trajectory Correction (TCM-1)",
			"description": "Executed precision monopropellant RCS thruster burn correcting trajectory drift to Mars entry corridor.",
			"completed": is_lvl4_done,
			"status_text": "CORRECTION EXECUTED" if is_lvl4_done else "NOT REQUIRED",
			"metrics": "Delta-V: 15.0 m/s • Fuel Burned: 12.1 kg"
		},
		{
			"id": 11,
			"phase": "APPROACH",
			"title": "Mars Orbit Insertion (MOI) Retrograde Burn",
			"description": "Fired main bipropellant propulsion into retrograde vector to capture into Mars gravitational well.",
			"completed": is_lvl4_done,
			"status_text": "MARS CAPTURE CERTIFIED" if is_lvl4_done else "INCOMING",
			"metrics": "Capture Orbit: 350 km circular • Retro-Burn: 1180 m/s"
		},
		{
			"id": 12,
			"phase": "EDL",
			"title": "Atmospheric Entry (EDL Seven Minutes of Terror)",
			"description": "Hypersonic atmospheric entry at 5.8 km/s with ablative heat shield thermal protection and supersonic parachute.",
			"completed": is_lvl5_done,
			"status_text": "ATMOSPHERIC ENTRY SURVIVED" if is_lvl5_done else "AWAITING ENTRY",
			"metrics": "Entry Kinetic Energy: 17.24 GJ • Chute Mach: 1.8"
		},
		{
			"id": 13,
			"phase": "TOUCHDOWN",
			"title": "Powered Descent & Surface Touchdown",
			"description": "Closed-loop radar altimeter terminal retro-engine throttling and crushable landing leg contact.",
			"completed": is_lvl5_done,
			"status_text": "TOUCHDOWN SUCCESSFUL" if is_lvl5_done else "PENDING LANDING",
			"metrics": "Touchdown Speed: 1.15 m/s (Nominal < 1.5 m/s)"
		},
		{
			"id": 14,
			"phase": "SURFACE",
			"title": "Lander Ramp Extension & Rover Egress",
			"description": "Deployment bay doors opened, motorized ramp tilted, and 6-wheel rover rolled onto Martian regolith.",
			"completed": is_lvl5_done,
			"status_text": "ROVER EGRESS COMPLETE" if is_lvl5_done else "STOWED IN LANDER",
			"metrics": "Ramp Angle: 25.8° • All 6 Wheels Grounded"
		},
		{
			"id": 15,
			"phase": "SURFACE",
			"title": "Surface Exploration & Rover Traversing",
			"description": "Traversed rocky terrain, dunes, and ancient delta deposits with rocker-bogie mobility and Mastcam imaging.",
			"completed": is_lvl5_done,
			"status_text": "SURFACE TRAVERSED" if is_lvl5_done else "NOT INITIATED",
			"metrics": "Max Speed: 3.6 km/h • Battery: 1200 Wh Nominal"
		},
		{
			"id": 16,
			"phase": "SCIENCE",
			"title": "Sample Collection & Astrobiological Discovery",
			"description": "Analyzed 5 primary science objectives with SuperCam, PIXL, SHERLOC, RIMFAX, and MOXIE ISRU oxygen production.",
			"completed": is_lvl5_done,
			"status_text": "5/5 DISCOVERIES CACHED" if is_lvl5_done else "PENDING HARVEST",
			"metrics": "Astrobiology Score: 90.0 Pts • All Primary Goals Met"
		}
	]
	return timeline

# =========================================================================
# MISSION PERFORMANCE ANALYSIS
# =========================================================================

static func get_performance_breakdown(gm: Node) -> Dictionary:
	var p = gm.progress if gm else null
	var comp_tasks: int = p.get_completed_tasks_count() if p else 0
	var total_tasks: int = p.get_total_tasks_count() if p else 23
	var inst_count: int = gm.selected_instruments.size() if gm else 0
	var samples_count: int = 5 if (p != null and p.is_level_completed("LVL_05")) else 0
	
	# Compute average calculation error from player attempts
	var total_err: float = 0.0
	var evaluated_attempts: int = 0
	if gm and gm.calculation_attempts.size() > 0:
		for att in gm.calculation_attempts:
			if att.get("is_valid", false):
				total_err += 0.2 # nominal low error
				evaluated_attempts += 1
	var avg_err: float = (total_err / float(max(1, evaluated_attempts))) if evaluated_attempts > 0 else 0.0
	
	var score_data = calculate_mission_score(comp_tasks, total_tasks, avg_err, inst_count, samples_count)
	
	var categories: Array[Dictionary] = [
		{
			"name": "Launch Vehicle & Trajectory",
			"score": 1500 if (p != null and p.is_level_completed("LVL_03")) else 0,
			"max_score": 1500,
			"grade": "100%" if (p != null and p.is_level_completed("LVL_03")) else "0%",
			"description": "Nominal launch vehicle mass margin, pad clearance, acoustic water suppression, and C3 orbital injection."
		},
		{
			"name": "Engineering Calculation Accuracy",
			"score": score_data.precision_bonus,
			"max_score": 2500,
			"grade": "%.1f%% Precision" % [100.0 - minf(100.0, avg_err * 20.0)],
			"description": "Accurate physical computations across 23 mandatory tasks (Tsiolkovsky delta-v, antenna link budget, solar flux, kinetic entry energy)."
		},
		{
			"name": "Interplanetary Navigation & TCM-1",
			"score": 1500 if (p != null and p.is_level_completed("LVL_04")) else 0,
			"max_score": 1500,
			"grade": "Optimal" if (p != null and p.is_level_completed("LVL_04")) else "Incomplete",
			"description": "Hyperbolic departure, Deep Space Network tracking, solar storm shelter orientation, and 15 m/s TCM-1 burn."
		},
		{
			"name": "Atmospheric Entry & Touchdown",
			"score": 2000 if (p != null and p.is_level_completed("LVL_05")) else 0,
			"max_score": 2000,
			"grade": "1.15 m/s (Soft)" if (p != null and p.is_level_completed("LVL_05")) else "Pending",
			"description": "17.24 GJ kinetic energy dissipation, supersonic parachute inflation, and terminal retro-thrust soft touchdown."
		},
		{
			"name": "Surface Mobility & Science Harvest",
			"score": score_data.science_points,
			"max_score": 2500,
			"grade": "5 / 5 Targets" if samples_count == 5 else ("%d Targets" % samples_count),
			"description": "6-wheel rover traverse, robotic arm sampling, RIMFAX ground-penetrating radar profiling, and MOXIE ISRU oxygen production."
		}
	]
	
	return {
		"overall": score_data,
		"categories": categories,
		"tasks_ratio": "%.1f%% (%d / %d Tasks)" % [float(comp_tasks) / float(max(1, total_tasks)) * 100.0, comp_tasks, total_tasks],
		"instruments_deployed": inst_count,
		"samples_cached": samples_count
	}

# =========================================================================
# SCIENCE DISCOVERY GALLERY DATA
# =========================================================================

static func get_science_gallery_data(gm: Node) -> Array[Dictionary]:
	var p = gm.progress if gm else null
	var is_lvl5_done: bool = p != null and p.is_level_completed("LVL_05")
	
	var discoveries: Array[Dictionary] = [
		{
			"id": "SAMPLE_01",
			"name": "Jezero Delta Smectite Clay Outcrop",
			"location": "Jezero Crater Fan Delta",
			"instrument": "SuperCam Laser & PIXL",
			"collected": is_lvl5_done,
			"observation": "Hydrated phyllosilicate clay minerals exhibiting fine-scale laminar sedimentation and associated organic carbon signatures.",
			"scientific_explanation": "Smectite clays are formed in long-lived standing water environments. They have an exceptional ability to preserve organic biosignatures on Earth and indicate ancient habitable lake conditions in Jezero Crater.",
			"real_world_nasa_discovery": "NASA's Perseverance rover discovered rich phyllosilicate clays in the 'Skinner Ridge' delta outcrop in 2022, confirming Jezero once held a sustained river lake system 3.5 billion years ago."
		},
		{
			"id": "SAMPLE_02",
			"name": "Olivine-Rich Igneous Basalt",
			"location": "Crater Floor Stratum",
			"instrument": "SuperCam & SHERLOC",
			"collected": is_lvl5_done,
			"observation": "Crystalline volcanic pyroxene and olivine rock showing grain textures characteristic of thick, slowly cooled magma flows.",
			"scientific_explanation": "Volcanic rocks provide an accurate radiometric clock (via potassium-argon / rubidium-strontium dating) to establish absolute ages of Martian geological epochs.",
			"real_world_nasa_discovery": "Perseverance's coring drill sampled the 'Séítah' formation in late 2021, revealing that the crater floor was composed of ancient igneous magma rather than purely sedimentary lake deposits."
		},
		{
			"id": "SAMPLE_03",
			"name": "Subsurface Cross-Bedded Radargram",
			"location": "Subterranean Strata (0 - 12m)",
			"instrument": "RIMFAX Ground-Penetrating Radar",
			"collected": is_lvl5_done,
			"observation": "Distinct subsurface radar dielectric permittivity boundaries revealing dipping reflector layers 12 meters beneath the regolith.",
			"scientific_explanation": "Subsurface radar maps buried paleolake geometries and identifies potential permafrost or brine reservoirs invisible to surface cameras.",
			"real_world_nasa_discovery": "RIMFAX radar data published by NASA and UCLA in 2023 mapped curved underground sediment beds beneath Jezero, confirming river delta deposition geometry from below."
		},
		{
			"id": "SAMPLE_04",
			"name": "Boundary Layer Meteorology & Dust Log",
			"location": "Martian Boundary Atmosphere",
			"instrument": "MEDA Environmental Sensor Station",
			"collected": is_lvl5_done,
			"observation": "Atmospheric pressure: 6.8 mbar, ambient temperature diurnal swing: -84°C to -12°C, peak dust optical depth tau = 0.45.",
			"scientific_explanation": "Continuous atmospheric dynamics telemetry validates global climate and circulation models required for future human Mars surface habitats.",
			"real_world_nasa_discovery": "NASA MEDA has recorded thousands of Martian sols of wind gusts, convective dust devils, and daily radiation fluctuations in Jezero Crater since February 2021."
		},
		{
			"id": "SAMPLE_05",
			"name": "ISRU Breathable Oxygen Production",
			"location": "Lander Base Station Reactor",
			"instrument": "MOXIE Solid Oxide Electrolyzer",
			"collected": is_lvl5_done,
			"observation": "Catalytic solid oxide electrolysis converted atmospheric CO2 into 99.6% purity breathable O2 at 5.8 grams per hour.",
			"scientific_explanation": "In-situ resource utilization (ISRU) eliminates the prohibitive launch mass of bringing return rocket oxidizer and life support oxygen from Earth.",
			"real_world_nasa_discovery": "Between 2021 and 2023, NASA's MOXIE experiment on Perseverance successfully generated 122 grams of oxygen across 16 test runs in various Martian seasons, proving ISRU technology."
		}
	]
	return discoveries

# =========================================================================
# 10 PLAYER ACHIEVEMENTS
# =========================================================================

static func get_player_achievements(gm: Node) -> Array[Dictionary]:
	var p = gm.progress if gm else null
	var is_lvl1: bool = p != null and p.is_level_completed("LVL_01")
	var is_lvl2: bool = p != null and p.is_level_completed("LVL_02")
	var is_lvl3: bool = p != null and p.is_level_completed("LVL_03")
	var is_lvl4: bool = p != null and p.is_level_completed("LVL_04")
	var is_lvl5: bool = p != null and p.is_level_completed("LVL_05")
	
	var achievements: Array[Dictionary] = [
		{
			"id": "ACH_FIRST_LAUNCH",
			"title": "First Launch",
			"subtitle": "Clear the Tower",
			"description": "Ignite main rocket engines, release hold-down clamps, and clear Pad 39A into high atmosphere.",
			"unlocked": is_lvl3,
			"icon": "🚀",
			"rarity": "Bronze"
		},
		{
			"id": "ACH_ORBIT_ACHIEVED",
			"title": "Orbit Achieved",
			"subtitle": "Keplerian Insertion",
			"description": "Achieve a stable circular parking orbit around Earth at 250 km altitude.",
			"unlocked": is_lvl3,
			"icon": "🛰️",
			"rarity": "Bronze"
		},
		{
			"id": "ACH_MARS_ARRIVAL",
			"title": "Mars Arrival",
			"subtitle": "Trans-Mars Voyager",
			"description": "Complete deep space Hohmann cruise, execute TCM-1, and perform Mars Orbit Insertion burn.",
			"unlocked": is_lvl4,
			"icon": "🔴",
			"rarity": "Silver"
		},
		{
			"id": "ACH_PERFECT_LANDING",
			"title": "Perfect Landing",
			"subtitle": "Seven Minutes Master",
			"description": "Survive hypersonic entry and achieve touchdown at vertical speed below 1.5 m/s.",
			"unlocked": is_lvl5,
			"icon": "🎯",
			"rarity": "Gold"
		},
		{
			"id": "ACH_ROVER_DEPLOYED",
			"title": "Rover Deployed",
			"subtitle": "Surface Grounding",
			"description": "Extend lander egress ramp and deploy 6-wheel science rover onto Martian regolith.",
			"unlocked": is_lvl5,
			"icon": "🚜",
			"rarity": "Bronze"
		},
		{
			"id": "ACH_FIRST_DISCOVERY",
			"title": "First Science Discovery",
			"subtitle": "Sample Pioneer",
			"description": "Acquire first geological sample outcrop and cache sample in rover payload bay.",
			"unlocked": is_lvl5,
			"icon": "🔬",
			"rarity": "Bronze"
		},
		{
			"id": "ACH_SAMPLE_COLLECTOR",
			"title": "Sample Collector",
			"subtitle": "Astrobiology Cache",
			"description": "Collect and seal multiple core drill samples from delta clays and volcanic basalth.",
			"unlocked": is_lvl5,
			"icon": "🧪",
			"rarity": "Silver"
		},
		{
			"id": "ACH_MISSION_SCIENTIST",
			"title": "Mission Scientist",
			"subtitle": "Complete Payload Harvest",
			"description": "Operate all 7 scientific instruments across geomorphology, radar, weather, and MOXIE ISRU.",
			"unlocked": is_lvl5,
			"icon": "🔭",
			"rarity": "Gold"
		},
		{
			"id": "ACH_MARS_EXPLORER",
			"title": "Mars Explorer",
			"subtitle": "Martian Wayfarer",
			"description": "Navigate over 50 meters across Jezero Crater with 6-wheel rocker-bogie mobility.",
			"unlocked": is_lvl5,
			"icon": "🗺️",
			"rarity": "Silver"
		},
		{
			"id": "ACH_COMPLETE_MISSION",
			"title": "Complete Mission",
			"subtitle": "NASA Mission Commander",
			"description": "Complete all 5 campaign levels and certify all 23 mandatory engineering challenges.",
			"unlocked": is_lvl1 and is_lvl2 and is_lvl3 and is_lvl4 and is_lvl5,
			"icon": "🏆",
			"rarity": "Platinum"
		}
	]
	return achievements

# =========================================================================
# SPACECRAFT PERFORMANCE REPORT
# =========================================================================

static func get_spacecraft_performance_summary(gm: Node) -> Dictionary:
	var telem = gm.get_design_telemetry() if gm else {}
	var lv = gm.get_selected_launch_vehicle() if gm else {}
	var route = gm.get_selected_mission_route() if gm else {}
	var p = gm.progress if gm else null
	
	var dry_mass: float = telem.get("mass", {}).get("total_mass_kg", 573.6)
	var wet_mass: float = dry_mass + 850.0 # with propellant
	var power_gen: float = telem.get("power", {}).get("total_generation_w", 420.0)
	var power_cons: float = telem.get("power", {}).get("total_consumption_w", 175.4)
	var power_margin: float = power_gen - power_cons
	
	return {
		"archetype": gm.selected_archetype if gm else "Surface Rover",
		"launch_vehicle_name": lv.get("name", "Atlas V 541"),
		"launch_capacity_kg": lv.get("payload_capacity_c3_kg", 1850.0),
		"dry_mass_kg": dry_mass,
		"wet_mass_kg": wet_mass,
		"propellant_mass_kg": 850.0,
		"power_generated_w": power_gen,
		"power_consumed_w": power_cons,
		"power_margin_w": power_margin,
		"total_cost_m": telem.get("cost_m", 251.0),
		"installed_instruments_count": gm.selected_instruments.size() if gm else 0,
		"trajectory_name": route.get("name", "Hohmann Transfer"),
		"transit_duration_days": route.get("duration_days", 260),
		"delta_v_demand_km_s": route.get("delta_v_km_s", 3.6),
		"landing_result": "Touchdown Nominal (1.15 m/s)" if (p != null and p.is_level_completed("LVL_05")) else "Pending Landing",
		"mission_status": "CERTIFIED SUCCESSFUL" if (p != null and p.is_level_completed("LVL_05")) else "IN PROGRESS"
	}
