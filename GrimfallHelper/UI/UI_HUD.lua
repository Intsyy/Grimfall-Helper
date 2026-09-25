-- ============================================================================
-- GrimfallHelper: UI/UI_HUD.lua
-- Floating Hybrid Multi-Resource HUD & Buff Sentinel Reminder Bar
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.UI = GH.UI or {}
local UI = GH.UI
local Utils = GH.Utils
local EventBus = GH.EventBus

UI.HUD = {}
local HUD = UI.HUD

local hudFrame = CreateFrame("Frame", "GrimfallHelperHUDFrame", UIParent)
hudFrame:SetSize(220, 68)
hudFrame:SetMovable(true)
hudFrame:EnableMouse(true)
hudFrame:RegisterForDrag("LeftButton")
hudFrame:SetClampedToScreen(true)
hudFrame:SetFrameStrata("LOW")

UI:ApplyBackdrop(hudFrame, false)

-- Dragging scripts
hudFrame:SetScript("OnDragStart", function(self)
    if not GH.Config:Get("hudLocked", false) then
        self:StartMoving()
    end
end)

hudFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    GH.Config:Set("hudPoint", point)
    GH.Config:Set("hudRelPoint", relPoint)
    GH.Config:Set("hudX", math.floor(x))
    GH.Config:Set("hudY", math.floor(y))
end)

-- Health Bar
local healthBar = CreateFrame("StatusBar", nil, hudFrame)
healthBar:SetSize(206, 16)
healthBar:SetPoint("TOPLEFT", hudFrame, "TOPLEFT", 7, -7)
healthBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBar:SetStatusBarColor(0.1, 0.8, 0.2)
healthBar:SetMinMaxValues(0, 100)
healthBar:SetValue(100)

local healthBg = healthBar:CreateTexture(nil, "BACKGROUND")
healthBg:SetAllPoints(true)
healthBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
healthBg:SetVertexColor(0.2, 0.05, 0.05, 0.6)

local healthText = healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
healthText:SetPoint("CENTER", healthBar, "CENTER", 0, 0)
healthText:SetTextColor(1, 1, 1)

-- Power Bar
local powerBar = CreateFrame("StatusBar", nil, hudFrame)
powerBar:SetSize(206, 14)
powerBar:SetPoint("TOPLEFT", healthBar, "BOTTOMLEFT", 0, -3)
powerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
powerBar:SetStatusBarColor(0.2, 0.5, 1.0)
powerBar:SetMinMaxValues(0, 100)
powerBar:SetValue(100)

local powerBg = powerBar:CreateTexture(nil, "BACKGROUND")
powerBg:SetAllPoints(true)
powerBg:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
powerBg:SetVertexColor(0.05, 0.05, 0.2, 0.6)

local powerText = powerBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
powerText:SetPoint("CENTER", powerBar, "CENTER", 0, 0)
powerText:SetTextColor(1, 1, 1)

-- Combo Points Container (5 pips)
local comboPips = {}
local comboContainer = CreateFrame("Frame", nil, hudFrame)
comboContainer:SetSize(206, 10)
comboContainer:SetPoint("TOPLEFT", powerBar, "BOTTOMLEFT", 0, -3)

for i = 1, 5 do
    local pip = comboContainer:CreateTexture(nil, "ARTWORK")
    pip:SetSize(12, 10)
    pip:SetTexture("Interface\\Buttons\\WHITE8X8")
    pip:SetVertexColor(0.2, 0.2, 0.2, 0.8)
    pip:SetPoint("LEFT", comboContainer, "LEFT", (i - 1) * 42 + 14, 0)
    comboPips[i] = pip
end

-- Buff Sentinel Display (Shows up to 5 missing buffs below the HUD)
local sentinelContainer = CreateFrame("Frame", nil, hudFrame)
sentinelContainer:SetSize(206, 24)
sentinelContainer:SetPoint("TOPLEFT", hudFrame, "BOTTOMLEFT", 7, -2)

