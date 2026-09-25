-- ============================================================================
-- GrimfallHelper: Modules/ZoneLevels.lua
-- World Map Recommended Zone Levels, Dungeon Brackets, and Leveling Advisor
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.ZoneLevels = {}
local ZL = GH.ZoneLevels
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Comprehensive WotLK 3.3.5a Zone and Dungeon Database
ZL.ZONE_DATA = {
    -- ========================================================================
    -- EASTERN KINGDOMS
    -- ========================================================================
    ["alterac mountains"] = {
        name = "Alterac Mountains", min = 30, max = 40, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["arathi highlands"] = {
        name = "Arathi Highlands", min = 30, max = 40, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["badlands"] = {
        name = "Badlands", min = 35, max = 45, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Uldaman", min = 41, max = 51 } },
    },
    ["blasted lands"] = {
        name = "Blasted Lands", min = 47, max = 55, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["burning steppes"] = {
        name = "Burning Steppes", min = 50, max = 59, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = {
            { name = "Blackrock Spire (LBRS)", min = 55, max = 60 },
            { name = "Blackrock Spire (UBRS)", min = 58, max = 60 },
            { name = "Blackwing Lair", min = 60, max = 60, raid = true },
        },
    },
    ["deadwind pass"] = {
        name = "Deadwind Pass", min = 55, max = 60, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Karazhan", min = 70, max = 70, raid = true } },
    },
    ["dun morogh"] = {
        name = "Dun Morogh", min = 1, max = 10, territory = "Alliance", continent = "Eastern Kingdoms",
        dungeons = { { name = "Gnomeregan", min = 29, max = 38 } },
    },
    ["duskwood"] = {
        name = "Duskwood", min = 18, max = 30, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["eastern plaguelands"] = {
        name = "Eastern Plaguelands", min = 54, max = 59, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Stratholme", min = 58, max = 67 } },
    },
    ["elwynn forest"] = {
        name = "Elwynn Forest", min = 1, max = 10, territory = "Alliance", continent = "Eastern Kingdoms",
    },
    ["eversong woods"] = {
        name = "Eversong Woods", min = 1, max = 10, territory = "Horde", continent = "Eastern Kingdoms",
    },
    ["ghostlands"] = {
        name = "Ghostlands", min = 10, max = 20, territory = "Horde", continent = "Eastern Kingdoms",
        dungeons = { { name = "Zul'Aman", min = 70, max = 70, raid = true } },
    },
    ["hillsbrad foothills"] = {
        name = "Hillsbrad Foothills", min = 20, max = 30, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["ironforge"] = {
        name = "Ironforge", min = 1, max = 80, territory = "Alliance", continent = "Eastern Kingdoms", isCity = true,
    },
    ["isle of quel'danas"] = {
        name = "Isle of Quel'Danas", min = 70, max = 70, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = {
            { name = "Magisters' Terrace", min = 70, max = 70 },
            { name = "Sunwell Plateau", min = 70, max = 70, raid = true },
        },
    },
    ["loch modan"] = {
        name = "Loch Modan", min = 10, max = 20, territory = "Alliance", continent = "Eastern Kingdoms",
    },
    ["redridge mountains"] = {
        name = "Redridge Mountains", min = 15, max = 25, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["searing gorge"] = {
        name = "Searing Gorge", min = 43, max = 50, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = {
            { name = "Blackrock Depths", min = 52, max = 60 },
            { name = "Molten Core", min = 60, max = 60, raid = true },
        },
    },
    ["silverpine forest"] = {
        name = "Silverpine Forest", min = 10, max = 20, territory = "Horde", continent = "Eastern Kingdoms",
        dungeons = { { name = "Shadowfang Keep", min = 22, max = 30 } },
    },
    ["stormwind city"] = {
        name = "Stormwind City", min = 1, max = 80, territory = "Alliance", continent = "Eastern Kingdoms", isCity = true,
        dungeons = { { name = "The Stockade", min = 24, max = 32 } },
    },
    ["stranglethorn vale"] = {
        name = "Stranglethorn Vale", min = 30, max = 45, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Zul'Gurub", min = 60, max = 60, raid = true } },
    },
    ["swamp of sorrows"] = {
        name = "Swamp of Sorrows", min = 35, max = 45, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Sunken Temple", min = 50, max = 60 } },
    },
    ["the hinterlands"] = {
        name = "The Hinterlands", min = 40, max = 50, territory = "Contested", continent = "Eastern Kingdoms",
    },
    ["tirisfal glades"] = {
        name = "Tirisfal Glades", min = 1, max = 10, territory = "Horde", continent = "Eastern Kingdoms",
        dungeons = { { name = "Scarlet Monastery", min = 32, max = 45 } },
    },
    ["undercity"] = {
        name = "Undercity", min = 1, max = 80, territory = "Horde", continent = "Eastern Kingdoms", isCity = true,
    },
    ["western plaguelands"] = {
        name = "Western Plaguelands", min = 51, max = 58, territory = "Contested", continent = "Eastern Kingdoms",
        dungeons = { { name = "Scholomance", min = 58, max = 60 } },
    },
    ["westfall"] = {
        name = "Westfall", min = 10, max = 20, territory = "Alliance", continent = "Eastern Kingdoms",
        dungeons = { { name = "The Deadmines", min = 18, max = 23 } },
    },
    ["wetlands"] = {
        name = "Wetlands", min = 20, max = 30, territory = "Contested", continent = "Eastern Kingdoms",
    },

    -- ========================================================================
    -- KALIMDOR
    -- ========================================================================
    ["ashenvale"] = {
        name = "Ashenvale", min = 18, max = 30, territory = "Contested", continent = "Kalimdor",
        dungeons = { { name = "Blackfathom Deeps", min = 24, max = 32 } },
    },
    ["azshara"] = {
        name = "Azshara", min = 45, max = 55, territory = "Contested", continent = "Kalimdor",
    },
    ["azuremyst isle"] = {
        name = "Azuremyst Isle", min = 1, max = 10, territory = "Alliance", continent = "Kalimdor",
    },
    ["bloodmyst isle"] = {
        name = "Bloodmyst Isle", min = 10, max = 20, territory = "Alliance", continent = "Kalimdor",
    },
    ["darkshore"] = {
        name = "Darkshore", min = 10, max = 20, territory = "Alliance", continent = "Kalimdor",
    },
    ["darnassus"] = {
        name = "Darnassus", min = 1, max = 80, territory = "Alliance", continent = "Kalimdor", isCity = true,
    },
    ["desolace"] = {
        name = "Desolace", min = 30, max = 40, territory = "Contested", continent = "Kalimdor",
        dungeons = { { name = "Maraudon", min = 46, max = 55 } },
    },
    ["durotar"] = {
        name = "Durotar", min = 1, max = 10, territory = "Horde", continent = "Kalimdor",
    },
    ["dustwallow marsh"] = {
        name = "Dustwallow Marsh", min = 35, max = 45, territory = "Contested", continent = "Kalimdor",
        dungeons = { { name = "Onyxia's Lair", min = 80, max = 80, raid = true } },
    },
    ["felwood"] = {
        name = "Felwood", min = 48, max = 55, territory = "Contested", continent = "Kalimdor",
    },
    ["feralas"] = {
        name = "Feralas", min = 40, max = 50, territory = "Contested", continent = "Kalimdor",
        dungeons = { { name = "Dire Maul", min = 55, max = 60 } },
    },
    ["moonglade"] = {
        name = "Moonglade", min = 1, max = 80, territory = "Sanctuary", continent = "Kalimdor",
    },
    ["mulgore"] = {
        name = "Mulgore", min = 1, max = 10, territory = "Horde", continent = "Kalimdor",
    },
    ["orgrimmar"] = {
        name = "Orgrimmar", min = 1, max = 80, territory = "Horde", continent = "Kalimdor", isCity = true,
        dungeons = { { name = "Ragefire Chasm", min = 15, max = 21 } },
    },
    ["silithus"] = {
        name = "Silithus", min = 55, max = 60, territory = "Contested", continent = "Kalimdor",
        dungeons = {
            { name = "Ruins of Ahn'Qiraj (AQ20)", min = 60, max = 60, raid = true },
            { name = "Temple of Ahn'Qiraj (AQ40)", min = 60, max = 60, raid = true },
        },
    },
    ["stonetalon mountains"] = {
        name = "Stonetalon Mountains", min = 15, max = 25, territory = "Contested", continent = "Kalimdor",
    },
    ["tanaris"] = {
        name = "Tanaris", min = 40, max = 50, territory = "Contested", continent = "Kalimdor",
        dungeons = {
            { name = "Zul'Farrak", min = 44, max = 54 },
            { name = "Old Hillsbrad Foothills", min = 66, max = 68 },
            { name = "The Black Morass", min = 69, max = 70 },
            { name = "The Culling of Stratholme", min = 80, max = 80 },
            { name = "Battle for Mount Hyjal", min = 70, max = 70, raid = true },
        },
    },
    ["teldrassil"] = {
        name = "Teldrassil", min = 1, max = 10, territory = "Alliance", continent = "Kalimdor",
    },
    ["the barrens"] = {
        name = "The Barrens", min = 10, max = 25, territory = "Horde", continent = "Kalimdor",
        dungeons = {
            { name = "Wailing Caverns", min = 17, max = 24 },
            { name = "Razorfen Kraul", min = 30, max = 40 },
            { name = "Razorfen Downs", min = 40, max = 50 },
        },
    },
    ["barrens"] = {
        name = "The Barrens", min = 10, max = 25, territory = "Horde", continent = "Kalimdor",
        dungeons = {
            { name = "Wailing Caverns", min = 17, max = 24 },
            { name = "Razorfen Kraul", min = 30, max = 40 },
            { name = "Razorfen Downs", min = 40, max = 50 },
        },
    },
    ["the exodar"] = {
        name = "The Exodar", min = 1, max = 80, territory = "Alliance", continent = "Kalimdor", isCity = true,
    },
    ["exodar"] = {
        name = "The Exodar", min = 1, max = 80, territory = "Alliance", continent = "Kalimdor", isCity = true,
    },
    ["thousand needles"] = {
        name = "Thousand Needles", min = 25, max = 35, territory = "Contested", continent = "Kalimdor",
    },
    ["thunder bluff"] = {
        name = "Thunder Bluff", min = 1, max = 80, territory = "Horde", continent = "Kalimdor", isCity = true,
    },
    ["un'goro crater"] = {
        name = "Un'Goro Crater", min = 48, max = 55, territory = "Contested", continent = "Kalimdor",
    },
    ["winterspring"] = {
        name = "Winterspring", min = 53, max = 60, territory = "Contested", continent = "Kalimdor",
    },

    -- ========================================================================
    -- OUTLAND
    -- ========================================================================
    ["hellfire peninsula"] = {
        name = "Hellfire Peninsula", min = 58, max = 63, territory = "Contested", continent = "Outland",
        dungeons = {
            { name = "Hellfire Ramparts", min = 60, max = 62 },
            { name = "The Blood Furnace", min = 61, max = 63 },
            { name = "The Shattered Halls", min = 70, max = 72 },
            { name = "Magtheridon's Lair", min = 70, max = 70, raid = true },
        },
    },
    ["zangarmarsh"] = {
        name = "Zangarmarsh", min = 60, max = 64, territory = "Contested", continent = "Outland",
        dungeons = {
            { name = "The Slave Pens", min = 62, max = 64 },
            { name = "The Underbog", min = 63, max = 65 },
            { name = "The Steamvault", min = 70, max = 72 },
            { name = "Serpentshrine Cavern", min = 70, max = 70, raid = true },
        },
    },
    ["terokkar forest"] = {
        name = "Terokkar Forest", min = 62, max = 65, territory = "Contested", continent = "Outland",
        dungeons = {
            { name = "Mana-Tombs", min = 64, max = 66 },
            { name = "Auchenai Crypts", min = 65, max = 67 },
            { name = "Sethekk Halls", min = 67, max = 69 },
            { name = "Shadow Labyrinth", min = 70, max = 72 },
        },
    },
    ["nagrand"] = {
        name = "Nagrand", min = 64, max = 67, territory = "Contested", continent = "Outland",
    },
    ["blade's edge mountains"] = {
        name = "Blade's Edge Mountains", min = 65, max = 68, territory = "Contested", continent = "Outland",
        dungeons = { { name = "Gruul's Lair", min = 70, max = 70, raid = true } },
    },
    ["netherstorm"] = {
        name = "Netherstorm", min = 67, max = 70, territory = "Contested", continent = "Outland",
        dungeons = {
            { name = "The Botanica", min = 70, max = 72 },
            { name = "The Mechanar", min = 70, max = 72 },
            { name = "The Arcatraz", min = 70, max = 72 },
            { name = "The Eye (Tempest Keep)", min = 70, max = 70, raid = true },
        },
    },
    ["shadowmoon valley"] = {
        name = "Shadowmoon Valley", min = 67, max = 70, territory = "Contested", continent = "Outland",
        dungeons = { { name = "Black Temple", min = 70, max = 70, raid = true } },
    },
    ["shattrath city"] = {
        name = "Shattrath City", min = 60, max = 80, territory = "Sanctuary", continent = "Outland", isCity = true,
    },

    -- ========================================================================
    -- NORTHREND
    -- ========================================================================
    ["borean tundra"] = {
        name = "Borean Tundra", min = 68, max = 72, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "The Nexus", min = 71, max = 73 },
            { name = "The Oculus", min = 79, max = 80 },
            { name = "The Eye of Eternity", min = 80, max = 80, raid = true },
        },
    },
    ["howling fjord"] = {
        name = "Howling Fjord", min = 68, max = 72, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "Utgarde Keep", min = 71, max = 73 },
            { name = "Utgarde Pinnacle", min = 79, max = 80 },
        },
    },
    ["dragonblight"] = {
        name = "Dragonblight", min = 71, max = 74, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "Azjol-Nerub", min = 72, max = 74 },
            { name = "Ahn'kahet: The Old Kingdom", min = 73, max = 75 },
            { name = "Naxxramas", min = 80, max = 80, raid = true },
            { name = "The Obsidian Sanctum", min = 80, max = 80, raid = true },
        },
    },
    ["grizzly hills"] = {
        name = "Grizzly Hills", min = 73, max = 75, territory = "Contested", continent = "Northrend",
        dungeons = { { name = "Drak'Tharon Keep", min = 74, max = 76 } },
    },
    ["zul'drak"] = {
        name = "Zul'Drak", min = 74, max = 77, territory = "Contested", continent = "Northrend",
        dungeons = { { name = "Gundrak", min = 76, max = 78 } },
    },
    ["sholazar basin"] = {
        name = "Sholazar Basin", min = 75, max = 77, territory = "Contested", continent = "Northrend",
    },
    ["the storm peaks"] = {
        name = "The Storm Peaks", min = 77, max = 80, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "Halls of Stone", min = 77, max = 79 },
            { name = "Halls of Lightning", min = 80, max = 80 },
            { name = "Ulduar", min = 80, max = 80, raid = true },
        },
    },
    ["storm peaks"] = {
        name = "The Storm Peaks", min = 77, max = 80, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "Halls of Stone", min = 77, max = 79 },
            { name = "Halls of Lightning", min = 80, max = 80 },
            { name = "Ulduar", min = 80, max = 80, raid = true },
        },
    },
    ["crystalsong forest"] = {
        name = "Crystalsong Forest", min = 77, max = 80, territory = "Contested", continent = "Northrend",
    },
    ["hrothgar's landing"] = {
        name = "Hrothgar's Landing", min = 77, max = 80, territory = "Contested", continent = "Northrend",
    },
    ["icecrown"] = {
        name = "Icecrown", min = 77, max = 80, territory = "Contested", continent = "Northrend",
        dungeons = {
            { name = "Trial of the Champion", min = 80, max = 80 },
            { name = "The Forge of Souls", min = 80, max = 80 },
            { name = "Pit of Saron", min = 80, max = 80 },
            { name = "Halls of Reflection", min = 80, max = 80 },
            { name = "Trial of the Crusader", min = 80, max = 80, raid = true },
            { name = "Icecrown Citadel", min = 80, max = 80, raid = true },
        },
    },
    ["dalaran"] = {
        name = "Dalaran", min = 74, max = 80, territory = "Sanctuary", continent = "Northrend", isCity = true,
        dungeons = { { name = "Violet Hold", min = 75, max = 77 } },
    },
    ["wintergrasp"] = {
        name = "Wintergrasp", min = 80, max = 80, territory = "PvP", continent = "Northrend",
        dungeons = { { name = "Vault of Archavon", min = 80, max = 80, raid = true } },
    },
}

