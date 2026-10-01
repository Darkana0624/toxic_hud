local Config = require 'config'
local Framework = require 'bridge'

-- Framework давхарга (bridge.lua) — qbx_core / qb-core / es_extended /
-- standalone-ийг нэгдсэн интерфейсээр өгнө. require-ээр ачаалснаар ижил
-- хүснэгтийн заагчийг баталгаатай авна (global хуваалцах хамаарлыг арилгана).

-- ============================================================
--  Туслах функцууд
-- ============================================================

local function sendUI(action, data)
    SendNUIMessage({ action = action, data = data })
end

-- ============================================================
--  HUD харагдах төлвийн төвлөрсөн менежмент
--  Доорх нөхцлүүдийг нэгтгэж HUD-г бүхэлд нь нуух/харуулна:
--    * Тоглогч нэвтрээгүй
--    * Pause menu (ESC) идэвхтэй  -> давхар HUD харагдахаас сэргийлнэ
--    * Өөр resource дэлгэцийг бүхэлд нь эзэлсэн (NUI focus авсан:
--      inventory / phone / tablet / menu г.м)
--    * Гадны script export-оор нуухыг хүссэн (hideHud)
--  Тохиргооны цэс (/lshud) нээлттэй үед нь үргэлж харуулна.
-- ============================================================

local hudVisible    = nil    -- NUI рүү сүүлд илгээсэн төлөв (nil = мэдэгдээгүй)
local settingsOpen  = false  -- /lshud тохиргооны цэс нээлттэй эсэх
local externalHidden = false -- гадны script export-оор нуусан эсэх
local cinematic     = false  -- тоглогч өөрөө түр унтраасан (cinematic mode)

local function computeVisible()
    if not Framework.loggedIn then return false end
    if externalHidden then return false end
    -- Тохиргоо нээлттэй бол (өөрийн NUI focus) заавал харуулна.
    -- Cinematic-аас ДЭЭГҮҮР шалгана — ингэснээр HUD унтраалттай байхад
    -- ч F7 дарж цэс рүү орох боломжтой хэвээр үлдэнэ.
    if settingsOpen then return true end
    if cinematic then return false end
    if IsPauseMenuActive() then return false end
    -- Өөр resource дэлгэц бүхэлд нь эзэлсэн үед нуух
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

-- Pause menu / NUI focus нь event биш тул хөнгөн давталтаар хянана.
CreateThread(function()
    while true do
        Wait(200)
        refreshHudVisibility()
    end
end)

-- ============================================================
--  Бусад script-д зориулсан export-ууд
--  Жишээ: exports['ls_hud']:hideHud() / exports['ls_hud']:showHud()
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

-- bool дамжуулж шууд тохируулах (true = нуух)
exports('setHudHidden', function(hidden)
    externalHidden = hidden and true or false
    refreshHudVisibility()
end)

exports('isHudVisible', function()
    return hudVisible == true
end)

-- ============================================================
--  CINEMATIC MODE — тоглогч HUD-ээ түр унтраах
--
--  Скриншот / видео бичих үед HUD бүхэлдээ алга болно. Тохиргооноос
--  хамаарч minimap-ыг ч хамт унтрааж, кино маягийн хар зураас нэмнэ.
--
--  Товч: Config.Cinematic.Key (анхдагч F9) — тоглогч FiveM-ийн
--  Settings > Key Bindings > FiveM хэсгээс дураараа сольж болно.
--  Чат: /cinematic
--
--  Энэ нь exports-ийн hideHud()-ээс ТУСДАА тугтай. Тиймээс tablet /
--  inventory зэрэг гадны script HUD-ыг нууж байхад тоглогчийн сонголт
--  дарагдахгүй, буцаад хэвийндээ орно.
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

    -- Radar-ыг DisplayRadar давталт өөрөө дагаж шинэчилнэ, гэхдээ 1 секунд
    -- хүлээлгэхгүйн тулд энд шууд нэг удаа тавина.
    if Config.Cinematic and Config.Cinematic.HideRadar then
        DisplayRadar(not cinematic)
    end

    if cinematic then cinematicBarsThread() end
