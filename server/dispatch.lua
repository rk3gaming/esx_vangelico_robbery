local function SendDispatchAlert(coords, storeName)
    local dispatchType = Config.Police.Dispatch
    
    if dispatchType == 'melons' then
        exports.melons_dispatch:DispatchAlert(coords, "storerobbery")
    elseif dispatchType == 'rcore' then
        local data = {
            code = '10-64 - Store Robbery',
            default_priority = 'high',
            coords = coords,
            job = 'police',
            text = 'A store robbery is in progress at ' .. storeName,
            type = 'shop_robbery',
            blip_time = 30,
            blip = {
                sprite = 439,
                colour = 1,
                scale = 0.7,
                text = 'Store Robbery',
                flashes = true,
                radius = 0
            }
        }
        TriggerEvent('rcore_dispatch:server:sendAlert', data)
    end
end

return {
    SendDispatchAlert = SendDispatchAlert
}
