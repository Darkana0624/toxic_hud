local Config = require 'config'

-- ============================================================
--  Toxic HUD - CIGARETTES / VAPE (client)
--
--  Animations, props and offsets are taken as-is from lusty94_smoking.
--  The logic is rewritten on top of ox_inventory + ox_lib (the original
--  was built for qb-core/qb-inventory).
--
--  Flow:
--    ox_inventory item use -> this event
--    -> server asks "can they?" (item, lighter / juice)
--    -> lib.progressCircle (animation / scenario + prop + effects)
--    -> server consumes the item and reduces stress
--
--  The client never removes the item itself - every decision is made on
--  the server.
-- ============================================================

if not (Config.Smoking and Config.Smoking.enabled) then return end

local busy = false

local function notify(msg, kind)
    lib.notify({ title = 'Smoking', description = msg, type = kind or 'error' })
end

-- Puff cycle (ms): draw for the first part, then exhale smoke
local CYCLE, DRAW = 6000, 2500

---Runs the ember glow / smoke puffs until `state.running` becomes false.
local function runEffects(ped, prop, fx, state)
    lib.requestNamedPtfx('core')

    local handBone = fx.handBone or 28422
    local headBone = GetPedBoneIndex(ped, fx.headBone or 31086)
    local started = GetGameTimer()
    local puffed = false

    while state.running and DoesEntityExist(ped) do
        local t = (GetGameTimer() - started) % CYCLE
        local drawing = t < DRAW

        if drawing then puffed = false end

        -- Cigarette tip glow (follows the hand) / vape LED (follows the prop)
        if fx.ember or fx.led then
            local p
            if prop and DoesEntityExist(prop) then
                p = GetEntityCoords(prop)
            else
                p = GetPedBoneCoords(ped, handBone, 0.08, 0.0, 0.0)
            end
            if fx.ember then
                DrawLightWithRange(p.x, p.y, p.z, 255, 60, 10, 0.3, drawing and 1.4 or 0.4)
            elseif drawing then
                DrawLightWithRange(p.x, p.y, p.z, 40, 120, 255, 0.4, 1.0)
            end
        end

        -- Smoke from the mouth (once per cycle, after the draw)
        if not drawing and not puffed and fx.exhale then
            puffed = true
            UseParticleFxAsset('core')
            StartParticleFxNonLoopedOnPedBone(fx.exhale, ped,
                0.0, 0.1, 0.0, 0.0, 0.0, 0.0, headBone, fx.scale or 0.2, false, false, false)
        end

        Wait(0)
    end
end

RegisterNetEvent('toxic_hud:client:useSmoke', function(data)
    -- ox_inventory passes the item name as data.name
    local itemName = type(data) == 'table' and (data.name or data.item) or data
    local cfg = itemName and Config.Smoking.items[itemName]
    if not cfg then return end

    if busy then
        notify('You are already doing something')
        return
    end

    local ok, reason, extra = lib.callback.await('toxic_hud:server:canSmoke', false, itemName)
    if not ok then
        if reason == 'requires' then
            notify(('You need %s'):format(extra or '...'))
        elseif reason == 'missing' then
            notify("You don't have that item")
        end
        return
    end

    busy = true

    local ped = cache.ped or PlayerPedId()

    -- We manage the prop / animation ourselves so effects can be attached to
    -- the prop (lib.progressCircle does not return the prop handle).
    local prop
    if cfg.prop and not cfg.scenario then
        local model = joaat(cfg.prop)
        lib.requestModel(model, 5000)
        local c = GetEntityCoords(ped)
        prop = CreateObject(model, c.x, c.y, c.z + 0.2, true, true, false)
        SetModelAsNoLongerNeeded(model)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, cfg.bone or 28422),
            cfg.pos.x, cfg.pos.y, cfg.pos.z, cfg.rot.x, cfg.rot.y, cfg.rot.z,
            true, true, false, true, 1, true)
    end

    if cfg.scenario then
        ClearPedTasks(ped)
        TaskStartScenarioInPlace(ped, cfg.scenario, 0, true)
    end

    local state = { running = true }
    if cfg.fx then
        CreateThread(function() runEffects(ped, prop, cfg.fx, state) end)
    end

    local done = lib.progressCircle({
        duration    = (cfg.duration or 10) * 1000,
        label       = cfg.label or '...',
        position    = 'bottom',
        useWhileDead = false,
        canCancel   = true,
        disable     = { move = false, car = false, combat = true },
        anim        = (not cfg.scenario and cfg.dict) and { dict = cfg.dict, clip = cfg.anim, flag = 49 } or nil,
    })

    state.running = false
    if cfg.scenario then ClearPedTasks(ped) end
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end

    if not done then
        busy = false
        notify('Cancelled')
        return
    end

    -- Lose health (cigarettes) - only possible on the client
    if cfg.health and cfg.health > 0 then
        SetEntityHealth(ped, math.max(101, GetEntityHealth(ped) - cfg.health))
    end

    -- Add armour (skipped when 0 in the config)
    if cfg.armour and cfg.armour > 0 then
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + cfg.armour))
    end

    TriggerServerEvent('toxic_hud:server:finishSmoke', itemName)

    Wait(500)   -- small delay to prevent item spam
    busy = false
end)
