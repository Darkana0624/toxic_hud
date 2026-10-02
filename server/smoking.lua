local Config = require 'config'

-- ============================================================
--  Toxic HUD - CIGARETTES / VAPE (server)
--
--  Checks item ownership, consumes items and hands out cigarettes from
--  packs. Animation / prop live on the client side.
--
--  Source: lusty94_smoking (qb-core + qb-inventory). Rewritten here on
--  ox_inventory; stress relief goes through server/stress.lua (the
--  client is not trusted).
-- ============================================================

if not (Config.Smoking and Config.Smoking.enabled) then return end

local ox = GetResourceState('ox_inventory') == 'started'

if not ox then
    print('^3[toxic_hud]^7 ox_inventory is not started, smoking system disabled')
    return
end

local function count(src, item)
    return exports.ox_inventory:GetItemCount(src, item) or 0
end

---Validates an item-use request fully on the server.
---The client only reports "I finished using this item"; remaining
---stock, required items and stress are all decided here.
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

    -- Check again - the item may have disappeared during the progress bar
    if count(src, itemName) < 1 then return end
    if cfg.requires and count(src, cfg.requires.item) < 1 then return end

    -- If the cigarettes from a pack cannot be carried, keep the pack
    if cfg.returns and not exports.ox_inventory:CanCarryItem(src, cfg.returns.item, cfg.returns.amount or 1) then
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Smoking', description = 'Your inventory is full', type = 'error',
        })
        return
    end

    -- Consume the main item (the vape itself stays)
    if not cfg.keepItem then
        if not exports.ox_inventory:RemoveItem(src, itemName, 1) then return end
    end

    -- Consume the required item with some probability (vape juice)
    if cfg.requires and cfg.consumesRequired and cfg.consumesRequired > 0 then
        if math.random() < cfg.consumesRequired then
            exports.ox_inventory:RemoveItem(src, cfg.requires.item, 1)
        end
    end

    -- Open a pack -> hand out cigarettes
    if cfg.returns then
        exports.ox_inventory:AddItem(src, cfg.returns.item, cfg.returns.amount or 1)
    end

    -- Reduce stress
    if cfg.stress and cfg.stress > 0 then
        exports[GetCurrentResourceName()]:RelieveStress(src, cfg.stress)
    end
end)
