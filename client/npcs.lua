local spawnedPeds = {}
local spawnedPetPeds = {}
local shopBlips = {}

--------------------------------------
-- PETSHOP NPC SPAWN
--------------------------------------

CreateThread(function()
    for i, s in ipairs(Config.Shops or {}) do
        if s.showblip then
            local x, y, z = s.npccoords.x, s.npccoords.y, s.npccoords.z
            local blip = Citizen.InvokeNative(0x554D9D53F696D002, 1664425300, x, y, z)
            if blip then
                SetBlipSprite(blip, Config.Blip.blipSprite, true)
                SetBlipScale(blip, Config.Blip.blipScale)
                Citizen.InvokeNative(0x9CB1A1623062F402, blip, Config.Blip.blipName)
                shopBlips[i] = blip
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(500)
        for k,v in pairs(Config.Shops) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - v.npccoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedPeds[k] then
                local spawnedPed = NearPed(v.npcmodel, v.npccoords)
                spawnedPeds[k] = { spawnedPed = spawnedPed }
				TaskStartScenarioInPlace(spawnedPed, joaat(v.scenario), -1, true)
            end
            
            if distance >= Config.DistanceSpawn and spawnedPeds[k] then
                if Config.FadeIn then
                    for i = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPeds[k].spawnedPed, i, false)
                    end
                end
                DeletePed(spawnedPeds[k].spawnedPed)
                spawnedPeds[k] = nil
            end
        end
    end
end)

function NearPed(npcmodel, npccoords)
    if not npcmodel or not npccoords then return nil end
    RequestModel(npcmodel)
    while not HasModelLoaded(npcmodel) do
        Wait(50)
    end
    local spawnedPed = CreatePed(npcmodel, npccoords.x, npccoords.y, npccoords.z - 1.0, npccoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPed, 0, false)
    SetRandomOutfitVariation(spawnedPed, true)
    SetEntityCanBeDamaged(spawnedPed, false)
    SetEntityInvincible(spawnedPed, true)
    FreezeEntityPosition(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedPed), `PLAYER`)
    if Config.Debug then
        local relationship = GetRelationshipBetweenGroups(GetPedRelationshipGroupHash(spawnedPed), `PLAYER`)
        print(relationship)
    end
    if Config.FadeIn then
        for i = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed, i, false)
        end
    end
    if Config.EnableTarget then
        local useOx = (GetResourceState and GetResourceState('ox_target') == 'started')
        if useOx then
            exports.ox_target:addLocalEntity(spawnedPed, {
                {
                    icon = "fa-solid fa-paw",
                    label = Lang:t('label.petshop'),
                    onSelect = function()
                        TriggerEvent("tbrp_companions:client:openpetshop2")
                    end,
                    distance = 3.0,
                }
            })
        end
    end
    return spawnedPed
end


--------------------------------------
-- PETSHOP PET NPC SPAWN
--------------------------------------

CreateThread(function()
    while true do
        Wait(500)
        for k2,v2 in pairs(Config.Shops) do
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - v2.npcpetcoords.xyz)

            if distance < Config.DistanceSpawn and not spawnedPetPeds[k2] then
                local spawnedPed2 = NearPed2(v2.npcpetmodel, v2.npcpetcoords)
                spawnedPetPeds[k2] = { spawnedPed2 = spawnedPed2 }
            end
            
            if distance >= Config.DistanceSpawn and spawnedPetPeds[k2] then
                if Config.FadeIn then
                    for i2 = 255, 0, -51 do
                        Wait(50)
                        SetEntityAlpha(spawnedPetPeds[k2].spawnedPed2, i2, false)
                    end
                end
                DeletePed(spawnedPetPeds[k2].spawnedPed2)
                spawnedPetPeds[k2] = nil
            end
        end
    end
end)

