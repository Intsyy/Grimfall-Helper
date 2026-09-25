-- ============================================================================
-- GrimfallHelper: UI/UI_MainFrame.lua
-- Generalized Grimfall Dashboard:
-- Tab 1: Builds (View Own / Imported / Shared Builds & Value Evaluator)
-- Tab 2: Shared Builds (Session-Only Inbox of Received Player Builds)
-- Tab 3: Spellbook (Classless Ability Browser)
-- Tab 4: Export & Share (Full Build Export, Compact Code & Chat Broadcast)
-- Tab 5: Rune List (Search all 2,615 Grimfall Runes)
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.UI = GH.UI or {}
local UI = GH.UI
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

UI.MainFrame = {}
local MF = UI.MainFrame

-- Quality Color Table
local QUALITY_COLORS = {
    [5] = "ff8000", -- Legendary (Orange)
    [4] = "a335ee", -- Epic (Purple)
    [3] = "0070dd", -- Rare (Blue)
    [2] = "1eff00", -- Uncommon (Green)
    [1] = "ffffff", -- Common (White)
}

local QUALITY_LABELS = {
    [5] = "Legendary",
    [4] = "Epic",
    [3] = "Rare",
    [2] = "Uncommon",
    [1] = "Common",
}

-- Create Primary Main Frame
local frame = CreateFrame("Frame", "GrimfallHelperMainFrame", UIParent)
frame:SetSize(780, 530)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:Hide()

UI:ApplyBackdrop(frame, false)
tinsert(UISpecialFrames, "GrimfallHelperMainFrame") -- Enable ESC to close

-- Drag handlers
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    GH.Config:Set("windowPoint", point)
    GH.Config:Set("windowRelPoint", relPoint)
    GH.Config:Set("windowX", math.floor(x))
    GH.Config:Set("windowY", math.floor(y))
end)

-- Title Bar
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -14)
title:SetText("|cff00FF96GRIMFALL|r |cffffffffHELPER|r  |cff888888(Builds, Runes & Sharing)|r")

-- Close Button
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
closeBtn:SetScript("OnClick", function()
    Utils:PlaySound("CLICK")
    frame:Hide()
end)

-- Tab Configuration
local TAB_NAMES = {
    "Builds",
    "Shared Builds",
    "Spellbook",
    "Export & Share",
    "Rune List"
}

local tabs = {}
local tabPanels = {}
local currentTab = 1

-- Tab Switch Handler
function MF:SelectTab(tabIndex)
    currentTab = tabIndex
    GH.Config:Set("selectedTab", tabIndex)

    for i, tab in ipairs(tabs) do
        if i == tabIndex then
            tab:SetBackdropColor(0.18, 0.20, 0.26, 1.0)
            tab:SetBackdropBorderColor(1.0, 0.82, 0.0, 1.0)
            tab.text:SetTextColor(1.0, 0.82, 0.0)
            tabPanels[i]:Show()
        else
            tab:SetBackdropColor(0.10, 0.11, 0.14, 0.8)
            tab:SetBackdropBorderColor(0.25, 0.28, 0.35, 0.8)
            tab.text:SetTextColor(0.7, 0.7, 0.7)
            tabPanels[i]:Hide()
        end
    end

    self:RefreshCurrentTab()
end

function MF:RefreshCurrentTab()
    if currentTab == 1 and MF.RefreshInspect then
        MF:RefreshInspect()
    elseif currentTab == 2 and MF.RefreshSharedTab then
        MF:RefreshSharedTab()
    elseif currentTab == 3 and MF.RefreshSpellbook then
        MF:RefreshSpellbook()
    elseif currentTab == 4 and MF.RefreshExport then
        MF:RefreshExport()
    elseif currentTab == 5 and MF.RefreshRuneDatabase then
        MF:RefreshRuneDatabase()
    end
end

-- Create Tab Headers & Panel Containers
local tabContainer = CreateFrame("Frame", nil, frame)
tabContainer:SetSize(756, 28)
tabContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -40)

for i, name in ipairs(TAB_NAMES) do
    local tab = CreateFrame("Button", nil, tabContainer)
    tab:SetSize(148, 26)
    tab:SetPoint("LEFT", tabContainer, "LEFT", (i - 1) * 152, 0)
    UI:ApplyBackdrop(tab, true)

    local txt = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    txt:SetPoint("CENTER", tab, "CENTER", 0, 0)
    txt:SetText(name)
    tab.text = txt

    tab:SetScript("OnClick", function()
        Utils:PlaySound("CLICK")
        MF:SelectTab(i)
    end)

    tabs[i] = tab

    local panel = CreateFrame("Frame", nil, frame)
    panel:SetSize(756, 446)
    panel:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -72)
    panel:Hide()
    tabPanels[i] = panel
end


-- ============================================================================
-- TAB 1: BUILDS (Local Player Build, Evaluator & Import)
-- ============================================================================
local p1 = tabPanels[1]
local inspectMode = "MY_BUILD" -- "MY_BUILD", "IMPORTED", or "SHARED"
local displayedBuild = nil

-- Top Action Bar
local topBar = CreateFrame("Frame", nil, p1)
topBar:SetSize(756, 32)
topBar:SetPoint("TOPLEFT", p1, "TOPLEFT", 0, 0)
UI:ApplyBackdrop(topBar, true)

local myBuildBtn = UI:CreateButton(topBar, "My Build", 95, 22, true)
myBuildBtn:SetPoint("LEFT", topBar, "LEFT", 6, 0)

local sendTargetBtn = UI:CreateButton(topBar, "Send to Target", 120, 22, true)
sendTargetBtn:SetPoint("LEFT", myBuildBtn, "RIGHT", 8, 0)

local partyShareBtn = UI:CreateButton(topBar, "Share to Party", 110, 22)
partyShareBtn:SetPoint("LEFT", sendTargetBtn, "RIGHT", 8, 0)

local guildShareBtn = UI:CreateButton(topBar, "Share to Guild", 110, 22)
guildShareBtn:SetPoint("LEFT", partyShareBtn, "RIGHT", 8, 0)

local importCodeBtn = UI:CreateButton(topBar, "Import Code", 100, 22)
importCodeBtn:SetPoint("RIGHT", topBar, "RIGHT", -6, 0)

-- Import Modal Frame
local importFrame = CreateFrame("Frame", nil, p1)
importFrame:SetSize(756, 34)
importFrame:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -4)
UI:ApplyBackdrop(importFrame, true)
importFrame:Hide()

local importInput = UI:CreateEditBox(importFrame, 620, 22, 1000)
importInput:SetPoint("LEFT", importFrame, "LEFT", 8, 0)

local importApplyBtn = UI:CreateButton(importFrame, "Load Build", 90, 22, true)
importApplyBtn:SetPoint("LEFT", importInput, "RIGHT", 8, 0)

