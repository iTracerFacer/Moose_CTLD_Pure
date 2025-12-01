# MOOSE CTLD/FAC and Convoy Scripts

This repository contains MOOSE-based scripts for enhancing DCS World missions with advanced logistics, troop transport, forward air control, and convoy management capabilities. CTLD was orignialy created by Ciribob using the MIST framework. I've converted his work to only use moose and have added many features included integrated MEDEVAC and Salvage system which both can have a direct impact on the state of a mission. 

## Overview

### MOOSE CTLD (Combat Troop Landing and Deployment)

MOOSE CTLD is a comprehensive logistics and troop transport system that transforms helicopters and transport aircraft into force multipliers. Players can:

- **Request and transport crates** containing vehicles, weapons, and equipment
- **Load and deploy troops** for defensive or offensive operations
- **Build forward operating bases (FOBs)** and upgrade them to functional forward arming and refueling points (FARPs)
- **Manage MEDEVAC operations** with salvage point rewards
- **Sling-load salvage** from destroyed enemy units
- **Receive hover coaching** for precise crate pickup
- **Access JTAC support** for laser designation

The system includes immersive features like:
- Dynamic zone activation/deactivation
- Inventory management per pickup zone
- Salvage-based economy for advanced builds
- Mobile MASH units for casualty evacuation
- Comprehensive F10 menu interface

### FAC (Forward Air Controller)

The FAC module provides full FAC/RECCE capabilities including:

- **Auto-detection** of FAC aircraft by group name or unit type
- **Auto-lasing** with configurable laser codes and marker types
- **Target scanning** and prioritization (AA/SAM detection)
- **Artillery and naval gunfire support**
- **Bomber/fighter tasking** for strikes
- **RECCE sweeps** with map marks and target storage
- **Carpet bombing** and TALD deployment
- **Event-driven tasking** via map marks

### Convoy System

The Convoy script implements a dynamic convoy escort system featuring:

- **Player-initiated spawns** via F10 map marks near CTLD zones
- **Road-based navigation** to player-defined destinations
- **Threat detection and response** with automatic halting
- **CAS (Close Air Support) requests** when under attack
- **Route integrity monitoring** to prevent waypoint manipulation
- **Coalition-specific operations** with configurable templates

## Integrated MEDEVAC and Salvage Systems

The CTLD system includes two interconnected economy systems that create dynamic mission progression and resource management.

### MEDEVAC (Medical Evacuation) System

The MEDEVAC system simulates casualty evacuation and medical support:

#### How It Works
- When enemy ground vehicles are destroyed, surviving crew members spawn at the wreck location
- Crews broadcast distress calls with their grid coordinates and request immediate evacuation
- Players must respond quickly - crews have a limited survival window (typically 15-30 minutes)
- Failed evacuations result in crew KIA and permanent vehicle loss

#### Evacuation Process
1. **Receive Alert**: Coalition receives MEDEVAC request with grid coordinates and crew count
2. **Locate Crew**: Use F10 menu to get vectors to stranded personnel
3. **Pickup**: Land or hover near crew location and hold position to load casualties
4. **Transport**: Fly crew to an active MASH (Mobile Army Surgical Hospital) zone
5. **Delivery**: Land in MASH zone and hold for offloading (typically 25 seconds)
6. **Reward**: Earn salvage points based on crew size and vehicle type

#### Salvage Points
- Salvage points are earned by successfully delivering MEDEVAC crews to MASH zones
- Points accumulate per coalition and are shared across all players
- Higher-value vehicles (tanks, IFVs) provide more salvage points
- Points can be used to "purchase" out-of-stock items from the crate catalog

### Sling-Load Salvage System

The salvage system creates opportunistic resource collection from battlefield wreckage:

#### How It Works
- When enemy units are destroyed, there's a chance (configurable per coalition) that salvageable wreckage spawns
- Wreckage appears as cargo crates with weight, value, and expiration timers
- Players can sling-load these crates using helicopters and deliver them to salvage collection zones

