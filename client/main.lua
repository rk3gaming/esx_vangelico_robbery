local F = require 'client.functions'
local lesterPed = nil
local storeMarkers = {}
local storeZones = {}
local caseMarkers = {}
local caseZones = {}
local soundid = GetSoundId()

RegisterNetEvent('esx_vangelico_robbery:currentlyrobbing')
AddEventHandler('esx_vangelico_robbery:currentlyrobbing', function(robb)
	F.holdingup = true
	F.store = robb
end)

RegisterNetEvent('esx_vangelico_robbery:toofarlocal')
AddEventHandler('esx_vangelico_robbery:toofarlocal', function(robb)
	F.holdingup = false
end)

RegisterNetEvent('esx_vangelico_robbery:robberycomplete')
AddEventHandler('esx_vangelico_robbery:robberycomplete', function(robb)
	F.holdingup = false
	F.Notify(_U('robbery_complete'), '', 'success')
	F.store = ""
end)

CreateThread(function()
	if not Config.UseBlips then return end
	
	for k,v in pairs(Locations.stores) do
		F.CreateBlip(v.position, v.blip.sprite, v.blip.color, v.blip.scale, _U('shop_robbery'))
	end
end)

for k,v in pairs(Locations.stores) do
    storeMarkers[k] = lib.marker.new({
        type = 27,
        coords = vec3(v.position.x, v.position.y, v.position.z - 0.9),
        color = { r = 255, g = 0, b = 0, a = 200 },
        width = 2.001,
        height = 0.5001
    })

    v.caseStates = {}
    for i,case in pairs(v.display_cases) do
        v.caseStates[i] = { isOpen = false }
    end

    storeZones[k] = lib.zones.sphere({
        coords = vec3(v.position.x, v.position.y, v.position.z),
        radius = 15,
        debug = false,
        inside = function()
            if not F.holdingup then
                storeMarkers[k]:draw()
            else
                for i,case in pairs(v.display_cases) do
                    if not v.caseStates[i].isOpen and Config.EnableMarker then
                        caseMarkers[i]:draw()
                    end
                end
            end
        end,
        onExit = function()
            if F.holdingup and F.store == k then
                TriggerServerEvent('esx_vangelico_robbery:toofar', k)
                F.holdingup = false
                for i,_ in pairs(v.display_cases) do 
                    v.caseStates[i].isOpen = false
                    F.vetrineRotte = 0
                end
                StopSound(soundid)
            end
        end
    })

    lib.zones.sphere({
        coords = vec3(v.position.x, v.position.y, v.position.z),
        radius = 1.0,
        debug = false,
        inside = function()
            if not F.holdingup and IsPedShooting(cache.ped) then
                lib.callback('esx_vangelico_robbery:conteggio', false, function(CopsConnected)
                    if CopsConnected >= Config.Police.RequiredCops.Rob then
                        TriggerServerEvent('esx_vangelico_robbery:rob', k)
                        PlaySoundFromCoord(soundid, "VEHICLES_HORNS_AMBULANCE_WARNING", v.position.x, v.position.y, v.position.z)
                    else
                        F.Notify(_U('min_two_police') .. Config.Police.RequiredCops.Rob .. _U('min_two_police2'), '', 'error')
                    end
                end)
            end
        end,
        onEnter = function()
            if not F.holdingup then
                lib.showTextUI(_U('press_to_rob'), {
                    position = 'top-center',
                    icon = 'gun',
                    iconColor = '#30c940'
                })
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })

    for i,case in pairs(v.display_cases) do
        caseMarkers[i] = lib.marker.new({
            type = 20,
            coords = vec3(case.x, case.y, case.z),
            color = { r = 0, g = 255, b = 0, a = 200 },
            width = 0.3,
            height = 0.3
        })

        caseZones[i] = lib.zones.sphere({
            coords = vec3(case.x, case.y, case.z),
            radius = 0.75,
            debug = false,
            onEnter = function()
                if F.holdingup and not v.caseStates[i].isOpen then
                    lib.showTextUI(_U('press_to_collect'), {
                        position = 'right-center',
                        icon = 'gem',
                        iconColor = '#4a76d4'
                    })
                end
            end,
            onExit = function()
                lib.hideTextUI()
            end
        })
    end
end

