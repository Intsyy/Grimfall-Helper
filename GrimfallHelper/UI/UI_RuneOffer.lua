-- ============================================================================
-- GrimfallHelper: UI/UI_RuneOffer.lua
-- Interactive Pending Rune Offer Card & Reroll Advisor
-- Hooks Grimfall's CUSTOM_MYSTIC_ENCHANTMENT_ROLL_AVAILABLE event
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
local UI = GH.UI or {}
GH.UI = UI
local Utils = GH.Utils

local QUALITY_COLORS = {
    [5] = "FF8000", -- Legendary
    [4] = "A335EE", -- Epic
    [3] = "0070DD", -- Rare
    [2] = "1EFF00", -- Uncommon
    [1] = "FFFFFF", -- Common
}

local QUALITY_NAMES = {
    [5] = "Legendary",
    [4] = "Epic",
    [3] = "Rare",
    [2] = "Uncommon",
    [1] = "Common",
}

-- Create the Floating Offer Frame
local offerFrame = CreateFrame("Frame", "GrimfallHelperRuneOfferFrame", UIParent)
offerFrame:SetSize(420, 230)
offerFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
offerFrame:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 2,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
offerFrame:SetBackdropColor(0.06, 0.08, 0.12, 0.96)
offerFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
offerFrame:SetMovable(true)
offerFrame:EnableMouse(true)
offerFrame:RegisterForDrag("LeftButton")
offerFrame:SetScript("OnDragStart", offerFrame.StartMoving)
offerFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    if GH.Config then
        GH.Config:Set("offerPoint", point)
        GH.Config:Set("offerRelPoint", relPoint)
        GH.Config:Set("offerX", math.floor(x))
        GH.Config:Set("offerY", math.floor(y))
    end
end)
offerFrame:SetFrameStrata("HIGH")
offerFrame:SetClampedToScreen(true)
offerFrame:Hide()

-- Top Header Bar
local titleBar = offerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
titleBar:SetPoint("TOPLEFT", offerFrame, "TOPLEFT", 12, -10)
titleBar:SetText("|cff00FF96[Grimfall]|r |cffFFD700Pending Rune Offer|r")

-- Close Button (X)
local closeBtn = CreateFrame("Button", nil, offerFrame)
closeBtn:SetSize(20, 20)
closeBtn:SetPoint("TOPRIGHT", offerFrame, "TOPRIGHT", -8, -8)
closeBtn:SetNormalFontObject("GameFontNormal")
closeBtn:SetHighlightFontObject("GameFontHighlight")
closeBtn:SetText("x")
closeBtn:SetScript("OnClick", function() offerFrame:Hide() end)

-- Rune Quality & Name Badge
local runeNameText = offerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
runeNameText:SetPoint("TOPLEFT", offerFrame, "TOPLEFT", 14, -36)
runeNameText:SetPoint("TOPRIGHT", offerFrame, "TOPRIGHT", -14, -36)
runeNameText:SetJustifyH("LEFT")
runeNameText:SetText("|cffFF8000Rune of the Hoplite|r")

-- Status Subtitle (e.g. [New Rune - Not Learned] or [Already Known])
local runeStatusText = offerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
runeStatusText:SetPoint("TOPLEFT", runeNameText, "BOTTOMLEFT", 0, -4)
runeStatusText:SetText("|cff00FF96[New Rune - Not Learned]|r")

-- Description Text Box with Scroll/Wrapping
local descText = offerFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
descText:SetPoint("TOPLEFT", runeStatusText, "BOTTOMLEFT", 0, -8)
descText:SetPoint("BOTTOMRIGHT", offerFrame, "BOTTOMRIGHT", -14, 50)
descText:SetJustifyH("LEFT")
descText:SetJustifyV("TOP")
descText:SetWordWrap(true)
descText:SetText("Rune effect description goes here...")

-- Action Button: Claim Offer
local claimBtn = CreateFrame("Button", nil, offerFrame)
claimBtn:SetSize(140, 28)
claimBtn:SetPoint("BOTTOMLEFT", offerFrame, "BOTTOMLEFT", 14, 12)
claimBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
claimBtn:SetBackdropColor(0.08, 0.25, 0.12, 0.9)
claimBtn:SetBackdropBorderColor(0.0, 1.0, 0.5, 1.0)
claimBtn:SetNormalFontObject("GameFontHighlight")
claimBtn:SetText("|cff00FF96Claim Rune|r")
claimBtn:SetScript("OnClick", function()
    if Utils then Utils:PlaySound("CLICK") end
    pcall(function()
        if type(MysticEnchant_ClaimPendingOffer) == "function" then
            MysticEnchant_ClaimPendingOffer()
        end
    end)
    offerFrame:Hide()
end)