importCodeBtn:SetScript("OnClick", function()
    if importFrame:IsShown() then
        importFrame:Hide()
    else
        importFrame:Show()
        importInput:SetFocus()
    end
end)

importApplyBtn:SetScript("OnClick", function()
    local text = importInput:GetText()
    if text and text ~= "" and GH.BuildSharing then
        local b = GH.BuildSharing:ParseBuildCode(text)
        if b then
            displayedBuild = b
            inspectMode = "IMPORTED"
            importFrame:Hide()
            importInput:SetText("")
            MF:RefreshInspect()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Loaded imported build successfully!")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r Invalid build code or text format.")
        end
    end
end)

myBuildBtn:SetScript("OnClick", function()
    inspectMode = "MY_BUILD"
    displayedBuild = GH.BuildSharing and GH.BuildSharing:GetMyBuild() or nil
    MF:RefreshInspect()
end)

sendTargetBtn:SetScript("OnClick", function()
    if GH.BuildSharing then
        GH.BuildSharing:SendBuildToTarget()
    end
end)

partyShareBtn:SetScript("OnClick", function()
    if GH.BuildSharing then
        GH.BuildSharing:ShareToChat("PARTY")
    end
end)

guildShareBtn:SetScript("OnClick", function()
    if GH.BuildSharing then
        GH.BuildSharing:ShareToChat("GUILD")
    end
end)

-- Build Overview Summary Card (Height 132 to cleanly present Attributes, Stats & Talents)
local overviewCard = CreateFrame("Frame", nil, p1)
overviewCard:SetSize(756, 132)
overviewCard:SetPoint("TOPLEFT", topBar, "BOTTOMLEFT", 0, -6)
UI:ApplyBackdrop(overviewCard, true)

local charTitle = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
charTitle:SetPoint("TOPLEFT", overviewCard, "TOPLEFT", 14, -10)

local ilvlBadge = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
ilvlBadge:SetPoint("LEFT", charTitle, "RIGHT", 10, 0)

local archetypeBadge = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
archetypeBadge:SetPoint("LEFT", ilvlBadge, "RIGHT", 8, 0)

local valueRatingText = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
valueRatingText:SetPoint("TOPLEFT", charTitle, "BOTTOMLEFT", 0, -6)

local runeSummaryText = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
runeSummaryText:SetPoint("LEFT", valueRatingText, "RIGHT", 14, 0)

local attrSummaryText = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
attrSummaryText:SetPoint("TOPLEFT", valueRatingText, "BOTTOMLEFT", 0, -5)
attrSummaryText:SetWidth(728)
attrSummaryText:SetJustifyH("LEFT")

local combatSummaryText = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
combatSummaryText:SetPoint("TOPLEFT", attrSummaryText, "BOTTOMLEFT", 0, -4)
combatSummaryText:SetWidth(728)
combatSummaryText:SetJustifyH("LEFT")

local talentSummaryText = overviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
talentSummaryText:SetPoint("TOPLEFT", combatSummaryText, "BOTTOMLEFT", 0, -4)
talentSummaryText:SetWidth(728)
talentSummaryText:SetJustifyH("LEFT")
talentSummaryText:SetWordWrap(true)

-- Scrollable Active Runes & Details List
local buildScrollFrame = CreateFrame("ScrollFrame", "GrimfallBuildScrollFrame", p1, "UIPanelScrollFrameTemplate")
buildScrollFrame:SetPoint("TOPLEFT", overviewCard, "BOTTOMLEFT", 0, -6)
buildScrollFrame:SetPoint("BOTTOMRIGHT", p1, "BOTTOMRIGHT", -26, 6)

local buildContent = CreateFrame("Frame", nil, buildScrollFrame)
buildContent:SetSize(720, 800)
buildScrollFrame:SetScrollChild(buildContent)

local runeCards = {}
local emptyRuneNotice = nil

