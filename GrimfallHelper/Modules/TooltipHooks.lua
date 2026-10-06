-- ============================================================================
-- GrimfallHelper: Modules/TooltipHooks.lua
-- Universal GameTooltip Hooks for Classless Metadata & Synergies
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.TooltipHooks = {}
local TH = GH.TooltipHooks
local C = GH.Constants
local Utils = GH.Utils

-- Check equipped item sub-types
local function CheckEquipmentForWarnings(meta)
    if not meta then return nil end

    if meta.reqShield then
        local ohLink = GetInventoryItemLink("player", 17)
        local hasShield = false
        if ohLink then
            local _, _, _, _, _, _, subType = GetItemInfo(ohLink)
            if subType == "Shields" or subType == "Shield" then
                hasShield = true
            end
        end
        if not hasShield then
            return "|cffFF3333⚠ Requirement Alert: Requires Shield in off-hand!|r"
        end
    end

    if meta.reqDagger then
        local mhLink = GetInventoryItemLink("player", 16)
        local hasDagger = false
        if mhLink then
            local _, _, _, _, _, _, subType = GetItemInfo(mhLink)
            if subType == "Daggers" or subType == "Dagger" then
                hasDagger = true
            end
        end
        if not hasDagger then
            return "|cffFF3333⚠ Requirement Alert: Requires Dagger in main hand!|r"
        end
    end

    if meta.reqRanged then
        local rangedLink = GetInventoryItemLink("player", 18)
        local hasRanged = false
        if rangedLink then
            local _, _, _, _, _, _, subType = GetItemInfo(rangedLink)
            if subType == "Bows" or subType == "Guns" or subType == "Crossbows" or subType == "Thrown" then
                hasRanged = true
            end
        end
        if not hasRanged then
            return "|cffFF3333⚠ Requirement Alert: Requires Bow, Gun, or Crossbow!|r"
        end
    end

    return nil
end

-- Injects Grimfall classless metadata into any tooltip
local function EnhanceTooltipWithSpell(tooltip, spellName)
    if not spellName or spellName == "" then return end
    if not GH.Config:Get("enhanceTooltips", true) then return end

    local cleanName = Utils:NormalizeName(spellName)
    local meta = C.SPELL_CATALOG[cleanName]

    local addedLine = false

    -- 1. Class, School, and Role Badges
    if meta then
        local classData = C.CLASSES[meta.class] or { name = meta.class, color = "FFFFFF" }
        local schoolData = C.SCHOOLS[meta.school] or { color = "FFFFFF" }
        local catLabel = C.CATEGORIES[meta.category] or meta.category

        tooltip:AddLine(" ")
        tooltip:AddDoubleLine(
            "|cff00FF96[Grimfall Classless]|r",
            "|cff" .. classData.color .. classData.name .. "|r",
            1, 1, 1, 1, 1, 1
        )
        tooltip:AddDoubleLine(
            "School / Role:",
            "|cff" .. schoolData.color .. meta.school .. "|r |cff888888•|r " .. catLabel,
            0.7, 0.7, 0.7, 1, 1, 1
        )
        addedLine = true
    end

    -- 3. Synergies Triggered
    local foundSynergies = {}
    for _, syn in ipairs(C.SYNERGIES) do
        for _, s in ipairs(syn.coreSpells) do
            if s == cleanName then
                local isActive = false
                if GH.Synergy and GH.Synergy.activeSynergies then
                    for _, activeSyn in ipairs(GH.Synergy.activeSynergies) do
                        if activeSyn.id == syn.id then
                            isActive = true
                            break
                        end
                    end
                end
                table.insert(foundSynergies, {
                    name = syn.name,
                    color = syn.color,
                    active = isActive
                })
                break
            end
        end
    end

    if #foundSynergies > 0 then
        if not addedLine then tooltip:AddLine(" ") addedLine = true end
        for _, syn in ipairs(foundSynergies) do
            local status = syn.active and "|cff00FF96(Combo Active)|r" or "|cffAAAAAA(Synergy Piece)|r"
            tooltip:AddDoubleLine(
                "Synergy Engine:",
                "|cff" .. syn.color .. syn.name .. "|r " .. status,
                0.7, 0.7, 0.7, 1, 1, 1
            )
        end
    end

    -- 4. Equipment Warnings
    local warn = CheckEquipmentForWarnings(meta)
    if warn then
        tooltip:AddLine(warn)
        addedLine = true
    end

    if addedLine then
        tooltip:Show()
    end
end

-- Hook GameTooltip SetSpell
hooksecurefunc(GameTooltip, "SetSpell", function(self, spellIndex, bookType)
    local name = GetSpellName(spellIndex, bookType or BOOKTYPE_SPELL)
    EnhanceTooltipWithSpell(self, name)
end)

-- Hook GameTooltip SetAction
hooksecurefunc(GameTooltip, "SetAction", function(self, slot)
    local actionType, id = GetActionInfo(slot)
    if actionType == "spell" and id then
        local name = GetSpellInfo(id)
        EnhanceTooltipWithSpell(self, name)
    end
end)

-- Hook ItemRefTooltip SetHyperlink (Chat links)
hooksecurefunc(ItemRefTooltip, "SetHyperlink", function(self, link)
    if link and string.find(link, "spell:") then
        local spellId = string.match(link, "spell:(%d+)")
        if spellId then
            local name = GetSpellInfo(tonumber(spellId))
            EnhanceTooltipWithSpell(self, name)
        end
    end
end)

-- Hook GameTooltip SetHyperlink
hooksecurefunc(GameTooltip, "SetHyperlink", function(self, link)
    if link and string.find(link, "spell:") then
        local spellId = string.match(link, "spell:(%d+)")
        if spellId then
            local name = GetSpellInfo(tonumber(spellId))
            EnhanceTooltipWithSpell(self, name)
        end
    end
end)
