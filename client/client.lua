local RSGCore = exports['rsg-core']:GetCoreObject()
local petPed = nil
local petNetId = nil
local petBlip = nil
local petIsOut = false
local petState = 'idle'
local fetchQueue = {}
local isFetching = false
local carriedEntity = 0
local attackTarget = 0
local lastAttackOrderAt = 0
local followDist = Config.PetAttributes.FollowDistance or 5
local followSpeed = Config.PetAttributes.FollowSpeed or 3
local callKeyName = (Config.TriggerKeys and Config.TriggerKeys.CallPet) or 'Z'
local callKey = Config.Keys[callKeyName] or 0x26E9DC00
local dogModels = nil
local FollowPrompt = nil
local StayPrompt = nil
local FeedPrompt = nil
local petFleeing = false
local hungerDeadline = 0
local hungerWarned = false
local hungerToken = 0

local function isPetEntityValid()
    return petPed ~= nil and DoesEntityExist(petPed)
end

local function resetPetState()
    petIsOut = false
    petPed = nil
    petNetId = nil
    petFleeing = false
    hungerToken = hungerToken + 1
    hungerDeadline = 0
    hungerWarned = false
    petState = 'idle'
    fetchQueue = {}
    isFetching = false
    attackTarget = 0
    FollowPrompt = nil
    StayPrompt = nil
    FeedPrompt = nil
    clearBlip()
end

local function getDogModels()
    if dogModels then return dogModels end
    dogModels = {}
    for _, v in ipairs(Config.Pets or {}) do
        local m = v.Param and v.Param.Model or nil
        if m then dogModels[joaat(m)] = true end
    end
    return dogModels
end
local function isStrayGroupDog(ped)
    if ped == 0 or not DoesEntityExist(ped) then return false end
    if IsPedHuman(ped) then return false end
    if not IsPedInGroup(ped) then return false end
    local pg = GetPedGroupIndex(PlayerPedId())
    if GetPedGroupIndex(ped) ~= pg then return false end
    if petPed and ped == petPed then return false end
    local models = getDogModels()
    return models[GetEntityModel(ped)] == true
end
local function cleanupStrayDogs()
    local peds = GetGamePool('CPed')
    for i=1,#peds do
        local ped = peds[i]
        if isStrayGroupDog(ped) then
            local t = GetGameTimer()
            NetworkRequestControlOfEntity(ped)
            while not NetworkHasControlOfEntity(ped) and GetGameTimer() - t < 1000 do
                Wait(50)
                NetworkRequestControlOfEntity(ped)
            end
            RemovePedFromGroup(ped)
            TaskAnimalFlee(ped, PlayerPedId(), -1)
            Wait(500)
            DeletePed(ped)
        end
    end
end

exports('LoadPet', function()
    TriggerServerEvent('tbrp_companions:loaddog')
end)

exports('PutAwayPet', function()
    TriggerEvent('tbrp_companions:putaway')
end)

local function notify(msg, typ)
    if lib and lib.notify then lib.notify({description = msg, type = typ or 'inform', duration = 10000}) end
end

RegisterNetEvent('tbrp_companions:client:notify', function(msg, typ)
    notify(msg, typ)
end)

local function stopHungerTimer()
    hungerToken = hungerToken + 1
    hungerDeadline = 0
    hungerWarned = false
end

function clearBlip()
    if petBlip and DoesBlipExist(petBlip) then RemoveBlip(petBlip) end
    petBlip = nil
end

local function addBlip()
    if not petPed or not DoesEntityExist(petPed) then return end
    clearBlip()
    local sprite = (Config.PetBlip and Config.PetBlip.blipSprite) or 1451797164
    local scale = (Config.PetBlip and Config.PetBlip.blipScale) or 0.2
    petBlip = Citizen.InvokeNative(0x23F74C2FDA6E7C61, 1664425300, petPed)
    if petBlip then
        SetBlipSprite(petBlip, sprite, true)
        SetBlipScale(petBlip, scale)
        local name = (Config.PetBlip and Config.PetBlip.blipName) or 'Pet'
        Citizen.InvokeNative(0x9CB1A1623062F402, petBlip, name)
    end
