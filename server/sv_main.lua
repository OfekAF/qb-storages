local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateCallback('qb-storages:server:createStorage', function(source,cb,data)
	local src = source
    local storages= MySQL.Sync.fetchAll('SELECT storagename,storage_location FROM storages WHERE citizenid = ? And storagename = ? AND storage_location = ?',{data.cid,data.storagename,data.storagelocation})
    if next(storages) then
        return cb(false)
    else
        local storage = MySQL.Sync.execute('INSERT INTO storages (`citizenid`, `password`, `storagename`,`storage_location`,`storage_size`) VALUES (?, ?, ?, ?, ?)',{data.cid,data.password,data.storagename,data.storagelocation,data.storagesize})
        return cb(true)
    end
    
end)

QBCore.Functions.CreateCallback('qb-storages:server:fetchStorage', function(source,cb,data)
	local src = source
    local cid = string.lower('%'..data.cid..'%')
    print()
    local storages= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size FROM storages WHERE (LOWER(citizenid) like ? OR LOWER(holders) like ? ) AND storage_location = ? ',{cid,cid,data.storagelocation})
    if next(storages) then
        return cb(storages)
    else
        return cb(false)
    end
    
end)

QBCore.Functions.CreateCallback('qb-storages:server:checkThePassword', function(source,cb,data)
	local src = source
    local storage= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size FROM storages WHERE id = ? And password = ? ',{data.id,data.password})
    if next(storage) then
        return cb(storage)
    else
        return cb(false)
    end
end)

QBCore.Functions.CreateCallback('qb-storages:server:addMember', function(source,cb,data)
	local src = source
    local holders
    local storage= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size,holders FROM storages WHERE id = ? ',{data.id})
    if next(storage) then
        if storage[1].holders then
           holders =json.decode(storage[1].holders)
        else
            holders= {}
        end

        table.insert(holders,data.citizenid)
        MySQL.Async.execute("UPDATE storages SET `holders`=:holders WHERE `id`=:id LIMIT 1", {
            holders = json.encode(holders),
            id = data.id
        }, function(r)
            if r then
                return cb(r)
            end
        end)
    else
        return cb(false)
    end
    
end)
QBCore.Functions.CreateCallback('qb-storages:server:changePassword', function(source,cb,data)
	local src = source
    local storage= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size,holders FROM storages WHERE id = ? ',{data.id})
    if next(storage) then
        MySQL.Async.execute("UPDATE storages SET `password`=:password WHERE `id`=:id LIMIT 1", {
            password = data.password,
            id = data.id
        }, function(r)
            if r then
                return cb(r)
            end
        end)
        TriggerEvent('qb-logs:server:createLog', 'storagepassword', 'Password Changed', "", source)
    else
        return cb(false)
    end
    
end)


QBCore.Functions.CreateCallback('qb-storages:server:removeMember', function(source,cb,data)
	local src = source
    local holders
    local storage= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size,holders FROM storages WHERE id = ? ',{data.id})
    if next(storage) then
        local temHolders={}
        if storage[1].holders then
           holders =json.decode(storage[1].holders)
        else
            holders= {}
        end

        for k, v in pairs(holders) do
            if v ~= data.citizenid then
                table.insert(temHolders,v)
            end
        end
        MySQL.Async.execute("UPDATE storages SET `holders`=:holders WHERE `id`=:id LIMIT 1", {
            holders = json.encode(temHolders),
            id = data.id
        }, function(r)
            if r then
                return cb(r)
            end
        end)
    else
        return cb(false)
    end
    
end)

QBCore.Functions.CreateCallback('qb-storages:server:addCapacity', function(source,cb,data)
	local src = source
    local holders
    local storage= MySQL.Sync.fetchAll('SELECT id,citizenid,storagename,storage_location,storage_size,holders FROM storages WHERE id = ? ',{data.id})
    if next(storage) then
        local storage_size = storage[1].storage_size + Config.StorageAddStep
        MySQL.Async.execute("UPDATE storages SET `storage_size`=:storage_size WHERE `id`=:id LIMIT 1", {
            storage_size = storage_size,
            id = data.id
        }, function(r)
            if r then
                return cb(r)
            end
        end)
    else
        return cb(false)
    end
    
end)


RegisterServerEvent('qb-storages:server:removeMoney')
AddEventHandler('qb-storages:server:removeMoney', function(price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    Player.Functions.RemoveMoney('cash', price, "buy-storage")
end)
