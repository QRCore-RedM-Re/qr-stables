local QRCore = exports['qr-core']:GetCoreObject()

RegisterServerEvent('qr-stables:server:BuyHorse', function(price, model, names)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    if (Player.PlayerData.money.cash < price) then
        TriggerClientEvent('QRCore:Notify', src, 'You don\'t have enough cash!', 'error')
        return
    end
    MySQL.insert('INSERT INTO player_horses(citizenid, name, horse, components, active) VALUES(@citizenid, @name, @horse, @components, @active)', {
        ['@citizenid'] = Player.PlayerData.citizenid,
        ['@name'] = names,
        ['@horse'] = model,
        ['@components'] = json.encode({}),
        ['@active'] = false,
    })
    Player.Functions.RemoveMoney('cash', price)
    TriggerClientEvent('QRCore:Notify', src, 'You have successfully bought a horse', 'success')
end)

RegisterServerEvent('qr-stables:server:SetHoresActive', function(id)
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, true})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { true, id, Player.PlayerData.citizenid })
end)

RegisterServerEvent('qr-stables:server:SetHoresUnActive', function(id)
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
    local activehorse = MySQL.scalar.await('SELECT id FROM player_horses WHERE citizenid = ? AND active = ?', {Player.PlayerData.citizenid, false})
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, activehorse, Player.PlayerData.citizenid })
    MySQL.update('UPDATE player_horses SET active = ? WHERE id = ? AND citizenid = ?', { false, id, Player.PlayerData.citizenid })
end)

RegisterServerEvent('qr-stables:server:DelHores', function(id)
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
    MySQL.update('DELETE FROM player_horses WHERE id = ? AND citizenid = ?', { id, Player.PlayerData.citizenid })
end)

QRCore.Functions.CreateCallback('qr-stables:server:GetHorse', function(source, cb)
	local src = source
	local Player = QRCore.Functions.GetPlayer(src)
	local GetHorse = {}
	local horses = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid', {
        ['@citizenid'] = Player.PlayerData.citizenid,
    })    
	if horses[1] ~= nil then
        cb(horses)
	end
end)

QRCore.Functions.CreateCallback('qr-stables:server:GetActiveHorse', function(source, cb)
    local src = source
    local Player = QRCore.Functions.GetPlayer(src)
    local cid = Player.PlayerData.citizenid
    local result = MySQL.query.await('SELECT * FROM player_horses WHERE citizenid=@citizenid AND active=@active', {
        ['@citizenid'] = cid,
        ['@active'] = 1
    })
    if (result[1] ~= nil) then
        cb(result[1])
    else
        return
    end
end)