end

local function updatePrompts()
    if FollowPrompt then
        local showFollow = (petState ~= 'follow') and (not petFleeing)
        PromptSetEnabled(FollowPrompt, showFollow)
        PromptSetVisible(FollowPrompt, showFollow)
    end
    if StayPrompt then
        local showStay = (petState == 'follow') and (not petFleeing)
        PromptSetEnabled(StayPrompt, showStay)
        PromptSetVisible(StayPrompt, showStay)
    end
    if FeedPrompt then
        local showFeed = hungerWarned and petIsOut and (not petFleeing)
        PromptSetEnabled(FeedPrompt, showFeed)
        PromptSetVisible(FeedPrompt, showFeed)
    end
end

local function AddFollowPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong())
    local handle = PromptRegisterBegin()
    PromptSetControlAction(handle, 0x63A38F2C)
    local str = CreateVarString(10, 'LITERAL_STRING', 'Follow')
    PromptSetText(handle, str)
    PromptSetEnabled(handle, true)
    PromptSetVisible(handle, true)
    PromptSetStandardMode(handle, true)
    PromptSetGroup(handle, group)
    PromptRegisterEnd(handle)
    FollowPrompt = handle
end

local function AddStayPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong())
    local handle = PromptRegisterBegin()
    PromptSetControlAction(handle, 0x9959A6F0)
    local str = CreateVarString(10, 'LITERAL_STRING', 'Stay')
    PromptSetText(handle, str)
    PromptSetEnabled(handle, true)
    PromptSetVisible(handle, true)
    PromptSetStandardMode(handle, true)
    PromptSetGroup(handle, group)
    PromptRegisterEnd(handle)
    StayPrompt = handle
end

local function AddFeedPrompt(entity)
    local group = Citizen.InvokeNative(0xB796970BD125FCE8, entity, Citizen.ResultAsLong())
    local handle = PromptRegisterBegin()
    local feedKeyName = (Config.TriggerKeys and Config.TriggerKeys.FeedPet) or 'E'
    PromptSetControlAction(handle, Config.Keys[feedKeyName] or 0xDFF812F9)
    local str = CreateVarString(10, 'LITERAL_STRING', 'Feed')
    PromptSetText(handle, str)
    PromptSetEnabled(handle, false)
    PromptSetVisible(handle, false)
    PromptSetStandardMode(handle, true)
    PromptSetGroup(handle, group)
    PromptRegisterEnd(handle)
    FeedPrompt = handle
end

local function setState(s)
    petState = s
    if petPed and DoesEntityExist(petPed) then
        local st = Entity(petPed) and Entity(petPed).state or nil
        if st then st:set('tbrp_state', s, true) end
        ClearPedTasks(petPed)
        if s == 'stay' then
            RemovePedFromGroup(petPed)
            SetBlockingOfNonTemporaryEvents(petPed, true)
            TaskStandStill(petPed, 1000000)
        else
            SetBlockingOfNonTemporaryEvents(petPed, false)
            if s == 'follow' then
                SetPedAsGroupMember(petPed, GetPedGroupIndex(PlayerPedId()))
            end
        end
    end
    updatePrompts()
end

local function recallPet()
    if not petPed then return end
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    local dc = #(pc - GetEntityCoords(petPed))
    if dc > 30.0 then
        SetEntityCoords(petPed, pc.x, pc.y, pc.z, false, false, false, false)
        PlaceEntityOnGroundProperly(petPed)
    else
        TaskGoToEntity(petPed, p, -1, 1.5, 2.0, 0, 0)
    end
    setState('follow')
end

