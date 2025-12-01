# MOOSE CTLD/FAC and Convoy Scripts

This repository contains MOOSE-based scripts for enhancing DCS World missions with advanced logistics, troop transport, forward air control, and convoy management capabilities.

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

- `InitialSalvage`: Starting salvage points
- `MobileMASH.Enabled`: Deployable medical units
- `SlingLoadSalvage.Enabled`: Salvage collection from wrecks

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