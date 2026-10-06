-- ============================================================================
-- GrimfallHelper: UI/UI_Core.lua
-- Theming, Widget Factories, Custom Dark Fantasy Styling, and Alert Banners
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.UI = GH.UI or {}
local UI = GH.UI
local Utils = GH.Utils

-- Theme Colors
UI.Theme = {
    bg = { 0.07, 0.08, 0.11, 0.94 },
    panelBg = { 0.11, 0.12, 0.16, 0.85 },
    border = { 0.22, 0.25, 0.32, 1.0 },
    gold = { 1.0, 0.82, 0.0, 1.0 },
    green = { 0.0, 1.0, 0.59, 1.0 },
    red = { 0.9, 0.2, 0.2, 1.0 },
    cyan = { 0.0, 0.82, 1.0, 1.0 },
    text = { 0.9, 0.9, 0.9, 1.0 },
    textDim = { 0.6, 0.6, 0.6, 1.0 },
}

-- Standard Dark Fantasy Backdrop Table
UI.BackdropMain = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}

UI.BackdropPanel = {
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = false,
    tileSize = 16,
    edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
}

-- Apply Theme Backdrop to a Frame
function UI:ApplyBackdrop(frame, isPanel)
    local bd = isPanel and self.BackdropPanel or self.BackdropMain
    frame:SetBackdrop(bd)
    if isPanel then
        frame:SetBackdropColor(self.Theme.panelBg[1], self.Theme.panelBg[2], self.Theme.panelBg[3], self.Theme.panelBg[4])
        frame:SetBackdropBorderColor(self.Theme.border[1], self.Theme.border[2], self.Theme.border[3], self.Theme.border[4])
    else
        frame:SetBackdropColor(self.Theme.bg[1], self.Theme.bg[2], self.Theme.bg[3], self.Theme.bg[4])
        frame:SetBackdropBorderColor(self.Theme.gold[1] * 0.7, self.Theme.gold[2] * 0.7, self.Theme.gold[3] * 0.7, 0.9)
    end
end

-- Create Themed Push Button
function UI:CreateButton(parent, text, width, height, isAccent)
    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetWidth(width or 100)
    btn:SetHeight(height or 24)
    btn:SetText(text or "")

    local font = btn:GetFontString()
    if font then
        font:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
        if isAccent then
            font:SetTextColor(0.0, 1.0, 0.6)
        else
            font:SetTextColor(1.0, 0.9, 0.7)
        end
    end

    return btn
end

-- Create Themed Checkbox
function UI:CreateCheckbox(parent, labelText, defaultVal, onClick)
    local check = CreateFrame("CheckButton", nil, parent, "OptionsCheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    check:SetChecked(defaultVal and true or false)

    local text = check:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", check, "RIGHT", 4, 0)
    text:SetText(labelText)
    text:SetTextColor(0.9, 0.9, 0.9)
    check.label = text

    check:SetScript("OnClick", function(self)
        local isChecked = self:GetChecked() and true or false
        Utils:PlaySound("CLICK")
        if onClick then
            onClick(isChecked)
        end
    end)

    return check
end

-- Create Themed EditBox
function UI:CreateEditBox(parent, width, height, maxChars)
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetWidth(width or 160)
    edit:SetHeight(height or 22)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetAutoFocus(false)
    edit:SetMaxLetters(maxChars or 100)
    edit:SetTextInsets(6, 6, 0, 0)

    edit:SetBackdrop(UI.BackdropPanel)
    edit:SetBackdropColor(0.05, 0.05, 0.07, 0.9)
    edit:SetBackdropBorderColor(0.3, 0.35, 0.4, 0.8)

    edit:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)

    return edit
end

-- Create On-Screen Banner Alert Notification
local alertFrame = CreateFrame("Frame", "GrimfallHelperAlertBanner", UIParent)
alertFrame:SetSize(420, 80)
alertFrame:SetPoint("TOP", UIParent, "TOP", 0, -180)
alertFrame:SetBackdrop(UI.BackdropMain)
alertFrame:SetBackdropColor(0.05, 0.06, 0.09, 0.95)
alertFrame:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
alertFrame:SetFrameStrata("TOOLTIP")
alertFrame:Hide()

local alertText = alertFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
alertText:SetPoint("CENTER", alertFrame, "CENTER", 0, 0)
alertText:SetJustifyH("CENTER")

local alertTimer = 0
alertFrame:SetScript("OnUpdate", function(self, elapsed)
    alertTimer = alertTimer - elapsed
    if alertTimer <= 0 then
        self:Hide()
    elseif alertTimer < 0.8 then
        self:SetAlpha(alertTimer / 0.8)
    else
        self:SetAlpha(1.0)
    end
end)

function UI:ShowAlertBanner(msg, hexColor)
    alertText:SetText(Utils:Colorize(msg, hexColor or "FFD700"))
    alertFrame:SetAlpha(1.0)
    alertTimer = 3.5
    alertFrame:Show()
end