function MF:RefreshInspect()
    if inspectMode == "MY_BUILD" or not displayedBuild then
        if GH.BuildSharing then
            displayedBuild = GH.BuildSharing:GetMyBuild()
        end
    end

    if not displayedBuild then return end
    local b = displayedBuild
    local eval = b.evaluation or (GH.BuildEvaluator and GH.BuildEvaluator:EvaluateBuild(b)) or {}

    -- Update Summary Card
    local modePrefix = (inspectMode == "MY_BUILD" and "|cff00FF96[My Build]|r ") or (inspectMode == "IMPORTED" and "|cffa335ee[Imported Build]|r ") or "|cffFFD700[Shared Build]|r "
    charTitle:SetText(modePrefix .. "|cffffffff" .. (b.name or "Hero") .. "|r  |cff888888(Lvl " .. (b.level or 80) .. " " .. (b.race or "") .. " " .. (b.class or "Hero") .. ")|r")

    local s = b.stats or {}
    if s.ilvl and tonumber(s.ilvl) and tonumber(s.ilvl) > 0 then
        ilvlBadge:SetText(string.format("|cffffd100[iLvl %d]|r", tonumber(s.ilvl)))
        ilvlBadge:Show()
    else
        ilvlBadge:SetText("")
        ilvlBadge:Hide()
    end

    archetypeBadge:SetText("|cff00FF96• " .. (eval.role or "Classless Adventurer") .. "|r")
    local scoreStr = string.format("Build Value Score: %s%d|r (%s%s|r)", eval.ratingColor or "|cffffd100", eval.totalScore or 0, eval.ratingColor or "|cffffd100", eval.ratingTitle or "Veteran")
    valueRatingText:SetText(scoreStr)
    runeSummaryText:SetText("•  Runes: |cffffffff" .. #(b.runes or {}) .. " active|r (" .. (eval.breakdownStr or "None") .. ")")

    -- Attributes line (Str, Agi, Sta, Int, Spi)
    local strVal = tonumber(s.str) or 0
    local agiVal = tonumber(s.agi) or 0
    local staVal = tonumber(s.sta) or 0
    local intVal = tonumber(s.int) or 0
    local spiVal = tonumber(s.spi) or 0
    attrSummaryText:SetText(string.format("|cffffd100Attributes:|r  Str: |cffffffff%d|r  •  Agi: |cffffffff%d|r  •  Sta: |cffffffff%d|r  •  Int: |cffffffff%d|r  •  Spi: |cffffffff%d|r",
        strVal, agiVal, staVal, intVal, spiVal))

    -- Combat stats line (AP, SP, Crit, Hit, Armor, Def)
    combatSummaryText:SetText(string.format("|cffffd100Combat Stats:|r  AP: |cffffffff%s|r  •  SP: |cffffffff%s|r  •  Crit: |cffffffff%s|r  •  Hit: |cffffffff%s|r  •  Armor: |cffffffff%s|r  •  Def: |cffffffff%s|r",
        s.ap or 0, s.sp or 0, s.meleeCrit or "0%", s.hit or "0%", s.armor or 0, s.defense or 0))

    -- Talents line
    talentSummaryText:SetText(string.format("|cffffd100Talents Allocated (%d pts):|r |cffffffff%s|r", b.talentCount or 0, b.talentSummary or "None"))

    -- Render Active Rune Cards
    for _, card in ipairs(runeCards) do card:Hide() end

    local runes = b.runes or {}
    local yOffset = 0

    if #runes == 0 then
        if not emptyRuneNotice then
            emptyRuneNotice = buildContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            emptyRuneNotice:SetPoint("TOP", buildContent, "TOP", 0, -40)
            emptyRuneNotice:SetWidth(600)
            emptyRuneNotice:SetJustifyH("CENTER")
        end
        if inspectMode == "MY_BUILD" then
            emptyRuneNotice:SetText("|cffaaaaaaNo active runes detected on your character.\n\nOpen your |cffffd100Classless|r panel to verify socketed runes,\nor socket runes into your Mystic Enchant slots.|r")
        else
            emptyRuneNotice:SetText("|cffaaaaaaNo active runes detected in this build.|r")
        end
        emptyRuneNotice:Show()
    else
        if emptyRuneNotice then emptyRuneNotice:Hide() end
    end

    for i, r in ipairs(runes) do
        local card = runeCards[i]
        if not card then
            card = CreateFrame("Frame", nil, buildContent)
            card:SetSize(720, 64)
            UI:ApplyBackdrop(card, true)

            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(40, 40)
            card.icon:SetPoint("LEFT", card, "LEFT", 12, 0)
            card.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
            card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 12, -2)

            card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.badge:SetPoint("LEFT", card.name, "RIGHT", 10, 0)

            card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.desc:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
            card.desc:SetWidth(640)
            card.desc:SetJustifyH("LEFT")
            card.desc:SetWordWrap(true)

            runeCards[i] = card
        end

        card:SetPoint("TOPLEFT", buildContent, "TOPLEFT", 0, -yOffset)

        local q = tonumber(r.quality) or 2
        local qColor = QUALITY_COLORS[q] or "ffffff"
        local qLabel = QUALITY_LABELS[q] or "Uncommon"

        card:SetBackdropBorderColor(
            tonumber(string.sub(qColor, 1, 2), 16) / 255,
            tonumber(string.sub(qColor, 3, 4), 16) / 255,
            tonumber(string.sub(qColor, 5, 6), 16) / 255,
            0.9
        )

        local icon = nil
        if r.spellId and r.spellId > 0 then
            local _, _, spIcon = GetSpellInfo(r.spellId)
            icon = spIcon
        end
        card.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Rune_01")

        card.name:SetText(string.format("|cff%s%s|r", qColor, r.name or ("Rune of Spell " .. (r.spellId or 0))))
        card.badge:SetText(string.format("|cff888888[%s | Spell ID: %d]|r", qLabel, r.spellId or 0))
        card.desc:SetText(r.desc and r.desc ~= "" and r.desc or "Grimfall Runic Enhancement")

        local textHeight = card.desc:GetStringHeight() or 14
        local cardH = math.max(64, textHeight + 36)
        card:SetHeight(cardH)

        card:Show()
        yOffset = yOffset + cardH + 6
    end

    buildContent:SetHeight(math.max(300, yOffset + 10))
end

-- Display an external or shared build in Tab 1
function MF:DisplayBuild(build, mode)
    if not build then return end
    displayedBuild = build
    inspectMode = mode or "SHARED"
    if not frame:IsShown() then
        frame:Show()
    end
    if currentTab ~= 1 then
        self:SelectTab(1)
    else
        self:RefreshInspect()
    end
end
GH.UI.MainFrame.DisplayBuild = function(self, build, mode) MF:DisplayBuild(build, mode) end


-- ============================================================================
-- TAB 2: SHARED BUILDS (Session Inbox & Detail Inspector)
-- ============================================================================
local p2 = tabPanels[2]

-- View 1: List View (Headline details of all received builds)
local sharedListView = CreateFrame("Frame", nil, p2)
sharedListView:SetAllPoints(p2)

-- View 2: Detail View (Full inspect of selected build: runes, talents, stats)
local sharedDetailView = CreateFrame("Frame", nil, p2)
sharedDetailView:SetAllPoints(p2)
sharedDetailView:Hide()

local currentDetailBuild = nil

-- LIST VIEW: Top Header Card with Disclaimer
local listHeader = CreateFrame("Frame", nil, sharedListView)
listHeader:SetSize(756, 48)
listHeader:SetPoint("TOPLEFT", sharedListView, "TOPLEFT", 0, 0)
UI:ApplyBackdrop(listHeader, true)

local listTitle = listHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
listTitle:SetPoint("TOPLEFT", listHeader, "TOPLEFT", 12, -8)
listTitle:SetText("|cff00FF96Shared Builds Inbox|r")

local listCountText = listHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
listCountText:SetPoint("LEFT", listTitle, "RIGHT", 12, 0)
listCountText:SetText("|cff8888880 builds received this session|r")

local clearAllBtn = UI:CreateButton(listHeader, "Clear All", 75, 20)
clearAllBtn:SetPoint("TOPRIGHT", listHeader, "TOPRIGHT", -10, -8)
clearAllBtn:SetScript("OnClick", function()
    GH.ReceivedBuilds = {}
    MF:RefreshSharedTab()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Shared builds session list cleared.")
end)

-- Prominent User-Requested Disclaimer Banner
local disclaimerText = listHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
disclaimerText:SetPoint("TOPLEFT", listTitle, "BOTTOMLEFT", 0, -6)
disclaimerText:SetText("|cffffaa00⚠️ Disclaimer:|r |cff888888Builds received are stored for this session only and will be lost if you exit or reload the game.|r")

-- LIST VIEW: Scrollable List Frame
local sharedScrollFrame = CreateFrame("ScrollFrame", "GrimfallSharedScrollFrame", sharedListView, "UIPanelScrollFrameTemplate")
sharedScrollFrame:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -6)
sharedScrollFrame:SetPoint("BOTTOMRIGHT", sharedListView, "BOTTOMRIGHT", -26, 6)

local sharedListContent = CreateFrame("Frame", nil, sharedScrollFrame)
sharedListContent:SetSize(720, 600)
sharedScrollFrame:SetScrollChild(sharedListContent)

local emptySharedNotice = sharedListContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
emptySharedNotice:SetPoint("TOP", sharedListContent, "TOP", 0, -40)
emptySharedNotice:SetWidth(600)
emptySharedNotice:SetJustifyH("CENTER")
emptySharedNotice:SetText("|cffffd100No shared builds received yet this session.|r\n\n|cffaaaaaaWhen another player whispers you their build code or clicks |cffffffff'Send to Target'|r,\ntheir build will automatically be collected here without interrupting your game.\n\nClick on any build in this list to inspect all of their runes, talents, and stats!|r")

local sharedBuildCards = {}