local function followLoop()
    if not petPed or not DoesEntityExist(petPed) then return end
    local p = PlayerPedId()
    local pc = GetEntityCoords(p)
    local dc = #(pc - GetEntityCoords(petPed))
    if petState == 'follow' then
        if dc > followDist + 1.0 then
            TaskGoToEntity(petPed, p, -1, followDist, followSpeed + 0.0, 0, 0)
        end
    end
end

local function tryAttack()
    if not Config.DefensiveMode or not petPed or not DoesEntityExist(petPed) then return end
    if attackTarget == 0 then
        local p = PlayerPedId()
        local pc = GetEntityCoords(p)
        local range = (Config.AttackRange or 30) + 0.0
        local peds = GetGamePool('CPed')
        for i=1,#peds do
            local ped = peds[i]
            if ped ~= 0 and DoesEntityExist(ped) and ped ~= p and not IsEntityDead(ped) then
                local pt = GetPedType(ped)
                if (pt == 4 or pt == 5) then
                    local distOk = #(GetEntityCoords(ped) - pc) <= range
                    if distOk and HasEntityBeenDamagedByEntity(ped, p, true, true) then
                        attackTarget = ped
                        setState('attack')
                        TaskCombatPed(petPed, ped, 0, 16)
                        break
                    end
                end
            end
        end
    else
        if (not DoesEntityExist(attackTarget)) or IsEntityDead(attackTarget) then
            attackTarget = 0
            setState('follow')
        end
    end
end

local function tryFetch()
    if not petPed or not DoesEntityExist(petPed) then return end
    if petState == 'attack' then return end
    if isFetching then return end
    local idx = nil
    for i=1,#fetchQueue do
        local ent = fetchQueue[i]
        if DoesEntityExist(ent) and IsEntityDead(ent) then idx = i break end
    end
    if not idx then return end
    local target = table.remove(fetchQueue, idx)
    if not DoesEntityExist(target) then return end
    isFetching = true
    setState('fetch')
    TaskGoToEntity(petPed, target, -1, 1.0, 3.0, 0, 0)
    while petState == 'fetch' and DoesEntityExist(target) do
        if #(GetEntityCoords(petPed) - GetEntityCoords(target)) < 2.0 then
            --SetEntityAsMissionEntity(target, true, true)
            local t = GetGameTimer()
            NetworkRequestControlOfEntity(target)
            while not NetworkHasControlOfEntity(target) and GetGameTimer() - t < 1000 do
                Wait(50)
                NetworkRequestControlOfEntity(target)
            end
            local bone = GetEntityBoneIndexByName(petPed, 'SKEL_Head')
            AttachEntityToEntity(target, petPed, bone, .35, 1, 0.0, 0.0, 90.0, 0.0, true, true, false, true, 2, true, false, false)
            carriedEntity = target  
            setState('return')
            TaskGoToEntity(petPed, PlayerPedId(), -1, 1.5, 3.0, 0, 0)
            break
        end
        Wait(200)
    end
    if petState == 'return' then
        while #(GetEntityCoords(petPed) - GetEntityCoords(PlayerPedId())) > 2.5 do
            Wait(200)
        end
        if carriedEntity ~= 0 and DoesEntityExist(carriedEntity) then
            DetachEntity(carriedEntity, true, true)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dogCoords = GetEntityCoords(petPed)
            local midpoint = vector3(
                (playerCoords.x + dogCoords.x) / 2,
                (playerCoords.y + dogCoords.y) / 2,
                (playerCoords.z + dogCoords.z) / 2 + 1
            )
            SetEntityCoords(carriedEntity, midpoint.x, midpoint.y, midpoint.z, false, false, false, false)
            PlaceEntityOnGroundProperly(carriedEntity)
        end
        carriedEntity = 0
    end
    local dw = (ConfigFetch and ConfigFetch.Settings and ConfigFetch.Settings.DeathWait or 0) * 1000
    if dw > 0 then Wait(dw) end
    setState('follow')
    isFetching = false