#### Salvage Categories
- **Light Salvage**: 500-1000kg, 1-2 points (50% spawn chance)
- **Medium Salvage**: 2501-5000kg, 5-10 points (30% spawn chance)  
- **Heavy Salvage**: 5001-8000kg, 15-24 points (15% spawn chance)
- **Super Heavy Salvage**: 8001-12000kg, 32-48 points (5% spawn chance)

#### Collection Process
1. **Locate Wreckage**: Receive coalition alert with grid coordinates and estimated value
2. **Sling Load**: Hover over crate and hook it with helicopter sling
3. **Transport**: Fly crate to an active salvage collection zone
4. **Delivery**: Release sling within zone boundaries to complete delivery
5. **Condition Bonus**: Intact deliveries receive full value; damaged crates lose value

#### Dynamic Features
- **Expiration Timers**: Crates deteriorate over time (default 1 hour) if not collected
- **Weight Simulation**: Heavier crates affect helicopter performance
- **Zone Restrictions**: Must deliver to designated salvage zones for credit
- **Condition Multipliers**: Undamaged (1.5x), Damaged (1.0x), Heavy Damage (0.5x)

### Strategic Impact

These systems create several gameplay dynamics:

#### Resource Scarcity
- Limited initial salvage points encourage early MEDEVAC operations
- Out-of-stock items can only be unlocked through salvage accumulation
- Players must balance combat operations with logistics support

#### Mission Progression
- Successful MEDEVAC operations provide resources for advanced builds
- Salvage collection creates incentives for aggressive operations
- Failed evacuations represent permanent losses that affect mission outcome

#### Coalition Competition
- Salvage points are tracked per coalition
- Both sides can collect salvage from enemy wrecks
- Resource advantages can shift based on operational success

#### Risk/Reward Balance
- High-value targets provide more salvage but are more dangerous
- Time pressure on MEDEVAC creates urgency without being punitive
- Salvage collection rewards thorough battlefield cleanup

## Setup Instructions

### Prerequisites

1. **DCS World** with MOOSE framework installed
2. Mission Editor access for zone creation and script loading

### Script Load Order

Load scripts in the Mission Editor in this exact order:

1. `Moose.lua` (MOOSE framework)
2. `Moose_CTLD.lua` (Core CTLD functionality)
3. `catalogs/Moose_CTLD_Catalog.lua` or `catalogs/Moose_CTLD_Catalog_LowCounts.lua` (Optional but recommended - provides crate recipes)
4. `Moose_CTLD_FAC.lua` (Optional - adds FAC capabilities)
5. `Moose_Convoy.lua` (Optional - adds convoy system)
6. Your initialization script (see examples below)

### Mission Editor Setup

#### Required Zones

Create the following trigger zones in the Mission Editor:

- **Pickup Zones**: Where players request crates and load troops (e.g., `PICKUP_BLUE_MAIN`)
- **Drop Zones**: Designated areas for crate deployment (e.g., `DROP_BLUE_1`)
- **FOB Zones**: Areas where FOBs can be built (e.g., `FOB_BLUE_A`)
- **MASH Zones**: Medical evacuation zones (e.g., `MASH_Alpha`)
- **Salvage Zones**: Areas for delivering sling-loaded salvage (e.g., `SALVAGE_1`)

#### Zone Configuration

Each zone can be configured with:
- `flag`: Mission flag number for activation control
- `activeWhen`: Flag value that activates the zone (0 = always active)
- `smoke`: Smoke color for visual marking
- `radius`: Zone radius in meters
- `freq`: Radio frequency for beacons (MASH zones)

### CTLD Initialization

Create a DO SCRIPT action in your mission with the following structure:

