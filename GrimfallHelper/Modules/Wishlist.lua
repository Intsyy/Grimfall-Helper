-- ============================================================================
-- GrimfallHelper: Modules/Wishlist.lua
-- Wildcard Wishlist Manager, Target Hunting, Roll Alerts, and Build Codes
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Wishlist = {}
local Wishlist = GH.Wishlist
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Tier Colors and Metadata
Wishlist.TIERS = {
    ["S"] = { label = "S-Tier (Must Have)",  color = "FFD700", r = 1.0, g = 0.84, b = 0.0 },
    ["A"] = { label = "A-Tier (High Value)", color = "C41F3B", r = 0.8, g = 0.2,  b = 0.2 },
    ["B"] = { label = "B-Tier (Situational)", color = "0070DE", r = 0.0, g = 0.44, b = 0.87 },
}

local recentlyAnnounced = {}

-- Get the character wishlist table
function Wishlist:GetWishlistTable()
    if not GrimfallHelperCharDB or not GrimfallHelperCharDB.wishlist then
        return { ["S"] = {}, ["A"] = {}, ["B"] = {} }
    end
    return GrimfallHelperCharDB.wishlist
end

-- Add Spell to Wishlist Tier
function Wishlist:Add(spellName, tier)
    if not spellName or spellName == "" then return end
    tier = tier or "A"
    spellName = Utils:Trim(spellName)

    -- Remove from all tiers first to prevent duplicates
    self:Remove(spellName, true)

    local db = self:GetWishlistTable()
    if not db[tier] then db[tier] = {} end
    table.insert(db[tier], spellName)

    Utils:Print("Added " .. Utils:Colorize(spellName, "FFFF00") .. " to Wishlist (" .. self.TIERS[tier].label .. ").")
    EventBus:Fire("GH_WISHLIST_UPDATED")
end

-- Remove Spell from Wishlist
function Wishlist:Remove(spellName, silent)
    if not spellName then return end
    local cleanTarget = Utils:NormalizeName(spellName)
    local db = self:GetWishlistTable()

    local removed = false
    for tier, list in pairs(db) do
        for i = #list, 1, -1 do
            if Utils:NormalizeName(list[i]) == cleanTarget then
                table.remove(list, i)
                removed = true
            end
        end
    end

    if removed and not silent then
        Utils:Print("Removed " .. Utils:Colorize(spellName, "AAAAAA") .. " from Wishlist.")
        EventBus:Fire("GH_WISHLIST_UPDATED")
    end
    return removed
end

-- Get Tier for a given spell
function Wishlist:GetTier(spellName)
    local cleanTarget = Utils:NormalizeName(spellName)
    local db = self:GetWishlistTable()
    for tier, list in pairs(db) do
        for _, name in ipairs(list) do
            if Utils:NormalizeName(name) == cleanTarget then
                return tier
            end
        end
    end
    return nil
end

-- Check if spell is in Wishlist
function Wishlist:Contains(spellName)
    return self:GetTier(spellName) ~= nil
end

-- Check if Wishlist spell has been acquired
function Wishlist:IsAcquired(spellName)
    if not GH.Spellbook then return false end
    return GH.Spellbook:HasSpell(spellName)
end

-- Return statistics (Total targets, Acquired, Pending)
function Wishlist:GetStats()
    local db = self:GetWishlistTable()
    local total = 0
    local acquired = 0

    for _, list in pairs(db) do
        for _, name in ipairs(list) do
            total = total + 1
            if self:IsAcquired(name) then
                acquired = acquired + 1
            end
        end
    end

    return total, acquired, total - acquired
end

-- Check for Wishlist acquisition and trigger alert
function Wishlist:CheckSpellAcquired(spellName)
    if not spellName then return end
    local tier = self:GetTier(spellName)
    if not tier then return end

    local clean = Utils:NormalizeName(spellName)
    if recentlyAnnounced[clean] then return end
    recentlyAnnounced[clean] = true

    local tierInfo = self.TIERS[tier]
    local tierColor = tierInfo and tierInfo.color or "FFD700"
    local tierLabel = tierInfo and tierInfo.label or (tier .. "-Tier")

    -- Sound Fanfare
    Utils:PlaySound("WISHLIST")

    -- Chat Notification
    Utils:Print("|cffFFD700★ WISHLIST ACQUIRED! ★|r " .. Utils:Colorize(spellName, tierColor) .. " (" .. tierLabel .. ") has been learned!")

    -- Center Screen Banner Alert
    if GH.UI and GH.UI.ShowAlertBanner and GH.Config:Get("wishlistAlertBanner", true) then
        GH.UI:ShowAlertBanner("★ WISHLIST SPELL ACQUIRED! ★\n" .. spellName .. " (" .. tier .. "-Tier)", tierColor)
    end

    -- Auto-Screenshot for S-Tier
    if tier == "S" and GH.Config:Get("autoScreenshotSTier", false) then
        Screenshot()
        Utils:Print("Screenshot automatically captured for S-Tier wildcard roll!")
    end

    -- Add to Reroll/Acquisition history
    if GH.Scrolls then
        GH.Scrolls:LogHistory("Acquired", spellName, tier)
    end

    EventBus:Fire("GH_WISHLIST_UPDATED")