function NearPed2(npcpetmodel, npcpetcoords)
    if not npcpetmodel or not npcpetcoords then return nil end
    RequestModel(npcpetmodel)
    while not HasModelLoaded(npcpetmodel) do
        Wait(50)
    end
    local spawnedPed2 = CreatePed(npcpetmodel, npcpetcoords.x, npcpetcoords.y, npcpetcoords.z - 1.0, npcpetcoords.w, false, false, 0, 0)
    SetEntityAlpha(spawnedPed2, 0, false)
    SetRandomOutfitVariation(spawnedPed2, true)
    SetEntityCanBeDamaged(spawnedPed2, false)
    SetEntityInvincible(spawnedPed2, true)
    FreezeEntityPosition(spawnedPed2, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed2, true)
    SetRelationshipBetweenGroups(1, GetPedRelationshipGroupHash(spawnedPed2), `PLAYER`)
    if Config.Debug then
        local relationship2 = GetRelationshipBetweenGroups(GetPedRelationshipGroupHash(spawnedPed2), `PLAYER`)
        print(relationship2)
    end
    if Config.FadeIn then
        for i2 = 0, 255, 51 do
            Wait(50)
            SetEntityAlpha(spawnedPed2, i2, false)
        end
    end
    return spawnedPed2
end

local previewCam = nil
local previewPed = nil
local previewIndex = 1
local previewOutfit = 1
local previewShop = nil

local function nearestShop()
    local player = GetEntityCoords(PlayerPedId())
    local idx = nil
    local best = 999999.0
    for i, s in ipairs(Config.Shops or {}) do
        local d = #(player - s.npccoords.xyz)
        if d < best then
            best = d
            idx = i
        end
    end
    return idx
end

local function destroyPreview()
    if previewCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    previewPed = nil
end

local function ensureCam(shop)
    if not shop then return end
    local tgt = shop.npcpetcoords
    local cx, cy, cz
    if shop.Camera then
        cx = shop.Camera.x
        cy = shop.Camera.y
        cz = shop.Camera.z
    else
        local rad = (tgt.w) * 0.0174532924
        local dist = 2.4
        cx = tgt.x + math.cos(rad) * dist
        cy = tgt.y + math.sin(rad) * dist
        cz = tgt.z + 0.7
    end
    if previewCam then
        DestroyCam(previewCam, false)
        previewCam = nil
    end
    previewCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cx, cy, cz, -30.0, 0.0, 0.0, 50.0, true, 2)
    PointCamAtCoord(previewCam, tgt.x, tgt.y, tgt.z - 0.2)
    RenderScriptCams(true, true, 500, true, true)
end

local function spawnPreview(model, outfit)
    local shop = Config.Shops[previewShop]
    if not shop then return end
    local c = shop.npcpetcoords
    local existing = spawnedPetPeds[previewShop] and spawnedPetPeds[previewShop].spawnedPed2 or nil
    if existing and DoesEntityExist(existing) then
        previewPed = existing
    else
        local hash0 = shop.npcpetmodel
        RequestModel(hash0)
        while not HasModelLoaded(hash0) do Wait(50) end
        previewPed = CreatePed(hash0, c.x, c.y, c.z - 1.0, c.w, false, false, 0, 0)
        SetEntityAlpha(previewPed, 255, false)
        SetRandomOutfitVariation(previewPed, true)
        SetEntityCanBeDamaged(previewPed, false)
        SetEntityInvincible(previewPed, true)
        FreezeEntityPosition(previewPed, true)
        SetBlockingOfNonTemporaryEvents(previewPed, true)
        PlaceEntityOnGroundProperly(previewPed)
        spawnedPetPeds[previewShop] = { spawnedPed2 = previewPed }
    end
    local currentModel = GetEntityModel(previewPed)
    local newHash = joaat(model)
    if currentModel ~= newHash then
        RequestModel(newHash)
        while not HasModelLoaded(newHash) do Wait(50) end
        local x,y,z = c.x, c.y, c.z - 1.0
        local w = c.w
        DeletePed(previewPed)
        previewPed = CreatePed(newHash, x, y, z, w, false, false, 0, 0)
        SetEntityAlpha(previewPed, 255, false)
        SetEntityVisible(previewPed, true)
        SetEntityCanBeDamaged(previewPed, false)
        SetEntityInvincible(previewPed, true)
        FreezeEntityPosition(previewPed, true)
        SetBlockingOfNonTemporaryEvents(previewPed, true)
        PlaceEntityOnGroundProperly(previewPed)
        spawnedPetPeds[previewShop].spawnedPed2 = previewPed
    end
    EquipMetaPedOutfitPreset(previewPed, outfit or 1, true)
