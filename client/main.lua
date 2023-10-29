local entities = {}
local npcs = {}
local timeout = false
local timeoutTimer = 30
local horsePed = 0
local horseSpawned = false
local HorseCalled = false

local function handleExports(name)
    for _, v in pairs(Config.BoxZones) do
        for _, n in pairs(v) do
            Wait(100)
            local model = GetHashKey(n.model)
            lib.requestModel(model, 1500)

            local entity = CreatePed(model, n.coords.x, n.coords.y, n.coords.z - 1.0, n.heading, true, true, 0, 0)
            while not DoesEntityExist(entity) do Wait(10) end

            table.insert(entities, entity)
            Citizen.InvokeNative(0x283978A15512B2FE, entity, true)
            FreezeEntityPosition(entity, true)
            SetEntityCanBeDamaged(entity, false)
            SetEntityInvincible(entity, true)
            exports['qr-target']:AddTargetEntity(entity, {
                options = {
                    {
                        icon = "fas fa-horse-head",
                        label =  n.names.." || " .. n.price ..  "$",
                        targeticon = "fas fa-eye",
                        action = function()
                            TriggerServerEvent('qr-stables:server:BuyHorse', n.price, n.model, n.names)
                        end
                    }
                },
                distance = 2.5,
            })
            SetModelAsNoLongerNeeded(model)
        end
    end

    for _, v in pairs(Config.ModelSpawns) do
        lib.requestModel(v.model, 1500)

        local ped = CreatePed(value.model, value.coords.x, value.coords.y, value.coords.z - 1.0, value.heading, true, true, 0, 0)
        while not DoesEntityExist(ped) do Wait(10) end

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
                        TriggerEvent("qr-stables:client:menu")
                    end
                },
                {
                    icon = "fas fa-horse-head",
                    label = "Store Horse",
                    targeticon = "fas fa-eye",
                    action = function()
                        TriggerEvent("qr-stables:client:storehorse")
                    end
                },
                {
                    icon = "fas fa-horse-head",
                    label = "Delete your horse",
                    targeticon = "fas fa-eye",
                    action = function()
                        TriggerEvent("qr-stables:client:MenuDel")
                    end
                }
            },
            distance = 2.5,
        })
        SetModelAsNoLongerNeeded(value.model)
        table.insert(npcs, ped)
    end
end

CreateThread(handleExports)

local function SpawnHorse()
    lib.callback('qr-stables:server:GetActiveHorse', false, function(data)
        if (data) then
            local model = GetHashKey(data.horse)
            local location = GetEntityCoords(cache.ped)
            if location then
                lib.requestModel(model, 1500)

                local coords = GetEntityCoords(cache.ped)
                local heading = 300
                if horsePed ~= 0 then return end

                horsePed = CreatePed(model, coords.x - math.random(50,100), coords.y, coords.z, heading, true, true, 0, 0)
                while not DoesEntityExist(horsePed) do Wait(10) end

                getControlOfEntity(horsePed)
                Citizen.InvokeNative(0x283978A15512B2FE, horsePed, true)
                Citizen.InvokeNative(0x23F74C2FDA6E7C61, -1230993421, horsePed)
                local hasp = GetHashKey("PLAYER")
                Citizen.InvokeNative(0xADB3F206518799E8, horsePed, hasp)
                Citizen.InvokeNative(0xCC97B29285B1DC3B, horsePed, 1)
                Citizen.InvokeNative(0x931B241409216C1F , cache.ped, horsePed , 0)
                SetModelAsNoLongerNeeded(model)
                horseSpawned = true
                moveHorseToPlayer()
                applyImportantThings()
            end
        end
    end)
end

exports('spawnHorse', SpawnHorse)

function applyImportantThings()
    Citizen.InvokeNative(0x931B241409216C1F, cache.ped, horsePed, 0)
    SetPedConfigFlag(horsePed, 297, true)
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x20359E53,true,true,true) --saddle
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x508B80B9,true,true,true) --blanket
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0xF0C30271,true,true,true) --bag
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x12F0DF9F,true,true,true) --bedroll
    Citizen.InvokeNative(0xD3A7B003ED343FD9, horsePed,0x67AF7302,true,true,true) --
end

