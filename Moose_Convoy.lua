-------------------------------------------------------------------
-- MOOSE CONVOY ESCORT SCRIPT
-------------------------------------------------------------------
-- A dynamic convoy system where convoys spawn, navigate to player-marked
-- destinations via roads, engage threats, and request air support.
--
-- SETUP:
-- 1. Create late-activated ground group templates listed in CONVOY_TEMPLATE_NAMES
--    (each spawn randomly picks one entry from the list; add/remove names to control variety)
-- 2. Players place F10 map marks containing the configured keywords:
--      • Spawn mark: keyword from CONVOY_SPAWN_KEYWORD near a valid CTLD pickup/FOB zone.
--      • Destination mark: keyword from CONVOY_DEST_KEYWORD.
--    - When PLAYER_CONTROLLED_DESTINATIONS = false, destination marks are rejected and convoys
--      auto-route to the static destinations defined below.
--    - When PLAYER_CONTROLLED_DESTINATIONS = true:
--        • First spawn mark creates a pending convoy for that coalition.
--        • The next destination mark pairs with that pending spawn (respecting MINIMUM_ROUTE_DISTANCE)
--          and launches the convoy.
--        • After a convoy is active, destination marks become redirects: specify the convoy name in
--          the mark text to target it directly; otherwise the closest active convoy of that coalition
--          is retasked.
-- 3. Each convoy locks to its assigned destination. If players drag waypoints in the F10 map the script
--    restores the original route and notifies the owning coalition.
-- 4. While en route the convoy halts on threat detection, requests CAS, and resumes only after threats clear.
-------------------------------------------------------------------

-------------------------------------------------------------------
-- CONFIGURATION SECTION
-------------------------------------------------------------------

-- Logging Configuration
LOGGING_ENABLED = true           -- Enable/disable detailed logging
LOGGING_LEVEL = "DEBUG"          -- "DEBUG", "INFO", "WARNING", "ERROR" (Set to DEBUG to troubleshoot zone issues)
STARTUP_TEST_REPORT = true       -- Report validation results to players on startup

-- Message Durations (seconds)
MESSAGE_DURATION_DEFAULT = 15    -- Standard message duration
MESSAGE_DURATION_SHORT = 10      -- Brief informational pings
MESSAGE_DURATION_LONG = 30       -- Extended announcements (e.g., validation reports)
MESSAGE_MGRS_PRECISION = 5       -- Digits for MGRS strings (1-5)
RESUME_MESSAGE_COOLDOWN = 120    -- Minimum seconds between identical "resume movement" notifications

-- Convoy Template Names (must exist as late-activated groups in mission)
CONVOY_TEMPLATE_NAMES = {
    "Convoy Template 1",  -- Add your template group names here
    "Convoy Template 2",
}

-- CTLD Integration (spawns convoys from CTLD pickup/FOB zones)
CTLD_INSTANCE_NAME_BLUE = "ctldBlue"  -- Name of your Blue CTLD instance (e.g., "ctldBlue")
CTLD_INSTANCE_NAME_RED = "ctldRed"    -- Name of your Red CTLD instance (e.g., "ctldRed")
USE_CTLD_ZONES = true                 -- If true, uses CTLD pickup/FOB zones as spawn points
SPAWN_ZONE_RADIUS = 500               -- Meters: mark must be within this distance of zone center to spawn

-- Destination Mode
PLAYER_CONTROLLED_DESTINATIONS = false  -- If true, players mark destinations; if false, use static destinations below

-- Static Destinations (used when PLAYER_CONTROLLED_DESTINATIONS = false)
-- Define as coordinate tables: { name = "Display Name", lat = latitude, lon = longitude }
-- OR as zone names: { name = "Display Name", zone = "ZoneName" }
STATIC_DESTINATIONS = {
    -- Examples:
    -- { name = "Main Base", lat = 42.1234, lon = 43.5678 },
    { name = "convoy end", zone = "convoy end" },
}

-- Mark Keywords (case-insensitive, detects if keyword is in mark text)
CONVOY_SPAWN_KEYWORD = "convoy start"           -- Mark near pickup/FOB zone to spawn convoy
CONVOY_DEST_KEYWORD = "convoy end" -- Mark to set convoy destination (if player-controlled)

-- Speed Settings (in km/h)
CONVOY_SPEED_ROAD = 60        -- Speed when traveling on roads
CONVOY_SPEED_OFFROAD = 30     -- Speed when traveling off-road

-- Update Intervals (in seconds)
PROGRESS_UPDATE_INTERVAL = 300      -- How often to announce progress (5 mins)
STUCK_ANNOUNCE_INTERVAL = 900       -- How often to announce stuck position (15 mins)
THREAT_CHECK_INTERVAL = 3           -- Faster sweeps so we tag threats before contact

-- Distance Thresholds (in meters)
DESTINATION_REACHED_DISTANCE = 100  -- Distance to consider destination reached
MINIMUM_ROUTE_DISTANCE = 5000       -- Minimum distance from spawn to destination (prevents exploits)
THREAT_DETECTION_RANGE = 10000      -- Detect armor ahead of effective weapon range
THREAT_CLEARED_RANGE = 11000        -- Give a little buffer before calling area safe

ROUTE_CHECK_INTERVAL = 3            -- Seconds between route integrity scans
ROUTE_DEVIATION_THRESHOLD = 750     -- Meters away from mission destination before re-routing
ROUTE_REISSUE_MIN_INTERVAL = 6      -- Seconds between automatic route reapplications
ROUTE_TASK_GRACE_PERIOD = 2         -- Seconds to wait after issuing a route before integrity checks run
ROUTE_WARNING_COOLDOWN = 6          -- Minimum seconds between route-missing warnings
ROUTE_RESUME_GRACE_PERIOD = 8       -- Seconds to wait after clearing a hold before route restores fire again

-- Threat Hold Behaviour
CONVOY_HARD_LOCK_ON_THREAT = true   -- true = players cannot override movement while in CONTACT; false = allow override but still warn

-- Smoke Settings
FRIENDLY_SMOKE_COLOR = SMOKECOLOR.Green  -- Smoke color for convoy position
ENEMY_SMOKE_COLOR = SMOKECOLOR.Red       -- Smoke color for enemy position
SMOKE_ON_CONTACT = true                  -- Pop smoke when contact is made
SMOKE_ON_CLEAR = false                    -- Pop smoke when threats cleared
SMOKE_MIN_INTERVAL = 60                   -- Minimum seconds between smoke pops per convoy

-- Radio Settings
CONVOY_RADIO_FREQUENCY = 256.0      -- Radio frequency for convoy comms (MHz)
USE_RADIO_MESSAGES = true           -- Use radio messages (vs just message to all)

-- Coalition Settings - Automatically detected from player placing the mark
-- Both coalitions can have convoys simultaneously

-------------------------------------------------------------------
-- END CONFIGURATION
-------------------------------------------------------------------

-------------------------------------------------------------------
-- GLOBAL VARIABLES
-------------------------------------------------------------------

MOOSE_CONVOY = {
    Version = "1.0.0",
    Convoys = {},  -- Active convoy tracking
    ConvoyCounter = 0,
    CTLDInstanceBlue = nil,  -- Reference to Blue CTLD instance
    CTLDInstanceRed = nil,   -- Reference to Red CTLD instance
    PickupZones = {},        -- Cached CTLD pickup zones (both coalitions)
    FOBZones = {},           -- Cached CTLD FOB zones (both coalitions)
    ValidationResults = {},  -- Stores startup validation results
    MenuRoots = {},          -- F10 coalition menu roots
    IntelMarks = {},         -- Active intel marks per coalition
    IntelMarkLookup = {},    -- Fast lookup for intel mark IDs
    MarkIdCounter = 0,       -- Sequential mark IDs for intel marks
    LastSmokeTime = {},      -- Per-convoy last smoke timestamp
}

-------------------------------------------------------------------
-- HELPER FUNCTIONS
-------------------------------------------------------------------

--- Logging function with level support
-- @param #string level Log level ("DEBUG", "INFO", "WARNING", "ERROR")
-- @param #string message Log message
function MOOSE_CONVOY:Log(level, message)
    if not LOGGING_ENABLED then
        return
    end
    
    local levels = { DEBUG = 1, INFO = 2, WARNING = 3, ERROR = 4 }
    local currentLevel = levels[LOGGING_LEVEL] or 2
    local msgLevel = levels[level] or 2
    
    if msgLevel >= currentLevel then
        local prefix = string.format("[MOOSE_CONVOY][%s]", level)
        local fullMessage = string.format("%s %s", prefix, message)
        
        if level == "ERROR" then
            env.error(fullMessage)
        elseif level == "WARNING" then
            env.warning(fullMessage)
        else
            env.info(fullMessage)
        end
    end
end

--- Safely resolve the name of a UNIT (handles both MOOSE and raw DCS objects)
-- @param unit The unit object
-- @return #string|nil The unit name or nil if unavailable
function MOOSE_CONVOY:GetUnitName(unit)
    if not unit then return nil end
    if unit.GetName then
        local ok, name = pcall(function() return unit:GetName() end)
        if ok and name then return name end
    end
    if unit.getName then
        local ok, name = pcall(function() return unit:getName() end)
        if ok and name then return name end
    end
    return nil
end

local function _convoyFormatDMS(lat, lon)
    local function toDMS(value, isLat)
        if type(value) ~= "number" then
            return nil
        end
        local hemisphere = isLat and (value >= 0 and "N" or "S") or (value >= 0 and "E" or "W")
        value = math.abs(value)
        local degrees = math.floor(value)
        local minutesFloat = (value - degrees) * 60
        local minutes = math.floor(minutesFloat)
        local seconds = (minutesFloat - minutes) * 60
        local formatPattern = isLat and "%s%02d°%02d'%05.2f\"" or "%s%03d°%02d'%05.2f\""
        return string.format(formatPattern, hemisphere, degrees, minutes, seconds)
    end

    local latText = toDMS(lat, true)
    local lonText = toDMS(lon, false)

    if not latText or not lonText then
        return nil
    end

    return string.format("%s %s", latText, lonText)
end

local function _convoyFormatMGRS(lat, lon, precision)
    if type(lat) ~= "number" or type(lon) ~= "number" then
        return nil
    end

    local mgrsTable = coord and coord.LLtoMGRS and coord.LLtoMGRS(lat, lon)
    if not mgrsTable or not mgrsTable.UTMZone or not mgrsTable.MGRSDigraph or not mgrsTable.Easting or not mgrsTable.Northing then
        return nil
    end

    local digits = tonumber(precision) or 5
    if digits < 1 then digits = 1 elseif digits > 5 then digits = 5 end

    local rawEast = math.floor(mgrsTable.Easting + 0.5)
    local rawNorth = math.floor(mgrsTable.Northing + 0.5)
    local divisor = 10 ^ (5 - digits)
    local east = math.floor(rawEast / divisor)
    local north = math.floor(rawNorth / divisor)
    local formatPattern = string.format("%%0%dd", digits)

    return string.format("%s%s %s %s",
        tostring(mgrsTable.UTMZone),
        tostring(mgrsTable.MGRSDigraph),
        string.format(formatPattern, east),
        string.format(formatPattern, north)
    )
end

function MOOSE_CONVOY:GetVec3FromCoordinate(source)
    if not source then
        return nil
    end

    -- Direct MOOSE coordinate support
    if type(source) == "table" then
        if source.GetVec3 then
            local ok, vec3 = pcall(function()
                return source:GetVec3()
            end)
            if ok and vec3 and vec3.x and vec3.z then
                vec3.y = vec3.y or 0
                return vec3
            end
        end

        if source.GetVec2 then
            local ok, vec2 = pcall(function()
                return source:GetVec2()
            end)
            if ok and vec2 and vec2.x and vec2.y then
                local height = land and land.getHeight and land.getHeight({ x = vec2.x, y = vec2.y }) or 0
                return { x = vec2.x, y = height, z = vec2.y }
            end
        end
    end

    -- Raw vec3 table { x, y, z }
    if type(source) == "table" and source.x and source.z then
        local vec3 = {
            x = source.x,
            z = source.z,
            y = source.y or source.alt or 0
        }
        if not vec3.y and land and land.getHeight then
            local ok, height = pcall(land.getHeight, { x = vec3.x, y = vec3.z })
            if ok and height then
                vec3.y = height
            end
        end
        return vec3
    end

    -- Vec2 table { x, y }
    if type(source) == "table" and source.x and source.y and not source.z then
        local height = land and land.getHeight and land.getHeight({ x = source.x, y = source.y }) or 0
        return { x = source.x, y = height, z = source.y }
    end

    return nil
