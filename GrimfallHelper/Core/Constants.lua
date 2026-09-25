-- ============================================================================
-- GrimfallHelper: Core/Constants.lua
-- Constants, Databases, Spell Categories, Synergy Combos, and Class Colors
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Constants = {}
local C = GH.Constants

C.ADDON_NAME = "GrimfallHelper"
C.ADDON_VERSION = "1.0.0"
C.ADDON_PREFIX = "|cff00ff96[GrimfallHelper]|r "

-- Class Definitions & Theme Colors
C.CLASSES = {
    ["WARRIOR"]     = { name = "Warrior",      color = "C79C6E", r = 0.78, g = 0.61, b = 0.43 },
    ["PALADIN"]     = { name = "Paladin",      color = "F58CBA", r = 0.96, g = 0.55, b = 0.73 },
    ["HUNTER"]      = { name = "Hunter",       color = "ABD473", r = 0.67, g = 0.83, b = 0.45 },
    ["ROGUE"]       = { name = "Rogue",        color = "FFF569", r = 1.00, g = 0.96, b = 0.41 },
    ["PRIEST"]      = { name = "Priest",       color = "FFFFFF", r = 1.00, g = 1.00, b = 1.00 },
    ["DEATHKNIGHT"] = { name = "Death Knight", color = "C41F3B", r = 0.77, g = 0.12, b = 0.23 },
    ["SHAMAN"]      = { name = "Shaman",       color = "0070DE", r = 0.00, g = 0.44, b = 0.87 },
    ["MAGE"]        = { name = "Mage",         color = "69CCF0", r = 0.41, g = 0.80, b = 0.94 },
    ["WARLOCK"]     = { name = "Warlock",      color = "9482C9", r = 0.58, g = 0.51, b = 0.79 },
    ["DRUID"]       = { name = "Druid",        color = "FF7D0A", r = 1.00, g = 0.49, b = 0.04 },
}

-- Magic Schools
C.SCHOOLS = {
    ["Physical"] = { color = "FFFFCC", r = 1.00, g = 1.00, b = 0.80 },
    ["Holy"]     = { color = "FFE680", r = 1.00, g = 0.90, b = 0.50 },
    ["Fire"]     = { color = "FF5522", r = 1.00, g = 0.33, b = 0.13 },
    ["Frost"]    = { color = "88DDFF", r = 0.53, g = 0.87, b = 1.00 },
    ["Shadow"]   = { color = "AA66CC", r = 0.67, g = 0.40, b = 0.80 },
    ["Nature"]   = { color = "44DD44", r = 0.27, g = 0.87, b = 0.27 },
    ["Arcane"]   = { color = "FF88FF", r = 1.00, g = 0.53, b = 1.00 },
}

-- Role Categories for Filter
C.CATEGORIES = {
    ["ALL"]         = "All Categories",
    ["MELEE_NUKE"]  = "Melee Attack",
    ["RANGED_NUKE"] = "Ranged / Caster",
    ["DOT_BLEED"]   = "DoT / Bleed",
    ["HEAL"]        = "Healing / HoT",
    ["DEFENSIVE"]   = "Defensive / Shield",
    ["CC_INTERRUPT"]= "CC / Interrupt",
    ["BUFF_AURA"]   = "Buff / Aura / Stance",
    ["PET_SUMMON"]  = "Pet / Utility",
    ["PASSIVE"]     = "Passive",
}

-- Resource Types
C.RESOURCES = {
    [0] = { name = "Mana",        color = "4080FF", r = 0.25, g = 0.50, b = 1.00 },
    [1] = { name = "Rage",        color = "FF3333", r = 1.00, g = 0.20, b = 0.20 },
    [2] = { name = "Focus",       color = "FF9933", r = 1.00, g = 0.60, b = 0.20 },
    [3] = { name = "Energy",      color = "FFFF33", r = 1.00, g = 1.00, b = 0.20 },
    [4] = { name = "Happiness",   color = "33FF66", r = 0.20, g = 1.00, b = 0.40 },
    [5] = { name = "Runes",       color = "AA66FF", r = 0.67, g = 0.40, b = 1.00 },
    [6] = { name = "Runic Power", color = "00D0FF", r = 0.00, g = 0.82, b = 1.00 },
}

