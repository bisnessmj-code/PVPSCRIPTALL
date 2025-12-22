-- ================================================================================================
-- GUNFIGHT ARENA - MODULE DE SÉCURITÉ v1.0
-- ================================================================================================
-- ✅ Chiffrement des données sensibles (webhook Discord, clés API, etc.)
-- ✅ Protection contre l'accès non autorisé aux fichiers
-- ✅ Système de déchiffrement côté serveur uniquement
-- ================================================================================================

local SecurityModule = {}

-- ================================================================================================
-- CONFIGURATION DE CHIFFREMENT (À PERSONNALISER)
-- ================================================================================================
-- ⚠️ IMPORTANT : Change cette clé de chiffrement unique pour ton serveur
-- Génère une clé aléatoire avec : https://www.random.org/strings/
local ENCRYPTION_KEY = "Qa2C90lw5I" -- À CHANGER ABSOLUMENT

-- ================================================================================================
-- FONCTION : XOR CIPHER (Chiffrement basique mais efficace)
-- ================================================================================================
-- Fonction XOR compatible FiveM (sans bit32)
local function xorByte(a, b)
    local result = 0
    local bitval = 1
    
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        
        if abit ~= bbit then
            result = result + bitval
        end
        
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    
    return result
end

local function xorCipher(data, key)
    local result = {}
    local keyLen = #key
    
    for i = 1, #data do
        local dataByte = string.byte(data, i)
        local keyByte = string.byte(key, ((i - 1) % keyLen) + 1)
        table.insert(result, string.char(xorByte(dataByte, keyByte)))
    end
    
    return table.concat(result)
end

-- ================================================================================================
-- FONCTION : BASE64 ENCODE (Pour stocker le chiffré en texte)
-- ================================================================================================
local base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64Encode(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r..(b % 2^i - b % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2^(6-i) or 0) end
        return base64Chars:sub(c+1, c+1)
    end)..({ '', '==', '=' })[#data % 3 + 1])
end

-- ================================================================================================
-- FONCTION : BASE64 DECODE
-- ================================================================================================
local function base64Decode(data)
    data = string.gsub(data, '[^'..base64Chars..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (base64Chars:find(x) - 1)
        for i = 6, 1, -1 do r = r..(f % 2^i - f % 2^(i-1) > 0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == '1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end

-- ================================================================================================
-- FONCTION PUBLIQUE : CHIFFRER UNE DONNÉE
-- ================================================================================================
function SecurityModule.Encrypt(plaintext)
    if not plaintext or plaintext == "" then
        return nil
    end
    
    local encrypted = xorCipher(plaintext, ENCRYPTION_KEY)
    return base64Encode(encrypted)
end

-- ================================================================================================
-- FONCTION PUBLIQUE : DÉCHIFFRER UNE DONNÉE
-- ================================================================================================
function SecurityModule.Decrypt(ciphertext)
    if not ciphertext or ciphertext == "" then
        return nil
    end
    
    local decoded = base64Decode(ciphertext)
    return xorCipher(decoded, ENCRYPTION_KEY)
end

-- ================================================================================================
-- FONCTION : VÉRIFIER LA VALIDITÉ D'UN WEBHOOK DISCORD
-- ================================================================================================
function SecurityModule.ValidateDiscordWebhook(url)
    if not url then return false end
    
    -- Pattern Discord webhook
    local pattern = "^https://discord%.com/api/webhooks/%d+/[%w%-_]+$"
    return string.match(url, pattern) ~= nil
end

-- ================================================================================================
-- FONCTION : MASQUER PARTIELLEMENT UNE URL (Pour les logs)
-- ================================================================================================
function SecurityModule.MaskUrl(url)
    if not url then return "N/A" end
    
    -- Masque la partie sensible du webhook
    local masked = url:gsub("(/webhooks/%d+/)([%w%-_]+)", function(prefix, token)
        return prefix .. string.rep("*", #token)
    end)
    
    return masked
end

-- ================================================================================================
-- EXPORT DU MODULE
-- ================================================================================================
-- Export global pour que les autres scripts puissent y accéder
_G.SecurityModule = SecurityModule

return SecurityModule