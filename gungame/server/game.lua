--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        SERVER - GAME.LUA                                   ║
    ║                    Gestion avancée de la partie                            ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

-- ═══════════════════════════════════════════════════════════════════════════
-- STATISTIQUES DE PARTIE
-- ═══════════════════════════════════════════════════════════════════════════
local GameStats = {
    startTime = os.time(),
    totalKills = 0
}

function GetGameDuration()
    return os.time() - GameStats.startTime
end

-- ═══════════════════════════════════════════════════════════════════════════
-- VALIDATION ANTI-CHEAT BASIQUE
-- ═══════════════════════════════════════════════════════════════════════════
function ValidateKill(killerSource, victimSource, weaponHash)
    if not GunGame.players[killerSource] or not GunGame.players[victimSource] then
        return false
    end
    
    if killerSource == victimSource then
        return false
    end
    
    return true
end

-- ═══════════════════════════════════════════════════════════════════════════
-- HOOKS
-- ═══════════════════════════════════════════════════════════════════════════
function OnPlayerKill(killer, victim)
    GameStats.totalKills = GameStats.totalKills + 1
    Config.Log('debug', '%s a éliminé %s', killer.name, victim.name)
end

function OnWeaponChange(player, newWeaponIndex)
    local weaponData = Config.GetWeapon(newWeaponIndex)
    Config.Log('debug', '%s passe à %s (%d/40)', player.name, weaponData and weaponData.label or 'Unknown', newWeaponIndex)
end

-- ═══════════════════════════════════════════════════════════════════════════
-- EXPORTS
-- ═══════════════════════════════════════════════════════════════════════════
exports('getGameStats', function() return GameStats end)
exports('getGameDuration', GetGameDuration)
exports('validateKill', ValidateKill)