```lua
-- Check for required dependencies
if not _MOOSE_CTLD then
    env.info("[INIT] MOOSE CTLD not loaded!")
    return
end

-- Configuration table
local ctldConfig = {
    CoalitionSide = coalition.side.BLUE,  -- BLUE or RED
    
    -- Core settings
    AllowedAircraft = {
        'UH-1H', 'Mi-8MTV2', 'Mi-24P', 'SA342M', 'SA342L', 
        'SA342Minigun', 'UH-60L', 'CH-47Fbl1', 'CH-47F', 'Mi-17'
    },
    
    -- MEDEVAC system
    MEDEVAC = {
        Enabled = true,
        InitialSalvage = 25,
        MobileMASH = {
            Enabled = true,
            ZoneRadius = 300,
            BeaconFrequency = '32.0 FM',
            AnnouncementInterval = 300
        }
    },
    
    -- Zone definitions
    Zones = {
        PickupZones = {
            { name = 'PICKUP_BLUE_MAIN', flag = 9001, activeWhen = 0 }
        },
        DropZones = {
            { name = 'DROP_BLUE_1', flag = 9002, activeWhen = 0 }
        },
        FOBZones = {
            { name = 'FOB_BLUE_A', flag = 9003, activeWhen = 0 }
        },
        MASHZones = {
            { name = 'MASH_Alpha', freq = '251.0 AM', radius = 300, flag = 9010, activeWhen = 0 }
        },
        SalvageDropZones = {
            { name = 'SALVAGE_1', radius = 300, flag = 9020, activeWhen = 0 }
        }
    },
    
    -- Additional options
    BuildRequiresGroundCrates = true,
    LogLevel = 2,  -- 0=NONE, 1=ERROR, 2=INFO, 3=VERBOSE, 4=DEBUG
}

-- Create CTLD instance
local ctld = _MOOSE_CTLD:New(ctldConfig)

-- Optional: Load crate catalog
if _CTLD_EXTRACTED_CATALOG then
    ctld:MergeCatalog(_CTLD_EXTRACTED_CATALOG)
end
```

### FAC Initialization (Optional)

Add FAC support after CTLD initialization:

```lua
if _MOOSE_CTLD_FAC then
    local facConfig = {
        CoalitionSide = coalition.side.BLUE,
        Arty = { Enabled = false },  -- Enable/disable artillery support
    }
    
    local fac = _MOOSE_CTLD_FAC:New(ctld, facConfig)
    -- Optional: Add reconnaissance zones
    -- fac:AddRecceZone({ name = 'RECCE_BLUE_1' })
    fac:Run()
end
```

### Convoy System Setup (Optional)

Configure the Convoy script at the top of `Moose_Convoy.lua`:

```lua
-- Template groups (must exist as late-activated in Mission Editor)
CONVOY_TEMPLATE_NAMES = {
    "Convoy Template 1",
    "Convoy Template 2",
}

-- CTLD integration
CTLD_INSTANCE_NAME_BLUE = "ctldBlue"  -- Variable name of your BLUE CTLD instance
CTLD_INSTANCE_NAME_RED = "ctldRed"    -- Variable name of your RED CTLD instance
USE_CTLD_ZONES = true

-- Destination control
PLAYER_CONTROLLED_DESTINATIONS = true  -- false = use static destinations

-- Keywords for map marks
CONVOY_SPAWN_KEYWORD = "convoy start"
CONVOY_DEST_KEYWORD = "convoy end"
```

### Complete Dual-Coalition Example

See `Moose_CTLD_Init_DualCoalitions.lua` for a complete example setting up both BLUE and RED coalitions with all systems enabled.

## Player Usage

### CTLD Operations

1. **Spawn** in a supported helicopter/transport aircraft
2. **Fly to a Pickup Zone** (marked with smoke)
3. **Access F10 Menu** → CTLD
4. **Request Crates** under Logistics → Request Crate
5. **Load Crates** by hovering or landing near them
6. **Transport and Deploy** crates at desired locations
7. **Build Units** using Operations → Build menus
8. **Load/Deploy Troops** for combat operations

