-- ============================================================================
-- GrimfallHelper: Modules/ActionBars.lua
-- Action Bar Profiles (Tank/DPS/Heal/PvP) and 1-Click Auto-Rank Upgrader
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.ActionBars = {}
local ActionBars = GH.ActionBars
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Extract numerical rank
local function ExtractRankNumber(rankStr)
    if not rankStr or rankStr == "" then return 1 end
    local num = string.match(rankStr, "%d+")
    return tonumber(num) or 1
end

-- Scan action bars for downranked spells
function ActionBars:ScanUpgradeable()
    local upgradeable = {}
    if not GH.Spellbook or not GH.Spellbook.highestRanks then
        return upgradeable
    end

    for slot = 1, 120 do
        if HasAction(slot) then
            local actionType, id, subType = GetActionInfo(slot)
            if actionType == "spell" and id then
                local spellName, spellRank = GetSpellInfo(id)
                if spellName then
                    local clean = Utils:NormalizeName(spellName)
                    local currentRankNum = ExtractRankNumber(spellRank)
                    local highest = GH.Spellbook:GetHighestRank(spellName)

                    if highest and highest.rankNum > currentRankNum then
                        table.insert(upgradeable, {
                            slot = slot,
                            name = spellName,
                            currentRank = spellRank,
                            currentRankNum = currentRankNum,
                            newRank = highest.rank,
                            newRankNum = highest.rankNum,
                            spellIndex = highest.spellIndex,
                        })
                    end
                end
            end
        end
    end

    return upgradeable
end

-- Get count of upgradeable action bar slots
function ActionBars:GetUpgradeableCount()
    local list = self:ScanUpgradeable()
    return #list
end

-- Upgrade all downranked spells on action bars to maximum known rank
function ActionBars:UpgradeAllRanks()
    if InCombatLockdown() then
        Utils:Print("|cffFF3333Cannot modify action bars while in combat!|r")
        return 0
    end

    local list = self:ScanUpgradeable()
    if #list == 0 then
        Utils:Print("All action bar spells are already at maximum known rank!")
        return 0
    end

    local upgraded = 0
    for _, item in ipairs(list) do
        -- Pick up highest rank spell from spellbook and place into action bar slot
        ClearCursor()
        PickupSpell(item.spellIndex, BOOKTYPE_SPELL)
        PlaceAction(item.slot)
        ClearCursor()
        upgraded = upgraded + 1
        Utils:Print("Upgraded " .. Utils:Colorize(item.name, "00FF96") .. " from " .. item.currentRank .. " to |cffFFFF00" .. item.newRank .. "|r (Slot " .. item.slot .. ")")
    end

    Utils:PlaySound("LEVEL_UP")
    Utils:Print("|cff00FF96Successfully upgraded " .. upgraded .. " action bar ability ranks!|r")
    EventBus:Fire("GH_ACTIONBARS_UPDATED")
    return upgraded
end

-- Get Profiles Table
function ActionBars:GetProfiles()
    if not GrimfallHelperCharDB then GrimfallHelperCharDB = {} end
    if not GrimfallHelperCharDB.actionBarProfiles then
        GrimfallHelperCharDB.actionBarProfiles = {}
    end
    return GrimfallHelperCharDB.actionBarProfiles
end

-- Save current action bar layout as a named profile
function ActionBars:SaveProfile(profileName)
    if not profileName or profileName == "" then
        Utils:Print("|cffFF3333Please provide a valid profile name.|r")
        return false
    end

    profileName = Utils:Trim(profileName)
    local profiles = self:GetProfiles()
    local slots = {}

    for slot = 1, 120 do
        if HasAction(slot) then
            local actionType, id, subType = GetActionInfo(slot)
            if actionType == "spell" and id then
                local name, rank = GetSpellInfo(id)
                slots[slot] = { type = "spell", id = id, name = name, rank = rank }
            elseif actionType == "macro" and id then
                local name = GetMacroInfo(id)
                slots[slot] = { type = "macro", id = id, name = name }
            elseif actionType == "item" and id then
                local name = GetItemInfo(id)
                slots[slot] = { type = "item", id = id, name = name }
            end
        end
    end

    profiles[profileName] = {
        name = profileName,
        savedAt = date("%Y-%m-%d %H:%M"),
        slots = slots,
    }

    Utils:PlaySound("CLICK")
    Utils:Print("Action Bar Profile |cffFFFF00[" .. profileName .. "]|r saved successfully!")
    EventBus:Fire("GH_ACTIONBARS_UPDATED")
    return true
end

-- Load a saved action bar profile
function ActionBars:LoadProfile(profileName)
    if InCombatLockdown() then
        Utils:Print("|cffFF3333Cannot switch action bar profiles while in combat!|r")
        return false
    end

    local profiles = self:GetProfiles()
    local profile = profiles[profileName]
    if not profile then
        Utils:Print("|cffFF3333Profile [" .. tostring(profileName) .. "] not found.|r")
        return false
    end

    -- Clear and restore slots
    for slot = 1, 120 do
        local saved = profile.slots[slot]
        if saved then
            if saved.type == "spell" and saved.name then
                -- Try to find highest known rank of spell in spellbook
                local highest = GH.Spellbook and GH.Spellbook:GetHighestRank(saved.name)
                if highest then
                    ClearCursor()
                    PickupSpell(highest.spellIndex, BOOKTYPE_SPELL)
                    PlaceAction(slot)
                    ClearCursor()
                else
                    -- Fallback to ID
                    ClearCursor()
                    PickupSpell(saved.id)
                    PlaceAction(slot)
                    ClearCursor()
                end
            elseif saved.type == "macro" and saved.name then
                ClearCursor()
                PickupMacro(saved.name)
                PlaceAction(slot)
                ClearCursor()
            elseif saved.type == "item" and saved.id then
                ClearCursor()
                PickupItem(saved.id)
                PlaceAction(slot)
                ClearCursor()
            end
        else
            -- If slot had an action but snapshot is empty, clear it
            if HasAction(slot) then
                PickupAction(slot)
                ClearCursor()
            end
        end
    end

    Utils:PlaySound("CLICK")
    Utils:Print("Action Bar Profile |cffFFFF00[" .. profileName .. "]|r loaded successfully!")
    EventBus:Fire("GH_ACTIONBARS_UPDATED")
    return true
end

-- Delete a profile
function ActionBars:DeleteProfile(profileName)
    local profiles = self:GetProfiles()
    if profiles[profileName] then
        profiles[profileName] = nil
        Utils:Print("Action Bar Profile |cffAAAAAA[" .. profileName .. "]|r deleted.")
        EventBus:Fire("GH_ACTIONBARS_UPDATED")
        return true
    end
    return false
end

-- Event Listeners
EventBus:Register("ACTIONBAR_SLOT_CHANGED", function()
    EventBus:Fire("GH_ACTIONBARS_UPDATED")
end)
