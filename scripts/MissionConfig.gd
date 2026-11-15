class_name MissionConfig
extends RefCounted

## MissionConfig.gd - Physical constants, celestial orbital elements, and mission baselines for MARS DEEP.

# Universal and Celestial Physical Constants
const SPEED_OF_LIGHT: float = 299792.458 # km/s
const STANDARD_GRAVITY: float = 9.80665 # m/s^2 (Earth g0)
const MARS_SURFACE_GRAVITY: float = 3.72076 # m/s^2
const SOLAR_CONSTANT_EARTH: float = 1361.0 # W/m^2 (1 AU)
const STEFAN_BOLTZMANN: float = 5.670374e-8 # W/(m^2 K^4)
const GRAVITATIONAL_CONSTANT: float = 6.67430e-11 # m^3/(kg s^2)

# Martian Orbital and Atmospheric Parameters
const MARS_MASS_KG: float = 6.4171e23
const MARS_MEAN_RADIUS_KM: float = 3389.5
const MARS_SEMI_MAJOR_AU: float = 1.52366
const MARS_PERIHELION_AU: float = 1.3814
const MARS_APHELION_AU: float = 1.6660
const MARS_ORBITAL_PERIOD_DAYS: float = 686.980
const MARS_SOL_HOURS: float = 24.65979
const MARS_ATMOSPHERE_SURFACE_DENSITY: float = 0.015 # kg/m^3
const MARS_ATMOSPHERE_SURFACE_PRESSURE: float = 610.0 # Pa

# Mission Archetypes
enum MissionArchetype {
	ORBITER,
	LANDER,
	ROVER,
	SAMPLE_RETURN
}

static func get_archetype_name(archetype: MissionArchetype) -> String:
	match archetype:
		MissionArchetype.ORBITER: return "Orbital Reconnaissance"
		MissionArchetype.LANDER: return "Stationary Lander"
		MissionArchetype.ROVER: return "Surface Rover"
		MissionArchetype.SAMPLE_RETURN: return "Sample Return Lander"
		_: return "Unknown Archetype"