-- Clean and normalize zone names for reliable map lookups
function ZL:NormalizeZoneName(name)
    if not name or name == "" then return "" end
    local clean = string.lower(Utils:Trim(name))
    clean = string.gsub(clean, "%s*%b()", "")
    clean = string.gsub(clean, "%s*%b[]", "")
    clean = string.gsub(clean, "^the%s+", "")
    clean = Utils:Trim(clean)
    return clean
end

-- Find zone entry by matching raw or normalized name
function ZL:GetZoneData(name)
    if not name or name == "" then return nil end
    local clean = string.lower(Utils:Trim(name))
    clean = string.gsub(clean, "%s*%b()", "")
    clean = string.gsub(clean, "%s*%b[]", "")
    clean = Utils:Trim(clean)

    -- Direct match
    if self.ZONE_DATA[clean] then
        return self.ZONE_DATA[clean]
    end

    -- Try without "the "
    local withoutThe = string.gsub(clean, "^the%s+", "")
    if self.ZONE_DATA[withoutThe] then
        return self.ZONE_DATA[withoutThe]
    end
    if self.ZONE_DATA["the " .. withoutThe] then
        return self.ZONE_DATA["the " .. withoutThe]
    end

    -- Fuzzy search
    for key, data in pairs(self.ZONE_DATA) do
        if string.find(clean, key, 1, true) or string.find(key, clean, 1, true) then
            return data
        end
    end

    return nil
