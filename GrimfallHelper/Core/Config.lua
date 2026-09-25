-- ============================================================================
-- GrimfallHelper: Core/Config.lua
-- Configuration Manager, Defaults, and SavedVariables Persistence
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Config = {}
local Config = GH.Config
local C = GH.Constants

-- Global Default Configuration (Account-Wide)
Config.DefaultGlobal = {
    version = "1.0.0",
    showMinimap = true,
    minimapPos = 45,
    autoVendor = true,
    autoRepair = true,
    autoRepairGuild = true,
    soundAlerts = true,
    wishlistAlertBanner = true,
    lootFanfare = true,
    showBuffSentinel = true,
    showHUD = true,
    hudLocked = false,
    hudScale = 1.0,
    hudPoint = "CENTER",
    hudRelPoint = "CENTER",
    hudX = 0,
    hudY = -140,
    windowPoint = "CENTER",
    windowRelPoint = "CENTER",
    windowX = 0,
    windowY = 20,
    selectedTab = 1,
    enhanceTooltips = true,
    autoQuest = false,
    showZoneLevels = true,
    nameplateDebuffs = true,
}

-- Character Specific Default Configuration
Config.DefaultChar = {
    wishlist = {
        ["S"] = {},
        ["A"] = {},
        ["B"] = {},
    },
    rerollHistory = {},
    actionBarProfiles = {},
    xpTracker = {
        startTime = 0,
        startXP = 0,
        currentXP = 0,
        maxXP = 0,
        xpGained = 0,
        kills = 0,
        quests = 0,
        scrollsFarmed = 0,
    },
}

local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

local function MergeTables(target, source)
    if type(target) ~= "table" or type(source) ~= "table" then
        return target
    end
    for k, v in pairs(source) do
        if target[k] == nil then
            target[k] = DeepCopy(v)
        elseif type(target[k]) == "table" and type(v) == "table" then
            -- Do not merge arrays like wishlist or rerollHistory, only key-value settings
            if #v == 0 then
                MergeTables(target[k], v)
            end
        end
    end
    return target
end

-- Initialize SavedVariables
function Config:Initialize()
    if not GrimfallHelperDB then
        GrimfallHelperDB = DeepCopy(Config.DefaultGlobal)
    else
        MergeTables(GrimfallHelperDB, Config.DefaultGlobal)
    end

    if not GrimfallHelperCharDB then
        GrimfallHelperCharDB = DeepCopy(Config.DefaultChar)
        -- Seed initial wishlist with meta choices on first ever load
        for tier, list in pairs(C.DEFAULT_WISHLIST_SEEDS) do
            for _, spell in ipairs(list) do
                table.insert(GrimfallHelperCharDB.wishlist[tier], spell)
            end
        end
    else
        MergeTables(GrimfallHelperCharDB, Config.DefaultChar)
    end

    self.db = GrimfallHelperDB
    self.charDB = GrimfallHelperCharDB
end

-- Getters & Setters
function Config:Get(key, defaultVal)
    if self.db and self.db[key] ~= nil then
        return self.db[key]
    end
    return defaultVal
end

function Config:Set(key, val)
    if not self.db then self.db = GrimfallHelperDB end
    self.db[key] = val
end

function Config:GetChar(key, defaultVal)
    if self.charDB and self.charDB[key] ~= nil then
        return self.charDB[key]
    end
    return defaultVal
end

function Config:SetChar(key, val)
    if not self.charDB then self.charDB = GrimfallHelperCharDB end
    self.charDB[key] = val
end

function Config:ResetToDefaults()
    GrimfallHelperDB = DeepCopy(Config.DefaultGlobal)
    self.db = GrimfallHelperDB
    GH.Utils:Print("Global settings have been reset to default values.")
end
