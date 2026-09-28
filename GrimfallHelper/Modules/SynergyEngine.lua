-- ============================================================================
-- GrimfallHelper: Modules/SynergyEngine.lua
-- Build Synergy Analyzer, Cross-Class Combo Detector, and Conflict Warnings
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Synergy = {}
local Synergy = GH.Synergy
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

Synergy.activeSynergies = {}
Synergy.warnings = {}
Synergy.recommendations = {}
Synergy.buildScore = 0
Synergy.buildRating = "C"
Synergy.archetypeTitle = "Novice Adventurer"

-- Check equipped item sub-types (Shield, Dagger, Ranged)
local function CheckEquipment()
    local hasShield = false
    local hasDagger = false
    local hasRanged = false

    -- Main hand (Slot 16)
    local mhLink = GetInventoryItemLink("player", 16)
    if mhLink then
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(mhLink)
        if itemSubType == "Daggers" or itemSubType == "Dagger" then
            hasDagger = true
        end
    end

    -- Off hand (Slot 17)
    local ohLink = GetInventoryItemLink("player", 17)
    if ohLink then
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(ohLink)
        if itemSubType == "Shields" or itemSubType == "Shield" then
            hasShield = true
        end
    end

    -- Ranged slot (Slot 18)
    local rangedLink = GetInventoryItemLink("player", 18)
    if rangedLink then
        local _, _, _, _, _, itemType, itemSubType = GetItemInfo(rangedLink)
        if itemSubType == "Bows" or itemSubType == "Guns" or itemSubType == "Crossbows" or itemSubType == "Thrown" then
            hasRanged = true
        end
    end

    return hasShield, hasDagger, hasRanged
end

-- Generate a dynamic hybrid archetype name
local function GenerateArchetypeTitle(topSynergies)
    if #topSynergies == 0 then
        return "Wildcard Initiate"
    elseif #topSynergies == 1 then
        return topSynergies[1].name .. " Specialist"
    else
        local prefix = {
            ["IGNITE_BURST"]   = "Flame-Forged",
            ["FROST_SHATTER"]  = "Frost-Bound",
            ["BLEED_MANGLE"]   = "Blood-Rending",
            ["HOLY_CRUSADER"]  = "Radiant",
            ["AFFLICTION_DRAIN"]= "Soul-Draining",
            ["NATURE_STORM"]   = "Storm-Calling",
            ["STEALTH_AMBUSH"] = "Shadow",
            ["IRON_FORTRESS"]  = "Ironclad",
        }
        local suffix = {
            ["IGNITE_BURST"]   = "Pyromancer",
            ["FROST_SHATTER"]  = "Gladiator",
            ["BLEED_MANGLE"]   = "Berserker",
            ["HOLY_CRUSADER"]  = "Crusader",
            ["AFFLICTION_DRAIN"]= "Harvester",
            ["NATURE_STORM"]   = "Shamanist",
            ["STEALTH_AMBUSH"] = "Assassin",
            ["IRON_FORTRESS"]  = "Juggernaut",
        }
        local p = prefix[topSynergies[1].id] or topSynergies[1].name
        local s = suffix[topSynergies[2].id] or topSynergies[2].name
        return p .. " " .. s
    end
end