end

-- Calculate level color code relative to player level
function ZL:GetLevelColorCode(minLevel, maxLevel, playerLevel)
    playerLevel = playerLevel or UnitLevel("player") or 1
    if not minLevel or not maxLevel then
        return "|cffffffff"
    end

    -- Extreme Danger (Red)
    if playerLevel < (minLevel - 3) then
        return "|cffFF2020"
    -- Challenging (Orange)
    elseif playerLevel < minLevel then
        return "|cffFF7700"
    -- Optimal / Ideal (Bright Green)
    elseif playerLevel >= minLevel and playerLevel <= maxLevel then
        return "|cff00FF66"
    -- Slightly Low (Light Blue/Teal)
    elseif playerLevel <= (maxLevel + 4) then
        return "|cff55CCFF"
    -- Trivial / Grey
    else
        return "|cff888888"
    end
end

-- Territory color
function ZL:GetTerritoryColorCode(territory)
    if territory == "Alliance" then
        return "|cff0070DE"
    elseif territory == "Horde" then
        return "|cffC41F3B"
    elseif territory == "Sanctuary" then
        return "|cff00FF96"
    elseif territory == "PvP" then
        return "|cffFF3333"
    else
        return "|cffFFD700" -- Contested (Gold)
    end
end

-- Format continent mouseover text: "Zone Name (Min - Max)"
function ZL:GetFormattedZoneText(zoneName)
    if not zoneName or zoneName == "" then return nil end
    local data = self:GetZoneData(zoneName)
    if not data or data.isCity then return nil end

    local color = self:GetLevelColorCode(data.min, data.max)
    local rangeStr = (data.min == data.max) and tostring(data.min) or (data.min .. "-" .. data.max)
    return zoneName .. " " .. color .. "(" .. rangeStr .. ")|r"
