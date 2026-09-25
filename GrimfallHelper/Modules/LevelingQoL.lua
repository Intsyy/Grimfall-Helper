-- ============================================================================
-- GrimfallHelper: Modules/LevelingQoL.lua
-- Auto-Vendor Junk, Auto-Repair, XP Speedometer, and Loot Fanfare
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.LevelingQoL = {}
local QoL = GH.LevelingQoL
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Session state
QoL.sessionStart = time()
QoL.startXP = 0
QoL.xpGained = 0
QoL.kills = 0
QoL.quests = 0
QoL.scrollsFarmed = 0

-- Initialize XP baseline
function QoL:InitXP()
    self.startXP = UnitXP("player") or 0
    self.sessionStart = time()
    self.xpGained = 0
    self.kills = 0
    self.quests = 0
    self.scrollsFarmed = 0
end

-- Auto-Vendor Grey Items
function QoL:AutoVendorGreys()
    if not GH.Config:Get("autoVendor", true) then return end

    local totalSold = 0
    local totalCopper = 0

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName, _, itemRarity, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(link)
                local _, count = GetContainerItemInfo(bag, slot)
                count = count or 1

                -- Rarity 0 is Poor (Grey)
                if itemRarity == 0 and itemSellPrice and itemSellPrice > 0 then
                    local stackPrice = itemSellPrice * count
                    totalCopper = totalCopper + stackPrice
                    totalSold = totalSold + 1
                    UseContainerItem(bag, slot)
                end
            end
        end
    end

    if totalSold > 0 then
        Utils:PlaySound("COIN")
        Utils:Print("Auto-sold |cffffffff" .. totalSold .. "|r grey items for " .. Utils:FormatMoney(totalCopper) .. ".")
    end
end

-- Auto-Repair Equipment
function QoL:AutoRepair()
    if not GH.Config:Get("autoRepair", true) then return end
    if not CanMerchantRepair() then return end

    local repairCost, canRepair = GetRepairAllCost()
    if not canRepair or repairCost <= 0 then return end

    local usedGuild = false
    if GH.Config:Get("autoRepairGuild", true) and IsInGuild() and CanGuildBankRepair() then
        local guildMoney = GetGuildBankWithdrawMoney()
        if guildMoney == -1 or guildMoney >= repairCost then
            RepairAllItems(1)
            usedGuild = true
            Utils:PlaySound("COIN")
            Utils:Print("Repaired all equipment via |cff00FF96Guild Bank|r for " .. Utils:FormatMoney(repairCost) .. ".")
            return
        end
    end

    local playerMoney = GetMoney()
    if playerMoney >= repairCost then
        RepairAllItems(0)
        Utils:PlaySound("COIN")
        Utils:Print("Repaired all equipment for " .. Utils:FormatMoney(repairCost) .. ".")
    else
        Utils:Print("|cffFF3333Insufficient gold to repair equipment!|r (Cost: " .. Utils:FormatMoney(repairCost) .. ")")
    end
end

-- Get XP Speedometer Metrics
function QoL:GetSpeedometer()
    local curXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    local curLevel = UnitLevel("player") or 1

    if curLevel >= 80 then
        return {
            isMaxLevel = true,
            elapsed = time() - self.sessionStart,
            kills = self.kills,
            quests = self.quests,
            scrollsFarmed = self.scrollsFarmed,
        }
    end

    local elapsed = math.max(1, time() - self.sessionStart)
    local xpPerHour = math.floor((self.xpGained / elapsed) * 3600)
    local xpRemaining = maxXP - curXP

    local secondsToLevel = 0
    if xpPerHour > 0 then
        secondsToLevel = math.floor((xpRemaining / xpPerHour) * 3600)
    end

    return {
        isMaxLevel = false,
        curLevel = curLevel,
        curXP = curXP,
        maxXP = maxXP,
        xpRemaining = xpRemaining,
        xpGained = self.xpGained,
        xpPercent = math.floor((curXP / maxXP) * 100),
        xpPerHour = xpPerHour,
        secondsToLevel = secondsToLevel,
        elapsed = elapsed,
        kills = self.kills,
        quests = self.quests,
        scrollsFarmed = self.scrollsFarmed,
    }
end

-- Reset Session Statistics
function QoL:ResetSession()
    self:InitXP()
    Utils:Print("Leveling & session statistics reset.")
    EventBus:Fire("GH_SPEEDOMETER_UPDATE")
end

-- Auto-Accept & Turn-In Quests
function QoL:HandleQuestDetail()
    if GH.Config:Get("autoQuest", false) or IsShiftKeyDown() then
        AcceptQuest()
    end
end

function QoL:HandleQuestProgress()
    if GH.Config:Get("autoQuest", false) or IsShiftKeyDown() then
        if IsQuestCompletable() then
            CompleteQuest()
        end
    end
end

function QoL:HandleQuestComplete()
    if GH.Config:Get("autoQuest", false) or IsShiftKeyDown() then
        if GetNumQuestChoices() <= 1 then
            GetQuestReward(1)
        end
    end
end

-- Event Listeners
EventBus:Register("QUEST_DETAIL", function()
    QoL:HandleQuestDetail()
end)

EventBus:Register("QUEST_PROGRESS", function()
    QoL:HandleQuestProgress()
end)

EventBus:Register("QUEST_COMPLETE", function()
    QoL:HandleQuestComplete()
end)

EventBus:Register("MERCHANT_SHOW", function()
    QoL:AutoVendorGreys()
    QoL:AutoRepair()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    QoL:InitXP()
end)

EventBus:Register("PLAYER_XP_UPDATE", function()
    local curXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1

    if curXP >= QoL.startXP then
        QoL.xpGained = curXP - QoL.startXP
    else
        -- Leveled up
        QoL.xpGained = QoL.xpGained + curXP
        QoL.startXP = 0
    end
    EventBus:Fire("GH_SPEEDOMETER_UPDATE")
end)

EventBus:Register("CHAT_MSG_COMBAT_XP_GAIN", function()
    QoL.kills = QoL.kills + 1
    EventBus:Fire("GH_SPEEDOMETER_UPDATE")
end)

EventBus:Register("QUEST_COMPLETE", function()
    QoL.quests = QoL.quests + 1
    EventBus:Fire("GH_SPEEDOMETER_UPDATE")
end)

EventBus:Register("CHAT_MSG_LOOT", function(event, msg)
    if not msg then return end

    -- Check if loot contains a wildcard scroll or card
    local lower = string.lower(msg)
    if string.find(lower, "reroll", 1, true) or string.find(lower, "hand of fate", 1, true) or string.find(lower, "wildcard", 1, true) then
        QoL.scrollsFarmed = QoL.scrollsFarmed + 1
        if GH.Config:Get("lootFanfare", true) then
            Utils:PlaySound("WISHLIST")
        end
        EventBus:Fire("GH_SPEEDOMETER_UPDATE")
    end
end)
