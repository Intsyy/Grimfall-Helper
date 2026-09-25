-- ============================================================================
-- GrimfallHelper: Modules/NameplateAuras.lua
-- Real-Time Enemy Nameplate Debuff, DoT, and Bleed Tracker (e.g. Rend, Corruption)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.NameplateAuras = {}
local NA = GH.NameplateAuras
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Configuration Constants
local MAX_AURAS_PER_PLATE = 6
local ICON_SIZE = 20
local ICON_GAP = 3
local ICON_ASPECT = 0.85

NA.hookedPlates = {}
NA.activePlates = {}
NA.trackedAuras = {}    -- [guid] = { [spellName] = { icon, expirationTime, duration, count, debuffType, spellId } }
NA.guidNames = {}       -- [guid] = name
NA.nameToGuid = {}      -- [name] = guid (most recent)
local playerGUID = nil

-- Standard Baseline Durations for common DoTs / Debuffs in WotLK (used when applied off-target)
local DEFAULT_DURATIONS = {
    ["rend"] = 15,
    ["deep wounds"] = 6,
    ["sunder armor"] = 30,
    ["hamstring"] = 15,
    ["demoralizing shout"] = 30,
    ["thunder clap"] = 30,
    ["mortal strike"] = 10,
    ["disarm"] = 10,
    ["corruption"] = 18,
    ["immolate"] = 15,
    ["curse of agony"] = 24,
    ["curse of doom"] = 60,
    ["curse of the elements"] = 300,
    ["curse of weakness"] = 120,
    ["curse of tongues"] = 30,
    ["siphon life"] = 30,
    ["seed of corruption"] = 18,
    ["unstable affliction"] = 15,
    ["fear"] = 20,
    ["banish"] = 30,
    ["moonfire"] = 12,
    ["insect swarm"] = 12,
    ["rip"] = 12,
    ["rake"] = 9,
    ["lacerate"] = 15,
    ["faerie fire"] = 300,
    ["faerie fire (feral)"] = 300,
    ["entangling roots"] = 27,
    ["cyclone"] = 6,
    ["shadow word: pain"] = 18,
    ["vampiric touch"] = 15,
    ["devouring plague"] = 24,
    ["mind flay"] = 3,
    ["holy fire"] = 7,
    ["psychic scream"] = 8,
    ["serpent sting"] = 15,
    ["black arrow"] = 15,
    ["explosive shot"] = 2,
    ["hunter's mark"] = 300,
    ["concussive shot"] = 4,
    ["wing clip"] = 10,
    ["freezing trap"] = 20,
    ["wyvern sting"] = 30,
    ["viper sting"] = 8,
    ["rupture"] = 16,
    ["garrote"] = 18,
    ["deadly poison"] = 12,
    ["wound poison"] = 15,
    ["crippling poison"] = 12,
    ["mind-numbing poison"] = 14,
    ["kidney shot"] = 6,
    ["cheap shot"] = 4,
    ["gouged"] = 4,
    ["gouge"] = 4,
    ["blind"] = 10,
    ["expose armor"] = 30,
    ["ignite"] = 4,
    ["pyroblast"] = 12,
    ["living bomb"] = 12,
    ["frostbolt"] = 9,
    ["frost nova"] = 8,
    ["cone of cold"] = 8,
    ["chilled"] = 5,
    ["slow"] = 15,
    ["polymorph"] = 50,
    ["flame shock"] = 18,
    ["frost shock"] = 8,
    ["earthbind"] = 5,
    ["hex"] = 30,
    ["blood plague"] = 15,
    ["frost fever"] = 15,
    ["chains of ice"] = 8,
    ["strangulate"] = 5,
    ["judgement of justice"] = 20,
    ["judgement of light"] = 20,
    ["judgement of wisdom"] = 20,
    ["hammer of justice"] = 6,
    ["repentance"] = 60,
}

-- Border Colors by Debuff Type
local DEBUFF_COLORS = {
    ["Magic"]   = { 0.20, 0.60, 1.00 },
    ["Curse"]   = { 0.70, 0.20, 0.90 },
    ["Disease"] = { 0.65, 0.40, 0.15 },
    ["Poison"]  = { 0.10, 0.85, 0.20 },
    ["none"]    = { 0.90, 0.15, 0.15 }, -- Physical / Bleed (e.g. Rend, Deep Wounds, Sunder)
}

