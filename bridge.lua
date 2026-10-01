local Config = require 'config'

-- ============================================================
--  Framework bridge — qbx_core / qb-core / es_extended / standalone
--  client.lua энэ нэгдсэн `Framework` global хүснэгтийг ашиглана.
--  Илрүүлэлт автомат (Config.Framework = 'auto') эсвэл гар тохиргоо.
-- ============================================================

local Framework = {
    name     = 'standalone',
    loggedIn = false,
    cash     = 0,
    bank     = 0,
    job      = 'Civilian',
    grade    = '',
    hunger   = nil,
    thirst   = nil,
    stress   = nil,
}

local function started(res)
    local s = GetResourceState(res)
    return s == 'started' or s == 'starting'
end

-- Нэвтрэх төлөв өөрчлөгдөхөд client.lua-д мэдэгдэнэ (HUD харуулах/нуух)
local function setLogin(state)
    Framework.loggedIn = state
    TriggerEvent('lshud:auth', state)
end

-- ===== Framework илрүүлэх =====
local fw = Config.Framework
if not fw or fw == 'auto' then
    if started('qbx_core') then fw = 'qbx'
    elseif started('qb-core') then fw = 'qb'
    elseif started('es_extended') then fw = 'esx'
    else fw = 'standalone' end
end
Framework.name = fw

-- qb / qbx HUD-ууд дамжуулдаг нийтлэг needs event-ууд
local function registerNeedEvents()
    RegisterNetEvent('hud:client:UpdateNeeds', function(h, t)
        if h ~= nil then Framework.hunger = math.floor(h + 0.5) end
        if t ~= nil then Framework.thirst = math.floor(t + 0.5) end
    end)
    RegisterNetEvent('hud:client:UpdateStress', function(s)
        if s ~= nil then Framework.stress = math.floor(s + 0.5) end
    end)
end

-- qb / qbx PlayerData бүтэц ижил тул нэг applier
local function applyQbData(pd)
    if not pd then return end
    Framework.cash  = (pd.money and pd.money.cash) or Framework.cash
    Framework.bank  = (pd.money and pd.money.bank) or Framework.bank
    Framework.job   = (pd.job and pd.job.label) or Framework.job
    Framework.grade = (pd.job and pd.job.grade and pd.job.grade.name) or Framework.grade
    if pd.metadata then
        Framework.hunger = pd.metadata.hunger or Framework.hunger
        Framework.thirst = pd.metadata.thirst or Framework.thirst
        Framework.stress = pd.metadata.stress or Framework.stress
    end
end

-- =========================================================
--  QBox (qbx_core)
-- =========================================================
if fw == 'qbx' then
    local QBX = exports.qbx_core

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        applyQbData(QBX:GetPlayerData())
        setLogin(true)
    end)
    RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
        setLogin(false)
    end)
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(pd)
        applyQbData(pd)
    end)
    registerNeedEvents()

    -- Аль хэдийн нэвтэрсэн (resource restart) эсвэл OnPlayerLoaded event-ийг
    -- алдсан тохиолдлыг барих polling — statebag бэлэн болмогц тогтооно.
    CreateThread(function()
        while not Framework.loggedIn do
            if LocalPlayer.state.isLoggedIn then
                applyQbData(QBX:GetPlayerData())
                setLogin(true)
            end
            Wait(500)
        end
    end)

-- =========================================================
--  QBCore (qb-core)
-- =========================================================
elseif fw == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()

    RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
        applyQbData(QBCore.Functions.GetPlayerData())
        setLogin(true)
    end)
    RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
        setLogin(false)
    end)
    RegisterNetEvent('QBCore:Player:SetPlayerData', function(pd)
        applyQbData(pd)
    end)
    registerNeedEvents()

    CreateThread(function()
        while not Framework.loggedIn do
            if LocalPlayer.state.isLoggedIn then
                applyQbData(QBCore.Functions.GetPlayerData())
                setLogin(true)
            end
            Wait(500)
        end
    end)

-- =========================================================
--  ESX (es_extended)
-- =========================================================
elseif fw == 'esx' then
    local ESX
    pcall(function() ESX = exports['es_extended']:getSharedObject() end)
    if not ESX then
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
    end

    local function applyEsx(pd)
        if not pd then return end
        for _, acc in pairs(pd.accounts or {}) do
            if acc.name == 'money' then Framework.cash = acc.money
            elseif acc.name == 'bank' then Framework.bank = acc.money end
        end
        if pd.job then
            Framework.job   = pd.job.label or Framework.job
            Framework.grade = pd.job.grade_label or Framework.grade
        end
    end

    RegisterNetEvent('esx:playerLoaded', function(xPlayer)
        applyEsx(xPlayer or (ESX and ESX.GetPlayerData()))
        setLogin(true)
    end)
    RegisterNetEvent('esx:onPlayerLogout', function()
        setLogin(false)
    end)
    RegisterNetEvent('esx:setAccountMoney', function(account)
        if not account then return end
        if account.name == 'money' then Framework.cash = account.money
        elseif account.name == 'bank' then Framework.bank = account.money end
    end)
    RegisterNetEvent('esx:setJob', function(job)
        if not job then return end
        Framework.job   = job.label or Framework.job
        Framework.grade = job.grade_label or Framework.grade
    end)

    -- Hunger / thirst (esx_status байгаа бол, утга 0..1,000,000)
    AddEventHandler('esx_status:onTick', function(data)
        for _, st in pairs(data) do
            local pct = math.floor((st.val or 0) / 10000 + 0.5)
            if st.name == 'hunger' then Framework.hunger = pct
            elseif st.name == 'thirst' then Framework.thirst = pct end
        end
    end)

    CreateThread(function()
        while not Framework.loggedIn do
            if ESX and ESX.IsPlayerLoaded and ESX.IsPlayerLoaded() then
                applyEsx(ESX.GetPlayerData())
                setLogin(true)
            end
            Wait(500)
        end
    end)

-- =========================================================
--  Standalone (framework байхгүй)
-- =========================================================
else
    -- Нэвтрэх систем байхгүй тул HUD шууд идэвхтэй. Мөнгө / job / needs
    -- байхгүй (статусын дугуйнууд nil үед автоматаар нуугдана).
    Framework.loggedIn = true
end

return Framework
