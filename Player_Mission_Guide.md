# Complete MOOSE CTLD System — Player & Mission Setup Guide

Welcome! This guide explains what logistics means in DCS, how the CTLD system lets players change the battlefield, and exactly how to use the in-game menus. It also includes a concise mission-maker setup section.

---

## What is CTLD and why it matters

- CTLD (logistics & troop transport) turns helicopters and transports into force multipliers.
- You request “crates” at Supply (Pickup) Zones, deliver them, and build combat units, SAM sites, radars, FOBs, and support vehicles.
- You can also transport troops and deploy them to hold ground or attack. 
- Every delivered asset can change the front line: new air defenses, JTACs, EWR coverage, armor pushes, or an FOB that shortens logistics legs.

[screenshot: F10 -> CTLD root menu]

Tip: The loop you’ll repeat is Request → Pickup → Transport → Deliver → Build → Fight.

---

## Getting started (players)

1) Spawn in a supported helicopter or transport.
2) Fly to a friendly Supply (Pickup) Zone.
3) Open F10 Other -> CTLD.
4) Use Logistics -> Request Crate to spawn crates; use Operations -> Build to assemble units/sites.
5) Use Navigation to get vectors and Hover Coach, and Field Tools to mark or create a quick Drop Zone.
6) Deliver, build, and watch the mission evolve.

[screenshot: Example Pickup Zone with smoke]

---

## Menu overview (matches in-game structure)

Below are the menu groups and the common actions you’ll see under each. Some options appear only when relevant (e.g., inventory enabled, crates nearby, zones configured).

### Operations

[screenshot: Operations menu open]

- Troop Transport
  - Load Troops: Load infantry while inside an ACTIVE Supply (Pickup) Zone if the mission enforces this rule.
  - Deploy Troops (Defend): Unload troops to hold the current area and defend nearby.
  - Deploy Troops (Attack): Unload troops and order them to seek and engage enemies or move toward enemy-held bases (mission-configured behavior and speed). Static/unsuitable units will hold position.
  - Notes
    - Troop loading may be restricted to Pickup Zones. The nearest zone will be shown in messages if you’re outside.
    - Deployment is blocked inside Pickup Zones when restrictions are enabled.

- Build
  - Build Here: Consumes nearby crates (within the Build Radius) and spawns the unit/site at your position. Includes a "confirm within X seconds" safety and a cooldown between builds.
  - Build (Advanced) → Buildable Near You
    - Lists everything that can be built with crates you've dropped nearby (and optionally what you're carrying, depending on mission settings).
    - Per item you'll see:
      - Build [Hold Position]: Spawns and orders the unit/site to hold.
      - Build [Attack (N m)]: Spawns and orders mobile units to seek/attack within the configured radius. Static/unsuitable units will still hold.
    - Refresh Buildable List: Re-scan nearby crates and update the list.
  - FOB-only recipes can require building inside an FOB Zone when enabled (mission-specific rule).

- MEDEVAC (if enabled in mission)
  - List Active MEDEVAC Requests: Shows all pending rescue missions with grid coordinates and time remaining
  - Nearest MEDEVAC Location: Bearing and range to the closest MEDEVAC crew needing rescue
  - Coalition Salvage Points: Display current salvage point balance for your coalition
  - Vectors to Nearest MEDEVAC: Full details (bearing, range, time remaining) to nearest crew
  - MASH Locations: Shows all active MASH (Mobile Army Surgical Hospital) zones where you can deliver crews
  - Pop Smoke at Crew Locations: Marks all active crew locations with smoke for easier visual identification
  - Pop Smoke at MASH Zones: Marks all MASH zones with smoke
  - MASH & Salvage System - Guide: In-game quick reference for the MEDEVAC system (same as in Admin/Help -> Player Guides)
  - Admin/Settings → Clear All MEDEVAC Missions: Debug/admin tool to reset all active MEDEVAC missions

### Logistics

