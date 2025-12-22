-- ================================================================================================
-- GUNFIGHT ARENA - CONFIGURATION DISCORD SÉCURISÉE v3.0
-- ================================================================================================
-- ✅ Webhook chiffré avec le module de sécurité
-- ✅ Protection contre l'accès non autorisé
-- ================================================================================================

-- Le module SecurityModule est chargé via _G depuis security_module.lua
local SecurityModule = _G.SecurityModule

-- Vérification que le module est chargé
if not SecurityModule then
    print("^1[GF-Security ERROR]^0 Module de sécurité non chargé !")
    print("^1[GF-Security ERROR]^0 Vérifie que security_module.lua est bien avant config_discord_secure.lua dans fxmanifest.lua")
end

-- ================================================================================================
-- CONFIGURATION DISCORD
-- ================================================================================================
Config.Discord = {
    enabled = true,
    
    webhookUrlEncrypted = "",
    
    -- Configuration publique (non sensible)
    autoSend = true,
    updateInterval = 43200, -- 12 heures
    sendOnStartup = false,
    displayStyle = "MODERN",
    showGlobalStats = true,
    showPodium = true,
    showFooterInfo = true,
    leaderboardLimit = 10,
    
    -- Personnalisation visuelle
    botName = "BOT FIGHT LEAGUE",
    botAvatar = "https://i.imgur.com/Oq5gxWS.png",
    embedTitle = "CLASSEMENT GUNFIGHT LEAGUE",
    embedDescription = "**Les 15 meilleurs joueurs de la ligue**\n" ..
                       "Voici le classement du serveur\n" ..
                       "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    embedColor = 65535,
    thumbnailUrl = "https://i.imgur.com/Oq5gxWS.png",
    bannerUrl = "https://i.imgur.com/Oq5gxWS.png",
    footerIcon = "https://i.imgur.com/Oq5gxWS.png",
    
    mentionEveryone = false,
    mentionRole = "",
    
    manualCommand = "sendleaderboard",
}

-- ================================================================================================
-- FONCTION : OBTENIR LE WEBHOOK DÉCHIFFRÉ (Côté serveur uniquement)
-- ================================================================================================
function Config.Discord.GetWebhookUrl()
    if not SecurityModule then
        print("^1[GF-Security ERROR]^0 Module de sécurité non disponible")
        return nil
    end
    
    if not Config.Discord.webhookUrlEncrypted or 
       Config.Discord.webhookUrlEncrypted == "" or 
       Config.Discord.webhookUrlEncrypted == "SERA_GENERE_PAR_LA_COMMANDE_SETWEBHOOK" then
        return nil
    end
    
    local decrypted = SecurityModule.Decrypt(Config.Discord.webhookUrlEncrypted)
    
    -- Validation du format
    if not SecurityModule.ValidateDiscordWebhook(decrypted) then
        print("^1[GF-Security ERROR]^0 Webhook invalide après déchiffrement")
        return nil
    end
    
    return decrypted
end

-- ================================================================================================
-- FONCTION : DÉFINIR UN NOUVEAU WEBHOOK (Commande admin)
-- ================================================================================================
function Config.Discord.SetWebhookUrl(plainWebhook)
    if not SecurityModule then
        return false, "Module de sécurité non disponible"
    end
    
    if not plainWebhook or plainWebhook == "" then
        return false, "URL vide"
    end
    
    -- Validation du format
    if not SecurityModule.ValidateDiscordWebhook(plainWebhook) then
        return false, "Format de webhook Discord invalide"
    end
    
    -- Chiffrement
    local encrypted = SecurityModule.Encrypt(plainWebhook)
    Config.Discord.webhookUrlEncrypted = encrypted
    
    print("^2[GF-Security]^0 Webhook Discord configuré avec succès")
    print("^3[GF-Security]^0 URL masquée: " .. SecurityModule.MaskUrl(plainWebhook))
    
    return true, "Webhook configuré"
end

-- ================================================================================================
-- EXPORTS POUR LES AUTRES SCRIPTS
-- ================================================================================================
exports('GetDiscordWebhook', Config.Discord.GetWebhookUrl)
exports('SetDiscordWebhook', Config.Discord.SetWebhookUrl)