CreateThread(function()
    while true do
        if F.holdingup then
            local playerCoords = GetEntityCoords(cache.ped)
            local store = Locations.stores[F.store]
            
            for i,case in pairs(store.display_cases) do
                if not store.caseStates[i].isOpen and caseZones[i]:contains(playerCoords) then
                    if IsControlJustPressed(0, 38) then
                        lib.hideTextUI()
                        
                        local canProceed = true
                        if Config.Skillcheck then
                            local success = lib.skillCheck({'medium', 'medium', 'medium'}, {'w', 'a', 's', 'd'})
                            if not success then
                                F.Notify(_U('skillcheck_failed'), '', 'error')
                                canProceed = false
                            end
                        end

                        if canProceed then
                            F.PlayCaseAnimation(cache.ped, case.x, case.y, case.z, case.w)
                            store.caseStates[i].isOpen = true 
                            F.PlayCaseEffects(case.x, case.y, case.z)
                            
                            F.Notify(_U('collectinprogress'), '', 'inform')
                            Citizen.Wait(5000)
                            ClearPedTasksImmediately(cache.ped)
                            
                            lib.callback('esx_vangelico_robbery:getJewels', false, function(success)
                                if success then
                                    PlaySound(-1, "PICK_UP", "HUD_FRONTEND_DEFAULT_SOUNDSET", 0, 0, 1)
                                    F.vetrineRotte = F.vetrineRotte + 1
                                    
                                    if F.vetrineRotte == Config.MaxWindows then 
                                        F.ResetStoreCases(F.store)
                                        TriggerServerEvent('esx_vangelico_robbery:endrob', F.store)
                                        F.Notify(_U('lester'), '', 'success')
                                        F.holdingup = false
                                        StopSound(soundid)
                                    end
                                else
                                    F.Notify(_U('inventory_full'), '', 'error')
                                end
                            end)
                        end
                    end
                end
            end
            Citizen.Wait(0)
        else
            Citizen.Wait(1000)
        end
    end
end)

CreateThread(function()
    lib.requestModel(Locations.lester.model)
    lesterPed = CreatePed(4, `cs_lestercrest`, Locations.lester.coords.x, Locations.lester.coords.y, Locations.lester.coords.z, Locations.lester.heading, false, true)
    SetEntityHeading(lesterPed, Locations.lester.heading)
    FreezeEntityPosition(lesterPed, true)
    SetEntityInvincible(lesterPed, true)
    SetBlockingOfNonTemporaryEvents(lesterPed, true)
    
    if Config.UseBlips then
        F.CreateBlip(Locations.lester.coords, Locations.lester.blip.sprite, Locations.lester.blip.color, Locations.lester.blip.scale, Locations.lester.blip.name)
    end
    
    local lesterZone = lib.zones.sphere({
        coords = Locations.lester.coords,
        radius = 1.5,
        debug = false,
        onEnter = function()
            lib.showTextUI(_U('press_to_sell'), {
                position = 'right-center',
                icon = 'gem',
                iconColor = '#4a76d4'
            })
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })
    
    while true do
        local sleep = 1000
        if lesterZone:contains(GetEntityCoords(cache.ped)) then
            sleep = 0
            if IsControlJustReleased(1, 51) then
                lib.hideTextUI()
                local count = exports.ox_inventory:Search('count', 'jewels')
                
                if count >= Config.Selling.Jewels.Min then
                    lib.callback('esx_vangelico_robbery:conteggio', false, function(CopsConnected)
                        if CopsConnected >= Config.Police.RequiredCops.Sell then
                            if lib.progressBar({
                                duration = 5000,
                                label = 'Selling jewels...',
                                useWhileDead = false,
                                canCancel = true,
                                disable = {
                                    car = true,
                                    move = true,
                                    combat = true
                                },
                                anim = {
                                    dict = 'mp_common',
                                    clip = 'givetake1_a'
                                }
                            }) then
                                lib.callback('esx_vangelico_robbery:sellJewels', false, function(success)
                                    if success then
                                        F.Notify(_U('sold_jewels'), '', 'success')
                                    else
                                        F.Notify(_U('failed_sell'), '', 'error')
                                    end
                                end)
                            else
                                F.Notify(_U('cancelled'), '', 'error')
                            end
                        else
                            F.Notify(_U('copsforsell') .. Config.Police.RequiredCops.Sell .. _U('copsforsell2'), '', 'error')
                        end
                    end)
                else
                    F.Notify(_U('notenoughgold'), '', 'error')
                end
            end
        end
        Citizen.Wait(sleep)
    end
end)


