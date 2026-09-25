-- ============================================================================
-- GrimfallHelper: Modules/BuildExporter.lua
-- 1-Click Build Exporter for AI (Spells, Talents, Grimfall Runes & Stats)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.BuildExporter = {}
local BE = GH.BuildExporter
local C = GH.Constants
local Utils = GH.Utils

-- Hidden Scanning Tooltip for inspecting item runes and talent descriptions
local scanTooltip = CreateFrame("GameTooltip", "GrimfallExportScanTooltip", UIParent, "GameTooltipTemplate")
scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

-- Equipment Slot Names
local INVENTORY_SLOTS = {
    { id = 1,  name = "Head" },
    { id = 2,  name = "Neck" },
    { id = 3,  name = "Shoulders" },
    { id = 15, name = "Back" },
    { id = 5,  name = "Chest" },
    { id = 9,  name = "Wrist" },
    { id = 10, name = "Hands" },
    { id = 6,  name = "Waist" },
    { id = 7,  name = "Legs" },
    { id = 8,  name = "Feet" },
    { id = 11, name = "Finger 1" },
    { id = 12, name = "Finger 2" },
    { id = 13, name = "Trinket 1" },
    { id = 14, name = "Trinket 2" },
    { id = 16, name = "Main Hand" },
    { id = 17, name = "Off Hand" },
    { id = 18, name = "Ranged" },
}

-- Clean Tooltip Text (strip color codes, linebreaks, and whitespace)
local function CleanTooltipText(text)
    if not text then return "" end
    text = string.gsub(text, "|c%x%x%x%x%x%x%x%x", "")
    text = string.gsub(text, "|r", "")
    text = string.gsub(text, "\r", "")
    text = string.gsub(text, "\n", " ")
    return Utils:Trim(text)
end

-- ============================================================================
-- DATA COLLECTORS
-- ============================================================================

-- 1. Collect Character Summary & Stats
function BE:CollectStats()
    local name = UnitName("player") or "Hero"
    local level = UnitLevel("player") or 1
    local race = UnitRace("player") or "Unknown"
    local class = UnitClass("player") or "Hero"

    -- Primary Attributes (Strength, Agility, Stamina, Intellect, Spirit)
    local str, agi, sta, int, spi = 0, 0, 0, 0, 0
    pcall(function() local _, s = UnitStat("player", 1); str = math.floor(s or 0) end)
    pcall(function() local _, a = UnitStat("player", 2); agi = math.floor(a or 0) end)
    pcall(function() local _, st = UnitStat("player", 3); sta = math.floor(st or 0) end)
    pcall(function() local _, i = UnitStat("player", 4); int = math.floor(i or 0) end)
    pcall(function() local _, sp = UnitStat("player", 5); spi = math.floor(sp or 0) end)

    -- Item Level
    local ilvl = 0
    pcall(function()
        if type(GetAverageItemLevel) == "function" then
            local _, eq = GetAverageItemLevel()
            if eq and eq > 0 then ilvl = math.floor(eq) end
        end
        if ilvl == 0 then
            local total, count = 0, 0
            local slots = { 1, 2, 3, 15, 5, 9, 10, 6, 7, 8, 11, 12, 13, 14, 16, 17, 18 }
            for _, slot in ipairs(slots) do
                local link = GetInventoryItemLink("player", slot)
                if link then
                    local _, _, _, itemLvl = GetItemInfo(link)
                    if itemLvl and itemLvl > 0 then
                        total = total + itemLvl
                        count = count + 1
                    end
                end
            end
            if count > 0 then
                ilvl = math.floor((total / count) + 0.5)
            end
        end
    end)

    local ap = 0
    pcall(function()
        local base, pos, neg = UnitAttackPower("player")
        ap = (base or 0) + (pos or 0) + (neg or 0)
    end)

    local sp = 0
    pcall(function() sp = GetSpellBonusDamage(2) or 0 end)

    local meleeCrit = 0
    pcall(function() meleeCrit = GetCritChance() or 0 end)

    local spellCrit = 0
    pcall(function() spellCrit = GetSpellCritChance(2) or 0 end)

    local hit = 0
    pcall(function() hit = GetCombatRatingBonus(CR_HIT_MELEE or 6) or 0 end)

    local defense = 0
    pcall(function()
        if GH.StatInspector then
            local s = GH.StatInspector:GetStats()
            if s and s.defense then defense = s.defense end
        end
    end)

    local armor = 0
    pcall(function()
        local _, eff = UnitArmor("player")
        armor = eff or 0
    end)

    return {
        name = name,
        level = level,
        race = race,
        class = class,
        ilvl = ilvl,
        str = str,
        agi = agi,
        sta = sta,
        int = int,
        spi = spi,
        ap = ap,
        sp = sp,
        meleeCrit = string.format("%.1f%%", meleeCrit),
        spellCrit = string.format("%.1f%%", spellCrit),
        hit = string.format("%.1f%%", hit),
        defense = defense,
        armor = armor,
    }
end