end

RegisterCommand('cinematic', function()
    setCinematic(not cinematic)
end, false)

RegisterKeyMapping('cinematic', 'Cinematic mode (HUD түр унтраах)', 'keyboard',
    (Config.Cinematic and Config.Cinematic.Key) or 'F9')

TriggerEvent('chat:addSuggestion', '/cinematic', 'HUD-ыг түр унтраах / асаах (cinematic mode)')

-- Гадны script-д зориулав
exports('setCinematic', function(state) setCinematic(state) end)
exports('toggleCinematic', function() setCinematic(not cinematic) end)
exports('isCinematic', function() return cinematic end)

-- Түлшийг авах (ox_fuel / LegacyFuel аль аль нь statebag/decor ашигладаг)
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
--  Нэвтрэх төлөв — framework-аас үл хамааран HUD харуулах / нуух
--  (bridge.lua login/logout үед "lshud:auth" event дамжуулна)
-- ============================================================

AddEventHandler('lshud:auth', function(_)
    -- Нэвтрэх/гарах төлөв өөрчлөгдөхөд төвлөрсөн менежментээр шинэчилнэ
    -- (loggedIn-ийг bridge.lua аль хэдийн тохируулсан байна).
    hudVisible = nil   -- төлвийг дахин баталгаажуулна
    refreshHudVisibility()
end)

-- ============================================================
--  Status loop (HP / Armor / Hunger / Thirst)
-- ============================================================

CreateThread(function()
    local last = {}
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

            -- Stamina: GetPlayerSprintStaminaRemaining нь 0 (дүүрэн) -> 100 (барагдсан)
            -- буцаадаг тул үлдсэн тэнхээг 100-аас хасч тооцно.
            local stamina = nil
            if Config.ShowStamina then
                stamina = math.floor(100 - GetPlayerSprintStaminaRemaining(PlayerId()) + 0.5)
                if stamina < 0 then stamina = 0 elseif stamina > 100 then stamina = 100 end
            end

            -- Voice: ярьж байгаа эсэх + voice range (pma-voice statebag)
            local talking, voiceRange = nil, nil
            if Config.ShowVoice then
                talking = NetworkIsPlayerTalking(PlayerId())
                local prox = LocalPlayer.state.proximity
                voiceRange = (prox and prox.index) or 2
            end

            local hunger = Config.ShowHunger and Framework.hunger and math.floor(Framework.hunger) or nil
            local thirst = Config.ShowThirst and Framework.thirst and math.floor(Framework.thirst) or nil
            local stress = Config.ShowStress and Framework.stress and math.floor(Framework.stress) or nil

            -- Машины хөдөлгүүрийн элэгдэл (эрүүл мэнд). Зөвхөн машинд сууж
            -- байх үед status дээр circle хэлбэрээр харагдана; явган бол nil
            -- илгээж circle-г нууна. GetVehicleEngineHealth: 0..1000 -> 0..100%.
            local engineHealth = nil
            local veh = cache.vehicle or GetVehiclePedIsIn(ped, false)
            if veh and veh ~= 0 then
                local eh = GetVehicleEngineHealth(veh)
                if eh < 0 then eh = 0 elseif eh > 1000 then eh = 1000 end
                engineHealth = math.floor(eh / 10 + 0.5)
            end

            -- Утга өөрчлөгдсөн үед л NUI рүү илгээнэ (idle үед зардал хэмнэнэ)
            if healthPct ~= last.health or armor ~= last.armor or hunger ~= last.hunger
               or thirst ~= last.thirst or stress ~= last.stress or stamina ~= last.stamina
               or talking ~= last.voice or voiceRange ~= last.voiceRange
               or engineHealth ~= last.engineHealth then
                last.health, last.armor = healthPct, armor
                last.hunger, last.thirst, last.stress = hunger, thirst, stress
                last.stamina, last.voice, last.voiceRange = stamina, talking, voiceRange
                last.engineHealth = engineHealth
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
                })
            end
        end
    end
end)

-- ============================================================
--  Speedometer loop
-- ============================================================

