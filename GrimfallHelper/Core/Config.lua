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
    version = "1.1.0",
    showMinimap = true,
    minimapPos = 45,
    soundAlerts = true,
    windowPoint = "CENTER",
    windowRelPoint = "CENTER",
    windowX = 0,
    windowY = 20,
    selectedTab = 1,
    enhanceTooltips = true,
    showZoneLevels = true,
}

-- Character Specific Default Configuration
Config.DefaultChar = {}

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
            -- Only recurse into key-value tables, preserve plain arrays
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