-- Rarity text mapping helper
local RARITY_MAP = {
    [0] = "Poor",
    [1] = "Common",
    [2] = "Uncommon",
    [3] = "Rare",
    [4] = "Epic",
    [5] = "Legendary",
    [6] = "Artifact",
}

local function FormatRarity(val)
    if type(val) == "string" and val ~= "" then
        return val
    elseif type(val) == "number" and RARITY_MAP[val] then
        return RARITY_MAP[val]
    end
    return "Rare"
end

-- Extract rich spell/rune description from tooltip
local function GetRuneDescription(spellId, fallbackName)
    local desc = ""
    if spellId and tonumber(spellId) and tonumber(spellId) > 0 then
        pcall(function()
            scanTooltip:ClearLines()
            scanTooltip:SetHyperlink("spell:" .. tonumber(spellId))
            local numLines = scanTooltip:NumLines() or 0
            if numLines >= 2 then
                local descLines = {}
                for l = 2, numLines do
                    local lineFrame = _G["GrimfallExportScanTooltipTextLeft" .. l]
                    local txt = lineFrame and lineFrame:GetText()
                    if txt and txt ~= "" then
                        local clean = CleanTooltipText(txt)
                        local lower = string.lower(clean)
                        if not (string.find(lower, "yd range") or 
                                string.find(lower, "instant") or 
                                string.find(lower, "sec cast") or 
                                string.find(lower, "cooldown") or 
                                string.find(lower, "mana") or 
                                string.find(lower, "rage") or 
                                string.find(lower, "energy") or 
                                string.find(lower, "runic power") or
                                string.find(lower, "requires level")) then
                            table.insert(descLines, clean)
                        end
                    end
                end
                if #descLines > 0 then
                    desc = table.concat(descLines, " ")
                else
                    local lastFrame = _G["GrimfallExportScanTooltipTextLeft" .. numLines]
                    desc = lastFrame and CleanTooltipText(lastFrame:GetText()) or ""
                end
            end
        end)
    end

    if desc == "" and fallbackName and fallbackName ~= "" then
        pcall(function()
            scanTooltip:ClearLines()
            scanTooltip:SetHyperlink("spell:" .. fallbackName)
            local numLines = scanTooltip:NumLines() or 0
            if numLines >= 2 then
                local lastFrame = _G["GrimfallExportScanTooltipTextLeft" .. numLines]
                desc = lastFrame and CleanTooltipText(lastFrame:GetText()) or ""
            end
        end)
    end

    return desc
end