end

-- ============================================================================
-- WORLD MAP UI INTEGRATION
-- ============================================================================
local mapBadge = nil
local inAreaHook = false

function ZL:CreateMapBadge()
    if mapBadge or not WorldMapFrame then return end

    -- Floating / Docked Zone Info Badge on WorldMapFrame
    mapBadge = CreateFrame("Button", "GrimfallZoneLevelBadge", WorldMapFrame)
    mapBadge:SetSize(280, 22)
    mapBadge:SetPoint("TOPRIGHT", WorldMapFrame, "TOPRIGHT", -40, -38)
    mapBadge:SetFrameLevel(WorldMapFrame:GetFrameLevel() + 10)

    -- Background styling
    mapBadge:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    mapBadge:SetBackdropColor(0.08, 0.10, 0.14, 0.90)
    mapBadge:SetBackdropBorderColor(0.25, 0.30, 0.40, 1.0)

    mapBadge.text = mapBadge:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    mapBadge.text:SetPoint("CENTER", mapBadge, "CENTER", 0, 0)
    mapBadge.text:SetText("|cff00FF96Zone Levels Active|r")

    -- Tooltip on badge hover
    mapBadge:SetScript("OnEnter", function(self)
        local curZoneName = ZL:GetCurrentMapZoneName()
        local data = ZL:GetZoneData(curZoneName)

        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        if data then
            local pLvl = UnitLevel("player") or 1
            local color = ZL:GetLevelColorCode(data.min, data.max, pLvl)
            local rangeStr = (data.min == data.max) and tostring(data.min) or (data.min .. " - " .. data.max)
            local terrColor = ZL:GetTerritoryColorCode(data.territory)

            GameTooltip:AddLine("|cff00FF96Grimfall Map Advisor|r", 1, 1, 1)
            GameTooltip:AddLine(data.name, 1, 0.82, 0)
            GameTooltip:AddDoubleLine("Recommended Level:", color .. rangeStr .. "|r", 0.8, 0.8, 0.8)
            GameTooltip:AddDoubleLine("Your Level:", "|cffffffff" .. pLvl .. "|r", 0.8, 0.8, 0.8)
            GameTooltip:AddDoubleLine("Territory:", terrColor .. data.territory .. "|r", 0.8, 0.8, 0.8)

            -- Level match verdict
            if pLvl < (data.min - 3) then
                GameTooltip:AddLine("|cffFF2020⚠ High Danger: Enemies are much higher level!|r", 1, 0.2, 0.2)
            elseif pLvl < data.min then
                GameTooltip:AddLine("|cffFF7700Challenging: Quests will be yellow/orange.|r", 1, 0.5, 0)
            elseif pLvl >= data.min and pLvl <= data.max then
                GameTooltip:AddLine("|cff00FF66★ Ideal: Optimal quest XP and leveling efficiency!|r", 0.2, 1.0, 0.4)
            elseif pLvl <= (data.max + 4) then
                GameTooltip:AddLine("|cff55CCFFSlightly Low: Easy completion / finishing quests.|r", 0.3, 0.8, 1.0)
            else
                GameTooltip:AddLine("|cff888888Trivial: Grey mobs and low XP reward.|r", 0.6, 0.6, 0.6)
            end

            -- Dungeons List
            if data.dungeons and #data.dungeons > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("|cffFFD700Dungeons & Raids in this Zone:|r", 1, 1, 1)
                for _, dung in ipairs(data.dungeons) do
                    local dColor = ZL:GetLevelColorCode(dung.min, dung.max, pLvl)
                    local tag = dung.raid and " (Raid)" or ""
                    local dRange = (dung.min == dung.max) and tostring(dung.min) or (dung.min .. "-" .. dung.max)
                    GameTooltip:AddDoubleLine("  • " .. dung.name .. tag, dColor .. "[" .. dRange .. "]|r", 0.9, 0.9, 0.9)
                end
            end
        else
            GameTooltip:AddLine("|cff00FF96Grimfall Map Advisor|r", 1, 1, 1)
            GameTooltip:AddLine("Continent / Cosmic View", 1, 0.82, 0)
            GameTooltip:AddLine("Hover over any zone on the map to see its recommended levels!", 0.8, 0.8, 0.8)
        end

        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cff666666Type /gf zones for recommended zones at your level|r", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    mapBadge:SetScript("OnLeave", function() GameTooltip:Hide() end)
    mapBadge:SetScript("OnClick", function()
        ZL:PrintRecommendedZones()
    end)
end

-- Get current zone name from map dropdowns or map info
function ZL:GetCurrentMapZoneName()
    if not WorldMapFrame then return "" end

    local cIndex = GetCurrentMapContinent()
    local zIndex = GetCurrentMapZone()

    if zIndex and zIndex > 0 and cIndex and cIndex > 0 then
        local zones = { GetMapZones(cIndex) }
        if zones and zones[zIndex] then
            return zones[zIndex]
        end
    end

    -- Fallback: Area label text
    local label = WorldMapFrameAreaLabel and WorldMapFrameAreaLabel:GetText()
    if label and label ~= "" then
        local clean = string.gsub(label, "%s*%b()", "")
        return Utils:Trim(clean)
    end

    return ""
end

-- Update Map Badge Text based on open map
function ZL:UpdateBadge()
    if not mapBadge or not WorldMapFrame:IsShown() then return end

    if not GH.Config:Get("showZoneLevels", true) then
        mapBadge:Hide()
        return
    end

    mapBadge:Show()
    local curZone = self:GetCurrentMapZoneName()
    local data = self:GetZoneData(curZone)

    if data and not data.isCity then
        local pLvl = UnitLevel("player") or 1
        local color = self:GetLevelColorCode(data.min, data.max, pLvl)
        local rangeStr = (data.min == data.max) and tostring(data.min) or (data.min .. " - " .. data.max)
        local terrColor = self:GetTerritoryColorCode(data.territory)

        mapBadge.text:SetText(data.name .. "  " .. color .. "[" .. rangeStr .. "]|r " .. terrColor .. "(" .. data.territory .. ")|r")
    else
        local cIndex = GetCurrentMapContinent()
        if cIndex and cIndex > 0 then
            mapBadge.text:SetText("|cff00FF96Hover zones for levels|r |cffAAAAAA(Click for list)|r")
        else
            mapBadge.text:SetText("|cff00FF96Grimfall Zone Levels|r |cffAAAAAA(Click for list)|r")
        end
    end
end

-- Hook WorldMapFrame updates
function ZL:HookWorldMap()
    if self.hooked then return end
    self.hooked = true

    self:CreateMapBadge()

    -- 1. Hook WorldMapFrameAreaLabel:SetText to append level brackets on hover
    if WorldMapFrameAreaLabel then
        local originalSetText = WorldMapFrameAreaLabel.SetText
        WorldMapFrameAreaLabel.SetText = function(frame, text, ...)
            if inAreaHook or not GH.Config:Get("showZoneLevels", true) then
                return originalSetText(frame, text, ...)
            end

            if text and text ~= "" then
                local formatted = ZL:GetFormattedZoneText(text)
                if formatted then
                    inAreaHook = true
                    originalSetText(frame, formatted, ...)
                    inAreaHook = false
                    return
                end
            end

            return originalSetText(frame, text, ...)
        end
    end

    -- 2. Hook WorldMapFrame_Update to refresh the badge
    if WorldMapFrame_Update then
        hooksecurefunc("WorldMapFrame_Update", function()
            ZL:UpdateBadge()
        end)
    end

    -- 3. Hook WorldMapFrame:OnShow
    if WorldMapFrame then
        WorldMapFrame:HookScript("OnShow", function()
            ZL:UpdateBadge()
        end)
    end
end

-- ============================================================================
-- LEVELING ADVISOR & CHAT COMMAND
-- ============================================================================
-- Print color-coded recommended zones for the player's current level
function ZL:PrintRecommendedZones()
    local pLvl = UnitLevel("player") or 1
    Utils:Print("|cffFFD700=== Recommended Zones for Level " .. pLvl .. " ===|r")

    local recommended = {}
    local seen = {}

    for _, data in pairs(self.ZONE_DATA) do
        if not data.isCity and not seen[data.name] then
            seen[data.name] = true
            -- Check if player level fits in or is near the zone level
            if pLvl >= (data.min - 1) and pLvl <= (data.max + 1) then
                table.insert(recommended, data)
            end
        end
    end

    -- Sort by min level ascending, then continent
    table.sort(recommended, function(a, b)
        if a.min == b.min then
            return a.name < b.name
        end
        return a.min < b.min
    end)

    if #recommended == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  |cffAAAAAANo specific level match found. Check Dalaran or endgame zones.|r")
    else
        for _, z in ipairs(recommended) do
            local color = self:GetLevelColorCode(z.min, z.max, pLvl)
            local rangeStr = (z.min == z.max) and tostring(z.min) or (z.min .. " - " .. z.max)
            local terrColor = self:GetTerritoryColorCode(z.territory)

            local line = "  • |cffffffff" .. z.name .. "|r " .. color .. "[" .. rangeStr .. "]|r - " .. terrColor .. z.territory .. "|r |cff666666(" .. z.continent .. ")|r"
            DEFAULT_CHAT_FRAME:AddMessage(line)

            -- If zone has dungeons in player's level range, display them
            if z.dungeons then
                for _, d in ipairs(z.dungeons) do
                    if pLvl >= (d.min - 2) and pLvl <= (d.max + 2) then
                        local dColor = self:GetLevelColorCode(d.min, d.max, pLvl)
                        local dRange = (d.min == d.max) and tostring(d.min) or (d.min .. "-" .. d.max)
                        DEFAULT_CHAT_FRAME:AddMessage("      |cff00FF96[Dungeon]|r " .. d.name .. " " .. dColor .. "(" .. dRange .. ")|r")
                    end
                end
            end
        end
    end
end

-- Initialize on Addon Load
function ZL:Initialize()
    self:HookWorldMap()
end

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    ZL:HookWorldMap()
end)
