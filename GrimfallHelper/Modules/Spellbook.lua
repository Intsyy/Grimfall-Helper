-- ============================================================================
-- GrimfallHelper: Modules/Spellbook.lua
-- Unified Classless Spellbook Scanner, Filtering Engine, and Rank Indexer
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Spellbook = {}
local Spellbook = GH.Spellbook
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

Spellbook.spells = {}           -- List of all scanned spells
Spellbook.spellsByName = {}     -- Lookup map [cleanName] = list of ranks
Spellbook.highestRanks = {}     -- Lookup map [cleanName] = max rank entry
Spellbook.learnedNames = {}     -- Set of learned spell clean names

-- Extract numerical rank from string (e.g. "Rank 4" -> 4)
-- Returns 0 for empty/nil so we never falsely claim "Rank 1"
-- When rank is unknown and the macro omits it, WoW 3.3.5a casts the highest rank automatically
local function ExtractRankNumber(rankStr)
    if not rankStr or rankStr == "" then return 0 end
    local num = string.match(rankStr, "%d+")
    return tonumber(num) or 0
end

-- Process a single spellbook slot and return a spell entry with the best available rank info
local function ProcessSpellEntry(spellIndex, tabIndex, bookType)
    local spellName, spellRank = GetSpellName(spellIndex, bookType)
    if not spellName or spellName == "" then return nil end

    local spellLink = GetSpellLink(spellIndex, bookType)
    local spellId = spellLink and tonumber(string.match(spellLink, "spell:(%d+)"))

    -- Resolve the best rank from ALL available sources, always picking the highest
    local bestRank = spellRank or ""
    local bestRankNum = ExtractRankNumber(bestRank)

    -- Source: GetSpellInfo by numeric Spell ID (most authoritative on custom servers!)
    -- Each rank of a spell has a unique spellId, so this always returns the exact rank
    if spellId then
        local _, idRank = GetSpellInfo(spellId)
        if idRank and idRank ~= "" then
            local num = ExtractRankNumber(idRank)
            if num > bestRankNum then
                bestRank = idRank
                bestRankNum = num
            end
        end
    end

    -- Source: GetSpellInfo by spell name
    -- On retail 3.3.5a this returns the highest known rank
    -- On custom servers it may return Rank 1 — only use if HIGHER than what we already found
    if spellName then
        local _, infoRank = GetSpellInfo(spellName)
        if infoRank and infoRank ~= "" then
            local num = ExtractRankNumber(infoRank)
            if num > bestRankNum then
                bestRank = infoRank
                bestRankNum = num
            end
        end
    end

    local cleanName = Utils:NormalizeName(spellName)
    local texture = GetSpellTexture(spellIndex, bookType)
    local isPassive = IsPassiveSpell(spellIndex, bookType)

    -- Check catalog metadata
    local meta = C.SPELL_CATALOG[cleanName] or {}
    local class = meta.class or "CUSTOM"
    local school = meta.school or (isPassive and "Physical" or "Arcane")
    local category = meta.category or (isPassive and "PASSIVE" or "MELEE_NUKE")
    local resource = meta.resource or "Mana"

    local entry = {
        spellIndex = spellIndex,
        tabIndex = tabIndex or 1,
        name = spellName,
        cleanName = cleanName,
        rank = bestRank,
        rankNum = bestRankNum,
        spellId = spellId,
        texture = texture,
        isPassive = isPassive,
        spellLink = spellLink,
        class = class,
        school = school,
        category = category,
        resource = resource,
        reqShield = meta.reqShield,
        reqDagger = meta.reqDagger,
        reqRanged = meta.reqRanged,
        reqStealth = meta.reqStealth,
        isBuff = meta.buff,
    }

    return entry
end

-- Store a processed entry, ALWAYS updating highestRanks if this rank is higher
local function StoreEntry(self, entry)
    table.insert(self.spells, entry)

    if not self.spellsByName[entry.cleanName] then
        self.spellsByName[entry.cleanName] = {}
    end
    table.insert(self.spellsByName[entry.cleanName], entry)

    -- Always compare and update — never skip higher ranks!
    local curHighest = self.highestRanks[entry.cleanName]
    if not curHighest or entry.rankNum > curHighest.rankNum then
        self.highestRanks[entry.cleanName] = entry
    end

    self.learnedNames[entry.cleanName] = true
end

