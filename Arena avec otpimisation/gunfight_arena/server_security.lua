-- ================================================================================================
-- GUNFIGHT ARENA - COMMANDES ADMIN SÉCURISÉES
-- ================================================================================================
-- ✅ Commande pour configurer le webhook de manière sécurisée
-- ✅ Accessible uniquement aux admins/superadmins
-- ================================================================================================

local ESX = exports['es_extended']:getSharedObject()

-- ================================================================================================
-- FONCTION : VÉRIFIER SI LE JOUEUR EST ADMIN
-- ================================================================================================
local function IsAdmin(playerId)
    if playerId == 0 then
        return true -- Console
    end
    
    local xPlayer = ESX.GetPlayerFromId(playerId)
    if not xPlayer then return false end
    
    local group = xPlayer.getGroup()
    return group == 'admin' or group == 'superadmin'
end

-- ================================================================================================
-- COMMANDE : DÉFINIR LE WEBHOOK DISCORD
-- ================================================================================================
RegisterCommand('gfsetwebhook', function(source, args, rawCommand)
    -- Vérification permissions
    if not IsAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, "^1Permission refusée.")
        end
        return
    end
    
    -- Récupération de l'URL
    local webhookUrl = table.concat(args, " ")
    
    if not webhookUrl or webhookUrl == "" then
        if source == 0 then
            print("^3[GF-Admin]^0 Usage: gfsetwebhook [URL du webhook Discord]")
        else
            TriggerClientEvent('esx:showNotification', source, "^3Usage: /gfsetwebhook [URL]")
        end
        return
    end
    
    -- Configuration du webhook
    local success, message = Config.Discord.SetWebhookUrl(webhookUrl)
    
    if success then
        if source == 0 then
            print("^2[GF-Admin]^0 " .. message)
        else
            TriggerClientEvent('esx:showNotification', source, "^2✓ " .. message)
        end
        
        -- Enregistrer dans un fichier sécurisé (optionnel)
        SaveConfig()
    else
        if source == 0 then
            print("^1[GF-Admin ERROR]^0 " .. message)
        else
            TriggerClientEvent('esx:showNotification', source, "^1✗ " .. message)
        end
    end
end, false)

-- ================================================================================================
-- COMMANDE : TESTER LE WEBHOOK DISCORD
-- ================================================================================================
RegisterCommand('gftestwebhook', function(source, args, rawCommand)
    if not IsAdmin(source) then
        if source ~= 0 then
            TriggerClientEvent('esx:showNotification', source, "^1Permission refusée.")
        end
        return
    end
    
    local webhookUrl = Config.Discord.GetWebhookUrl()
    
    if not webhookUrl then
        if source == 0 then
            print("^1[GF-Admin ERROR]^0 Aucun webhook configuré")
        else
            TriggerClientEvent('esx:showNotification', source, "^1Aucun webhook configuré")
        end
        return
    end
    
    if source == 0 then
        print("^3[GF-Admin]^0 Envoi du message de test...")
    else
        TriggerClientEvent('esx:showNotification', source, "^3Envoi du message de test...")
    end
    
    -- Message de test
    local testEmbed = {
        title = "🔧 Test de Configuration",
        description = "Ce message confirme que le webhook Discord est correctement configuré.",
        color = 3066993, -- Vert
        footer = {
            text = "Gunfight Arena - Test Webhook"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
    }
    
    local payload = json.encode({
        username = Config.Discord.botName or "Gunfight Arena",
        embeds = {testEmbed}
    })
    
    PerformHttpRequest(webhookUrl, function(statusCode, responseText, headers)
        if statusCode == 204 or statusCode == 200 then
            if source == 0 then
                print("^2[GF-Admin]^0 ✓ Test réussi ! (Code HTTP: " .. statusCode .. ")")
            else
                TriggerClientEvent('esx:showNotification', source, "^2✓ Test réussi !")
            end
        else
            if source == 0 then
                print("^1[GF-Admin ERROR]^0 ✗ Test échoué (Code HTTP: " .. statusCode .. ")")
                print("^1[GF-Admin ERROR]^0 Réponse: " .. tostring(responseText))
            else
                TriggerClientEvent('esx:showNotification', source, "^1✗ Test échoué (Code: " .. statusCode .. ")")
            end
        end
    end, 'POST', payload, {
        ['Content-Type'] = 'application/json'
    })
end, false)

-- ================================================================================================
-- FONCTION : SAUVEGARDER LA CONFIGURATION (Optionnel - avancé)
-- ================================================================================================
function SaveConfig()
    -- Cette fonction peut être étendue pour sauvegarder
    -- la configuration dans un fichier externe sécurisé
    -- ou une base de données
    
    -- Pour l'instant, on logue simplement
    print("^3[GF-Admin]^0 Configuration sauvegardée (en mémoire)")
end

-- ================================================================================================
-- INITIALISATION
-- ================================================================================================
Citizen.CreateThread(function()
    Citizen.Wait(2000)
    
    print("^2╔═══════════════════════════════════════════════╗^0")
    print("^2║      Gunfight Arena - Sécurité Activée      ║^0")
    print("^2╚═══════════════════════════════════════════════╝^0")
    print("")
    print("^3[GF-Security]^0 Commandes disponibles:")
    print("^3[GF-Security]^0 • /gfsetwebhook [URL] - Configurer le webhook")
    print("^3[GF-Security]^0 • /gftestwebhook - Tester le webhook")
    print("")
    
    -- Vérifier si un webhook est configuré
    local webhook = Config.Discord.GetWebhookUrl()
    if webhook then
        print("^2[GF-Security]^0 ✓ Webhook Discord configuré")
    else
        print("^1[GF-Security]^0 ⚠️  Aucun webhook configuré")
        print("^3[GF-Security]^0 Utilisez /gfsetwebhook pour configurer")
    end
    print("")
end)