-- DETAIL VIEW: Top Bar
local detailTopBar = CreateFrame("Frame", nil, sharedDetailView)
detailTopBar:SetSize(756, 32)
detailTopBar:SetPoint("TOPLEFT", sharedDetailView, "TOPLEFT", 0, 0)
UI:ApplyBackdrop(detailTopBar, true)

local backToListBtn = UI:CreateButton(detailTopBar, "< Back to Shared List", 150, 22, true)
backToListBtn:SetPoint("LEFT", detailTopBar, "LEFT", 6, 0)
backToListBtn:SetScript("OnClick", function()
    sharedDetailView:Hide()
    sharedListView:Show()
    MF:RefreshSharedTab()
end)

local detailCopyCodeBtn = UI:CreateButton(detailTopBar, "Copy Build Code", 125, 22)
detailCopyCodeBtn:SetPoint("LEFT", backToListBtn, "RIGHT", 8, 0)
detailCopyCodeBtn:SetScript("OnClick", function()
    if currentDetailBuild and GH.BuildSharing then
        local code = GH.BuildSharing:GenerateBuildCode(currentDetailBuild)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Build Code for " .. (currentDetailBuild.name or "Hero") .. ": " .. code)
        if type(ChatEdit_ChooseBoxForSend) == "function" then
            local eb = ChatEdit_ChooseBoxForSend()
            if eb then
                ChatEdit_ActivateChat(eb)
                eb:SetText(code)
                eb:HighlightText()
            end
        end
    end
end)

-- DETAIL VIEW: Summary Header Card (Height 132 to cleanly present Attributes, Stats & Talents)
local detailOverviewCard = CreateFrame("Frame", nil, sharedDetailView)
detailOverviewCard:SetSize(756, 132)
detailOverviewCard:SetPoint("TOPLEFT", detailTopBar, "BOTTOMLEFT", 0, -6)
UI:ApplyBackdrop(detailOverviewCard, true)

local detailCharTitle = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
detailCharTitle:SetPoint("TOPLEFT", detailOverviewCard, "TOPLEFT", 14, -10)

local detailIlvlBadge = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
detailIlvlBadge:SetPoint("LEFT", detailCharTitle, "RIGHT", 10, 0)

local detailRoleBadge = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
detailRoleBadge:SetPoint("LEFT", detailIlvlBadge, "RIGHT", 8, 0)

local detailScoreText = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontNormal")
detailScoreText:SetPoint("TOPLEFT", detailCharTitle, "BOTTOMLEFT", 0, -6)

local detailRuneCountLine = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailRuneCountLine:SetPoint("LEFT", detailScoreText, "RIGHT", 14, 0)

local detailAttrLine = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailAttrLine:SetPoint("TOPLEFT", detailScoreText, "BOTTOMLEFT", 0, -5)
detailAttrLine:SetWidth(728)
detailAttrLine:SetJustifyH("LEFT")

local detailCombatLine = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailCombatLine:SetPoint("TOPLEFT", detailAttrLine, "BOTTOMLEFT", 0, -4)
detailCombatLine:SetWidth(728)
detailCombatLine:SetJustifyH("LEFT")

local detailTalentLine = detailOverviewCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
detailTalentLine:SetPoint("TOPLEFT", detailCombatLine, "BOTTOMLEFT", 0, -4)
detailTalentLine:SetWidth(728)
detailTalentLine:SetJustifyH("LEFT")
detailTalentLine:SetWordWrap(true)

-- DETAIL VIEW: Scrollable Rune Cards List
local detailScrollFrame = CreateFrame("ScrollFrame", "GrimfallDetailScrollFrame", sharedDetailView, "UIPanelScrollFrameTemplate")
detailScrollFrame:SetPoint("TOPLEFT", detailOverviewCard, "BOTTOMLEFT", 0, -6)
detailScrollFrame:SetPoint("BOTTOMRIGHT", sharedDetailView, "BOTTOMRIGHT", -26, 6)

local detailRuneContent = CreateFrame("Frame", nil, detailScrollFrame)
detailRuneContent:SetSize(720, 800)
detailScrollFrame:SetScrollChild(detailRuneContent)

local detailRuneCards = {}
local detailEmptyRuneNotice = nil