-- Format Duration text for display
local function FormatTime(seconds)
    if seconds <= 0 then
        return ""
    elseif seconds < 3 then
        return string.format("|cffFF3333%.1f|r", seconds)
    elseif seconds < 10 then
        return string.format("|cffFFD700%.0f|r", seconds)
    elseif seconds < 60 then
        return string.format("|cffffffff%.0fs|r", seconds)
    else
        return string.format("|cffffffff%dm|r", math.floor(seconds / 60))
    end
end

-- ============================================================================
-- NAMEPLATE DETECTION & HOOKING
-- ============================================================================

-- Check if a given WorldFrame child is a 3.3.5a Blizzard nameplate
local function IsNameplate(frame)
    if not frame or frame:GetName() then return false end
    local regions = { frame:GetRegions() }
    for _, r in ipairs(regions) do
        if r:GetObjectType() == "Texture" then
            local tex = r:GetTexture()
            if tex == "Interface\\Tooltips\\Nameplate-Border" or tex == "Interface\\Tooltips\\Nameplate-Glow" then
                return true
            end
        end
    end
    return false
end

-- Find the HealthBar and Name text of a 3.3.5a nameplate
local function GetNameplateComponents(plate)
    local healthBar = nil
    local nameText = nil

    -- Find StatusBar child
    local children = { plate:GetChildren() }
    for _, child in ipairs(children) do
        if child:GetObjectType() == "StatusBar" then
            healthBar = child
            break
        end
    end

    -- Find FontString region with unit name
    local regions = { plate:GetRegions() }
    for _, r in ipairs(regions) do
        if r:GetObjectType() == "FontString" then
            local text = r:GetText()
            if text and not string.match(text, "^%d+$") and not string.match(text, "^%d+%+?$") then
                nameText = r
                break
            end
        end
    end

    return healthBar, nameText
end

-- Create Aura Container and Icon Frames on a Nameplate
function NA:AttachAuraContainer(plate)
    if plate.ghAuraContainer then return end

    local healthBar, nameText = GetNameplateComponents(plate)
    if not healthBar then return end

    plate.ghHealthBar = healthBar
    plate.ghNameText = nameText

    -- Container Frame anchored right above health bar
    local container = CreateFrame("Frame", nil, plate)
    container:SetSize(MAX_AURAS_PER_PLATE * (ICON_SIZE + ICON_GAP), ICON_SIZE + 4)
    container:SetPoint("BOTTOM", healthBar, "TOP", 0, 10)
    container:SetFrameLevel(plate:GetFrameLevel() + 5)
    plate.ghAuraContainer = container

    -- Create Icon Frames
    container.icons = {}
    for i = 1, MAX_AURAS_PER_PLATE do
        local iconFrame = CreateFrame("Frame", nil, container)
        iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
        iconFrame:SetPoint("LEFT", container, "LEFT", (i - 1) * (ICON_SIZE + ICON_GAP), 0)

        -- Dark background / backdrop
        iconFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, tileSize = 0, edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        iconFrame:SetBackdropColor(0, 0, 0, 0.8)
        iconFrame:SetBackdropBorderColor(0.9, 0.15, 0.15, 1.0)

        -- Spell Icon Texture
        local tex = iconFrame:CreateTexture(nil, "ARTWORK")
        tex:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", 1, -1)
        tex:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", -1, 1)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        iconFrame.texture = tex

        -- Cooldown Animation Spiral
        local cd = CreateFrame("Cooldown", nil, iconFrame, "CooldownFrameTemplate")
        cd:SetAllPoints(iconFrame)
        cd:SetReverse(true)
        iconFrame.cooldown = cd

        -- Duration Countdown Text (Crisp outline centered on top)
        local timer = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        timer:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
        timer:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
        timer:SetTextColor(1, 1, 1)
        iconFrame.timer = timer

        -- Stack Count Badge (Bottom-Right)
        local stacks = iconFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        stacks:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 2, -1)
        stacks:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
        stacks:SetTextColor(0.2, 1.0, 0.4)
        iconFrame.stacks = stacks

        iconFrame:Hide()
        container.icons[i] = iconFrame
    end

    -- Hook Show/Hide scripts
    plate:HookScript("OnShow", function(self)
        NA.activePlates[self] = true
        NA:UpdatePlateAuras(self)
    end)

    plate:HookScript("OnHide", function(self)
        NA.activePlates[self] = nil
        self.ghUnitGUID = nil
        self.ghUnitName = nil
        if self.ghAuraContainer then
            for _, iconFrame in ipairs(self.ghAuraContainer.icons) do
                iconFrame:Hide()
            end
        end
    end)

    self.hookedPlates[plate] = true
    if plate:IsShown() then
        self.activePlates[plate] = true
        self:UpdatePlateAuras(plate)
    end
