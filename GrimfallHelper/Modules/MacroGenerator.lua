-- ============================================================================
-- GrimfallHelper: Modules/MacroGenerator.lua
-- 1-Click Smart Macro Generation (Reroll, Hybrid Attack, Panic Defensives, Burst)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.MacroGenerator = {}
local MG = GH.MacroGenerator
local Utils = GH.Utils

-- Create or update a macro in the character-specific macro tab
function MG:CreateOrUpdate(macroName, iconTexture, macroBody)
    if InCombatLockdown() then
        Utils:Print("|cffFF3333Cannot create macros while in combat!|r")
        return false
    end

    local existingIndex = GetMacroIndexByName(macroName)

    if existingIndex and existingIndex > 0 then
        -- Update existing
        EditMacro(existingIndex, macroName, iconTexture or "INV_Misc_QuestionMark", macroBody)
        Utils:PlaySound("CLICK")
        Utils:Print("Updated macro |cffFFFF00[" .. macroName .. "]|r.")
        return true
    else
        -- Create new (Check character macro limit of 18)
        local _, perCharNum = GetNumMacros()
        if perCharNum >= 18 then
            Utils:Print("|cffFF3333Character macro list is full (18/18). Please delete an unused macro first.|r")
            return false
        end

        local newId = CreateMacro(macroName, iconTexture or "INV_Misc_QuestionMark", macroBody, 1)
        if newId and newId > 0 then
            Utils:PlaySound("CLICK")
            Utils:Print("Created macro |cff00FF96[" .. macroName .. "]|r! Open |cffFFFF00/macro|r to drag it onto your action bars.")
            return true
        else
            Utils:Print("|cffFF3333Failed to create macro [" .. macroName .. "].|r")
            return false
        end
    end
end

-- 1. Wildcard Fast Reroll Macro
function MG:GenerateRerollMacro()
    local body = "#showtooltip\n/gf use"
    return self:CreateOrUpdate("GH_Reroll", "INV_Scroll_03", body)
end

-- 2. Smart Hybrid Attack Macro
function MG:GenerateSmartAttackMacro()
    local body = "#showtooltip\n/startattack\n/cast [harm,nodead] Auto Shot\n/cast [harm,nodead] Shoot\n/cast [harm,nodead] Attack"
    return self:CreateOrUpdate("GH_SmartAttack", "Ability_DualWield", body)
end

-- 3. Panic Defensive Sequencing Macro
function MG:GeneratePanicMacro()
    local defensives = {}
    local cand = { "Divine Shield", "Ice Block", "Dispersion", "Shield Wall", "Barkskin", "Survival Instincts", "Last Stand", "Deterrence", "Evasion" }

    for _, spell in ipairs(cand) do
        if GH.Spellbook and GH.Spellbook:HasSpell(spell) then
            table.insert(defensives, "/cast " .. spell)
        end
    end

    if #defensives == 0 then
        table.insert(defensives, "/cast Divine Shield")
        table.insert(defensives, "/cast Shield Wall")
    end

    local body = "#showtooltip\n/stopcasting\n" .. table.concat(defensives, "\n")
    return self:CreateOrUpdate("GH_Panic", "Spell_Holy_DivineIntervention", body)
end

-- 4. Offensive Burst Cooldown Stacker Macro
function MG:GenerateBurstMacro()
    local burstSpells = {}
    local cand = { "Bloodlust", "Heroism", "Avenging Wrath", "Berserker Rage", "Recklessness", "Adrenaline Rush", "Bestial Wrath", "Death Wish" }

    for _, spell in ipairs(cand) do
        if GH.Spellbook and GH.Spellbook:HasSpell(spell) then
            table.insert(burstSpells, "/cast " .. spell)
        end
    end

    if #burstSpells == 0 then
        table.insert(burstSpells, "/cast Avenging Wrath")
        table.insert(burstSpells, "/cast Bloodlust")
    end

    table.insert(burstSpells, "/use 13")
    table.insert(burstSpells, "/use 14")

    local body = "#showtooltip\n" .. table.concat(burstSpells, "\n")
    return self:CreateOrUpdate("GH_Burst", "Spell_Nature_BloodLust", body)
end
