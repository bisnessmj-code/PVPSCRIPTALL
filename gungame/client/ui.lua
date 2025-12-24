--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CLIENT - UI.LUA                                     ║
    ║                      Bridge NUI - Interface                                ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local isUIVisible = false

RegisterNUICallback('uiReady', function(data, cb)
    Logger.Debug('UI', 'NUI prête')
    cb({ success = true })
end)

RegisterNUICallback('closeUI', function(data, cb)
    isUIVisible = false
    SetNuiFocus(false, false)
    cb({ success = true })
end)

RegisterNUICallback('requestLeave', function(data, cb)
    TriggerServerEvent('gungame:server:requestLeave')
    cb({ success = true })
end)

exports('isUIVisible', function() return isUIVisible end)
