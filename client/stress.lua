local Config = require 'config'

-- ============================================================
--  Toxic HUD - STRESS sources (client)
--
--  GAIN:   vehicle crash / falling (ragdoll) / getting hurt
--  RELIEF: fast driving (here), GYM (hooks_server.lua),
--          food / alcohol (qbx_consumables), smoking (smoking.lua)
--
--  !!! DRIVING FAST GIVES NO STRESS !!!
--  qb-hud and most stress scripts ADD stress for speeding. Here it is the
--  opposite - driving fast RELIEVES stress. The only vehicle-related
--  stress gain is a CRASH.
-- ============================================================

if not (Config.Stress and Config.Stress.enabled) then return end

local G = (Config.Stress.gain or {})
local R = (Config.Stress.relief or {})

local function addStress(amount)
    if amount and amount > 0 then
        TriggerServerEvent('toxic_hud:server:addStress', amount)
    end
end

local function relieveStress(amount)
    if amount and amount > 0 then
        TriggerServerEvent('toxic_hud:server:relieveStress', amount)
    end
end

-- ============================================================
--  GAIN 1 - Vehicle crash
--  Measured by how sharply the body health (0-1000) drops. Only while
--  DRIVING - passengers do not count.
-- ============================================================
if G.crash and G.crash.enabled then
    CreateThread(function()
        local lastHealth, lastVeh = nil, nil
        local nextAt = 0

        while true do
            Wait(200)
            local veh = cache.vehicle
            if veh and veh ~= 0 and GetPedInVehicleSeat(veh, -1) == (cache.ped or PlayerPedId()) then
                local health = GetVehicleBodyHealth(veh)

                if veh ~= lastVeh then
                    lastVeh, lastHealth = veh, health
                else
                    local drop = (lastHealth or health) - health
                    lastHealth = health

                    if drop >= (G.crash.minDamage or 40) then
                        local now = GetGameTimer()
                        if now >= nextAt then
                            nextAt = now + ((G.crash.cooldown or 3) * 1000)
                            local amount = drop * (G.crash.perDamage or 0.02)
                            addStress(math.min(amount, G.crash.maxPerHit or 6.0))
                        end
                    end
                end
            else
                lastVeh, lastHealth = nil, nil
            end
        end
    end)
end

-- ============================================================
--  GAIN 2 - Falling / losing balance (ragdoll)
--  ls_core/antipunchspam knocks the player down when they spam punches.
--  It sends the 'ls_core:client:stumbled' event (see below).
--  Besides that, it triggers on any ragdoll.
-- ============================================================
if G.ragdoll and G.ragdoll.enabled then
    local nextRagdollAt = 0

    local function onRagdoll()
        local now = GetGameTimer()
        if now < nextRagdollAt then return end
        nextRagdollAt = now + ((G.ragdoll.cooldown or 10) * 1000)
        addStress(G.ragdoll.amount or 1.5)
    end

    -- Direct signal from antipunchspam (the most precise path)
    RegisterNetEvent('ls_core:client:stumbled', onRagdoll)

    -- Generic ragdoll detection (falling from height, thrown off a bike etc.)
    CreateThread(function()
        local wasRagdoll = false
        while true do
            Wait(500)
            local ped = cache.ped or PlayerPedId()
            local isRag = IsPedRagdoll(ped)
            if isRag and not wasRagdoll then onRagdoll() end
            wasRagdoll = isRag
        end
    end)
end

-- ============================================================
--  GAIN 3 - Getting hurt (health drops)
--  p_ambulancejob has no dedicated hook for this, so we watch health
--  directly. That way it works for being shot / punched / crashing /
--  falling - in every case.
-- ============================================================
if G.injury and G.injury.enabled then
    CreateThread(function()
        local lastHp = nil

        while true do
            Wait(400)
            local ped = cache.ped or PlayerPedId()

            if IsPedDeadOrDying(ped, true) then
                lastHp = nil
            else
                local hp = GetEntityHealth(ped)
                if lastHp and hp < lastHp then
                    local drop = lastHp - hp
                    if drop >= (G.injury.minDrop or 5) then
                        local amount = drop * (G.injury.perHp or 0.25)
                        addStress(math.min(amount, G.injury.maxPerHit or 8.0))
                    end
                end
                lastHp = hp
            end
        end
    end)
end

-- ============================================================
--  RELIEF - Fast driving
--  "Wind in your hair". Only relieves while holding a steady high speed;
--  stopping / driving slowly has no effect.
-- ============================================================
if R.fastDriving and R.fastDriving.enabled then
    CreateThread(function()
        local interval = math.max(5, R.fastDriving.interval or 20)
        local minSpeed = (R.fastDriving.minSpeed or 80) / 3.6   -- km/h -> m/s

        while true do
            Wait(interval * 1000)
            local veh = cache.vehicle
            if veh and veh ~= 0
               and GetPedInVehicleSeat(veh, -1) == (cache.ped or PlayerPedId())
               and GetEntitySpeed(veh) >= minSpeed then
                relieveStress(R.fastDriving.amount or 0.6)
            end
        end
    end)
end

-- ============================================================
--  Statebag -> HUD
--  Other scripts on this server (qbx_consumables - food / alcohol,
--  p_ambulancejob - reset on revive) write stress DIRECTLY to
--  Player(src).state.stress. We listen to the statebag so the HUD
--  follows their changes.
-- ============================================================
-- The server ID may not be known yet when this script loads, so we register
-- without a bag filter and compare against our own bag inside the handler.
AddStateBagChangeHandler('stress', nil, function(bagName, _, value)
    if value == nil then return end
    if bagName ~= ('player:%s'):format(GetPlayerServerId(PlayerId())) then return end
    TriggerEvent('hud:client:UpdateStress', value)
end)

-- ============================================================
--  GAIN 4 - Continuous gain while lying down bleeding
--
--  p_ambulancejob's documented statebag:
--    LocalPlayer.state.deathType = 'death'|'bleeding'|'recovering'|'none'
--
--  The one-off stress at the moment of going down is added server-side
--  (via the onDeathStateChange hook). Here is only the continuous growth
--  WHILE LYING DOWN - the longer the medic takes, the more stress.
-- ============================================================
local WB = G.downed and G.downed.enabled and G.downed.whileBleeding

if WB and WB.enabled then
    CreateThread(function()
        local interval = math.max(5, WB.interval or 15)
        while true do
            Wait(interval * 1000)
            if LocalPlayer.state.deathType == 'bleeding' then
                addStress(WB.amount or 1.0)
            end
        end
    end)
end