-- Цахилгаан машины model hash-уудын хайлтын хүснэгт
local electricHashes = {}
for _, name in ipairs(Config.ElectricVehicles or {}) do
    electricHashes[GetHashKey(name)] = true
end

-- Дизель машины model hash-ууд
local dieselHashes = {}
for _, name in ipairs(Config.DieselVehicles or {}) do
    dieselHashes[GetHashKey(name)] = true
end

-- Тухайн машинд тохирох автомат speedo загвар (эсвэл nil)
local function autoStyleFor(veh)
    if not Config.AutoSpeedoStyle then return nil end
    local class = GetVehicleClass(veh)
    local model = GetEntityModel(veh)
    if class == 15 then                       -- 15 = Helicopters
        return 'heli'
    elseif class == 16 then                   -- 16 = Planes
        return 'air'
    elseif class == 8 then                    -- 8 = Motorcycles (мотоцикл)
        return 'moto'
    elseif class == 13 then                   -- 13 = Cycles (унадаг дугуй)
        return 'bike'
    elseif electricHashes[model] then
        return 'ev'
    elseif dieselHashes[model] then
        return 'diesel'
    end
    return 'petrol'                           -- бусад бүх машин: бензин
end

CreateThread(function()
    -- nil = "төлөв хараахан илгээгээгүй". Ингэснээр сервер рүү ороод
    -- машинд суугаагүй байхад эхний давталтад л hide илгээгдэнэ.
    local shown = nil
    while true do
        -- Машинд байгаа үед л 50ms (зүү жигд хөдлөхөд), явган үед
        -- 250ms-ээр шалгана. Ингэснээр idle үед CPU мэдэгдэхүйц буурна.
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
                local seatbelt = LocalPlayer.state.seatbelt or false
                local style   = autoStyleFor(veh)

                -- Хурдны зураас: машины бодит дээд хурдтай харьцуулсан хувь
                local spd      = GetEntitySpeed(veh)
                local maxSpeed = GetVehicleEstimatedMaxSpeed(veh)
                local speedPct = (maxSpeed and maxSpeed > 0)
                    and math.min(100, math.floor(spd / maxSpeed * 100 + 0.5)) or 0

                -- Хөдөлгүүрийн эрүүл мэнд (0-100). GetVehicleEngineHealth нь
                -- 0-1000 буцаадаг; сөрөг утга (шатсан хөдөлгүүр) -> 0.
                local eh = GetVehicleEngineHealth(veh) or 1000.0
                if eh < 0.0 then eh = 0.0 end
                local engHealth = math.floor(eh / 10 + 0.5)
                if engHealth > 100 then engHealth = 100 end

                local payload = {
                    visible  = true,
                    mps      = spd,                  -- түүхий хурд (m/s), нэгжийг NUI талд хөрвүүлнэ
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

                -- Нисэхийн багажид зориулсан нэмэлт дата
                if style == 'air' or style == 'heli' then
                    local coords = GetEntityCoords(veh)
                    local vel    = GetEntityVelocity(veh)
                    payload.alt     = coords.z
                    payload.vspeed  = vel.z
                    payload.heading = GetEntityHeading(veh)
                    payload.roll    = GetEntityRoll(veh)
                    payload.pitch   = GetEntityPitch(veh)
                end

                -- Гэрэл: ойрын (low beam) / холын (high beam) — унадаг дугуйнаас
                -- бусад бүх загварт илгээнэ (доорх speedo-нууд дээр харуулна).
                if style ~= 'bike' then
                    local _, lightsOn, highbeams = GetVehicleLightsState(veh)
                    payload.highbeam = highbeams == 1 or highbeams == true
                    payload.lights   = lightsOn == 1 or lightsOn == true
                end

                -- Мотоциклын кластерт зориулсан нэмэлт заагч гэрэл
                if style ~= 'bike' then
                    -- GetVehicleIndicatorLights: bit 1 = баруун, bit 2 = зүүн
                    local ind = GetVehicleIndicatorLights(veh)
                    payload.indLeft  = (ind & 2) ~= 0
                    payload.indRight = (ind & 1) ~= 0
                end

                sendUI('speedo', payload)
            else
                -- shown == nil (анх) эсвэл true (машинаас буусан) бол hide илгээнэ
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
--  Цаг / мөнгө / job / гудамж loop
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
--  Compass / Street loop (дээд гол)
--  Камерын харж буй өнцгөөр зүг/градус, одоогийн болон
--  зүүн/баруун талын огтлолцох гудамжны нэрийг тооцоолно.
-- ============================================================

local COMPASS_DIRS = { 'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW' }

-- Тухайн цэг дэх гудамжны нэрийг авах
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

            -- Камерын харж буй чиглэл (heading): 0 = Хойд, эерэг = цагийн зүүний эсрэг
            local camHeading = GetGameplayCamRot(2).z % 360.0
            if camHeading < 0 then camHeading = camHeading + 360.0 end

            -- Compass bearing (0 = Хойд, цагийн зүүний дагуу нэмэгдэнэ)
            local bearing = (360.0 - camHeading) % 360.0
            local dirIndex = math.floor((bearing + 22.5) / 45.0) % 8
            local dir = COMPASS_DIRS[dirIndex + 1]

            -- Зүүн / баруун талын цэгүүдийг тооцоолох (харааны чиглэлд харьцангуй)
            local rad = math.rad(camHeading)
            local dist = 25.0
            local rx, ry = math.cos(rad) * dist, math.sin(rad) * dist  -- баруун вектор

            local streetName  = streetAt(coords.x, coords.y, coords.z)
            local streetRight = streetAt(coords.x + rx, coords.y + ry, coords.z)
            local streetLeft  = streetAt(coords.x - rx, coords.y - ry, coords.z)

            -- Зүүн/баруун нь одоогийнхтой ижил бол хоосон болгож давхцлыг арилгана
            if streetRight == streetName then streetRight = '' end
            if streetLeft == streetName then streetLeft = '' end

            local deg = math.floor(bearing)
            -- Өмнөхтэй ижил бол NUI рүү дахин илгээхгүй (зардал хэмнэнэ)
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
--  Minimap (radar) — явган үед ч үргэлж харуулах
--  DisplayRadar(true)-г frame бүрт дуудах шаардлагагүй — төлөв нь
--  тогтвортой хадгалагддаг тул 1 секунд тутамд дахин баталгаажуулахад
--  хангалттай (frame бүрийн CPU зардлыг бүрэн арилгана).
-- ============================================================

CreateThread(function()
    while true do
        -- Cinematic mode үед (тохиргоо зөвшөөрвөл) radar-ыг ч унтраана
        DisplayRadar(not (cinematic and Config.Cinematic and Config.Cinematic.HideRadar))
        Wait(1000)
    end
end)

-- ============================================================
--  Minimap (radar)-ийн байрлал — Config.MinimapPosition
--     'bottom-left' — GTA-гийн анхдагч. Radar-ийг огт хөндөхгүй.
--     'top-right'   — баруун дээд булан.
--
--  ЗАРЧИМ: тоглоомын гурван бүрдэл (minimap = зураг+компас,
--  minimap_mask = харагдах муж, minimap_blur = захын бүдгэрэлт) нь
--  анхнаасаа ХАРИЛЦАН ӨӨР offset / хэмжээтэй байдаг. Тэдгээрийг тус
--  тусад нь "баруун дээш" гэж таамаглан бичвэл маск зурагтайгаа
--  зөрж, компас тусдаа хөвдөг.
--
--  Тиймээс энд бүрдэл бүрийг ТУСАД НЬ байрлуулахгүй. Оронд нь
--  анхны (vanilla) утгуудыг хэвээр нь үлдээж, ГУРВУУЛАНГ НЬ НЭГ ИЖИЛ
--  зайгаар шилжүүлнэ. Ингэснээр хоорондын харьцаа огт эвдрэхгүй —
--  маск үргэлж зурагтайгаа таарч, компас газрын зурган дээрээ үлдэнэ.
--
--  Шилжих зайг safezone / нягтрал / дүрсний харьцаанаас автоматаар
--  боддог тул гараар тааруулах зүйл үндсэндээ байхгүй. Шаардлагатай
--  бол Config.MinimapNudge-ээр бага зэрэг нударч болно.
--
--  ХЯЗГААРЛАЛТ (тоглоомын өөрийнх):
--    * "Bigmap" (Z товч) хэвээр зүүн доод буланд нээгдэнэ
--    * Үндсэн health / armour arc байрлал зөрнө — гэхдээ LS HUD
--      тэдгээрийг Config.HideNativeHealthArmour-оор нуудаг
-- ============================================================

-- GTA-гийн анхны байрлалууд. alignX = 'L' (зүүнээс), alignY = 'B' (доороос);
-- энэ анкорыг ХЭВЭЭР үлдээж, зөвхөн x/y дээр нэмнэ. x эерэг = баруун тийш,
-- y эерэг = дээш.
local MM_VANILLA = {
    { comp = 'minimap',      x =  0.000, y = -0.047, w = 0.1638, h = 0.183 },
    { comp = 'minimap_mask', x =  0.000, y =  0.000, w = 0.128,  h = 0.200 },
    { comp = 'minimap_blur', x = -0.010, y =  0.025, w = 0.262,  h = 0.300 },
}

-- Radar-ийн бодит хэмжээ, дэлгэцийн хувиар (тоглоомын албан ёсны томьёо).
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

-- Тоглогч өөрөө сонгосон байрлал (F7 -> "Байрлал засах" -> MINIMAP хайрцгийг
-- чирэх). Дэлгэцийн хувиар, ЗҮҮН ДЭЭД булангаар. nil = config-ийн анхдагч.
local playerMM = nil

-- Radar-ийг тоглоомын анхдагчаас хөдөлгөх шаардлагатай эсэх
local function minimapMoved()
    return playerMM ~= nil or Config.MinimapPosition == 'top-right'
end

-- Зүүн доод буланд байгаа radar-ыг очих байрлал руу нь зөөхөд шаардагдах
-- шилжилт (дэлгэцийн хувиар). x эерэг = баруун тийш, y эерэг = дээш.
local function minimapShift()
    local wFrac, hFrac, inset = minimapFrac()
    local nudge = Config.MinimapNudge or {}
    local dx, dy

    if playerMM then
        -- Тоглогчийн сонголт давуу эрхтэй. NUI нь зүүн дээд булангаар
        -- (y дээрээс) өгдөг тул доороос хэмжсэн утга руу хөрвүүлнэ.
        dx = playerMM.x - inset
        dy = (1.0 - playerMM.y - hFrac) - inset
    elseif Config.MinimapPosition == 'top-right' then
        -- Хоёуланд нь 2*inset хасагдана: нэг inset нь одоогийн (зүүн/доод)
        -- захаас, нөгөө нь очих (баруун/дээд) захаас.
        dx = 1.0 - 2.0 * inset - wFrac
        dy = 1.0 - 2.0 * inset - hFrac
    else
        return 0.0, 0.0
    end

    return dx + (nudge.x or 0.0), dy + (nudge.y or 0.0)
end

-- Хамгийн сүүлд radar-ыг хөндсөн эсэх. Тоглогч байрлалаа reset хийхэд
-- vanilla утгыг НЭГ УДАА буцааж бичих шаардлагатай — үүнийг мэдэхэд хэрэглэнэ.
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
        -- SetMinimapComponentPosition-ийн Y тэнхлэг ДООШОО чиглэдэг
        -- (vanilla minimap y = -0.047 нь доод захаас ДЭЭШ гэсэн үг).
        -- dy бол "дээш шилжих" хэмжээ тул ХАСНА. Нэмбэл radar дэлгэцийн
        -- доогуур гарч бүрмөсөн алга болно.
        SetMinimapComponentPosition(v.comp, 'L', 'B',
            v.x + dx + 0.0, v.y - dy + 0.0, v.w + 0.0, v.h + 0.0)
    end
end

-- Тоглогч байрлалаа өөрчилж болох тул давталтыг үргэлж ажиллуулна
-- (тоглоом respawn / нягтрал солих / bigmap-ийн дараа байрлалаа
--  анхныхаараа сэргээдэг). Хөдөлгөх зүйлгүй үед 1 харьцуулалт л хийнэ.
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
--  GTA-гийн ҮНДСЭН health / armour бар — minimap-ийн доор гарч
--  ирдэг ногоон (амь) ба цэнхэр (хуяг) зураас. LS HUD өөрөө
--  эдгээрийг харуулдаг тул давхардуулахгүйн тулд нууна.
--
--  "minimap" scaleform-ийн SETUP_HEALTH_ARMOUR арга:
--     0 = хоёулаа харагдана (тоглоомын анхдагч)
--     1 = зөвхөн амь
--     2 = зөвхөн хуяг
--     3 = аль аль нь нуугдана
--  Тоглоом frame бүрт өөрийн утгаараа дахин тохируулдаг тул
--  frame бүрт дарж бичих ёстой (нэг scaleform дуудлага — зардал бага).
--  minimap.gfx файл солих / stream хийх шаардлагагүй.
--
--  АНХААР: интернэтэд түгээмэл байдаг жишээнүүд scaleform-ийг
--  "сэргээхийн" тулд SetRadarBigmapEnabled(true) -> (false) гэж
--  тольдог. ҮҮНИЙГ ХИЙХГҮЙ — ачаалалтын үед тэр унтраах дуудлага
--  алдагдаж, minimap өргөтгөсөн (bigmap) хэлбэрээрээ гацдаг.
--  Доорх давталт frame бүрт ажилладаг тул сэргээх заль хэрэггүй.
-- ============================================================

if Config.HideNativeHealthArmour then
    CreateThread(function()
        -- Тоглогч ертөнцөд бүрэн орох хүртэл хүлээнэ. Ачаалах дэлгэц
        -- дээр байхад radar хараахан байхгүй тул тэр үед хандвал
        -- дуудлага алдагдаж, bigmap асаалттай гацах эрсдэлтэй.
        while not NetworkIsSessionStarted() do Wait(500) end
        while not DoesEntityExist(PlayerPedId()) do Wait(250) end

        -- Цэвэрлэгээ: bigmap (өргөтгөсөн minimap) асаалттай гацсан байвал
        -- энгийн жижиг minimap руу буцаана.
        SetRadarBigmapEnabled(false, false)

        local mm = RequestScaleformMovie('minimap')
        local tries = 0
        while not HasScaleformMovieLoaded(mm) and tries < 300 do
            Wait(10)
            tries = tries + 1
        end
        if not HasScaleformMovieLoaded(mm) then
            print('^3[ls_hud]^7 minimap scaleform ачаалагдсангүй — үндсэн health/armour бар хэвээр үлдэнэ')
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
--  Дэлгэцийн мэдээлэл — HUD-ийн responsive масштабад зориулав
--  NUI тал нь дэлгэцийн нягтралыг өөрөө мэддэг ч, GTA-гийн
--  "Safe Zone Size" тохиргоо ба aspect ratio-г зөвхөн эндээс л
--  авах боломжтой. Эдгээрээс minimap (radar)-ийн байрлал/хэмжээ
--  хамаардаг тул HUD түүнтэй яг зэрэгцэж чадна.
-- ============================================================

-- GTA-гийн radar (minimap)-ийн бодит тэгш өнцөгтийг пикселээр тооцоолно.
-- Албан ёсны томьёо:
--     өргөн  = resX / (4 * aspectRatio)
--     өндөр  = resY / 5.674
--     зүүн   = resX * 0.5 * (1 - safeZone)
--     доод   = resY * 0.5 * (1 - safeZone)
-- ЧУХАЛ: өргөнийг resY/4 гэж товчилж БОЛОХГҮЙ. Тэр товчлол нь зөвхөн
-- aspectRatio == resX/resY үед зөв бөгөөд дэлгэц сунгасан (stretched),
-- letterbox эсвэл олон дэлгэцийн тохиргоонд GetAspectRatio(false) нь
-- resX/resY-ээс зөрдөг тул хүрээ minimap-аас хажуу тийш гүйдэг.
local function minimapRect()
    local resX, resY = GetActiveScreenResolution()
    local aspect   = GetAspectRatio(false)
    local safeZone = GetSafeZoneSize()

    -- Хамгаалалт: aspect 0 / nan ирвэл дэлгэцийн харьцаанд шилжинэ
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

    -- Radar-ийг баруун дээд буланд зөөсөн бол хүрээний тэгш өнцөгтийг ч
    -- тэр булан руу шилжүүлнэ. CSS нь mm.x (зүүнээс) ба mm.b (доороос)
    -- гэсэн нэг л конвенц ашигладаг тул зөвхөн эдгээрийг дахин бодоход
    -- хангалттай — .status-frame болон .status-wrap автоматаар дагана.
    if Config.MinimapPosition == 'top-right' then
        -- Radar-т хэрэглэсэн ЯГ ижил шилжилтийг ашиглана — ингэснээр
        -- нударга (MinimapNudge) хийсэн ч хүрээ зурагнаасаа салахгүй.
        local dx, dy = minimapShift()
        mm.x = mm.x + resX * dx
        mm.b = mm.b + resY * dy
    end

    -- Тоглогчийн minimap стандарт бус бол (өргөтгөсөн газрын зураг,
    -- дугуй/дөрвөлжин minimap mod г.м) config-оос гараар дарж бичнэ.
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
        -- radar-ийн тэгш өнцөгт (px) — NUI тал үүнийг шууд хэрэглэнэ
        mmX = math.floor(mm.x + 0.5),
        mmB = math.floor(mm.b + 0.5),
        mmW = math.floor(mm.w + 0.5),
        mmH = math.floor(mm.h + 0.5),
        -- Аль буланд байгаа нь — NUI status кластерыг эсрэг тал руу нь тавина
        mmPos = Config.MinimapPosition or 'bottom-left',
    })
end

-- ------------------------------------------------------------
--  /mmpos — radar-ийн байрлалыг тоглоом дундаас нударч тохируулах
--
--  Шилжилт нь автоматаар бодогддог тул ихэвчлэн хэрэггүй. Гэхдээ
--  minimap-ийг өөрчилдөг өөр resource байвал (дөрвөлжин minimap,
--  өргөтгөсөн газрын зураг г.м) 2-3 мянганы нэгжээр зөрж болно.
--
--     /mmpos                -> одоогийн нударгыг хэвлэнэ
--     /mmpos 0.01 -0.005    -> x, y-г тэр хэмжээгээр НЭМЖ нударна
--     /mmpos reset          -> нударгыг тэглэнэ
--
--  Таарсан утгаа config.lua-гийн Config.MinimapNudge руу бичнэ.
--  Гурван бүрдэл хамт шилждэг тул маск / компас хэзээ ч салахгүй.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
--  Тоглогч minimap-ийг өөрөө зөөх (F7 -> "Байрлал засах")
--
--  NUI дотор minimap-ийн тэгш өнцөгтийг төлөөлсөн хайрцаг (#mmghost)
--  чирэгддэг. Тавьсан газрыг энд хүлээж авна: x, y нь дэлгэцийн хувь,
--  ЗҮҮН ДЭЭД булангаар. Хоосон объект ирвэл (Reset) тоглоомын анхдагч
--  байрлал руу буцаана.
--
--  Байрлал нь бусад HUD элементийн хамт 'lshud:pos' KVP дотор
--  хадгалагдана — NUI дахин ачаалагдахдаа энэ callback руу буцааж
--  илгээдэг тул reconnect хийсний дараа ч хэвээр үлдэнэ.
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
    sendScreenInfo()   -- HUD-ийн хүрээ / status кластер radar-аа дагана
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
                print('^1[ls_hud]^7 /mmpos <dx> <dy>  |  /mmpos reset  |  /mmpos')
                return
            end
            n.x = (n.x or 0.0) + dx
            n.y = (n.y or 0.0) + dy
        end

        applyMinimapLayout()
        sendScreenInfo()
        print(('^2[ls_hud]^7 MinimapNudge = { x = %.4f, y = %.4f }  <- config.lua-д хуулна уу')
            :format(n.x or 0.0, n.y or 0.0))
    end, false)

    TriggerEvent('chat:addSuggestion', '/mmpos', 'Minimap-ийн байрлалыг нударч тохируулах (dx dy)')
end

-- Тоглогч график тохиргоогоо (нягтрал / safezone) дундуур өөрчилж болох тул
-- хөнгөн давталтаар хянаж, өөрчлөгдсөн үед л NUI рүү илгээнэ.
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
--  Resource эхлэх / зогсох
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
        -- Resource дунд restart хийгдсэн ч аль хэдийн нэвтэрсэн бол төлвийг сэргээнэ
        hudVisible = nil
        refreshHudVisibility()
    end
end)