end

local recallCooldownUntil = 0
local lostControlSince = 0

local function beginFlee(reason)
    if not petPed or not DoesEntityExist(petPed) then return end
    if petFleeing then return end
    stopHungerTimer()
    petFleeing = true
    SetEntityCanBeDamaged(petPed, false)
    SetPedCanBeTargetted(petPed, false)
    TaskAnimalFlee(petPed, PlayerPedId(), -1)
    local cd = (Config.PetFleetCooldown or 60000)
    recallCooldownUntil = GetGameTimer() + cd
    local msg = 'Your pet ran off. You can resummon it in '..tostring(math.floor(cd/1000))..' seconds.'
    if reason == 'hunger' then
        msg = 'Your pet got too hungry and ran off. You can resummon it in '..tostring(math.floor(cd/1000))..' seconds.'
    end
    if lib and lib.notify then lib.notify({description = msg, type = 'inform', duration = 10000}) end
    print('[Companions] Pet fleeing for '..tostring(math.floor(cd/1000))..'s')
    CreateThread(function()
        local p = PlayerPedId()
        local startTime = GetGameTimer()
        local despawnAfter = 15000
        local despawnDist = (Config.DistanceSpawn or 40.0) + 0.0
        while petFleeing do
            if not petPed or not DoesEntityExist(petPed) then break end
            local d = #(GetEntityCoords(petPed) - GetEntityCoords(p))
            if d >= despawnDist or (GetGameTimer() - startTime) >= despawnAfter then
                DeletePed(petPed)
                --TriggerEvent('tbrp_companions:putaway')
                petFleeing = false
                break
            end
            Wait(300)
        end
    end)
end

local function startHungerTimer()
    stopHungerTimer()
    if not petIsOut or not petPed or not DoesEntityExist(petPed) then return end

    local minMinutes = Config.FeedMinMinutes or 60
    local maxMinutes = Config.FeedMaxMinutes or 120
    if maxMinutes < minMinutes then maxMinutes = minMinutes end

    local feedMinutes = math.random(minMinutes, maxMinutes)
    hungerDeadline = GetGameTimer() + (feedMinutes * 60 * 1000)
    hungerWarned = false
    local token = hungerToken
    local warningMs = ((Config.FeedWarningMinutes or 15) * 60 * 1000)

    CreateThread(function()
        while petIsOut and token == hungerToken do
            if not petPed or not DoesEntityExist(petPed) then return end
            if petFleeing then return end

            local remaining = hungerDeadline - GetGameTimer()
            if remaining <= 0 then
                beginFlee('hunger')
                return
            end

            if Config.NotifyWhenHungry and not hungerWarned and remaining <= warningMs then
                hungerWarned = true
                notify('Your dog is hungry. Use pet food before it runs away.', 'inform')
            end

            Wait(1000)
        end
    end)
end

local function handleInjury()
    if not petPed or not DoesEntityExist(petPed) or petFleeing then return end
    local hp = GetEntityHealth(petPed)
    local threshold = (Config.PetAttributes and Config.PetAttributes.InjuryThreshold) or 25
    if IsEntityDead(petPed) or hp <= 1 then
        Citizen.InvokeNative(0x71BC8E838B9C6035, petPed)
        SetEntityHealth(petPed, math.max(5, threshold))
        hp = GetEntityHealth(petPed)
    end
    if (not Config.DisablePetFlee) and hp > 0 and hp <= threshold then
        beginFlee()
    end
end

local function startMonitor()
    CreateThread(function()
        while petIsOut do
            if IsEntityDead(PlayerPedId()) then
                TriggerEvent('tbrp_companions:putaway')
            end
            handleInjury()
            if not petFleeing then
                followLoop()
                tryAttack()
                tryFetch()
            end
            updatePrompts()
            if petPed and DoesEntityExist(petPed) then
                if not NetworkHasControlOfEntity(petPed) then
                    if lostControlSince == 0 then lostControlSince = GetGameTimer() end
                    if GetGameTimer() - lostControlSince > 5000 then
                        if not Config.DisablePetFlee then
                            beginFlee()
                        end
                        lostControlSince = 0
                    end
                else
                    lostControlSince = 0
                end
            end
            Wait(200)
        end
    end)