[screenshot: Logistics -> Request Crate]

- Request Crate
  - Menu is organized by categories (e.g., Combat Vehicles, AAA, SAM short range, Support, Artillery, etc.).
  - Each entry shows how many crates are required (e.g., “M1097 Avenger (2 crates)”).
  - Requests generally require being within the maximum distance to an ACTIVE Pickup Zone.
  - When inventory is enabled, stock is tracked per zone; out-of-stock types cannot be requested at that location until resupplied.

- Recipe Info
  - Browse categories and see each item’s description; use this to plan which crates you need to build a unit or a multi-crate site.

- Request Crate (In Stock Here)
  - Appears when inventory menus are enabled and the mission-maker has exposed this view.
  - Shows only items in stock at your nearest active Supply Zone and lets you spawn them directly.
  - Includes a “Refresh” option to update the list after requests.

- Crate handling tips
  - Crates are marked with smoke at spawn.
  - Use Navigation -> Request Vectors to Nearest Crate if you lose sight of it.
  - Hover pickup: hold roughly 5–20 m AGL, very low ground speed, steady for a few seconds to auto-load.
  - Crates have a mission-configured lifetime and will self-cleanup if not used.

### Field Tools

[screenshot: Field Tools menu open]

- Create Drop Zone (AO)
  - Quickly creates a temporary Drop Zone around your current position for coordination or scripted objectives.

- Smoke My Location
  - Green / Red / White / Orange / Blue: Mark your current spot with smoke to help other players find you or the build point.

### Navigation

[screenshot: Navigation menu open]

- Hover Coach: Enable / Disable
  - In-game guidance messages to help you nail the hover pickup window (AGL, drift, speed, “hold steady” cues).

- Request Vectors to Nearest Crate
  - Prints bearing and range to the closest friendly crate.

- Vectors to Nearest Pickup Zone
  - Bearing and range to the nearest active Supply (Pickup) Zone; if none are active, you’ll get helpful direction to the nearest configured one.

### Admin/Help

[screenshot: Admin/Help menu open]

- Show CTLD Status
  - Quick summary of active crates, how many zones exist, and whether Build Confirm/Cooldown are ON.

- Draw CTLD Zones on Map / Clear CTLD Map Drawings
  - Draws labeled circles for Pickup/Drop/FOB zones on the F10 map for your coalition; clear them when you’re done.

- Debug → Enable logging / Disable logging
  - Toggles detailed logging (mission maker troubleshooting).

- Player Guides (in-game quick reference)
  - Zones – Guide
  - Inventory – How It Works
  - CTLD Basics (2-minute tour)
  - Troop Transport & JTAC Use
  - Hover Pickup & Slingloading
  - Build System: Build Here and Advanced
  - SAM Sites: Building, Repairing, and Augmenting

- Coalition Summary (if exposed by mission maker)
  - A roll-up of coalition CTLD activity (counts, highlights). Exact placement depends on mission configuration.

---

## How players influence the mission

- Build air defenses (SAM/AAA): Protect friendly FARPs/FOBs and deny enemy air.
- Deploy armor and ATGM teams: Push objectives, ambush enemy convoys, or hold key terrain.
- Build EWR/JTAC: Improve situational awareness and targeting support.
- Establish FOBs: Create forward supply hubs to shorten flight times and increase the tempo of logistics.
- Rescue MEDEVAC crews: Save downed vehicle crews, earn salvage points, and keep friendly vehicles in the fight.

[screenshot: Example built SAM site]

Practical tip: Coordinate. One player can shuttle crates while others escort or build. FOBs multiply everyone's effectiveness.

---

## MEDEVAC & Salvage System (Player Operations Guide)

The MEDEVAC (Medical Evacuation) and Salvage system adds a high-stakes rescue mission layer to logistics. When friendly ground vehicles are destroyed, their crews may survive and call for rescue. Successfully rescuing and delivering these crews to MASH zones earns your coalition Salvage Points—a critical resource that keeps logistics flowing even when supply zones run dry.