-- Known Wildcard Ability Data (Catalog for Classless Recognition)
-- Format: [NormalizedSpellName] = { class, school, category, resource, icon }
C.SPELL_CATALOG = {
    -- Warrior
    ["charge"]             = { class = "WARRIOR", school = "Physical", category = "CC_INTERRUPT", resource = "Rage" },
    ["intercept"]          = { class = "WARRIOR", school = "Physical", category = "CC_INTERRUPT", resource = "Rage" },
    ["intervene"]          = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "Rage" },
    ["mortal strike"]      = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["bloodthirst"]        = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["shield slam"]        = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage", reqShield = true },
    ["whirlwind"]          = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["overpower"]          = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["execute"]            = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["slam"]               = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["heroic strike"]      = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["cleave"]             = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["rend"]               = { class = "WARRIOR", school = "Physical", category = "DOT_BLEED",    resource = "Rage" },
    ["thunder clap"]       = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "Rage" },
    ["disarm"]             = { class = "WARRIOR", school = "Physical", category = "CC_INTERRUPT", resource = "Rage" },
    ["pummel"]             = { class = "WARRIOR", school = "Physical", category = "CC_INTERRUPT", resource = "Rage" },
    ["shield wall"]        = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "Rage", reqShield = true },
    ["shield block"]       = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "Rage", reqShield = true },
    ["last stand"]         = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["retaliation"]        = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["recklessness"]       = { class = "WARRIOR", school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["spell reflection"]   = { class = "WARRIOR", school = "Physical", category = "DEFENSIVE",    resource = "Rage", reqShield = true },
    ["battle shout"]       = { class = "WARRIOR", school = "Physical", category = "BUFF_AURA",    resource = "Rage", buff = true },
    ["commanding shout"]   = { class = "WARRIOR", school = "Physical", category = "BUFF_AURA",    resource = "Rage", buff = true },
    ["berserker rage"]     = { class = "WARRIOR", school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["bloodrage"]          = { class = "WARRIOR", school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["bladestorm"]         = { class = "WARRIOR", school = "Physical", category = "MELEE_NUKE",   resource = "Rage" },
    ["shockwave"]          = { class = "WARRIOR", school = "Physical", category = "CC_INTERRUPT", resource = "Rage" },

    -- Paladin
    ["holy light"]         = { class = "PALADIN", school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["flash of light"]     = { class = "PALADIN", school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["holy shock"]         = { class = "PALADIN", school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["lay on hands"]       = { class = "PALADIN", school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["crusader strike"]    = { class = "PALADIN", school = "Physical", category = "MELEE_NUKE",   resource = "Mana" },
    ["divine storm"]       = { class = "PALADIN", school = "Physical", category = "MELEE_NUKE",   resource = "Mana" },
    ["judgement of light"] = { class = "PALADIN", school = "Holy",     category = "MELEE_NUKE",   resource = "Mana" },
    ["judgement of wisdom"]= { class = "PALADIN", school = "Holy",     category = "MELEE_NUKE",   resource = "Mana" },
    ["judgement of justice"]={ class = "PALADIN", school = "Holy",     category = "MELEE_NUKE",   resource = "Mana" },
    ["hammer of wrath"]    = { class = "PALADIN", school = "Holy",     category = "RANGED_NUKE",  resource = "Mana" },
    ["consecration"]       = { class = "PALADIN", school = "Holy",     category = "RANGED_NUKE",  resource = "Mana" },
    ["exorcism"]           = { class = "PALADIN", school = "Holy",     category = "RANGED_NUKE",  resource = "Mana" },
    ["hammer of justice"]  = { class = "PALADIN", school = "Holy",     category = "CC_INTERRUPT", resource = "Mana" },
    ["divine shield"]      = { class = "PALADIN", school = "Holy",     category = "DEFENSIVE",    resource = "Mana" },
    ["divine protection"]  = { class = "PALADIN", school = "Holy",     category = "DEFENSIVE",    resource = "Mana" },
    ["hand of protection"] = { class = "PALADIN", school = "Holy",     category = "DEFENSIVE",    resource = "Mana" },
    ["hand of freedom"]    = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana" },
    ["righteous fury"]     = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["seal of command"]    = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["seal of righteousness"]={ class = "PALADIN", school = "Holy",    category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["seal of light"]      = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["avenging wrath"]     = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana" },
    ["blessing of kings"]  = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["blessing of might"]  = { class = "PALADIN", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["cleanse"]            = { class = "PALADIN", school = "Holy",     category = "DEFENSIVE",    resource = "Mana" },

    -- Hunter
    ["auto shot"]          = { class = "HUNTER",  school = "Physical", category = "RANGED_NUKE",  resource = "None", reqRanged = true },
    ["arcane shot"]        = { class = "HUNTER",  school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["aimed shot"]         = { class = "HUNTER",  school = "Physical", category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["multi-shot"]         = { class = "HUNTER",  school = "Physical", category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["chimera shot"]       = { class = "HUNTER",  school = "Nature",   category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["explosive shot"]     = { class = "HUNTER",  school = "Fire",     category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["kill shot"]          = { class = "HUNTER",  school = "Physical", category = "RANGED_NUKE",  resource = "Mana", reqRanged = true },
    ["serpent sting"]      = { class = "HUNTER",  school = "Nature",   category = "DOT_BLEED",    resource = "Mana", reqRanged = true },
    ["hunter's mark"]      = { class = "HUNTER",  school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["disengage"]          = { class = "HUNTER",  school = "Physical", category = "DEFENSIVE",    resource = "Mana" },
    ["feign death"]        = { class = "HUNTER",  school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["deterrence"]         = { class = "HUNTER",  school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["freezing trap"]      = { class = "HUNTER",  school = "Frost",    category = "CC_INTERRUPT", resource = "Mana" },
    ["explosive trap"]     = { class = "HUNTER",  school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["bestial wrath"]      = { class = "HUNTER",  school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["aspect of the hawk"] = { class = "HUNTER",  school = "Physical", category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["aspect of the viper"]= { class = "HUNTER",  school = "Physical", category = "BUFF_AURA",    resource = "Mana", buff = true },

    -- Rogue
    ["sinister strike"]    = { class = "ROGUE",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy" },
    ["backstab"]           = { class = "ROGUE",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy", reqDagger = true },
    ["ambush"]             = { class = "ROGUE",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy", reqDagger = true, reqStealth = true },
    ["eviscerate"]         = { class = "ROGUE",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy" },
    ["slice and dice"]     = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "Energy" },
    ["rupture"]            = { class = "ROGUE",   school = "Physical", category = "DOT_BLEED",    resource = "Energy" },
    ["garrote"]            = { class = "ROGUE",   school = "Physical", category = "DOT_BLEED",    resource = "Energy", reqStealth = true },
    ["cheap shot"]         = { class = "ROGUE",   school = "Physical", category = "CC_INTERRUPT", resource = "Energy", reqStealth = true },
    ["kidney shot"]        = { class = "ROGUE",   school = "Physical", category = "CC_INTERRUPT", resource = "Energy" },
    ["gouge"]              = { class = "ROGUE",   school = "Physical", category = "CC_INTERRUPT", resource = "Energy" },
    ["blind"]              = { class = "ROGUE",   school = "Physical", category = "CC_INTERRUPT", resource = "Energy" },
    ["kick"]               = { class = "ROGUE",   school = "Physical", category = "CC_INTERRUPT", resource = "Energy" },
    ["stealth"]            = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["vanish"]             = { class = "ROGUE",   school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["evasion"]            = { class = "ROGUE",   school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["sprint"]             = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["cloak of shadows"]   = { class = "ROGUE",   school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["shadowstep"]         = { class = "ROGUE",   school = "Shadow",   category = "BUFF_AURA",    resource = "Energy" },
    ["preparation"]        = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["adrenaline rush"]    = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "None" },
    ["blade flurry"]       = { class = "ROGUE",   school = "Physical", category = "BUFF_AURA",    resource = "Energy" },

    -- Priest
    ["flash heal"]         = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["greater heal"]       = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["renew"]              = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["power word: shield"] = { class = "PRIEST",  school = "Holy",     category = "DEFENSIVE",    resource = "Mana" },
    ["prayer of mending"]  = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["penance"]            = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["circle of healing"]  = { class = "PRIEST",  school = "Holy",     category = "HEAL",         resource = "Mana" },
    ["smite"]              = { class = "PRIEST",  school = "Holy",     category = "RANGED_NUKE",  resource = "Mana" },
    ["holy fire"]          = { class = "PRIEST",  school = "Holy",     category = "RANGED_NUKE",  resource = "Mana" },
    ["shadow word: pain"]  = { class = "PRIEST",  school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["mind blast"]         = { class = "PRIEST",  school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["mind flay"]          = { class = "PRIEST",  school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["vampiric touch"]     = { class = "PRIEST",  school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["vampiric embrace"]   = { class = "PRIEST",  school = "Shadow",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["devouring plague"]   = { class = "PRIEST",  school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["shadow word: death"] = { class = "PRIEST",  school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["psychic scream"]     = { class = "PRIEST",  school = "Shadow",   category = "CC_INTERRUPT", resource = "Mana" },
    ["silence"]            = { class = "PRIEST",  school = "Shadow",   category = "CC_INTERRUPT", resource = "Mana" },
    ["dispersion"]         = { class = "PRIEST",  school = "Shadow",   category = "DEFENSIVE",    resource = "None" },
    ["inner fire"]         = { class = "PRIEST",  school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["power word: fortitude"]={ class = "PRIEST", school = "Holy",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["shadowform"]         = { class = "PRIEST",  school = "Shadow",   category = "BUFF_AURA",    resource = "Mana", buff = true },

    -- Death Knight
    ["icy touch"]          = { class = "DEATHKNIGHT", school = "Frost",  category = "RANGED_NUKE", resource = "Runes" },
    ["plague strike"]      = { class = "DEATHKNIGHT", school = "Shadow", category = "MELEE_NUKE",  resource = "Runes" },
    ["death strike"]       = { class = "DEATHKNIGHT", school = "Shadow", category = "MELEE_NUKE",  resource = "Runes" },
    ["obliterate"]         = { class = "DEATHKNIGHT", school = "Physical", category = "MELEE_NUKE",resource = "Runes" },
    ["heart strike"]       = { class = "DEATHKNIGHT", school = "Physical", category = "MELEE_NUKE",resource = "Runes" },
    ["blood boil"]         = { class = "DEATHKNIGHT", school = "Shadow", category = "MELEE_NUKE",  resource = "Runes" },
    ["howling blast"]      = { class = "DEATHKNIGHT", school = "Frost",  category = "RANGED_NUKE", resource = "Runes" },
    ["frost strike"]       = { class = "DEATHKNIGHT", school = "Frost",  category = "MELEE_NUKE",  resource = "Runic Power" },
    ["death coil"]         = { class = "DEATHKNIGHT", school = "Shadow", category = "RANGED_NUKE", resource = "Runic Power" },
    ["death grip"]         = { class = "DEATHKNIGHT", school = "Shadow", category = "CC_INTERRUPT",resource = "None" },
    ["strangulate"]        = { class = "DEATHKNIGHT", school = "Shadow", category = "CC_INTERRUPT",resource = "Runes" },
    ["mind freeze"]        = { class = "DEATHKNIGHT", school = "Frost",  category = "CC_INTERRUPT",resource = "Runic Power" },
    ["icebound fortitude"] = { class = "DEATHKNIGHT", school = "Physical", category = "DEFENSIVE", resource = "Runic Power" },
    ["anti-magic shell"]   = { class = "DEATHKNIGHT", school = "Shadow", category = "DEFENSIVE",   resource = "Runic Power" },
    ["bone shield"]        = { class = "DEATHKNIGHT", school = "Shadow", category = "DEFENSIVE",   resource = "Runes" },
    ["horn of winter"]     = { class = "DEATHKNIGHT", school = "Frost",  category = "BUFF_AURA",   resource = "None", buff = true },
    ["blood presence"]     = { class = "DEATHKNIGHT", school = "Shadow", category = "BUFF_AURA",   resource = "None", buff = true },
    ["frost presence"]     = { class = "DEATHKNIGHT", school = "Frost",  category = "BUFF_AURA",   resource = "None", buff = true },
    ["unholy presence"]    = { class = "DEATHKNIGHT", school = "Shadow", category = "BUFF_AURA",   resource = "None", buff = true },

    -- Shaman
    ["lightning bolt"]     = { class = "SHAMAN",  school = "Nature",   category = "RANGED_NUKE",  resource = "Mana" },
    ["chain lightning"]    = { class = "SHAMAN",  school = "Nature",   category = "RANGED_NUKE",  resource = "Mana" },
    ["earth shock"]        = { class = "SHAMAN",  school = "Nature",   category = "RANGED_NUKE",  resource = "Mana" },
    ["flame shock"]        = { class = "SHAMAN",  school = "Fire",     category = "DOT_BLEED",    resource = "Mana" },
    ["frost shock"]        = { class = "SHAMAN",  school = "Frost",    category = "RANGED_NUKE",  resource = "Mana" },
    ["lava burst"]         = { class = "SHAMAN",  school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["stormstrike"]        = { class = "SHAMAN",  school = "Physical", category = "MELEE_NUKE",   resource = "Mana" },
    ["lava lash"]          = { class = "SHAMAN",  school = "Fire",     category = "MELEE_NUKE",   resource = "Mana" },
    ["healing wave"]       = { class = "SHAMAN",  school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["lesser healing wave"]= { class = "SHAMAN",  school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["chain heal"]         = { class = "SHAMAN",  school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["riptide"]            = { class = "SHAMAN",  school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["wind shear"]         = { class = "SHAMAN",  school = "Nature",   category = "CC_INTERRUPT", resource = "Mana" },
    ["bloodlust"]          = { class = "SHAMAN",  school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["heroism"]            = { class = "SHAMAN",  school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["lightning shield"]   = { class = "SHAMAN",  school = "Nature",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["water shield"]       = { class = "SHAMAN",  school = "Nature",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["ghost wolf"]         = { class = "SHAMAN",  school = "Nature",   category = "BUFF_AURA",    resource = "Mana" },

    -- Mage
    ["fireball"]           = { class = "MAGE",    school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["pyroblast"]          = { class = "MAGE",    school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["scorch"]             = { class = "MAGE",    school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["fire blast"]         = { class = "MAGE",    school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["frostbolt"]          = { class = "MAGE",    school = "Frost",    category = "RANGED_NUKE",  resource = "Mana" },
    ["ice lance"]          = { class = "MAGE",    school = "Frost",    category = "RANGED_NUKE",  resource = "Mana" },
    ["cone of cold"]       = { class = "MAGE",    school = "Frost",    category = "RANGED_NUKE",  resource = "Mana" },
    ["blizzard"]           = { class = "MAGE",    school = "Frost",    category = "RANGED_NUKE",  resource = "Mana" },
    ["frost nova"]         = { class = "MAGE",    school = "Frost",    category = "CC_INTERRUPT", resource = "Mana" },
    ["deep freeze"]        = { class = "MAGE",    school = "Frost",    category = "CC_INTERRUPT", resource = "Mana" },
    ["arcane missiles"]    = { class = "MAGE",    school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana" },
    ["arcane blast"]       = { class = "MAGE",    school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana" },
    ["arcane barrage"]     = { class = "MAGE",    school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana" },
    ["polymorph"]          = { class = "MAGE",    school = "Arcane",   category = "CC_INTERRUPT", resource = "Mana" },
    ["counterspell"]       = { class = "MAGE",    school = "Arcane",   category = "CC_INTERRUPT", resource = "Mana" },
    ["blink"]              = { class = "MAGE",    school = "Arcane",   category = "DEFENSIVE",    resource = "Mana" },
    ["ice barrier"]        = { class = "MAGE",    school = "Frost",    category = "DEFENSIVE",    resource = "Mana", buff = true },
    ["mana shield"]        = { class = "MAGE",    school = "Arcane",   category = "DEFENSIVE",    resource = "Mana" },
    ["ice block"]          = { class = "MAGE",    school = "Frost",    category = "DEFENSIVE",    resource = "None" },
    ["evocation"]          = { class = "MAGE",    school = "Arcane",   category = "BUFF_AURA",    resource = "None" },
    ["arcane intellect"]   = { class = "MAGE",    school = "Arcane",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["molten armor"]       = { class = "MAGE",    school = "Fire",     category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["frost armor"]        = { class = "MAGE",    school = "Frost",    category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["mage armor"]         = { class = "MAGE",    school = "Arcane",   category = "BUFF_AURA",    resource = "Mana", buff = true },

    -- Warlock
    ["shadow bolt"]        = { class = "WARLOCK", school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["incinerate"]         = { class = "WARLOCK", school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["chaos bolt"]         = { class = "WARLOCK", school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["soul fire"]          = { class = "WARLOCK", school = "Fire",     category = "RANGED_NUKE",  resource = "Mana" },
    ["corruption"]         = { class = "WARLOCK", school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["curse of agony"]     = { class = "WARLOCK", school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["immolate"]           = { class = "WARLOCK", school = "Fire",     category = "DOT_BLEED",    resource = "Mana" },
    ["unstable affliction"]= { class = "WARLOCK", school = "Shadow",   category = "DOT_BLEED",    resource = "Mana" },
    ["haunt"]              = { class = "WARLOCK", school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["drain life"]         = { class = "WARLOCK", school = "Shadow",   category = "RANGED_NUKE",  resource = "Mana" },
    ["life tap"]           = { class = "WARLOCK", school = "Shadow",   category = "BUFF_AURA",    resource = "None" },
    ["fear"]               = { class = "WARLOCK", school = "Shadow",   category = "CC_INTERRUPT", resource = "Mana" },
    ["shadowfury"]         = { class = "WARLOCK", school = "Shadow",   category = "CC_INTERRUPT", resource = "Mana" },
    ["demonic circle: teleport"] = { class = "WARLOCK", school = "Shadow", category = "DEFENSIVE", resource = "Mana" },
    ["fel armor"]          = { class = "WARLOCK", school = "Shadow",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["demon armor"]        = { class = "WARLOCK", school = "Shadow",   category = "BUFF_AURA",    resource = "Mana", buff = true },

    -- Druid
    ["wrath"]              = { class = "DRUID",   school = "Nature",   category = "RANGED_NUKE",  resource = "Mana" },
    ["starfire"]           = { class = "DRUID",   school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana" },
    ["moonfire"]           = { class = "DRUID",   school = "Arcane",   category = "DOT_BLEED",    resource = "Mana" },
    ["insect swarm"]       = { class = "DRUID",   school = "Nature",   category = "DOT_BLEED",    resource = "Mana" },
    ["starfall"]           = { class = "DRUID",   school = "Arcane",   category = "RANGED_NUKE",  resource = "Mana" },
    ["entangling roots"]   = { class = "DRUID",   school = "Nature",   category = "CC_INTERRUPT", resource = "Mana" },
    ["cyclone"]            = { class = "DRUID",   school = "Nature",   category = "CC_INTERRUPT", resource = "Mana" },
    ["healing touch"]      = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["regrowth"]           = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["rejuvenation"]       = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["swiftmend"]          = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["lifebloom"]          = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["wild growth"]        = { class = "DRUID",   school = "Nature",   category = "HEAL",         resource = "Mana" },
    ["claw"]               = { class = "DRUID",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy", reqCat = true },
    ["shred"]              = { class = "DRUID",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy", reqCat = true },
    ["rake"]               = { class = "DRUID",   school = "Physical", category = "DOT_BLEED",    resource = "Energy", reqCat = true },
    ["rip"]                = { class = "DRUID",   school = "Physical", category = "DOT_BLEED",    resource = "Energy", reqCat = true },
    ["ferocious bite"]     = { class = "DRUID",   school = "Physical", category = "MELEE_NUKE",   resource = "Energy", reqCat = true },
    ["maul"]               = { class = "DRUID",   school = "Physical", category = "MELEE_NUKE",   resource = "Rage",   reqBear = true },
    ["swipe"]              = { class = "DRUID",   school = "Physical", category = "MELEE_NUKE",   resource = "Rage",   reqBear = true },
    ["growl"]              = { class = "DRUID",   school = "Physical", category = "CC_INTERRUPT", resource = "Rage",   reqBear = true },
    ["barkskin"]           = { class = "DRUID",   school = "Nature",   category = "DEFENSIVE",    resource = "None" },
    ["survival instincts"] = { class = "DRUID",   school = "Physical", category = "DEFENSIVE",    resource = "None" },
    ["mark of the wild"]   = { class = "DRUID",   school = "Nature",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["thorns"]             = { class = "DRUID",   school = "Nature",   category = "BUFF_AURA",    resource = "Mana", buff = true },
    ["bear form"]          = { class = "DRUID",   school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["dire bear form"]     = { class = "DRUID",   school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
    ["cat form"]           = { class = "DRUID",   school = "Physical", category = "BUFF_AURA",    resource = "Mana" },
}

-- Synergy Packages for Build Evaluation
C.SYNERGIES = {
    {
        id = "IGNITE_BURST",
        name = "Pyroclasm & Ignite",
        color = "FF5522",
        icon = "Spell_Fire_Fireball02",
        description = "High Fire damage scaling with crit chaining and burning damage over time.",
        coreSpells = { "fireball", "pyroblast", "scorch", "fire blast", "immolate", "incinerate", "chaos bolt", "lava burst", "flame shock" },
        minMatch = 2,
        weight = 15,
    },
    {
        id = "FROST_SHATTER",
        name = "Frost Shatter Shatterstrike",
        color = "88DDFF",
        icon = "Spell_Frost_FrostBolt02",
        description = "Freezes targets and exploits Shatter mechanics for massive critical strikes.",
        coreSpells = { "frostbolt", "ice lance", "frost nova", "cone of cold", "deep freeze", "blizzard", "icy touch", "howling blast", "frost shock" },
        minMatch = 2,
        weight = 15,
    },
    {
        id = "BLEED_MANGLE",
        name = "Ravage & Rend Bleed Engine",
        color = "C79C6E",
        icon = "Ability_Gouge",
        description = "Physical bleed amplification scaling with attack power, tearing armor apart.",
        coreSpells = { "rend", "rake", "rip", "garrote", "rupture", "mortal strike", "bloodthirst", "shred" },
        minMatch = 2,
        weight = 14,
    },
    {
        id = "HOLY_CRUSADER",
        name = "Radiant Crusader",
        color = "FFE680",
        icon = "Spell_Holy_HolyBolt",
        description = "Melee-holy synthesis with judgements, instant heals, and holy burst.",
        coreSpells = { "holy shock", "crusader strike", "divine storm", "judgement of light", "judgement of wisdom", "consecration", "hammer of wrath", "exorcism" },
        minMatch = 2,
        weight = 14,
    },
    {
        id = "AFFLICTION_DRAIN",
        name = "Shadow Drain & Leech",
        color = "AA66CC",
        icon = "Spell_Shadow_LifeDrain02",
        description = "Sustained shadow attrition, self-healing while suffocating targets.",
        coreSpells = { "corruption", "curse of agony", "shadow word: pain", "vampiric touch", "haunt", "drain life", "devouring plague", "death strike" },
        minMatch = 2,
        weight = 14,
    },
    {
        id = "NATURE_STORM",
        name = "Tempest & Lightning",
        color = "44DD44",
        icon = "Spell_Nature_Lightning",
        description = "High rapid Nature burst chaining shocks, lightning, and elemental shields.",
        coreSpells = { "lightning bolt", "chain lightning", "earth shock", "lightning shield", "stormstrike", "lava burst", "wrath" },
        minMatch = 2,
        weight = 13,
    },
    {
        id = "STEALTH_AMBUSH",
        name = "Shadow Assassin",
        color = "FFF569",
        icon = "Ability_Stealth",
        description = "Deadly burst from stealth with heavy control and rapid repositioning.",
        coreSpells = { "stealth", "ambush", "cheap shot", "backstab", "shadowstep", "kidney shot", "blind", "vanish" },
        minMatch = 2,
        weight = 15,
    },
    {
        id = "IRON_FORTRESS",
        name = "Juggernaut Fortress",
        color = "C41F3B",
        icon = "Ability_Warrior_ShieldWall",
        description = "Ultimate damage reduction, armor amplification, and active block mitigation.",
        coreSpells = { "shield slam", "shield block", "shield wall", "icebound fortitude", "anti-magic shell", "barkskin", "bone shield", "divine shield", "last stand" },
        minMatch = 2,
        weight = 15,
    },
}

-- Meta / Popular Wishlist Defaults for Quick Seeding
C.DEFAULT_WISHLIST_SEEDS = {
    ["S"] = {
        "Pyroblast", "Mortal Strike", "Divine Shield", "Bloodlust", "Stealth", "Penance", "Bladestorm", "Chaos Bolt"
    },
    ["A"] = {
        "Holy Shock", "Shadowstep", "Vampiric Touch", "Death Strike", "Blink", "Shield Slam", "Chain Lightning", "Aimed Shot"
    },
    ["B"] = {
        "Frost Nova", "Charge", "Inner Fire", "Wind Shear", "Consecration", "Barkskin", "Evocation", "Ice Barrier"
    }
}

-- Item Search Substrings for Grimfall Wildcard Scrolls & Tokens
C.WILDCARD_ITEM_KEYWORDS = {
    "reroll ability",
    "ability reroll",
    "talent reroll",
    "reroll",
    "hand of fate",
    "card",
    "wildcard",
    "scroll of fortune",
    "grimfall",
    "runic",
    "mystic",
    "token",
}

-- 3.3.5a Rating Caps & Milestones
C.STAT_CAPS = {
    MELEE_HIT_CAP = 8.0,       -- 8% Physical Special Hit Cap (Raid Boss)
    SPELL_HIT_CAP = 17.0,      -- 17% Spell Hit Cap (Raid Boss)
    DEFENSE_CAP = 540,         -- 540 Defense (Crit Immune against Level 83 Raid Boss)
    DEFENSE_PER_CRIT = 0.04,   -- 1 Defense skill reduces chance to be critically hit by 0.04%
}

-- 8 Pre-Built Meta Archetype Templates for 1-Click Wishlist Loading
C.META_TEMPLATES = {
    {
        id = "PYROMANCER",
        name = "Pyromancer Archmage",
        color = "FF5522",
        icon = "Spell_Fire_Fireball02",
        role = "Ranged Fire DPS",
        description = "Chains explosive crits, Ignite rolling damage, and instant Lava Burst / Chaos Bolt finishers.",
        wishlist = {
            ["S"] = { "Pyroblast", "Chaos Bolt", "Lava Burst", "Molten Armor" },
            ["A"] = { "Fireball", "Immolate", "Fire Blast", "Scorch" },
            ["B"] = { "Blink", "Evocation", "Flame Shock", "Mana Shield" },
        }
    },
    {
        id = "CRYOMANCER",
        name = "Shatterstrike Cryomancer",
        color = "88DDFF",
        icon = "Spell_Frost_FrostBolt02",
        role = "Control Ranged Burst",
        description = "Freezes enemies in place and unleashes triple-damage Shatter crits with Ice Lance and Deep Freeze.",
        wishlist = {
            ["S"] = { "Deep Freeze", "Ice Lance", "Frost Nova", "Ice Barrier" },
            ["A"] = { "Frostbolt", "Cone of Cold", "Howling Blast", "Ice Block" },
            ["B"] = { "Blink", "Counterspell", "Frost Armor", "Blizzard" },
        }
    },
    {
        id = "JUGGERNAUT",
        name = "Ironclad Juggernaut Tank",
        color = "C41F3B",
        icon = "Ability_Warrior_ShieldWall",
        role = "Unkillable Hybrid Tank",
        description = "Combines high block value, active mitigation, Righteous Fury threat, and self-sustaining heals.",
        wishlist = {
            ["S"] = { "Shield Slam", "Shield Wall", "Icebound Fortitude", "Righteous Fury" },
            ["A"] = { "Shield Block", "Death Strike", "Last Stand", "Bloodthirst" },
            ["B"] = { "Thunder Clap", "Barkskin", "Inner Fire", "Taunt" },
        }
    },
    {
        id = "CRUSADER",
        name = "Radiant Holy Crusader",
        color = "FFE680",
        icon = "Spell_Holy_HolyBolt",
        role = "Melee-Healer Hybrid",
        description = "Empowered melee strikes triggering Judgements, instant Holy Shocks, and divine damage.",
        wishlist = {
            ["S"] = { "Holy Shock", "Crusader Strike", "Divine Storm", "Divine Shield" },
            ["A"] = { "Judgement of Light", "Consecration", "Hammer of Wrath", "Seal of Command" },
            ["B"] = { "Flash of Light", "Hand of Freedom", "Cleanse", "Blessing of Kings" },
        }
    },
    {
        id = "HARVESTER",
        name = "Shadow Drain Harvester",
        color = "AA66CC",
        icon = "Spell_Shadow_LifeDrain02",
        role = "Sustained Leech DPS",
        description = "Suffocates enemies with multi-DoTs while leaching endless health through Drain Life and Death Strike.",
        wishlist = {
            ["S"] = { "Vampiric Touch", "Haunt", "Drain Life", "Shadowform" },
            ["A"] = { "Corruption", "Shadow Word: Pain", "Devouring Plague", "Death Strike" },
            ["B"] = { "Fear", "Dispersion", "Fel Armor", "Death Coil" },
        }
    },
    {
        id = "TEMPEST",
        name = "Tempest Stormcaller",
        color = "44DD44",
        icon = "Spell_Nature_Lightning",
        role = "Elemental Shaman Hybrid",
        description = "Unleashes rapid Nature shocks, chain lightning, and Stormstrike procs with dual-imbued power.",
        wishlist = {
            ["S"] = { "Chain Lightning", "Stormstrike", "Lightning Shield", "Bloodlust" },
            ["A"] = { "Lightning Bolt", "Earth Shock", "Lava Burst", "Wind Shear" },
            ["B"] = { "Water Shield", "Ghost Wolf", "Riptide", "Barkskin" },
        }
    },
    {
        id = "BERSERKER",
        name = "Bleed-and-Rend Berserker",
        color = "C79C6E",
        icon = "Ability_Gouge",
        role = "Physical Bleed DPS",
        description = "Tears enemy armor apart with cumulative bleeds, Mangle amplification, and Mortal Strike healing debuffs.",
        wishlist = {
            ["S"] = { "Mortal Strike", "Bladestorm", "Rend", "Rip" },
            ["A"] = { "Bloodthirst", "Rake", "Charge", "Whirlwind" },
            ["B"] = { "Berserker Rage", "Overpower", "Intercept", "Battle Shout" },
        }
    },
    {
        id = "ASSASSIN",
        name = "Shadow Infiltrator Assassin",
        color = "FFF569",
        icon = "Ability_Stealth",
        role = "Stealth Burst & Control",
        description = "Strikes from the shadows with guaranteed critical Ambush openers, teleportation, and inescapable stuns.",
        wishlist = {
            ["S"] = { "Stealth", "Ambush", "Shadowstep", "Cheap Shot" },
            ["A"] = { "Backstab", "Kidney Shot", "Vanish", "Eviscerate" },
            ["B"] = { "Blind", "Sprint", "Cloak of Shadows", "Preparation" },
        }
    },
}
