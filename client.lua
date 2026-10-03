local Config = require 'config'
local Framework = require 'bridge'

-- Framework layer (bridge.lua) - provides qbx_core / qb-core / es_extended /
-- standalone through one unified interface. Loading it with require
-- guarantees the same table reference (removes the global-sharing dependency).

-- ============================================================
--  Helper functions
-- ============================================================

local function sendUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- ============================================================
--  Central management of HUD visibility
--  The HUD is hidden / shown as a whole by combining these conditions:
--    * Player is not logged in
--    * Pause menu (ESC) is active  -> prevents a duplicate HUD showing
--    * Another resource covers the whole screen (took NUI focus:
--      inventory / phone / tablet / menu etc.)
--    * Another script asked to hide it via export (hideHud)
--  It is ALWAYS shown while the settings menu (/toxichud) is open.
-- ============================================================

local hudVisible    = nil    -- last state sent to the NUI (nil = unknown)
local settingsOpen  = false  -- whether the /toxichud settings menu is open
local externalHidden = false -- whether hidden by another script via export
local cinematic     = false  -- temporarily turned off by the player (cinematic mode)

local function computeVisible()
    if not Framework.loggedIn then return false end
    if externalHidden then return false end
    -- Always show when settings are open (our own NUI focus).
    -- Checked BEFORE cinematic - so even when the HUD is turned off the
    -- menu can still be reached via the command.
    if settingsOpen then return true end
    if cinematic then return false end
    if IsPauseMenuActive() then return false end
    -- Hide while another resource covers the whole screen
    if IsNuiFocused() then return false end
    return true
end

local function refreshHudVisibility()
    local v = computeVisible()
    if v ~= hudVisible then
        hudVisible = v
        sendUI(v and 'show' or 'hide')
    end
end

-- Pause menu / NUI focus are not events, so we watch them with a light loop.
CreateThread(function()
    while true do
        Wait(200)
        refreshHudVisibility()
    end
end)

-- ============================================================
--  Exports for other scripts
--  Example: exports['toxic_hud']:hideHud() / exports['toxic_hud']:showHud()
-- ============================================================

exports('hideHud', function()
    externalHidden = true
    refreshHudVisibility()
end)

exports('showHud', function()
    externalHidden = false
    refreshHudVisibility()
end)

exports('toggleHud', function()
    externalHidden = not externalHidden
    refreshHudVisibility()
end)

-- Set directly by passing a bool (true = hide)
exports('setHudHidden', function(hidden)
    externalHidden = hidden and true or false
    refreshHudVisibility()
end)

exports('isHudVisible', function()
    return hudVisible == true
end)

-- ============================================================
--  CINEMATIC MODE - the player temporarily turns the HUD off
--
--  While taking screenshots / recording video the whole HUD disappears.
--  Depending on config the minimap is also turned off and cinematic bars added.
--
--  Key: Config.Cinematic.Key (default F9) - players can rebind it in
--  FiveM's Settings > Key Bindings > FiveM.
--  Chat: /cinematic
--
--  This has a SEPARATE flag from the hideHud() export. So while another
--  script (tablet / inventory) hides the HUD the player's choice is not
--  overridden and it returns to normal afterwards.
-- ============================================================

local function cinematicBarsThread()
    CreateThread(function()
        while cinematic and Config.Cinematic and Config.Cinematic.Bars do
            local h = Config.Cinematic.BarHeight or 0.11
            DrawRect(0.5, h * 0.5,       1.0, h, 0, 0, 0, 255)
            DrawRect(0.5, 1.0 - h * 0.5, 1.0, h, 0, 0, 0, 255)
            Wait(0)
        end
    end)
end

local function setCinematic(state)
    state = state and true or false
    if state == cinematic then return end
    cinematic = state

    refreshHudVisibility()

    -- The DisplayRadar loop updates the radar itself, but we set it once here
    -- directly so we do not have to wait 1 second.
    if Config.Cinematic and Config.Cinematic.HideRadar then
        DisplayRadar(not cinematic)
    end

    if cinematic then cinematicBarsThread() end
end

RegisterCommand('cinematic', function()
    setCinematic(not cinematic)
end, false)

RegisterKeyMapping('cinematic', 'Cinematic mode (temporarily hide HUD)', 'keyboard',
    (Config.Cinematic and Config.Cinematic.Key) or 'F9')

TriggerEvent('chat:addSuggestion', '/cinematic', 'Temporarily hide / show the HUD (cinematic mode)')

