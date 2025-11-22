-- CrateCatalog_CTLD_Extract.lua
-- Auto-generated from CTLD.lua (Operation_Polar_Shield) spawnableCrates config
-- Returns a table of crate definitions suitable for CTLD:MergeCatalog()
-- Notes:
-- - Each entry has keys: description/menu, dcsCargoType, required or requires (composite), side, category, build(point, headingDeg)
-- - Single-unit entries spawn one unit by DCS type. Composite "SITE" entries spawn a multi-unit group approximating system components.

local function singleUnit(unitType)
  return function(point, headingDeg)
    local name = string.format('%s-%d', unitType, math.random(100000,999999))
    local hdg = math.rad(headingDeg or 0)
    return {
      visible=false, lateActivation=false, tasks={}, task='Ground Nothing', route={},
      units={ { type=unitType, name=name, x=point.x, y=point.z, heading=hdg } },
      name = 'CTLD_'..name
    }
  end
end

-- Build a single AIR unit that spawns in the air at a configured altitude/speed.
-- Falls back gracefully to singleUnit behavior if config is unavailable/disabled.
local function singleAirUnit(unitType)
  return function(point, headingDeg)
    local cfg = (rawget(_G, 'CTLD') and CTLD.Config and CTLD.Config.DroneAirSpawn) or nil
    if not cfg or cfg.Enabled == false then
      return singleUnit(unitType)(point, headingDeg)
    end

    local name = string.format('%s-%d', unitType, math.random(100000,999999))
    local hdgDeg = headingDeg or 0
    local hdg = math.rad(hdgDeg)
    local alt = tonumber(cfg.AltitudeMeters) or 1200
    local spd = tonumber(cfg.SpeedMps) or 120

    -- Create a tiny 2-point route to ensure forward flight at the chosen altitude.
    local function fwdOffset(px, pz, meters, headingRadians)
      return px + math.sin(headingRadians) * meters, pz + math.cos(headingRadians) * meters
    end
    local p1x, p1z = point.x, point.z
    local p2x, p2z = fwdOffset(point.x, point.z, 1000, hdg) -- 1 km ahead

    local group = {
      visible=false,
      lateActivation=false,
      tasks={},
      task='CAS',
      route={
        points={
          {
            alt = alt, alt_type = 'BARO',
            type = 'Turning Point', action = 'Turning Point',
            x = p1x, y = p1z,
            speed = spd, ETA = 0, ETA_locked = false,
            task = {}
          },
          {
            alt = alt, alt_type = 'BARO',
            type = 'Turning Point', action = 'Turning Point',
            x = p2x, y = p2z,
            speed = spd, ETA = 0, ETA_locked = false,
            task = {}
          }
        }
      },
      units={
        {
          type=unitType, name=name,
          x=p1x, y=p1z,
          heading=hdg,
          speed = spd,
          alt = alt, alt_type = 'BARO'
        }
      },
      name = 'CTLD_'..name
    }
    return group
  end
end

local function multiUnits(units)
  -- units: array of { type, dx, dz }
  return function(point, headingDeg)
    local hdg = math.rad(headingDeg or 0)
    local function off(dx, dz) return { x = point.x + dx, z = point.z + dz } end
    local list = {}
    for i,u in ipairs(units) do
      local p = off(u.dx or 0, u.dz or 3*i)
      table.insert(list, {
        type = u.type, name = string.format('CTLD-%s-%d', u.type, math.random(100000,999999)),
        x = p.x, y = p.z, heading = hdg
      })
    end
    return { visible=false, lateActivation=false, tasks={}, task='Ground Nothing', route={}, units=list, name=string.format('CTLD_SITE_%d', math.random(100000,999999)) }
  end
end

local BLUE = coalition.side.BLUE
local RED  = coalition.side.RED

local cat = {}