-- ============================================================
--  HUD тохиргоо — элемент зөөх цэс нээх
-- ============================================================

RegisterNUICallback('closeSettings', function(_, cb)
    SetNuiFocus(false, false)
    settingsOpen = false
    refreshHudVisibility()
    cb('ok')
end)

-- ============================================================
--  HUD тохиргоо хадгалах (client KVP — reconnect-д тэсвэртэй)
--  Браузерын localStorage сервер дахин холбогдоход цэвэрлэгддэг тул
--  байрлал / загвар / нэгжийг SetResourceKvp-ээр найдвартай хадгална.
-- ============================================================

-- Хуучин 'dkhud:' түлхүүрээс шинэ 'lshud:' рүү нэг удаагийн шилжүүлэг.
-- (resource dk_hud -> ls_hud болж нэр солигдсон тул тоглогчийн хадгалсан
--  байрлал / загвар / нэгж алдагдахгүй.)
local function kvpGet(key)
    local v = GetResourceKvpString('lshud:' .. key)
    if v == nil then
        v = GetResourceKvpString('dkhud:' .. key)
        if v ~= nil then SetResourceKvp('lshud:' .. key, v) end
    end
    return v
end

RegisterNUICallback('saveSetting', function(data, cb)
    if data and data.key then
        local k = 'lshud:' .. data.key
        if data.value == nil or data.value == '' then
            DeleteResourceKvp(k)
        else
            SetResourceKvp(k, tostring(data.value))
        end
    end
    cb('ok')
end)