#### MEDEVAC Operations
1. **Monitor for Alerts** when enemy vehicles are destroyed
2. **Get Vectors** using F10 → CTLD → Navigation → MEDEVAC Vectors
3. **Pickup Crews** by landing/hovering at their location and holding position
4. **Transport to MASH** zone (marked with beacons and smoke)
5. **Deliver** by landing in MASH zone and holding for offloading
6. **Earn Salvage Points** for successful deliveries

#### Salvage Collection
1. **Receive Alerts** when enemy wrecks spawn salvage opportunities
2. **Locate Crates** using F10 → CTLD → Navigation → Salvage Vectors
3. **Sling Load** by hovering over crate and hooking with helicopter
4. **Transport to Zone** fly to active salvage collection zone
5. **Deliver** by releasing sling within zone boundaries
6. **Check Status** using F10 → CTLD → Logistics → Salvage Status

### FAC Operations

1. **Spawn** in a FAC-configured aircraft (group name containing "AFAC", "RECON", or "RECCE")
2. **Access F10 Menu** → FAC/RECCE
3. **Enable Auto-Lase** for automatic target designation
4. **Scan for Targets** and select priority threats
5. **Request Support** (artillery, naval gunfire, air strikes)

### Convoy Operations

1. **Place Map Mark** with "convoy start" near a CTLD zone to spawn
2. **Place Destination Mark** with "convoy end" to set route
3. **Monitor Progress** via coalition messages
4. **Provide CAS** when convoys request air support
5. **Redirect** active convoys with additional destination marks

## Configuration Options

### CTLD Core Settings

- `CoalitionSide`: BLUE or RED coalition
- `LogLevel`: Logging verbosity (0-4)
- `MessageDuration`: On-screen message display time
- `BuildRadius`: Distance for collecting crates to build
- `CrateLifetime`: Auto-cleanup time for undelivered crates
- `Inventory.Enabled`: Per-zone stock tracking

### Aircraft Capacities

Configure load limits per aircraft type:

```lua
AircraftCapacities = {
    ['UH-1H'] = { maxCrates = 3, maxTroops = 11, maxWeightKg = 1800 },
    ['CH-47F'] = { maxCrates = 10, maxTroops = 33, maxWeightKg = 12000 },
}
```

### MEDEVAC System

- `InitialSalvage`: Starting salvage points for the coalition
- `MobileMASH.Enabled`: Enable deployable MASH units via crate builds
- `MobileMASH.ZoneRadius`: Radius of MASH zones in meters
- `MobileMASH.BeaconFrequency`: Radio frequency for MASH beacons
- `MobileMASH.AnnouncementInterval`: How often MASH locations are announced (seconds)

### Sling-Load Salvage System

- `SlingLoadSalvage.Enabled`: Master switch for salvage system
- `SlingLoadSalvage.SpawnChance`: Probability of salvage spawning when enemy units die (per coalition)
- `SlingLoadSalvage.WeightClasses`: Configuration for salvage categories and values
- `SlingLoadSalvage.CrateLifetime`: Time before salvage crates expire (seconds)
- `SlingLoadSalvage.MaxActiveCrates`: Maximum simultaneous salvage crates per coalition
- `SlingLoadSalvage.ConditionMultipliers`: Value modifiers based on delivery condition

## Troubleshooting

### Common Issues

1. **No CTLD menu**: Check script load order and Moose installation
2. **Cannot request crates**: Ensure within range of active Pickup Zone
3. **Build fails**: Verify sufficient crates and correct zone restrictions
4. **FAC not working**: Check aircraft group naming and FAC script loading

### Debug Logging

Set `LogLevel = 4` in configuration for detailed debug information in `dcs.log`.

### Zone Validation

Use the included validation tools to ensure zones are properly configured and accessible.

## Contributing

This is a pure-MOOSE implementation focused on template-free setup and comprehensive logistics simulation. Contributions should maintain compatibility with the MOOSE framework and follow the established code patterns.

## License

See individual script headers for licensing information. This implementation is based on original CTLD work by Ciribob with MOOSE adaptations.