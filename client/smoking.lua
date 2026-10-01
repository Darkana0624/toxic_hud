local Config = require 'config'

-- ============================================================
--  Toxic HUD — ТАМХИ / ВЭЙП (client)
--
--  Анимаци, prop, байрлал / эргэлтийн утгууд нь lusty94_smoking-
--  аас яг хэвээрээ авсан. Ажиллагааг нь ox_inventory + ox_lib
--  дээр дахин бичсэн (эх код qb-core/qb-inventory дээр байсан).
--
--  Урсгал:
--    ox_inventory item ашиглах -> энэ эвент
--    -> server "болох уу?" шалгана (item, асаагуур/шингэн)
--    -> lib.progressCircle (анимаци + prop)
--    -> server item-ийг зарцуулж, stress-ийг бууруулна
--
--  Item-ийг клиент өөрөө хасахгүй — бүх шийдвэр server дээр.
-- ============================================================

if not (Config.Smoking and Config.Smoking.enabled) then return end

local busy = false

local function notify(msg, kind)
    lib.notify({ title = 'Тамхи', description = msg, type = kind or 'error' })
end

RegisterNetEvent('toxic_hud:client:useSmoke', function(data)
    -- ox_inventory нь item нэрийг data.name-аар дамжуулна
    local itemName = type(data) == 'table' and (data.name or data.item) or data
    local cfg = itemName and Config.Smoking.items[itemName]
    if not cfg then return end

    if busy then
        notify('Та аль хэдийн юм хийж байна')
        return
    end

    local ok, reason, extra = lib.callback.await('toxic_hud:server:canSmoke', false, itemName)
    if not ok then
        if reason == 'requires' then
            notify(('Танд %s хэрэгтэй'):format(extra or '...'))
        elseif reason == 'missing' then
            notify('Танд энэ зүйл алга')
        end
        return
    end

    busy = true

    local ped = cache.ped or PlayerPedId()

    -- Prop / анимацийг өөрсдөө удирдана — ингэснээр prop дээр утаа / гэрэл
    -- залгах боломжтой (lib.progressCircle prop-ийн заагчийг буцаадаггүй).
    local prop
    if cfg.prop then
        local model = joaat(cfg.prop)
        lib.requestModel(model, 5000)
        local c = GetEntityCoords(ped)
        prop = CreateObject(model, c.x, c.y, c.z + 0.2, true, true, false)
        SetModelAsNoLongerNeeded(model)
        AttachEntityToEntity(prop, ped, GetPedBoneIndex(ped, cfg.bone or 28422),
            cfg.pos.x, cfg.pos.y, cfg.pos.z, cfg.rot.x, cfg.rot.y, cfg.rot.z,
            true, true, false, true, 1, true)
    end

    local running = true
    local fx = cfg.fx
    if fx then
        CreateThread(function()
            lib.requestNamedPtfx('core')
            local handles = {}
            local function stopAll()
                for i = 1, #handles do StopParticleFxLooped(handles[i], false) end
            end

            -- Тамхины үзүүрээс тасралтгүй гарах утаа
            if fx.trail and prop then
                UseParticleFxAsset('core')
                handles[#handles + 1] = StartParticleFxLoopedOnEntity(fx.trail, prop,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0, fx.scale or 1.0, false, false, false)
            end

            -- 4 секундын мөчлөг: 0-1.5с сорох (гэрэл тод) -> 1.5-4с амнаас утаа гаргах
            local started = GetGameTimer()
            local puffed = false
            while running and DoesEntityExist(ped) do
                local t = ((GetGameTimer() - started) % 4000) / 1000.0
                local drag = t < 1.5

                if drag then puffed = false end

                -- Үзүүр улаасах / вэйпийн LED
                if prop and DoesEntityExist(prop) and (fx.ember or fx.led) then
                    local p = GetOffsetFromEntityInWorldCoords(prop, 0.0, 0.0, 0.0)
                    if fx.ember then
                        local glow = drag and 1.0 or 0.35
                        DrawLightWithRange(p.x, p.y, p.z, 255, 60, 10, 0.35, 1.2 * glow)
                    elseif drag then
                        DrawLightWithRange(p.x, p.y, p.z, 40, 120, 255, 0.4, 1.0)
                    end
                end

                -- Амнаас гарах утаа (мөчлөг бүрт нэг удаа)
                if not drag and not puffed and fx.exhale then
                    puffed = true
                    UseParticleFxAsset('core')
                    local h = StartParticleFxLoopedOnPedBone(fx.exhale, ped,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 31086, fx.scale or 1.0, false, false, false)
                    SetTimeout(1800, function() StopParticleFxLooped(h, false) end)
                end

                Wait(0)
            end
            stopAll()
        end)
    end

    local done = lib.progressCircle({
        duration    = (cfg.duration or 10) * 1000,
        label       = cfg.label or '...',
        position    = 'bottom',
        useWhileDead = false,
        canCancel   = true,
        disable     = { move = false, car = false, combat = true },
        anim        = { dict = cfg.dict, clip = cfg.anim, flag = 49 },
    })

    running = false
    if prop and DoesEntityExist(prop) then DeleteEntity(prop) end

    if not done then
        busy = false
        notify('Цуцлагдлаа')
        return
    end

    -- Амь хасах (тамхи) — клиент талд л хийх боломжтой
    if cfg.health and cfg.health > 0 then
        local ped = cache.ped or PlayerPedId()
        SetEntityHealth(ped, math.max(101, GetEntityHealth(ped) - cfg.health))
    end

    -- Хуяг нэмэх (тохиргоонд 0 бол алгасна)
    if cfg.armour and cfg.armour > 0 then
        local ped = cache.ped or PlayerPedId()
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + cfg.armour))
    end

    TriggerServerEvent('toxic_hud:server:finishSmoke', itemName)

    Wait(500)   -- item spam-аас сэргийлэх бага зэргийн саатал
    busy = false
end)