function moveHorseToPlayer()
    Citizen.CreateThread(function()
        Citizen.InvokeNative(0x6A071245EB0D1882, horsePed, cache.ped, -1, 5.0, 15.0, 0, 0)
        while horseSpawned == true do
            local coords = GetEntityCoords(cache.ped)
            local horseCoords = GetEntityCoords(horsePed)
            local distance = #(coords - horseCoords)
            if (distance < 5.0) then
                ClearPedTasksImmediately(horsePed)
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


local function Flee()
    TaskAnimalFlee(horsePed, cache.ped, -1)
    Wait(10000)
    DeleteEntity(horsePed)
    Wait(1000)
    horsePed = 0
    HorseCalled = false
end

CreateThread(function()
    while true do
        Wait(1)
        if Citizen.InvokeNative(0x91AEF906BCA88877, 0, QRCore.Shared.GetKey('H')) then -- call horse
            if not HorseCalled then
                SpawnHorse()
                HorseCalled = true
                Wait(10000) -- Spam protect
            else
                moveHorseToPlayer()
            end
        elseif Citizen.InvokeNative(0x91AEF906BCA88877, 0, QRCore.Shared.GetKey('HorseCommandFlee')) then -- flee horse
            if horseSpawned ~= 0 then
                Flee()
            end
		end
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, v in pairs(entities) do
        DeletePed(v)
        SetEntityAsNoLongerNeeded(v)
    end

    for _, v in pairs(npcs) do
        DeletePed(v)
        SetEntityAsNoLongerNeeded(v)
    end

    if horsePed ~= 0 then
        DeletePed(horsePed)
        SetEntityAsNoLongerNeeded(horsePed)
    end
end)

CreateThread(function()
    for _, v in pairs(Config.ModelSpawns) do
        local StablesBlip = N_0x554d9d53f696d002(1664425300, v.coords)
        SetBlipSprite(StablesBlip, 1938782895, 52)
        SetBlipScale(StablesBlip, 0.1)
        Citizen.InvokeNative(0x9CB1A1623062F402, tonumber(StablesBlip), "Horse Stable")
    end
end)

local HorseId = nil

RegisterNetEvent('qr-stables:client:SpawnHorse', function(data)
    HorseId = data.player.id
    TriggerServerEvent("qr-stables:server:SetHoresActive", data.player.id)
    QRCore.Functions.Notify('Horse has been set active call from back by whistling', 'success', 7500)
end)

RegisterNetEvent("qr-stables:client:storehorse", function(data)
    if horsePed ~= 0 then
        TriggerServerEvent("qr-stables:server:SetHoresUnActive", HorseId)
        QRCore.Functions.Notify('Taking your horse to the back', 'success', 7500)
        Flee()
        Wait(10000)
        DeletePed(horsePed)
        SetEntityAsNoLongerNeeded(horsePed)
        HorseCalled = false
    end
end)

RegisterNetEvent('qr-stables:client:menu', function()
    local GetHorse = {}
    local horses = lib.callback.await('qr-stables:server:GetHorse', false)

    if horses then
        for _, v in pairs(horses) do
            GetHorse[#GetHorse + 1] = {
                title = v.name,
                icon = "fa-solid fa-circle-user",
                event = "qr-stables:client:SpawnHorse",
                args = { player = v, active = 1 }
            }
        end
    else
        GetHorse[#GetHorse + 1] = {
            title = 'No Horses Available',
            icon = "fas fa-ban",
        }
    end

    lib.registerContext({
        id = 'stables_menu',
        title = '| My Horses |',
        options = GetHorse
    })
    lib.showContext('stables_menu')
end)

RegisterNetEvent('qr-stables:client:MenuDel', function()
    local GetHorse = {}
    local horses = lib.callback.await('qr-stables:server:GetHorse', false)

    if horses then
        for _, v in pairs(horses) do
            GetHorse[#GetHorse + 1] = {
                title = v.name,
                description = "Delete Horse",
                icon = "fa-solid fa-circle-user",
                event = "qr-stables:client:MenuDelC",
            }
        end
    else
        GetHorse[#GetHorse + 1] = {
            title = 'No Horses Available',
            icon = "fas fa-ban",
        }
    end

    lib.registerContext({
        id = 'stables_menu_delete',
        title = '| Delete Horses |',
        options = GetHorse
    })
    lib.showContext('stables_menu_delete')
end)

RegisterNetEvent('qr-stables:client:MenuDelC', function(data)
    local GetHorse = {}
    local horses = lib.callback.await('qr-stables:server:GetHorse', false)
    for _, v in pairs(horses) do
        GetHorse[#GetHorse + 1] = {
            title = v.name,
            description = "Doing this will make you lose your horse forever!",
            icon = "fa-solid fa-circle-user",
            event = "qr-stables:client:DeleteHorse",
            args = { player = v, active = 1 }
        }
    end

    lib.registerContext({
        id = 'stables_menu_delete_confirm',
        title = '| Confirm Delete Horses |',
        options = GetHorse
    })
    lib.showContext('stables_menu_delete_confirm')
end)

RegisterNetEvent('qr-stables:client:DeleteHorse', function(data)
    QRCore.Functions.Notify('Horse has been successfully removed', 'success', 7500)
    TriggerServerEvent("qr-stables:server:DelHores", data.player.id)
end)