RegisterNUICallback('loadSettings', function(_, cb)
    -- NUI хуудас ачаалагдсан нь энэ дуудлагаар батлагдсан тул дэлгэцийн
    -- мэдээллийг (эхний удаад алдагдсан байж болзошгүй) дахин илгээнэ.
    sendScreenInfo()
    cb({
        pos   = kvpGet('pos'),
        style = kvpGet('style'),
        unit  = kvpGet('unit'),
        lang  = kvpGet('lang'),
        scale = kvpGet('scale'),
        statusLayout = kvpGet('statusLayout'),

        -- Серверийн анхдагчууд. 'config' мессеж нь resource эхлэхэд илгээгддэг
        -- боловч NUI хуудасны JS хараахан ачаалагдаагүй бол АЛДАГДАНА
        -- (SendNUIMessage дараалалд ордоггүй). Тиймээс NUI өөрөө татахдаа
        -- эдгээрийг хамт авч, тохиргоо ямар ч тохиолдолд бүрэн ирнэ.
        cfgUseMPH = Config.UseMPH,
        cfgLang   = Config.Language,
        cfgScale  = Config.HudScale,
    })
end)

RegisterCommand('lshud', function()
    settingsOpen = true
    refreshHudVisibility()   -- тохиргоо нээх үед HUD-г заавал харуулна
    SetNuiFocus(true, true)
    sendUI('openSettings', {})
end, false)

RegisterKeyMapping('lshud', 'LS HUD тохиргоо нээх', 'keyboard', 'F7')

-- Чат санал болголт
TriggerEvent('chat:addSuggestion', '/lshud', 'LS HUD-ийн байрлалын тохиргоог нээх')

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        sendUI('hide')
    end
end)