end

local function refreshPreviewMenu()
    local pet = Config.Pets[previewIndex]
    local title = pet and pet.Text or 'Pet'
    local desc = pet and pet.Desc or ''
    local img = pet and pet.img or nil
    local maxOutfit = (pet and pet.outfitMax) or 3
    previewOutfit = math.max(1, math.min(previewOutfit, maxOutfit))
    local price = pet and pet.Param and pet.Param.Price or 0
    lib.registerContext({
        id = 'pet_preview_menu',
        title = title,
        description = desc,
        menu = 'petshop_menu',
        onExit = function()
            destroyPreview()
        end,
        options = {
            { title = 'Breed', description = title, disabled = true },
            { title = 'Outfit: '..tostring(previewOutfit)..' / '..tostring(maxOutfit), disabled = true },
            { title = 'Prev Breed', onSelect = function()
                previewIndex = previewIndex - 1
                if previewIndex < 1 then previewIndex = #Config.Pets end
                previewOutfit = 1
                spawnPreview(Config.Pets[previewIndex].Param.Model, previewOutfit)
                refreshPreviewMenu()
            end },
            { title = 'Next Breed', onSelect = function()
                previewIndex = previewIndex + 1
                if previewIndex > #Config.Pets then previewIndex = 1 end
                previewOutfit = 1
                spawnPreview(Config.Pets[previewIndex].Param.Model, previewOutfit)
                refreshPreviewMenu()
            end },
            { title = 'Prev Outfit', onSelect = function()
                local maxOut = (Config.Pets[previewIndex] and Config.Pets[previewIndex].outfitMax) or 3
                previewOutfit = previewOutfit - 1
                if previewOutfit < 1 then previewOutfit = maxOut end
                if previewPed and DoesEntityExist(previewPed) then
                    EquipMetaPedOutfitPreset(previewPed, previewOutfit, true)
                end
                refreshPreviewMenu()
            end },
            { title = 'Next Outfit', onSelect = function()
                local maxOut = (Config.Pets[previewIndex] and Config.Pets[previewIndex].outfitMax) or 3
                previewOutfit = previewOutfit + 1
                if previewOutfit > maxOut then previewOutfit = 1 end
                if previewPed and DoesEntityExist(previewPed) then
                    EquipMetaPedOutfitPreset(previewPed, previewOutfit, true)
                end
                refreshPreviewMenu()
            end },
            { title = 'Buy', icon = 'fa-solid fa-dollar-sign', onSelect = function()
                local p = Config.Pets[previewIndex]
                if p and p.Param then
                    TriggerServerEvent('tbrp_companions:buydog', { price = p.Param.Price, model = p.Param.Model, skin = previewOutfit })
                end
                destroyPreview()
            end },
            { title = 'Cancel', onSelect = function()
                destroyPreview()
                lib.showContext('petshop_menu')
            end },
        }
    })
    lib.showContext('pet_preview_menu')
end

local function OpenPetShop()
    if not Config.AlwaysOpen then
        local hour = GetClockHours()
        if (hour < Config.OpenTime) or (hour >= Config.CloseTime) then
            if lib and lib.notify then lib.notify({ description = Lang:t('info.close_2')..Config.OpenTime..Lang:t('info.close_3'), type = 'error' }) end
            return
        end
    end
    TriggerEvent('tbrp_companions:client:openpetshop')
end

AddEventHandler('tbrp_companions:client:openpetshop2', function()
    OpenPetShop()
end)

RegisterNetEvent('tbrp_companions:client:openpetshop', function()
    destroyPreview()
    lib.registerContext({
        id = 'petshop_menu',
        title = Lang:t('label.petshop'),
        options = {
            {
                title = Lang:t('label.petshop'),
                icon = 'fa-solid fa-box',
                event = 'tbrp_companions:client:petshelter',
                arrow = true
            },
            {
                title = Lang:t('label.manage_pets'),
                icon = 'fa-solid fa-box',
                event = 'tbrp_companions:client:managePets',
                arrow = true
            },
        }
    })
    lib.showContext('petshop_menu')
end)