-- For other scripts
exports('setCinematic', function(state) setCinematic(state) end)
exports('toggleCinematic', function() setCinematic(not cinematic) end)
exports('isCinematic', function() return cinematic end)

-- Get fuel (ox_fuel / LegacyFuel both use statebag/decor)
local function getFuel(veh)
    -- ox_fuel
    if veh and veh ~= 0 then
        local sb = Entity(veh).state and Entity(veh).state.fuel
        if sb then return math.floor(sb + 0.5) end
        return math.floor(GetVehicleFuelLevel(veh) + 0.5)
    end
    return 0
end

-- ============================================================
--  Login state - show / hide the HUD regardless of framework
--  (bridge.lua fires the "toxic_hud:auth" event on login/logout)
-- ============================================================

AddEventHandler('toxic_hud:auth', function(_)
    -- When the login / logout state changes, update through the central manager
    -- (loggedIn has already been set by bridge.lua).
    hudVisible = nil   -- force the state to be re-evaluated
    refreshHudVisibility()
end)

-- ============================================================
--  Status loop (HP / Armor / Hunger / Thirst / Stamina / Lung)
-- ============================================================

CreateThread(function()
    local last = {}
    local lungMax = (Config.LungCapacity and Config.LungCapacity.maxTime) or 10.0
    if lungMax <= 0.0 then lungMax = 10.0 end
    while true do
        Wait(Config.UpdateInterval)
        if Framework.loggedIn then
            local ped = cache.ped or PlayerPedId()

            local health = GetEntityHealth(ped) - 100   -- GTA: 100 = death floor
            if health < 0 then health = 0 end
            local maxHealth = GetEntityMaxHealth(ped) - 100
            if maxHealth <= 0 then maxHealth = 100 end
            local healthPct = math.floor((health / maxHealth) * 100)

            local armor = GetPedArmour(ped)

            -- Stamina: GetPlayerSprintStaminaRemaining returns 0 (full) -> 100 (depleted),
            -- so remaining stamina is computed as 100 minus that.
            local stamina = nil
            if Config.ShowStamina then
                stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(PlayerId()) + 0.5)
                if stamina < 0 then stamina = 0 elseif stamina > 100 then stamina = 100 end
            end

            -- Voice: whether talking + voice range (pma-voice statebag)
            local talking, voiceRange = nil, nil
            if Config.ShowVoice then
                talking = NetworkIsPlayerTalking(PlayerId())
                local prox = LocalPlayer.state.proximity
                voiceRange = (prox and prox.index) or 2
            end

            -- Lung capacity: remaining underwater breathing time as a percentage.
            -- When full and not underwater (hideWhenFull) send nil to hide it.
            local lung = nil
            if Config.ShowLungCapacity then
                local cfgL = Config.LungCapacity or {}
                local remaining = GetPlayerUnderwaterTimeRemaining(PlayerId())
                if remaining > lungMax then lungMax = remaining end
                lung = math.floor(remaining / lungMax * 100 + 0.5)
                if lung < 0 then lung = 0 elseif lung > 100 then lung = 100 end
                if cfgL.hideWhenFull ~= false and lung >= 100
                   and not IsPedSwimmingUnderWater(ped) then
                    lung = nil
                end
            end

            local hunger = Config.ShowHunger and Framework.hunger and math.floor(Framework.hunger) or nil
            local thirst = Config.ShowThirst and Framework.thirst and math.floor(Framework.thirst) or nil
            local stress = Config.ShowStress and Framework.stress and math.floor(Framework.stress) or nil

            -- Vehicle engine wear (health). Only shown as a circle on the status HUD
            -- while sitting in a vehicle; on foot we send nil to hide the circle.
            -- GetVehicleEngineHealth: 0..1000 -> 0..100%.
            local engineHealth = nil
            local veh = cache.vehicle or GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then
                local eh = GetVehicleEngineHealth(veh)
                if eh < 0 then eh = 0 elseif eh > 1000 then eh = 1000 end
                engineHealth = math.floor(eh / 10 + 0.5)
            end

            -- Only send to the NUI when a value changed (saves cost when idle)
            if healthPct ~= last.health or armor ~= last.armor or hunger ~= last.hunger
               or thirst ~= last.thirst or stress ~= last.stress or stamina ~= last.stamina
               or talking ~= last.voice or voiceRange ~= last.voiceRange
               or engineHealth ~= last.engineHealth or lung ~= last.lung then
                last.health, last.armor = healthPct, armor
                last.hunger, last.thirst, last.stress = hunger, thirst, stress
                last.stamina, last.voice, last.voiceRange = stamina, talking, voiceRange
                last.engineHealth, last.lung = engineHealth, lung
                sendUI('status', {
                    health = healthPct,
                    armor  = armor,
                    hunger = hunger,
                    thirst = thirst,
                    stress = stress,
                    stamina = stamina,
                    voice = talking,
                    voiceRange = voiceRange,
                    engineHealth = engineHealth,
                    lung = lung,
                })
            end
        end
    end