end

-- Scan WorldFrame children for new nameplates
function NA:ScanWorldFrameForPlates()
    local children = { WorldFrame:GetChildren() }
    for _, child in ipairs(children) do
        if not self.hookedPlates[child] and IsNameplate(child) then
            self:AttachAuraContainer(child)
        end
    end
end

-- ============================================================================
-- AURA TRACKING & COMBAT LOG ENGINE
-- ============================================================================

-- Store or refresh an aura for a unit GUID
function NA:SetAura(guid, spellName, icon, duration, expirationTime, count, debuffType, spellId)
    if not guid or not spellName then return end

    if not self.trackedAuras[guid] then
        self.trackedAuras[guid] = {}
    end

    local clean = string.lower(spellName)
    self.trackedAuras[guid][clean] = {
        name = spellName,
        icon = icon or GetSpellTexture(spellName) or "Interface\\Icons\\INV_Misc_QuestionMark",
        duration = duration or DEFAULT_DURATIONS[clean] or 15,
        expirationTime = expirationTime or (GetTime() + (duration or DEFAULT_DURATIONS[clean] or 15)),
        count = count or 1,
        debuffType = debuffType or "none",
        spellId = spellId,
    }

    self:RefreshPlatesForGUID(guid)
end

-- Remove an aura for a unit GUID
function NA:RemoveAura(guid, spellName)
    if not guid or not spellName or not self.trackedAuras[guid] then return end

    local clean = string.lower(spellName)
    self.trackedAuras[guid][clean] = nil

    self:RefreshPlatesForGUID(guid)
end

-- Clear all auras for a deceased or destroyed unit
function NA:ClearUnit(guid)
    if not guid then return end
    self.trackedAuras[guid] = nil
    self:RefreshPlatesForGUID(guid)
end

-- Refresh nameplate display for a specific GUID
function NA:RefreshPlatesForGUID(guid)
    for plate in pairs(self.activePlates) do
        if plate.ghUnitGUID == guid or (not plate.ghUnitGUID and plate.ghUnitName and self.nameToGuid[plate.ghUnitName] == guid) then
            self:UpdatePlateAuras(plate)
        end
    end
end

-- Synchronize exact auras directly from Target or Mouseover
function NA:ScanUnitAuras(unit)
    if not UnitExists(unit) or not UnitCanAttack("player", unit) then return end
    local guid = UnitGUID(unit)
    local name = UnitName(unit)
    if not guid then return end

    self.guidNames[guid] = name
    if name then self.nameToGuid[name] = guid end

    local activeThisScan = {}

    -- Scan debuffs on target
    for i = 1, 40 do
        local debuffName, _, icon, count, debuffType, duration, expirationTime, unitCaster, _, _, spellId = UnitDebuff(unit, i)
        if not debuffName then break end

        -- Only track debuffs applied by the player!
        if unitCaster == "player" then
            local clean = string.lower(debuffName)
            activeThisScan[clean] = true

            local dur = (duration and duration > 0) and duration or (DEFAULT_DURATIONS[clean] or 15)
            local exp = (expirationTime and expirationTime > 0) and expirationTime or (GetTime() + dur)

            self:SetAura(guid, debuffName, icon, dur, exp, count, debuffType, spellId)
        end
    end

    -- Clean up any auras for this GUID that are no longer on the unit
    if self.trackedAuras[guid] then
        for cleanSpell in pairs(self.trackedAuras[guid]) do
            if not activeThisScan[cleanSpell] then
                self.trackedAuras[guid][cleanSpell] = nil
            end
        end
    end

    self:RefreshPlatesForGUID(guid)
