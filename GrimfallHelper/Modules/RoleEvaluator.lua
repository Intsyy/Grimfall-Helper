-- ============================================================================
-- GrimfallHelper: Modules/RoleEvaluator.lua
-- Role Auto-Detection, Best Spells Scoring Engine, and "Dream Bar" Populator
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.RoleEvaluator = {}
local RE = GH.RoleEvaluator
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

RE.currentRole = "AUTO" -- "AUTO", "TANK", "MELEE_DPS", "CASTER_DPS", "HEALER", "SOLO_HYBRID"
RE.detectedRole = "SOLO_HYBRID"
RE.bestSpells = {}
RE.dreamBarSlots = {}

-- Supported Roles Metadata
RE.ROLES = {
    ["TANK"]        = { name = "Tank",         color = "C41F3B", desc = "Damage mitigation, high threat generation, block & cooldowns." },
    ["MELEE_DPS"]   = { name = "Melee DPS",    color = "C79C6E", desc = "Physical burst, melee strikes, bleeds, builders and finishers." },
    ["CASTER_DPS"]  = { name = "Caster DPS",   color = "69CCF0", desc = "Spell power nukes, spell crit, DoTs, instant procs & mana burn." },
    ["HEALER"]      = { name = "Healer",       color = "00FF96", desc = "Direct heals, HoTs, shields, AoE group sustain & dispels." },
    ["SOLO_HYBRID"] = { name = "Solo Hybrid",  color = "FFD700", desc = "Balanced self-sufficient build mixing damage, mitigation & self-heals." },
}

-- Detect Role based on gear, stats, and learned spellbook
function RE:DetectRole()
    local hasShield = false
    local ohLink = GetInventoryItemLink("player", 17)
    if ohLink then
        local _, _, _, _, _, _, subType = GetItemInfo(ohLink)
        if subType == "Shields" or subType == "Shield" then
            hasShield = true
        end
    end

    local stats = GH.StatInspector and GH.StatInspector:GetStats()
    local totalAP = stats and stats.ap or 0
    local maxSP = stats and stats.sp or 0

    local healCount = 0
    local tankCount = 0
    local casterCount = 0
    local meleeCount = 0

    if GH.Spellbook and GH.Spellbook.spells then
        for _, sp in ipairs(GH.Spellbook.spells) do
            if sp.category == "HEAL" then
                healCount = healCount + 1
            elseif sp.category == "DEFENSIVE" then
                tankCount = tankCount + 1
            elseif sp.category == "RANGED_NUKE" or (sp.school ~= "Physical" and sp.category == "DOT_BLEED") then
                casterCount = casterCount + 1
            elseif sp.category == "MELEE_NUKE" or (sp.school == "Physical" and sp.category == "DOT_BLEED") then
                meleeCount = meleeCount + 1
            end
        end
    end

    if hasShield and tankCount >= 3 then
        self.detectedRole = "TANK"
    elseif healCount >= 4 and maxSP > totalAP then
        self.detectedRole = "HEALER"
    elseif casterCount > meleeCount and maxSP >= (totalAP * 0.75) then
        self.detectedRole = "CASTER_DPS"
    elseif meleeCount >= casterCount and totalAP >= maxSP then
        self.detectedRole = "MELEE_DPS"
    else
        self.detectedRole = "SOLO_HYBRID"
    end

    return self.detectedRole
end

-- Get Effective Active Role
function RE:GetActiveRole()
    if self.currentRole == "AUTO" then
        return self:DetectRole()
    end
    return self.currentRole
end

-- Spell Evaluation Matrix for Role Slotting
local ROLE_SPELL_MATRIX = {
    ["SPENDER"] = {
        "mortal strike", "bloodthirst", "shield slam", "pyroblast", "chaos bolt", "lava burst",
        "deep freeze", "eviscerate", "ferocious bite", "mind blast", "stormstrike", "aimed shot",
        "chimera shot", "explosive shot", "starfall", "penance"
    },
    ["BUILDER"] = {
        "charge", "bloodrage", "sinister strike", "fireball", "frostbolt", "lightning bolt",
        "smite", "claw", "wrath", "backstab", "icy touch", "plague strike", "crusader strike"
    },
    ["EXECUTE"] = {
        "execute", "hammer of wrath", "kill shot", "shadow word: death"
    },
    ["DOT_BLEED"] = {
        "rend", "rake", "rip", "corruption", "immolate", "curse of agony", "shadow word: pain",
        "vampiric touch", "devouring plague", "serpent sting", "flame shock", "moonfire", "insect swarm"
    },
    ["DEFENSIVE"] = {
        "shield wall", "shield block", "icebound fortitude", "divine shield", "divine protection",
        "barkskin", "dispersion", "evasion", "cloak of shadows", "deterrence", "survival instincts",
        "last stand", "anti-magic shell", "bone shield", "ice barrier", "mana shield"
    },
    ["HEAL_SHIELD"] = {
        "holy shock", "flash of light", "flash heal", "lesser healing wave", "healing touch",
        "regrowth", "power word: shield", "rejuvenation", "renew", "riptide", "death strike", "drain life"
    },
    ["COOLDOWN"] = {
        "bloodlust", "heroism", "avenging wrath", "berserker rage", "recklessness", "adrenaline rush",
        "bestial wrath", "death wish", "rapid fire", "icy veins", "combustion", "blade flurry"
    },
    ["CC_INTERRUPT"] = {
        "pummel", "kick", "wind shear", "counterspell", "mind freeze", "hammer of justice",
        "cheap shot", "kidney shot", "frost nova", "psychic scream", "fear", "blind", "cyclone", "shockwave"
    },
    ["MOBILITY"] = {
        "blink", "shadowstep", "intercept", "intervene", "disengage", "sprint", "ghost wolf"
    },
}

