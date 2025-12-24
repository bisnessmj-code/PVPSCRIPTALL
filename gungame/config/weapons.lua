--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                        CONFIGURATION DES ARMES                             ║
    ║           40 armes équilibrées - Du pistolet au couteau final              ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

Config.Weapons = {
    -- PISTOLETS (1-10)
    [1]  = { name = "WEAPON_SNSPISTOL",         label = "SNS Pistol",         category = "pistol" },
    [2]  = { name = "WEAPON_DOUBLEACTION",     label = "Pistol Double",     category = "pistol" },
    [3]  = { name = "WEAPON_VINTAGEPISTOL",     label = "Vintage Pistol",     category = "pistol" },
    [4]  = { name = "WEAPON_PISTOL",            label = "Pistol",             category = "pistol" },
    [5]  = { name = "WEAPON_PISTOL_MK2",        label = "Pistol MK2",         category = "pistol" },
    [6]  = { name = "WEAPON_COMBATPISTOL",      label = "Combat Pistol",      category = "pistol" },
    [7]  = { name = "WEAPON_APPISTOL",          label = "AP Pistol",          category = "pistol" },
    [8]  = { name = "WEAPON_HEAVYPISTOL",       label = "Heavy Pistol",       category = "pistol" },
    [9]  = { name = "WEAPON_REVOLVER",          label = "Revolver",           category = "pistol" },
    [10] = { name = "WEAPON_PISTOL50",          label = "Pistol .50",         category = "pistol" },
    
    -- SMG / MITRAILLETTES (11-18)
    [11] = { name = "WEAPON_MICROSMG",          label = "Micro SMG",          category = "smg" },
    [12] = { name = "WEAPON_MINISMG",           label = "Mini SMG",           category = "smg" },
    [13] = { name = "WEAPON_MACHINEPISTOL",     label = "Machine Pistol",     category = "smg" },
    [14] = { name = "WEAPON_SMG",               label = "SMG",                category = "smg" },
    [15] = { name = "WEAPON_SMG_MK2",           label = "SMG MK2",            category = "smg" },
    [16] = { name = "WEAPON_MILITARYRIFLE",        label = "Machine Pistol",        category = "rifle" },
    [17] = { name = "WEAPON_COMBATPDW",         label = "Combat PDW",         category = "smg" },
    [18] = { name = "WEAPON_GUSENBERG",         label = "Gusenberg Sweeper",  category = "smg" },
    
    -- FUSILS D'ASSAUT (19-28)
    [19] = { name = "WEAPON_TACTICALRIFLE",      label = "Compact Rifle",      category = "rifle" },
    [20] = { name = "WEAPON_ASSAULTRIFLE",      label = "Assault Rifle",      category = "rifle" },
    [21] = { name = "WEAPON_ASSAULTRIFLE_MK2",  label = "Assault Rifle MK2",  category = "rifle" },
    [22] = { name = "WEAPON_CARBINERIFLE",      label = "Carbine Rifle",      category = "rifle" },
    [23] = { name = "WEAPON_CARBINERIFLE_MK2",  label = "Carbine Rifle MK2",  category = "rifle" },
    [24] = { name = "WEAPON_ADVANCEDRIFLE",     label = "Advanced Rifle",     category = "rifle" },
    [25] = { name = "WEAPON_SPECIALCARBINE",    label = "Special Carbine",    category = "rifle" },
    [26] = { name = "WEAPON_SPECIALCARBINE_MK2",label = "Special Carbine MK2",category = "rifle" },
    [27] = { name = "WEAPON_BULLPUPRIFLE",      label = "Bullpup Rifle",      category = "rifle" },
    [28] = { name = "WEAPON_BULLPUPRIFLE_MK2",  label = "Bullpup Rifle MK2",  category = "rifle" },
    
    -- FUSILS À POMPE (29-34)
    [29] = { name = "WEAPON_SAWNOFFSHOTGUN",    label = "Sawed-Off Shotgun",  category = "shotgun" },
    [30] = { name = "WEAPON_PUMPSHOTGUN",       label = "Pump Shotgun",       category = "shotgun" },
    [31] = { name = "WEAPON_PUMPSHOTGUN_MK2",   label = "Pump Shotgun MK2",   category = "shotgun" },
    [32] = { name = "WEAPON_ASSAULTSHOTGUN",    label = "Assault Shotgun",    category = "shotgun" },
    [33] = { name = "WEAPON_COMBATSHOTGUN",     label = "Combat Shotgun",     category = "shotgun" },
    [34] = { name = "WEAPON_HEAVYSHOTGUN",      label = "Heavy Shotgun",      category = "shotgun" },
    
    -- SNIPERS (35-38)
    [35] = { name = "WEAPON_MARKSMANRIFLE",     label = "Marksman Rifle",     category = "sniper" },
    [36] = { name = "WEAPON_MARKSMANRIFLE_MK2", label = "Marksman Rifle MK2", category = "sniper" },
    [37] = { name = "WEAPON_SNIPERRIFLE",       label = "Sniper Rifle",       category = "sniper" },
    [38] = { name = "WEAPON_HEAVYSNIPER_MK2",   label = "Heavy Sniper MK2",   category = "sniper" },
    
    -- SPÉCIAL & FINAL (39-40)
    [39] = { name = "WEAPON_COMPACTRIFLE",               label = "Compact Rifle",                category = "rifle" },
    [40] = { name = "WEAPON_ASSAULTSMG",             label = "Gusenberg Sweeper",            category = "smg" }
}

function Config.GetWeapon(index)
    return Config.Weapons[index]
end

function Config.GetWeaponHash(index)
    local weapon = Config.Weapons[index]
    if weapon then
        return GetHashKey(weapon.name)
    end
    return 0
end

function Config.GetTotalWeapons()
    return #Config.Weapons
end
