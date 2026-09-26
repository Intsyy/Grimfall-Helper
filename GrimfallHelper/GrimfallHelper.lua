-- ============================================================================
-- GrimfallHelper: GrimfallHelper.lua
-- Main Lifecycle Orchestrator and Slash Command System
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
local C = GH.Constants
local Utils = GH.Utils
local EventBus = GH.EventBus

-- Register Slash Commands
SLASH_GRIMFALLHELPER1 = "/gf"
SLASH_GRIMFALLHELPER2 = "/grimfall"

SlashCmdList["GRIMFALLHELPER"] = function(msg)
    local cmd, arg = string.match(msg or "", "^(%a+)%s*(.*)$")
    cmd = cmd and string.lower(cmd) or ""
    arg = arg and Utils:Trim(arg) or ""

    if cmd == "" or cmd == "toggle" or cmd == "open" or cmd == "build" then
        if GH.UI and GH.UI.MainFrame then
            GH.UI.MainFrame:Toggle()
        end
    elseif cmd == "inspect" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(2)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Inspect target is disabled. Have players send builds via |cffffd100/gf send|r or check your |cffffd100/gf shared|r tab!")
    elseif cmd == "send" or cmd == "whisper" then
        local targetName = arg ~= "" and arg or nil
        if GH.BuildSharing then
            GH.BuildSharing:SendBuildToTarget(targetName)
        end
    elseif cmd == "shared" or cmd == "received" or cmd == "inbox" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(2)
        end
    elseif cmd == "share" then
        local channel = arg ~= "" and arg or "PARTY"
        if GH.BuildSharing then
            GH.BuildSharing:ShareToChat(channel)
        end
    elseif cmd == "spellbook" or cmd == "spells" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(3)
        end
    elseif cmd == "export" or cmd == "copy" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(4)
        end
    elseif cmd == "runes" or cmd == "runelist" or cmd == "compendium" or cmd == "database" then
        if GH.UI and GH.UI.MainFrame then
            if not GrimfallHelperMainFrame:IsShown() then
                GH.UI.MainFrame:Toggle()
            end
            GH.UI.MainFrame:SelectTab(5)
        end

    elseif cmd == "debugrunes" or cmd == "testrunes" then
        if GH.BuildExporter and GH.BuildExporter.DebugRunes then
            GH.BuildExporter:DebugRunes()
        end
    elseif cmd == "zones" or cmd == "map" then
        if GH.ZoneLevels then
            GH.ZoneLevels:PrintRecommendedZones()
        end
    elseif cmd == "help" then
        Utils:Print("|cffFFD700GrimfallHelper Slash Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf|r - Toggle main dashboard (Builds, Runes & Sharing)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf send [player]|r - Send your full build & runes directly to target player via whisper")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf shared|r - Open Shared Builds inbox (received player builds)")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf share [party|guild]|r - Share your full build summary to chat")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf export|r - Open 1-Click Build Exporter & Code Generator")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf spellbook|r - Open Classless Spellbook browser")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf runes|r - Search all 2,615 Grimfall Runes in the Rune List")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf debugrunes|r - Print local rune detection diagnostic info")
        DEFAULT_CHAT_FRAME:AddMessage("  |cff00FF96/gf zones|r - Show recommended leveling zones for your level")
    elseif cmd == "debug" then
        -- Diagnostic: print available Grimfall APIs and test timer
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r --- API Diagnostic ---")
        local apis = {
            "MysticEnchant_GetKnownRESpellIds",
            "MysticEnchant_GetActiveRESpellIds",
            "MysticEnchant_GetSpellQuality",
            "ClasslessFrame_Freepick_BuildRuneGroups",
            "ClasslessFrame_Freepick_GetKnownRuneSpellIDs",
            "GetActiveSkillCardBySlot",
            "GetSkillCards",
            "CheckInteractDistance",
            "NotifyInspect",
            "RegisterAddonMessagePrefix",
            "SendAddonMessage",
        }
        for _, name in ipairs(apis) do
            local t = type(_G[name])
            local color = (t == "function") and "|cff00FF96" or "|cffff4444"
            DEFAULT_CHAT_FRAME:AddMessage("  " .. color .. name .. "|r = " .. t)
        end
        -- Test Utils:After timer
        DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Timer test: will print in 2s...")
        if GH.Utils and GH.Utils.After then
            GH.Utils:After(2.0, function()
                DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Timer fired OK!")
            end)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r GH.Utils.After not found!")
        end
        -- Print rune count
        if GH.BuildSharing then
            local b = GH.BuildSharing:GetMyBuild()
            DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r GetMyBuild runes: " .. #(b and b.runes or {}))
        end
    else
        Utils:Print("Unknown command |cffffffff'" .. cmd .. "'|r. Type |cff00FF96/gf help|r for command list.")
    end
end

-- Initialize on Addon Loaded
EventBus:Register("ADDON_LOADED", function(event, addonName)
    if string.lower(addonName) == "grimfallhelper" or addonName == C.ADDON_NAME then
        GH.Config:Initialize()
        if GH.Spellbook then
            GH.Spellbook:Scan()
        end
        if GH.UI and GH.UI.Minimap then
            GH.UI.Minimap:Initialize()
        end
        if GH.ZoneLevels then
            GH.ZoneLevels:Initialize()
        end
        if GH.BuildExporter then
            GH.BuildExporter:Initialize()
        end
        Utils:Print("|cff00FF96v1.1.0|r loaded! Type |cffFFFF00/gf|r or click the minimap button to inspect & share builds.")
    end
end)

-- Initial Startup on Player Entering World
EventBus:Register("PLAYER_ENTERING_WORLD", function()
    if GH.Spellbook then GH.Spellbook:Scan() end
end)

-- Listen for Grimfall Classless SkillCard & MysticEnchant (Rune) State Changes
pcall(function()
    local runeEventFrame = CreateFrame("Frame")
    runeEventFrame:RegisterEvent("CUSTOM_CLASSLESS_SKILLCARD_ACTIVE_STATE_CHANGED")
    runeEventFrame:RegisterEvent("CUSTOM_MYSTIC_ENCHANTMENT_CONFIRM_SPELL_LEARNED")
    runeEventFrame:RegisterEvent("CUSTOM_MYSTIC_ENCHANTMENT_CONFIRM_SPELL_UNLEARNED")
    runeEventFrame:RegisterEvent("CUSTOM_MYSTIC_ENCHANTMENT_ROLL_AVAILABLE")
    runeEventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    runeEventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    runeEventFrame:SetScript("OnEvent", function(self, event, ...)
        if GH.UI and GH.UI.MainFrame and GrimfallHelperMainFrame and GrimfallHelperMainFrame:IsShown() then
            if GH.UI.MainFrame.RefreshInspect then
                GH.UI.MainFrame:RefreshInspect()
            end
            if GH.UI.MainFrame.RefreshExport then
                GH.UI.MainFrame:RefreshExport()
            end
        end
    end)
end)
