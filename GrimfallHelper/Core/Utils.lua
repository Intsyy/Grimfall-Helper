-- ============================================================================
-- GrimfallHelper: Core/Utils.lua
-- Utility Helpers: String Formatting, Colors, Currency, Serialization, Sounds
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.Utils = {}
local Utils = GH.Utils
local C = GH.Constants

-- Colorize text with Hex
function Utils:Colorize(text, hexColor)
    if not hexColor then return text end
    return "|cff" .. hexColor .. tostring(text) .. "|r"
end

-- Formatted Print to Default Chat Frame
function Utils:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(C.ADDON_PREFIX .. tostring(msg))
    end
end

-- Debug Print
function Utils:Debug(msg)
    if GH.Config and GH.Config:Get("debugMode", false) then
        if DEFAULT_CHAT_FRAME then
            DEFAULT_CHAT_FRAME:AddMessage("|cff999999[GF-Debug]|r " .. tostring(msg))
        end
    end
end

-- Format Currency (Copper to Gold, Silver, Copper)
function Utils:FormatMoney(copper)
    if not copper or copper <= 0 then
        return "0|cffeda55fc|r"
    end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = math.floor(copper % 100)

    local res = ""
    if gold > 0 then
        res = res .. gold .. "|cffffd700g|r "
    end
    if silver > 0 or gold > 0 then
        res = res .. silver .. "|cffc7c7cfs|r "
    end
    res = res .. cop .. "|cffeda55fc|r"
    return res
end

-- Format Large Numbers with Commas
function Utils:FormatNumber(n)
    if not n then return "0" end
    local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
    return left .. (num:reverse():gsub('(%d%d%d)', '%1,'):reverse()) .. right
end

-- String Trim
function Utils:Trim(s)
    if not s then return "" end
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- Normalize Spell/Item Name (Lowercase, trimmed)
function Utils:NormalizeName(name)
    if not name then return "" end
    local clean = string.lower(Utils:Trim(name))
    -- Remove any rank info like " (Rank 1)" if present
    clean = string.gsub(clean, "%s*%([^%)]*%)", "")
    return clean
end

-- Safe Sound Player
function Utils:PlaySound(soundKey)
    if not GH.Config or not GH.Config:Get("soundAlerts", true) then
        return
    end

    if soundKey == "FANFARE" or soundKey == "WISHLIST" then
        PlaySoundFile("Sound\\Interface\\AuctionWindowOpen.wav")
    elseif soundKey == "LEVEL_UP" then
        PlaySoundFile("Sound\\Interface\\LevelUp.wav")
    elseif soundKey == "CLICK" then
        PlaySound("igMainMenuOptionCheckBoxOn")
    elseif soundKey == "COIN" then
        PlaySoundFile("Sound\\Interface\\PickUp\\PickUpGold.wav")
    elseif soundKey == "ALERT" then
        PlaySoundFile("Sound\\Interface\\RaidWarning.wav")
    else
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
end

-- Frame-based Timer Mechanism (Delayed Callbacks for WoW 3.3.5a)
local timerFrame = CreateFrame("Frame", "GrimfallHelperTimerFrame", UIParent)
timerFrame:SetSize(1, 1)
timerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, 0)
timerFrame:Show()
local activeTimers = {}

timerFrame:SetScript("OnUpdate", function(self, elapsed)
    local i = 1
    while i <= #activeTimers do
        local t = activeTimers[i]
        t.timeLeft = t.timeLeft - elapsed
        if t.timeLeft <= 0 then
            table.remove(activeTimers, i)
            pcall(t.callback)
        else
            i = i + 1
        end
    end
end)

function Utils:After(delay, callback)
    if type(callback) ~= "function" then return end
    delay = tonumber(delay) or 0
    table.insert(activeTimers, { timeLeft = delay, callback = callback })
end

