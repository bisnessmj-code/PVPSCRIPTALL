--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     DEBUG - DÉTECTION DES TOUCHES                          ║
    ║              Affiche dans la console toutes les touches pressées           ║
    ║                    (Désactivé si Config.Debug = false)                     ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local debugMode = false

-- Commande pour activer/désactiver le debug
RegisterCommand('ggdebug', function()
    debugMode = not debugMode
    Logger.Info('DEBUG', 'Mode debug: %s', debugMode and 'ACTIVÉ' or 'DÉSACTIVÉ')
end, false)

-- Liste des touches à surveiller
local controlsToMonitor = {
    {id = 37, name = "TAB (Inventaire)"},
    {id = 157, name = "1 (&)"},
    {id = 158, name = "2 (é)"},
    {id = 160, name = "3 (\")"},
    {id = 164, name = "4 (')"},
    {id = 165, name = "5 (()"},
    {id = 159, name = "6 (-)"},
    {id = 161, name = "7 (è)"},
    {id = 162, name = "8 (_)"},
    {id = 163, name = "9 (ç)"},
    {id = 14, name = "Scroll Down"},
    {id = 15, name = "Scroll Up"},
    {id = 16, name = "Scroll Wheel"},
    {id = 17, name = "Scroll Wheel Alt"},
    {id = 289, name = "I (Inventaire)"},
    {id = 170, name = "F3 (Inventaire Alt)"},
    {id = 244, name = "M (Map)"},
    {id = 288, name = "F1 (Phone/Menu)"},
    {id = 99, name = "X (Weapon Select)"},
    {id = 115, name = "X (Alt)"},
}

CreateThread(function()
    while true do
        Wait(0)
        
        if debugMode then
            for _, control in ipairs(controlsToMonitor) do
                if IsControlJustPressed(0, control.id) or 
                   IsControlJustPressed(1, control.id) or 
                   IsDisabledControlJustPressed(0, control.id) or 
                   IsDisabledControlJustPressed(1, control.id) then
                    Logger.Debug('DEBUG', '🔴 Touche pressée: %s (Control ID: %d)', control.name, control.id)
                end
                
                if IsControlPressed(0, control.id) or 
                   IsControlPressed(1, control.id) or 
                   IsDisabledControlPressed(0, control.id) or 
                   IsDisabledControlPressed(1, control.id) then
                    Logger.Debug('DEBUG', '🟡 Touche maintenue: %s (Control ID: %d)', control.name, control.id)
                end
            end
        else
            Wait(500)
        end
    end
end)

Logger.Debug('DEBUG', 'Script de debug chargé - Utilise /ggdebug pour activer')