end

-- Export Wishlist to string
function Wishlist:ExportCode()
    local db = self:GetWishlistTable()
    return Utils:EncodeBuild(db)
end

-- Import Wishlist from string
function Wishlist:ImportCode(codeStr)
    local decoded, err = Utils:DecodeBuild(codeStr)
    if not decoded then
        Utils:Print("|cffFF3333Import Error:|r " .. tostring(err))
        return false
    end

    if not GrimfallHelperCharDB then GrimfallHelperCharDB = {} end
    GrimfallHelperCharDB.wishlist = decoded

    local total, _, _ = self:GetStats()
    Utils:Print("|cff00FF96Build Wishlist imported successfully!|r (" .. total .. " total targets loaded)")
    Utils:PlaySound("LEVEL_UP")
    EventBus:Fire("GH_WISHLIST_UPDATED")
    return true
end

-- Load Meta Archetype Template
function Wishlist:LoadMetaTemplate(templateId)
    local template = nil
    for _, t in ipairs(C.META_TEMPLATES) do
        if t.id == templateId then
            template = t
            break
        end
    end

    if not template then
        Utils:Print("|cffFF3333Template [" .. tostring(templateId) .. "] not found.|r")
        return false
    end

    local newWishlist = { ["S"] = {}, ["A"] = {}, ["B"] = {} }
    for tier, list in pairs(template.wishlist) do
        for _, name in ipairs(list) do
            table.insert(newWishlist[tier], name)
        end
    end

    if not GrimfallHelperCharDB then GrimfallHelperCharDB = {} end
    GrimfallHelperCharDB.wishlist = newWishlist

    Utils:PlaySound("LEVEL_UP")
    Utils:Print("|cff00FF96Loaded Meta Template:|r " .. Utils:Colorize(template.name, template.color) .. " (" .. template.role .. ")")
    EventBus:Fire("GH_WISHLIST_UPDATED")
    return true
end

-- Share Build to Chat
function Wishlist:ShareBuildToChat(channel)
    channel = channel or GH.Config:Get("shareChannel", "PARTY")
    local syn = GH.Synergy
    if not syn then return end

    local title = syn.archetypeTitle or "Wildcard Hybrid"
    local score = syn.buildScore or 0
    local rating = syn.buildRating or "C"

    local sList = (self:GetWishlistTable())["S"] or {}
    local coreStr = #sList > 0 and table.concat(sList, ", ") or "None"

    local msg = "[GrimfallHelper] Build: " .. title .. " | Synergy: " .. score .. "/100 (" .. rating .. "-Tier) | Core: " .. coreStr
    SendChatMessage(msg, channel)
    Utils:Print("Shared build to " .. string.upper(channel) .. " chat!")
end

-- Listen for Spell Learning and Chat Messages
EventBus:Register("CHAT_MSG_SYSTEM", function(event, msg)
    if not msg then return end

    -- Pattern matching standard WoW and custom server spell acquisition
    -- "You have learned a new ability: [Name]" or "You have learned: [Name]"
    local spell = string.match(msg, "You have learned.*: %[(.+)%]")
    if not spell then
        spell = string.match(msg, "learned a new ability: (.+)%.")
    end
    if not spell then
        spell = string.match(msg, "Rolled ability: %[(.+)%]")
    end

    if spell then
        Wishlist:CheckSpellAcquired(spell)
    end
end)

EventBus:Register("LEARNED_SPELL_IN_TAB", function(event, spellId)
    if spellId then
        local spellName = GetSpellInfo(spellId)
        if spellName then
            Wishlist:CheckSpellAcquired(spellName)
        end
    end
end)
