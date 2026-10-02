local Config = require 'config'

-- ============================================================
--  Toxic HUD — ТАМХИ / ВЭЙП (server)
--
--  Item-ийн эзэмшил шалгах, зарцуулах, хайрцгаас ширхэг гаргах
--  ажиллагаа. Анимаци / prop нь client талд.
--
--  Эх сурвалж: lusty94_smoking (qb-core + qb-inventory). Энд
--  ox_inventory дээр дахин бичсэн бөгөөд stress бууралтыг
--  server/stress.lua дээгүүр дамжуулна (клиент итгэмжлэгдэхгүй).
-- ============================================================

if not (Config.Smoking and Config.Smoking.enabled) then return end

local ox = GetResourceState('ox_inventory') == 'started'

if not ox then
    print('^3[toxic_hud]^7 ox_inventory эхлээгүй тул тамхины систем идэвхгүй')
    return
end

local function count(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

---Item ашиглах хүсэлтийг БҮРЭН server талд шалгаж гүйцэтгэнэ.
---Клиент зөвхөн "би энэ item-ийг ашиглаж дууслаа" гэж мэдэгдэнэ;
---үлдэгдэл, шаардлагатай item, stress — бүгд эндээс шийдэгдэнэ.
lib.callback.register('toxic_hud:server:canSmoke', function(src, itemName)
    local cfg = Config.Smoking.items[itemName]
    if not cfg then return false, 'unknown' end
    if count(src, itemName) < 1 then return false, 'missing' end

    if cfg.requires and count(src, cfg.requires.item) < 1 then
        return false, 'requires', cfg.requires.label or cfg.requires.item
    end

    return true
end)

RegisterNetEvent('toxic_hud:server:finishSmoke', function(itemName)
    local src = source
    local cfg = Config.Smoking.items[itemName]
    if not cfg then return end

    -- Дахин шалгана — progressCircle-ийн хугацаанд item алга болсон байж болно
    if count(src, itemName) < 1 then return end
    if cfg.requires and count(src, cfg.requires.item) < 1 then return end

    -- Хайрцаг задлахад ширхэг багтахгүй бол хайрцгийг АЛДАЛГҮЙ үлдээнэ
    if cfg.returns and not exports.ox_inventory:CanCarryItem(src, cfg.returns.item, cfg.returns.amount or 1) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Тамхи', description = 'Таны шуудай дүүрсэн байна', type = 'error',
        })
        return
    end

    -- Үндсэн item-ийг зарцуулах (вэйп өөрөө үлдэнэ)
    if not cfg.keepItem then
        if not exports.ox_inventory:RemoveItem(src, itemName, 1) then return end
    end

    -- Шаардлагатай item-ийг магадлалаар зарцуулах (вэйп шингэн)
    if cfg.requires and cfg.consumesRequired and cfg.consumesRequired > 0 then
        if math.random() < cfg.consumesRequired then
            exports.ox_inventory:RemoveItem(src, cfg.requires.item, 1)
        end
    end

    -- Хайрцаг задлах -> ширхэг олгох
    if cfg.returns then
        exports.ox_inventory:AddItem(src, cfg.returns.item, cfg.returns.amount or 1)
    end

    -- Stress бууруулах
    if cfg.stress and cfg.stress > 0 then
        exports[GetCurrentResourceName()]:RelieveStress(src, cfg.stress)
    end
end)