-- Function to open Detail View for a given build
function MF:OpenSharedBuildDetail(build)
    if not build then return end
    currentDetailBuild = build
    sharedListView:Hide()
    sharedDetailView:Show()

    local eval = build.evaluation or (GH.BuildEvaluator and GH.BuildEvaluator:EvaluateBuild(build)) or {}
    detailCharTitle:SetText("|cffFFD700[Shared Build]|r |cffffffff" .. (build.name or "Hero") .. "|r  |cff888888(Lvl " .. (build.level or 80) .. " " .. (build.race or "") .. " " .. (build.class or "Hero") .. ")|r")

    local s = build.stats or {}
    if s.ilvl and tonumber(s.ilvl) and tonumber(s.ilvl) > 0 then
        detailIlvlBadge:SetText(string.format("|cffffd100[iLvl %d]|r", tonumber(s.ilvl)))
        detailIlvlBadge:Show()
    else
        detailIlvlBadge:SetText("")
        detailIlvlBadge:Hide()
    end

    detailRoleBadge:SetText("|cff00FF96• " .. (eval.role or "Classless Adventurer") .. "|r")

    local scoreStr = string.format("Build Value Score: %s%d|r (%s%s|r)", eval.ratingColor or "|cffffd100", eval.totalScore or 0, eval.ratingColor or "|cffffd100", eval.ratingTitle or "Veteran")
    detailScoreText:SetText(scoreStr)
    detailRuneCountLine:SetText("•  Runes: |cffffffff" .. #(build.runes or {}) .. " active|r (" .. (eval.breakdownStr or "None") .. ")")

    -- Attributes line (Str, Agi, Sta, Int, Spi)
    local strVal = tonumber(s.str) or 0
    local agiVal = tonumber(s.agi) or 0
    local staVal = tonumber(s.sta) or 0
    local intVal = tonumber(s.int) or 0
    local spiVal = tonumber(s.spi) or 0
    detailAttrLine:SetText(string.format("|cffffd100Attributes:|r  Str: |cffffffff%d|r  •  Agi: |cffffffff%d|r  •  Sta: |cffffffff%d|r  •  Int: |cffffffff%d|r  •  Spi: |cffffffff%d|r",
        strVal, agiVal, staVal, intVal, spiVal))

    -- Combat stats line (AP, SP, Crit, Hit, Armor, Def)
    detailCombatLine:SetText(string.format("|cffffd100Combat Stats:|r  AP: |cffffffff%s|r  •  SP: |cffffffff%s|r  •  Crit: |cffffffff%s|r  •  Hit: |cffffffff%s|r  •  Armor: |cffffffff%s|r  •  Def: |cffffffff%s|r",
        s.ap or 0, s.sp or 0, s.meleeCrit or "0%", s.hit or "0%", s.armor or 0, s.defense or 0))

    -- Talents line
    detailTalentLine:SetText(string.format("|cffffd100Talents Allocated (%d pts):|r |cffffffff%s|r", build.talentCount or 0, build.talentSummary or "None"))

    -- Render Runes
    for _, card in ipairs(detailRuneCards) do card:Hide() end
    local runes = build.runes or {}
    local yOffset = 0

    if #runes == 0 then
        if not detailEmptyRuneNotice then
            detailEmptyRuneNotice = detailRuneContent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            detailEmptyRuneNotice:SetPoint("TOP", detailRuneContent, "TOP", 0, -40)
            detailEmptyRuneNotice:SetWidth(600)
            detailEmptyRuneNotice:SetJustifyH("CENTER")
        end
        detailEmptyRuneNotice:SetText("|cffaaaaaaNo active runes detected in this build.|r")
        detailEmptyRuneNotice:Show()
    else
        if detailEmptyRuneNotice then detailEmptyRuneNotice:Hide() end
    end

    for i, r in ipairs(runes) do
        local card = detailRuneCards[i]
        if not card then
            card = CreateFrame("Frame", nil, detailRuneContent)
            card:SetSize(720, 64)
            UI:ApplyBackdrop(card, true)

            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(40, 40)
            card.icon:SetPoint("LEFT", card, "LEFT", 12, 0)
            card.icon:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
            card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 12, -2)

            card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.badge:SetPoint("LEFT", card.name, "RIGHT", 10, 0)

            card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.desc:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
            card.desc:SetWidth(640)
            card.desc:SetJustifyH("LEFT")
            card.desc:SetWordWrap(true)

            detailRuneCards[i] = card
        end

        card:SetPoint("TOPLEFT", detailRuneContent, "TOPLEFT", 0, -yOffset)

        local q = tonumber(r.quality) or 2
        local qColor = QUALITY_COLORS[q] or "ffffff"
        local qLabel = QUALITY_LABELS[q] or "Uncommon"

        card:SetBackdropBorderColor(
            tonumber(string.sub(qColor, 1, 2), 16) / 255,
            tonumber(string.sub(qColor, 3, 4), 16) / 255,
            tonumber(string.sub(qColor, 5, 6), 16) / 255,
            0.9
        )

        local icon = nil
        if r.spellId and r.spellId > 0 then
            local _, _, spIcon = GetSpellInfo(r.spellId)
            icon = spIcon
        end
        card.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_Rune_01")

        card.name:SetText(string.format("|cff%s%s|r", qColor, r.name or ("Rune of Spell " .. (r.spellId or 0))))
        card.badge:SetText(string.format("|cff888888[%s | Spell ID: %d]|r", qLabel, r.spellId or 0))
        card.desc:SetText(r.desc and r.desc ~= "" and r.desc or "Grimfall Runic Enhancement")

        local textHeight = card.desc:GetStringHeight() or 14
        local cardH = math.max(64, textHeight + 36)
        card:SetHeight(cardH)
        card:Show()
        yOffset = yOffset + cardH + 6
    end

    detailRuneContent:SetHeight(math.max(300, yOffset + 10))
end