### What is MEDEVAC?

- **Vehicle destruction triggers rescue missions**: When a friendly ground vehicle (tank, APC, AA vehicle, etc.) is destroyed, the crew has a chance to survive and spawn near the wreck.
- **Time-limited rescue window**: Crews have a limited time (typically 60 minutes) to be rescued. If no one comes, they're KIA and the vehicle is permanently lost.
- **Coalition-wide benefit**: Any helicopter pilot can attempt the rescue. Successful delivery to MASH earns salvage points for the entire coalition.

### How the rescue workflow works

1. **Vehicle destroyed → Crew spawns** (after a delay, typically 5 minutes to let the battle clear)
   - Crew spawns near the wreck with a small offset toward the nearest enemy
   - Invulnerability period during announcement (crews can't be killed immediately)
   - MEDEVAC request broadcast to coalition with grid coordinates and salvage value
   - Map marker created (if enabled) showing location and time remaining

2. **Navigate to crew location**
   - Use Operations → MEDEVAC → Vectors to Nearest MEDEVAC for bearing and range
   - Or check Navigation → Vectors to Nearest MEDEVAC Crew
   - Crews pop smoke when they detect approaching helicopters (typically within 8 km)
   - Watch for humorous greeting messages when you get close!

3. **Load the crew**
   - Hover nearby and load troops normally (Operations → Troop Transport → Load Troops)
   - System automatically detects MEDEVAC crew and marks them as rescued
   - **Original vehicle respawns at its death location** (if enabled), fully repaired and ready to fight
   - You'll see a confirmation message with crew size and salvage value

4. **Deliver to MASH zone**
   - Fly to any friendly MASH (Mobile Army Surgical Hospital) zone
   - Use Operations → MEDEVAC → MASH Locations or Navigation → Vectors to Nearest MASH
   - Deploy troops inside the MASH zone (Operations → Troop Transport → Deploy)
   - **Salvage points automatically awarded** to your coalition
   - Coalition-wide message announces the delivery, points earned, and new total

### Warning system

The mission keeps you informed of time-critical rescues:
- **15-minute warning**: "WARNING: [vehicle] crew at [grid] - rescue window expires in 15 minutes!"
- **5-minute warning**: "URGENT: [vehicle] crew at [grid] - rescue window expires in 5 minutes!"
- **Timeout**: If rescue window expires, crew is KIA and vehicle is permanently lost

### MASH Zones (Mobile Army Surgical Hospital)

**Fixed MASH zones** are pre-configured by the mission maker at friendly bases or FARPs. These are always active and visible on the map (use Admin/Help → Draw CTLD Zones to see them).

**Mobile MASH** can be built by players using MASH crates from the logistics catalog:
- Request and build Mobile MASH crates like any other unit
- Creates a new delivery zone with radio beacon
- Perfect for forward operations near active combat zones
- Multiple mobile MASHs can be deployed to reduce delivery times
- If destroyed, that MASH zone stops accepting deliveries

### Salvage Points: The economic engine

**Earning salvage**:
- Each vehicle type has a salvage value (typically 1 point per crew member)
- Deliver crews to MASH to earn points for your coalition
- Coalition-wide pool: everyone benefits from everyone's rescues

**Using salvage**:
- When you request crates and the supply zone is OUT OF STOCK, salvage automatically applies (if enabled)
- System consumes salvage points equal to the item's cost
- Lets you build critical items even when supply lines are exhausted
- Check current balance: Operations → MEDEVAC → Coalition Salvage Points

**Strategic value**:
- High-value vehicles (tanks, AA systems) typically award more salvage
- Prioritize rescues based on salvage value and proximity
- Mobile MASH deployment near combat zones multiplies salvage income
- Salvage can unlock mission-critical capabilities when inventory runs low

### Crew survival mechanics (mission-configurable)

- **Survival chance**: Configurable per coalition (default ~50%). Not every destroyed vehicle spawns a crew.
- **MANPADS chance**: Some crew members may spawn with anti-air weapons (default ~10%), providing limited self-defense
- **Crew size**: Varies by vehicle type (catalog-defined). Tanks typically have 3-4 crew, APCs 2-3.
- **Crew defense**: Crews will return fire if engaged during rescue (can be disabled)
- **Invulnerability**: Crews are typically immortal during the announcement delay and often remain protected until rescue to prevent instant death

### Best practices for MEDEVAC operations

1. **Monitor requests actively**: Use Operations → MEDEVAC → List Active MEDEVAC Requests to see all pending missions
2. **Prioritize by value and time**: High salvage + low time remaining = top priority
3. **Deploy Mobile MASH forward**: Reduce delivery time by placing MASH near active combat zones
4. **Coordinate with team**: Share MEDEVAC locations. One player can rescue while another delivers to MASH.
5. **Use smoke marking**: Operations → MEDEVAC → Pop Smoke at Crew Locations marks all crews with smoke
6. **Check salvage before major operations**: Know your coalition's salvage balance before pushing objectives
7. **Risk assessment**: Don't sacrifice your aircraft for low-value rescues in hot zones. Dead rescuer = no rescue.

### MEDEVAC menu quick reference (Operations → MEDEVAC)

- **List Active MEDEVAC Requests**: Overview of all pending rescues (grid, vehicle type, time left)
- **Nearest MEDEVAC Location**: Quick bearing/range to closest crew
- **Vectors to Nearest MEDEVAC**: Detailed navigation info with time remaining
- **Coalition Salvage Points**: Check current balance
- **MASH Locations**: Shows all active MASH zones (fixed and mobile)
- **Pop Smoke at Crew Locations**: Visual marking for all active crews
- **Pop Smoke at MASH Zones**: Visual marking for all delivery zones
- **MASH & Salvage System - Guide**: In-game reference (same content available in Admin/Help → Player Guides)

### MEDEVAC statistics (if enabled)

Some missions track detailed statistics available via Admin/Help → Show MEDEVAC Statistics:
- Crews spawned, rescued, delivered to MASH
- Timed out and killed in action
- Vehicles respawned
- Salvage earned, used, and current balance

[screenshot: MEDEVAC request message with grid coordinates]
[screenshot: Operations → MEDEVAC menu]
[screenshot: Mobile MASH deployed with beacon]

---

## How players influence the mission

- Build air defenses (SAM/AAA): Protect friendly FARPs/FOBs and deny enemy air.
- Deploy armor and ATGM teams: Push objectives, ambush enemy convoys, or hold key terrain.
- Build EWR/JTAC: Improve situational awareness and targeting support.
- Establish FOBs: Create forward supply hubs to shorten flight times and increase the tempo of logistics.
- Rescue MEDEVAC crews: Save downed vehicle crews, earn salvage points, and keep friendly vehicles in the fight.

[screenshot: Example built SAM site]

Practical tip: Coordinate. One player can shuttle crates while others escort or build. FOBs multiply everyone's effectiveness.

---

## Mission setup (for mission makers)

Keep this section short and focused. You can find the defaults and toggles inside:
- `Moose_CTLD_Pure/Moose_CTLD.lua` (main CTLD implementation; see the `CTLD.Config` table)
- `Moose_CTLD_Pure/Moose_CTLD_FAC.lua` (optional FAC/RECCE support)
- `Moose_CTLD_Pure/catalogs/` (example catalogs with ready-to-use recipes)
- `Moose_CTLD_Pure/init_mission_dual_coalition.lua` (ready-to-use minimal init for BLUE+RED)

### Load order (Do Script File in Mission Editor)

1) `Moose.lua`
2) `Moose_CTLD.lua`
3) A catalog file from `/catalogs/`
4) `Moose_CTLD_FAC.lua` (optional FAC/RECCE)
5) Your mission init block (you can use `Moose_CTLD_Pure/init_mission_dual_coalition.lua` as-is or adapt it)

