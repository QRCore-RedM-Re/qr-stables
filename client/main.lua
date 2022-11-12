local entities = {}
local npcs = {}
local timeout = false
local timeoutTimer = 30
local horsePed = 0
local horseSpawned = false
local QRCore = exports['qr-core']:GetCoreObject()

function handleExports()
    for k,v in pairs(Config.BoxZones) do
        for j, n in pairs(v) do
            Wait(100)
            local model = GetHashKey(n.model)
            while (not HasModelLoaded(model)) do
                RequestModel(model)
                Wait(10)
            end
            local entity = CreatePed(model, n.coords.x, n.coords.y, n.coords.z - 1.0, n.heading, true, true, 0, 0)
            while not DoesEntityExist(entity) do
                Wait(10)
            end
            table.insert(entities, entity)
            Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
            SetEntityCanBeDamaged(entity, false)
            SetEntityInvincible(entity, true)
            Wait(100)
            exports['qr-target']:AddTargetEntity(entity, {
                options = {
                    {
                        icon = "fas fa-horse-head",
                        label = "Buy horse " .. n.price .. "$",
                        targeticon = "fas fa-eye",
                        action = function()
                            TriggerServerEvent('qr-stables:server:buyHorse', n.price, n.model)
                        end
                    }
                },
                distance = 2.5,
            })
            SetModelAsNoLongerNeeded(model)
        end
    end

    for key,value in pairs(Config.ModelSpawns) do
        while not HasModelLoaded(value.model) do
            RequestModel(value.model)
            Wait(10)
        end
        local ped = CreatePed(value.model, value.coords.x, value.coords.y, value.coords.z - 1.0, value.heading, true, true, 0, 0)
        while not DoesEntityExist(ped) do
            Wait(10)
        end

        Citizen.InvokeNative(0x283978A15512B2FE, ped, true)
        SetEntityCanBeDamaged(ped, false)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        Wait(100)
        exports['qr-target']:AddTargetEntity(ped, {
            options = {
                {
                    icon = "fas fa-horse-head",
                    label = "Get your horse",
                    targeticon = "fas fa-eye",
                    action = function()
                        exports['qr-stables']:spawnHorse(key)
                    end
                }
            },
            distance = 2.5,
        })
        SetModelAsNoLongerNeeded(value.model)
        table.insert(npcs, ped)
    end
end

Citizen.CreateThread(handleExports)

function handleSpawnHorse(playerLocation)
    QRCore.Functions.TriggerCallback('qr-stables:server:getActiveHorse', function(data)
        if (data) then
            local model = GetHashKey(data.horse)
            local location = Config.ModelSpawns[playerLocation]
            if (location) then
                while not HasModelLoaded(model) do
                    RequestModel(model)
                    Wait(10)
                end
                local coords = location.horseCoords
                local heading = location.horseHeading
                if (horsePed == 0) then
                    horsePed = CreatePed(model, coords.x, coords.y, coords.z, heading, true, true, 0, 0)
                    while not DoesEntityExist(horsePed) do
                        Wait(10)
                    end
                    getControlOfEntity(horsePed)
                    Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true)
                    Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed)
                    local hasp = GetHashKey("PLAYER")
                    Citizen.InvokeNative(0xADB3F206518799E8, horsePed, hasp)
                    Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1)
                    Citizen.InvokeNative(0x931B241409216C1F , PlayerPedId(), horsePed , 0)
                    SetModelAsNoLongerNeeded(model)
                    horseSpawned = true
                    moveHorseToPlayer()
                    applyImportantThings()
                end
            end
        end
    end)
end

function applyImportantThings()
    Citizen.InvokeNative(0x931B241409216C1F, PlayerPedId(), horsePed, 0)
    SetPedConfigFlag(horsePed, 297, true)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x20359E53,true,true,true) --saddle
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x508B80B9,true,true,true) --blanket
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0xF0C30271,true,true,true) --bag
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x12F0DF9F,true,true,true) --bedroll
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x67AF7302,true,true,true) --
end

function moveHorseToPlayer()
    Citizen.CreateThread(function()
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, PlayerPedId(), -1, 5.0, 15.0, 0, 0)
        while horseSpawned == true do
            local coords = GetEntityCoords(PlayerPedId())
            local horseCoords = GetEntityCoords(horsePed)
            local distance = #(coords - horseCoords)
            if (distance < 5.0) then
                ClearPedTasksImmediately(horsePed, true, true)
                horseSpawned = false
            end
            Wait(1000)
        end
    end)
end

function setPedDefaultOutfit(model)
    return Citizen.InvokeNative(0x283978A15512B2FE, model, true)
end

function getControlOfEntity(entity)
    NetworkRequestControlOfEntity(entity)
    SetEntityAsMissionEntity(entity, true, true)
    local timeout = 2000

    while timeout > 0 and NetworkHasControlOfEntity(entity) == nil do
        Wait(100)
        timeout = timeout - 100
    end
    print('We have control of entity')
    return NetworkHasControlOfEntity(entity)
end


Citizen.CreateThread(function()
    while true do
        if (timeout) then
            if (timeoutTimer == 0) then
                timeout = false
            end
            timeoutTimer = timeoutTimer - 1
            Wait(1000)
        end
        Wait(0)
    end
end)

Citizen.CreateThread(function()
    while true do
        Wait(10)
        if (not timeout) then
            if IsControlJustReleased(0, 0x24978A28) then
                timeout = true
                spawnHorse()
            end
        end
    end
end)

exports('spawnHorse', handleSpawnHorse)

AddEventHandler('onResourceStop', function(resource)
    if (resource == GetCurrentResourceName()) then
        for k,v in pairs(entities) do
            DeletePed(v)
            SetEntityAsNoLongerNeeded(v)
        end

        for k,v in pairs(npcs) do
            DeletePed(v)
            SetEntityAsNoLongerNeeded(v)
        end

        if (horsePed ~= 0) then
            DeletePed(horsePed)
            SetEntityAsNoLongerNeeded(horsePed)
        end
    end
end)