end)

-- ============================================================
--  Speedometer loop
-- ============================================================

-- Lookup table of electric vehicle model hashes
local electricHashes = {}
for _, name in ipairs(Config.ElectricVehicles or {}) do
    electricHashes[GetHashKey(name)] = true
end

-- Diesel vehicle model hashes
local dieselHashes = {}
for _, name in ipairs(Config.DieselVehicles or {}) do
    dieselHashes[GetHashKey(name)] = true
end

-- Seatbelt state. With the JVI integration (Config.JVI.enabled) it comes from
-- JamzVehicleImmersion's IsSeatbeltOn() export; otherwise (or if the export is
-- unavailable) from the LocalPlayer.state.seatbelt statebag.
local function getSeatbelt()
    local jvi = Config.JVI
    if jvi and jvi.enabled and GetResourceState(jvi.resource) == 'started' then
        local ok, buckled = pcall(function() return exports[jvi.resource]:IsSeatbeltOn() end)
        if ok then return buckled == true end
    end
    return LocalPlayer.state.seatbelt or false
end

exports('isSeatbeltOn', getSeatbelt)

-- Automatic speedo style matching the vehicle (or nil)
local function autoStyleFor(veh)
    if not Config.AutoSpeedoStyle then return nil end
    local class = GetVehicleClass(veh)
    local model = GetEntityModel(veh)
    if class == 15 then                       -- 15 = Helicopters
        return 'heli'
    elseif class == 16 then                   -- 16 = Planes
        return 'air'
    elseif class == 8 then                    -- 8 = Motorcycles
        return 'moto'
    elseif class == 13 then                   -- 13 = Cycles (bicycles)
        return 'bike'
    elseif electricHashes[model] then
        return 'ev'
    elseif dieselHashes[model] then
        return 'diesel'
    end
    return 'petrol'                           -- every other vehicle: petrol
end

CreateThread(function()
    -- nil = "state not sent yet". This way, right after joining the server while
    -- not in a vehicle, hide is only sent on the first iteration.
    local shown = nil
    while true do
        -- 50ms only while in a vehicle (so the needle moves smoothly), 250ms
        -- on foot. This noticeably lowers CPU when idle.
        local sleep = 250
        if Framework.loggedIn then
            local veh = cache.vehicle or GetVehiclePedIsIn(cache.ped or PlayerPedId(), false)

            if veh and veh ~= 0 then
                sleep = 50
                if not shown then
                    sendUI('speedo', { visible = true })
                    shown = true
                end

                local rpm     = GetVehicleCurrentRpm(veh)
                local gear    = GetVehicleCurrentGear(veh)
                local fuel    = getFuel(veh)
                local engineOn = GetIsVehicleEngineRunning(veh)
                local seatbelt = getSeatbelt()
                local style   = autoStyleFor(veh)

                -- Speed bar: percentage relative to the vehicle's real top speed
                local spd      = GetEntitySpeed(veh)
                local maxSpeed = GetVehicleEstimatedMaxSpeed(veh)
                local speedPct = (maxSpeed and maxSpeed > 0)
                    and math.min(100, math.floor(spd / maxSpeed * 100 + 0.5)) or 0

                -- Engine health (0-100). GetVehicleEngineHealth returns 0-1000;
                -- negative values (burnt-out engine) -> 0.
                local eh = GetVehicleEngineHealth(veh) or 1000.0
                if eh < 0.0 then eh = 0.0 end
                local engHealth = math.floor(eh / 10 + 0.5)
                if engHealth > 100 then engHealth = 100 end

                local payload = {
                    visible  = true,
                    mps      = spd,                  -- raw speed (m/s), the NUI side converts units
                    speedPct = speedPct,
                    engineHealth = engHealth,
                    rpm      = rpm,
                    gear     = gear,
                    fuel     = fuel,
                    engine   = engineOn,
                    seatbelt = seatbelt,
                    forceStyle = style,              -- air / bike / ev / nil
                    clock    = string.format('%02d:%02d', GetClockHours(), GetClockMinutes()),
                    temp     = 14 + math.floor(8 * math.sin((GetClockHours() - 6) / 24 * math.pi * 2) + 0.5),
                }

                -- Extra data for aviation instruments
                if style == 'air' or style == 'heli' then
                    local coords = GetEntityCoords(veh)
                    local vel    = GetEntityVelocity(veh)
                    payload.alt     = coords.z
                    payload.vspeed  = vel.z
                    payload.heading = GetEntityHeading(veh)
                    payload.roll    = GetEntityRoll(veh)
                    payload.pitch   = GetEntityPitch(veh)
                end

                -- Lights: low beam / high beam - sent for every style except bicycles
                -- (shown on the speedos below).
                if style ~= 'bike' then
                    local _, lightsOn, highbeams = GetVehicleLightsState(veh)
                    payload.highbeam = highbeams == 1 or highbeams == true
                    payload.lights   = lightsOn == 1 or lightsOn == true
                end

                -- Extra indicator lights for the motorcycle cluster
                if style ~= 'bike' then
                    -- GetVehicleIndicatorLights: bit 1 = right, bit 2 = left
                    local ind = GetVehicleIndicatorLights(veh)
                    payload.indLeft  = (ind & 2) ~= 0
                    payload.indRight = (ind & 1) ~= 0
                end

                sendUI('speedo', payload)
            else
                -- send hide if shown == nil (initial) or true (just left the vehicle)
                if shown ~= false then
                    sendUI('speedo', { visible = false })
                    shown = false
                end
            end
        else
            sleep = 1000
        end
        Wait(sleep)
    end
end)

