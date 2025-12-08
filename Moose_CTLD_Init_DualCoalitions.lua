-- init_mission_dual_coalition.lua
-- Use in Mission Editor with DO SCRIPT FILE load order:
--  1) Moose.lua
--  2) Moose_CTLD_Pure/Moose_CTLD.lua
--  3) Moose_CTLD_Pure/catalogs/CrateCatalog_CTLD_Extract.lua  -- optional but recommended catalog with BLUE+RED items (_CTLD_EXTRACTED_CATALOG)
--  4) Moose_CTLD_Pure/Moose_CTLD_FAC.lua                      -- optional FAC/RECCE support
--  5) DO SCRIPT: dofile on this file OR paste the block below directly
--
-- IMPORTANT: F10 menu ordering depends on script execution order!
--   Load this initialization script BEFORE other mission scripts (TADC, CVN, Intel, etc.)
--   to ensure CTLD and FAC appear earlier in the F10 menu.
--
-- Zones you should create in the Mission Editor (as trigger zones):
--   BLUE: PICKUP_BLUE_MAIN, DROP_BLUE_1, FOB_BLUE_A
--   RED : PICKUP_RED_MAIN,  DROP_RED_1,  FOB_RED_A
-- Adjust names below if you use different zone names.


-- Create CTLD instances only if Moose and CTLD are available
if _MOOSE_CTLD and _G.BASE then
local blueCfg = {
    CoalitionSide = coalition.side.BLUE,
    PickupZoneSmokeColor = trigger.smokeColor.Green,
    AllowedAircraft = {                    -- transport-capable unit type names (case-sensitive as in DCS DB)
        'UH-1H','Mi-8MTV2','Mi-24P','SA342M','SA342L','SA342Minigun','UH-60L','CH-47Fbl1','CH-47F','Mi-17','GazelleAI'
    },
  -- Optional: drive zone activation from mission flags (preferred: set per-zone below via flag/activeWhen)
    
  MapDraw = {
    Enabled = true,
    DrawMASHZones = true,  -- Enable MASH zone drawing
  },
  
  Zones = {
    PickupZones = { { name = 'ALPHA', flag = 9001, activeWhen = 0 } },
    DropZones   = { { name = 'BRAVO', flag = 9002, activeWhen = 0 } },
    FOBZones    = { { name = 'CHARLIE',  flag = 9003, activeWhen = 0 } },
    MASHZones   = { { name = 'MASH Alpha', freq = '251.0 AM', radius = 500, flag = 9010, activeWhen = 0 } },
    SalvageDropZones = { { name = 'S1', flag = 9020, radius = 500, activeWhen = 0 } },
  },
  BuildRequiresGroundCrates = true,
}
env.info('[DEBUG] blueCfg.Zones.MASHZones count: ' .. tostring(blueCfg.Zones and blueCfg.Zones.MASHZones and #blueCfg.Zones.MASHZones or 'NIL'))
if blueCfg.Zones and blueCfg.Zones.MASHZones and blueCfg.Zones.MASHZones[1] then
  env.info('[DEBUG] blueCfg.Zones.MASHZones[1].name: ' .. tostring(blueCfg.Zones.MASHZones[1].name))
end
ctldBlue = _MOOSE_CTLD:New(blueCfg)

local redCfg = {
    CoalitionSide = coalition.side.RED,
    PickupZoneSmokeColor = trigger.smokeColor.Green,
    AllowedAircraft = {                    -- transport-capable unit type names (case-sensitive as in DCS DB)
        'UH-1H','Mi-8MTV2','Mi-24P','SA342M','SA342L','SA342Minigun','UH-60L','CH-47Fbl1','CH-47F','Mi-17','GazelleAI'

    },
  -- Optional: drive zone activation for RED via per-zone flag/activeWhen

  MapDraw = {
    Enabled = true,
    DrawMASHZones = true,  -- Enable MASH zone drawing
  },
  
  Zones = {
    PickupZones = { { name = 'DELTA', flag = 9101, activeWhen = 0 } },
    DropZones   = { { name = 'ECHO', flag = 9102, activeWhen = 0 } },
    FOBZones    = { { name = 'FOXTROT',  flag = 9103, activeWhen = 0 } },
    MASHZones   = { { name = 'MASH Bravo', freq = '252.0 AM', radius = 500, flag = 9111, activeWhen = 0 } },
  },
  BuildRequiresGroundCrates = true,
}
env.info('[DEBUG] redCfg.Zones.MASHZones count: ' .. tostring(redCfg.Zones and redCfg.Zones.MASHZones and #redCfg.Zones.MASHZones or 'NIL'))
if redCfg.Zones and redCfg.Zones.MASHZones and redCfg.Zones.MASHZones[1] then
  env.info('[DEBUG] redCfg.Zones.MASHZones[1].name: ' .. tostring(redCfg.Zones.MASHZones[1].name))
end
ctldRed = _MOOSE_CTLD:New(redCfg)

-- Merge catalog into both CTLD instances if catalog was loaded
env.info('[init_mission_dual_coalition] Checking for catalog: '..((_CTLD_EXTRACTED_CATALOG and 'FOUND') or 'NOT FOUND'))
if _CTLD_EXTRACTED_CATALOG then
  local count = 0
  for k,v in pairs(_CTLD_EXTRACTED_CATALOG) do count = count + 1 end
  env.info('[init_mission_dual_coalition] Catalog has '..tostring(count)..' entries')
  env.info('[init_mission_dual_coalition] Merging catalog into CTLD instances')
  ctldBlue:MergeCatalog(_CTLD_EXTRACTED_CATALOG)
  ctldRed:MergeCatalog(_CTLD_EXTRACTED_CATALOG)
  env.info('[init_mission_dual_coalition] Catalog merged successfully')
  -- Verify merge
  local blueCount = 0
  for k,v in pairs(ctldBlue.Config.CrateCatalog) do blueCount = blueCount + 1 end
  env.info('[init_mission_dual_coalition] BLUE catalog now has '..tostring(blueCount)..' entries')
else
  env.info('[init_mission_dual_coalition] WARNING: _CTLD_EXTRACTED_CATALOG not found - catalog not loaded!')
  env.info('[init_mission_dual_coalition] Available globals: '..((_G._CTLD_EXTRACTED_CATALOG and 'in _G') or 'not in _G'))
end
else
  env.info('[init_mission_dual_coalition] Moose or CTLD missing; skipping CTLD init')
end


-- Optional: FAC/RECCE for both sides (requires Moose_CTLD_FAC.lua)
if _MOOSE_CTLD_FAC and _G.BASE and ctldBlue and ctldRed then
  facBlue = _MOOSE_CTLD_FAC:New(ctldBlue, {
    CoalitionSide = coalition.side.BLUE,
    Arty = { Enabled = false },
  })
  -- facBlue:AddRecceZone({ name = 'RECCE_BLUE_1' })
  facBlue:Run()

  facRed = _MOOSE_CTLD_FAC:New(ctldRed, {
    CoalitionSide = coalition.side.RED,
    Arty = { Enabled = false },
  })
  -- facRed:AddRecceZone({ name = 'RECCE_RED_1' })
  facRed:Run()
else
  env.info('[init_mission_dual_coalition] FAC not initialized (missing Moose/CTLD/FAC or CTLD not created)')
end