-- Action Button: Decline / Reroll
local passBtn = CreateFrame("Button", nil, offerFrame)
passBtn:SetSize(140, 28)
passBtn:SetPoint("BOTTOMLEFT", claimBtn, "BOTTOMRIGHT", 10, 0)
passBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
passBtn:SetBackdropColor(0.25, 0.08, 0.08, 0.9)
passBtn:SetBackdropBorderColor(1.0, 0.3, 0.3, 1.0)
passBtn:SetNormalFontObject("GameFontHighlight")
passBtn:SetText("|cffff5555Pass / Reroll|r")
passBtn:SetScript("OnClick", function()
    if Utils then Utils:PlaySound("CLICK") end
    pcall(function()
        if type(MysticEnchant_CancelPendingOffer) == "function" then
            MysticEnchant_CancelPendingOffer()
        elseif type(MysticEnchant_ClearPendingOffers) == "function" then
            MysticEnchant_ClearPendingOffers()
        end
    end)
    offerFrame:Hide()
end)

-- Dismiss Button
local dismissBtn = CreateFrame("Button", nil, offerFrame)
dismissBtn:SetSize(80, 28)
dismissBtn:SetPoint("BOTTOMRIGHT", offerFrame, "BOTTOMRIGHT", -14, 12)
dismissBtn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 0, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
dismissBtn:SetBackdropColor(0.15, 0.17, 0.22, 0.9)
dismissBtn:SetBackdropBorderColor(0.4, 0.4, 0.5, 1.0)
dismissBtn:SetNormalFontObject("GameFontHighlightSmall")
dismissBtn:SetText("Dismiss")
dismissBtn:SetScript("OnClick", function()
    offerFrame:Hide()
end)

-- Core Offer Display Method
UI.RuneOffer = {}

function UI.RuneOffer:ShowOffer(spellId)
    spellId = tonumber(spellId)
    if not spellId or spellId <= 0 then
        -- Query engine for pending offer
        pcall(function()
            if type(MysticEnchant_GetPendingOffer) == "function" then
                spellId = tonumber(MysticEnchant_GetPendingOffer())
            elseif type(MysticEnchant_GetCurrentOffer) == "function" then
                spellId = tonumber(MysticEnchant_GetCurrentOffer())
            end
        end)
    end

    if not spellId or spellId <= 0 then return end

    local rData = GH.RuneData and GH.RuneData[spellId]
    local name = rData and rData.name or GetSpellInfo(spellId) or ("Rune " .. spellId)
    local q = rData and rData.quality or 3
    if type(MysticEnchant_GetSpellQuality) == "function" then
        pcall(function() q = MysticEnchant_GetSpellQuality(spellId) or q end)
    end
    local color = QUALITY_COLORS[q] or "FFFFFF"
    local qName = QUALITY_NAMES[q] or "Rare"
    local desc = rData and rData.desc or "Special runic enchantment power."

    -- Set Border & Header Color based on Quality
    local r, g, b = 1, 1, 1
    if q == 5 then r, g, b = 1.0, 0.5, 0.0     -- Legendary Orange
    elseif q == 4 then r, g, b = 0.64, 0.2, 0.93 -- Epic Purple
    elseif q == 3 then r, g, b = 0.0, 0.44, 0.87 -- Rare Blue
    elseif q == 2 then r, g, b = 0.12, 1.0, 0.0  -- Uncommon Green
    end
    offerFrame:SetBackdropBorderColor(r, g, b, 1.0)

    runeNameText:SetText(string.format("|cff%s[%s] %s|r", color, qName, name))
    descText:SetText(desc)

    -- Check if learned
    local isKnown = false
    pcall(function()
        if type(MysticEnchant_GetKnownRESpellIds) == "function" then
            local known = MysticEnchant_GetKnownRESpellIds()
            if type(known) == "table" then
                for _, id in pairs(known) do
                    if tonumber(id) == spellId then isKnown = true break end
                end
            end
        end
    end)

    if isKnown then
        runeStatusText:SetText("|cffff5555[Already In Your Known Runes]|r")
    else
        runeStatusText:SetText("|cff00FF96[New Unlearned Rune - Quality: " .. qName .. "]|r")
    end

    if Utils then Utils:PlaySound("FANFARE") end
    offerFrame:Show()
end

function UI.RuneOffer:HideOffer()
    offerFrame:Hide()
end

-- Hook engine events
local offerWatcher = CreateFrame("Frame")
offerWatcher:RegisterEvent("CUSTOM_MYSTIC_ENCHANTMENT_ROLL_AVAILABLE")
offerWatcher:SetScript("OnEvent", function(self, event, ...)
    UI.RuneOffer:ShowOffer()
end)
