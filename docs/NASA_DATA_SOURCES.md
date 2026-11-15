# NASA DATA SOURCES & MISSION REFERENCE DOCUMENTATION
## MARS DEEP — Educational Mars Mission Design & Simulation Game

### 1. Planetary & Physical Constants
All planetary parameters in MARS DEEP are aligned with official NASA Planetary Fact Sheets:
- **Mars Physical Fact Sheet**: NASA Goddard Space Flight Center (Dr. David R. Williams)
  - Mean Radius: 3,389.5 km
  - Volumetric Mean Radius: 3,389.5 km
  - Mass: 6.4171 × 10²³ kg
  - Surface Gravity: 3.72076 m/s² (0.379 g)
  - Standard Gravitational Parameter (μ): 42,828.375 km³/s²
  - Semi-major Axis: 1.52366 AU (227,939,200 km)
  - Perihelion: 1.3814 AU (206,620,000 km)
  - Aphelion: 1.6660 AU (249,230,000 km)
  - Orbital Period: 686.980 Earth days (668.599 Martian Sols)
  - Solar Day (Sol): 24 hours, 39 minutes, 35.244 seconds
  - Solar Irradiance at Mean Distance: 586.2 W/m² (at 1 AU: 1361 W/m²)
  - Surface Atmospheric Pressure: ~610 Pa (0.006 atm) mean (varying 400 - 870 Pa seasonally)
  - Atmospheric Composition: 95.32% CO₂, 2.6% N₂, 1.9% Ar, 0.16% O₂, 0.08% CO

### 2. Historical & Active NASA Missions
- **Mars 2020 Perseverance Rover**:
  - Jet Propulsion Laboratory (JPL) Mission Architecture: Cruise Stage, Aeroshell, Descent Stage (Sky Crane), Rover Platform.
  - Science Payload: Mastcam-Z, SuperCam, PIXL, SHERLOC, MOXIE, MEDA, RIMFAX.
  - Power: Multi-Mission Radioisotope Thermoelectric Generator (MMRTG) using 4.8 kg Plutonium-238 dioxide, producing ~110 W electrical at launch.
  - Entry, Descent, and Landing (EDL): Range Trigger, Terrain-Relative Navigation (TRN), 21.5-meter Disk-Gap-Band supersonic parachute, 8-engine powered descent vehicle.
- **Mars Science Laboratory (Curiosity Rover)**:
  - Launch Vehicle: United Launch Alliance (ULA) Atlas V 541.
  - Trans-Mars Injection C3: ~16.5 km²/s².
  - Cruise Duration: 254 days (Launch: Nov 26, 2011; Landing: Aug 6, 2012).
- **Mars Reconnaissance Orbiter (MRO)**:
  - Instruments: HiRISE (High Resolution Imaging Science Experiment), CRISM, SHARAD.
  - Telecom: 3-meter High-Gain Antenna, 100 W X-band Traveling Wave Tube Amplifier (TWTA), Electra UHF relay package.
- **InSight Mars Lander**:
  - Solar Power: Twin 2.15-meter diameter UltraFlex solar arrays (~600 W at perihelion on clean panels).
  - Geophysics: SEIS (Seismic Experiment for Interior Structure), HP³ heat flow probe.

### 3. Engineering & Orbital Mechanics Formulations
- **Tsiolkovsky Rocket Equation**:
  $$\Delta v = I_{sp} \cdot g_0 \cdot \ln\left(\frac{m_0}{m_f}\right)$$
  Where $g_0 = 9.80665\ \text{m/s}^2$, $m_0$ is total initial wet mass, and $m_f$ is final dry mass.
- **Hohmann Transfer Orbit**:
  $$a_{transfer} = \frac{r_{Earth} + r_{Mars}}{2} = \frac{1.000 + 1.524}{2} = 1.262\ \text{AU}$$
  $$T_{transit} = \frac{1}{2} \sqrt{a_{transfer}^3} \times 365.25\ \text{days} \approx 259\ \text{days}$$
- **Inverse-Square Solar Irradiance Law**:
  $$S(r) = \frac{S_0}{r^2}$$
  Where $S_0 = 1361\ \text{W/m}^2$ at 1.0 AU.
- **Electromagnetic Propagation Latency**:
  $$t = \frac{d}{c}$$
  Where $c \approx 299,792.458\ \text{km/s}$, resulting in one-way time delay between 3.1 minutes (closest approach, 56M km) and 22.3 minutes (superior conjunction, 401M km).
- **Aerodynamic Terminal Velocity (Thin Atmosphere EDL)**:
  $$v_t = \sqrt{\frac{2 \cdot m \cdot g}{\rho \cdot A \cdot C_d}}$$

### 4. Public Repositories & Data Portals
- NASA Planetary Data System (PDS): https://pds.nasa.gov/
- NASA Jet Propulsion Laboratory (JPL): https://www.jpl.nasa.gov/missions
- NASA SPICE Toolkit & Ephemerides: https://naif.jpl.nasa.gov/naif/
- NASA Eyes on the Solar System: https://eyes.nasa.gov/