-- Refresh the Shared Builds List
function MF:RefreshSharedTab()
    local list = GH.ReceivedBuilds or {}
    listCountText:SetText(string.format("|cff888888%d build%s received this session|r", #list, #list == 1 and "" or "s"))

    if #list == 0 then
        emptySharedNotice:Show()
    else
        emptySharedNotice:Hide()
    end

    for _, c in ipairs(sharedBuildCards) do c:Hide() end

    local yOffset = 0
    local cardH = 76

    for i, b in ipairs(list) do
        local card = sharedBuildCards[i]
        if not card then
            card = CreateFrame("Button", nil, sharedListContent)
            card:SetSize(720, cardH)
            UI:ApplyBackdrop(card, true)

            card.icon = card:CreateTexture(nil, "ARTWORK")
            card.icon:SetSize(42, 42)
            card.icon:SetPoint("LEFT", card, "LEFT", 12, 0)
            card.icon:SetTexture("Interface\\Icons\\INV_Misc_Book_09")
            card.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            card.nameLine = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            card.nameLine:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 12, -4)
            card.nameLine:SetWidth(440)
            card.nameLine:SetJustifyH("LEFT")

            card.headline1 = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            card.headline1:SetPoint("TOPLEFT", card.nameLine, "BOTTOMLEFT", 0, -4)
            card.headline1:SetWidth(440)
            card.headline1:SetJustifyH("LEFT")

            card.headline2 = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.headline2:SetPoint("TOPLEFT", card.headline1, "BOTTOMLEFT", 0, -4)
            card.headline2:SetWidth(440)
            card.headline2:SetJustifyH("LEFT")
            card.headline2:SetWordWrap(false)

            card.timeText = card:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            card.timeText:SetPoint("TOPRIGHT", card, "TOPRIGHT", -12, -8)

            card.statsText = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.statsText:SetPoint("TOPRIGHT", card.timeText, "BOTTOMRIGHT", 0, -4)
            card.statsText:SetJustifyH("RIGHT")

            card.viewBtn = UI:CreateButton(card, "View Details", 95, 22, true)
            card.viewBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -36, 8)

            card.delBtn = CreateFrame("Button", nil, card)
            card.delBtn:SetSize(20, 20)
            card.delBtn:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 9)
            local delText = card.delBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            delText:SetPoint("CENTER", card.delBtn, "CENTER", 0, 0)
            delText:SetText("|cffff4444✕|r")

            sharedBuildCards[i] = card
        end

        card:SetPoint("TOPLEFT", sharedListContent, "TOPLEFT", 0, -yOffset)

        local eval = b.evaluation or (GH.BuildEvaluator and GH.BuildEvaluator:EvaluateBuild(b)) or {}
        local s = b.stats or {}
        local ilvlBadgeStr = (s.ilvl and s.ilvl > 0) and ("  |cffffd100[iLvl " .. s.ilvl .. "]|r") or ""
        card.nameLine:SetText("|cffffffff" .. (b.name or "Hero") .. "|r" .. ilvlBadgeStr .. "  |cff888888(Lvl " .. (b.level or 80) .. " " .. (b.race or "") .. " " .. (b.class or "Hero") .. ")|r")

        local ratingColor = eval.ratingColor or "|cffffd100"
        card.headline1:SetText(string.format("%sScore: %d (%s)|r  •  |cff00FF96%s|r", ratingColor, eval.totalScore or 0, eval.ratingTitle or "Veteran", eval.role or "Classless"))

        local runesCount = #(b.runes or {})
        -- Compact top 3 specs for list view to avoid text overflow
        local talentParts = {}
        for _, t in ipairs(b.talents or {}) do
            if (t.points or 0) > 0 then
                table.insert(talentParts, { name = t.name, points = t.points })
            end
        end
        table.sort(talentParts, function(x, y) return x.points > y.points end)

        local topTalents = {}
        for idx = 1, math.min(3, #talentParts) do
            table.insert(topTalents, talentParts[idx].name .. " (" .. talentParts[idx].points .. ")")
        end
        local extraCount = #talentParts > 3 and string.format(" +%d more", #talentParts - 3) or ""
        local talentBrief = (#topTalents > 0)
            and (table.concat(topTalents, ", ") .. extraCount .. " [" .. (b.talentCount or 0) .. " pts]")
            or ((b.talentCount or 0) .. " pts")

        card.headline2:SetText(string.format("|cffffd100Runes:|r |cffffffff%d active|r  •  |cffffd100Talents:|r |cffffffff%s|r", runesCount, talentBrief))

        card.timeText:SetText(b.timeStr and ("Received at " .. b.timeStr) or "")

        local ilvlPrefix = (s.ilvl and s.ilvl > 0) and ("|cffffd100iLvl " .. s.ilvl .. "|r • ") or ""
        card.statsText:SetText(string.format("%sAP: %s  •  SP: %s\nStr: %s  •  Sta: %s  •  Armor: %s",
            ilvlPrefix, s.ap or 0, s.sp or 0, s.str or 0, s.sta or 0, s.armor or 0))

        card.viewBtn:SetScript("OnClick", function()
            MF:OpenSharedBuildDetail(b)
        end)
        card:SetScript("OnClick", function()
            MF:OpenSharedBuildDetail(b)
        end)

        local currentIdx = i
        card.delBtn:SetScript("OnClick", function()
            table.remove(GH.ReceivedBuilds, currentIdx)
            MF:RefreshSharedTab()
        end)

        card:Show()
        yOffset = yOffset + cardH + 6
    end

    sharedListContent:SetHeight(math.max(380, yOffset + 10))
end


-- ============================================================================
-- TAB 3: SPELLBOOK (Classless Ability Browser)
-- ============================================================================
local p3 = tabPanels[3]

-- Filter Bar
local filterBar = CreateFrame("Frame", nil, p3)
filterBar:SetSize(756, 32)
filterBar:SetPoint("TOPLEFT", p3, "TOPLEFT", 0, 0)

local searchBox = UI:CreateEditBox(filterBar, 140, 22)
searchBox:SetPoint("LEFT", filterBar, "LEFT", 4, 0)
searchBox.hint = searchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
searchBox.hint:SetPoint("LEFT", searchBox, "LEFT", 6, 0)
searchBox.hint:SetText("Search abilities...")
searchBox:SetScript("OnEditFocusGained", function(self) self.hint:Hide() end)
searchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self.hint:Show() end
end)

local selectedClassFilter = "ALL"
local selectedCategoryFilter = "ALL"
local selectedSchoolFilter = "ALL"
local highestRankOnly = true

local classBtn = UI:CreateButton(filterBar, "Class: All", 95, 22)
classBtn:SetPoint("LEFT", searchBox, "RIGHT", 6, 0)

local catBtn = UI:CreateButton(filterBar, "Role: All", 95, 22)
catBtn:SetPoint("LEFT", classBtn, "RIGHT", 6, 0)

local schoolBtn = UI:CreateButton(filterBar, "School: All", 95, 22)
schoolBtn:SetPoint("LEFT", catBtn, "RIGHT", 6, 0)

local rankCheck = CreateFrame("CheckButton", "GrimfallHelperRankCheck", filterBar, "UICheckButtonTemplate")
rankCheck:SetChecked(highestRankOnly)
rankCheck.text = rankCheck:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rankCheck.text:SetPoint("LEFT", rankCheck, "RIGHT", 2, 0)
rankCheck.text:SetText("Max Ranks Only")
rankCheck:SetScript("OnClick", function(self)
    highestRankOnly = self:GetChecked()
    MF:RefreshSpellbook()
end)
rankCheck:SetPoint("LEFT", schoolBtn, "RIGHT", 10, 0)

-- Spell List Frame
local spellListFrame = CreateFrame("Frame", nil, p3)
spellListFrame:SetSize(756, 406)
spellListFrame:SetPoint("TOPLEFT", p3, "TOPLEFT", 0, -36)
UI:ApplyBackdrop(spellListFrame, true)

local spellScroll = CreateFrame("ScrollFrame", "GrimfallHelperSpellScroll", spellListFrame, "UIPanelScrollFrameTemplate")
spellScroll:SetPoint("TOPLEFT", spellListFrame, "TOPLEFT", 6, -6)
spellScroll:SetPoint("BOTTOMRIGHT", spellListFrame, "BOTTOMRIGHT", -26, 6)

local spellContent = CreateFrame("Frame", nil, spellScroll)
spellContent:SetSize(720, 1000)
spellScroll:SetScrollChild(spellContent)

local spellRows = {}

-- Filter cycling
local classList = { "ALL", "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local classIdx = 1
classBtn:SetScript("OnClick", function()
    classIdx = (classIdx % #classList) + 1
    selectedClassFilter = classList[classIdx]
    classBtn:SetText("Class: " .. (selectedClassFilter == "ALL" and "All" or selectedClassFilter))
    MF:RefreshSpellbook()
end)

local catList = { "ALL", "MELEE_NUKE", "RANGED_NUKE", "DOT_BLEED", "HEAL", "DEFENSIVE", "CC_INTERRUPT", "BUFF_AURA", "PASSIVE" }
local catIdx = 1
catBtn:SetScript("OnClick", function()
    catIdx = (catIdx % #catList) + 1
    selectedCategoryFilter = catList[catIdx]
    local label = C.CATEGORIES[selectedCategoryFilter] or selectedCategoryFilter
    catBtn:SetText("Role: " .. (selectedCategoryFilter == "ALL" and "All" or string.sub(label, 1, 9)))
    MF:RefreshSpellbook()
end)

local schoolList = { "ALL", "Physical", "Holy", "Fire", "Frost", "Shadow", "Nature", "Arcane" }
local schoolIdx = 1
schoolBtn:SetScript("OnClick", function()
    schoolIdx = (schoolIdx % #schoolList) + 1
    selectedSchoolFilter = schoolList[schoolIdx]
    schoolBtn:SetText("School: " .. (selectedSchoolFilter == "ALL" and "All" or selectedSchoolFilter))
    MF:RefreshSpellbook()
end)

searchBox:SetScript("OnTextChanged", function()
    MF:RefreshSpellbook()
end)

function MF:RefreshSpellbook()
    if not GH.Spellbook then return end
    local query = searchBox:GetText()
    local spells = GH.Spellbook:FilterSpells(selectedClassFilter, selectedCategoryFilter, selectedSchoolFilter, "ALL", query, highestRankOnly)

    for _, row in ipairs(spellRows) do row:Hide() end

    local rowHeight = 36
    for i, sp in ipairs(spells) do
        local row = spellRows[i]
        if not row then
            row = CreateFrame("Button", nil, spellContent)
            row:SetSize(716, 32)
            UI:ApplyBackdrop(row, true)

            row.icon = CreateFrame("Button", nil, row)
            row.icon:SetSize(26, 26)
            row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
            row.icon.tex = row.icon:CreateTexture(nil, "ARTWORK")
            row.icon.tex:SetAllPoints(true)
            row.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

            row.icon:RegisterForDrag("LeftButton")
            row.icon:SetScript("OnDragStart", function(self)
                if self.spellIndex then
                    PickupSpell(self.spellIndex, BOOKTYPE_SPELL)
                end
            end)

            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)

            row.classBadge = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.classBadge:SetPoint("LEFT", row, "LEFT", 260, 0)

            row.info = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.info:SetPoint("LEFT", row, "LEFT", 380, 0)

            row.resource = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            row.resource:SetPoint("LEFT", row, "LEFT", 530, 0)

            spellRows[i] = row
        end

        row:SetPoint("TOPLEFT", spellContent, "TOPLEFT", 0, -(i - 1) * (rowHeight))
        row.icon.tex:SetTexture(sp.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon.spellIndex = sp.spellIndex

        row.icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpell(sp.spellIndex, BOOKTYPE_SPELL)
            GameTooltip:Show()
        end)
        row.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)

        local rankStr = sp.rank ~= "" and (" |cff888888(" .. sp.rank .. ")|r") or ""
        row.name:SetText(sp.name .. rankStr)

        local classColor = C.CLASSES[sp.class] and C.CLASSES[sp.class].color or "CCCCCC"
        row.classBadge:SetText(Utils:Colorize(sp.class, classColor))

        local schoolColor = C.SCHOOLS[sp.school] and C.SCHOOLS[sp.school].color or "FFFFFF"
        local catName = C.CATEGORIES[sp.category] or sp.category
        row.info:SetText(Utils:Colorize(sp.school, schoolColor) .. " |cff666666•|r " .. catName)

        row.resource:SetText("|cffAAAAAA" .. sp.resource .. "|r")
        row:Show()
    end

    spellContent:SetHeight(math.max(400, #spells * rowHeight + 10))
end


-- ============================================================================
-- TAB 4: EXPORT & SHARE BUILD
-- ============================================================================
local p4 = tabPanels[4]

local expHeader = CreateFrame("Frame", nil, p4)
expHeader:SetSize(756, 36)
expHeader:SetPoint("TOPLEFT", p4, "TOPLEFT", 0, 0)

local expTitle = expHeader:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
expTitle:SetPoint("TOPLEFT", expHeader, "TOPLEFT", 4, -4)
expTitle:SetText("|cff00FF96Build Exporter & Share Codes|r")

local expSub = expHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
expSub:SetPoint("BOTTOMLEFT", expHeader, "BOTTOMLEFT", 4, 0)
expSub:SetText("|cff888888Export plain text build to clipboard or copy a compact code for in-game sharing.|r")

local copyBtn = UI:CreateButton(expHeader, "Copy Text (Ctrl+C)", 140, 24, true)
copyBtn:SetPoint("TOPRIGHT", expHeader, "TOPRIGHT", 0, -4)

local copyCodeBtn = UI:CreateButton(expHeader, "Copy Share Code", 130, 24)
copyCodeBtn:SetPoint("RIGHT", copyBtn, "LEFT", -6, 0)

local refreshExpBtn = UI:CreateButton(expHeader, "Refresh", 80, 24)
refreshExpBtn:SetPoint("RIGHT", copyCodeBtn, "LEFT", -6, 0)

local statusBanner = p4:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusBanner:SetPoint("TOPLEFT", p4, "TOPLEFT", 4, -40)
statusBanner:SetText("|cffFFFF00Click 'Copy Text' or 'Copy Share Code' to share with friends, Discord, or AI.|r")

local textBox = CreateFrame("Frame", nil, p4)
textBox:SetSize(756, 390)
textBox:SetPoint("TOPLEFT", p4, "TOPLEFT", 0, -56)
UI:ApplyBackdrop(textBox, true)

local exportScroll = CreateFrame("ScrollFrame", "GrimfallMainExportScroll", textBox, "UIPanelScrollFrameTemplate")
exportScroll:SetPoint("TOPLEFT", textBox, "TOPLEFT", 8, -8)
exportScroll:SetPoint("BOTTOMRIGHT", textBox, "BOTTOMRIGHT", -28, 8)

local exportEditBox = CreateFrame("EditBox", "GrimfallMainExportEditBox", exportScroll)
exportEditBox:SetMultiLine(true)
exportEditBox:SetMaxLetters(0)
exportEditBox:EnableMouse(true)
exportEditBox:SetAutoFocus(false)
exportEditBox:SetFont("Fonts\\FRIZQT__.TTF", 11)
exportEditBox:SetWidth(716)
exportScroll:SetScrollChild(exportEditBox)

local function HighlightExportText()
    exportEditBox:SetFocus()
    exportEditBox:HighlightText(0, -1)
    statusBanner:SetText("|cff00FF66✔ Text highlighted! Press Ctrl + C on your keyboard to copy to clipboard.|r")
    Utils:PlaySound("CLICK")
end

copyBtn:SetScript("OnClick", HighlightExportText)

copyCodeBtn:SetScript("OnClick", function()
    if GH.BuildSharing then
        local code = GH.BuildSharing:GenerateBuildCode()
        exportEditBox:SetText(code)
        HighlightExportText()
        statusBanner:SetText("|cff00FF96Compact Build Code generated! Press Ctrl + C to copy.|r")
    end
end)

refreshExpBtn:SetScript("OnClick", function()
    MF:RefreshExport()
    statusBanner:SetText("|cff00FF96Build refreshed!|r")
end)

exportEditBox:SetScript("OnMouseUp", function(self)
    self:SetFocus()
end)

function MF:RefreshExport()
    if not GH.BuildExporter then return end
    local text = GH.BuildExporter:GenerateExportString(false)
    exportEditBox:SetText(text)
end


-- ============================================================================
-- TAB 5: RUNE LIST (Search all 2,615 Grimfall Runes)
-- ============================================================================
local p5 = tabPanels[5]

local rFilterBar = CreateFrame("Frame", nil, p5)
rFilterBar:SetSize(756, 32)
rFilterBar:SetPoint("TOPLEFT", p5, "TOPLEFT", 0, 0)

local rSearchBox = UI:CreateEditBox(rFilterBar, 200, 22)
rSearchBox:SetPoint("LEFT", rFilterBar, "LEFT", 4, 0)
rSearchBox.hint = rSearchBox:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rSearchBox.hint:SetPoint("LEFT", rSearchBox, "LEFT", 6, 0)
rSearchBox.hint:SetText("Search 2,615 runes by name or effect...")
rSearchBox:SetScript("OnEditFocusGained", function(self) self.hint:Hide() end)
rSearchBox:SetScript("OnEditFocusLost", function(self)
    if self:GetText() == "" then self.hint:Show() end
end)

local currentRuneFilter = 0 -- 0: All, 5: Leg, 4: Epic, 3: Rare, 2: Uncommon

local allRuneBtn = UI:CreateButton(rFilterBar, "All (2615)", 80, 22, true)
allRuneBtn:SetPoint("LEFT", rSearchBox, "RIGHT", 8, 0)

local legRuneBtn = UI:CreateButton(rFilterBar, "Legendary", 85, 22)
legRuneBtn:SetPoint("LEFT", allRuneBtn, "RIGHT", 6, 0)

local epicRuneBtn = UI:CreateButton(rFilterBar, "Epic", 75, 22)
epicRuneBtn:SetPoint("LEFT", legRuneBtn, "RIGHT", 6, 0)

local rareRuneBtn = UI:CreateButton(rFilterBar, "Rare", 75, 22)
rareRuneBtn:SetPoint("LEFT", epicRuneBtn, "RIGHT", 6, 0)

local uncRuneBtn = UI:CreateButton(rFilterBar, "Uncommon", 85, 22)
uncRuneBtn:SetPoint("LEFT", rareRuneBtn, "RIGHT", 6, 0)

local rCountText = rFilterBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rCountText:SetPoint("RIGHT", rFilterBar, "RIGHT", -8, 0)
rCountText:SetText("Showing 0 runes")

allRuneBtn:SetScript("OnClick", function() currentRuneFilter = 0; MF:RefreshRuneDatabase() end)
legRuneBtn:SetScript("OnClick", function() currentRuneFilter = 5; MF:RefreshRuneDatabase() end)
epicRuneBtn:SetScript("OnClick", function() currentRuneFilter = 4; MF:RefreshRuneDatabase() end)
rareRuneBtn:SetScript("OnClick", function() currentRuneFilter = 3; MF:RefreshRuneDatabase() end)
uncRuneBtn:SetScript("OnClick", function() currentRuneFilter = 2; MF:RefreshRuneDatabase() end)

rSearchBox:SetScript("OnTextChanged", function()
    MF:RefreshRuneDatabase()
end)

local rListFrame = CreateFrame("Frame", nil, p5)
rListFrame:SetSize(756, 406)
rListFrame:SetPoint("TOPLEFT", p5, "TOPLEFT", 0, -36)
UI:ApplyBackdrop(rListFrame, true)

local rScroll = CreateFrame("ScrollFrame", "GrimfallHelperRuneDBCScroll", rListFrame, "UIPanelScrollFrameTemplate")
rScroll:SetPoint("TOPLEFT", rListFrame, "TOPLEFT", 6, -6)
rScroll:SetPoint("BOTTOMRIGHT", rListFrame, "BOTTOMRIGHT", -26, 6)

local rContent = CreateFrame("Frame", nil, rScroll)
rContent:SetSize(720, 1000)
rScroll:SetScrollChild(rContent)

local dbRuneCards = {}

function MF:RefreshRuneDatabase()
    if not GH.RuneData then return end
    local query = string.lower(rSearchBox:GetText() or "")

    local matched = {}
    for sid, data in pairs(GH.RuneData) do
        local passQuality = (currentRuneFilter == 0) or (data.quality == currentRuneFilter)
        if passQuality then
            local passQuery = true
            if query ~= "" then
                local inName = string.find(string.lower(data.name or ""), query, 1, true)
                local inDesc = string.find(string.lower(data.desc or ""), query, 1, true)
                passQuery = inName or inDesc
            end
            if passQuery then
                table.insert(matched, {
                    spellId = sid,
                    name = data.name,
                    quality = data.quality,
                    entry = data.entry,
                    desc = data.desc,
                })
            end
        end
    end

    table.sort(matched, function(a, b)
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        return (a.name or "") < (b.name or "")
    end)

    rCountText:SetText(string.format("Showing |cff00FF96%d|r runes", #matched))

    for _, c in ipairs(dbRuneCards) do c:Hide() end

    local yOffset = 0
    local cardH = 58
    local maxDisplay = math.min(#matched, 150)

    for i = 1, maxDisplay do
        local r = matched[i]
        local card = dbRuneCards[i]
        if not card then
            card = CreateFrame("Frame", nil, rContent)
            card:SetSize(716, cardH)
            UI:ApplyBackdrop(card, true)

            card.name = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            card.name:SetPoint("TOPLEFT", card, "TOPLEFT", 10, -6)

            card.badge = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.badge:SetPoint("LEFT", card.name, "RIGHT", 8, 0)

            card.desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            card.desc:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
            card.desc:SetWidth(696)
            card.desc:SetJustifyH("LEFT")

            dbRuneCards[i] = card
        end

        card:SetPoint("TOPLEFT", rContent, "TOPLEFT", 0, -yOffset)

        local q = r.quality or 2
        local qColor = QUALITY_COLORS[q] or "ffffff"
        local qLabel = QUALITY_LABELS[q] or "Uncommon"

        card:SetBackdropBorderColor(
            tonumber(string.sub(qColor, 1, 2), 16) / 255,
            tonumber(string.sub(qColor, 3, 4), 16) / 255,
            tonumber(string.sub(qColor, 5, 6), 16) / 255,
            0.7
        )

        card.name:SetText(string.format("|cff%s%s|r", qColor, r.name))
        card.badge:SetText(string.format("|cff888888[%s | Spell ID: %d | Entry: %d]|r", qLabel, r.spellId, r.entry or 0))
        card.desc:SetText(r.desc and r.desc ~= "" and r.desc or "No description available.")

        card:Show()
        yOffset = yOffset + cardH + 4
    end

    rContent:SetHeight(math.max(400, yOffset + 10))
end


-- ============================================================================
-- TOGGLE & EVENT HOOKS
-- ============================================================================
function MF:Toggle()
    if frame:IsShown() then
        frame:Hide()
    else
        local point = GH.Config:Get("windowPoint", "CENTER")
        local relPoint = GH.Config:Get("windowRelPoint", "CENTER")
        local x = GH.Config:Get("windowX", 0)
        local y = GH.Config:Get("windowY", 20)
        frame:ClearAllPoints()
        frame:SetPoint(point, UIParent, relPoint, x, y)

        frame:Show()
        self:SelectTab(GH.Config:Get("selectedTab", 1))
    end
end

-- Refresh Spellbook when spells update
EventBus:RegisterCustom("GH_SPELLBOOK_UPDATED", function()
    if frame:IsShown() and currentTab == 3 then
        MF:RefreshSpellbook()
    end
end)

-- Refresh Shared tab when a new whisper build arrives
EventBus:RegisterCustom("RECEIVED_BUILDS_UPDATED", function(build)
    if frame:IsShown() and currentTab == 2 then
        MF:RefreshSharedTab()
    end
end)
