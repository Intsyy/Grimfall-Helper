-- ============================================================================
-- GrimfallHelper: Modules/StatInspector.lua
-- Hybrid Stat & Rating Cap Engine (AP vs SP, Hit/Crit Caps, Defense 540, MP5)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.StatInspector = {}
local SI = GH.StatInspector
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

-- CR Combat Rating Constants for 3.3.5a
local CR_DEFENSE_SKILL = 2
local CR_HIT_MELEE = 6
local CR_HIT_RANGED = 7
local CR_HIT_SPELL = 8
local CR_CRIT_MELEE = 9
local CR_CRIT_SPELL = 11

-- Calculate full stat summary
function SI:GetStats()
    local level = UnitLevel("player") or 80

    -- 1. Attack Power
    local baseAP, posAP, negAP = UnitAttackPower("player")
    local totalAP = (baseAP or 0) + (posAP or 0) + (negAP or 0)

    local baseRAP, posRAP, negRAP = UnitRangedAttackPower("player")
    local totalRAP = (baseRAP or 0) + (posRAP or 0) + (negRAP or 0)

    -- 2. Spell Power (Scan schools 2 to 7 and get max)
    local maxSP = 0
    for school = 2, 7 do
        local sp = GetSpellBonusDamage(school) or 0
        if sp > maxSP then maxSP = sp end
    end
    local bonusHealing = GetSpellBonusHealing() or maxSP

    -- 3. Hit Ratings & Caps
    local meleeHitRating = GetCombatRating(CR_HIT_MELEE) or 0
    local meleeHitPct = GetCombatRatingBonus(CR_HIT_MELEE) or 0
    local meleeHitCap = C.STAT_CAPS.MELEE_HIT_CAP
    local meleeHitRemaining = math.max(0, meleeHitCap - meleeHitPct)

    local spellHitRating = GetCombatRating(CR_HIT_SPELL) or 0
    local spellHitPct = GetCombatRatingBonus(CR_HIT_SPELL) or 0
    local spellHitCap = C.STAT_CAPS.SPELL_HIT_CAP
    local spellHitRemaining = math.max(0, spellHitCap - spellHitPct)

    -- 4. Crit Ratings
    local meleeCritPct = GetCritChance() or 0
    local maxSpellCritPct = 0
    for school = 2, 7 do
        local sc = GetSpellCritChance(school) or 0
        if sc > maxSpellCritPct then maxSpellCritPct = sc end
    end

    -- 5. Defense Rating & Boss Crit Immunity
    local baseDef, armorDef = UnitDefense("player")
    local totalDef = (baseDef or 0) + (armorDef or 0)
    local defRating = GetCombatRating(CR_DEFENSE_SKILL) or 0
    local defCap = C.STAT_CAPS.DEFENSE_CAP
    local defRemaining = math.max(0, defCap - totalDef)
    local isCritImmune = totalDef >= defCap

    -- 6. Armor & Damage Reduction
    local _, effectiveArmor = UnitArmor("player")
    effectiveArmor = effectiveArmor or 0
    local armorK = 400 + (85 * level)
    local armorReduction = (effectiveArmor / (effectiveArmor + armorK)) * 100
    if armorReduction > 75 then armorReduction = 75 end -- 75% hard cap in 3.3.5a

    -- 7. Mana Regeneration (Inside & Outside 5-second rule)
    local baseRegen, castingRegen = GetManaRegen()
    local mp5Out = math.floor((baseRegen or 0) * 5)
    local mp5In = math.floor((castingRegen or 0) * 5)

    -- 8. Hybrid Gearing Advice
    local advice = ""
    if maxSP > (totalAP * 0.85) then
        advice = "Primary Caster Scaling: Prioritize Spell Power, Spell Hit (17% cap), and Spell Crit/Haste."
    elseif totalAP > (maxSP * 1.5) then
        advice = "Primary Physical Scaling: Prioritize Attack Power, Armor Penetration, and Melee Hit (8% cap)."
    else
        advice = "Hybrid Cross-Scaling: Balanced between AP and SP. Look for hybrid spell-blade weapons and multi-school enhancements."
    end

    return {
        level = level,
        ap = totalAP,
        rap = totalRAP,
        sp = maxSP,
        healing = bonusHealing,
        meleeHitRating = meleeHitRating,
        meleeHitPct = meleeHitPct,
        meleeHitCap = meleeHitCap,
        meleeHitRemaining = meleeHitRemaining,
        spellHitRating = spellHitRating,
        spellHitPct = spellHitPct,
        spellHitCap = spellHitCap,
        spellHitRemaining = spellHitRemaining,
        meleeCritPct = meleeCritPct,
        spellCritPct = maxSpellCritPct,
        defenseSkill = totalDef,
        defenseRating = defRating,
        defenseCap = defCap,
        defenseRemaining = defRemaining,
        isCritImmune = isCritImmune,
        armor = effectiveArmor,
        armorReduction = armorReduction,
        mp5Out = mp5Out,
        mp5In = mp5In,
        advice = advice,
    }
end

-- Event Listeners
EventBus:Register("PLAYER_ENTERING_WORLD", function()
    EventBus:Fire("GH_STATS_UPDATED")
end)

EventBus:Register("PLAYER_EQUIPMENT_CHANGED", function()
    EventBus:Fire("GH_STATS_UPDATED")
end)

EventBus:Register("UNIT_AURA", function(event, unit)
    if unit == "player" then
        EventBus:Fire("GH_STATS_UPDATED")
    end
end)