end

RegisterNetEvent('tbrp_companions:client:spawnPet', function(data)
    if petIsOut then return end
    cleanupStrayDogs()
    local model = data and data.model or 'A_C_DogHusky_01'
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)
    local heading = GetEntityHeading(playerPed)
    local headingRad = math.rad(heading)
    local spawnDistance = 10.0
    local spawnCoords = vector3(
        coords.x + (math.sin(headingRad) * spawnDistance),
        coords.y - (math.cos(headingRad) * spawnDistance),
        coords.z
    )
    local hash = joaat(model)
    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(50) end
    petPed = CreatePed(hash, spawnCoords.x, spawnCoords.y, spawnCoords.z, heading, true, true, 0, 0)
    --SetEntityAsMissionEntity(petPed, true, true)
    SetEntityAlpha(petPed, 255, false)
    SetEntityVisible(petPed, true)
    if data and data.skin then
        EquipMetaPedOutfitPreset(petPed, data.skin, true)
    else
        SetRandomOutfitVariation(petPed, true)
    end
    PlaceEntityOnGroundProperly(petPed)
    petNetId = NetworkGetNetworkIdFromEntity(petPed)
    if petNetId then
        SetNetworkIdExistsOnAllMachines(petNetId, true)
    end
    SetEntityCanBeDamaged(petPed, true)
   
    DisablePedInjuredOnGroundBehaviour(petPed)
    SetPedAsGroupMember(petPed, GetPedGroupIndex(PlayerPedId()))
    SetModelAsNoLongerNeeded(hash)
    petIsOut = true
    addBlip()
    AddFollowPrompt(petPed)
    AddStayPrompt(petPed)
    AddFeedPrompt(petPed)
    local st = Entity(petPed) and Entity(petPed).state or nil
    if st then
        st:set('tbrp_is_pet', true, true)
        st:set('tbrp_owner', GetPlayerServerId(PlayerId()), true)
        st:set('tbrp_state', 'follow', true)
    end
    setState('follow')
    startHungerTimer()
    startMonitor()
    SetEntityAsNoLongerNeeded(petPed)
end)

RegisterNetEvent('tbrp_companions:putaway', function()
    if not petIsOut then return end
    stopHungerTimer()
    petIsOut = false
    if petPed and DoesEntityExist(petPed) then DeletePed(petPed) end
    petPed = nil
    petNetId = nil
    fetchQueue = {}
    isFetching = false
    attackTarget = 0
    FollowPrompt = nil
    StayPrompt = nil
    FeedPrompt = nil
    clearBlip()
    cleanupStrayDogs()
end)

RegisterNetEvent('tbrp_companions:client:tryFeedPet', function()
    if not petIsOut or not petPed or not DoesEntityExist(petPed) then
        notify('Your pet needs to be out before you can feed it.', 'error')
        return
    end

    if petFleeing then
        notify('Your pet is too far gone to feed right now.', 'error')
        return
    end

    TriggerServerEvent('tbrp_companions:server:consumePetFood')
end)

RegisterNetEvent('tbrp_companions:client:petFed', function()
    if not petIsOut or not petPed or not DoesEntityExist(petPed) then return end
    TaskTurnPedToFaceEntity(petPed, PlayerPedId(), 1000)
    startHungerTimer()
    notify('You fed your dog.', 'success')
end)

RegisterNetEvent('tbrp_companions:client:pet', function()
    if not petIsOut or petFleeing then return end
    TaskTurnPedToFaceEntity(petPed, PlayerPedId(), 1000)
end)

