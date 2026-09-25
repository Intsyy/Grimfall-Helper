-- ============================================================================
-- GrimfallHelper: Modules/Scrolls.lua
-- Wildcard Scroll Inventory Scanner, Fast Use Macro, and Reroll History Logger
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Scrolls = {}
local Scrolls = GH.Scrolls
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

Scrolls.items = {}
Scrolls.totalCount = 0

-- Check if an item is a Grimfall Wildcard Scroll / Token
local function IsWildcardItem(itemName)
    if not itemName then return false end
    local lower = string.lower(itemName)
    for _, kw in ipairs(C.WILDCARD_ITEM_KEYWORDS) do
        if string.find(lower, kw, 1, true) then
            return true
        end
    end
    return false
end

-- Scan player bags for scrolls
function Scrolls:Scan()
    table.wipe(self.items)
    self.totalCount = 0

    local itemMap = {}

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName, _, itemRarity, _, _, _, _, _, _, itemTexture = GetItemInfo(link)
                local texture, count = GetContainerItemInfo(bag, slot)
                count = count or 1

                if itemName and IsWildcardItem(itemName) then
                    self.totalCount = self.totalCount + count

                    if not itemMap[itemName] then
                        itemMap[itemName] = {
                            name = itemName,
                            link = link,
                            texture = itemTexture or texture,
                            rarity = itemRarity or 1,
                            count = 0,
                            bag = bag,
                            slot = slot,
                        }
                    end
                    itemMap[itemName].count = itemMap[itemName].count + count
                end
            end
        end
    end

    for _, v in pairs(itemMap) do
        table.insert(self.items, v)
    end

    table.sort(self.items, function(a, b)
        return a.count > b.count
    end)

    Utils:Debug("Scrolls scanned: " .. self.totalCount .. " total scrolls/tokens found.")
    EventBus:Fire("GH_SCROLLS_UPDATED")
end

-- Fast Use first available Reroll Scroll
function Scrolls:UseFirstScroll()
    if InCombatLockdown() then
        Utils:Print("|cffFF3333Cannot use items while in combat!|r")
        return false
    end

    for bag = 0, 4 do
        local numSlots = GetContainerNumSlots(bag)
        for slot = 1, numSlots do
            local link = GetContainerItemLink(bag, slot)
            if link then
                local itemName = GetItemInfo(link)
                if itemName and IsWildcardItem(itemName) then
                    Utils:Print("Using |cffFFFF00[" .. itemName .. "]|r...")
                    UseContainerItem(bag, slot)
                    return true
                end
            end
        end
    end

    Utils:Print("|cffFF3333No Reroll Scrolls or Wildcard items found in bags!|r")
    return false
end

-- Log Reroll/Acquisition History
function Scrolls:LogHistory(actionType, spellName, tier)
    if not GrimfallHelperCharDB then GrimfallHelperCharDB = {} end
    if not GrimfallHelperCharDB.rerollHistory then
        GrimfallHelperCharDB.rerollHistory = {}
    end

    local entry = {
        action = actionType or "Rolled",
        spell = spellName or "Unknown Ability",
        tier = tier or "-",
        level = UnitLevel("player") or 1,
        time = date("%m/%d %H:%M"),
    }

    table.insert(GrimfallHelperCharDB.rerollHistory, 1, entry)

    -- Cap history at 100 entries
    while #GrimfallHelperCharDB.rerollHistory > 100 do
        table.remove(GrimfallHelperCharDB.rerollHistory)
    end

    EventBus:Fire("GH_HISTORY_UPDATED")
end

-- Get History list
function Scrolls:GetHistory()
    if not GrimfallHelperCharDB or not GrimfallHelperCharDB.rerollHistory then
        return {}
    end
    return GrimfallHelperCharDB.rerollHistory
end

-- Clear History
function Scrolls:ClearHistory()
    if GrimfallHelperCharDB then
        GrimfallHelperCharDB.rerollHistory = {}
    end
    Utils:Print("Reroll history cleared.")
    EventBus:Fire("GH_HISTORY_UPDATED")
end

-- Event Listeners
EventBus:Register("BAG_UPDATE", function()
    Scrolls:Scan()
end)

EventBus:Register("PLAYER_ENTERING_WORLD", function()
    Scrolls:Scan()
end)