-- Analyze entire build
function Synergy:Analyze()
    table.wipe(self.activeSynergies)
    table.wipe(self.warnings)
    table.wipe(self.recommendations)

    if not GH.Spellbook then return end

    local totalWeight = 0
    local rawScore = 0
    local hasShield, hasDagger, hasRanged = CheckEquipment()

    -- 1. Evaluate Synergies
    for _, syn in ipairs(C.SYNERGIES) do
        totalWeight = totalWeight + syn.weight
        local matched = {}
        local missing = {}

        for _, spellName in ipairs(syn.coreSpells) do
            if GH.Spellbook:HasSpell(spellName) then
                table.insert(matched, spellName)
            else
                table.insert(missing, spellName)
            end
        end

        local count = #matched
        if count >= syn.minMatch then
            local ratio = count / #syn.coreSpells
            local scoreContribution = syn.weight * (0.6 + 0.4 * ratio)
            rawScore = rawScore + scoreContribution

            table.insert(self.activeSynergies, {
                id = syn.id,
                name = syn.name,
                color = syn.color,
                icon = syn.icon,
                description = syn.description,
                matched = matched,
                missing = missing,
                count = count,
                total = #syn.coreSpells,
            })

            -- Recommend the top missing spell if synergy is close to complete
            if #missing > 0 and count >= 2 then
                table.insert(self.recommendations, {
                    type = "COMPLETE_SYNERGY",
                    synergy = syn.name,
                    spell = missing[1],
                    color = syn.color,
                    text = "Unlock " .. Utils:Colorize(missing[1], syn.color) .. " to amplify your " .. syn.name .. " synergy!",
                })
            end
        elseif count == 1 and #self.recommendations < 4 then
            -- Near synergy
            table.insert(self.recommendations, {
                type = "NEAR_SYNERGY",
                synergy = syn.name,
                spell = syn.coreSpells[2] or syn.coreSpells[1],
                color = syn.color,
                text = "Add " .. Utils:Colorize(syn.coreSpells[2] or syn.coreSpells[1], syn.color) .. " to activate " .. syn.name .. ".",
            })
        end
    end

    -- Sort active synergies by matched count
    table.sort(self.activeSynergies, function(a, b)
        return a.count > b.count
    end)

    -- 2. Detect Anti-Synergies & Equipment Conflicts
    if not hasShield then
        local shieldSpells = { "shield slam", "shield wall", "shield block", "spell reflection" }
        for _, s in ipairs(shieldSpells) do
            if GH.Spellbook:HasSpell(s) then
                table.insert(self.warnings, {
                    severity = "HIGH",
                    color = "FF3333",
                    text = "Equip a Shield in off-hand! |cffffffff[" .. s .. "]|r is unusable without a shield.",
                })
                break
            end
        end
    end

    if not hasDagger then
        local daggerSpells = { "backstab", "ambush" }
        for _, s in ipairs(daggerSpells) do
            if GH.Spellbook:HasSpell(s) then
                table.insert(self.warnings, {
                    severity = "HIGH",
                    color = "FF3333",
                    text = "Equip a Dagger in main hand! |cffffffff[" .. s .. "]|r requires a dagger.",
                })
                break
            end
        end
    end

    if not hasRanged then
        local rangedSpells = { "aimed shot", "arcane shot", "multi-shot", "chimera shot", "explosive shot" }
        for _, s in ipairs(rangedSpells) do
            if GH.Spellbook:HasSpell(s) then
                table.insert(self.warnings, {
                    severity = "HIGH",
                    color = "FF3333",
                    text = "Equip a Bow, Gun or Crossbow! |cffffffff[" .. s .. "]|r requires a ranged weapon.",
                })
                break
            end
        end
    end

    -- Check Rage Resource Balance: Heavy Rage spenders with 0 rage generators
    local hasRageSpenders = GH.Spellbook:HasSpell("mortal strike") or GH.Spellbook:HasSpell("whirlwind") or GH.Spellbook:HasSpell("bloodthirst") or GH.Spellbook:HasSpell("slam")
    local hasRageBuilders = GH.Spellbook:HasSpell("charge") or GH.Spellbook:HasSpell("bloodrage") or GH.Spellbook:HasSpell("intercept")
    if hasRageSpenders and not hasRageBuilders then
        table.insert(self.warnings, {
            severity = "MEDIUM",
            color = "FF9900",
            text = "Rage starvation risk: You have heavy Rage spenders but no Charge or Bloodrage to generate opener rage.",
        })
    end

    -- 3. Calculate Final Build Score & Rating
    local maxPossible = 65 -- Normalized theoretical max synergy baseline
    local normalized = math.min(100, math.floor((rawScore / maxPossible) * 100))
    if #self.warnings > 0 then
        normalized = math.max(10, normalized - (#self.warnings * 10))
    end
    self.buildScore = normalized

    if normalized >= 85 then
        self.buildRating = "S"
    elseif normalized >= 70 then
        self.buildRating = "A"
    elseif normalized >= 50 then
        self.buildRating = "B"
    else
        self.buildRating = "C"
    end

    self.archetypeTitle = GenerateArchetypeTitle(self.activeSynergies)

    Utils:Debug("Build Analyzed: Score " .. self.buildScore .. " (" .. self.buildRating .. "), Archetype: " .. self.archetypeTitle)
    EventBus:Fire("GH_SYNERGY_UPDATED")
end

-- Event Listeners
EventBus:RegisterCustom("GH_SPELLBOOK_UPDATED", function()
    Synergy:Analyze()
end)

EventBus:Register("PLAYER_EQUIPMENT_CHANGED", function()
    Synergy:Analyze()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    Synergy:Analyze()
end)
