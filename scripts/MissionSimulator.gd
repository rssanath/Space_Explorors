class_name MissionSimulator
extends RefCounted

## MissionSimulator.gd - Interplanetary trajectory and flight phase simulation state machine.

enum FlightPhase {
	PRE_LAUNCH,
	ASCENT_AND_TMI,
	INTERPLANETARY_CRUISE,
	TRAJECTORY_CORRECTION,
	MARS_APPROACH,
	ATMOSPHERIC_ENTRY,
	POWERED_DESCENT,
	SURFACE_OPERATIONS,
	MISSION_COMPLETE
}

var current_phase: FlightPhase = FlightPhase.PRE_LAUNCH
var elapsed_mission_time_s: float = 0.0
var distance_traveled_km: float = 0.0
var total_trajectory_distance_km: float = 480000000.0 # ~480 million km transfer arc
var current_spacecraft_velocity_kms: float = 0.0
var fuel_consumed_kg: float = 0.0

signal phase_changed(new_phase: FlightPhase)
signal telemetry_updated(telemetry: Dictionary)

func reset_simulation() -> void:
	current_phase = FlightPhase.PRE_LAUNCH
	elapsed_mission_time_s = 0.0
	distance_traveled_km = 0.0
	current_spacecraft_velocity_kms = 0.0
	fuel_consumed_kg = 0.0
	emit_telemetry()

func advance_to_next_phase() -> void:
	if current_phase < FlightPhase.MISSION_COMPLETE:
		current_phase = (current_phase + 1) as FlightPhase
		phase_changed.emit(current_phase)
		emit_telemetry()

func get_phase_name() -> String:
	match current_phase:
		FlightPhase.PRE_LAUNCH: return "Pre-Launch Countdown & Pad Verification"
		FlightPhase.ASCENT_AND_TMI: return "Ascent & Trans-Mars Injection Burn"
		FlightPhase.INTERPLANETARY_CRUISE: return "Hohmann Interplanetary Cruise Phase"
		FlightPhase.TRAJECTORY_CORRECTION: return "Midcourse Trajectory Correction Maneuver (TCM)"
		FlightPhase.MARS_APPROACH: return "Mars Gravity Well Approach & Targeting"
		FlightPhase.ATMOSPHERIC_ENTRY: return "Hypersonic Atmospheric Entry (Seven Minutes of Terror)"
		FlightPhase.POWERED_DESCENT: return "Supersonic Parachute & Sky Crane Powered Descent"
		FlightPhase.SURFACE_OPERATIONS: return "Touchdown & Surface Exploration Operations"
		FlightPhase.MISSION_COMPLETE: return "Primary Mission Objectives Achieved"
		_: return "Unknown Phase"

func emit_telemetry() -> void:
	var progress_fraction: float = clampf(distance_traveled_km / total_trajectory_distance_km, 0.0, 1.0)
	var telemetry: Dictionary = {
		"phase": get_phase_name(),
		"phase_id": current_phase,
		"elapsed_time_days": elapsed_mission_time_s / 86400.0,
		"distance_km": distance_traveled_km,
		"distance_fraction": progress_fraction,
		"velocity_kms": current_spacecraft_velocity_kms,
		"fuel_consumed_kg": fuel_consumed_kg
	}
	telemetry_updated.emit(telemetry)
