local robbers = {}
local CopsConnected  = 0
local lastSold = {} 
local Dispatch = require 'server.dispatch' 

AddEventHandler('esx:playerLoaded', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if lib.table.contains(Config.Police.Jobs, xPlayer.job.name) then
        CopsConnected = CopsConnected + 1
    end
end)

AddEventHandler('esx:playerDropped', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer and lib.table.contains(Config.Police.Jobs, xPlayer.job.name) then
        CopsConnected = math.max(0, CopsConnected - 1)
    end
end)

AddEventHandler('esx:setJob', function(source, job, lastJob)
    if lib.table.contains(Config.Police.Jobs, lastJob.name) then
        CopsConnected = math.max(0, CopsConnected - 1)
    end
    if lib.table.contains(Config.Police.Jobs, job.name) then
        CopsConnected = CopsConnected + 1
    end
end)

RegisterNetEvent('esx_vangelico_robbery:toofar')
AddEventHandler('esx_vangelico_robbery:toofar', function(robb)
	local source = source
	if robbers[source] then
		TriggerClientEvent('esx_vangelico_robbery:toofarlocal', source)
		robbers[source] = nil
	end
end)

RegisterNetEvent('esx_vangelico_robbery:endrob')
AddEventHandler('esx_vangelico_robbery:endrob', function(robb)
	local source = source
	local xPlayers = ESX.GetPlayers()
	
	for i=1, #xPlayers, 1 do
		local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
		if lib.table.contains(Config.Police.Jobs, xPlayer.job.name) then
			TriggerClientEvent('ox_lib:notify', xPlayers[i], {
				title = _U('end'),
				type = 'success'
			})
		end
	end
	
	if robbers[source] then
		TriggerClientEvent('esx_vangelico_robbery:robberycomplete', source)
		robbers[source] = nil
	end
end)

RegisterNetEvent('esx_vangelico_robbery:rob')
AddEventHandler('esx_vangelico_robbery:rob', function(robb)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local xPlayers = ESX.GetPlayers()
	
	if Locations.stores[robb] then
		local store = Locations.stores[robb]

		if not store.lastRobbed then
			store.lastRobbed = 0
		end

		if (os.time() - store.lastRobbed) < Config.SecBetwNextRob and store.lastRobbed ~= 0 then
			TriggerClientEvent('ox_lib:notify', source, {
				title = _U('already_expropriated') .. math.floor((Config.SecBetwNextRob - (os.time() - store.lastRobbed)) / 60) .. _U('minutes'),
				type = 'error'
			})
			return
		end

		if CopsConnected >= Config.Police.RequiredCops.Rob then
			robbers[source] = robb
			Dispatch.SendDispatchAlert(store.position, store.nameofstore)
			TriggerClientEvent('esx_vangelico_robbery:currentlyrobbing', source, robb)
			store.lastRobbed = os.time()
		else
			TriggerClientEvent('ox_lib:notify', source, {
				title = _U('min_two_police') .. Config.Police.RequiredCops.Rob .. _U('min_two_police2'),
				type = 'error'
			})
		end
	end
end)


-- Fuck you cheaters lick my dick. (Removed old additem event, try exploiting now.)
lib.callback.register('esx_vangelico_robbery:getJewels', function(source)
    if not robbers[source] then return false end  -- Check if player is in a robbery (Because if not how the fuck are they gonna rob it?)
    
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    
    -- Check if player is near any display case in the store they're robbing (Because how the fuck are they gonna rob it and get items if they're not near the case?)
    local isNearCase = false
    local store = Locations.stores[robbers[source]]
    if store then
        for _, displayCase in pairs(store.display_cases) do
            if #(coords - vector3(displayCase.x, displayCase.y, displayCase.z)) < 1.0 then
                isNearCase = true
                break
            end
        end
    end
    
    if not isNearCase then return false end
    
    local amount = math.random(Config.Selling.Jewels.Min, Config.Selling.Jewels.Max)
    local totalWeight = amount * 220
    local canCarryWeight, freeWeight = exports.ox_inventory:CanCarryWeight(source, totalWeight)
    
    if canCarryWeight then
        local success = exports.ox_inventory:AddItem(source, 'jewels', amount)
        return success
    end
    
    return false
end)

-- Again fuck you cheaters suck my dick.
lib.callback.register('esx_vangelico_robbery:sellJewels', function(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local lesterCoords = Locations.lester.coords
    
    if #(coords - lesterCoords) > 2.0 then return false end
    
    if CopsConnected < Config.Police.RequiredCops.Sell then return false end
    
    -- Check cooldown
    local currentTime = os.time()
    if lastSold[source] and (currentTime - lastSold[source]) < Config.Selling.Cooldown then
        local remainingTime = Config.Selling.Cooldown - (currentTime - lastSold[source])
        TriggerClientEvent('ox_lib:notify', source, {
            title = _U('cooldown_active') .. remainingTime .. _U('seconds'),
            type = 'error'
        })
        return false
    end
    
    local count = exports.ox_inventory:GetItemCount(source, 'jewels')
    
    if count >= Config.Selling.Jewels.Min then
        local amountToSell = math.min(count, Config.Selling.Jewels.Max)
        local success = exports.ox_inventory:RemoveItem(source, 'jewels', amountToSell)
        if success then
            local reward = math.floor(Config.Selling.Jewels.Price * amountToSell)
            exports.ox_inventory:AddItem(source, 'money', reward)
            lastSold[source] = currentTime 
            return true
        end
    end
    return false
end)

lib.callback.register('esx_vangelico_robbery:conteggio', function(source)
    return CopsConnected
end)
