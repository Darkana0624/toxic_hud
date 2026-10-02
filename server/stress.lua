local Config = require 'config'

-- ============================================================
--  Toxic HUD - STRESS SYSTEM (server)
--
--  Storage:
--    1) qbx_core metadata.stress  - persists in the DB with the player
--    2) Player(src).state.stress  - statebag, read by other resources
--       (envi-bridge/qbox, jg-stress-addon etc. listen to this)
--
--  The HUD is notified through the 'hud:client:UpdateStress' event -
--  bridge.lua already listens to it, so no extra wiring is needed. It is
--  the standard qb/qbx ecosystem event, so stress written by other
--  scripts also shows up correctly on the HUD.
--
--  DRIVING GIVES NO STRESS - the sources live in client/stress.lua and
--  speed / collisions are not involved there.
-- ============================================================

local qbx = GetResourceState('qbx_core') == 'started'

local function clamp(v)
    local maxv = (Config.Stress and Config.Stress.max) or 100.0
    if v < 0.0 then return 0.0 end
    if v > maxv then return maxv end
    return v
end

---Returns the current stress (0-100)
---
---IMPORTANT: the statebag is the SOURCE OF TRUTH. Other scripts on this
---server (qbx_consumables - food / alcohol, p_ambulancejob - reset on
---revive, envi-bridge) all write Player(src).state.stress DIRECTLY and do
---not touch the metadata. Reading metadata first would overwrite their
---changes. Metadata is only for persistence between sessions (the
---statebag disappears when the server restarts).
---@param src number
---@return number
local function getStress(src)
    local sb = Player(src).state.stress
    if sb ~= nil then return tonumber(sb) or 0.0 end

    if qbx then
        local player = exports.qbx_core:GetPlayer(src)
        if player and player.PlayerData and player.PlayerData.metadata then
            return tonumber(player.PlayerData.metadata.stress) or 0.0
        end
    end
    return 0.0
end

---Sets stress to an exact value
---@param src number
---@param value number
local function setStress(src, value)
    value = clamp(tonumber(value) or 0.0)

    if qbx then
        local player = exports.qbx_core:GetPlayer(src)
        if player then player.Functions.SetMetaData('stress', value) end
    end

    -- statebag (3rd parameter = replicated, readable on the client)
    Player(src).state:set('stress', value, true)

    -- HUD + other qb/qbx compatible scripts
    TriggerClientEvent('hud:client:UpdateStress', src, value)
    return value
end

local function addStress(src, amount)
    amount = tonumber(amount) or 0.0
    if amount <= 0.0 then return end
    return setStress(src, getStress(src) + amount)
end

local function relieveStress(src, amount)
    amount = tonumber(amount) or 0.0
    if amount <= 0.0 then return end
    return setStress(src, getStress(src) - amount)
end

-- ---- Exports (for other resources) ----
exports('GetStress',     function(src) return getStress(src) end)
exports('SetStress',     function(src, v) return setStress(src, v) end)
exports('AddStress',     function(src, v) return addStress(src, v) end)
exports('RelieveStress', function(src, v) return relieveStress(src, v) end)

-- ---- Events ----
RegisterNetEvent('toxic_hud:server:addStress', function(amount)
    addStress(source, amount)
end)

RegisterNetEvent('toxic_hud:server:relieveStress', function(amount)
    relieveStress(source, amount)
end)

-- Standard qb-hud ecosystem events. Many scripts such as lusty94_smoking
-- call these, so we stay compatible.
RegisterNetEvent('hud:server:GainStress', function(amount)
    addStress(source, amount)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    relieveStress(source, amount)
end)

-- ---- Natural decay ----
-- Stress slowly drops to zero while the player does nothing.
if Config.Stress and Config.Stress.enabled then
    CreateThread(function()
        local interval = math.max(5, Config.Stress.decayInterval or 60)
        local amount   = Config.Stress.decayAmount or 1.0
        if amount <= 0.0 then return end

        while true do
            Wait(interval * 1000)
            for _, playerId in ipairs(GetPlayers()) do
                local src = tonumber(playerId)
                if src then
                    local cur = getStress(src)
                    if cur > 0.0 then setStress(src, cur - amount) end
                end
            end
        end
    end)
end

-- When a player joins, restore the statebag from metadata (the statebag
-- does not persist between sessions).
-- qbx_core calls this from the server side as
-- TriggerEvent('QBCore:Server:PlayerLoaded', self), so `source` is not the
-- player ID (it is '') - we take the ID from the Player object that is
-- passed in. It is a server-local event, so AddEventHandler rather than
-- RegisterNetEvent (a client cannot fake-trigger it).
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = tonumber(player and player.PlayerData and player.PlayerData.source)
    if not src or src <= 0 then return end
    SetTimeout(1000, function()
        if not GetPlayerName(src) then return end -- they may have left within 1 second
        setStress(src, getStress(src))
    end)
end)

-- ============================================================
--  p_ambulancejob - OFFICIAL injury hook
--
--  Docs: piotreq-scripts.gitbook.io/.../ambulance-job-v2/api/server-side
--    RegisterNetEvent('p_ambulancejob/onDeathStateChange')
--    parameters: deathType (string), deathData (table)
--    deathType: 'death' | 'bleeding' | 'recovering' | 'none'
--
--  Unlike guessing from client-side health, this is an official,
--  server-side signal, so it is reliable. No stress is added for
--  'recovering' / 'none' (the healing phase).
--
--  Note: p_ambulancejob sets stress to 0 itself when REVIVING a player
--  (state:set('stress', 0) in shared/config.lua). Our system reads the
--  statebag as the source of truth, so it follows that.
-- ============================================================

local D = Config.Stress and Config.Stress.gain and Config.Stress.gain.downed

if D and D.enabled then
    RegisterNetEvent('p_ambulancejob/onDeathStateChange', function(deathType)
        local src = source
        if not src or src == 0 then return end

        if deathType == 'bleeding' then
            addStress(src, D.bleeding or 12.0)
        elseif deathType == 'death' then
            addStress(src, D.death or 20.0)
        end
    end)
end