-- Calculate Best Spells for Chosen Role
function RE:EvaluateBestSpells(role)
    role = role or self:GetActiveRole()
    table.wipe(self.bestSpells)
    table.wipe(self.dreamBarSlots)

    if not GH.Spellbook or not GH.Spellbook.highestRanks then
        return self.dreamBarSlots
    end

    local knownHighest = GH.Spellbook.highestRanks
    local synSpells = {}
    if GH.Synergy and GH.Synergy.activeSynergies then
        for _, s in ipairs(GH.Synergy.activeSynergies) do
            for _, spName in ipairs(s.matched) do
                synSpells[Utils:NormalizeName(spName)] = true
            end
        end
    end

    -- Helper to find best matching spell for a category
    local function FindBest(categoryList, excludeMap)
        local bestEntry = nil
        local bestScore = -1

        for _, rawName in ipairs(categoryList) do
            local clean = Utils:NormalizeName(rawName)
            if not excludeMap[clean] and knownHighest[clean] then
                local entry = knownHighest[clean]
                local score = entry.rankNum * 10

                -- Synergy bonus (+50% weight)
                if synSpells[clean] then
                    score = score + 25
                end

                -- Role affinity bonus
                if role == "TANK" and (entry.category == "DEFENSIVE" or entry.reqShield) then
                    score = score + 30
                elseif role == "HEALER" and entry.category == "HEAL" then
                    score = score + 30
                elseif role == "CASTER_DPS" and entry.school ~= "Physical" then
                    score = score + 20
                elseif role == "MELEE_DPS" and entry.category == "MELEE_NUKE" then
                    score = score + 20
                end

                if score > bestScore then
                    bestScore = score
                    bestEntry = entry
                end
            end
        end

        return bestEntry
    end

    local usedSpells = {}

    -- Slot assignments for optimal "Dream Bar"
    local slotPlan = {
        { slot = 1,  name = "Primary Spender / Nuke", list = ROLE_SPELL_MATRIX["SPENDER"] },
        { slot = 2,  name = "Primary Builder / Filler", list = ROLE_SPELL_MATRIX["BUILDER"] },
        { slot = 3,  name = "Secondary Spender",       list = ROLE_SPELL_MATRIX["SPENDER"] },
        { slot = 4,  name = "Execute / Finisher",      list = ROLE_SPELL_MATRIX["EXECUTE"] },
        { slot = 5,  name = "DoT / Bleed Debuff",      list = ROLE_SPELL_MATRIX["DOT_BLEED"] },
        { slot = 6,  name = "CC / Interrupt",          list = ROLE_SPELL_MATRIX["CC_INTERRUPT"] },
        { slot = 7,  name = "Mobility / Gap Closer",   list = ROLE_SPELL_MATRIX["MOBILITY"] },
        { slot = 8,  name = "Defensive Cooldown",      list = ROLE_SPELL_MATRIX["DEFENSIVE"] },
        { slot = 9,  name = "Emergency Heal / Shield", list = ROLE_SPELL_MATRIX["HEAL_SHIELD"] },
        { slot = 10, name = "Big Offensive Cooldown",  list = ROLE_SPELL_MATRIX["COOLDOWN"] },
    }

    -- If Execute is missing, fallback to another nuke/spender
    for _, plan in ipairs(slotPlan) do
        local best = FindBest(plan.list, usedSpells)
        if not best and plan.slot == 4 then
            best = FindBest(ROLE_SPELL_MATRIX["SPENDER"], usedSpells)
        elseif not best and plan.slot == 7 then
            best = FindBest(ROLE_SPELL_MATRIX["BUILDER"], usedSpells)
        end

        if best then
            usedSpells[best.cleanName] = true
            self.dreamBarSlots[plan.slot] = {
                slot = plan.slot,
                roleLabel = plan.name,
                spellName = best.name,
                spellRank = best.rank,
                spellIndex = best.spellIndex,
                texture = best.texture,
            }
        end
    end

    EventBus:Fire("GH_ROLE_EVALUATED")
    return self.dreamBarSlots
end

-- Automatically populate action bars slots 1 to 10 with the Best Spells!
function RE:PopulateDreamBar()
    if InCombatLockdown() then
        Utils:Print("|cffFF3333Cannot modify action bars while in combat!|r")
        return false
    end

    self:EvaluateBestSpells()

    local placed = 0
    for slot = 1, 10 do
        local assignment = self.dreamBarSlots[slot]
        if assignment and assignment.spellIndex then
            ClearCursor()
            PickupSpell(assignment.spellIndex, BOOKTYPE_SPELL)
            PlaceAction(slot)
            ClearCursor()
            placed = placed + 1
            Utils:Print("Slot " .. slot .. ": Set to |cff00FF96[" .. assignment.spellName .. "]|r (" .. assignment.roleLabel .. ")")
        end
    end

    Utils:PlaySound("LEVEL_UP")
    Utils:Print("|cff00FF96Successfully populated action bar with " .. placed .. " optimal role abilities!|r")
    EventBus:Fire("GH_ACTIONBARS_UPDATED")
    return true
end

-- Event Listeners
EventBus:RegisterCustom("GH_SPELLBOOK_UPDATED", function()
    RE:DetectRole()
    RE:EvaluateBestSpells()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    RE:DetectRole()
    RE:EvaluateBestSpells()
end)