cat['BLUE_M1128_STRYKER_MGS_CRATE'] = { hidden=true, description='M1128 Stryker MGS crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M1128_STRYKER_MGS']       = { menuCategory='Combat Vehicles', menu='M1128 Stryker MGS', description='M1128 Stryker MGS', dcsCargoType='container_cargo', requires={ BLUE_M1128_STRYKER_MGS_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M1128 Stryker MGS'), unitType='M1128 Stryker MGS', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['BLUE_M60A3_PATTON_CRATE']      = { hidden=true, description='M-60A3 Patton crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M60A3_PATTON']            = { menuCategory='Combat Vehicles', menu='M-60A3 Patton', description='M-60A3 Patton', dcsCargoType='container_cargo', requires={ BLUE_M60A3_PATTON_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M-60'), unitType='M-60', MEDEVAC=true, salvageValue=3, crewSize=4 }
cat['BLUE_HMMWV_TOW_CRATE']         = { hidden=true, description='Humvee - TOW crate', dcsCargoType='container_cargo', required=1, initialStock=6, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_HMMWV_TOW']               = { menuCategory='Combat Vehicles', menu='Humvee - TOW', description='Humvee - TOW', dcsCargoType='container_cargo', requires={ BLUE_HMMWV_TOW_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M1045 HMMWV TOW'), unitType='M1045 HMMWV TOW', MEDEVAC=true, salvageValue=3, crewSize=2 }
cat['BLUE_M1134_STRYKER_ATGM_CRATE']= { hidden=true, description='M1134 Stryker ATGM crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M1134_STRYKER_ATGM']      = { menuCategory='Combat Vehicles', menu='M1134 Stryker ATGM', description='M1134 Stryker ATGM', dcsCargoType='container_cargo', requires={ BLUE_M1134_STRYKER_ATGM_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M1134 Stryker ATGM'), unitType='M1134 Stryker ATGM', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['BLUE_LAV25_CRATE']             = { hidden=true, description='LAV-25 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_LAV25']                   = { menuCategory='Combat Vehicles', menu='LAV-25', description='LAV-25', dcsCargoType='container_cargo', requires={ BLUE_LAV25_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('LAV-25'), unitType='LAV-25', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['BLUE_M2A2_BRADLEY_CRATE']      = { hidden=true, description='M2A2 Bradley crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M2A2_BRADLEY']            = { menuCategory='Combat Vehicles', menu='M2A2 Bradley', description='M2A2 Bradley', dcsCargoType='container_cargo', requires={ BLUE_M2A2_BRADLEY_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M-2 Bradley'), unitType='M-2 Bradley', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['BLUE_VAB_MEPHISTO_CRATE']      = { hidden=true, description='ATGM VAB Mephisto crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_VAB_MEPHISTO']            = { menuCategory='Combat Vehicles', menu='ATGM VAB Mephisto', description='ATGM VAB Mephisto', dcsCargoType='container_cargo', requires={ BLUE_VAB_MEPHISTO_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('VAB_Mephisto'), unitType='VAB_Mephisto', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['BLUE_M1A2C_ABRAMS_CRATE']      = { hidden=true, description='M1A2C Abrams crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M1A2C_ABRAMS']            = { menuCategory='Combat Vehicles', menu='M1A2C Abrams', description='M1A2C Abrams', dcsCargoType='container_cargo', requires={ BLUE_M1A2C_ABRAMS_CRATE=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M1A2C_SEP_V3'), unitType='M1A2C_SEP_V3', MEDEVAC=true, salvageValue=3, crewSize=4 }

-- Combat Vehicles (RED)
cat['RED_BTR82A_CRATE']      = { hidden=true, description='BTR-82A crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_BTR82A']            = { menuCategory='Combat Vehicles', menu='BTR-82A', description='BTR-82A', dcsCargoType='container_cargo', requires={ RED_BTR82A_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BTR-82A'), unitType='BTR-82A', MEDEVAC=true, salvageValue=2, crewSize=3 }
cat['RED_BRDM2_CRATE']       = { hidden=true, description='BRDM-2 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_BRDM2']             = { menuCategory='Combat Vehicles', menu='BRDM-2', description='BRDM-2', dcsCargoType='container_cargo', requires={ RED_BRDM2_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BRDM-2'), unitType='BRDM-2', MEDEVAC=true, salvageValue=2, crewSize=2 }
cat['RED_BMP3_CRATE']        = { hidden=true, description='BMP-3 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_BMP3']              = { menuCategory='Combat Vehicles', menu='BMP-3', description='BMP-3', dcsCargoType='container_cargo', requires={ RED_BMP3_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BMP-3'), unitType='BMP-3', MEDEVAC=true, salvageValue=2, crewSize=3 }
cat['RED_BMP2_CRATE']        = { hidden=true, description='BMP-2 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_BMP2']              = { menuCategory='Combat Vehicles', menu='BMP-2', description='BMP-2', dcsCargoType='container_cargo', requires={ RED_BMP2_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BMP-2'), unitType='BMP-2', MEDEVAC=true, salvageValue=2, crewSize=3 }
cat['RED_BTR80_CRATE']       = { hidden=true, description='BTR-80 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_BTR80']             = { menuCategory='Combat Vehicles', menu='BTR-80', description='BTR-80', dcsCargoType='container_cargo', requires={ RED_BTR80_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BTR-80'), unitType='BTR-80', MEDEVAC=true, salvageValue=2, crewSize=3 }
cat['RED_T72B3_CRATE']       = { hidden=true, description='T-72B3 crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_T72B3']             = { menuCategory='Combat Vehicles', menu='T-72B3', description='T-72B3', dcsCargoType='container_cargo', requires={ RED_T72B3_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('T-72B3'), unitType='T-72B3', MEDEVAC=true, salvageValue=3, crewSize=3 }
cat['RED_T90M_CRATE']        = { hidden=true, description='T-90M crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=RED, category=Group.Category.GROUND }
cat['RED_T90M']              = { menuCategory='Combat Vehicles', menu='T-90M', description='T-90M', dcsCargoType='container_cargo', requires={ RED_T90M_CRATE=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('CHAP_T90M'), unitType='CHAP_T90M', MEDEVAC=true, salvageValue=3, crewSize=3 }

-- Support (BLUE)
cat['BLUE_MRAP_JTAC']         = { menuCategory='Support', menu='MRAP - JTAC',       description='JTAC MRAP',         dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('MaxxPro_MRAP'), MEDEVAC=true, salvageValue=1, crewSize=4, roles={'JTAC'}, jtac={ platform='ground' } }
cat['BLUE_M818_AMMO']         = { menuCategory='Support', menu='M-818 Ammo Truck',  description='M-818 Ammo Truck',  dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M 818'), salvageValue=1, crewSize=2 }
cat['BLUE_M978_TANKER']       = { menuCategory='Support', menu='M-978 Tanker',      description='M-978 Tanker',      dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M978 HEMTT Tanker'), salvageValue=1, crewSize=2 }
cat['BLUE_EWR_FPS117']        = { menuCategory='Support', menu='EWR Radar FPS-117', description='EWR Radar FPS-117', dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('FPS-117'), salvageValue=1, crewSize=3 }

-- Support (RED)
cat['RED_TIGR_JTAC']          = { menuCategory='Support', menu='Tigr - JTAC',       description='JTAC Tigr',         dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('Tigr_233036'), MEDEVAC=true, salvageValue=1, crewSize=4, roles={'JTAC'}, jtac={ platform='ground' } }
cat['RED_URAL4320_AMMO']      = { menuCategory='Support', menu='Ural-4320-31 Ammo Truck', description='Ural-4320-31 Ammo Truck', dcsCargoType='container_cargo', required=1, initialStock=2, side=RED, category=Group.Category.GROUND, build=singleUnit('Ural-4320-31'), salvageValue=1, crewSize=2 }
cat['RED_ATZ10_TANKER']       = { menuCategory='Support', menu='ATZ-10 Refueler',   description='ATZ-10 Refueler',   dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('ATZ-10'), salvageValue=1, crewSize=2 }
cat['RED_EWR_1L13']           = { menuCategory='Support', menu='EWR Radar 1L13',    description='EWR Radar 1L13',    dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('1L13 EWR'), salvageValue=1, crewSize=3 }

-- Artillery (BLUE)
cat['BLUE_MLRS_CRATE']        = { hidden=true, description='MLRS crate',              dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_MLRS']              = { menuCategory='Artillery', menu='MLRS',              description='MLRS',              dcsCargoType='container_cargo', requires={ BLUE_MLRS_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('MLRS'), salvageValue=2, crewSize=3 }
cat['BLUE_SMERCH_CM_CRATE']   = { hidden=true, description='Smerch (CM) crate',       dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_SMERCH_CM']         = { menuCategory='Artillery', menu='Smerch_CM',         description='Smerch (CM)',       dcsCargoType='container_cargo', requires={ BLUE_SMERCH_CM_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Smerch'), salvageValue=2, crewSize=3 }
cat['BLUE_L118_105MM']        = { menuCategory='Artillery', menu='L118 Light Artillery 105mm', description='L118 105mm', dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('L118_Unit'), salvageValue=1, crewSize=5 }
cat['BLUE_SMERCH_HE_CRATE']   = { hidden=true, description='Smerch (HE) crate',       dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_SMERCH_HE']         = { menuCategory='Artillery', menu='Smerch_HE',         description='Smerch (HE)',       dcsCargoType='container_cargo', requires={ BLUE_SMERCH_HE_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Smerch_HE'), salvageValue=2, crewSize=3 }
cat['BLUE_M109_CRATE']        = { hidden=true, description='M-109 crate',             dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M109']              = { menuCategory='Artillery', menu='M-109',             description='M-109',             dcsCargoType='container_cargo', requires={ BLUE_M109_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M-109'), salvageValue=2, crewSize=4 }

-- Artillery (RED)
cat['RED_GVOZDIKA_CRATE']     = { hidden=true, description='SAU Gvozdika crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_GVOZDika']           = { menuCategory='Artillery', menu='SAU Gvozdika',      description='SAU Gvozdika',      dcsCargoType='container_cargo', requires={ RED_GVOZDIKA_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('SAU Gvozdika'), salvageValue=2, crewSize=3 }
cat['RED_2S19_MSTA_CRATE']    = { hidden=true, description='SPH 2S19 Msta crate',    dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_2S19_MSTA']          = { menuCategory='Artillery', menu='SPH 2S19 Msta',     description='SPH 2S19 Msta',     dcsCargoType='container_cargo', requires={ RED_2S19_MSTA_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('SAU Msta'), salvageValue=2, crewSize=4 }
cat['RED_URAGAN_BM27_CRATE']  = { hidden=true, description='Uragan BM-27 crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_URAGAN_BM27']        = { menuCategory='Artillery', menu='Uragan_BM-27',      description='Uragan BM-27',      dcsCargoType='container_cargo', requires={ RED_URAGAN_BM27_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('Uragan_BM-27'), salvageValue=2, crewSize=3 }
cat['RED_BM21_GRAD_CRATE']    = { hidden=true, description='BM-21 Grad crate',       dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_BM21_GRAD']          = { menuCategory='Artillery', menu='BM-21 Grad Ural',   description='BM-21 Grad Ural',   dcsCargoType='container_cargo', requires={ RED_BM21_GRAD_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('Grad-URAL'), salvageValue=2, crewSize=3 }
cat['RED_PLZ05_CRATE']        = { hidden=true, description='PLZ-05 crate',           dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_PLZ05']              = { menuCategory='Artillery', menu='PLZ-05 Mobile Artillery', description='PLZ-05',      dcsCargoType='container_cargo', requires={ RED_PLZ05_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('PLZ05'), salvageValue=2, crewSize=4 }

-- AAA (BLUE)
cat['BLUE_GEPARD']            = { menuCategory='AAA', menu='Gepard AAA',        description='Gepard AAA',        dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Gepard'), salvageValue=1, crewSize=3 }
cat['BLUE_CRAM']              = { menuCategory='AAA', menu='LPWS C-RAM',        description='LPWS C-RAM',        dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('HEMTT_C-RAM_Phalanx'), salvageValue=1, crewSize=2 }
cat['BLUE_VULCAN_M163']       = { menuCategory='AAA', menu='SPAAA Vulcan M163', description='Vulcan M163',       dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Vulcan'), salvageValue=1, crewSize=2 }
cat['BLUE_BOFORS40']          = { menuCategory='AAA', menu='Bofors 40mm',       description='Bofors 40mm',       dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('bofors40'), salvageValue=1, crewSize=4 }

-- AAA (RED)
cat['RED_URAL_ZU23']          = { menuCategory='AAA', menu='Ural-375 ZU-23',    description='Ural-375 ZU-23',    dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('Ural-375 ZU-23'), salvageValue=1, crewSize=3 }
cat['RED_SHILKA']             = { menuCategory='AAA', menu='ZSU-23-4 Shilka',   description='ZSU-23-4 Shilka',   dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('ZSU-23-4 Shilka'), salvageValue=1, crewSize=3 }
cat['RED_ZSU57_2']            = { menuCategory='AAA', menu='ZSU_57_2',          description='ZSU_57_2',          dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('ZSU_57_2'), salvageValue=1, crewSize=3 }

cat['BLUE_M1097_AVENGER_CRATE'] = { hidden=true, description='M1097 Avenger crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M1097_AVENGER']     = { menuCategory='SAM short range', menu='M1097 Avenger',     description='M1097 Avenger',     dcsCargoType='container_cargo', requires={ BLUE_M1097_AVENGER_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M1097 Avenger') }
cat['BLUE_M48_CHAPARRAL_CRATE'] = { hidden=true, description='M48 Chaparral crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_M48_CHAPARRAL']     = { menuCategory='SAM short range', menu='M48 Chaparral',     description='M48 Chaparral',     dcsCargoType='container_cargo', requires={ BLUE_M48_CHAPARRAL_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M48 Chaparral') }
cat['BLUE_ROLAND_ADS_CRATE']  = { hidden=true, description='Roland ADS crate',        dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND }
cat['BLUE_ROLAND_ADS']        = { menuCategory='SAM short range', menu='Roland ADS',        description='Roland ADS',        dcsCargoType='container_cargo', requires={ BLUE_ROLAND_ADS_CRATE=2 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Roland ADS') }
cat['BLUE_M6_LINEBACKER']     = { menuCategory='SAM short range', menu='M6 Linebacker',     description='M6 Linebacker',     dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M6 Linebacker') }
cat['BLUE_RAPIER_LN']         = { menuCategory='SAM short range', menu='Rapier Launcher',   description='Rapier Launcher',    dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('rapier_fsa_launcher') }
cat['BLUE_RAPIER_SR']         = { menuCategory='SAM short range', menu='Rapier SR',         description='Rapier SR',          dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('rapier_fsa_blindfire_radar') }
cat['BLUE_RAPIER_TR']         = { menuCategory='SAM short range', menu='Rapier Tracker',    description='Rapier Tracker',     dcsCargoType='container_cargo', required=1, initialStock=2, side=BLUE, category=Group.Category.GROUND, build=singleUnit('rapier_fsa_optical_tracker_unit') }
cat['BLUE_RAPIER_SITE']       = { menuCategory='SAM short range', menu='Rapier - All crates', description='Rapier Site',      dcsCargoType='container_cargo', requires={ BLUE_RAPIER_LN=1, BLUE_RAPIER_SR=1, BLUE_RAPIER_TR=1 }, initialStock=0, side=BLUE, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='rapier_fsa_launcher'}, {type='rapier_fsa_blindfire_radar', dx=12, dz=6}, {type='rapier_fsa_optical_tracker_unit', dx=-12, dz=6} }) }

-- SAM short range (RED)
cat['RED_OSA_9K33_CRATE']     = { hidden=true, description='9K33 Osa crate',          dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_OSA_9K33']           = { menuCategory='SAM short range', menu='9K33 Osa',          description='9K33 Osa',          dcsCargoType='container_cargo', requires={ RED_OSA_9K33_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('Osa 9A33 ln') }
cat['RED_STRELA1_9P31_CRATE'] = { hidden=true, description='9P31 Strela-1 crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_STRELA1_9P31']       = { menuCategory='SAM short range', menu='9P31 Strela-1',     description='9P31 Strela-1',     dcsCargoType='container_cargo', requires={ RED_STRELA1_9P31_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('Strela-1 9P31') }
cat['RED_TUNGUSKA_2S6_CRATE'] = { hidden=true, description='2K22 Tunguska crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_TUNGUSKA_2S6']       = { menuCategory='SAM short range', menu='2K22 Tunguska',     description='2K22 Tunguska',     dcsCargoType='container_cargo', requires={ RED_TUNGUSKA_2S6_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('2S6 Tunguska') }
cat['RED_STRELA10M3_CRATE']   = { hidden=true, description='SA-13 Strela-10M3 crate', dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_STRELA10M3']         = { menuCategory='SAM short range', menu='SA-13 Strela-10M3', description='SA-13 Strela-10M3', dcsCargoType='container_cargo', requires={ RED_STRELA10M3_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('Strela-10M3') }
-- HQ-7 components and site
cat['RED_HQ7_LN_CRATE']       = { hidden=true, description='HQ-7 Launcher crate',     dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND }
cat['RED_HQ7_LN']             = { menuCategory='SAM short range', menu='HQ-7_Launcher',     description='HQ-7 Launcher',     dcsCargoType='container_cargo', requires={ RED_HQ7_LN_CRATE=2 }, initialStock=0, side=RED,  category=Group.Category.GROUND, build=singleUnit('HQ-7_LN_SP') }
cat['RED_HQ7_STR']            = { menuCategory='SAM short range', menu='HQ-7_STR_SP',       description='HQ-7 STR',          dcsCargoType='container_cargo', required=1, initialStock=2, side=RED,  category=Group.Category.GROUND, build=singleUnit('HQ-7_STR_SP') }
cat['RED_HQ7_SITE']           = { menuCategory='SAM short range', menu='HQ-7 - All crates', description='HQ-7 Site',         dcsCargoType='container_cargo', requires={ RED_HQ7_LN=1, RED_HQ7_STR=1 }, initialStock=0, side=RED, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='HQ-7_LN_SP'}, {type='HQ-7_STR_SP', dx=10, dz=8} }) }

-- SAM mid range (BLUE) HAWK + NASAMS
cat['BLUE_HAWK_LN']           = { menuCategory='SAM mid range', menu='HAWK Launcher',     description='HAWK Launcher',     dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Hawk ln') }
cat['BLUE_HAWK_SR']           = { menuCategory='SAM mid range', menu='HAWK Search Radar', description='HAWK SR',           dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Hawk sr') }
cat['BLUE_HAWK_TR']           = { menuCategory='SAM mid range', menu='HAWK Track Radar',  description='HAWK TR',           dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Hawk tr') }
cat['BLUE_HAWK_PCP']          = { menuCategory='SAM mid range', menu='HAWK PCP',          description='HAWK PCP',          dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Hawk pcp') }
cat['BLUE_HAWK_CWAR']         = { menuCategory='SAM mid range', menu='HAWK CWAR',         description='HAWK CWAR',         dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Hawk cwar') }
cat['BLUE_HAWK_SITE']         = { menuCategory='SAM mid range', menu='HAWK - All crates', description='HAWK Site',         dcsCargoType='container_cargo', requires={ BLUE_HAWK_LN=1, BLUE_HAWK_SR=1, BLUE_HAWK_TR=1, BLUE_HAWK_PCP=1, BLUE_HAWK_CWAR=1 }, initialStock=0, side=BLUE, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='Hawk ln'}, {type='Hawk sr', dx=12, dz=8}, {type='Hawk tr', dx=-12, dz=8}, {type='Hawk pcp', dx=18, dz=12}, {type='Hawk cwar', dx=-18, dz=12} }) }

-- HAWK site repair/augment (adds +1 launcher, repairs site by respawn)
cat['BLUE_HAWK_REPAIR']       = { menuCategory='SAM mid range', menu='HAWK Repair/Launcher +1', description='HAWK Repair (adds launcher)', dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, isRepair=true, build=function(point, headingDeg)
  -- Build is handled specially in CTLD:BuildSpecificAtGroup for isRepair entries
  return singleUnit('Ural-375')(point, headingDeg)
end }

cat['BLUE_NASAMS_LN']         = { menuCategory='SAM mid range', menu='NASAMS Launcher 120C', description='NASAMS LN 120C', dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('NASAMS_LN_C') }
cat['BLUE_NASAMS_RADAR']      = { menuCategory='SAM mid range', menu='NASAMS Search/Track Radar', description='NASAMS Radar', dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('NASAMS_Radar_MPQ64F1') }
cat['BLUE_NASAMS_CP']         = { menuCategory='SAM mid range', menu='NASAMS Command Post', description='NASAMS CP',      dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('NASAMS_Command_Post') }
cat['BLUE_NASAMS_SITE']       = { menuCategory='SAM mid range', menu='NASAMS - All crates', description='NASAMS Site',     dcsCargoType='container_cargo', requires={ BLUE_NASAMS_LN=1, BLUE_NASAMS_RADAR=1, BLUE_NASAMS_CP=1 }, initialStock=0, side=BLUE, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='NASAMS_LN_C'}, {type='NASAMS_Radar_MPQ64F1', dx=12, dz=8}, {type='NASAMS_Command_Post', dx=-12, dz=8} }) }

-- SAM mid range (RED) KUB
cat['RED_KUB_LN']             = { menuCategory='SAM mid range', menu='KUB Launcher',      description='KUB Launcher',      dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('Kub 2P25 ln') }
cat['RED_KUB_RADAR']          = { menuCategory='SAM mid range', menu='KUB Radar',         description='KUB Radar',         dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('Kub 1S91 str') }
cat['RED_KUB_SITE']           = { menuCategory='SAM mid range', menu='KUB - All crates',  description='KUB Site',          dcsCargoType='container_cargo', requires={ RED_KUB_LN=1, RED_KUB_RADAR=1 }, initialStock=0, side=RED, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='Kub 2P25 ln'}, {type='Kub 1S91 str', dx=12, dz=8} }) }

-- KUB site repair/augment (adds +1 launcher, repairs site by respawn)
cat['RED_KUB_REPAIR']         = { menuCategory='SAM mid range', menu='KUB Repair/Launcher +1', description='KUB Repair (adds launcher)', dcsCargoType='container_cargo', required=1, initialStock=1, side=RED, category=Group.Category.GROUND, isRepair=true, build=function(point, headingDeg)
  return singleUnit('Ural-375')(point, headingDeg)
end }

-- SAM long range (BLUE) Patriot
cat['BLUE_PATRIOT_LN']        = { menuCategory='SAM long range', menu='Patriot Launcher',  description='Patriot Launcher',  dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Patriot ln') }
cat['BLUE_PATRIOT_RADAR']     = { menuCategory='SAM long range', menu='Patriot Radar',     description='Patriot Radar',     dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Patriot str') }
cat['BLUE_PATRIOT_ECS']       = { menuCategory='SAM long range', menu='Patriot ECS',       description='Patriot ECS',       dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, build=singleUnit('Patriot ECS') }
cat['BLUE_PATRIOT_SITE']      = { menuCategory='SAM long range', menu='Patriot - All crates', description='Patriot Site',   dcsCargoType='container_cargo', requires={ BLUE_PATRIOT_LN=1, BLUE_PATRIOT_RADAR=1, BLUE_PATRIOT_ECS=1 }, initialStock=0, side=BLUE, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='Patriot ln'}, {type='Patriot str', dx=14, dz=10}, {type='Patriot ECS', dx=-14, dz=10} }) }

-- Patriot site repair/augment (adds +1 launcher, repairs site by respawn)
cat['BLUE_PATRIOT_REPAIR']    = { menuCategory='SAM long range', menu='Patriot Repair/Launcher +1', description='Patriot Repair (adds launcher)', dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.GROUND, isRepair=true, build=function(point, headingDeg)
  return singleUnit('Ural-375')(point, headingDeg)
end }

-- SAM long range (RED) BUK
cat['RED_BUK_LN']             = { menuCategory='SAM long range', menu='BUK Launcher',      description='BUK Launcher',      dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('SA-11 Buk LN 9A310M1') }
cat['RED_BUK_SR']             = { menuCategory='SAM long range', menu='BUK Search Radar',  description='BUK Search Radar',  dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('SA-11 Buk SR 9S18M1') }
cat['RED_BUK_CC']             = { menuCategory='SAM long range', menu='BUK CC Radar',      description='BUK CC Radar',      dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.GROUND, build=singleUnit('SA-11 Buk CC 9S470M1') }
cat['RED_BUK_SITE']           = { menuCategory='SAM long range', menu='BUK - All crates',  description='BUK Site',          dcsCargoType='container_cargo', requires={ RED_BUK_LN=1, RED_BUK_SR=1, RED_BUK_CC=1 }, initialStock=0, side=RED, category=Group.Category.GROUND,
                                   build=multiUnits({ {type='SA-11 Buk LN 9A310M1'}, {type='SA-11 Buk SR 9S18M1', dx=12, dz=8}, {type='SA-11 Buk CC 9S470M1', dx=-12, dz=8} }) }

-- BUK site repair/augment (adds +1 launcher, repairs site by respawn)
cat['RED_BUK_REPAIR']         = { menuCategory='SAM long range', menu='BUK Repair/Launcher +1', description='BUK Repair (adds launcher)', dcsCargoType='container_cargo', required=1, initialStock=1, side=RED, category=Group.Category.GROUND, isRepair=true, build=function(point, headingDeg)
  return singleUnit('Ural-375')(point, headingDeg)
end }

-- Drones (JTAC)
cat['BLUE_MQ9']               = { menuCategory='Drones', menu='MQ-9 Reaper - JTAC', description='MQ-9 JTAC',        dcsCargoType='container_cargo', required=1, initialStock=1, side=BLUE, category=Group.Category.AIRPLANE, build=singleAirUnit('MQ-9 Reaper'), roles={'JTAC'}, jtac={ platform='air' } }
cat['RED_WINGLOONG']          = { menuCategory='Drones', menu='WingLoong-I - JTAC', description='WingLoong-I JTAC', dcsCargoType='container_cargo', required=1, initialStock=1, side=RED,  category=Group.Category.AIRPLANE, build=singleAirUnit('WingLoong-I'), roles={'JTAC'}, jtac={ platform='air' } }

-- FOB crates (Support) — three small crates build a FOB site
cat['FOB_SMALL']              = { hidden=true, description='FOB small crate', dcsCargoType='container_cargo', required=1, initialStock=6, side=nil, category=Group.Category.GROUND, build=function(point, headingDeg)
  -- spawns a harmless placeholder truck for visibility; consumed by FOB_SITE build
  return singleUnit('Ural-375')(point, headingDeg)
end }
cat['FOB_SITE']               = { menuCategory='Support', menu='FOB Crates - All', description='FOB Site', isFOB=true, dcsCargoType='container_cargo', requires={ FOB_SMALL=3 }, initialStock=0, side=nil, category=Group.Category.GROUND,
  build=multiUnits({ {type='HEMTT TFFT'}, {type='Ural-375 PBU', dx=10, dz=8}, {type='Ural-375', dx=-10, dz=8} }) }

-- Mobile MASH (Support) — three crates build a Mobile MASH unit
cat['MOBILE_MASH_SMALL']      = { hidden=true, description='Mobile MASH crate', dcsCargoType='container_cargo', required=1, initialStock=3, side=nil, category=Group.Category.GROUND, build=function(point, headingDeg)
  -- spawns placeholder truck for visibility; consumed by MOBILE_MASH build
  return singleUnit('Ural-375')(point, headingDeg)
end }
cat['BLUE_MOBILE_MASH']       = { menuCategory='Support', menu='Mobile MASH - All', description='Blue Mobile MASH Unit', isMobileMASH=true, dcsCargoType='container_cargo', requires={ MOBILE_MASH_SMALL=3 }, initialStock=0, side=BLUE, category=Group.Category.GROUND, build=singleUnit('M-113') }
cat['RED_MOBILE_MASH']        = { menuCategory='Support', menu='Mobile MASH - All', description='Red Mobile MASH Unit', isMobileMASH=true, dcsCargoType='container_cargo', requires={ MOBILE_MASH_SMALL=3 }, initialStock=0, side=RED, category=Group.Category.GROUND, build=singleUnit('BTR_D') }

-- =========================
-- Troop Type Definitions
-- =========================
-- These define the composition of troop squads for Load/Unload Troops (NOT crates)
-- Structure: { label, size, unitsBlue, unitsRed, units (fallback) }
local troops = {}

-- Assault Squad: general-purpose rifles/MG
troops['AS'] = {
  label = 'Assault Squad',
  size = 8,
  unitsBlue = { 'Soldier M4', 'Soldier M249' },
  unitsRed  = { 'Infantry AK', 'Infantry AK ver3' },
  units     = { 'Infantry AK' },
}

-- MANPADS Team: Anti-air element
troops['AA'] = {
  label = 'MANPADS Team',
  size = 4,
  unitsBlue = { 'Soldier stinger', 'Stinger comm' },
  unitsRed  = { 'SA-18 Igla-S manpad', 'SA-18 Igla comm' },
  units     = { 'Infantry AK' },
}

-- AT Team: Anti-tank element
troops['AT'] = {
  label = 'AT Team',
  size = 4,
  unitsBlue = { 'Soldier RPG', 'Soldier RPG' },
  unitsRed  = { 'Soldier RPG', 'Soldier RPG' },
  units     = { 'Infantry AK' },
}

-- Mortar Team: Indirect fire element
troops['AR'] = {
  label = 'Mortar Team',
  size = 4,
  unitsBlue = { '2B11 mortar' },
  unitsRed  = { '2B11 mortar' },
  units     = { '2B11 mortar' },
}

-- Export troop types
_CTLD_TROOP_TYPES = troops

-- Also export as a global for mission setups that load via DO SCRIPT FILE (no return capture)
_CTLD_EXTRACTED_CATALOG = cat
return cat
