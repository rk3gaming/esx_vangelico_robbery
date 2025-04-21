local holdingup = false
local store = ""
local vetrineRotte = 0 

local function Notify(title, description, type)
    lib.notify({
        title = title,
        description = description,
        type = type or 'inform'
    })
end

local function PlayCaseEffects(x, y, z)
    PlaySoundFromCoord(-1, "Glass_Smash", x, y, z, "", 0, 0, 0)
    lib.requestNamedPtfxAsset("scr_jewelheist")
    SetPtfxAssetNextCall("scr_jewelheist")
    StartParticleFxLoopedAtCoord("scr_jewel_cab_smash", x, y, z, 0.0, 0.0, 0.0, 1.0, false, false, false, false)
end

local function PlayCaseAnimation(ped, x, y, z, heading)
    SetEntityCoords(ped, x, y, z-0.95)
    SetEntityHeading(ped, heading)
    lib.requestAnimDict("missheist_jewel")
    lib.playAnim(ped, "missheist_jewel", "smash_case", 8.0, 8.0, 5000, 2, 0.0, false, 0, false)
end

local function ResetStoreCases(store)
    for i,_ in pairs(Locations.stores[store].display_cases) do 
        Locations.stores[store].caseStates[i].isOpen = false
    end
    vetrineRotte = 0
end

local function CreateBlip(coords, sprite, color, scale, name)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color)
    SetBlipScale(blip, scale)
    SetBlipAsShortRange(blip, true)
    if name then
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString(name)
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

return {
    holdingup = holdingup,
    store = store,
    vetrineRotte = vetrineRotte,
    Notify = Notify,
    PlayCaseEffects = PlayCaseEffects,
    PlayCaseAnimation = PlayCaseAnimation,
    ResetStoreCases = ResetStoreCases,
    CreateBlip = CreateBlip
}
