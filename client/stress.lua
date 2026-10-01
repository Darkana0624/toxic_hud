local Config = require 'config'

-- ============================================================
--  Toxic HUD — STRESS-ийн эх үүсвэрүүд (client)
--
--  НЭМЭГДЭХ:  машинаар мөргөх / унах (ragdoll) / гэмтэх
--  ТАЙЛАГДАХ: хурдтай жолоодох (энд), GYM (hooks_server.lua),
--             хоол-архи (qbx_consumables), тамхи (smoking.lua)
--
--  !!! ЗҮГЭЭР ЖОЛООДОХ нь stress ӨГӨХГҮЙ !!!
--  qb-hud болон ихэнх stress script хурд хэтрүүлэхэд stress
--  НЭМДЭГ. Энд эсрэгээрээ — хурдтай явах нь stress ТАЙЛНА.
--  Машинтай холбоотой цорын ганц нэмэгдүүлэгч нь МӨРГӨЛТ.
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
--  НЭМЭГДЭХ 1 — Машинаар мөргөх
--  Биеийн эвдрэл (0-1000) хэр огцом буурснаар хэмжинэ. Зөвхөн
--  ЖОЛООЧ байх үед — зорчигчид биш.
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
--  НЭМЭГДЭХ 2 — Унах / тэнцвэрээ алдах (ragdoll)
--  ls_core/antipunchspam нударга спам хийхэд тоглогчийг унагадаг.
--  Тэр нь 'ls_core:client:stumbled' эвент илгээдэг (доороос үз).
--  Түүнээс гадна ямар ч шалтгаанаар ragdoll болоход ажиллана.
-- ============================================================
if G.ragdoll and G.ragdoll.enabled then
    local nextRagdollAt = 0

    local function onRagdoll()
        local now = GetGameTimer()
        if now < nextRagdollAt then return end
        nextRagdollAt = now + ((G.ragdoll.cooldown or 10) * 1000)
        addStress(G.ragdoll.amount or 1.5)
    end

    -- antipunchspam-аас шууд дохио (хамгийн нарийвчлалтай зам)
    RegisterNetEvent('ls_core:client:stumbled', onRagdoll)

    -- Ерөнхий ragdoll илрүүлэлт (өндрөөс унах, мотоциклоос нисэх г.м)
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
--  НЭМЭГДЭХ 3 — Гэмтэх (амь буурах)
--  p_ambulancejob тусгай hook гаргадаггүй тул амины бууралтыг
--  шууд хянана. Ингэснээр буудуулах / зодуулах / мөргөх / унах —
--  аль ч тохиолдолд ажиллана.
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
--  ТАЙЛАГДАХ — Хурдтай жолоодох
--  "Салхинд гарах". Тогтмол хурдтай явж байж л тайлагдана;
--  зогсох / удаан явах нь нөлөөлөхгүй.
-- ============================================================
if R.fastDriving and R.fastDriving.enabled then
    CreateThread(function()
        local interval = math.max(5, R.fastDriving.interval or 20)
        local minSpeed = (R.fastDriving.minSpeed or 80) / 3.6   -- км/ц -> м/с

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
--  Энэ серверийн бусад script (qbx_consumables — хоол/архи,
--  p_ambulancejob — сэргээх үед тэглэх) stress-ийг ШУУД
--  Player(src).state.stress дээр бичдэг. Тэдгээрийг HUD дагаж
--  шинэчлэхийн тулд statebag-ийг сонсоно.
-- ============================================================
-- Server ID нь script ачаалах үед хараахан тодорхойгүй байж болох тул
-- bag-ийг шүүхгүйгээр бүртгэж, handler дотор өөрийн bag-тай тулгана.
AddStateBagChangeHandler('stress', nil, function(bagName, _, value)
    if value == nil then return end
    if bagName ~= ('player:%s'):format(GetPlayerServerId(PlayerId())) then return end
    TriggerEvent('hud:client:UpdateStress', value)
end)

-- ============================================================
--  НЭМЭГДЭХ 4 — Цус алдаж хэвтэх хугацаанд тасралтгүй
--
--  p_ambulancejob-ийн баримтжуулсан statebag:
--    LocalPlayer.state.deathType = 'death'|'bleeding'|'recovering'|'none'
--
--  Унах агшны нэг удаагийн stress нь server талд (onDeathStateChange
--  hook-оор) нэмэгддэг. Энд зөвхөн ХЭВТЭЖ БАЙХ хугацааны тасралтгүй
--  өсөлт — эмч удаан ирэх тусам stress нэмэгдэнэ.
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
