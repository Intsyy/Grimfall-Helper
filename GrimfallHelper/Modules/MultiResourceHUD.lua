-- ============================================================================
-- GrimfallHelper: Modules/MultiResourceHUD.lua
-- Multi-Resource State Engine (Health, Mana, Rage, Energy, Runic, Combo)
-- and Missing Self-Buff Sentinel for Classless Hybrids
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.ResourceEngine = {}
local RE = GH.ResourceEngine
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Essential Self-Buffs to monitor if known
local ESSENTIAL_SELF_BUFFS = {
    { spell = "inner fire",         aura = "Inner Fire",         icon = "Spell_Holy_InnerFire" },
    { spell = "righteous fury",     aura = "Righteous Fury",     icon = "Spell_Holy_SealOfFury" },
    { spell = "fel armor",          aura = "Fel Armor",          icon = "Spell_Shadow_FelMageArmor" },
    { spell = "demon armor",        aura = "Demon Armor",        icon = "Spell_Shadow_RagingScream" },
    { spell = "molten armor",       aura = "Molten Armor",       icon = "Ability_Mage_MoltenArmor" },
    { spell = "frost armor",        aura = "Frost Armor",        icon = "Spell_Frost_FrostArmor02" },
    { spell = "mage armor",         aura = "Mage Armor",         icon = "Spell_MageArmor" },
    { spell = "lightning shield",   aura = "Lightning Shield",   icon = "Spell_Nature_LightningShield" },
    { spell = "water shield",       aura = "Water Shield",       icon = "Ability_Shaman_WaterShield" },
    { spell = "mark of the wild",   aura = "Mark of the Wild",   icon = "Spell_Nature_Regeneration" },
    { spell = "thorns",             aura = "Thorns",             icon = "Spell_Nature_Thorns" },
    { spell = "horn of winter",     aura = "Horn of Winter",     icon = "Inv_misc_horn_02" },
    { spell = "battle shout",       aura = "Battle Shout",       icon = "Ability_Warrior_BattleShout" },
    { spell = "commanding shout",   aura = "Commanding Shout",   icon = "Ability_Warrior_RallyingCry" },
}

-- Check if player has an aura active by name
local function HasPlayerAura(auraName)
    local i = 1
    local name = UnitBuff("player", i)
    while name do
        if string.lower(name) == string.lower(auraName) then
            return true
        end
        i = i + 1
        name = UnitBuff("player", i)
    end
    return false
end

-- Get Missing Essential Buffs
function RE:GetMissingBuffs()
    local missing = {}
    if not GH.Spellbook or not GH.Config:Get("showBuffSentinel", true) then
        return missing
    end

    -- Skip if dead or mounted
    if UnitIsDeadOrGhost("player") or IsMounted() then
        return missing
    end

    for _, def in ipairs(ESSENTIAL_SELF_BUFFS) do
        if GH.Spellbook:HasSpell(def.spell) then
            if not HasPlayerAura(def.aura) then
                table.insert(missing, def)
            end
        end
    end

    return missing
end

-- Get Current Player Resource Snapshot
function RE:GetSnapshot()
    local hp = UnitHealth("player") or 0
    local hpMax = UnitHealthMax("player") or 1
    local powerType, powerToken = UnitPowerType("player")
    local power = UnitPower("player") or 0
    local powerMax = UnitPowerMax("player") or 1
    local comboPoints = GetComboPoints("player", "target") or 0

    local resInfo = C.RESOURCES[powerType] or { name = powerToken or "Power", color = "FFFFFF", r = 1, g = 1, b = 1 }

    return {
        hp = hp,
        hpMax = hpMax,
        hpPercent = math.floor((hp / hpMax) * 100),
        powerType = powerType,
        powerToken = powerToken,
        power = power,
        powerMax = powerMax,
        powerPercent = powerMax > 0 and math.floor((power / powerMax) * 100) or 0,
        powerName = resInfo.name,
        powerColor = resInfo.color,
        powerR = resInfo.r,
        powerG = resInfo.g,
        powerB = resInfo.b,
        comboPoints = comboPoints,
        missingBuffs = self:GetMissingBuffs(),
    }
end

-- Event Listeners
EventBus:Register("UNIT_POWER", function(event, unit)
    if unit == "player" then
        EventBus:Fire("GH_HUD_UPDATE")
    end
end)

EventBus:Register("UNIT_HEALTH", function(event, unit)
    if unit == "player" then
        EventBus:Fire("GH_HUD_UPDATE")
    end
end)

EventBus:Register("PLAYER_TARGET_CHANGED", function()
    EventBus:Fire("GH_HUD_UPDATE")
end)

EventBus:Register("UNIT_AURA", function(event, unit)
    if unit == "player" then
        EventBus:Fire("GH_HUD_UPDATE")
    end
end)
