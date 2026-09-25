-- ============================================================================
-- GrimfallHelper: Modules/BuildEvaluator.lua
-- Build Value & Power Scoring Engine (Rune Tiers, Role Archetype & Synergies)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.BuildEvaluator = {}
local BEval = GH.BuildEvaluator

local QUALITY_WEIGHTS = {
    [5] = 100, -- Legendary
    [4] = 50,  -- Epic
    [3] = 25,  -- Rare
    [2] = 10,  -- Uncommon
    [1] = 5,   -- Common
}

local QUALITY_NAMES = {
    [5] = "Legendary",
    [4] = "Epic",
    [3] = "Rare",
    [2] = "Uncommon",
    [1] = "Common",
}

-- Evaluate a build data structure (from local player, inspected player, or imported code)
function BEval:EvaluateBuild(buildData)
    if not buildData then return nil end

    local runes = buildData.runes or {}
    local stats = buildData.stats or {}
    local talents = buildData.talents or {}

    local runeScore = 0
    local counts = { [5] = 0, [4] = 0, [3] = 0, [2] = 0, [1] = 0 }
    local totalRunes = 0

    local archetypeKeywords = {
        tank = 0,
        healer = 0,
        melee = 0,
        caster = 0,
        fire = 0,
        frost = 0,
        shadow = 0,
        holy = 0,
        nature = 0,
        arcane = 0,
        bleed = 0,
        crit = 0,
    }

    for _, r in ipairs(runes) do
        totalRunes = totalRunes + 1
        local q = tonumber(r.quality) or 2
        counts[q] = (counts[q] or 0) + 1
        runeScore = runeScore + (QUALITY_WEIGHTS[q] or 10)

        local desc = string.lower((r.desc or "") .. " " .. (r.name or ""))
        if string.find(desc, "block") or string.find(desc, "threat") or string.find(desc, "armor") or string.find(desc, "defense") or string.find(desc, "shield") or string.find(desc, "damage taken") then
            archetypeKeywords.tank = archetypeKeywords.tank + 2
        end
        if string.find(desc, "heal") or string.find(desc, "regrowth") or string.find(desc, "flash heal") or string.find(desc, "cleanse") then
            archetypeKeywords.healer = archetypeKeywords.healer + 2
        end
        if string.find(desc, "melee") or string.find(desc, "attack power") or string.find(desc, "weapon") or string.find(desc, "strike") or string.find(desc, "sinister") then
            archetypeKeywords.melee = archetypeKeywords.melee + 2
        end
        if string.find(desc, "spell power") or string.find(desc, "spell damage") or string.find(desc, "mana") then
            archetypeKeywords.caster = archetypeKeywords.caster + 2
        end
        if string.find(desc, "fire") then archetypeKeywords.fire = archetypeKeywords.fire + 1 end
        if string.find(desc, "frost") or string.find(desc, "chill") then archetypeKeywords.frost = archetypeKeywords.frost + 1 end
        if string.find(desc, "shadow") then archetypeKeywords.shadow = archetypeKeywords.shadow + 1 end
        if string.find(desc, "holy") then archetypeKeywords.holy = archetypeKeywords.holy + 1 end
        if string.find(desc, "bleed") then archetypeKeywords.bleed = archetypeKeywords.bleed + 1 end
        if string.find(desc, "critical") or string.find(desc, "crit") then archetypeKeywords.crit = archetypeKeywords.crit + 1 end
    end

    -- Stat influence on archetype
    local ap = tonumber(stats.ap) or 0
    local sp = tonumber(stats.sp) or 0
    local armor = tonumber(stats.armor) or 0
    local defense = tonumber(stats.defense) or 0

    if ap > sp + 200 then
        archetypeKeywords.melee = archetypeKeywords.melee + 3
    elseif sp > ap + 100 then
        archetypeKeywords.caster = archetypeKeywords.caster + 3
    end

    if defense > 350 or armor > 8000 then
        archetypeKeywords.tank = archetypeKeywords.tank + 3
    end

    -- Determine Role Archetype
    local role = "Hybrid Adventurer"
    local subRole = ""

    if archetypeKeywords.tank >= archetypeKeywords.healer and archetypeKeywords.tank >= archetypeKeywords.melee and archetypeKeywords.tank >= archetypeKeywords.caster and archetypeKeywords.tank >= 3 then
        role = "Protection Tank"
    elseif archetypeKeywords.healer >= archetypeKeywords.melee and archetypeKeywords.healer >= archetypeKeywords.caster and archetypeKeywords.healer >= 3 then
        role = "Support Healer"
    elseif archetypeKeywords.caster >= archetypeKeywords.melee and archetypeKeywords.caster >= 3 then
        if archetypeKeywords.frost > archetypeKeywords.fire and archetypeKeywords.frost > archetypeKeywords.shadow then
            role = "Frost Caster DPS"
        elseif archetypeKeywords.fire > archetypeKeywords.frost and archetypeKeywords.fire > archetypeKeywords.shadow then
            role = "Fire Caster DPS"
        elseif archetypeKeywords.shadow > archetypeKeywords.frost and archetypeKeywords.shadow > archetypeKeywords.fire then
            role = "Shadow Caster DPS"
        else
            role = "Magic Caster DPS"
        end
    elseif archetypeKeywords.melee >= 3 then
        if archetypeKeywords.bleed >= 2 then
            role = "Physical Bleed Melee"
        elseif archetypeKeywords.crit >= 2 then
            role = "Crit Burst Melee"
        else
            role = "Melee Bruiser DPS"
        end
    end

    -- Talent points contribution
    local talentCount = tonumber(buildData.talentCount) or 0
    if talentCount == 0 and type(talents) == "table" then
        for _, t in ipairs(talents) do
            if type(t) == "table" and t.points then
                talentCount = talentCount + (t.points or 0)
            elseif type(t) == "table" and t.talents then
                talentCount = talentCount + #(t.talents)
            else
                talentCount = talentCount + 1
            end
        end
    end

    local totalScore = runeScore + (talentCount * 2)

    -- Quality breakdown summary
    local breakdownParts = {}
    if counts[5] > 0 then table.insert(breakdownParts, counts[5] .. " Legendary") end
    if counts[4] > 0 then table.insert(breakdownParts, counts[4] .. " Epic") end
    if counts[3] > 0 then table.insert(breakdownParts, counts[3] .. " Rare") end
    if counts[2] > 0 then table.insert(breakdownParts, counts[2] .. " Uncommon") end
    if counts[1] > 0 then table.insert(breakdownParts, counts[1] .. " Common") end

    local breakdownStr = table.concat(breakdownParts, ", ")
    if breakdownStr == "" then breakdownStr = "No active runes detected" end

    -- Rating Tier
    local ratingTitle = "Initiate"
    local ratingColor = "|cffaaaaaa"
    if totalScore >= 400 then
        ratingTitle = "Mythic Masterwork"
        ratingColor = "|cffff8000" -- Orange
    elseif totalScore >= 250 then
        ratingTitle = "Elite Veteran"
        ratingColor = "|cffa335ee" -- Purple
    elseif totalScore >= 150 then
        ratingTitle = "Seasoned Adventurer"
        ratingColor = "|cff0070dd" -- Blue
    elseif totalScore >= 80 then
        ratingTitle = "Adept"
        ratingColor = "|cff1eff00" -- Green
    end

    return {
        totalScore = totalScore,
        runeScore = runeScore,
        totalRunes = totalRunes,
        counts = counts,
        breakdownStr = breakdownStr,
        role = role,
        ratingTitle = ratingTitle,
        ratingColor = ratingColor,
        talentCount = talentCount,
    }
end