-- Scan player spellbook
function Spellbook:Scan()
    table.wipe(self.spells)
    table.wipe(self.spellsByName)
    table.wipe(self.highestRanks)
    table.wipe(self.learnedNames)

    local bookType = BOOKTYPE_SPELL or "spell"
    local processedSlots = {}

    -- Pass 1: Scan via Spell Tabs (standard spellbook layout)
    local numTabs = GetNumSpellTabs()
    for tabIndex = 1, numTabs do
        local tabName, tabTexture, offset, numSpells = GetSpellTabInfo(tabIndex)
        if offset and numSpells then
            for i = 1, numSpells do
                local spellIndex = offset + i
                processedSlots[spellIndex] = true
                local entry = ProcessSpellEntry(spellIndex, tabIndex, bookType)
                if entry then
                    StoreEntry(self, entry)
                end
            end
        end
    end

    -- Pass 2: Brute-force scan of ALL spell indices to catch spells outside tabs
    -- Critical for classless servers where spells may not belong to standard tabs!
    -- Does NOT skip already-seen spell names — higher ranks at different indices are always picked up
    local emptyStreak = 0
    for spellIndex = 1, 1024 do
        if not processedSlots[spellIndex] then
            local spellName = GetSpellName(spellIndex, bookType)
            if spellName and spellName ~= "" then
                emptyStreak = 0
                local entry = ProcessSpellEntry(spellIndex, 1, bookType)
                if entry then
                    StoreEntry(self, entry)
                end
            else
                emptyStreak = emptyStreak + 1
                if emptyStreak > 100 then break end
            end
        end
    end

    -- Pass 3: Final rank verification via spellId
    -- For each highest-rank entry, double-check using GetSpellInfo(spellId)
    for cleanName, entry in pairs(self.highestRanks) do
        if entry.spellId then
            local _, idRank = GetSpellInfo(entry.spellId)
            if idRank and idRank ~= "" then
                local num = ExtractRankNumber(idRank)
                if num > entry.rankNum then
                    entry.rank = idRank
                    entry.rankNum = num
                end
            end
        end
    end

    -- Pass 4: Grimfall Classless engine known spell IDs (from clientextensions.dll)
    if type(GetKnownClasslessSpellIds) == "function" then
        pcall(function()
            local ids = GetKnownClasslessSpellIds()
            if type(ids) == "table" then
                for _, spId in pairs(ids) do
                    if type(spId) == "number" and spId > 0 then
                        local sName, sRank, sIcon = GetSpellInfo(spId)
                        if sName and sName ~= "" then
                            local entry = {
                                name = sName,
                                rank = sRank or "",
                                rankNum = ExtractRankNumber(sRank),
                                spellId = spId,
                                texture = sIcon,
                                category = C.CATEGORIES[sName] or "OTHER",
                                school = C.SPELL_SCHOOLS[sName] or "Physical",
                                class = C.CLASS_SPELLS[sName] or "Custom",
                                resource = C.SPELL_COST_TYPES[sName] or "None",
                                spellIndex = 1,
                                tabIndex = 1,
                                bookType = BOOKTYPE_SPELL,
                            }
                            StoreEntry(self, entry)
                        end
                    end
                end
            end
        end)
    end

    Utils:Debug("Spellbook scanned: " .. #self.spells .. " spells, " .. self:GetUniqueSpellCount() .. " unique abilities.")
    EventBus:Fire("GH_SPELLBOOK_UPDATED")
end

-- Return number of unique spell abilities
function Spellbook:GetUniqueSpellCount()
    local count = 0
    for _ in pairs(self.highestRanks) do
        count = count + 1
    end
    return count
end

-- Check if player knows a spell
function Spellbook:HasSpell(spellName)
    if not spellName or spellName == "" then return false end
    local clean = Utils:NormalizeName(spellName)
    if self.learnedNames[clean] then return true end
    if self.highestRanks[clean] then return true end
    -- Fallback: ask the client engine directly (catches spells missed by scan)
    local name = GetSpellInfo(spellName)
    return name ~= nil
end

-- Get highest rank entry for a given spell name
function Spellbook:GetHighestRank(spellName)
    local clean = Utils:NormalizeName(spellName)
    return self.highestRanks[clean]
end

-- Get highest rank cast string for macros (e.g. "Flash Heal(Rank 7)")
-- If rank is unknown, returns just the spell name so WoW casts the highest rank by default
function Spellbook:GetHighestRankCastString(spellName)
    if not spellName or spellName == "" then return spellName end

    local bestRank = nil
    local bestRankNum = 0

    -- 1. Cached highest rank entry (most reliable on custom servers)
    local entry = self:GetHighestRank(spellName)
    if entry then
        if entry.rank and entry.rank ~= "" then
            local num = ExtractRankNumber(entry.rank)
            if num > bestRankNum then
                bestRank = entry.rank
                bestRankNum = num
            end
        end
        -- 1b. GetSpellInfo by stored spellId (authoritative per-rank)
        if entry.spellId then
            local _, idRank = GetSpellInfo(entry.spellId)
            if idRank and idRank ~= "" then
                local num = ExtractRankNumber(idRank)
                if num > bestRankNum then
                    bestRank = idRank
                    bestRankNum = num
                end
            end
        end
    end

    -- 2. GetSpellInfo by name — only used if it gives a HIGHER rank than cached data
    local _, infoRank = GetSpellInfo(spellName)
    if infoRank and infoRank ~= "" then
        local num = ExtractRankNumber(infoRank)
        if num > bestRankNum then
            bestRank = infoRank
            bestRankNum = num
        end
    end

    -- 3. Format as SpellName(Rank N)
    -- If rank is unknown (bestRankNum=0), return just the spell name
    -- WoW 3.3.5a will automatically cast the highest learned rank!
    if bestRank and bestRank ~= "" and bestRankNum > 0 then
        if not string.find(bestRank, "%(") then
            return spellName .. "(" .. bestRank .. ")"
        else
            return spellName .. bestRank
        end
    end

    return spellName
end

-- Get highest rank number (e.g. 7), returns nil if unknown
function Spellbook:GetHighestRankNum(spellName)
    if not spellName or spellName == "" then return nil end

    local bestNum = 0

    -- Cached entry
    local entry = self:GetHighestRank(spellName)
    if entry then
        if entry.rankNum and entry.rankNum > bestNum then
            bestNum = entry.rankNum
        end
        if entry.spellId then
            local _, idRank = GetSpellInfo(entry.spellId)
            if idRank and idRank ~= "" then
                local num = ExtractRankNumber(idRank)
                if num > bestNum then bestNum = num end
            end
        end
    end

    -- GetSpellInfo by name
    local _, infoRank = GetSpellInfo(spellName)
    if infoRank and infoRank ~= "" then
        local num = ExtractRankNumber(infoRank)
        if num > bestNum then bestNum = num end
    end

    return bestNum > 0 and bestNum or nil
end

-- Get rank badge string for UI buttons (e.g. "R7")
function Spellbook:GetHighestRankBadge(spellName)
    local num = self:GetHighestRankNum(spellName)
    if num and num > 0 then
        return "R" .. num
    end
    return ""
end


-- Filter spells for UI display
function Spellbook:FilterSpells(classFilter, categoryFilter, schoolFilter, resourceFilter, searchQuery, highestOnly)
    local results = {}
    local query = searchQuery and Utils:NormalizeName(searchQuery) or ""

    local source = highestOnly and self.highestRanks or self.spells

    for _, entry in pairs(source) do
        local match = true

        -- Class filter
        if classFilter and classFilter ~= "ALL" and entry.class ~= classFilter then
            match = false
        end

        -- Category filter
        if match and categoryFilter and categoryFilter ~= "ALL" and entry.category ~= categoryFilter then
            match = false
        end

        -- School filter
        if match and schoolFilter and schoolFilter ~= "ALL" and entry.school ~= schoolFilter then
            match = false
        end

        -- Resource filter
        if match and resourceFilter and resourceFilter ~= "ALL" and entry.resource ~= resourceFilter then
            match = false
        end

        -- Search query filter
        if match and query ~= "" then
            if not string.find(entry.cleanName, query, 1, true) and not string.find(string.lower(entry.school), query, 1, true) then
                match = false
            end
        end

        if match then
            table.insert(results, entry)
        end
    end

    -- Sort alphabetically by name then rank
    table.sort(results, function(a, b)
        if a.name == b.name then
            return a.rankNum < b.rankNum
        end
        return a.name < b.name
    end)

    return results
end

-- Drag to Action Bar
function Spellbook:Pickup(spellIndex)
    if spellIndex then
        PickupSpell(spellIndex, BOOKTYPE_SPELL)
    end
end

-- Event Listeners
EventBus:Register("SPELLS_CHANGED", function()
    Spellbook:Scan()
end)

EventBus:Register("LEARNED_SPELL_IN_TAB", function()
    Spellbook:Scan()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    Spellbook:Scan()
end)

EventBus:Register("PLAYER_LOGIN", function()
    Spellbook:Scan()
end)