<img width="390" height="170" alt="image" src="https://github.com/user-attachments/assets/fd468f5c-5240-47f0-8603-a7996e20ba7e" />


Minimal snippet (example) — keep it to the point:

- Create a CTLD instance per coalition with: CoalitionSide, AllowedAircraft, Zones (Pickup/Drop/FOB definitions), and key toggles.
- Optionally create a FAC module instance and run it.
- Optionally merge a crate catalog.

Hint: See the shipped `init_mission_dual_coalition.lua` for a clean example of both BLUE and RED.

### Zones you must create in the Mission Editor

- Pickup (Supply): e.g., `ALPHA` (BLUE), `DELTA` (RED)
- Drop: e.g., `BRAVO` (BLUE), `ECHO` (RED)
- FOB: e.g., `CHARLIE` (BLUE), `FOXTROT` (RED)
- MASH (optional, for MEDEVAC): e.g., `MASH_BLUE_1`, `MASH_RED_1` (accepts crew deliveries for salvage points)

Use the names referenced by your init script. The example init uses flags to control active/inactive state.

[screenshot: Trigger zones for Pickup/Drop/FOB/MASH]

### Frequently configured options (where to change)

All of the following live under `CTLD.Config` in `Moose_CTLD.lua` or can be provided in the table passed to `_MOOSE_CTLD:New({...})` in your init script.