end

--- Format a coordinate for player-facing messages (LL + MGRS when available)
-- @param coord #COORDINATE Coordinate to format
-- @return #string Coordinate string for chat/radio output
function MOOSE_CONVOY:GetCoordinateComponents(source)
    if not source then
        return nil, nil
    end

    local vec3 = self:GetVec3FromCoordinate(source)
    if not vec3 then
        return nil, nil
    end

    local lat, lon
    if coord and coord.LOtoLL then
        local ok, latResult, lonResult = pcall(function()
            return coord.LOtoLL(vec3)
        end)
        if ok then
            lat, lon = latResult, lonResult
        end
    end

    if not lat or not lon then
        return nil, nil
    end

    local ll = _convoyFormatDMS(lat, lon)
    local mgrs = _convoyFormatMGRS(lat, lon, MESSAGE_MGRS_PRECISION)

    if mgrs and mgrs ~= "" then
        mgrs = "MGRS " .. mgrs
    else
        mgrs = nil
    end

    return ll, mgrs
end

function MOOSE_CONVOY:FormatCoordinateForMessage(coord)
    local ll, mgrs = self:GetCoordinateComponents(coord)

    if ll and mgrs then
        return string.format("%s | %s", ll, mgrs)
    end
    if ll then
        return ll
    end
    if mgrs then
        return mgrs
    end

    return "UNKNOWN"
end

--- Return a short coalition name for messages
-- @param coalitionID #number Coalition side ID
-- @return #string Human-readable coalition name
function MOOSE_CONVOY:GetCoalitionName(coalitionID)
    if coalitionID == coalition.side.BLUE then
        return "Blue"
    elseif coalitionID == coalition.side.RED then
        return "Red"
    end
    return "Coalition"
end

--- Return an MGRS label suitable for map mark text
-- @param coord #COORDINATE
-- @return #string Short MGRS string or "UNK"
function MOOSE_CONVOY:GetCoordinateMGRSLabel(coord)
    local _, mgrs = self:GetCoordinateComponents(coord)
    if not mgrs or mgrs == "" then
        return "UNK"
    end
    return mgrs:gsub("^MGRS%s+", "")
end

--- Generate the next mark ID for intel marks
-- @return #number markId
function MOOSE_CONVOY:NextMarkId()
    self.MarkIdCounter = (self.MarkIdCounter or 0) + 1
    return 600000 + self.MarkIdCounter
end

--- Remove intel marks for a coalition (if any)
-- @param coalitionID #number Coalition side ID
function MOOSE_CONVOY:RemoveIntelMarks(coalitionID)
    if not self.IntelMarks or not self.IntelMarks[coalitionID] then
        return
    end
    local marks = self.IntelMarks[coalitionID]
    self.IntelMarks[coalitionID] = nil
    for _, markId in ipairs(marks) do
        trigger.action.removeMark(markId)
        if self.IntelMarkLookup then
            self.IntelMarkLookup[markId] = nil
        end
    end
end

--- Remove intel marks associated with a specific convoy (by name prefix)
-- @param convoy #table Convoy object
function MOOSE_CONVOY:ClearIntelForConvoy(convoy)
    if not convoy or not convoy.Name or not self.IntelMarks then
        return
    end
    local nameLower = string.lower(convoy.Name)
    for coalitionID, marks in pairs(self.IntelMarks) do
        if marks then
            for idx = #marks, 1, -1 do
                local markId = marks[idx]
                local owner = self.IntelMarkLookup and self.IntelMarkLookup[markId]
                if owner == coalitionID then
                    local markInfo = trigger.misc.getMarkID and trigger.misc.getMarkID(markId)
                    local text = markInfo and markInfo.text or ""
                    if text ~= "" and string.find(string.lower(text), nameLower, 1, true) then
                        trigger.action.removeMark(markId)
                        self.IntelMarkLookup[markId] = nil
                        table.remove(marks, idx)
                    end
                end
            end
            if #marks == 0 then
                self.IntelMarks[coalitionID] = nil
            end
        end
    end
end

--- Determine whether a mark ID belongs to convoy intel
-- @param markId #number
-- @return #boolean
function MOOSE_CONVOY:IsIntelMark(markId)
    if not markId then
        return false
    end
    return self.IntelMarkLookup and self.IntelMarkLookup[markId] ~= nil
end

--- Cleanup bookkeeping for an intel mark that has been removed externally
-- @param markId #number
function MOOSE_CONVOY:HandleIntelMarkRemoval(markId)
    if not markId then
        return
    end
    if self.IntelMarkLookup then
        self.IntelMarkLookup[markId] = nil
    end
    if not self.IntelMarks then
        return
    end
    for coalitionID, marks in pairs(self.IntelMarks) do
        if marks then
            for idx = #marks, 1, -1 do
                if marks[idx] == markId then
                    table.remove(marks, idx)
                end
            end
            if #marks == 0 then
                self.IntelMarks[coalitionID] = nil
            end
        end
    end
end

--- Gather active convoys for a coalition
-- @param coalitionID #number Coalition side ID
-- @return #table List of convoy objects
function MOOSE_CONVOY:GetActiveConvoysForCoalition(coalitionID)
    local results = {}
    for _, convoy in pairs(self.Convoys or {}) do
        if convoy and convoy.Coalition == coalitionID and self:IsConvoyActive(convoy) then
            table.insert(results, convoy)
        end
    end
    table.sort(results, function(a, b)
        return (a.ID or 0) < (b.ID or 0)
    end)
    return results
end

--- Create F10 menus for each coalition to request convoy intel
function MOOSE_CONVOY:SetupCoalitionMenus()
    if self.MenusInitialized then
        return
    end

    local coalitionsToSetup = { coalition.side.BLUE, coalition.side.RED }
    for _, coalID in ipairs(coalitionsToSetup) do
        local rootMenu = MENU_COALITION:New(coalID, "Convoy Intel")
        if rootMenu then
            self.MenuRoots[coalID] = rootMenu
            MENU_COALITION_COMMAND:New(coalID, "Request Convoy Intel", rootMenu, function()
                self:BroadcastConvoyIntel(coalID)
            end)
            MENU_COALITION_COMMAND:New(coalID, "Drop Intel Map Marks", rootMenu, function()
                self:CreateIntelMarks(coalID)
            end)
            self:Log("INFO", string.format("Coalition menu created for %s", self:GetCoalitionName(coalID)))
        else
            self:Log("WARNING", string.format("Failed to create menu for coalition %s", tostring(coalID)))
        end
    end

    self.MenusInitialized = true
end