-- ============================================================
--  Time / money / job / street loop
-- ============================================================

CreateThread(function()
    while true do
        Wait(1000)
        if Framework.loggedIn then
            local hours = GetClockHours()
            local minutes = GetClockMinutes()
            local timeStr = string.format('%02d:%02d', hours, minutes)

            sendUI('info', {
                id     = GetPlayerServerId(PlayerId()),
                cash   = Framework.cash or 0,
                bank   = Framework.bank or 0,
                prefix = Config.MoneyPrefix,
                time   = timeStr,
                job    = Framework.job or 'Unemployed',
                grade  = Framework.grade or '',
            })
        end
    end
end)

-- ============================================================
--  Compass / Street loop (top center)
--  From the direction the camera is facing, computes heading / degrees and
--  the names of the current and left / right intersecting streets.
-- ============================================================

local COMPASS_DIRS = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }

-- Get the street name at a point
local function streetAt(x, y, z)
    local hash = GetStreetNameAtCoord(x, y, z)
    local name = GetStreetNameFromHashKey(hash)
    if name and name ~= '' then return name end
    return ''
end

CreateThread(function()
    local last = {}
    while true do
        if Framework.loggedIn and Config.ShowStreetInfo then
            Wait(250)
            local ped = cache.ped or PlayerPedId()
            local coords = GetEntityCoords(ped)

            -- Direction the camera is facing (heading): 0 = North, positive = counter-clockwise
            local camHeading = GetGameplayCamRot(2).z % 360.0
            if camHeading < 0 then camHeading = camHeading + 360.0 end

            -- Compass bearing (0 = North, increases clockwise)
            local bearing = (360.0 - camHeading) % 360.0
            local dirIndex = math.floor((bearing + 22.5) / 45.0) % 8
            local dir = COMPASS_DIRS[dirIndex + 1]

            -- Compute left / right points (relative to the view direction)
            local rad = math.rad(camHeading)
            local dist = 25.0
            local rx, ry = math.cos(rad) * dist, math.sin(rad) * dist  -- right vector

            local streetName  = streetAt(coords.x, coords.y, coords.z)
            local streetRight = streetAt(coords.x + rx, coords.y + ry, coords.z)
            local streetLeft  = streetAt(coords.x - rx, coords.y - ry, coords.z)

            -- If left / right equal the current one, blank them to remove duplication
            if streetRight == streetName then streetRight = '' end
            if streetLeft == streetName then streetLeft = '' end

            local deg = math.floor(bearing)
            -- Do not resend to the NUI if unchanged (saves cost)
            if deg ~= last.deg or dir ~= last.dir or streetName ~= last.street
               or streetLeft ~= last.left or streetRight ~= last.right then
                last.deg, last.dir, last.street = deg, dir, streetName
                last.left, last.right = streetLeft, streetRight
                sendUI('info', {
                    onlyCompass = true,
                    dir    = dir,
                    deg    = deg,
                    street = streetName,
                    streetLeft = streetLeft,
                    streetRight = streetRight,
                })
            end
        else
            Wait(500)
        end
    end
end)