- Logistics rules
  - `RequirePickupZoneForCrateRequest`: Enforce being near an ACTIVE Supply Zone to request crates
  - `RequirePickupZoneForTroopLoad`: Enforce being inside a Supply Zone to load troops
  - `PickupZoneMaxDistance`: Max distance to the nearest ACTIVE zone for crate requests
  - `ForbidDropsInsidePickupZones`: Block dropping crates inside Supply Zones
  - `ForbidTroopDeployInsidePickupZones`: Block troop deployment inside Supply Zones
  - `ForbidChecksActivePickupOnly`: If true, restrictions apply only to ACTIVE zones

- Building behavior
  - `BuildRadius`: How far to search for crates around the player when building
  - `BuildSpawnOffset`: Push spawn a few meters ahead of the aircraft to avoid collisions
  - `BuildConfirmEnabled` + `BuildConfirmWindowSeconds`: Double-press safety to prevent accidental builds
  - `BuildCooldownEnabled` + `BuildCooldownSeconds`: Per-group cooldown after a successful build
  - `RestrictFOBToZones`: When true, FOB-only builds must occur inside an FOB Zone
  - `AutoBuildFOBInZones`: When true, crates for FOBs inside an FOB Zone can auto-build

- Inventory system (per-zone stock)
  - `Inventory.Enabled`: Track stock per Supply Zone and FOB
  - `Inventory.ShowStockInMenu`: Show counts in menu labels
  - `Inventory.HideZeroStockMenu`: Enable the special “In Stock Here” menu at nearest zone
  - `Inventory.FOBStockFactor`: % of initial stock seeded when a new FOB is built

- Hover & pickup quality-of-life
  - `HoverCoachConfig`: Message timing and thresholds for the in-game hover guidance
  - `TroopSpawnOffset`: Spawn troops slightly forward to avoid overlaps

- AI behavior for Attack builds
  - `AttackAI.VehicleSearchRadius`: How far spawned vehicles look for enemies when ordered to Attack
  - `AttackAI.MoveSpeedKmh`: Movement speed for Attack orders