RegisterNetEvent('tbrp_companions:client:petshelter', function()
    previewShop = nearestShop()
    previewIndex = 1
    previewOutfit = 1
    local shop = Config.Shops[previewShop]
    if not shop then return end
    ensureCam(shop)
    spawnPreview(Config.Pets[previewIndex].Param.Model, previewOutfit)
    refreshPreviewMenu()
    CreateThread(function()
        while previewCam do
            Wait(250)
            local ply = GetEntityCoords(PlayerPedId())
            local dist = #(ply - shop.npccoords.xyz)
            if dist > (Config.DistanceSpawn or 40.0) then
                destroyPreview()
                if lib and lib.hideContext then lib.hideContext(true) end
                break
            end
        end
    end)
end)

AddEventHandler('tbrp_companions:client:managePets', function()
    TriggerServerEvent('tbrp_companions:server:listPets')
end)

RegisterNetEvent('tbrp_companions:client:showManage', function(pets)
    local options = {}
    for _, p in ipairs(pets or {}) do
        local title = p.name and p.name ~= '' and p.name or (p.dog or 'Pet')
        if p.active == 1 then title = title .. ' *' end
        options[#options+1] = {
            title = title,
            icon = 'fa-solid fa-dog',
            args = p,
            event = 'tbrp_companions:client:manageOne',
            arrow = true,
        }
    end
    lib.registerContext({
        id = 'manage_pets_list',
        title = Lang:t('label.manage_pets'),
        menu = 'petshop_menu',
        options = options
    })
    lib.showContext('manage_pets_list')
end)

AddEventHandler('tbrp_companions:client:manageOne', function(p)
    lib.registerContext({
        id = 'manage_pet_actions_'..p.id,
        title = (p.name and p.name ~= '' and p.name or p.dog),
        menu = 'manage_pets_list',
        options = {
            {
                title = Lang:t('label.name_pet'),
                icon = 'fa-solid fa-pen',
                onSelect = function()
                    local input = lib.inputDialog(Lang:t('label.name_pet'), { { type = 'input', label = Lang:t('label.pet_name'), required = true, min = 1, max = 32 } })
                    if input and input[1] then
                        TriggerServerEvent('tbrp_companions:server:namePet', p.id, input[1])
                        Wait(200)
                        TriggerServerEvent('tbrp_companions:server:listPets')
                    end
                end,
            },
            {
                title = Lang:t('label.set_active'),
                icon = 'fa-solid fa-check',
                onSelect = function()
                    TriggerServerEvent('tbrp_companions:server:setActive', p.id)
                    Wait(200)
                    TriggerServerEvent('tbrp_companions:server:listPets')
                end,
            },
            {
                title = Lang:t('label.sell_pet'),
                icon = 'fa-solid fa-dollar-sign',
                onSelect = function()
                    TriggerServerEvent('tbrp_companions:sellpet', p.id)
                    Wait(200)
                    TriggerServerEvent('tbrp_companions:server:listPets')
                end,
            },
        }
    })
    lib.showContext('manage_pet_actions_'..p.id)
end)

-- cleanup
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    for k,v in pairs(spawnedPeds) do
        DeletePed(spawnedPeds[k].spawnedPed)
        if spawnedPeds[k].blip and DoesBlipExist(spawnedPeds[k].blip) then
            RemoveBlip(spawnedPeds[k].blip)
        end
        spawnedPeds[k] = nil
    end
    for k2,v2 in pairs(spawnedPetPeds) do
        DeletePed(spawnedPetPeds[k2].spawnedPed2)
        spawnedPetPeds[k2] = nil
    end
    if previewPed and DoesEntityExist(previewPed) then DeletePed(previewPed) end
    if previewCam then
        RenderScriptCams(false, true, 500, true, true)
        DestroyCam(previewCam, false)
        previewCam = nil
    end
end)
