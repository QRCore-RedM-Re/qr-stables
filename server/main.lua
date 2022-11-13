local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent('qr-stables:server:buyHorse')
AddEventHandler('qr-stables:server:buyHorse', function(price, model)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    if (Player.PlayerData.money.cash < price) then
        print("buy a horse")
        return
    end

    exports.ghmattimysql:executeSync('INSERT INTO player_horses(citizenid, horse, components, active) VALUES(@citizenid, @horse, @components, @active)', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@horse'] = model,
        ['@components'] = json.encode({}),
        ['@active'] = true,
    })
    Player.Functions.RemoveMoney('cash', price)
    print("You have successfully bought a horse")
end)


QRCore.Functions.CreateCallback('qr-stables:server:getActiveHorse', function(source, cb)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local result = exports.ghmattimysql:executeSync('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)