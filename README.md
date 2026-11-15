# MARS DEEP — NASA Space Apps Challenge 2026
### DESIGN. LAUNCH. EXPLORE.
**An Immersive 3D Spacecraft Engineering & Planetary Exploration Simulation**

Developed for Godot Engine 4.7.2 Forward+ Desktop Renderer.

---

## 🚀 QUICK START GUIDE (JUDGES & PLAYERS)

1. **Launch the Game**:
   - Double-click `MarsDeep.exe` to run in windowed / fullscreen desktop mode.
   - Or run `MarsDeep_console.exe` to view live telemetry and diagnostic output in real-time.

2. **For Hackathon Judges (Demo Mode)**:
   - Click **DEMO / JUDGE MODE** on the Main Menu to instantly access any of the 8 simulation milestones without completing earlier engineering challenges.
   - Alternatively, press `Tab` or look at the orange header bar on top (`DEMO MODE ACTIVE • STAGE SELECTOR`) to jump between stages anytime during gameplay.
   - Demo mode unlocks all 5 campaign tiers and preserves player progression independently.

3. **Standard Campaign Playthrough**:
   - Click **START MISSION** for a fresh 20-step astronaut journey from Earth to Mars.
   - Select **BEGINNER MODE** for intuitive engineering guidance, or switch to **ADVANCED MODE** for unassisted raw formulas and strict scientific constraints.

---

## 🛰️ 20-STEP MISSION JOURNEY

1. **Cinematic Main Menu**: Procedural 3D Mars globe with dynamic atmosphere, orbiting spacecraft, 1,200 stars, and ambient aerospace audio.
2. **Mission Briefing Station**: NASA Jet Propulsion Laboratory (JPL) mission dossier, planetary alignment window, and science goals.
3. **Interactive 3D Spacecraft Designer**: Real-time 3D modular CAD editor assembling bus, power (MMRTG / Solar), propulsion, avionics, and science bay.
4. **Beginner & Advanced Engineering Lab**: Real mathematical challenges (payload mass balance, electrical generation, mission budget, DSN telemetry).
5. **Cape Canaveral Launch Complex 39A**: Fully modeled 3D launch pad, cryogenic feed lines, hold-down clamps, flame trench, and mobile launch tower.
6. **Cockpit Pre-Flight Check**: First-person instrument panel inspection, throttle lever tracking, and countdown synchronization.
7. **Interactive Ignition Sequence**: Engine spool-up rumble, exhaust plumes, hold-down clamp release, and liftoff.
8. **Under-Rocket & Tracking Cameras**: 6 dynamic camera perspectives tracking the vehicle from launch trench to high altitude.
9. **Orbital Insertion**: Transitioning through the upper atmosphere to Low Earth Orbit (LEO) with visible Earth horizon.
10. **First-Person Spacecraft Interior**: Astronaut cabin, mission clock, live life-support monitoring ($O_2$ consumption, cabin pressure, power reserve).
11. **Translunar & Trans-Mars Injection (TMI)**: Interplanetary trajectory selection (Fast Transit vs. Fuel-Saving Hohmann Ellipse).
12. **Deep Space Cruise**: Keplerian orbit propagation, real-time heliocentric distance telemetry, and solar irradiance falloff ($1/r^2$).
13. **Mid-Course Correction Burn (TCM-1)**: Manual RCS alignment and retrograde/prograde Delta-V burns.
14. **Deep Space Environmental Hazards**: Deep Space Network (DSN) communication loss and solar proton radiation storm events.
15. **Mars Orbit Insertion (MOI)**: Atmospheric approach and gravitational capture burn around the Red Planet.
16. **Atmospheric Entry, Descent & Landing (EDL)**: "Seven Minutes of Terror" with aerodynamic friction, parachute deploy, and retro-propulsion.
17. **Martian Touchdown & Site Selection**: Landing in Jezero Crater, Gale Crater, or Elysium Planitia with safe touchdown velocity checks (<1.5 m/s).
18. **Lander Egress & Rover Deployment**: Lowering the deployment ramp and rolling the 6-wheel rover onto Martian regolith.
19. **Martian Surface Exploration**: Driving across Jezero Crater delta, deploying SuperCam, PIXL, and RIMFAX to discover ancient astrobiological signatures.
20. **NASA Mission Control Debrief Room**: 3D debriefing theater with holographic Earth/Mars globes, 16-stage flight timeline, performance grades, and official NASA achievement certification.

