-- ============================================================================
-- GrimfallHelper: UI/UI_Minimap.lua
-- Draggable Minimap Launcher with Dynamic Status Tooltip
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.UI = GH.UI or {}
local UI = GH.UI
local Utils = GH.Utils

local minimapBtn = CreateFrame("Button", "GrimfallHelperMinimapButton", Minimap)
minimapBtn:SetSize(31, 31)
minimapBtn:SetFrameStrata("MEDIUM")
minimapBtn:SetFrameLevel(8)
minimapBtn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
minimapBtn:RegisterForDrag("LeftButton")
minimapBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-Button-Highlight")

-- Outer circular border
local overlay = minimapBtn:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

-- Center icon (Use a cool gem/portal texture)
local icon = minimapBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetTexture("Interface\\Icons\\Spell_Arcane_PortalDalaran")
icon:SetPoint("CENTER", minimapBtn, "CENTER", 0, 1)

-- Update Position around Minimap
local function UpdatePosition(angle)
    local rad = math.rad(angle or 45)
    local cx, cy = 0, 0
    local radius = 80
    local x = math.cos(rad) * radius
    local y = math.sin(rad) * radius
    minimapBtn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Dragging Logic
minimapBtn:SetScript("OnDragStart", function(self)
    self.isDragging = true
end)

minimapBtn:SetScript("OnDragStop", function(self)
    self.isDragging = false
end)

minimapBtn:SetScript("OnUpdate", function(self)
    if self.isDragging then
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local angle = math.deg(math.atan2(py - my, px - mx))
        if angle < 0 then angle = angle + 360 end
        GH.Config:Set("minimapPos", angle)
        UpdatePosition(angle)
    end
end)

-- Click Handlers
minimapBtn:SetScript("OnClick", function(self, button)
    Utils:PlaySound("CLICK")
    if button == "LeftButton" then
        if GH.UI.MainFrame then
            GH.UI.MainFrame:Toggle()
        end
    elseif button == "RightButton" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(2)
        end
    end
end)

-- Dynamic Tooltip
minimapBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:ClearLines()
    GameTooltip:AddLine("|cff00FF96Grimfall|r|cffffffffHelper|r |cff888888v1.1.0|r", 1, 1, 1)
    -- Build Overview & Runes
    local build = GH.BuildSharing and GH.BuildSharing:GetMyBuild()
    if build then
        local eval = build.evaluation or {}
        GameTooltip:AddDoubleLine("Build Archetype:", Utils:Colorize(eval.role or "Classless Adventurer", "FFD700"), 1, 1, 1)
        GameTooltip:AddDoubleLine("Build Value Score:", string.format("%d (%s)", eval.totalScore or 0, eval.ratingTitle or "Veteran"), 0.8, 0.8, 0.8, 0, 1, 0.5)
        GameTooltip:AddDoubleLine("Active Runes:", eval.breakdownStr or "0 active", 0.8, 0.8, 0.8, 1, 1, 1)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff00FF96Left-Click:|r Open Builds & Runes Dashboard", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff00FF96Right-Click:|r Open Shared Builds Inbox", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cff888888Drag to move around minimap|r", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

minimapBtn:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

UI.Minimap = {}

function UI.Minimap:Initialize()
    local savedAngle = GH.Config:Get("minimapPos", 45)
    UpdatePosition(savedAngle)
    if GH.Config:Get("showMinimap", true) then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end

function UI.Minimap:Toggle(show)
    if show == nil then
        if minimapBtn:IsShown() then minimapBtn:Hide() else minimapBtn:Show() end
    elseif show then
        minimapBtn:Show()
    else
        minimapBtn:Hide()
    end
end