local buffIcons = {}
for i = 1, 5 do
    local btn = CreateFrame("Frame", nil, sentinelContainer)
    btn:SetSize(20, 20)
    btn:SetPoint("LEFT", sentinelContainer, "LEFT", (i - 1) * 24, 0)

    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetAllPoints(true)
    iconTex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = iconTex

    -- Red warning border
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(1, 0.2, 0.2, 0.8)

    btn:SetScript("OnEnter", function(self)
        if self.auraName then
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("|cffFF3333Missing Buff:|r " .. self.auraName, 1, 1, 1)
            GameTooltip:Show()
        end
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    btn:Hide()
    buffIcons[i] = btn
end

-- Update HUD Values
function HUD:Update()
    if not GH.ResourceEngine then return end
    local snap = GH.ResourceEngine:GetSnapshot()

    -- Health
    healthBar:SetMinMaxValues(0, snap.hpMax)
    healthBar:SetValue(snap.hp)
    healthText:SetText(Utils:FormatNumber(snap.hp) .. " / " .. Utils:FormatNumber(snap.hpMax) .. " (" .. snap.hpPercent .. "%)")

    -- Smooth green-yellow-red color transition
    local pct = snap.hpPercent / 100
    if pct > 0.5 then
        healthBar:SetStatusBarColor((1 - pct) * 2, 1, 0.2)
    else
        healthBar:SetStatusBarColor(1, pct * 2, 0.2)
    end

    -- Power
    powerBar:SetMinMaxValues(0, snap.powerMax)
    powerBar:SetValue(snap.power)
    powerBar:SetStatusBarColor(snap.powerR, snap.powerG, snap.powerB)
    powerText:SetText(snap.powerName .. ": " .. Utils:FormatNumber(snap.power) .. " / " .. Utils:FormatNumber(snap.powerMax) .. " (" .. snap.powerPercent .. "%)")

    -- Combo Points
    for i = 1, 5 do
        if i <= snap.comboPoints then
            if i == 5 then
                comboPips[i]:SetVertexColor(1.0, 0.2, 0.2, 1.0) -- Red for 5
            else
                comboPips[i]:SetVertexColor(1.0, 0.8, 0.0, 1.0) -- Orange/Yellow for 1-4
            end
        else
            comboPips[i]:SetVertexColor(0.2, 0.2, 0.2, 0.6)
        end
    end

    -- Buff Sentinel
    local missing = snap.missingBuffs
    for i = 1, 5 do
        if missing[i] then
            buffIcons[i].icon:SetTexture("Interface\\Icons\\" .. missing[i].icon)
            buffIcons[i].auraName = missing[i].aura
            buffIcons[i]:Show()
        else
            buffIcons[i]:Hide()
        end
    end
end

-- Initialize Position & Visibility
function HUD:Initialize()
    local point = GH.Config:Get("hudPoint", "CENTER")
    local relPoint = GH.Config:Get("hudRelPoint", "CENTER")
    local x = GH.Config:Get("hudX", 0)
    local y = GH.Config:Get("hudY", -140)

    hudFrame:ClearAllPoints()
    hudFrame:SetPoint(point, UIParent, relPoint, x, y)

    if GH.Config:Get("showHUD", true) then
        hudFrame:Show()
    else
        hudFrame:Hide()
    end

    self:Update()
end

-- Toggle Visibility
function HUD:Toggle(show)
    if show == nil then
        if hudFrame:IsShown() then hudFrame:Hide() else hudFrame:Show() end
    elseif show then
        hudFrame:Show()
    else
        hudFrame:Hide()
    end
    GH.Config:Set("showHUD", hudFrame:IsShown())
end

-- Event Listeners
EventBus:RegisterCustom("GH_HUD_UPDATE", function()
    HUD:Update()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    HUD:Initialize()
end)