end

-- ============================================================================
-- NAMEPLATE UI RENDERING
-- ============================================================================

-- Render active debuff icons onto a single nameplate
function NA:UpdatePlateAuras(plate)
    if not plate or not plate.ghAuraContainer then return end
    if not GH.Config:Get("nameplateDebuffs", true) then
        plate.ghAuraContainer:Hide()
        return
    end

    plate.ghAuraContainer:Show()

    -- 1. Resolve Plate Unit GUID
    local name = plate.ghNameText and plate.ghNameText:GetText()
    plate.ghUnitName = name

    -- If this is the current target nameplate:
    if UnitExists("target") and (plate:GetAlpha() == 1.0 or (plate.ghHealthBar and plate.ghHealthBar:GetAlpha() == 1.0)) and name == UnitName("target") then
        plate.ghUnitGUID = UnitGUID("target")
    -- If this is mouseover nameplate:
    elseif UnitExists("mouseover") and name == UnitName("mouseover") then
        plate.ghUnitGUID = UnitGUID("mouseover")
    -- Fallback: lookup by name if recorded
    elseif not plate.ghUnitGUID and name and self.nameToGuid[name] then
        plate.ghUnitGUID = self.nameToGuid[name]
    end

    local guid = plate.ghUnitGUID
    local auras = guid and self.trackedAuras[guid]

    -- Collect and sort active auras
    local activeList = {}
    local now = GetTime()

    if auras then
        for _, aura in pairs(auras) do
            local remaining = aura.expirationTime - now
            if remaining > 0 then
                table.insert(activeList, aura)
            end
        end
    end

    -- Sort by shortest remaining duration first (so soonest to expire is prominent on left!)
    table.sort(activeList, function(a, b)
        return a.expirationTime < b.expirationTime
    end)

    -- Display up to MAX_AURAS_PER_PLATE
    local numToShow = math.min(#activeList, MAX_AURAS_PER_PLATE)

    -- Center align the icons above the health bar
    if numToShow > 0 then
        local totalWidth = (numToShow * ICON_SIZE) + ((numToShow - 1) * ICON_GAP)
        plate.ghAuraContainer:SetWidth(totalWidth)
        plate.ghAuraContainer:ClearAllPoints()
        plate.ghAuraContainer:SetPoint("BOTTOM", plate.ghHealthBar, "TOP", 0, 10)
    end

    for i = 1, MAX_AURAS_PER_PLATE do
        local iconFrame = plate.ghAuraContainer.icons[i]
        local aura = activeList[i]

        if aura and i <= numToShow then
            local remaining = aura.expirationTime - now

            iconFrame.texture:SetTexture(aura.icon)

            -- Border Color by Debuff Type
            local color = DEBUFF_COLORS[aura.debuffType or "none"] or DEBUFF_COLORS["none"]
            iconFrame:SetBackdropBorderColor(color[1], color[2], color[3], 1.0)

            -- Cooldown Animation Spiral
            local start = aura.expirationTime - aura.duration
            iconFrame.cooldown:SetCooldown(start, aura.duration)

            -- Countdown Text
            iconFrame.timer:SetText(FormatTime(remaining))

            -- Stack Count Badge
            if aura.count and aura.count > 1 then
                iconFrame.stacks:SetText(tostring(aura.count))
                iconFrame.stacks:Show()
            else
                iconFrame.stacks:Hide()
            end

            iconFrame.auraData = aura
            iconFrame:Show()
        else
            iconFrame.auraData = nil
            iconFrame:Hide()
        end
    end
end

-- ============================================================================
-- REAL-TIME ENGINE TICK & EVENT LISTENERS
-- ============================================================================

local tickFrame = CreateFrame("Frame", "GrimfallNameplateTickFrame")
local elapsedTimer = 0
local scanTimer = 0

tickFrame:SetScript("OnUpdate", function(self, elapsed)
    elapsedTimer = elapsedTimer + elapsed
    scanTimer = scanTimer + elapsed

    -- 1. Nameplate Scanner: Scan WorldFrame for newly spawned nameplates (every 0.2s)
    if scanTimer >= 0.20 then
        scanTimer = 0
        NA:ScanWorldFrameForPlates()
    end

    -- 2. Countdown Timer Refresh: Update active timers on all visible nameplates (every 0.1s)
    if elapsedTimer >= 0.10 then
        elapsedTimer = 0
        local now = GetTime()

        for plate in pairs(NA.activePlates) do
            if plate:IsShown() and plate.ghAuraContainer and plate.ghAuraContainer:IsShown() then
                for i = 1, MAX_AURAS_PER_PLATE do
                    local iconFrame = plate.ghAuraContainer.icons[i]
                    if iconFrame:IsShown() and iconFrame.auraData then
                        local remaining = iconFrame.auraData.expirationTime - now
                        if remaining <= 0 then
                            NA:UpdatePlateAuras(plate)
                            break
                        else
                            iconFrame.timer:SetText(FormatTime(remaining))
                        end
                    end
                end
            end
        end
    end
end)

-- Target Change
EventBus:Register("PLAYER_TARGET_CHANGED", function()
    if UnitExists("target") and UnitCanAttack("player", "target") then
        NA:ScanUnitAuras("target")
    end
    -- Update all plates on target switch
    for plate in pairs(NA.activePlates) do
        NA:UpdatePlateAuras(plate)
    end
end)

-- Mouseover Change
EventBus:Register("UPDATE_MOUSEOVER_UNIT", function()
    if UnitExists("mouseover") and UnitCanAttack("player", "mouseover") then
        NA:ScanUnitAuras("mouseover")
    end
end)

-- Target Aura Update Event
EventBus:Register("UNIT_AURA", function(event, unit)
    if unit == "target" then
        NA:ScanUnitAuras("target")
    elseif unit == "mouseover" then
        NA:ScanUnitAuras("mouseover")
    end
end)

-- Combat Log Event Listener: Authoritative DoT / Debuff Tracking
EventBus:Register("COMBAT_LOG_EVENT_UNFILTERED", function(event, timestamp, eventType, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags, spellId, spellName, spellSchool, auraType, amount)
    if not playerGUID then
        playerGUID = UnitGUID("player")
    end

    -- Only track player-applied debuffs!
    if sourceGUID == playerGUID and auraType == "DEBUFF" then
        if eventType == "SPELL_AURA_APPLIED" or eventType == "SPELL_AURA_REFRESH" or eventType == "SPELL_AURA_APPLIED_DOSE" then
            local clean = string.lower(spellName or "")
            local icon = GetSpellTexture(spellId or spellName) or "Interface\\Icons\\INV_Misc_QuestionMark"
            local dur = DEFAULT_DURATIONS[clean] or 15

            -- If target matches, get precise expiration
            local exp = GetTime() + dur
            if destGUID == UnitGUID("target") then
                for i = 1, 40 do
                    local name, _, _, count, debuffType, duration, expirationTime, unitCaster = UnitDebuff("target", i)
                    if name == spellName and unitCaster == "player" then
                        if duration and duration > 0 then dur = duration end
                        if expirationTime and expirationTime > 0 then exp = expirationTime end
                        break
                    end
                end
            end

            NA.guidNames[destGUID] = destName
            if destName then NA.nameToGuid[destName] = destGUID end
            NA:SetAura(destGUID, spellName, icon, dur, exp, amount or 1, "none", spellId)

        elseif eventType == "SPELL_AURA_REMOVED" or eventType == "SPELL_AURA_BROKEN" or eventType == "SPELL_AURA_BROKEN_SPELL" then
            NA:RemoveAura(destGUID, spellName)
        end
    end

    -- Clear auras on unit death
    if eventType == "UNIT_DIED" or eventType == "UNIT_DESTROYED" then
        NA:ClearUnit(destGUID)
    end
end)

-- Initialize on Addon Loaded
function NA:Initialize()
    playerGUID = UnitGUID("player")
    self:ScanWorldFrameForPlates()
end

EventBus:Register("PLAYER_LOGIN", function()
    playerGUID = UnitGUID("player")
    NA:Initialize()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    playerGUID = UnitGUID("player")
    NA:Initialize()
end)
