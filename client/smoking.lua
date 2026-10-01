local Config = require 'config'

-- ============================================================
--  LS HUD — ТАМХИ / ВЭЙП (client)
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

RegisterNetEvent('ls_hud:client:useSmoke', function(data)
    -- ox_inventory нь item нэрийг data.name-аар дамжуулна
    local itemName = type(data) == 'table' and (data.name or data.item) or data
    local cfg = itemName and Config.Smoking.items[itemName]
    if not cfg then return end

    if busy then
        notify('Та аль хэдийн юм хийж байна')
        return
    end

    local ok, reason, extra = lib.callback.await('ls_hud:server:canSmoke', false, itemName)
    if not ok then
        if reason == 'requires' then
            notify(('Танд %s хэрэгтэй'):format(extra or '...'))
        elseif reason == 'missing' then
            notify('Танд энэ зүйл алга')
        end
        return
    end

    busy = true

    local done = lib.progressCircle({
        duration    = (cfg.duration or 10) * 1000,
        label       = cfg.label or '...',
        position    = 'bottom',
        useWhileDead = false,
        canCancel   = true,
        disable     = { move = false, car = false, combat = true },
        anim        = { dict = cfg.dict, clip = cfg.anim, flag = 49 },
        prop        = cfg.prop and {
            model = cfg.prop,
            bone  = cfg.bone,
            pos   = cfg.pos,
            rot   = cfg.rot,
        } or nil,
    })

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

    TriggerServerEvent('ls_hud:server:finishSmoke', itemName)

    Wait(500)   -- item spam-аас сэргийлэх бага зэргийн саатал
    busy = false
end)