---

## 🔬 REAL NASA TECHNOLOGIES & DATASETS

MARS DEEP models authentic aerospace systems based on publicly available NASA and JPL technical literature:

* **Launch Vehicles**:
  - *Atlas V 541* (NASA Mars 2020 / Perseverance launcher)
  - *Space Launch System (SLS) Block 1* (Artemis architecture)
  - *Falcon Heavy* (Commercial heavy lifter)
* **Spacecraft Subsystems**:
  - Multi-Mission Radioisotope Thermoelectric Generator (MMRTG)
  - UltraFlex Gallium Arsenide Solar Arrays
  - High-Gain X-Band Deep Space Network parabolic antenna
  - Bi-propellant Monomethylhydrazine / Nitrogen Tetroxide (MMH/NTO) hypergolic propulsion
* **Martian Scientific Payload**:
  - **SuperCam**: Laser-induced breakdown spectroscopy for remote mineral chemistry.
  - **PIXL**: Planetary Instrument for X-ray Lithochemistry for elemental micro-analysis.
  - **SHERLOC**: Deep UV fluorescence and Raman spectrometer for organic detection.
  - **RIMFAX**: Ground-penetrating radar imaging subsurface stratigraphy down to 10 meters.
  - **MOXIE**: Solid oxide electrolysis producing breathable $O_2$ from atmospheric $CO_2$.
  - **Mastcam-Z**: Multispectral stereoscopic zoom panoramic imaging.

---

## 🎮 CONTROLS REFERENCE

### Launch Facility (Pad 39A)
- `W` / `S` or `Up` / `Down`: Increase / Decrease throttle lever (0% to 100%).
- `Space`: Release hold-down clamps (active when throttle $\ge$ 90%).
- `1` - `6`: Cycle camera views (Full Pad, Tower Close-up, Under-Rocket Engines, Launch Control, Cockpit, Ascent Tracking).
- `Esc`: Pause Menu / Settings.

### Spacecraft Interior & Deep Space
- `1` - `5`: Switch between Cockpit View, Observation Window, External View, Nav Display, and Systems Diagnostics.
- `F`: Execute Trajectory Correction Burn.
- `R`: Orient solar arrays / aft heat shield towards the Sun during radiation storm.
- `Tab`: Demo Stage Selector (in Demo Mode).

### Mars Surface Rover
- `W` / `S` or `Up` / `Down`: Accelerate Forward / Reverse.
- `A` / `D` or `Left` / `Right`: Steer Wheels Left / Right.
- `Space`: Handbrake.
- `C`: Toggle Camera (Third-Person Chase / Mastcam First-Person / Cockpit).
- `E`: Interact / Sample Target Rock & Mineral Formations.

---

## 🧪 AUTOMATED TEST SUITE & GUI SMOKE TESTS

All systems in MARS DEEP are verified by an integrated test suite (`tests/TestRunner.gd` and `scenes/RunGUISmokeTests.tscn`):
- **110 / 110 Automated Test Assertions Passing (100% Pass Rate)**.
- **9 / 9 Core Gameplay Scenes Verified via Native GUI Smoke Tests (100% Pass Rate)**:
  1. Main Menu (`smoke_1_main_menu.png`)
  2. Launch Preparation (`smoke_2_launch_preparation.png`)
  3. Rocket Liftoff (`smoke_3_rocket_liftoff.png`)
  4. Interplanetary Flight (`smoke_4_interplanetary_flight.png`)
  5. Mars Orbit Capture & Revolution (`smoke_5_mars_orbit.png`)
  6. Mars Powered Descent & Landing (`smoke_6_mars_landing.png`)
  7. Rover Egress & Deployment Animation (`smoke_7_rover_deployment.png`)
  8. Martian Science Experiments Interface (`smoke_8_science_experiments.png`)
  9. NASA Mission Debrief Room (`smoke_9_mission_debrief.png`)
- Verified in Godot 4.7.2 headless execution and Vulkan Forward+ native desktop rendering.

---

## 📜 EDUCATIONAL & SCIENTIFIC DISCLAIMER

*MARS DEEP was created as an educational game for the NASA Space Apps Challenge 2026. While spacecraft mass figures, Delta-V equations, Keplerian orbital parameters, solar irradiance falloff, and science payloads are modeled from authentic NASA/JPL technical datasets, certain flight trajectories and landing sequences are optimized for real-time interactive gameplay and accessibility.*