--- Send an intel report to a coalition
-- @param coalitionID #number Coalition side ID
function MOOSE_CONVOY:BroadcastConvoyIntel(coalitionID)
    local convoys = self:GetActiveConvoysForCoalition(coalitionID)
    local coalitionName = self:GetCoalitionName(coalitionID)

    if #convoys == 0 then
        MESSAGE:New(string.format("%s coalition: No active convoys at this time.", coalitionName), MESSAGE_DURATION_SHORT):ToCoalition(coalitionID)
        return
    end

    local lines = {}
    lines[#lines + 1] = string.format("%s Coalition Convoy Intel (%d active)", coalitionName, #convoys)

    local function appendCoordinateBlock(targetLines, label, coord)
        targetLines[#targetLines + 1] = string.format("  %s:", label)
        local ll, mgrs = self:GetCoordinateComponents(coord)
        targetLines[#targetLines + 1] = string.format("    -- %s", ll or "LL UNKNOWN")
        targetLines[#targetLines + 1] = string.format("    -- %s", mgrs or "MGRS UNKNOWN")
    end

    for _, convoy in ipairs(convoys) do
        local groupCoord = convoy.Group and convoy.Group:GetCoordinate()
        local status = convoy.Status or "UNKNOWN"

        lines[#lines + 1] = string.format("%s [%s]", convoy.Name, status)
        appendCoordinateBlock(lines, "Position", groupCoord)

        if convoy.DestPoint then
            appendCoordinateBlock(lines, "Destination", convoy.DestPoint)
        end

        if groupCoord and convoy.DestPoint then
            local remaining = groupCoord:Get2DDistance(convoy.DestPoint)
            if remaining then
                lines[#lines + 1] = string.format("  Distance Remaining: %.1f km", remaining / 1000)
            end
        end

        if convoy.InContact then
            local reasonText = (convoy.ContactReason == "UNDER_FIRE") and "Taking fire" or "Enemy spotted"
            appendCoordinateBlock(lines, string.format("Enemy Contact (%s)", reasonText), convoy.EnemyPosition)
        end

        lines[#lines + 1] = ""
    end

    local messageText = table.concat(lines, "\n")
    MESSAGE:New(messageText, MESSAGE_DURATION_LONG):ToCoalition(coalitionID)
end
--- Create map marks for convoys needing assistance
-- @param coalitionID #number Coalition side ID
function MOOSE_CONVOY:CreateIntelMarks(coalitionID)
    self:RemoveIntelMarks(coalitionID)

    local convoys = self:GetActiveConvoysForCoalition(coalitionID)
    local coalitionName = self:GetCoalitionName(coalitionID)

    local marksCreated = {}

    for _, convoy in ipairs(convoys) do
        if convoy.InContact then
            local convoyCoord = convoy.Group and convoy.Group:GetCoordinate()
            if convoyCoord then
                local convoyMarkId = self:NextMarkId()
                self.IntelMarkLookup = self.IntelMarkLookup or {}
                self.IntelMarkLookup[convoyMarkId] = coalitionID
                local convoyMgrs = self:GetCoordinateMGRSLabel(convoyCoord)
                local convoyVec3 = convoyCoord:GetVec3()
                if convoyVec3 and convoyVec3.x ~= nil and convoyVec3.y ~= nil and convoyVec3.z ~= nil then
                    trigger.action.markToCoalition(convoyMarkId, string.format("%s HOLD %s", convoy.Name, convoyMgrs), convoyVec3, coalitionID)
                    table.insert(marksCreated, convoyMarkId)
                else
                    self:Log("WARNING", string.format("Unable to place convoy intel mark for %s - invalid coordinate vector", convoy.Name))
                    if self.IntelMarkLookup then
                        self.IntelMarkLookup[convoyMarkId] = nil
                    end
                end
            end

            if convoy.EnemyPosition then
                local enemyMarkId = self:NextMarkId()
                self.IntelMarkLookup = self.IntelMarkLookup or {}
                self.IntelMarkLookup[enemyMarkId] = coalitionID
                local enemyMgrs = self:GetCoordinateMGRSLabel(convoy.EnemyPosition)
                local enemyVec3 = convoy.EnemyPosition:GetVec3()
                if enemyVec3 and enemyVec3.x ~= nil and enemyVec3.y ~= nil and enemyVec3.z ~= nil then
                    trigger.action.markToCoalition(enemyMarkId, string.format("%s ENEMY %s", convoy.Name, enemyMgrs), enemyVec3, coalitionID)
                    table.insert(marksCreated, enemyMarkId)
                else
                    self:Log("WARNING", string.format("Unable to place enemy intel mark for %s - invalid coordinate vector", convoy.Name))
                    if self.IntelMarkLookup then
                        self.IntelMarkLookup[enemyMarkId] = nil
                    end
                end
            end
        end
    end

    if #marksCreated == 0 then
        MESSAGE:New(string.format("%s coalition: No convoys currently requesting assistance. Existing intel marks cleared.", coalitionName), MESSAGE_DURATION_SHORT):ToCoalition(coalitionID)
        return
    end

    self.IntelMarks[coalitionID] = marksCreated
    MESSAGE:New(string.format("%s coalition: Intel marks placed for convoys requesting assistance.", coalitionName), MESSAGE_DURATION_DEFAULT):ToCoalition(coalitionID)
end

--- Get CTLD zones for convoy spawning from both coalition instances
function MOOSE_CONVOY:GetCTLDZones()
    if not USE_CTLD_ZONES then
        self:Log("DEBUG", "CTLD zones disabled in configuration")
        return {}, {}
    end
    
    -- Get CTLD instances
    if not self.CTLDInstanceBlue and CTLD_INSTANCE_NAME_BLUE then
        self.CTLDInstanceBlue = _G[CTLD_INSTANCE_NAME_BLUE]
        self:Log("DEBUG", "Retrieved Blue CTLD instance: " .. tostring(CTLD_INSTANCE_NAME_BLUE) .. " = " .. tostring(self.CTLDInstanceBlue ~= nil))
    end
    
    if not self.CTLDInstanceRed and CTLD_INSTANCE_NAME_RED then
        self.CTLDInstanceRed = _G[CTLD_INSTANCE_NAME_RED]
        self:Log("DEBUG", "Retrieved Red CTLD instance: " .. tostring(CTLD_INSTANCE_NAME_RED) .. " = " .. tostring(self.CTLDInstanceRed ~= nil))
    end
    
    if not self.CTLDInstanceBlue and not self.CTLDInstanceRed then
        self:Log("ERROR", "No CTLD instances found. Check CTLD_INSTANCE_NAME_BLUE and CTLD_INSTANCE_NAME_RED config.")
        return {}, {}
    end
    
    local pickupZones = {}
    local fobZones = {}
    
    -- Process Blue CTLD instance
    if self.CTLDInstanceBlue then
        self:Log("DEBUG", "Processing Blue CTLD zones...")
        local bluePickup, blueFOB = self:ProcessCTLDInstance(self.CTLDInstanceBlue, "BLUE")
        for _, zone in ipairs(bluePickup) do table.insert(pickupZones, zone) end
        for _, zone in ipairs(blueFOB) do table.insert(fobZones, zone) end
    else
        self:Log("WARNING", "Blue CTLD instance not found")
    end
    
    -- Process Red CTLD instance
    if self.CTLDInstanceRed then
        self:Log("DEBUG", "Processing Red CTLD zones...")
        local redPickup, redFOB = self:ProcessCTLDInstance(self.CTLDInstanceRed, "RED")
        for _, zone in ipairs(redPickup) do table.insert(pickupZones, zone) end
        for _, zone in ipairs(redFOB) do table.insert(fobZones, zone) end
    else
        self:Log("WARNING", "Red CTLD instance not found")
    end
    
    self:Log("INFO", string.format("Zone retrieval complete: %d pickup, %d FOB zones found", #pickupZones, #fobZones))
    
    return pickupZones, fobZones
end

--- Process a single CTLD instance to extract zones
-- @param #table ctldInstance The CTLD instance
-- @param #string coalitionName Coalition name for logging
-- @return #table pickupZones, #table fobZones
function MOOSE_CONVOY:ProcessCTLDInstance(ctldInstance, coalitionName)
    local pickupZones = {}
    local fobZones = {}
    
    if not ctldInstance or not ctldInstance.Config then
        self:Log("WARNING", coalitionName .. " CTLD instance has no Config")
        return pickupZones, fobZones
    end
    
    self:Log("DEBUG", coalitionName .. " CTLD.Config.Zones exists: " .. tostring(ctldInstance.Config.Zones ~= nil))
    
    if not ctldInstance.Config.Zones then
        return pickupZones, fobZones
    end
    
    -- Get pickup zones
    if ctldInstance.Config.Zones.PickupZones then
        self:Log("DEBUG", coalitionName .. " PickupZones count: " .. #ctldInstance.Config.Zones.PickupZones)
        for i, zoneDef in ipairs(ctldInstance.Config.Zones.PickupZones) do
            self:Log("DEBUG", string.format("%s PickupZone[%d]: name=%s", coalitionName, i, tostring(zoneDef.name)))
            if zoneDef.name then
                local zone = ZONE:FindByName(zoneDef.name)
                if zone then
                    table.insert(pickupZones, {
                        name = zoneDef.name,
                        zone = zone,
                        coord = zone:GetCoordinate(),
                        radius = zone:GetRadius(),
                        coalition = coalitionName,
                    })
                    self:Log("DEBUG", string.format("✓ %s Pickup zone '%s' loaded successfully", coalitionName, zoneDef.name))
                else
                    self:Log("WARNING", string.format("✗ %s Pickup zone '%s' not found in mission", coalitionName, zoneDef.name))
                end
            end
        end
    else
        self:Log("DEBUG", coalitionName .. " has no PickupZones defined")
    end
    
    -- Get FOB zones
    if ctldInstance.Config.Zones.FOBZones then
        self:Log("DEBUG", coalitionName .. " FOBZones count: " .. #ctldInstance.Config.Zones.FOBZones)
        for i, zoneDef in ipairs(ctldInstance.Config.Zones.FOBZones) do
            self:Log("DEBUG", string.format("%s FOBZone[%d]: name=%s", coalitionName, i, tostring(zoneDef.name)))
            if zoneDef.name then
                local zone = ZONE:FindByName(zoneDef.name)
                if zone then
                    table.insert(fobZones, {
                        name = zoneDef.name,
                        zone = zone,
                        coord = zone:GetCoordinate(),
                        radius = zone:GetRadius(),
                        coalition = coalitionName,
                    })
                    self:Log("DEBUG", string.format("✓ %s FOB zone '%s' loaded successfully", coalitionName, zoneDef.name))
                else
                    self:Log("WARNING", string.format("✗ %s FOB zone '%s' not found in mission", coalitionName, zoneDef.name))
                end
            end
        end
    else
        self:Log("DEBUG", coalitionName .. " has no FOBZones defined")
    end
    
    return pickupZones, fobZones
end

--- Find nearest CTLD zone to a coordinate
-- @param #table coordinate MOOSE coordinate
-- @return #table|nil Zone data, #number distance
function MOOSE_CONVOY:FindNearestCTLDZone(coordinate)
    local allZones = {}
    
    -- Combine pickup and FOB zones
    for _, z in ipairs(self.PickupZones) do
        table.insert(allZones, z)
    end
    for _, z in ipairs(self.FOBZones) do
        table.insert(allZones, z)
    end
    
    local nearestZone = nil
    local nearestDistance = 999999999
    
    for _, zoneData in ipairs(allZones) do
        local dist = coordinate:Get2DDistance(zoneData.coord)
        if dist < nearestDistance then
            nearestDistance = dist
            nearestZone = zoneData
        end
    end
    
    return nearestZone, nearestDistance
end

--- Locate an active convoy that owns a unit by name
-- @param #string unitName The unit name to resolve
-- @return #table|nil Convoy instance when found
function MOOSE_CONVOY:GetConvoyByUnitName(unitName)
    if not unitName then return nil end
    for _, convoy in pairs(self.Convoys or {}) do
        if convoy and convoy.UnitNames and convoy.UnitNames[unitName] then
            return convoy
        end
    end
    return nil
end

--- Determine current speed of the convoy in km/h (first alive unit sample)
-- @return #number Speed in km/h
function MOOSE_CONVOY:GetCurrentSpeedKmh()
    if not self.Group then return 0 end
    local units = self.Group:GetUnits()
    if not units then return 0 end
    for _, unitObj in pairs(units) do
        if unitObj and unitObj:IsAlive() then
            local vec3
            local ok = pcall(function() vec3 = unitObj:GetVelocityVec3() end)
            if ok and vec3 then
                local speedMps = math.sqrt((vec3.x or 0)^2 + (vec3.y or 0)^2 + (vec3.z or 0)^2)
                return speedMps * 3.6
            end
        end
    end
    return 0
end

--- Apply or reapply the route towards the current destination
-- @param #string reason Context for logging
-- @param #boolean force Ignore contact holds
-- @param #boolean bypassThrottle Ignore minimum interval checks
-- @return #boolean true when a route command was issued
function MOOSE_CONVOY:ApplyRouteToDestination(reason, force, bypassThrottle)
    if not self.Group or not self.Group:IsAlive() or not self.DestPoint then
        return false
    end

    -- In hard-lock mode, we never reapply a movement route while in
    -- contact, except explicitly from the "threats cleared" path.
    if self.InContact and not force then
        if CONVOY_HARD_LOCK_ON_THREAT then
            self.RouteNeedsRefresh = true
            return false
        end
        self.RouteNeedsRefresh = true
        return false
    end

    local now = timer.getTime()
    if not bypassThrottle and (self.LastRouteReissue or 0) > 0 and (now - self.LastRouteReissue) < ROUTE_REISSUE_MIN_INTERVAL then
        return false
    end

    self.LastRouteReissue = now
    self.LastRouteCommandTime = now
    self.RouteNeedsRefresh = false
    if self.DestPoint.GetVec2 then
        self.ExpectedRouteEndpoint = self.DestPoint:GetVec2()
    else
        self.ExpectedRouteEndpoint = nil
    end
    self.Group:RouteGroundOnRoad(self.DestPoint, CONVOY_SPEED_ROAD)
    self:EnsureOnRoadFormation()
    self:Log("INFO", string.format("%s route command issued (%s)", self.Name, reason or "ROUTE"))
    return true
end

--- Ensure the convoy stays in an on-road formation to prevent lateral drift
function MOOSE_CONVOY:EnsureOnRoadFormation()
    if not self.Group or not self.Group:IsAlive() then
        return
    end

    local groundOptions = AI and AI.Option and AI.Option.Ground
    if not groundOptions then
        return
    end

    local formationId = groundOptions.id and (groundOptions.id.FORMATION or groundOptions.id.formation)
    if not formationId then
        return
    end

    local formationTable = groundOptions.formation or (groundOptions.val and groundOptions.val.FORMATION)
    if not formationTable then
        return
    end

    local chosenFormation = formationTable.ON_ROAD or formationTable.COLUMN
    if not chosenFormation then
        return
    end

    local formationLabel
    if formationTable.ON_ROAD == chosenFormation then
        formationLabel = "ON_ROAD"
    elseif formationTable.COLUMN == chosenFormation then
        formationLabel = "COLUMN"
    else
        formationLabel = "UNKNOWN"
    end

    local dcsGroup = self.Group:GetDCSObject()
    if not dcsGroup then
        return
    end

    local controller = dcsGroup:getController()
    if not controller then
        return
    end

    local ok, err = pcall(function()
        controller:setOption(formationId, chosenFormation)
    end)

    if not ok then
        self:Log("WARNING", string.format("%s failed to enforce convoy formation: %s", self.Name, tostring(err)))
        return
    end

    if self.LastFormationApplied ~= formationLabel then
        self.LastFormationApplied = formationLabel
        self:Log("DEBUG", string.format("%s formation locked to %s", self.Name, formationLabel))
    end
end

--- Retrieve the current DCS route endpoint for comparison
-- @return #table|nil Vec2 of last waypoint when a mission route is active
-- @return #string Current controller task classification ("MISSION", "STOP", "NONE", etc.)
function MOOSE_CONVOY:GetRouteEndpointVec2()
    if not self.Group then return nil, "NO_GROUP" end
    local dcsGroup = self.Group:GetDCSObject()
    if not dcsGroup then return nil, "NO_GROUP_OBJECT" end

    local controller = dcsGroup:getController()
    if not controller then return nil, "NO_CONTROLLER" end

    local ok, task = pcall(function()
        return controller:getTask()
    end)

    if not ok or not task then
        return nil, "NO_TASK"
    end

    local function unwrapControlledTask(candidate)
        if not candidate then
            return nil
        end
        if candidate.id == "ControlledTask" and candidate.params and candidate.params.task then
            return unwrapControlledTask(candidate.params.task)
        end
        return candidate
    end

    local missionTask = unwrapControlledTask(task)
    if not missionTask then
        return nil, "NO_TASK"
    end

    if missionTask.id == "WrappedAction" then
        local action = missionTask.params and missionTask.params.action
        local actionId = action and action.id
        if actionId == "Stop" then
            return nil, "STOP"
        end
        return nil, actionId or "WRAPPED_ACTION"
    end

    if missionTask.id ~= "Mission" then
        return nil, missionTask.id or "UNKNOWN_TASK"
    end

    local route = missionTask.params and missionTask.params.route and missionTask.params.route.points
    if not route or #route == 0 then
        return nil, "NO_ROUTE"
    end

    local lastPoint = route[#route]
    if not lastPoint or not lastPoint.x or not lastPoint.y then
        return nil, "INVALID_ROUTE"
    end

    self.HasSeenMissionRoute = true
    return { x = lastPoint.x, y = lastPoint.y }, "MISSION"
end

--- Detect and correct manual route edits while convoy is in motion
function MOOSE_CONVOY:MonitorRouteIntegrity(forceOverride)
    forceOverride = forceOverride or false
    if not self.DestPoint or not self.Group or not self.Group:IsAlive() then
        return
    end

    -- In hard-lock mode, once we are in contact we do not attempt to
    -- correct or reapply any mission routes. Any player-added routes
    -- should be immediately cancelled by the hold logic instead.
    if CONVOY_HARD_LOCK_ON_THREAT and self.InContact then
        -- Ensure the controller remains in a STOP state; do not
        -- issue new RouteGroundOnRoad tasks while threats remain.
        self.Group:RouteStop()
        self.LastRouteStopTime = timer.getTime()
        return
    end

    local now = timer.getTime()
    local lastCommand = self.LastRouteCommandTime or 0
    if lastCommand > 0 and (now - lastCommand) < ROUTE_TASK_GRACE_PERIOD then
        return
    end

    local lastCheck = self.LastRouteCheck or 0
    if lastCheck > 0 and (now - lastCheck) < ROUTE_CHECK_INTERVAL then
        return
    end

    self.LastRouteCheck = now

    local resumeTimestamp = self.LastHoldReleaseTime or 0
    if resumeTimestamp > 0 and (now - resumeTimestamp) < ROUTE_RESUME_GRACE_PERIOD then
        return
    end

    local expected = self.ExpectedRouteEndpoint
    if not expected and self.DestPoint and self.DestPoint.GetVec2 then
        expected = self.DestPoint:GetVec2()
        self.ExpectedRouteEndpoint = expected
    end

    if not expected then
        return
    end
    local routeEnd, taskState = self:GetRouteEndpointVec2()

    if taskState == "STOP" then
        -- DCS controller is still honouring a RouteStop action; wait for the mission task to return
        return
    end

    if not routeEnd then
        -- DCS is not exposing a Mission route task; as long as we are not
        -- in contact, trust the last issued order and avoid trying to
        -- "fix" the route, which can cause constant jinking.
        return
    end

    local dx = (expected.x or 0) - (routeEnd.x or 0)
    local dy = (expected.y or 0) - (routeEnd.y or 0)
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance > ROUTE_DEVIATION_THRESHOLD then
        if lastCommand > 0 and (now - lastCommand) < ROUTE_REISSUE_MIN_INTERVAL then
            self.RouteNeedsRefresh = true
            return
        end

        self:Log("WARNING", string.format("%s route deviation detected (%.0fm)", self.Name, distance))
        local routeApplied = self:ApplyRouteToDestination("ROUTE_CORRECTION", forceOverride, forceOverride)
        if routeApplied then
            self:AnnounceRouteOverride(distance)
            if self.Group and self.Group:IsAlive() and (forceOverride or self.InContact) then
                self.Group:RouteStop()
                self.LastRouteStopTime = now
            end
        else
            self.RouteNeedsRefresh = true
        end
    end
end

--- Notify players that we reclaimed the route (throttled)
-- @param #number deviationMeters Distance deviation detected
function MOOSE_CONVOY:AnnounceRouteOverride(deviationMeters)
    local now = timer.getTime()
    local last = self.LastRouteWarning or 0
    if last > 0 and (now - last) < 20 then
        return
    end

    if not deviationMeters then
        self.LastRouteWarning = now
        self:Log("DEBUG", string.format("%s route restore issued with no deviation; suppressing player notice", self.Name))
        return
    end

    self.LastRouteWarning = now
    local deviationText = deviationMeters and string.format(" (override %.0fm)", deviationMeters) or ""
    local messageText = string.format("%s - Mission route restored%s. Convoy continues to assigned destination.", self.Name, deviationText)

    local coalitionID = self.Coalition
    if coalitionID then
        MESSAGE:New(messageText, MESSAGE_DURATION_DEFAULT):ToCoalition(coalitionID)
    else
        self:MessageToAll(messageText)
    end
end

--- Update convoy destination based on a new coordinate
-- @param newCoordinate #COORDINATE Destination coordinate
-- @param params #table Optional parameters: label, coalition, reason
function MOOSE_CONVOY:RedirectTo(newCoordinate, params)
    if not newCoordinate then
        return false
    end

    self.DestPoint = newCoordinate
    if newCoordinate.GetVec2 then
        self.ExpectedRouteEndpoint = newCoordinate:GetVec2()
    end

    if params and params.label and params.label ~= "" then
        self.DestinationName = params.label
    end

    local currentPos = self.Group and self.Group:GetCoordinate()
    if currentPos then
        self.InitialDistance = currentPos:Get2DDistance(newCoordinate)
    end

    self.LastProgressTime = timer.getTime()
    self.RouteNeedsRefresh = true

    local reason = (params and params.reason) or "PLAYER_REDIRECT"
    self:Log("INFO", string.format("%s destination updated (%s)", self.Name, reason))

    if not self.InContact then
        self:ApplyRouteToDestination(reason, false, true)
    end

    local destText = self:FormatCoordinateForMessage(newCoordinate)
    local labelText = params and params.label and params.label ~= "" and params.label or nil
    local messageText
    if labelText then
        messageText = string.format("%s - Redirected to '%s'. Coordinates: %s", self.Name, labelText, destText)
    else
        messageText = string.format("%s - Redirected to new player destination. Coordinates: %s", self.Name, destText)
    end

    if self.InContact then
        messageText = messageText .. " Holding until threats clear."
    end

    if params and params.notify ~= false then
        if params and params.coalition then
            MESSAGE:New(messageText, MESSAGE_DURATION_DEFAULT):ToCoalition(params.coalition)
        else
            self:MessageToAll(messageText)
        end
    end

    return true
end

--- Force the convoy to remain stopped while in a hold, reissuing orders if needed
-- @param reason #string Context for logging/messaging
function MOOSE_CONVOY:EnforceHold(reason)
    if not self.Group or not self.Group:IsAlive() then
        return
    end

    -- Always issue a stop when in a hold
    self.Group:RouteStop()
    self.LastRouteStopTime = timer.getTime()

    local now = timer.getTime()
    local last = self.LastHoldEnforce or 0
    if last > 0 and (now - last) < 8 then
        -- Always keep the AI stopped, but avoid spamming player messages.
        return
    end

    self.LastHoldEnforce = now
    self.LastHoldReleaseTime = nil

    local holdLabel = (self.ContactReason == "UNDER_FIRE") and "TAKING FIRE" or "ENEMY SPOTTED"
    local distanceInfo = ""
    if self.ContactPosition and self.EnemyPosition then
        local dist = self.ContactPosition:Get2DDistance(self.EnemyPosition)
        if dist then
            distanceInfo = string.format(" Enemy %.1f km.", dist / 1000)
        end
    end

    -- If hard-lock is disabled we still enforce RouteStop, but we
    -- treat continued movement as a player override and reduce spam.
    local msg
    if CONVOY_HARD_LOCK_ON_THREAT then
        if reason == "MOVEMENT" then
            msg = string.format("%s - HOLD ORDER ACTIVE (%s). Movement blocked until CAS clears the route.%s", self.Name, holdLabel, distanceInfo)
        elseif reason == "INITIAL" then
            -- Already announced contact; just ensure players know the stop is intentional without repeating the full call
            msg = string.format("%s - Holding position (%s). Await CAS before resuming.%s", self.Name, holdLabel, distanceInfo)
        else
            msg = string.format("%s - Maintaining defensive hold (%s). Awaiting CAS.%s", self.Name, holdLabel, distanceInfo)
        end
    else
        if reason == "INITIAL" then
            msg = string.format("%s - Holding position (%s). Await CAS before resuming.%s", self.Name, holdLabel, distanceInfo)
        elseif reason == "MOVEMENT" then
            -- Player is likely forcing a move; issue a softer reminder with cooldown
            msg = string.format("%s - HOLD ORDER ACTIVE (%s). You may override movement manually, but route is still unsafe.%s", self.Name, holdLabel, distanceInfo)
        else
            msg = string.format("%s - Maintaining defensive hold (%s). Threats not yet cleared.%s", self.Name, holdLabel, distanceInfo)
        end
    end

    if msg then
        self:MessageToAll(msg)
    end
end

--- Ensure we are listening for combat events so convoys can react when hit
function MOOSE_CONVOY:SetupEventHandlers()
    if self.EventHandler then
        return
    end

    local handler = EVENTHANDLER:New()
    handler:HandleEvent(EVENTS.Hit)
    handler:HandleEvent(EVENTS.Dead)

    function handler:OnEventHit(EventData)
        MOOSE_CONVOY:HandleUnitHit(EventData)
    end

    function handler:OnEventDead(EventData)
        MOOSE_CONVOY:HandleUnitDead(EventData)
    end

    self.EventHandler = handler
    self:Log("INFO", "Combat event handler registered")
end

--- Translate a HIT event into an under-fire hold for the owning convoy
-- @param EventData MOOSE event payload
function MOOSE_CONVOY:HandleUnitHit(EventData)
    if not EventData then return end

    local targetUnit = EventData.TgtUnit or EventData.Target or EventData.TargetUnit
    local unitName = self:GetUnitName(targetUnit) or EventData.TgtUnitName
    if not unitName then return end

    local convoy = self:GetConvoyByUnitName(unitName)
    if not convoy then return end

    local attacker = EventData.IniUnit or EventData.IniDCSUnit or EventData.WeaponOwner
    convoy:OnUnderFire(attacker, targetUnit, EventData)
end

--- Translate a DEAD event into an under-fire hold and cleanup
-- @param EventData MOOSE event payload
function MOOSE_CONVOY:HandleUnitDead(EventData)
    if not EventData then return end

    local deadUnit = EventData.IniUnit or EventData.Target or EventData.TgtUnit
    local unitName = self:GetUnitName(deadUnit) or EventData.IniUnitName
    if not unitName then return end

    local convoy = self:GetConvoyByUnitName(unitName)
    if not convoy then return end

    convoy.UnitNames[unitName] = nil
    convoy:CacheUnitNames()

    local attacker = EventData.TgtUnit or EventData.WeaponOwner
    if attacker then
        local attackerName = self:GetUnitName(attacker)
        if attackerName and convoy.UnitNames and convoy.UnitNames[attackerName] then
            attacker = nil
        end
    end

    convoy:OnUnderFire(attacker, deadUnit, EventData)
end

-- CONVOY CLASS

--- Creates a new convoy object
-- @param #string templateName The template group name
-- @param #table spawnPoint Coordinate where convoy spawns
-- @param #table destPoint Coordinate where convoy goes
-- @param #number convoyCoalition The coalition of the convoy
-- @return #table Convoy object
function MOOSE_CONVOY:NewConvoy(templateName, spawnPoint, destPoint, convoyCoalition)
    MOOSE_CONVOY.ConvoyCounter = MOOSE_CONVOY.ConvoyCounter + 1

    local coalitionName = convoyCoalition == coalition.side.BLUE and "BLUE" or "RED"

    local convoy = {
        ID = MOOSE_CONVOY.ConvoyCounter,
        Name = string.format("%s Convoy-%03d", coalitionName, MOOSE_CONVOY.ConvoyCounter),
        TemplateName = templateName,
        SpawnPoint = spawnPoint,
        DestPoint = destPoint,
        Coalition = convoyCoalition,
        Group = nil,
        Status = "SPAWNING",
        LastProgressTime = 0,
        LastStuckAnnounce = 0,
        StartTime = timer.getTime(),
        InitialDistance = 0,
        InContact = false,
        ContactPosition = nil,
        EnemyPosition = nil,
        SchedulerID = nil,
        ContactReason = nil,
        UnitNames = {},
        LastUnderFireAlert = 0,
        LastHoldEnforce = 0,
        LastRouteReissue = 0,
        LastRouteCheck = 0,
        RouteNeedsRefresh = false,
        ExpectedRouteEndpoint = nil,
        LastRouteWarning = 0,
        LastRouteMissingLog = 0,
        LastRouteCommandTime = 0,
        LastResumeMessageTime = nil,
        LastFormationApplied = nil,
        HasSeenMissionRoute = false,
        LastHumanControlNoticeTime = nil,
        LastScriptControlNoticeTime = nil,
    }

    if destPoint and destPoint.GetVec2 then
        convoy.ExpectedRouteEndpoint = destPoint:GetVec2()
    end

    setmetatable(convoy, self)
    self.__index = self

    return convoy
end

--- Spawn the convoy at the spawn point
function MOOSE_CONVOY:Spawn()
    MOOSE_CONVOY:Log("INFO", string.format("Spawning convoy %s", self.Name))
    
    -- Create spawn object
    local spawn = SPAWN:New(self.TemplateName)
    spawn:InitCoalition(self.Coalition)
    spawn:OnSpawnGroup(
        function(spawnedGroup)
            self:OnSpawned(spawnedGroup)
        end,
        self
    )
    
    -- Spawn the group from the requested coordinate
    self.Group = spawn:SpawnFromCoordinate(self.SpawnPoint)
    
    if self.Group then
        self.Status = "SPAWNING"
        self:MessageToAll(string.format("%s spawned. Moving to staging area.", self.Name))
    else
        MOOSE_CONVOY:Log("ERROR", string.format("Failed to spawn convoy from template %s", self.TemplateName))
    end
end

--- Refresh cached unit name lookups for this convoy
function MOOSE_CONVOY:CacheUnitNames()
    self.UnitNames = {}
    if not self.Group then return end
    local units = self.Group:GetUnits()
    if not units then return end
    for _, unitObj in pairs(units) do
        if unitObj:IsAlive() then
            local uname = MOOSE_CONVOY:GetUnitName(unitObj)
            if uname then
                self.UnitNames[uname] = true
            end
        end
    end
end

--- Called when convoy is spawned
function MOOSE_CONVOY:OnSpawned(group)
    MOOSE_CONVOY:Log("INFO", string.format("Convoy %s spawned successfully", self.Name))
    
    self.Group = group
    self:CacheUnitNames()
    
    -- Calculate initial distance
    local currentPos = self.Group:GetCoordinate()
    self.InitialDistance = currentPos:Get2DDistance(self.DestPoint)
    
    -- Start the journey
    self:StartJourney()
end

--- Start the convoy journey to destination
function MOOSE_CONVOY:StartJourney()
    MOOSE_CONVOY:Log("INFO", string.format("%s starting journey - Distance: %.1f km", self.Name, self.InitialDistance / 1000))
    
    self.Status = "MOVING"
    self.LastProgressTime = timer.getTime()
    
    -- Set convoy to move to destination on roads
    local currentPos = self.Group:GetCoordinate()
    
    -- Route to destination using roads
    self:ApplyRouteToDestination("INITIAL_ROUTE", true, true)
    
    self:MessageToAll(string.format("%s departing. Destination: %.1f km away. Proceeding via road network.", 
        self.Name, 
        self.InitialDistance / 1000))
    
    -- Start monitoring scheduler
    self:StartMonitoring()

    -- Immediate threat check so we halt even if enemies are already inside the bubble
    self:CheckForThreats()
end

--- Start monitoring the convoy status
function MOOSE_CONVOY:StartMonitoring()
    MOOSE_CONVOY:Log("DEBUG", string.format("%s monitoring started - Check interval: %ds", self.Name, THREAT_CHECK_INTERVAL))
    -- Schedule periodic checks
    self.SchedulerID = SCHEDULER:New(nil,
        function()
            self:Update()
        end,
        {}, 1, THREAT_CHECK_INTERVAL
    )
end

--- Update convoy status (called periodically)
function MOOSE_CONVOY:Update()
    if not self.Group or not self.Group:IsAlive() then
        self:OnDestroyed()
        return
    end
    
    local currentTime = timer.getTime()
    local currentPos = self.Group:GetCoordinate()
    local distanceRemaining = currentPos:Get2DDistance(self.DestPoint)
    
    -- Check if reached destination
    if distanceRemaining < DESTINATION_REACHED_DISTANCE then
        self:OnReachedDestination()
        return
    end
    
    -- Check for threats / enforce holds
    if self.Status == "MOVING" then
        self:CheckForThreats()
    elseif self.Status == "CONTACT" or self.Status == "STUCK" then
        self:CheckThreatsCleared()

        if self.InContact then
            local speed = self:GetCurrentSpeedKmh()

            if CONVOY_HARD_LOCK_ON_THREAT then
                -- In hard-lock mode we want speed effectively zero while in
                -- contact, regardless of player-added waypoints.
                if speed > 0.5 then
                    MOOSE_CONVOY:Log("DEBUG", string.format("%s hard-lock CONTACT: speed %.1f km/h, issuing RouteStop", self.Name, speed))
                    self:EnforceHold("MOVEMENT")
                else
                    -- Even when stopped, keep the controller pinned to STOP
                    -- so no latent route tasks start rolling us forward.
                    self:MonitorRouteIntegrity(true)
                end
            else
                -- Override-friendly mode: still try to hold, but only
                -- announce once per contact episode when the player keeps
                -- moving.
                if speed > 1.5 then
                    if not self.OverrideModeHoldNotified then
                        self.OverrideModeHoldNotified = true
                        self:EnforceHold("MOVEMENT")
                    end
                else
                    self.OverrideModeHoldNotified = nil
                    self:MonitorRouteIntegrity(true)
                end
            end
        end
    end
    
    -- Progress updates
    if self.Status == "MOVING" then
        if currentTime - self.LastProgressTime > PROGRESS_UPDATE_INTERVAL then
            self:AnnounceProgress()
            self.LastProgressTime = currentTime
        end
    end
    
    -- Stuck announcements
    if self.Status == "STUCK" or self.Status == "CONTACT" then
        if currentTime - self.LastStuckAnnounce > STUCK_ANNOUNCE_INTERVAL then
            self:AnnounceStuck()
            self.LastStuckAnnounce = currentTime
        end
    end

    if self.Status == "MOVING" and not self.InContact then
        local speed = self:GetCurrentSpeedKmh()

        -- If we are essentially stopped well short of destination, assume
        -- external control has parked the convoy and reassert our route.
        if speed < 1.0 and distanceRemaining > (DESTINATION_REACHED_DISTANCE * 3) then
            local lastCommand = self.LastRouteCommandTime or 0
            if lastCommand <= 0 or (currentTime - lastCommand) >= ROUTE_REISSUE_MIN_INTERVAL then
                local msg = string.format("%s - We've been idle short of the objective. Resuming convoy movement to assigned destination.", self.Name)
                local lastScript = self.LastScriptControlNoticeTime or 0
                if lastScript <= 0 or (currentTime - lastScript) >= 60 then
                    self.LastScriptControlNoticeTime = currentTime
                    self:MessageToAll(msg)
                end
                self:ApplyRouteToDestination("STOPPED_RECOVERY", true, false)
            end
        elseif speed >= 1.0 and distanceRemaining > (DESTINATION_REACHED_DISTANCE * 3) then
            -- Convoy moving but clearly not at destination: likely under
            -- human/GC routing. Acknowledge once per episode and defer.
            if not self.LastHumanControlNoticeTime or self.LastHumanControlNoticeTime <= 0 then
                self.LastHumanControlNoticeTime = currentTime
                local msg = string.format("%s - Higher command routing received. Following current orders until halted or objective reached.", self.Name)
                self:MessageToAll(msg)
            end
        end

        self:MonitorRouteIntegrity()
    elseif not self.InContact and self.RouteNeedsRefresh then
        local lastCommand = self.LastRouteCommandTime or 0
        if lastCommand <= 0 or (currentTime - lastCommand) >= ROUTE_REISSUE_MIN_INTERVAL then
            if not self:ApplyRouteToDestination("PENDING_RESTORE", false, false) then
                self.RouteNeedsRefresh = true
            end
        end
    end
end

--- Check for nearby threats
function MOOSE_CONVOY:CheckForThreats()
    local currentPos = self.Group:GetCoordinate()
    if not currentPos then
        return
    end

    local enemyCoalition = (self.Coalition == coalition.side.RED) and "blue" or "red"

    local scanSet = SET_GROUP:New()
        :FilterCoalitions(enemyCoalition)
        :FilterCategoryGround()
        :FilterActive(true)
        :FilterOnce()

    local threatsFound = false
    local closestThreat = nil
    local closestDistance = THREAT_DETECTION_RANGE

    scanSet:ForEachGroup(function(group)
        if group and group:IsAlive() then
            local coord = group:GetCoordinate()
            if coord then
                local distance = currentPos:Get2DDistance(coord)
                if distance < THREAT_DETECTION_RANGE then
                    threatsFound = true
                    if distance < closestDistance then
                        closestDistance = distance
                        closestThreat = group
                    end
                end
            end
        end
    end)

    if threatsFound and closestThreat then
        local enemyUnit = closestThreat:GetUnit(1) or closestThreat
        if closestThreat.GetCoordinate then
            self.EnemyPosition = closestThreat:GetCoordinate()
        end
        MOOSE_CONVOY:Log("WARNING", string.format("%s detected threat at %.0fm", self.Name, closestDistance))
        self:OnContactWithEnemy(enemyUnit, "DETECTION")
    end
end

--- Called when convoy makes contact with enemy
-- @param enemyUnit The detected or attacking enemy unit (can be nil)
-- @param reason #string Reason for the hold ("DETECTION" vs "UNDER_FIRE")
function MOOSE_CONVOY:OnContactWithEnemy(enemyUnit, reason)
    reason = reason or "DETECTION"

    local isEscalation = self.InContact and self.ContactReason ~= "UNDER_FIRE" and reason == "UNDER_FIRE"
    if self.InContact and not isEscalation then
        return
    end

    local currentPos = self.Group and self.Group:GetCoordinate()
    if not currentPos then
        return
    end

    local enemyCoord = self.EnemyPosition
    if enemyUnit and enemyUnit.GetCoordinate then
        local ok, coord = pcall(function()
            return enemyUnit:GetCoordinate()
        end)
        if ok and coord then
            enemyCoord = coord
        end
    end
    if enemyCoord then
        self.EnemyPosition = enemyCoord
    end

    if not isEscalation then
        MOOSE_CONVOY:Log("WARNING", string.format("%s entering hold - reason: %s", self.Name, reason))
        self.Status = "CONTACT"
        self.InContact = true
        self.ContactReason = reason
        self.LastStuckAnnounce = timer.getTime()
        self.ContactPosition = currentPos
        self.LastHoldEnforce = 0

        self.Group:RouteStop()
        self.LastRouteStopTime = timer.getTime()
        self.RouteNeedsRefresh = true
        self.LastHoldReleaseTime = nil

        if SMOKE_ON_CONTACT then
            self:MaybeSmokeAt(currentPos, FRIENDFLY_SMOKE_COLOR)
            if self.EnemyPosition then
                self:MaybeSmokeAt(self.EnemyPosition, ENEMY_SMOKE_COLOR)
            end
        end
    else
        MOOSE_CONVOY:Log("WARNING", string.format("%s hold escalated to UNDER_FIRE", self.Name))
        self.ContactReason = "UNDER_FIRE"
        self.LastStuckAnnounce = timer.getTime()
        self.LastHoldEnforce = 0
        self.RouteNeedsRefresh = true
        if SMOKE_ON_CONTACT and self.ContactPosition then
            self:MaybeSmokeAt(self.ContactPosition, FRIENDFLY_SMOKE_COLOR)
        end
        if SMOKE_ON_CONTACT and self.EnemyPosition then
            self:MaybeSmokeAt(self.EnemyPosition, ENEMY_SMOKE_COLOR)
        end
    end

    local contactCoord = self.ContactPosition or currentPos
    local bearing
    local distance
    if contactCoord and self.EnemyPosition then
        bearing = contactCoord:HeadingTo(self.EnemyPosition)
        distance = contactCoord:Get2DDistance(self.EnemyPosition)
    end

    local holdLabel = (self.ContactReason == "UNDER_FIRE") and "HOLD STATUS: TAKING FIRE" or "HOLD STATUS: ENEMY SPOTTED"
    local bearingText = bearing and string.format("%03d", bearing) or nil
    local leadMessage
    if self.ContactReason == "UNDER_FIRE" then
        if bearing and distance then
            leadMessage = string.format("%s - TAKING FIRE! Enemy %s degrees, distance %.1f km. Holding position and requesting immediate CAS!", self.Name, bearingText, distance / 1000)
        else
            leadMessage = string.format("%s - TAKING FIRE! Holding position and requesting immediate CAS!", self.Name)
        end
    else
        if bearing and distance then
            leadMessage = string.format("%s - Enemy spotted ahead %s degrees, distance %.1f km. Holding short and requesting CAS support.", self.Name, bearingText, distance / 1000)
        else
            leadMessage = string.format("%s - Enemy activity detected ahead. Holding short and requesting CAS support.", self.Name)
        end
    end

    self:MessageToAll(leadMessage)

    if self.EnemyPosition then
        local enemyPosText = self:FormatCoordinateForMessage(self.EnemyPosition)
        self:MessageToAll(string.format("%s - %s. Enemy position: %s. Smoke: Green on convoy, Red on enemy.", self.Name, holdLabel, enemyPosText))
    else
        self:MessageToAll(string.format("%s - %s. Enemy position unknown, search for smoke markers.", self.Name, holdLabel))
    end
end

--- Escalate the convoy into an under-fire hold based on combat events
-- @param attackerUnit Unit that fired on the convoy (may be nil)
-- @param friendlyUnit Unit that was hit or destroyed (may be nil)
-- @param EventData Original MOOSE event payload for reference
function MOOSE_CONVOY:OnUnderFire(attackerUnit, friendlyUnit, EventData)
    if not self.Group or not self.Group:IsAlive() then
        return
    end

    local now = timer.getTime()
    if self.ContactReason == "UNDER_FIRE" and (now - (self.LastUnderFireAlert or 0)) < 10 then
        return
    end
    self.LastUnderFireAlert = now

    if friendlyUnit and (not self.ContactPosition or not self.InContact) then
        local friendlyCoord = MOOSE_CONVOY:GetUnitCoordinate(friendlyUnit)
        if friendlyCoord then
            self.ContactPosition = friendlyCoord
        end
    end

    local attacker = attackerUnit
    local attackerName = MOOSE_CONVOY:GetUnitName(attacker)
    if attackerName and self.UnitNames and self.UnitNames[attackerName] then
        attacker = nil -- Attacker is one of ours; ignore to avoid bad bearing data
    end

    MOOSE_CONVOY:Log("WARNING", string.format("%s registering under-fire event", self.Name))
    self:OnContactWithEnemy(attacker, "UNDER_FIRE")
end

--- Check if threats have been cleared
function MOOSE_CONVOY:CheckThreatsCleared()
    local currentPos = self.Group:GetCoordinate()
    if not currentPos then
        return
    end

    local enemyCoalition = (self.Coalition == coalition.side.RED) and "blue" or "red"

    local scanSet = SET_GROUP:New()
        :FilterCoalitions(enemyCoalition)
        :FilterCategoryGround()
        :FilterActive(true)
        :FilterOnce()

    local threatsRemain = false

    scanSet:ForEachGroup(function(group)
        if group and group:IsAlive() then
            local coord = group:GetCoordinate()
            if coord then
                local distance = currentPos:Get2DDistance(coord)
                if distance < THREAT_CLEARED_RANGE then
                    threatsRemain = true
                end
            end
        end
    end)

    if not threatsRemain then
        self:OnThreatsCleared()
    else
        MOOSE_CONVOY:Log("DEBUG", string.format("%s still has threats within %.1f km", self.Name, THREAT_CLEARED_RANGE / 1000))
    end
end

--- Called when threats are cleared
function MOOSE_CONVOY:OnThreatsCleared()
    if not self.InContact then
        return
    end
    
    local now = timer.getTime()
    MOOSE_CONVOY:Log("INFO", string.format("%s threats cleared - resuming movement", self.Name))
    
    self.Status = "MOVING"
    self.InContact = false
    self.ContactReason = nil
    self.EnemyPosition = nil
    self.ContactPosition = nil
    self.LastUnderFireAlert = 0
    self.LastHoldEnforce = 0
    self.LastHoldReleaseTime = nil
    
    -- Pop smoke on current position
    if SMOKE_ON_CLEAR then
        local currentPos = self.Group:GetCoordinate()
        self:MaybeSmokeAt(currentPos, FRIENDFLY_SMOKE_COLOR)
    end
    
    local lastResume = self.LastResumeMessageTime
    local allowResumeMessage = true
    if lastResume and RESUME_MESSAGE_COOLDOWN and RESUME_MESSAGE_COOLDOWN > 0 then
        if (now - lastResume) < RESUME_MESSAGE_COOLDOWN then
            allowResumeMessage = false
        end
    end

    if allowResumeMessage then
        self:MessageToAll(string.format(
            "%s - Area clear! Threats eliminated. Resuming movement to destination. Thank you for the support!",
            self.Name
        ))
        self.LastResumeMessageTime = now
    else
        MOOSE_CONVOY:Log("DEBUG", string.format("%s resume notice suppressed (%.0fs since last)", self.Name, now - lastResume))
    end
    
    -- Resume journey
    self.LastProgressTime = now
    local currentPos = self.Group:GetCoordinate()
    if self:ApplyRouteToDestination("THREATS_CLEARED", true, true) then
        self.LastHoldReleaseTime = now
    end
end

--- Announce convoy is stuck and needs help
function MOOSE_CONVOY:AnnounceStuck()
    local currentPos = self.Group:GetCoordinate()
    local currentText = self:FormatCoordinateForMessage(currentPos)
    local distanceRemaining = currentPos:Get2DDistance(self.DestPoint)
    
    local followUp
    if self.ContactReason == "UNDER_FIRE" then
        followUp = string.format("%s - Still taking fire! Position: %s. Destination %.1f km away. Need CAS immediately!", self.Name, currentText, distanceRemaining / 1000)
    else
        followUp = string.format("%s - Still holding for CAS. Position: %s. Destination %.1f km away. Awaiting air support to clear the route.", self.Name, currentText, distanceRemaining / 1000)
    end

    self:MessageToAll(followUp)
    
    -- Pop smoke again (throttled)
    self:MaybeSmokeAt(currentPos, FRIENDFLY_SMOKE_COLOR)
end

--- Announce progress update
function MOOSE_CONVOY:AnnounceProgress()
    local currentPos = self.Group:GetCoordinate()
    local distanceRemaining = currentPos:Get2DDistance(self.DestPoint)
    if distanceRemaining > self.InitialDistance then
        -- Convoy may have to backtrack to hit the road network; update baseline so progress never goes negative
        self.InitialDistance = distanceRemaining
    end
    local distanceTraveled = self.InitialDistance - distanceRemaining
    local percentComplete = 0
    if self.InitialDistance > 0 then
        percentComplete = (distanceTraveled / self.InitialDistance) * 100
    end
    if percentComplete < 0 then percentComplete = 0 end
    if percentComplete > 100 then percentComplete = 100 end
    
    -- Calculate ETA (rough estimate based on average speed)
    local timeElapsed = timer.getTime() - self.StartTime
    local avgSpeed = 0
    if timeElapsed > 0 then
        avgSpeed = distanceTraveled / timeElapsed  -- m/s
    end
    local eta = 0
    if avgSpeed > 0 then
        eta = distanceRemaining / avgSpeed / 60  -- minutes
    end
    
    self:MessageToAll(string.format(
        "%s - Progress update: %.1f%% complete. Distance remaining: %.1f km. ETA: %d minutes.",
        self.Name,
        percentComplete,
        distanceRemaining / 1000,
        eta
    ))
end

--- Safely and throttled smoke at a coordinate
-- @param coord #COORDINATE or vec3-like table
-- @param color #number SMOKECOLOR
function MOOSE_CONVOY:MaybeSmokeAt(coord, color)
    if not coord then return end

    local now = timer.getTime()
    local id = self.ID or 0
    local last = MOOSE_CONVOY.LastSmokeTime[id] or 0
    if SMOKE_MIN_INTERVAL and SMOKE_MIN_INTERVAL > 0 then
        if last > 0 and (now - last) < SMOKE_MIN_INTERVAL then
            return
        end
    end

    local vec3
    if type(coord) == "table" and coord.GetVec3 then
        vec3 = coord:GetVec3()
    else
        vec3 = coord
    end

    if not vec3 or not vec3.x or not vec3.z then
        return
    end

    trigger.action.smoke(vec3, color or FRIENDLY_SMOKE_COLOR)
    MOOSE_CONVOY.LastSmokeTime[id] = now
end


--- Called when convoy reaches destination
function MOOSE_CONVOY:OnReachedDestination()
    MOOSE_CONVOY:Log("INFO", string.format("%s reached destination successfully", self.Name))
    
    self.Status = "COMPLETED"
    
    local timeElapsed = timer.getTime() - self.StartTime
    local minutes = math.floor(timeElapsed / 60)
    
    self:MessageToAll(string.format(
        "%s - Destination reached! Mission successful. Transit time: %d minutes. Thanks for the escort!",
        self.Name,
        minutes
    ))
    
    -- Pop green smoke
    local currentPos = self.Group:GetCoordinate()
    self:MaybeSmokeAt(currentPos, FRIENDFLY_SMOKE_COLOR)
    
    -- Stop monitoring
    if self.SchedulerID then
        self.SchedulerID:Stop()
    end
    
    -- Remove from active convoys after delay
    SCHEDULER:New(nil,
        function()
            MOOSE_CONVOY.Convoys[self.ID] = nil
            MOOSE_CONVOY:ClearIntelForConvoy(self)
            if self.Group and self.Group:IsAlive() then
                self.Group:Destroy()
            end
        end,
        {}, 30
    )
end

--- Called when convoy is destroyed
function MOOSE_CONVOY:OnDestroyed()
    MOOSE_CONVOY:Log("WARNING", string.format("%s was destroyed", self.Name))
    
    self.Status = "DESTROYED"
    
    self:MessageToAll(string.format(
        "%s - DESTROYED! Convoy has been eliminated. Mission failed.",
        self.Name
    ))
    
    -- Stop monitoring
    if self.SchedulerID then
        self.SchedulerID:Stop()
    end
    
    -- Remove from active convoys and clear any intel marks
    MOOSE_CONVOY.Convoys[self.ID] = nil
    MOOSE_CONVOY:ClearIntelForConvoy(self)
end

--- Send message to all players
function MOOSE_CONVOY:MessageToAll(message)
    MESSAGE:New(message, MESSAGE_DURATION_DEFAULT):ToAll()
    MOOSE_CONVOY:Log("DEBUG", string.format("Message broadcast: %s", message))
end

-------------------------------------------------------------------
-- MARK POINT HANDLER
-------------------------------------------------------------------

--- Handle mark point events
function MOOSE_CONVOY:MarkHandler(EventData)
    local markText = EventData.text or ""
    local markPos = EventData.coordinate
    local markCoalition = EventData.coalition  -- Get coalition of player who placed mark
    local markID = EventData.MarkID  -- Get mark ID for deletion
    
    -- Ignore empty marks or marks with only whitespace
    if not markText or markText == "" or markText:match("^%s*$") then
        return
    end

    if self:IsIntelMark(markID) then
        self:Log("DEBUG", string.format("Ignoring convoy intel mark ID %s", tostring(markID)))
        return
    end
    
    local markTextLower = string.lower(markText)
    
    -- Handle spectator/game master marks - default to Blue coalition
    if not markCoalition or markCoalition == 0 then
        markCoalition = coalition.side.BLUE
        MOOSE_CONVOY:Log("DEBUG", "Mark placed by spectator/neutral - defaulting to Blue coalition")
    end
    
    -- Check if this mark contains our convoy keywords
    local hasSpawnKeyword = string.find(markTextLower, string.lower(CONVOY_SPAWN_KEYWORD))
    local hasDestKeyword = string.find(markTextLower, string.lower(CONVOY_DEST_KEYWORD))
    
    -- Only process marks that contain our keywords
    if not hasSpawnKeyword and not hasDestKeyword then
        return  -- Not a convoy-related mark, ignore silently
    end
    
    -- This is a convoy mark, log it
    MOOSE_CONVOY:Log("DEBUG", string.format("Mark detected: '%s' (Coalition: %d, ID: %s)", markText, markCoalition, tostring(markID)))

    -- Check for spawn keyword
    if hasSpawnKeyword then
        MOOSE_CONVOY:HandleSpawnMark(markPos, markText, markCoalition, markID)
    end

    -- Check for destination keyword
    if hasDestKeyword then
        MOOSE_CONVOY:HandleDestinationMark(markPos, markText, markCoalition, markID)
    end
end

--- Handle convoy spawn mark
function MOOSE_CONVOY:HandleSpawnMark(coordinate, markText, markCoalition, markID)
    MOOSE_CONVOY:Log("INFO", string.format("Processing spawn mark for coalition %d", markCoalition))
    
    local coalitionName = markCoalition == coalition.side.BLUE and "Blue" or "Red"
    
    -- If CTLD zones are required, check if mark is near a valid zone
    if USE_CTLD_ZONES then
        local nearestZone, distance = self:FindNearestCTLDZone(coordinate)
        
        if not nearestZone or distance > SPAWN_ZONE_RADIUS then
            local msg = string.format(
                "Convoy spawn denied: Must mark within %d meters of a Supply or FOB zone. Nearest zone: %s (%.0fm away)",
                SPAWN_ZONE_RADIUS,
                nearestZone and nearestZone.name or "None",
                distance or 0
            )
            MESSAGE:New(msg, MESSAGE_DURATION_DEFAULT):ToCoalition(markCoalition)
            MOOSE_CONVOY:Log("WARNING", msg)
            -- Delete the mark since it was processed (even if rejected)
            if markID then
                trigger.action.removeMark(markID)
                MOOSE_CONVOY:Log("DEBUG", "Removed invalid spawn mark ID: " .. tostring(markID))
            end
            return
        end
        
        -- Use zone center as spawn point
        coordinate = nearestZone.coord
        MOOSE_CONVOY:Log("INFO", string.format("Using zone '%s' as spawn point (distance: %.0fm)", nearestZone.name, distance))
    end
    
    -- Pick a random template
    local templateName = CONVOY_TEMPLATE_NAMES[math.random(#CONVOY_TEMPLATE_NAMES)]
    
    -- Store spawn point for pairing with destination (keyed by coalition)
    if not MOOSE_CONVOY.PendingSpawns then
        MOOSE_CONVOY.PendingSpawns = {}
    end
    
    MOOSE_CONVOY.PendingSpawns[markCoalition] = {
        Template = templateName,
        Position = coordinate,
        Coalition = markCoalition,
        SpawnMarkID = markID,
    }
    
    if PLAYER_CONTROLLED_DESTINATIONS then
        MESSAGE:New(string.format("%s convoy spawn point recorded. Place a second mark with '%s' when ready.", coalitionName, CONVOY_DEST_KEYWORD), MESSAGE_DURATION_SHORT):ToCoalition(markCoalition)
    else
        -- Static destinations - auto-select or show menu
        self:HandleStaticDestination(markCoalition)
    end
end

--- Determine if a convoy is active and controllable
-- @param convoy #table Convoy object
-- @return #boolean
function MOOSE_CONVOY:IsConvoyActive(convoy)
    if not convoy or convoy.Status == "DESTROYED" or convoy.Status == "COMPLETED" then
        return false
    end
    if not convoy.Group or not convoy.Group:IsAlive() then
        return false
    end
    return true
end

--- Locate a convoy to redirect based on mark data
-- @param coalitionID #number Coalition placing the mark
-- @param coordinate #COORDINATE Target coordinate
-- @param markText #string Mark text for optional matching
-- @return #table|nil Convoy selected for redirect
function MOOSE_CONVOY:FindConvoyForRedirection(coalitionID, coordinate, markText)
    local markLower = markText and string.lower(markText) or ""

    -- Exact name match takes priority
    for _, convoy in pairs(self.Convoys or {}) do
        if convoy and convoy.Coalition == coalitionID and self:IsConvoyActive(convoy) then
            local convoyName = convoy.Name and string.lower(convoy.Name) or nil
            if convoyName and markLower ~= "" and string.find(markLower, convoyName, 1, true) then
                return convoy
            end
        end
    end

    -- Otherwise pick the convoy closest to the desired destination
    local bestConvoy = nil
    local bestDistance = 1e12
    for _, convoy in pairs(self.Convoys or {}) do
        if convoy and convoy.Coalition == coalitionID and self:IsConvoyActive(convoy) then
            local convoyCoord = convoy.Group:GetCoordinate()
            if convoyCoord then
                local distance = coordinate:Get2DDistance(convoyCoord)
                if distance < bestDistance then
                    bestDistance = distance
                    bestConvoy = convoy
                end
            end
        end
    end

    return bestConvoy
end

--- Extract a human-readable label from the mark text for messaging
-- @param markText #string
-- @return #string|nil
function MOOSE_CONVOY:ExtractDestinationLabel(markText)
    if not markText or markText == "" then
        return nil
    end

    local text = markText
    local keyword = CONVOY_DEST_KEYWORD or ""
    if keyword ~= "" then
        local lowerText = string.lower(text)
        local lowerKeyword = string.lower(keyword)
        local idx = lowerText:find(lowerKeyword, 1, true)
        if idx then
            local before = text:sub(1, idx - 1)
            local after = text:sub(idx + #keyword)
            text = before .. after
        end
    end

    text = text:gsub("%s+", " ")
    text = text:match("^%s*(.-)%s*$") or ""
    if text == "" then
        return nil
    end
    return text
end

--- Handle convoy destination mark
function MOOSE_CONVOY:HandleDestinationMark(coordinate, markText, markCoalition, markID)
    MOOSE_CONVOY:Log("INFO", string.format("Processing destination mark for coalition %d", markCoalition))
    
    if not PLAYER_CONTROLLED_DESTINATIONS then
        MESSAGE:New("Convoy destinations are controlled by mission designer. Remove mark.", MESSAGE_DURATION_SHORT):ToCoalition(markCoalition)
        -- Delete the mark
        if markID then
            trigger.action.removeMark(markID)
            MOOSE_CONVOY:Log("DEBUG", "Removed invalid destination mark ID: " .. tostring(markID))
        end
        return
    end
    
    if MOOSE_CONVOY.PendingSpawns and MOOSE_CONVOY.PendingSpawns[markCoalition] then
        -- We have a spawn point for this coalition, validate and create the convoy
        local pendingSpawn = MOOSE_CONVOY.PendingSpawns[markCoalition]
        
        -- Check minimum distance
        local distance = pendingSpawn.Position:Get2DDistance(coordinate)
        if distance < MINIMUM_ROUTE_DISTANCE then
            local msg = string.format(
                "Convoy route too short: %.1f km. Minimum distance: %.1f km. Mark a destination further away.",
                distance / 1000,
                MINIMUM_ROUTE_DISTANCE / 1000
            )
            MESSAGE:New(msg, MESSAGE_DURATION_DEFAULT):ToCoalition(markCoalition)
            MOOSE_CONVOY:Log("WARNING", msg)
            -- Delete the mark even though it was rejected
            if markID then
                trigger.action.removeMark(markID)
                MOOSE_CONVOY:Log("DEBUG", "Removed invalid destination mark ID: " .. tostring(markID))
            end
            return
        end
        
        -- Delete the mark before creating convoy
        if markID then
            trigger.action.removeMark(markID)
            MOOSE_CONVOY:Log("DEBUG", "Removed destination mark ID: " .. tostring(markID))
        end
        
        if pendingSpawn.SpawnMarkID then
            trigger.action.removeMark(pendingSpawn.SpawnMarkID)
            MOOSE_CONVOY:Log("DEBUG", "Removed paired spawn mark ID: " .. tostring(pendingSpawn.SpawnMarkID))
        end
        
        self:CreateConvoy(pendingSpawn, coordinate, markCoalition)
    else
        local redirectConvoy = self:FindConvoyForRedirection(markCoalition, coordinate, markText)
        if redirectConvoy then
            if markID then
                trigger.action.removeMark(markID)
                MOOSE_CONVOY:Log("DEBUG", "Removed redirect destination mark ID: " .. tostring(markID))
            end
            local label = self:ExtractDestinationLabel(markText)
            redirectConvoy:RedirectTo(coordinate, {
                label = label,
                coalition = markCoalition,
                reason = "PLAYER_MARK",
            })
        else
            local coalitionName = markCoalition == coalition.side.BLUE and "Blue" or "Red"
            MESSAGE:New(string.format("No active %s convoy available to redirect.", coalitionName), MESSAGE_DURATION_SHORT):ToCoalition(markCoalition)
            if markID then
                trigger.action.removeMark(markID)
                MOOSE_CONVOY:Log("DEBUG", "Removed unused destination mark ID: " .. tostring(markID))
            end
        end
    end
end

--- Handle static destination mode (mission designer controlled)
function MOOSE_CONVOY:HandleStaticDestination(markCoalition)
    if not MOOSE_CONVOY.PendingSpawns or not MOOSE_CONVOY.PendingSpawns[markCoalition] then
        return
    end
    
    local pendingSpawn = MOOSE_CONVOY.PendingSpawns[markCoalition]
    
    -- If no static destinations defined, error
    if #STATIC_DESTINATIONS == 0 then
        MESSAGE:New("No static destinations configured. Contact mission designer.", MESSAGE_DURATION_DEFAULT):ToCoalition(markCoalition)
        MOOSE_CONVOY.PendingSpawns[markCoalition] = nil
        return
    end
    
    -- Pick a random destination
    local destDef = STATIC_DESTINATIONS[math.random(#STATIC_DESTINATIONS)]
    local destCoord = nil
    
    if destDef.zone then
        -- Zone-based destination
        local zone = ZONE:FindByName(destDef.zone)
        if zone then
            destCoord = zone:GetCoordinate()
        else
            MOOSE_CONVOY:Log("ERROR", string.format("Static destination zone '%s' not found", destDef.zone))
        end
    elseif destDef.lat and destDef.lon then
        -- Coordinate-based destination (defaults altitude to ground level when omitted)
        destCoord = COORDINATE:NewFromLLDD(destDef.lat, destDef.lon, destDef.alt or 0)
    end
    
    if not destCoord then
        MESSAGE:New("Invalid destination configuration. Contact mission designer.", MESSAGE_DURATION_DEFAULT):ToCoalition(markCoalition)
        MOOSE_CONVOY.PendingSpawns[markCoalition] = nil
        return
    end
    
    -- Validate minimum distance
    local distance = pendingSpawn.Position:Get2DDistance(destCoord)
    if distance < MINIMUM_ROUTE_DISTANCE then
        MESSAGE:New(string.format("Selected destination too close (%.1f km). Trying another...", distance / 1000), MESSAGE_DURATION_SHORT):ToCoalition(markCoalition)
        -- Could implement retry logic here
        MOOSE_CONVOY.PendingSpawns[markCoalition] = nil
        return
    end
    
    -- Create convoy with static destination
    if pendingSpawn.SpawnMarkID then
        trigger.action.removeMark(pendingSpawn.SpawnMarkID)
        MOOSE_CONVOY:Log("DEBUG", "Removed spawn mark ID after static destination assignment: " .. tostring(pendingSpawn.SpawnMarkID))
    end
    self:CreateConvoy(pendingSpawn, destCoord, markCoalition, destDef.name)
end

--- Create and spawn a convoy
function MOOSE_CONVOY:CreateConvoy(pendingSpawn, destination, markCoalition, destName)
    local convoy = MOOSE_CONVOY:NewConvoy(
        pendingSpawn.Template,
        pendingSpawn.Position,
        destination,
        pendingSpawn.Coalition
    )
    
    convoy.DestinationName = destName  -- Optional name for static destinations
    
    local distance = pendingSpawn.Position:Get2DDistance(destination)
    MOOSE_CONVOY:Log("INFO", string.format("Creating convoy %s - Template: %s, Distance: %.1f km", 
        convoy.Name, pendingSpawn.Template, distance / 1000))
    
    MOOSE_CONVOY.Convoys[convoy.ID] = convoy
    convoy:Spawn()
    
    -- Clear pending spawn for this coalition
    MOOSE_CONVOY.PendingSpawns[markCoalition] = nil
end

-------------------------------------------------------------------
-- INITIALIZATION
-------------------------------------------------------------------

--- Validate configuration and templates
-- @return #boolean success True if all validations pass
function MOOSE_CONVOY:ValidateConfiguration()
    self:Log("INFO", "Starting configuration validation...")
    local allPassed = true
    local results = {}
    
    -- Test 1: Validate convoy templates
    self:Log("INFO", "Test 1: Validating convoy templates...")
    local templateTest = { name = "Convoy Templates", passed = true, details = {} }
    
    if #CONVOY_TEMPLATE_NAMES == 0 then
        templateTest.passed = false
        templateTest.details[#templateTest.details + 1] = "ERROR: No convoy templates configured"
        self:Log("ERROR", "No convoy templates defined in CONVOY_TEMPLATE_NAMES")
        allPassed = false
    else
        for _, templateName in ipairs(CONVOY_TEMPLATE_NAMES) do
            local templateGroup = GROUP:FindByName(templateName)
            if not templateGroup then
                templateTest.passed = false
                templateTest.details[#templateTest.details + 1] = string.format("ERROR: Template '%s' not found", templateName)
                self:Log("ERROR", string.format("Template group '%s' not found in mission", templateName))
                allPassed = false
            else
                templateTest.details[#templateTest.details + 1] = string.format("OK: Template '%s' found", templateName)
                self:Log("INFO", string.format("Template '%s' validated successfully", templateName))
            end
        end
    end
    table.insert(results, templateTest)
    
    -- Test 2: Validate CTLD integration (if enabled)
    if USE_CTLD_ZONES then
        self:Log("INFO", "Test 2: Validating CTLD integration...")
        local ctldTest = { name = "CTLD Integration", passed = true, details = {} }
        
        self.PickupZones, self.FOBZones = self:GetCTLDZones()
        local totalZones = #self.PickupZones + #self.FOBZones
        
        if totalZones == 0 then
            ctldTest.passed = false
            ctldTest.details[#ctldTest.details + 1] = "WARNING: No CTLD zones found"
            self:Log("WARNING", "No CTLD zones found - check CTLD_INSTANCE_NAME or disable USE_CTLD_ZONES")
            allPassed = false
        else
            ctldTest.details[#ctldTest.details + 1] = string.format("OK: Loaded %d pickup zones, %d FOB zones", #self.PickupZones, #self.FOBZones)
            self:Log("INFO", string.format("CTLD zones loaded: %d pickup, %d FOB", #self.PickupZones, #self.FOBZones))
        end
        table.insert(results, ctldTest)
    else
        self:Log("INFO", "Test 2: CTLD integration disabled")
    end
    
    -- Test 3: Validate destination configuration
    self:Log("INFO", "Test 3: Validating destination configuration...")
    local destTest = { name = "Destination Config", passed = true, details = {} }
    
    if PLAYER_CONTROLLED_DESTINATIONS then
        destTest.details[#destTest.details + 1] = "OK: Player-controlled destinations enabled"
        self:Log("INFO", "Destinations: Player-controlled mode active")
    else
        if #STATIC_DESTINATIONS == 0 then
            destTest.passed = false
            destTest.details[#destTest.details + 1] = "ERROR: No static destinations defined"
            self:Log("ERROR", "PLAYER_CONTROLLED_DESTINATIONS is false but STATIC_DESTINATIONS is empty")
            allPassed = false
        else
            destTest.details[#destTest.details + 1] = string.format("OK: %d static destinations configured", #STATIC_DESTINATIONS)
            self:Log("INFO", string.format("Static destinations: %d configured", #STATIC_DESTINATIONS))
        end
    end
    table.insert(results, destTest)
    
    -- Test 4: Validate configuration parameters
    self:Log("INFO", "Test 4: Validating configuration parameters...")
    local configTest = { name = "Config Parameters", passed = true, details = {} }
    
    if CONVOY_SPEED_ROAD <= 0 or CONVOY_SPEED_ROAD > 150 then
        configTest.passed = false
        configTest.details[#configTest.details + 1] = string.format("WARNING: CONVOY_SPEED_ROAD (%d) outside normal range", CONVOY_SPEED_ROAD)
        self:Log("WARNING", "CONVOY_SPEED_ROAD value seems unusual")
    end
    
    if DESTINATION_REACHED_DISTANCE < 50 or DESTINATION_REACHED_DISTANCE > 500 then
        configTest.details[#configTest.details + 1] = string.format("INFO: DESTINATION_REACHED_DISTANCE (%d) may be too small/large", DESTINATION_REACHED_DISTANCE)
        self:Log("INFO", "DESTINATION_REACHED_DISTANCE value noted")
    end
    
    if #configTest.details == 0 then
        configTest.details[#configTest.details + 1] = "OK: All parameters within acceptable ranges"
    end
    self:Log("INFO", "Configuration parameters validated")
    table.insert(results, configTest)
    
    -- Test 5: Validate mark keywords
    self:Log("INFO", "Test 5: Validating mark keywords...")
    local keywordTest = { name = "Mark Keywords", passed = true, details = {} }
    
    if not CONVOY_SPAWN_KEYWORD or CONVOY_SPAWN_KEYWORD == "" then
        keywordTest.passed = false
        keywordTest.details[#keywordTest.details + 1] = "ERROR: CONVOY_SPAWN_KEYWORD not defined"
        self:Log("ERROR", "CONVOY_SPAWN_KEYWORD is empty or nil")
        allPassed = false
    else
        keywordTest.details[#keywordTest.details + 1] = string.format("OK: Spawn keyword: '%s'", CONVOY_SPAWN_KEYWORD)
        self:Log("INFO", "Spawn keyword validated")
    end
    
    if PLAYER_CONTROLLED_DESTINATIONS and (not CONVOY_DEST_KEYWORD or CONVOY_DEST_KEYWORD == "") then
        keywordTest.passed = false
        keywordTest.details[#keywordTest.details + 1] = "ERROR: CONVOY_DEST_KEYWORD not defined"
        self:Log("ERROR", "CONVOY_DEST_KEYWORD is empty or nil")
        allPassed = false
    elseif PLAYER_CONTROLLED_DESTINATIONS then
        keywordTest.details[#keywordTest.details + 1] = string.format("OK: Destination keyword: '%s'", CONVOY_DEST_KEYWORD)
        self:Log("INFO", "Destination keyword validated")
    end
    table.insert(results, keywordTest)
    
    self.ValidationResults = results
    self:Log("INFO", string.format("Configuration validation complete. Overall result: %s", allPassed and "PASSED" or "FAILED"))
    
    return allPassed, results
end

--- Report validation results to players
function MOOSE_CONVOY:ReportValidationResults(allPassed, results)
    if not STARTUP_TEST_REPORT then
        return
    end
    
    local report = {}
    report[#report + 1] = "═══════════════════════════════════════"
    report[#report + 1] = "MOOSE CONVOY SYSTEM v" .. self.Version
    report[#report + 1] = "STARTUP VALIDATION REPORT"
    report[#report + 1] = "═══════════════════════════════════════"
    report[#report + 1] = ""
    
    for _, test in ipairs(results) do
        local status = test.passed and "✓ PASSED" or "✗ FAILED"
        report[#report + 1] = string.format("%s: %s", test.name, status)
        for _, detail in ipairs(test.details) do
            report[#report + 1] = "  " .. detail
        end
        report[#report + 1] = ""
    end
    
    report[#report + 1] = "═══════════════════════════════════════"
    if allPassed then
        report[#report + 1] = "✓ ALL TESTS PASSED"
        report[#report + 1] = "System ready for operations."
        report[#report + 1] = "Place marks to spawn convoys."
    else
        report[#report + 1] = "✗ SOME TESTS FAILED"
        report[#report + 1] = "Check configuration and fix errors."
    end
    report[#report + 1] = "═══════════════════════════════════════"
    
    local reportText = table.concat(report, "\n")
    MESSAGE:New(reportText, MESSAGE_DURATION_LONG):ToAll()
    
    self:Log("INFO", "Validation report displayed to players")
end

--- Initialize the convoy system
function MOOSE_CONVOY:Initialize()
    self:Log("INFO", "Initializing convoy escort system v" .. MOOSE_CONVOY.Version)
    
    -- Validate configuration
    local allPassed, results = self:ValidateConfiguration()
    
    -- Report results to players
    self:ReportValidationResults(allPassed, results)

    -- Ensure combat events are wired before convoys spawn
    self:SetupEventHandlers()

    -- Create F10 menus for situational awareness
    self:SetupCoalitionMenus()
    
    -- Set up mark event handler using world.event
    self:Log("INFO", "Setting up mark event handler...")
    
    local ConvoyMarkHandler = {}
    
    function ConvoyMarkHandler:onEvent(event)
        MOOSE_CONVOY.PendingMarks = MOOSE_CONVOY.PendingMarks or {}

        if event.id == world.event.S_EVENT_MARK_REMOVED then
            if event.idx and MOOSE_CONVOY:IsIntelMark(event.idx) then
                MOOSE_CONVOY:HandleIntelMarkRemoval(event.idx)
                MOOSE_CONVOY:Log("DEBUG", string.format("Intel mark ID %s removed", tostring(event.idx)))
            end
            MOOSE_CONVOY.PendingMarks[event.idx] = nil
            if MOOSE_CONVOY.PendingSpawns then
                for coalitionID, pending in pairs(MOOSE_CONVOY.PendingSpawns) do
                    if pending and pending.SpawnMarkID == event.idx then
                        MOOSE_CONVOY:Log("DEBUG", string.format("Spawn mark ID %s removed before pairing - clearing pending spawn for coalition %s", tostring(event.idx), tostring(coalitionID)))
                        MOOSE_CONVOY.PendingSpawns[coalitionID] = nil
                    end
                end
            end
            return
        end

        if event.id ~= world.event.S_EVENT_MARK_ADDED and event.id ~= world.event.S_EVENT_MARK_CHANGE then
            return
        end

        local markText = event.text or ""
        if markText == "" or markText:match("^%s*$") then
            if event.pos then
                MOOSE_CONVOY.PendingMarks[event.idx] = event.pos
            end
            MOOSE_CONVOY:Log("DEBUG", string.format("Mark event %s received without text yet (ID: %s) - waiting for update", tostring(event.id), tostring(event.idx)))
            return
        end

        local markVec3 = event.pos or MOOSE_CONVOY.PendingMarks[event.idx]
        if not markVec3 then
            MOOSE_CONVOY:Log("WARNING", string.format("Mark event %s missing position data (ID: %s) - cannot process", tostring(event.id), tostring(event.idx)))
            return
        end

        local intelMark = event.idx and MOOSE_CONVOY:IsIntelMark(event.idx)
        if not intelMark then
            env.info("[MOOSE_CONVOY] RAW MARK EVENT DETECTED!")
            env.info(string.format("[MOOSE_CONVOY] Mark text: '%s', Coalition: %s, initiator: %s", 
                tostring(event.text), 
                tostring(event.coalition),
                tostring(event.initiator)))
        end

        -- Convert to MOOSE-style EventData
        local EventData = {
            text = event.text,
            coalition = event.coalition,
            MarkID = event.idx,
            coordinate = COORDINATE:NewFromVec3(markVec3)
        }

        MOOSE_CONVOY.PendingMarks[event.idx] = nil
        MOOSE_CONVOY:MarkHandler(EventData)
    end
    
    world.addEventHandler(ConvoyMarkHandler)
    
    self:Log("INFO", "Mark event handler registered successfully")
    MESSAGE:New("CONVOY SYSTEM: Mark handler active. Place marks with 'convoy' to test.", MESSAGE_DURATION_DEFAULT):ToAll()
    
    if allPassed then
        self:Log("INFO", "Initialization complete - all systems operational")
    else
        self:Log("WARNING", "Initialization complete with warnings/errors - check configuration")
    end
end

-------------------------------------------------------------------
-- START THE SYSTEM
-------------------------------------------------------------------

-- Initialize when mission starts
MOOSE_CONVOY:Initialize()

MOOSE_CONVOY:Log("INFO", "Moose_Convoy.lua script loaded successfully")
