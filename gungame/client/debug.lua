--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                     DEBUG - DÉTECTION DES TOUCHES                          ║
    ║              Affiche dans la console toutes les touches pressées           ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

local debugMode = false

-- Commande pour activer/désactiver le debug
RegisterCommand('ggdebug', function()
    debugMode = not debugMode
    print('^5[GunGame][DEBUG]^7 Mode debug: ' .. (debugMode and '^2ACTIVÉ' or '^1DÉSACTIVÉ'))
end, false)

-- Liste des touches à surveiller pour qs-inventory
local controlsToMonitor = {
    -- TAB
    {id = 37, name = "TAB (Inventaire)"},
    
    -- Touches 1-9
    {id = 157, name = "1 (&)"},
    {id = 158, name = "2 (é)"},
    {id = 160, name = "3 (\")"},
    {id = 164, name = "4 (')"},
    {id = 165, name = "5 (()"},
    {id = 159, name = "6 (-)"},
    {id = 161, name = "7 (è)"},
    {id = 162, name = "8 (_)"},
    {id = 163, name = "9 (ç)"},
    
    -- Scroll
    {id = 14, name = "Scroll Down"},
    {id = 15, name = "Scroll Up"},
    {id = 16, name = "Scroll Wheel"},
    {id = 17, name = "Scroll Wheel Alt"},
    
    -- Inventaire
    {id = 289, name = "I (Inventaire)"},
    {id = 170, name = "F3 (Inventaire Alt)"},
    
    -- Menu
    {id = 244, name = "M (Map)"},
    {id = 288, name = "F1 (Phone/Menu)"},
    
    -- X
    {id = 99, name = "X (Weapon Select)"},
    {id = 115, name = "X (Alt)"},
}

CreateThread(function()
    while true do
        Wait(0)
        
        if debugMode then
            for _, control in ipairs(controlsToMonitor) do
                -- Vérifier si la touche vient d'être pressée
                if IsControlJustPressed(0, control.id) or 
                   IsControlJustPressed(1, control.id) or 
                   IsDisabledControlJustPressed(0, control.id) or 
                   IsDisabledControlJustPressed(1, control.id) then
                    print('^3[GunGame][DEBUG]^7 🔴 Touche pressée: ^5' .. control.name .. '^7 (Control ID: ' .. control.id .. ')')
                end
                
                -- Vérifier si la touche est maintenue
                if IsControlPressed(0, control.id) or 
                   IsControlPressed(1, control.id) or 
                   IsDisabledControlPressed(0, control.id) or 
                   IsDisabledControlPressed(1, control.id) then
                    print('^3[GunGame][DEBUG]^7 🟡 Touche maintenue: ^5' .. control.name .. '^7 (Control ID: ' .. control.id .. ')')
                end
            end
        else
            Wait(500)
        end
    end
end)

print('^2[GunGame][DEBUG]^7 Script de debug chargé')
print('^2[GunGame][DEBUG]^7 Utilise /ggdebug pour activer/désactiver')
