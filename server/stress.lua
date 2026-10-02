local Config = require 'config'

-- ============================================================
--  Toxic HUD — STRESS СИСТЕМ (server)
--
--  Хадгалалт:
--    1) qbx_core metadata.stress  — тоглогчтой хамт DB-д үлдэнэ
--    2) Player(src).state.stress  — statebag, бусад resource уншина
--       (envi-bridge/qbox, jg-stress-addon зэрэг үүнийг сонсдог)
--
--  HUD руу 'hud:client:UpdateStress' эвентээр мэдэгдэнэ — bridge.lua
--  аль хэдийн үүнийг сонсдог тул нэмэлт холболт шаардахгүй. Энэ нь
--  qb/qbx экосистемийн стандарт эвент учир бусад script-ийн
--  бичсэн stress ч HUD дээр зөв харагдана.
--
--  ЖОЛООДЛОГООС STRESS ӨГӨХГҮЙ — эх үүсвэрүүд client/stress.lua
--  дотор бөгөөд тэнд хурд / мөргөлт огт хамаарахгүй.
-- ============================================================

local qbx = GetResourceState('qbx_core') == 'started'

local function clamp(v)
    local maxv = (Config.Stress and Config.Stress.max) or 100.0
    if v < 0.0 then return 0.0 end
    if v > maxv then return maxv end
    return v
end

---Одоогийн stress-ийг буцаана (0-100)
---
---ЧУХАЛ: statebag нь ҮНЭНИЙ ЭХ СУРВАЛЖ. Энэ серверийн бусад script
---(qbx_consumables — хоол/архи, p_ambulancejob — сэргээхэд тэглэх,
---envi-bridge) бүгд Player(src).state.stress дээр ШУУД бичдэг бөгөөд
---metadata-г хөнддөггүй. Metadata-г эхэнд уншвал тэдний өөрчлөлтийг
---дарж бичих байсан. Metadata нь зөвхөн сессийн хооронд хадгалах
---зориулалттай (statebag сервер унтрахад алга болдог).
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

---Stress-ийг шууд утгаар тавина
---@param src number
---@param value number
local function setStress(src, value)
    value = clamp(tonumber(value) or 0.0)

    if qbx then
        local player = exports.qbx_core:GetPlayer(src)
        if player then player.Functions.SetMetaData('stress', value) end
    end

    -- statebag (3 дахь параметр = replicated, клиент талд уншигдана)
    Player(src).state:set('stress', value, true)

    -- HUD + бусад qb/qbx нийцтэй script-үүд
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

-- ---- Экспорт (бусад resource-д) ----
exports('GetStress',     function(src) return getStress(src) end)
exports('SetStress',     function(src, v) return setStress(src, v) end)
exports('AddStress',     function(src, v) return addStress(src, v) end)
exports('RelieveStress', function(src, v) return relieveStress(src, v) end)

-- ---- Эвентүүд ----
RegisterNetEvent('toxic_hud:server:addStress', function(amount)
    addStress(source, amount)
end)

RegisterNetEvent('toxic_hud:server:relieveStress', function(amount)
    relieveStress(source, amount)
end)

-- qb-hud экосистемийн стандарт эвентүүд. lusty94_smoking зэрэг олон
-- script эдгээрийг дууддаг тул нийцтэй байлгав.
RegisterNetEvent('hud:server:GainStress', function(amount)
    addStress(source, amount)
end)

RegisterNetEvent('hud:server:RelieveStress', function(amount)
    relieveStress(source, amount)
end)

-- ---- Байгалийн бууралт ----
-- Тоглогч юу ч хийхгүй байхад stress аажим тэглэгдэнэ.
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

-- Тоглогч ороход statebag-ийг metadata-аас сэргээнэ (statebag нь
-- сессийн хооронд хадгалагддаггүй).
-- qbx_core үүнийг server талаас TriggerEvent('QBCore:Server:PlayerLoaded', self)
-- гэж дууддаг тул `source` нь тоглогчийн ID биш ('' байдаг) — тоглогчийн
-- ID-г дамжуулсан Player объектоос авна. Server-local эвент тул
-- RegisterNetEvent биш AddEventHandler (клиент хуурамчаар дуудаж чадахгүй).
AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = tonumber(player and player.PlayerData and player.PlayerData.source)
    if not src or src <= 0 then return end
    SetTimeout(1000, function()
        if not GetPlayerName(src) then return end -- 1 секундэд гарчихсан байж болно
        setStress(src, getStress(src))
    end)
end)

-- ============================================================
--  p_ambulancejob — АЛБАН ЁСНЫ гэмтлийн hook
--
--  Docs: piotreq-scripts.gitbook.io/.../ambulance-job-v2/api/server-side
--    RegisterNetEvent('p_ambulancejob/onDeathStateChange')
--    параметр: deathType (string), deathData (table)
--    deathType: 'death' | 'bleeding' | 'recovering' | 'none'
--
--  Клиентийн амь хянах таамаглалаас ялгаатай нь энэ нь албан ёсны,
--  server талын дохио тул найдвартай. 'recovering' / 'none' үед
--  stress нэмэхгүй (эдгэж байгаа үе).
--
--  Тайлбар: p_ambulancejob нь тоглогчийг СЭРГЭЭХЭД stress-ийг өөрөө
--  0 болгодог (shared/config.lua дотор state:set('stress', 0)). Бидний
--  систем statebag-ийг эх сурвалж болгон уншдаг тул түүнийг дагана.
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