RegisterNetEvent('tbrp_companions:client:toggleStay', function()
    if not petIsOut or petFleeing then return end
    if petState == 'stay' then
        setState('follow')
    else
        setState('stay')
    end
end)

CreateThread(function()
    while true do
        Wait(5)
        if Config.CallPetKey and IsControlJustReleased(0, callKey) then
            if petIsOut and not isPetEntityValid() then
                resetPetState()
            end

            if not petIsOut then
                local now = GetGameTimer()
                if recallCooldownUntil > 0 and now < recallCooldownUntil then
                    local secs = math.ceil((recallCooldownUntil - now) / 1000)
                    if lib and lib.notify then lib.notify({description = string.format('Pet is recovering: %ds remaining', secs), type = 'inform', duration = 10000}) end
                else
                    TriggerServerEvent('tbrp_companions:loaddog')
                end
            else
                local now = GetGameTimer()
                if petFleeing or (recallCooldownUntil > 0 and now < recallCooldownUntil) then
                    local secs = math.ceil((recallCooldownUntil - now) / 1000)
                    if lib and lib.notify then lib.notify({description = string.format('Pet is fleeing: %ds remaining', math.max(0, secs)), type = 'inform', duration = 10000}) end
                else
                    recallPet()
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(5000)
        if petIsOut and not isPetEntityValid() then
            resetPetState()
        end
        if (not petIsOut) or (not isPetEntityValid()) then
            cleanupStrayDogs()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        if not petIsOut or not petPed then goto cont end
        if isFetching or #fetchQueue > 0 then goto cont end
        local pc = GetEntityCoords(PlayerPedId())
        local range = (ConfigFetch and ConfigFetch.Settings and ConfigFetch.Settings.Range) or 200.0
        local animals = (ConfigFetch and ConfigFetch.Animals) or {}
        local peds = GetGamePool('CPed')
        for i=1,#peds do
            local ped = peds[i]
            if ped ~= 0 and DoesEntityExist(ped) and not IsPedHuman(ped) and IsEntityDead(ped) then
                local dc = #(pc - GetEntityCoords(ped))
                if dc <= range + 0.0 then
                    local ignore = (ConfigFetch and ConfigFetch.Settings and ConfigFetch.Settings.IgnoreRange) or 10.0
                    if dc <= ignore + 0.0 then goto nextped end
                    local attacked = HasEntityBeenDamagedByEntity(ped, PlayerPedId(), true, true)
                    if not attacked then
                        local killer = GetPedSourceOfDeath(ped)
                        if killer == PlayerPedId() then attacked = true end
                    end
                    if attacked then
                        local model = GetEntityModel(ped)
                        if animals[model] then
                            local exists = false
                            for j=1,#fetchQueue do if fetchQueue[j] == ped then exists = true break end end
                            if not exists then
                                table.insert(fetchQueue, ped)
                                print('[FetchScan] Queued '..tostring(ped)..' dist '..string.format('%.1f', dc))
                            end
                        end
                    end
                end
                ::nextped::
            end
        end
        ::cont::
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if not petIsOut or not petPed then goto cont end
        if petFleeing then goto cont end
        local id = PlayerId()
        if IsPlayerTargettingAnything(id) then
            local result, entity = GetPlayerTargetEntity(id)
            if result and entity == petPed then
                if FollowPrompt and PromptHasStandardModeCompleted(FollowPrompt) then
                    setState('follow')
                    Wait(300)
                end
                if StayPrompt and PromptHasStandardModeCompleted(StayPrompt) then
                    setState('stay')
                    Wait(300)
                end
                if FeedPrompt and PromptHasStandardModeCompleted(FeedPrompt) then
                    TriggerServerEvent('tbrp_companions:server:feedPetPrompt')
                    Wait(300)
                end
            end
        end
        ::cont::
    end
end)



AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    if petPed and DoesEntityExist(petPed) then DeletePed(petPed) end
    clearBlip()
end)
