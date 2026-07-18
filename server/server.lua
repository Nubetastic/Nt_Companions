local RSGCore = exports['rsg-core']:GetCoreObject()
local pendingPetFoodUses = {}

local function notify(src, msg, typ)
    TriggerClientEvent('tbrp_companions:client:notify', src, msg, typ or 'inform')
end

RSGCore.Functions.CreateUseableItem(Config.AnimalFood, function(source, item)
    pendingPetFoodUses[source] = {
        expires = os.time() + 10,
        slot = item and item.slot or nil,
    }

    TriggerClientEvent('tbrp_companions:client:tryFeedPet', source)
end)

local function feedPet(src, slot)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local foodItem = Config.AnimalFood or 'pet_food'
    local item = Player.Functions.GetItemByName and Player.Functions.GetItemByName(foodItem)
    local amount = item and (item.amount or item.count or 0) or 0
    if amount < 1 then
        notify(src, Lang:t('error.nofood'), 'error')
        return
    end

    local removed = Player.Functions.RemoveItem(foodItem, 1, slot)
    if removed == false then
        notify(src, Lang:t('error.nofood'), 'error')
        return
    end

    if RSGCore.Shared and RSGCore.Shared.Items and RSGCore.Shared.Items[foodItem] then
        TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[foodItem], 'remove', 1)
    end

    TriggerClientEvent('tbrp_companions:client:petFed', src)
end

CreateThread(function()
    MySQL.query.await([[ALTER TABLE tbrp_companions
        ADD COLUMN IF NOT EXISTS name VARCHAR(50) NULL,
        ADD COLUMN IF NOT EXISTS active TINYINT(1) NOT NULL DEFAULT 0
    ]])
end)

RegisterNetEvent('tbrp_companions:server:consumePetFood', function()
    local src = source
    local request = pendingPetFoodUses[src]
    pendingPetFoodUses[src] = nil

    if not request or request.expires < os.time() then return end
    feedPet(src, request.slot)
end)

RegisterNetEvent('tbrp_companions:server:feedPetPrompt', function()
    feedPet(source)
end)

AddEventHandler('playerDropped', function()
    pendingPetFoodUses[source] = nil
end)

local function getPriceForModel(model)
    for _, v in ipairs(Config.Pets or {}) do
        if v.Param and v.Param.Model == model then
            return v.Param.Price or 0
        end
    end
    return 0
end

RegisterNetEvent('tbrp_companions:loaddog', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    if not identifier then return end
    local rows = MySQL.query.await('SELECT dog, skin FROM tbrp_companions WHERE identifier = ? AND active = 1 ORDER BY charidentifier DESC LIMIT 1', { identifier }) or {}
    if rows[1] and rows[1].dog and rows[1].dog ~= '' then
        local model = rows[1].dog
        local skin = rows[1].skin or 0
        TriggerClientEvent('tbrp_companions:client:spawnPet', src, { model = model, skin = skin })
    else
        TriggerClientEvent('RSGCore:Notify', src, Lang:t('error.nopet'), 'error')
    end
end)

RegisterNetEvent('tbrp_companions:sellpet', function(petId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    if not identifier or not petId then return end
    local rows = MySQL.query.await('SELECT dog FROM tbrp_companions WHERE charidentifier = ? AND identifier = ? LIMIT 1', { petId, identifier }) or {}
    if not rows[1] then return end
    local model = rows[1].dog
    local price = getPriceForModel(model)
    local refund = math.floor((price or 0) * 0.1)
    if refund > 0 and Player.Functions.AddMoney then Player.Functions.AddMoney('cash', refund) end
    local wasActive = MySQL.query.await('SELECT active FROM tbrp_companions WHERE charidentifier = ? AND identifier = ? LIMIT 1', { petId, identifier })
    MySQL.update.await('DELETE FROM tbrp_companions WHERE charidentifier = ? AND identifier = ?', { petId, identifier })
    if wasActive and wasActive[1] and wasActive[1].active == 1 then
        TriggerClientEvent('tbrp_companions:putaway', src)
    end
end)

RegisterNetEvent('tbrp_companions:server:listPets', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    if not identifier then return end
    local rows = MySQL.query.await('SELECT charidentifier as id, dog, name, active FROM tbrp_companions WHERE identifier = ? ORDER BY charidentifier DESC', { identifier }) or {}
    TriggerClientEvent('tbrp_companions:client:showManage', src, rows)
end)

RegisterNetEvent('tbrp_companions:server:namePet', function(petId, newName)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    if not identifier or not petId then return end
    MySQL.update.await('UPDATE tbrp_companions SET name = ? WHERE charidentifier = ? AND identifier = ?', { newName, petId, identifier })
end)

RegisterNetEvent('tbrp_companions:server:setActive', function(petId)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    if not identifier or not petId then return end
    MySQL.update.await('UPDATE tbrp_companions SET active = 0 WHERE identifier = ?', { identifier })
    MySQL.update.await('UPDATE tbrp_companions SET active = 1 WHERE charidentifier = ? AND identifier = ?', { petId, identifier })
    local row = MySQL.query.await('SELECT dog, skin FROM tbrp_companions WHERE charidentifier = ? AND identifier = ? LIMIT 1', { petId, identifier })
    if row and row[1] and row[1].dog then
        TriggerClientEvent('tbrp_companions:putaway', src)
        Wait(200)
        TriggerClientEvent('tbrp_companions:client:spawnPet', src, { model = row[1].dog, skin = row[1].skin })
    end
end)

RegisterNetEvent('tbrp_companions:buydog', function(args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end
    local identifier = Player.PlayerData and (Player.PlayerData.citizenid or Player.PlayerData.identifier or Player.PlayerData.license) or nil
    local price = args and args.price or 0
    local model = args and args.model or 'A_C_DogHusky_01'
    local skin = args and args.skin or 0
    if not identifier then return end
    local money = Player.PlayerData and Player.PlayerData.money and Player.PlayerData.money.cash or 0
    if money < price then return end
    if Player.Functions.RemoveMoney then Player.Functions.RemoveMoney('cash', price) end
    MySQL.update.await('UPDATE tbrp_companions SET active = 0 WHERE identifier = ?', { identifier })
    MySQL.insert.await('INSERT INTO tbrp_companions (identifier,dog,skin,name,active) VALUES (?,?,?,?,1)', { identifier, model, skin, nil })
    TriggerClientEvent('tbrp_companions:client:spawnPet', src, { model = model, skin = skin })
end)