-- 2. Collect Active Grimfall Runes (Runic Enhancements / Skill Cards)
function BE:CollectRunes()
    local runes = {}
    local seen = {}

    -- Helper to register unique active rune
    local function AddRune(name, rarity, source, desc, spellId, slot)
        if not name or name == "" then return end
        local cleanName = CleanTooltipText(name)

        -- Cross-reference with GH.RuneData database for 100% decrypted name, quality & translated values
        if (not spellId or spellId == 0) and GH.RuneDataByName then
            spellId = GH.RuneDataByName[string.lower(cleanName)]
        end
        if spellId and GH.RuneData and GH.RuneData[spellId] then
            local rd = GH.RuneData[spellId]
            if rd.name and rd.name ~= "" then cleanName = rd.name end
            if rd.quality then rarity = rd.quality end
            if rd.desc and rd.desc ~= "" then desc = rd.desc end
        end

        if cleanName == "" or seen[cleanName] then return end
        seen[cleanName] = true

        local rText = FormatRarity(rarity)
        local dText = desc or ""
        if (dText == "" or dText == cleanName) and spellId then
            dText = GetRuneDescription(spellId, cleanName)
        end
        if dText == "" or dText == cleanName then
            dText = rText .. " Runic Enhancement"
        end

        table.insert(runes, {
            name = cleanName,
            rarity = rText,
            quality = type(rarity) == "number" and rarity or (rText == "Legendary" and 5 or rText == "Epic" and 4 or rText == "Rare" and 3 or 2),
            source = source or (rText .. " Rune"),
            desc = dText,
            spellId = spellId,
            slot = slot,
        })
    end

    -- ------------------------------------------------------------------------
    -- Source 0: Grimfall Classless Freepick Active Rune Groups (Exact UI Model)
    -- This is the official function Grimfall's Classless window uses to build the active runes list!
    -- ------------------------------------------------------------------------
    local fnBuildGroups = (type(ClasslessFrame_Freepick_BuildRuneGroups) == "function" and ClasslessFrame_Freepick_BuildRuneGroups)
                       or (type(_G.ClasslessFrame_Freepick_BuildRuneGroups) == "function" and _G.ClasslessFrame_Freepick_BuildRuneGroups)

    if fnBuildGroups then
        pcall(function()
            local groups = fnBuildGroups()
            if type(groups) == "table" then
                for _, group in ipairs(groups) do
                    local groupQuality = group.quality or FormatRarity(group.qualityID)
                    for _, enchant in ipairs(group.enchants or {}) do
                        local spellId = enchant.spellID
                        local name = enchant.name
                        if (not name or name == "") and spellId then
                            name = GetSpellInfo(spellId)
                        end
                        if name and name ~= "" then
                            local rarity = enchant.qualityName or groupQuality
                            local desc = GetRuneDescription(spellId, name)
                            AddRune(name, rarity, "Active " .. rarity .. " Rune", desc, spellId, nil)
                        end
                    end
                end
            end
        end)
    end

    -- ------------------------------------------------------------------------
    -- Source 1: Grimfall Native Engine Runic Enhancement APIs (MysticEnchant_)
    -- Direct engine C API registered by clientextensions.dll
    -- ------------------------------------------------------------------------
    local fnGetKnownRE = (type(MysticEnchant_GetKnownRESpellIds) == "function" and MysticEnchant_GetKnownRESpellIds)
                      or (type(_G.MysticEnchant_GetKnownRESpellIds) == "function" and _G.MysticEnchant_GetKnownRESpellIds)
                      or (type(ClasslessFrame_Freepick_GetKnownRuneSpellIDs) == "function" and ClasslessFrame_Freepick_GetKnownRuneSpellIDs)

    local fnGetQuality = (type(MysticEnchant_GetSpellQuality) == "function" and MysticEnchant_GetSpellQuality)
                      or (type(ClasslessFrame_Freepick_GetRuneQuality) == "function" and ClasslessFrame_Freepick_GetRuneQuality)

    if fnGetKnownRE then
        pcall(function()
            local knownIds = fnGetKnownRE()
            if type(knownIds) == "table" then
                for _, rawId in pairs(knownIds) do
                    local spellId = tonumber(rawId)
                    if spellId and spellId > 0 then
                        local name = GetSpellInfo(spellId)
                        if name and name ~= "" then
                            local qId = fnGetQuality and fnGetQuality(spellId) or 3
                            local rarity = FormatRarity(qId)
                            local desc = GetRuneDescription(spellId, name)
                            AddRune(name, rarity, "Active " .. rarity .. " Rune", desc, spellId, nil)
                        end
                    end
                end
            end
        end)
    end

    -- ------------------------------------------------------------------------
    -- Source 2: Active Runes Panel UI Frame Inspection (ClasslessFrame_Freepick)
    -- Reads directly from the rendered Classless window buttons if initialized
    -- ------------------------------------------------------------------------
    pcall(function()
        local frame = _G.ClasslessFrame_Freepick
        if frame and frame.ActiveRunesPanel and frame.ActiveRunesPanel.Widgets then
            for _, widget in ipairs(frame.ActiveRunesPanel.Widgets) do
                if widget and widget.enchantData then
                    local data = widget.enchantData
                    local spellId = data.spellID
                    local name = widget.fullName or data.name or (spellId and GetSpellInfo(spellId))
                    local rarity = data.qualityName or "Rare"
                    if name and name ~= "" then
                        local desc = GetRuneDescription(spellId, name)
                        AddRune(name, rarity, "Active " .. rarity .. " Rune (UI)", desc, spellId, nil)
                    end
                end
            end
        end
    end)

    -- ------------------------------------------------------------------------
    -- Source 3: Native Grimfall Engine SkillCard APIs (clientextensions.dll)
    -- Queries active slots and cards via GetActiveSkillCardBySlot / GetSkillCards
    -- ------------------------------------------------------------------------
    local getActiveSlot = (type(GetActiveSkillCardBySlot) == "function" and GetActiveSkillCardBySlot)
                       or (type(SkillCard_GetActiveCardBySlot) == "function" and SkillCard_GetActiveCardBySlot)

    local maxSlots = 25
    if type(GetMaxActiveSkillCards) == "function" then
        pcall(function() maxSlots = GetMaxActiveSkillCards() or maxSlots end)
    elseif type(SkillCard_GetMaxActiveCards) == "function" then
        pcall(function() maxSlots = SkillCard_GetMaxActiveCards() or maxSlots end)
    end

    if getActiveSlot then
        for slot = 0, maxSlots do
            pcall(function()
                local card = getActiveSlot(slot)
                if type(card) == "table" then
                    local cardName = card.CardName
                    local spellId = card.SpellID
                    if (cardName and cardName ~= "") or (spellId and tonumber(spellId) and tonumber(spellId) > 0) then
                        local name = cardName
                        if (not name or name == "") and spellId then
                            name = GetSpellInfo(spellId) or ("Rune " .. spellId)
                        end
                        if name and name ~= "" then
                            local rarity = FormatRarity(card.Rarity)
                            local slotNum = card.Slot or slot
                            local desc = GetRuneDescription(spellId, name)
                            AddRune(name, rarity, "Active " .. rarity .. " Rune (Slot " .. slotNum .. ")", desc, spellId, slotNum)
                        end
                    end
                end
            end)
        end
    end

    local getAllCards = (type(GetSkillCards) == "function" and GetSkillCards)
                     or (type(SkillCard_GetCards) == "function" and SkillCard_GetCards)

    if getAllCards then
        pcall(function()
            local cards = getAllCards()
            if type(cards) == "table" then
                for _, card in pairs(cards) do
                    if type(card) == "table" and (card.Active == true or card.Active == 1) then
                        local cardName = card.CardName
                        local spellId = card.SpellID
                        local name = cardName
                        if (not name or name == "") and spellId then
                            name = GetSpellInfo(spellId) or ("Rune " .. spellId)
                        end
                        if name and name ~= "" then
                            local rarity = FormatRarity(card.Rarity)
                            local slotNum = card.Slot
                            local desc = GetRuneDescription(spellId, name)
                            AddRune(name, rarity, "Active " .. rarity .. " Rune", desc, spellId, slotNum)
                        end
                    end
                end
            end
        end)
    end

    -- ------------------------------------------------------------------------
    -- Source 4: Dynamic Grimfall Classless UI Frame Scanner
    -- Traverses all frames via EnumerateFrames to find active rune rows
    -- ------------------------------------------------------------------------
    pcall(function()
        local function ProcessRuneFrame(f)
            if not f then return end
            if f.enchantData then
                local data = f.enchantData
                local spellId = data.spellID
                local name = f.fullName or data.name or (spellId and GetSpellInfo(spellId))
                local rarity = data.qualityName or "Rare"
                if name and name ~= "" then
                    local desc = GetRuneDescription(spellId, name)
                    AddRune(name, rarity, "Active " .. rarity .. " Rune", desc, spellId, nil)
                    return
                end
            end

            if not f.GetRegions then return end
            local fsList = {}
            for _, r in ipairs({ f:GetRegions() }) do
                if r and r.GetObjectType and r:IsObjectType("FontString") then
                    local t = r:GetText()
                    if t and t ~= "" then
                        table.insert(fsList, CleanTooltipText(t))
                    end
                end
            end

            local runeName = nil
            local runeRarity = nil
            for _, t in ipairs(fsList) do
                local m = string.match(t, "(Rune of [^\n\r]+)") or string.match(t, "(Runic [^\n\r]+)")
                if m then
                    runeName = CleanTooltipText(m)
                elseif t == "Legendary" or t == "Epic" or t == "Rare" or t == "Uncommon" or t == "Common" then
                    runeRarity = t
                end
            end

            if runeName and runeRarity then
                local resolvedName = runeName
                local resolvedSpellId = f.spellId or f.spellID or f.cardId or f.id

                if string.find(runeName, "%.%.%.$") then
                    local prefix = string.sub(runeName, 1, -4)
                    if GH.Spellbook and GH.Spellbook.spells then
                        for _, sp in ipairs(GH.Spellbook.spells) do
                            if sp.name and string.sub(sp.name, 1, #prefix) == prefix then
                                resolvedName = sp.name
                                resolvedSpellId = resolvedSpellId or sp.spellId
                                break
                            end
                        end
                    end
                end

                local desc = GetRuneDescription(resolvedSpellId, resolvedName)
                AddRune(resolvedName, runeRarity, "Classless Active Rune (" .. runeRarity .. ")", desc, resolvedSpellId, nil)
            end
        end

        local f = EnumerateFrames()
        while f do
            ProcessRuneFrame(f)
            f = EnumerateFrames(f)
        end
    end)

    -- ------------------------------------------------------------------------
    -- Source 3: Scan Equipped Gear Tooltips for Engraved Runes
    -- ------------------------------------------------------------------------
    for _, slotInfo in ipairs(INVENTORY_SLOTS) do
        pcall(function()
            local link = GetInventoryItemLink("player", slotInfo.id)
            if link then
                scanTooltip:ClearLines()
                scanTooltip:SetInventoryItem("player", slotInfo.id)

                local itemName = GetItemInfo(link) or slotInfo.name
                local numLines = scanTooltip:NumLines() or 0

                for lineIdx = 2, numLines do
                    local lineFrame = _G["GrimfallExportScanTooltipTextLeft" .. lineIdx]
                    local lineText = lineFrame and lineFrame:GetText()

                    if lineText and lineText ~= "" then
                        local clean = CleanTooltipText(lineText)
                        local lower = string.lower(clean)

                        if string.find(lower, "rune") or string.find(lower, "runic") or string.find(lower, "enhancement") then
                            AddRune(clean, "Rare", slotInfo.name .. " (" .. itemName .. ")", clean, nil, nil)
                        end
                    end
                end
            end
        end)
    end

    -- ------------------------------------------------------------------------
    -- Source 4: Scan Spellbook for Learned Runes and Passives
    -- ------------------------------------------------------------------------
    if GH.Spellbook and GH.Spellbook.spells then
        for _, entry in ipairs(GH.Spellbook.spells) do
            pcall(function()
                local cleanName = string.lower(entry.name or "")
                local isRuneSpell = string.find(cleanName, "rune") or string.find(cleanName, "runic")

                local tabName = ""
                if entry.tabIndex then
                    tabName = select(1, GetSpellTabInfo(entry.tabIndex)) or ""
                end
                local isRuneTab = string.find(string.lower(tabName), "rune") or string.find(string.lower(tabName), "enhancement")

                if isRuneSpell or isRuneTab then
                    local desc = GetRuneDescription(entry.spellId, entry.name)
                    local rName = entry.name .. (entry.rank and entry.rank ~= "" and (" (" .. entry.rank .. ")") or "")
                    local src = (tabName ~= "") and ("Spellbook - " .. tabName) or "Spellbook Passive"
                    AddRune(rName, "Rare", src, desc, entry.spellId, nil)
                end
            end)
        end
    end

    -- ------------------------------------------------------------------------
    -- Source 5: Scan Active Player Buffs/Auras for Rune Effects
    -- ------------------------------------------------------------------------
    for i = 1, 40 do
        pcall(function()
            local name = UnitBuff("player", i)
            if name then
                local lower = string.lower(name)
                if string.find(lower, "rune") or string.find(lower, "runic") then
                    local desc = ""
                    pcall(function()
                        scanTooltip:ClearLines()
                        scanTooltip:SetUnitBuff("player", i)
                        local nLines = scanTooltip:NumLines() or 0
                        if nLines >= 2 then
                            local dFrame = _G["GrimfallExportScanTooltipTextLeft" .. nLines]
                            desc = dFrame and CleanTooltipText(dFrame:GetText()) or ""
                        end
                    end)
                    AddRune(name, "Rare", "Active Player Aura", desc, nil, nil)
                end
            end
        end)
    end

    return runes
end

-- 3. Collect Allocated Talents
function BE:CollectTalents()
    local trees = {}
    local numTabs = 0
    pcall(function() numTabs = GetNumTalentTabs() or 0 end)

    for tab = 1, numTabs do
        pcall(function()
            local tabName, tabTexture, pointsSpent = GetTalentTabInfo(tab)
            tabName = tabName or ("Tree " .. tab)
            pointsSpent = pointsSpent or 0

            local allocatedTalents = {}
            local numTalents = GetNumTalents(tab) or 0

            for i = 1, numTalents do
                pcall(function()
                    local name, iconTexture, tier, column, currentRank, maxRank = GetTalentInfo(tab, i)
                    if currentRank and currentRank > 0 then
                        local desc = ""
                        pcall(function()
                            scanTooltip:ClearLines()
                            scanTooltip:SetTalent(tab, i)
                            local numLines = scanTooltip:NumLines() or 0
                            if numLines >= 2 then
                                local dFrame = _G["GrimfallExportScanTooltipTextLeft" .. numLines]
                                desc = dFrame and CleanTooltipText(dFrame:GetText()) or ""
                            end
                        end)

                        table.insert(allocatedTalents, {
                            name = name or ("Talent " .. i),
                            currentRank = currentRank,
                            maxRank = maxRank or currentRank,
                            tier = tier or 1,
                            desc = desc,
                        })
                    end
                end)
            end

            if pointsSpent > 0 or #allocatedTalents > 0 then
                table.insert(trees, {
                    name = tabName,
                    points = pointsSpent,
                    talents = allocatedTalents,
                })
            end
        end)
    end

    return trees
end

-- 4. Collect Learned Spells (Categorized by Role / School)
function BE:CollectSpells()
    if not GH.Spellbook or not GH.Spellbook.highestRanks or next(GH.Spellbook.highestRanks) == nil then
        if GH.Spellbook then
            pcall(function() GH.Spellbook:Scan() end)
        end
    end

    local categories = {
        ["MELEE_NUKE"]   = { title = "⚔️ Melee Attacks & Strikes", spells = {} },
        ["RANGED_NUKE"]  = { title = "🏹 Ranged & Spell Attacks", spells = {} },
        ["DOT_BLEED"]    = { title = "🩸 Damage Over Time & Bleeds", spells = {} },
        ["HEAL"]         = { title = "💚 Healing, HoTs & Shields", spells = {} },
        ["DEFENSIVE"]    = { title = "🛡️ Defensives, Mitigation & Survival", spells = {} },
        ["CC_INTERRUPT"] = { title = "❄️ Crowd Control & Interrupts", spells = {} },
        ["BUFF_AURA"]    = { title = "✨ Buffs, Auras & Stances", spells = {} },
        ["PET_SUMMON"]   = { title = "🐾 Utility & Summons", spells = {} },
        ["PASSIVE"]      = { title = "📜 Passive Abilities", spells = {} },
        ["OTHER"]        = { title = "🔮 Other Abilities", spells = {} },
    }

    local highestRanks = (GH.Spellbook and GH.Spellbook.highestRanks) or {}

    for cleanName, entry in pairs(highestRanks) do
        local catKey = entry.category or "OTHER"
        if not categories[catKey] then
            catKey = "OTHER"
        end

        local rankStr = (entry.rank and entry.rank ~= "") and (" (" .. entry.rank .. ")") or ""
        local schoolStr = entry.school and (" [" .. entry.school .. "]") or ""
        local resourceStr = (entry.resource and entry.resource ~= "None") and (" {" .. entry.resource .. "}") or ""

        table.insert(categories[catKey].spells, {
            name = (entry.name or cleanName) .. rankStr,
            school = entry.school or "Physical",
            class = entry.class or "Custom",
            meta = schoolStr .. resourceStr,
            id = entry.spellId,
        })
    end

    -- Sort spells alphabetically within each category
    for _, group in pairs(categories) do
        table.sort(group.spells, function(a, b) return a.name < b.name end)
    end

    return categories
end

-- ============================================================================
-- EXPORT STRING GENERATOR (MARKDOWN FOR AI)
-- ============================================================================

function BE:GenerateExportString(includePrompt)
    if includePrompt == nil then includePrompt = true end

    local stats = self:CollectStats()
    local runes = self:CollectRunes()
    local talentTrees = self:CollectTalents()
    local spellCats = self:CollectSpells()

    local lines = {}

    -- AI Prompt Header
    if includePrompt then
        table.insert(lines, "# 🧙‍♂️ Grimfall Classless WoW Character Build")
        table.insert(lines, "> **Prompt for AI:** Please analyze this character build from Grimfall WoW (a classless Wrath of the Lich King 3.3.5a server). Evaluate my synergies, talent point allocations, active runes, and spell choices. Suggest build optimizations, missing synergy abilities, rotation priorities, and gearing recommendations.")
        table.insert(lines, "")
    else
        table.insert(lines, "# Grimfall Character Build Export")
        table.insert(lines, "")
    end

    -- Character Info
    table.insert(lines, "## 👤 Character Overview")
    table.insert(lines, "- **Name:** " .. stats.name)
    local ilvlStr = (stats.ilvl and stats.ilvl > 0) and (" | **Item Level:** " .. stats.ilvl) or ""
    table.insert(lines, "- **Level:** " .. stats.level .. " | **Race:** " .. stats.race .. " | **Class/Hero:** " .. stats.class .. ilvlStr)
    table.insert(lines, string.format("- **Primary Attributes:** Str: %d | Agi: %d | Sta: %d | Int: %d | Spi: %d",
        stats.str or 0, stats.agi or 0, stats.sta or 0, stats.int or 0, stats.spi or 0))
    table.insert(lines, string.format("- **Combat Stats:** AP: %d | SP: %d | Melee Crit: %s | Spell Crit: %s | Hit: %s | Defense: %d | Armor: %d",
        stats.ap or 0, stats.sp or 0, stats.meleeCrit or "0%", stats.spellCrit or "0%", stats.hit or "0%", stats.defense or 0, stats.armor or 0))
    table.insert(lines, "")

    -- Active Grimfall Runes
    table.insert(lines, "## 📜 Active Runes (Grimfall Runic Enhancements)")
    if #runes == 0 then
        table.insert(lines, "_No active equipment runes or runic passives detected._")
    else
        -- Group runes by rarity tier
        local tierOrder = { "Legendary", "Epic", "Rare", "Uncommon", "Common", "Other" }
        local tierIcons = {
            ["Legendary"] = "🟠 Legendary Runes",
            ["Epic"]      = "🟣 Epic Runes",
            ["Rare"]      = "🔵 Rare Runes",
            ["Uncommon"]  = "🟢 Uncommon Runes",
            ["Common"]    = "⚪ Common Runes",
            ["Other"]     = "📜 Other Enhancements",
        }
        local groups = {
            ["Legendary"] = {},
            ["Epic"]      = {},
            ["Rare"]      = {},
            ["Uncommon"]  = {},
            ["Common"]    = {},
            ["Other"]     = {},
        }

        for _, r in ipairs(runes) do
            local tier = r.rarity or "Other"
            if not groups[tier] then tier = "Other" end
            table.insert(groups[tier], r)
        end

        for _, tier in ipairs(tierOrder) do
            local list = groups[tier]
            if list and #list > 0 then
                table.insert(lines, string.format("### %s (%d)", tierIcons[tier] or tier, #list))
                for _, r in ipairs(list) do
                    local metaParts = {}
                    if r.slot then table.insert(metaParts, "Slot " .. r.slot) end
                    if r.spellId then table.insert(metaParts, "Spell ID: " .. r.spellId) end
                    local metaStr = #metaParts > 0 and (" (" .. table.concat(metaParts, " | ") .. ")") or ""

                    if r.desc and r.desc ~= "" and r.desc ~= r.name then
                        table.insert(lines, string.format("  • **[%s]**%s: %s", r.name, metaStr, r.desc))
                    else
                        table.insert(lines, string.format("  • **[%s]**%s", r.name, metaStr))
                    end
                end
                table.insert(lines, "")
            end
        end
    end
    table.insert(lines, "")

    -- Talents
    table.insert(lines, "## 🌲 Talents & Specializations")
    local totalTalentPoints = 0
    for _, tree in ipairs(talentTrees) do
        totalTalentPoints = totalTalentPoints + tree.points
    end

    if #talentTrees == 0 or totalTalentPoints == 0 then
        table.insert(lines, "_No talent points currently allocated._")
    else
        for _, tree in ipairs(talentTrees) do
            table.insert(lines, string.format("### %s (%d points)", tree.name, tree.points))
            for _, t in ipairs(tree.talents) do
                if t.desc and t.desc ~= "" then
                    table.insert(lines, string.format("  • **%s (%d/%d):** %s", t.name, t.currentRank, t.maxRank, t.desc))
                else
                    table.insert(lines, string.format("  • **%s (%d/%d)**", t.name, t.currentRank, t.maxRank))
                end
            end
            table.insert(lines, "")
        end
    end
    table.insert(lines, "")

    -- Learned Spells
    table.insert(lines, "## 🌟 Learned Spells & Abilities (Highest Known Ranks)")
    local order = { "MELEE_NUKE", "RANGED_NUKE", "DOT_BLEED", "HEAL", "DEFENSIVE", "CC_INTERRUPT", "BUFF_AURA", "PET_SUMMON", "PASSIVE", "OTHER" }

    local totalSpells = 0
    for _, key in ipairs(order) do
        local grp = spellCats[key]
        if grp and #grp.spells > 0 then
            totalSpells = totalSpells + #grp.spells
            table.insert(lines, "### " .. grp.title .. " (" .. #grp.spells .. ")")
            for _, sp in ipairs(grp.spells) do
                table.insert(lines, string.format("  • %s%s", sp.name, sp.meta))
            end
            table.insert(lines, "")
        end
    end

    if totalSpells == 0 then
        table.insert(lines, "_No spells found in spellbook._")
    end

    table.insert(lines, "---")
    table.insert(lines, "_Exported via GrimfallHelper v" .. C.ADDON_VERSION .. " for WoW 3.3.5a_")

    return table.concat(lines, "\n")
end

-- Open the Dedicated Export Page in the Dashboard
function BE:OpenExportPage()
    if GH.UI and GH.UI.MainFrame then
        if not GrimfallHelperMainFrame:IsShown() then
            GH.UI.MainFrame:Toggle()
        end
        GH.UI.MainFrame:SelectTab(3)
    end
end

-- Initialize
function BE:Initialize()
    -- Ready
end

-- Diagnostic Command to verify rune scanning in chat
function BE:DebugRunes()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r --- Rune Scanner Diagnostic ---")
    GrimfallHelperCharDB = GrimfallHelperCharDB or {}
    GrimfallHelperCharDB.runeDebug = {}
    local dbg = GrimfallHelperCharDB.runeDebug

    -- Test Grimfall MysticEnchant / Freepick APIs
    local fnGetKnownRE = (type(MysticEnchant_GetKnownRESpellIds) == "function" and MysticEnchant_GetKnownRESpellIds)
                      or (type(_G.MysticEnchant_GetKnownRESpellIds) == "function" and _G.MysticEnchant_GetKnownRESpellIds)
    local fnBuildGroups = (type(ClasslessFrame_Freepick_BuildRuneGroups) == "function" and ClasslessFrame_Freepick_BuildRuneGroups)
                       or (type(_G.ClasslessFrame_Freepick_BuildRuneGroups) == "function" and _G.ClasslessFrame_Freepick_BuildRuneGroups)
    local fnGetKnownRuneIDs = (type(ClasslessFrame_Freepick_GetKnownRuneSpellIDs) == "function" and ClasslessFrame_Freepick_GetKnownRuneSpellIDs)
                           or (type(_G.ClasslessFrame_Freepick_GetKnownRuneSpellIDs) == "function" and _G.ClasslessFrame_Freepick_GetKnownRuneSpellIDs)

    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Grimfall APIs: MysticEnchant_GetKnownRESpellIds=%s | BuildRuneGroups=%s | Freepick_GetKnownRuneIDs=%s",
        type(fnGetKnownRE), type(fnBuildGroups), type(fnGetKnownRuneIDs)))

    if fnGetKnownRE then
        pcall(function()
            local reIds = fnGetKnownRE()
            if type(reIds) == "table" then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  MysticEnchant_GetKnownRESpellIds: count=%d", #reIds))
                for idx, sid in ipairs(reIds) do
                    local sName = GetSpellInfo(sid) or ("Spell " .. sid)
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("    RE[%d]: |cff00FF96%s|r (ID: %s)", idx, sName, tostring(sid)))
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("  MysticEnchant_GetKnownRESpellIds returned " .. tostring(reIds))
            end
        end)
    end

    if fnBuildGroups then
        pcall(function()
            local groups = fnBuildGroups()
            if type(groups) == "table" then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  ClasslessFrame_Freepick_BuildRuneGroups: groups=%d", #groups))
                for gIdx, grp in ipairs(groups) do
                    local count = grp.enchants and #grp.enchants or 0
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("    Group[%d]: %s (%d/%d)", gIdx, grp.quality or "Tier", count, grp.limit or 0))
                    for eIdx, enc in ipairs(grp.enchants or {}) do
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("      • |cff00FF96%s|r [%s] (ID: %s)", enc.name or "Rune", enc.qualityName or grp.quality or "Rare", tostring(enc.spellID)))
                    end
                end
            end
        end)
    end

    local freepickFrame = _G.ClasslessFrame_Freepick
    local frameState = freepickFrame and (freepickFrame:IsShown() and "Shown" or "Hidden") or "Nil"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  ClasslessFrame_Freepick: %s", frameState))

    local fnGetActive = (type(GetActiveSkillCardBySlot) == "function" and GetActiveSkillCardBySlot) or (type(SkillCard_GetActiveCardBySlot) == "function" and SkillCard_GetActiveCardBySlot)
    local fnGetCards = (type(GetSkillCards) == "function" and GetSkillCards) or (type(SkillCard_GetCards) == "function" and SkillCard_GetCards)
    local fnGetNum = (type(GetNumActiveSkillCards) == "function" and GetNumActiveSkillCards) or (type(SkillCard_GetNumActiveCards) == "function" and SkillCard_GetNumActiveCards)
    local fnGetMax = (type(GetMaxActiveSkillCards) == "function" and GetMaxActiveSkillCards) or (type(SkillCard_GetMaxActiveCards) == "function" and SkillCard_GetMaxActiveCards)

    local numActive = fnGetNum and fnGetNum() or "N/A"
    local maxActive = fnGetMax and fnGetMax() or "N/A"
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  SkillCard APIs: GetNumActive=%s | GetMaxActive=%s", tostring(numActive), tostring(maxActive)))
    dbg.numActive = numActive
    dbg.maxActive = maxActive

    if fnGetCards then
        pcall(function()
            local cards = fnGetCards()
            dbg.cardsType = type(cards)
            if type(cards) == "table" then
                dbg.cardsCount = #cards
                local activeCount = 0
                for _, c in pairs(cards) do
                    if type(c) == "table" and c.Active then activeCount = activeCount + 1 end
                end
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  GetSkillCards: total=%d, active=%d", #cards, activeCount))
                dbg.activeCount = activeCount
            end
        end)
    end

    -- Test slots
    dbg.slots = {}
    if fnGetActive then
        for s = 0, 18 do
            pcall(function()
                local c = fnGetActive(s)
                if c then
                    table.insert(dbg.slots, { slot = s, name = c.CardName, id = c.SpellID, active = c.Active, rarity = c.Rarity })
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Slot %d: %s [ID:%s Active:%s]", s, tostring(c.CardName), tostring(c.SpellID), tostring(c.Active)))
                end
            end)
        end
    end

    -- Run CollectRunes
    local runes = self:CollectRunes()
    DEFAULT_CHAT_FRAME:AddMessage("  Total Active Runes Detected: |cffFFFF00" .. #runes .. "|r")
    for i, r in ipairs(runes) do
        local slotStr = r.slot and (" Slot:" .. r.slot) or ""
        local idStr = r.spellId and (" ID:" .. r.spellId) or ""
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  [%d] |cff00FF96%s|r |cffFFFF00[%s]|r%s%s", i, r.name, r.rarity or "Rare", slotStr, idStr))
    end

    -- Check EnumerateFrames for any frames containing "Rune" or "Classless"
    dbg.frames = {}
    local fCount = 0
    pcall(function()
        local f = EnumerateFrames()
        while f do
            local fn = f:GetName() or ""
            local txt = nil
            if f.GetRegions then
                for _, r in ipairs({ f:GetRegions() }) do
                    if r and r.GetObjectType and r:IsObjectType("FontString") then
                        local t = r:GetText()
                        if t and (string.find(t, "Active Runes") or string.find(t, "Deepening Frost") or string.find(t, "Blood Strike") or (string.find(t, "Classless") and not string.find(t, "GrimfallHelper"))) then
                            txt = t
                            break
                        end
                    end
                end
            end
            if txt or (fn ~= "" and (string.find(string.lower(fn), "classless") or string.find(string.lower(fn), "rune") or string.find(string.lower(fn), "skillcard")) and not string.find(string.lower(fn), "grimfallhelper")) then
                fCount = fCount + 1
                local p = f:GetParent() and f:GetParent():GetName() or "<unnamed>"
                table.insert(dbg.frames, { name = fn, parent = p, text = txt })
                if fCount <= 8 then
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Frame: |cff00FF96%s|r Text: |cffFFFF00%s|r", fn ~= "" and fn or "<unnamed>", txt or ""))
                end
            end
            f = EnumerateFrames(f)
        end
    end)
    DEFAULT_CHAT_FRAME:AddMessage("  Matched UI Frames: " .. fCount)

    -- Mouse focus frame
    local mf = GetMouseFocus()
    if mf then
        local mfn = mf:GetName() or "<unnamed>"
        local mfp = mf:GetParent() and mf:GetParent():GetName() or "<no-parent>"
        DEFAULT_CHAT_FRAME:AddMessage("  Hovered Frame: " .. mfn .. " (Parent: " .. mfp .. ")")
        dbg.mouseFocus = { name = mfn, parent = mfp }
    end
end

-- Explicit API Alias
BE.CollectActiveRunes = BE.CollectRunes