-- ============================================================
--  Minimap (radar) - always show, even on foot
--  There is no need to call DisplayRadar(true) every frame - the state is
--  persistent, so re-confirming it every second is enough
--  (completely removes the per-frame CPU cost).
-- ============================================================

CreateThread(function()
    while true do
        -- During cinematic mode (if config allows) also turn the radar off
        DisplayRadar(not (cinematic and Config.Cinematic and Config.Cinematic.HideRadar))
        Wait(1000)
    end
end)

-- ============================================================
--  Minimap (radar) position - Config.MinimapPosition
--     'bottom-left' - GTA default. The radar is not touched at all.
--     'top-right'   - top-right corner.
--
--  PRINCIPLE: the game's three components (minimap = image + compass,
--  minimap_mask = visible area, minimap_blur = edge fade) naturally have
--  DIFFERENT offsets / sizes relative to each other. If you position them
--  separately assuming "top right", the mask separates from its image
--  and the compass floats on its own.
--
--  So here we do NOT place each component SEPARATELY. Instead we keep the
--  original (vanilla) values and shift ALL THREE BY THE SAME distance.
--  That way the relationship between them is never broken -
--  the mask always matches its image and the compass stays on the map.
--
--  The shift distance is calculated automatically from safezone / resolution /
--  aspect ratio, so there is essentially nothing to tune by hand. If needed,
--  Config.MinimapNudge can adjust it slightly.
--
--  LIMITATIONS (the game's own):
--    * "Bigmap" (Z key) still opens at the bottom left
--    * The native health / armour arc position will be off - but Toxic HUD
--      hides them via Config.HideNativeHealthArmour
-- ============================================================

-- GTA's original positions. alignX = 'L' (from left), alignY = 'B' (from bottom);
-- we KEEP this anchor and only add to x/y. positive x = right,
-- positive y = up.
local MM_VANILLA = {
    { comp = 'minimap',      x =  0.000, y = -0.047, w = 0.1638, h = 0.183 },
    { comp = 'minimap_mask', x =  0.000, y =  0.000, w = 0.128,  h = 0.200 },
    { comp = 'minimap_blur', x = -0.010, y =  0.025, w = 0.262,  h = 0.300 },
}

-- Real size of the radar, as a screen fraction (the game's official formula).
local function minimapFrac()
    local resX, resY = GetActiveScreenResolution()
    local aspect = GetAspectRatio(false)
    if not aspect or aspect ~= aspect or aspect <= 0.0 then
        aspect = resX / resY
    end

    local inset = 0.5 * (1.0 - (GetSafeZoneSize() or 1.0))
    if inset < 0.0 then inset = 0.0 elseif inset > 0.1 then inset = 0.1 end

    return 1.0 / (4.0 * aspect), 1.0 / 5.674, inset
end

-- Position the player chose themselves (/toxichud -> "Edit layout" -> drag the
-- MINIMAP box). Screen fraction, from the TOP-LEFT corner. nil = config default.
local playerMM = nil

-- Whether the radar needs to be moved from the game's default
local function minimapMoved()
    return playerMM ~= nil or Config.MinimapPosition == 'top-right'
end

-- The shift needed to move the bottom-left radar to its target position
-- (screen fraction). positive x = right, positive y = up.
local function minimapShift()
    local wFrac, hFrac, inset = minimapFrac()
    local nudge = Config.MinimapNudge or {}
    local dx, dy

    if playerMM then
        -- The player's choice takes priority. The NUI gives it from the top-left
        -- corner (y from the top), so convert to a value measured from the bottom.
        dx = playerMM.x - inset
        dy = (1.0 - playerMM.y - hFrac) - inset
    elseif Config.MinimapPosition == 'top-right' then
        -- 2*inset is subtracted from both: one inset from the current (left / bottom)
        -- edge, the other from the target (right / top) edge.
        dx = 1.0 - 2.0 * inset - wFrac
        dy = 1.0 - 2.0 * inset - hFrac
    else
        return 0.0, 0.0
    end

    return dx + (nudge.x or 0.0), dy + (nudge.y or 0.0)
end

-- Whether the radar was touched last time. When the player resets their position
-- the vanilla values must be written back ONCE - this is used to know that.
local mmApplied = false

local function applyMinimapLayout()
    if not minimapMoved() then
        if not mmApplied then return end
        mmApplied = false
        for i = 1, #MM_VANILLA do
            local v = MM_VANILLA[i]
            SetMinimapComponentPosition(v.comp, 'L', 'B',
                v.x + 0.0, v.y + 0.0, v.w + 0.0, v.h + 0.0)
        end
        return
    end

    local dx, dy = minimapShift()
    mmApplied = true
    for i = 1, #MM_VANILLA do
        local v = MM_VANILLA[i]
        -- The Y axis of SetMinimapComponentPosition points DOWNWARD
        -- (vanilla minimap y = -0.047 means UP from the bottom edge).
        -- dy is the "shift up" amount, so SUBTRACT it. If added, the radar goes
        -- below the screen and disappears completely.
        SetMinimapComponentPosition(v.comp, 'L', 'B',
            v.x + dx + 0.0, v.y - dy + 0.0, v.w + 0.0, v.h + 0.0)
    end
end

-- Since the player can change the position, the loop always runs
-- (the game restores its original position after respawn / resolution
-- change / bigmap). When there is nothing to move it does just 1 comparison.
if Config.MinimapPosition == 'top-right' or Config.AllowPlayerMinimapMove then
    CreateThread(function()
        while not NetworkIsSessionStarted() do Wait(500) end
        while true do
            applyMinimapLayout()
            Wait(1000)
        end
    end)
end

-- ============================================================
--  GTA's NATIVE health / armour bars - the green (health) and blue (armour)
--  strips that appear under the minimap. Toxic HUD shows these itself, so
--  they are hidden to avoid duplicates.
--
--  SETUP_HEALTH_ARMOUR method of the "minimap" scaleform:
--     0 = both visible (game default)
--     1 = health only
--     2 = armour only
--     3 = both hidden
--  The game resets this to its own value every frame, so it must be
--  overwritten every frame (a single scaleform call - low cost).
--  No need to replace / stream minimap.gfx.
--
--  WARNING: examples commonly found online toggle SetRadarBigmapEnabled
--  (true) -> (false) to "restore" the scaleform. DO NOT DO THIS - during
--  loading that turn-off call can get lost, and the minimap gets stuck in
--  its expanded (bigmap) form.
--  The loop below runs every frame, so no restore trick is needed.
-- ============================================================

if Config.HideNativeHealthArmour then
    CreateThread(function()
        -- Wait until the player has fully entered the world. On the loading screen
        -- the radar does not exist yet, so touching it then risks the call being
        -- lost and bigmap getting stuck on.
        while not NetworkIsSessionStarted() do Wait(500) end
        while not DoesEntityExist(PlayerPedId()) do Wait(250) end

        -- Cleanup: if bigmap (expanded minimap) got stuck on, return to the
        -- normal small minimap.
        SetRadarBigmapEnabled(false, false)

        local mm = RequestScaleformMovie('minimap')
        local tries = 0
        while not HasScaleformMovieLoaded(mm) and tries < 300 do
            Wait(10)
            tries = tries + 1
        end
        if not HasScaleformMovieLoaded(mm) then
            print('^3[toxic_hud]^7 minimap scaleform failed to load - native health/armour bars will remain')
            return
        end

        while true do
            BeginScaleformMovieMethod(mm, 'SETUP_HEALTH_ARMOUR')
            ScaleformMovieMethodAddParamInt(3)
            EndScaleformMovieMethod()
            Wait(0)
        end
    end)
end

-- ============================================================
--  Screen info - for the HUD's responsive scaling
--  The NUI side knows the screen resolution itself, but GTA's
--  "Safe Zone Size" setting and aspect ratio can only be obtained here.
--  The minimap (radar) position / size depends on them, so the HUD can
--  line up exactly with it.
-- ============================================================

-- Computes the real rectangle of GTA's radar (minimap) in pixels.
-- Official formula:
--     width  = resX / (4 * aspectRatio)
--     height = resY / 5.674
--     left   = resX * 0.5 * (1 - safeZone)
--     bottom = resY * 0.5 * (1 - safeZone)
-- IMPORTANT: do NOT shorten the width to resY/4. That shortcut is only
-- correct when aspectRatio == resX/resY; on stretched, letterboxed or
-- multi-monitor setups GetAspectRatio(false) differs from resX/resY,
-- so the frame would drift sideways off the minimap.
local function minimapRect()
    local resX, resY = GetActiveScreenResolution()
    local aspect   = GetAspectRatio(false)
    local safeZone = GetSafeZoneSize()

    -- Guard: if aspect is 0 / nan, fall back to the screen ratio
    if not aspect or aspect ~= aspect or aspect <= 0.0 then
        aspect = resX / resY
    end

    local inset = 0.5 * (1.0 - safeZone)
    if inset < 0.0 then inset = 0.0 elseif inset > 0.1 then inset = 0.1 end

    local mm = {
        w = resX / (4.0 * aspect),
        h = resY / 5.674,
        x = resX * inset,
        b = resY * inset,
    }

    -- If the radar was moved to the top-right corner, move the frame rectangle
    -- to that corner as well. CSS uses a single convention, mm.x (from the left)
    -- and mm.b (from the bottom), so recomputing only these is enough -
    -- .status-frame and .status-wrap follow automatically.
    if Config.MinimapPosition == 'top-right' then
        -- Use EXACTLY the same shift applied to the radar - that way the frame
        -- does not separate from the image even with a nudge (MinimapNudge).
        local dx, dy = minimapShift()
        mm.x = mm.x + resX * dx
        mm.b = mm.b + resY * dy
    end

    -- If the player's minimap is non-standard (expanded map, round / square
    -- minimap mods etc.), override manually from the config.
    local ov = Config.MinimapOverride
    if ov and ov.enabled then
        if ov.w then mm.w = resX * ov.w end
        if ov.h then mm.h = resY * ov.h end
        if ov.x then mm.x = resX * ov.x end
        if ov.b then mm.b = resY * ov.b end
    end

    return resX, resY, aspect, safeZone, mm
end

local function sendScreenInfo()
    local resX, resY, aspect, safeZone, mm = minimapRect()
    sendUI('screen', {
        resX     = resX,
        resY     = resY,
        aspect   = aspect,
        safeZone = safeZone,
        -- radar rectangle (px) - the NUI side uses this directly
        mmX = math.floor(mm.x + 0.5),
        mmB = math.floor(mm.b + 0.5),
        mmW = math.floor(mm.w + 0.5),
        mmH = math.floor(mm.h + 0.5),
        -- Which corner it is in - the NUI puts the status cluster on the opposite side
        mmPos = Config.MinimapPosition or 'bottom-left',
    })
end

-- ------------------------------------------------------------
--  /mmpos - nudge the radar position from in game
--
--  The shift is calculated automatically, so this is usually not needed. But
--  if another resource changes the minimap (square minimap,
--  expanded map etc.) it can be off by 2-3 thousandths.
--
--     /mmpos                -> prints the current nudge
--     /mmpos 0.01 -0.005    -> ADDS that amount to x, y
--     /mmpos reset          -> zeroes the nudge
--
--  Write the value that fits into Config.MinimapNudge in config.lua.
--  The three components move together, so the mask / compass never separate.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
--  The player moves the minimap themselves (/toxichud -> "Edit layout")
--
--  Inside the NUI a box (#mmghost) representing the minimap rectangle is
--  draggable. The drop position is received here: x, y are screen fractions,
--  from the TOP-LEFT corner. If an empty object arrives (Reset) it returns
--  to the game's default position.
--
--  The position is stored with the other HUD elements in the 'toxichud:pos'
--  KVP - when the NUI reloads it sends it back to this callback,
--  so it persists after a reconnect too.
-- ------------------------------------------------------------

RegisterNUICallback('setMinimapPos', function(data, cb)
    if not Config.AllowPlayerMinimapMove then
        cb('disabled')
        return
    end

    if type(data) == 'table' and type(data.x) == 'number' and type(data.y) == 'number' then
        playerMM = { x = data.x, y = data.y }
    else
        playerMM = nil
    end

    applyMinimapLayout()
    sendScreenInfo()   -- the HUD frame / status cluster follows the radar
    cb('ok')
end)


if Config.MinimapPosition == 'top-right' then
    RegisterCommand('mmpos', function(_, args)
        Config.MinimapNudge = Config.MinimapNudge or { x = 0.0, y = 0.0 }
        local n = Config.MinimapNudge

        if args[1] == 'reset' then
            n.x, n.y = 0.0, 0.0
        elseif args[1] then
            local dx, dy = tonumber(args[1]), tonumber(args[2])
            if not dx or not dy then
                print('^1[toxic_hud]^7 /mmpos <dx> <dy>  |  /mmpos reset  |  /mmpos')
                return
            end
            n.x = (n.x or 0.0) + dx
            n.y = (n.y or 0.0) + dy
        end

        applyMinimapLayout()
        sendScreenInfo()
        print(('^2[toxic_hud]^7 MinimapNudge = { x = %.4f, y = %.4f }  <- copy into config.lua')
            :format(n.x or 0.0, n.y or 0.0))
    end, false)

    TriggerEvent('chat:addSuggestion', '/mmpos', 'Nudge the minimap position (dx dy)')
end

-- The player can change graphics settings (resolution / safezone) mid-game, so
-- a light loop watches them and sends to the NUI only when they change.
CreateThread(function()
    local lastX, lastY, lastSafe, lastAspect = 0, 0, -1.0, -1.0
    while true do
        local resX, resY = GetActiveScreenResolution()
        local safe   = GetSafeZoneSize()
        local aspect = GetAspectRatio(false)
        if resX ~= lastX or resY ~= lastY
            or math.abs(safe - lastSafe) > 0.001
            or math.abs(aspect - lastAspect) > 0.001 then
            lastX, lastY, lastSafe, lastAspect = resX, resY, safe, aspect
            sendScreenInfo()
        end
        Wait(2000)
    end
end)

-- ============================================================
--  Resource start / stop
-- ============================================================

AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        sendUI('config', {
            useMPH = Config.UseMPH,
            lang = Config.Language,
            scale = Config.HudScale,
            resourceName = GetCurrentResourceName(),
        })
        sendScreenInfo()
        -- Even if the resource was restarted mid-session, restore the state if already logged in
        hudVisible = nil
        refreshHudVisibility()
    end
end)

-- ============================================================
--  HUD settings - open the element-moving menu
-- ============================================================

RegisterNUICallback('closeSettings', function(_, cb)
    SetNuiFocus(false, false)
    settingsOpen = false
    refreshHudVisibility()
    cb('ok')
end)

-- ============================================================
--  Saving HUD settings (client KVP - survives reconnects)
--  The browser's localStorage is cleared when reconnecting to a server,
--  so position / style / unit are saved reliably with SetResourceKvp.
-- ============================================================

-- One-time migration from the old 'lshud:' / 'dkhud:' keys to the new 'toxichud:'
-- (because of the rename, saved positions / styles are not lost).
local function kvpGet(key)
    local v = GetResourceKvpString('toxichud:' .. key)
    if v == nil then
        v = GetResourceKvpString('lshud:' .. key) or GetResourceKvpString('dkhud:' .. key)
        if v ~= nil then SetResourceKvp('toxichud:' .. key, v) end
    end
    return v
end

RegisterNUICallback('saveSetting', function(data, cb)
    if data and data.key then
        local k = 'toxichud:' .. data.key
        if data.value == nil or data.value == '' then
            DeleteResourceKvp(k)
        else
            SetResourceKvp(k, tostring(data.value))
        end
    end
    cb('ok')
end)

RegisterNUICallback('loadSettings', function(_, cb)
    -- This call confirms the NUI page has loaded, so resend the screen
    -- info (it may have been lost the first time).
    sendScreenInfo()
    cb({
        pos   = kvpGet('pos'),
        style = kvpGet('style'),
        unit  = kvpGet('unit'),
        lang  = kvpGet('lang'),
        scale = kvpGet('scale'),
        statusLayout = kvpGet('statusLayout'),

        -- Server defaults. The 'config' message is sent when the resource starts,
        -- but if the NUI page's JS has not loaded yet it is LOST
        -- (SendNUIMessage does not queue). So the NUI pulls these itself,
        -- together, so the config arrives completely in every case.
        cfgUseMPH = Config.UseMPH,
        cfgLang   = Config.Language,
        cfgScale  = Config.HudScale,
    })
end)

-- Settings open only with the /toxichud command (no key binding).
RegisterCommand('toxichud', function()
    settingsOpen = true
    refreshHudVisibility()   -- always show the HUD when opening settings
    SetNuiFocus(true, true)
    sendUI('openSettings', {})
end, false)

-- Chat suggestion
TriggerEvent('chat:addSuggestion', '/toxichud', 'Open the Toxic HUD settings')

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        sendUI('hide')
    end
end)