- MEDEVAC & Salvage system (optional feature)
  - `MEDEVAC.Enabled`: Master switch for the rescue/salvage system
  - `MEDEVAC.CrewSurvivalChance`: Per-coalition probability that destroyed vehicle crews survive (0.0-1.0)
  - `MEDEVAC.ManPadSpawnChance`: Probability crews spawn with MANPADS for self-defense
  - `MEDEVAC.CrewSpawnDelay`: Seconds after death before crew spawns (allows battle to clear)
  - `MEDEVAC.CrewTimeout`: Max time for rescue before crew is KIA (default 3600 = 1 hour)
  - `MEDEVAC.CrewImmortalDuringDelay`: Invulnerability during announcement delay
  - `MEDEVAC.PopSmokeOnApproach`: Auto-smoke when helos get close (default true)
  - `MEDEVAC.RespawnOnPickup`: Original vehicle respawns when crew is rescued (default true)
  - `MEDEVAC.Salvage.Enabled`: Enable salvage points economy
  - `MEDEVAC.Salvage.AutoApply`: Auto-use salvage for out-of-stock items (default true)
  - `MEDEVAC.MapMarkers.Enabled`: Create F10 map markers for active MEDEVAC requests
  - `Zones.MASHZones`: Configure fixed MASH delivery zones (Mobile MASH can be built by players)

- Menus
  - `UseGroupMenus`: Per-group F10 menus (recommended)
  - `UseCategorySubmenus`: Organize Request Crate/Recipe Info by category
  - `PickupZoneSmokeColor`: Color for crate spawn smoke marks

### Crate catalog (recipes)

- Use one of the provided catalogs under `Moose_CTLD_Pure/catalogs/` or your own.
- Each entry defines a display label, side, category, stock, and a build function.
- Multi-crate “SITE” entries build multi-unit groups (SAM sites or composite systems).
- Typical workflow
  - Load your chosen catalog after `Moose_CTLD.lua`.
  - Merge it into each CTLD instance you created.

[screenshot: Request Crate categories]

### Dual-coalition setup

- Instantiate two CTLD instances (one per side), each with its own zone names and smoke colors.
- Instantiate two FAC modules if you want auto-lase/RECCE for both sides.
- The included `init_mission_dual_coalition.lua` shows a minimal working setup.

### FAC/RECCE (optional, from `Moose_CTLD_FAC.lua`)

- What it adds
  - Auto-lase with configurable laser codes, IR markers, map marks
  - Manual target lists, quick multi-strike helper
  - Artillery/Naval/Air tasking (HE/illum/mortar, carpet/TALD prompts)
  - RECCE sweeps: detects and marks units with DMS/MGRS
- Player usage
  - Look for an F10 FAC/RECCE menu in qualifying aircraft or groups
- Mission knobs
  - CoalitionSide, auto-lase behavior, code reservations, marker type/color, and on-station logic are configurable in `Moose_CTLD_FAC.lua` or via `:New()` overrides

### Sanity checks and troubleshooting

- Use Admin/Help -> Show CTLD Status to verify counts and toggles quickly.
- Draw zones to confirm names/positions match your intent.
- If crates don’t spawn: check zone active state, distance to zone, and inventory stock.
- If builds don’t trigger: check Build Radius, confirm window, cooldown, and that the crates match the recipe.

---

## Screenshot ideas (drop your captures in the placeholders above)

- CTLD root menu with the five groups (Operations, Logistics, Field Tools, Navigation, Admin/Help)
- Request Crate with category submenus visible
- Build (Advanced) -> Buildable Near You list
- Hover Coach prompt during a near-perfect hover
- Vectors message to a crate / pickup zone
- Zone drawings on the F10 map (Pickup/Drop/FOB labeled)
- In Stock Here list (if enabled)
- Example SAM site placed after a build

---

## Appendix: File locations and names

- Main CTLD: `Moose_CTLD_Pure/Moose_CTLD.lua`
- FAC/RECCE: `Moose_CTLD_Pure/Moose_CTLD_FAC.lua`
- Example dual-coalition init: `Moose_CTLD_Pure/init_mission_dual_coalition.lua`
- Catalogs: `Moose_CTLD_Pure/catalogs/`

No large code is required; most options are cleanly exposed in the config tables. Keep snippets tiny when needed.
