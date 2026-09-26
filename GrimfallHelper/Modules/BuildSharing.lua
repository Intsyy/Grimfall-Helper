-- ============================================================================
-- GrimfallHelper: Modules/BuildSharing.lua
-- Direct Whisper Build Sharing & Session Inbox System
-- Compatible with WoW 3.3.5a (Wrath of the Lich King)
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.BuildSharing = {}
local BS = GH.BuildSharing

local PROTOCOL_VERSION = "V3"

-- In-memory session store for shared builds (cleared on game exit/reload)
GH.ReceivedBuilds = GH.ReceivedBuilds or {}

-- Common talent tree abbreviation maps to fit safely within 255-char whisper limit
local TREE_SHORT = {
    ["affliction"] = "Aff", ["demonology"] = "Demo", ["destruction"] = "Dest",
    ["arcane"] = "Arc", ["fire"] = "Fire", ["frost"] = "Frst",
    ["arms"] = "Arms", ["fury"] = "Fury", ["protection"] = "Prot",
    ["holy"] = "Holy", ["retribution"] = "Ret", ["discipline"] = "Disc",
    ["shadow"] = "Shd", ["assassination"] = "Assa", ["combat"] = "Cmbt",
    ["subtlety"] = "Sub", ["elemental"] = "Ele", ["enhancement"] = "Enh",
    ["restoration"] = "Resto", ["balance"] = "Bal", ["feral combat"] = "Feral",
    ["beast mastery"] = "BM", ["marksmanship"] = "MM", ["survival"] = "Surv",
    ["blood"] = "Bld", ["unholy"] = "Unh"
}

local TREE_EXPAND = {
    ["aff"] = "Affliction", ["demo"] = "Demonology", ["dest"] = "Destruction",
    ["arc"] = "Arcane", ["fire"] = "Fire", ["frst"] = "Frost",
    ["arms"] = "Arms", ["fury"] = "Fury", ["prot"] = "Protection",
    ["holy"] = "Holy", ["ret"] = "Retribution", ["disc"] = "Discipline",
    ["shd"] = "Shadow", ["assa"] = "Assassination", ["cmbt"] = "Combat",
    ["sub"] = "Subtlety", ["ele"] = "Elemental", ["enh"] = "Enhancement",
    ["resto"] = "Restoration", ["bal"] = "Balance", ["feral"] = "Feral Combat",
    ["bm"] = "Beast Mastery", ["mm"] = "Marksmanship", ["surv"] = "Survival",
    ["bld"] = "Blood", ["unh"] = "Unholy"
}

-- Robust string split preserving empty tokens
local function Split(str, delim)
    if not str then return {} end
    local result = {}
    local from = 1
    local dFrom, dTo = string.find(str, delim, from, true)
    while dFrom do
        table.insert(result, string.sub(str, from, dFrom - 1))
        from = dTo + 1
        dFrom, dTo = string.find(str, delim, from, true)
    end
    table.insert(result, string.sub(str, from))
    return result
end

-- ============================================================================
-- EVENT LISTENER: Whisper Chat Monitor
-- ============================================================================
local listener = CreateFrame("Frame", "GrimfallBSListener")
listener:RegisterEvent("CHAT_MSG_WHISPER")
listener:RegisterEvent("CHAT_MSG_WHISPER_INFORM")

listener:SetScript("OnEvent", function(self, event, msg, sender)
    if event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_WHISPER_INFORM" then
        BS:OnWhisperReceived(msg, sender, event == "CHAT_MSG_WHISPER_INFORM")
    end
end)

-- ============================================================================
-- 1. WHISPER CHAT MONITOR
-- ============================================================================
function BS:OnWhisperReceived(msg, sender, isInform)
    if not msg or msg == "" then return end

    -- Check if message contains a Grimfall build code
    local payload = string.match(msg, "GF#(.+)")
    if not payload then return end

    -- Strip trailing whitespace/newlines
    payload = string.gsub(payload, "^%s*(.-)%s*$", "%1")

    sender = string.gsub(sender or "", "%-.+", "")
    sender = string.gsub(sender, "^%s*(.-)%s*$", "%1")
    if sender == "" then sender = UnitName("player") or "Hero" end

    -- If this is WHISPER_INFORM (we sent it), only record if target was self
    if isInform then
        local myName = UnitName("player") or ""
        if string.lower(sender) ~= string.lower(myName) then
            return
        end
    end

    -- Check if this is a chunked message (C1 or C2)
    local cNum, cData = string.match(payload, "^C(%d):(.+)$")
    if cNum and cData then
        cNum = tonumber(cNum)
        BS.chunkBuffers = BS.chunkBuffers or {}
        local key = string.lower(sender)
        BS.chunkBuffers[key] = BS.chunkBuffers[key] or {}
        BS.chunkBuffers[key][cNum] = cData
        if BS.chunkBuffers[key][1] and BS.chunkBuffers[key][2] then
            local combined = BS.chunkBuffers[key][1] .. BS.chunkBuffers[key][2]
            BS.chunkBuffers[key] = nil
            BS:ReceiveBuild(combined, sender)
        end
        return
    end

    BS:ReceiveBuild(payload, sender)
end

-- Parse and store received build in session inbox
function BS:ReceiveBuild(payload, sender)
    if not payload or payload == "" then return end

    local build = nil
    local ok, err = pcall(function()
        build = BS:DecodePayload(payload, sender)
    end)

    if not ok or not build then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r Received an unreadable build code from " .. tostring(sender))
        return
    end

    build.sender = sender
    build.receivedTime = time()

    local timeStr = ""
    pcall(function() timeStr = date("%H:%M") end)
    if timeStr == "" then timeStr = "Now" end
    build.timeStr = timeStr

    -- Update or prepend to GH.ReceivedBuilds
    local existingIdx = nil
    for idx, item in ipairs(GH.ReceivedBuilds) do
        if string.lower(item.name or item.sender or "") == string.lower(build.name or sender) then
            existingIdx = idx
            break
        end
    end

    if existingIdx then
        table.remove(GH.ReceivedBuilds, existingIdx)
    end
    table.insert(GH.ReceivedBuilds, 1, build) -- newest on top

    -- Audio chime
    pcall(function()
        if GH.Utils and GH.Utils.PlaySound then
            GH.Utils:PlaySound("WISHLIST")
        end
    end)

    -- Discrete chat notice (no jarring UI popup)
    local rCount = #(build.runes or {})
    local eval = build.evaluation or {}
    local score = eval.totalScore or 0
    local role = eval.role or "Classless"
    local title = eval.ratingTitle or "Adventurer"
    local tCount = build.talentCount or 0

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cff00FF96[GrimfallHelper]|r Received full build from |cffffd100" .. (build.name or sender)
        .. "|r! Saved to |cffffd100[Shared Builds]|r tab. (|cffffffff" .. rCount .. " Runes|r | " .. tCount .. " Talents | Score: " .. score .. " " .. title .. " | " .. role .. ")"
    )
    DEFAULT_CHAT_FRAME:AddMessage(
        "  |cff888888Click the minimap button or type |cff00FF96/gf shared|r to inspect their full build.|r"
    )

    -- Notify EventBus & refresh UI if Shared tab is currently open
    pcall(function()
        if GH.EventBus then
            GH.EventBus:Fire("RECEIVED_BUILDS_UPDATED", build)
        end
        if GH.UI and GH.UI.MainFrame and GH.UI.MainFrame.RefreshSharedTab then
            GH.UI.MainFrame:RefreshSharedTab()
        end
    end)
end

-- ============================================================================
-- 2. SEND BUILD DIRECTLY TO TARGET PLAYER (Standard Whisper)
-- ============================================================================
function BS:InspectTarget()
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r Target inspect is disabled. Use |cff00FF96/gf send|r to whisper builds directly.")
end

function BS:SendBuildToTarget(targetName)
    targetName = targetName or UnitName("target")
    if not targetName or targetName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r Please select a player target first, or type: /gf send <name>")
        return false
    end

    local myBuild = BS:GetMyBuild()
    if not myBuild then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[GrimfallHelper]|r Could not collect your character's build data.")
        return false
    end

    local payload = BS:EncodePayload(myBuild)
    local fullCode = "GF#" .. payload

    if string.len(fullCode) <= 254 then
        SendChatMessage(fullCode, "WHISPER", nil, targetName)
    else
        local half = math.ceil(string.len(payload) / 2)
        local p1 = string.sub(payload, 1, half)
        local p2 = string.sub(payload, half + 1)
        SendChatMessage("GF#C1:" .. p1, "WHISPER", nil, targetName)
        SendChatMessage("GF#C2:" .. p2, "WHISPER", nil, targetName)
    end

    local runeCount = #(myBuild.runes or {})
    local score = myBuild.evaluation and myBuild.evaluation.totalScore or 0
    local talentCount = myBuild.talentCount or 0
    DEFAULT_CHAT_FRAME:AddMessage("|cff00FF96[GrimfallHelper]|r Whispered your build to |cffffd100" .. targetName .. "|r! (" .. runeCount .. " runes, " .. talentCount .. " talents, Score: " .. score .. ")")
    DEFAULT_CHAT_FRAME:AddMessage("|cff888888If they have GrimfallHelper installed, it will appear in their 'Shared Builds' tab.|r")
    return true
end

-- ============================================================================
-- 3. BUILD PAYLOAD ENCODE / DECODE (V3: Compact Stats at Front + Talents + Runes)
-- ============================================================================
function BS:EncodePayload(build)
    build = build or {}
    local rList = {}
    for _, r in ipairs(build.runes or {}) do
        local sid = tonumber(r.spellId) or 0
        if sid == 0 and r.name and GH.RuneDataByName then
            sid = GH.RuneDataByName[string.lower(r.name)] or 0
        end
        local q = tonumber(r.quality) or 2
        if sid > 0 then
            local known = GH.RuneData and GH.RuneData[sid]
            if known and (known.quality == q or not known.quality) then
                table.insert(rList, tostring(sid))
            else
                table.insert(rList, sid .. ":" .. q)
            end
        elseif r.name and r.name ~= "" then
            local safeName = string.gsub(r.name, "[,:~]", " ")
            safeName = string.gsub(safeName, "^%s*(.-)%s*$", "%1")
            table.insert(rList, "0:" .. q .. ":" .. safeName)
        end
    end

    local sortedTalents = {}
    for _, t in ipairs(build.talents or {}) do
        local pts = tonumber(t.points) or 0
        if pts > 0 and t.name and t.name ~= "" then
            table.insert(sortedTalents, { name = t.name, points = pts })
        end
    end
    table.sort(sortedTalents, function(a, b) return a.points > b.points end)

    local tList = {}
    for _, t in ipairs(sortedTalents) do
        local shortName = TREE_SHORT[string.lower(t.name)] or t.name
        local safeTree = string.gsub(shortName, "[,:~]", " ")
        safeTree = string.gsub(safeTree, "^%s*(.-)%s*$", "%1")
        table.insert(tList, safeTree .. ":" .. t.points)
    end

    local s = build.stats or {}
    local cleanCrit = string.gsub(tostring(s.meleeCrit or "0"), "%%", "")
    -- Pack ALL primary attributes and combat stats at Field 6 (never truncated!)
    -- ilvl:str:agi:sta:int:spi:ap:sp:armor:def:crit
    local statsPacked = string.format("%d:%d:%d:%d:%d:%d:%d:%d:%d:%d:%s",
        tonumber(s.ilvl) or 0,
        tonumber(s.str) or 0,
        tonumber(s.agi) or 0,
        tonumber(s.sta) or 0,
        tonumber(s.int) or 0,
        tonumber(s.spi) or 0,
        tonumber(s.ap) or 0,
        tonumber(s.sp) or 0,
        tonumber(s.armor) or 0,
        tonumber(s.defense) or 0,
        cleanCrit)

    local fields = {
        PROTOCOL_VERSION,
        build.name    or UnitName("player")  or "Hero",
        build.level   or UnitLevel("player") or 80,
        build.class   or UnitClass("player") or "Hero",
        build.race    or UnitRace("player")  or "Unknown",
        statsPacked,
        build.talentCount or 0,
        table.concat(tList, ","),
        table.concat(rList, ","),
    }
    return table.concat(fields, "~")
end

function BS:DecodePayload(str, fallbackSender)
    if not str or str == "" then return nil end
    local parts = Split(str, "~")
    if #parts < 5 then return nil end

    local version = string.upper(parts[1] or "")
    local name  = (parts[2] and parts[2] ~= "") and parts[2] or (fallbackSender or "Hero")
    local level = tonumber(parts[3]) or 80
    local class = (parts[4] and parts[4] ~= "") and parts[4] or "Hero"
    local race  = (parts[5] and parts[5] ~= "") and parts[5] or "Unknown"

    local ilvl, strVal, agiVal, staVal, intVal, spiVal = 0, 0, 0, 0, 0, 0
    local ap, sp, armor, def, crit = 0, 0, 0, 0, "0%"
    local talentCount = 0
    local treeStr = ""
    local runeStr = ""

    if version == "V3" then
        -- V3 Format: parts[6] = statsPacked, parts[7] = talentCount, parts[8] = treeStr, parts[9] = runeStr
        local sTokens = Split(parts[6] or "", ":")
        ilvl   = tonumber(sTokens[1]) or 0
        strVal = tonumber(sTokens[2]) or 0
        agiVal = tonumber(sTokens[3]) or 0
        staVal = tonumber(sTokens[4]) or 0
        intVal = tonumber(sTokens[5]) or 0
        spiVal = tonumber(sTokens[6]) or 0
        ap     = tonumber(sTokens[7]) or 0
        sp     = tonumber(sTokens[8]) or 0
        armor  = tonumber(sTokens[9]) or 0
        def    = tonumber(sTokens[10]) or 0
        crit   = (sTokens[11] and sTokens[11] ~= "") and sTokens[11] or "0%"
        if not string.find(crit, "%%") and crit ~= "" then
            crit = crit .. "%"
        end

        talentCount = tonumber(parts[7]) or 0
        treeStr     = parts[8] or ""
        runeStr     = parts[9] or ""
    else
        -- V2 Backward Compatibility (14 fields)
        ap    = tonumber(parts[6]) or 0
        sp    = tonumber(parts[7]) or 0
        armor = tonumber(parts[8]) or 0
        def   = tonumber(parts[9]) or 0
        crit  = (parts[10] and parts[10] ~= "") and parts[10] or "0%"
        runeStr     = parts[11] or ""
        talentCount = tonumber(parts[12]) or 0
        treeStr     = parts[13] or ""
        local primaryStr = parts[14] or ""

        if primaryStr ~= "" then
            local pTokens = Split(primaryStr, ":")
            ilvl   = tonumber(pTokens[1]) or 0
            strVal = tonumber(pTokens[2]) or 0
            agiVal = tonumber(pTokens[3]) or 0
            staVal = tonumber(pTokens[4]) or 0
            intVal = tonumber(pTokens[5]) or 0
            spiVal = tonumber(pTokens[6]) or 0
        end
    end

    local runes = {}
    if runeStr ~= "" then
        for _, entry in ipairs(Split(runeStr, ",")) do
            if entry ~= "" then
                local sid, q, customName = string.match(entry, "^(%d+):?(%d*):?(.*)$")
                sid = tonumber(sid) or 0
                q   = tonumber(q)
                if sid > 0 then
                    local rData = GH.RuneData and GH.RuneData[sid]
                    local resolvedQ = (rData and rData.quality) or q or 2
                    table.insert(runes, {
                        spellId = sid,
                        name    = (rData and rData.name) or ("Rune #" .. sid),
                        quality = resolvedQ,
                        desc    = (rData and rData.desc) or "Grimfall Runic Enhancement",
                    })
                elseif customName and customName ~= "" then
                    local rData = GH.RuneDataByName and GH.RuneDataByName[string.lower(customName)]
                    table.insert(runes, {
                        spellId = rData or 0,
                        name    = customName,
                        quality = q or 2,
                        desc    = (rData and GH.RuneData and GH.RuneData[rData] and GH.RuneData[rData].desc) or "Equipped Gear Rune",
                    })
                end
            end
        end
    end

    local trees = {}
    if treeStr ~= "" then
        for _, entry in ipairs(Split(treeStr, ",")) do
            if entry ~= "" then
                local tName, pts = string.match(entry, "^(.-):(%d+)$")
                if tName and pts then
                    local fullName = TREE_EXPAND[string.lower(tName)] or tName
                    table.insert(trees, {
                        name = fullName,
                        points = tonumber(pts) or 0,
                    })
                end
            end
        end
    end

    table.sort(trees, function(a, b) return a.points > b.points end)

    local treeParts = {}
    for _, t in ipairs(trees) do
        table.insert(treeParts, t.name .. " (" .. t.points .. ")")
    end
    local talentSummary = (#treeParts > 0) and table.concat(treeParts, "  •  ") or (talentCount .. " pts")

    local buildData = {
        name        = name,
        level       = level,
        class       = class,
        race        = race,
        stats       = {
            ilvl = ilvl,
            str = strVal,
            agi = agiVal,
            sta = staVal,
            int = intVal,
            spi = spiVal,
            ap = ap,
            sp = sp,
            armor = armor,
            defense = def,
            meleeCrit = crit,
            hit = "0%",
        },
        runes       = runes,
        talents     = trees,
        talentCount = talentCount,
        talentSummary = talentSummary,
        timestamp   = time(),
    }

    if GH.BuildEvaluator then
        pcall(function()
            buildData.evaluation = GH.BuildEvaluator:EvaluateBuild(buildData)
        end)
    end
    return buildData
end

-- ============================================================================
-- 4. GENERATE / PARSE COMPACT SHARE CODE (GF#...)
-- ============================================================================
function BS:GenerateBuildCode(build)
    build = build or BS:GetMyBuild()
    if not build then return "" end
    return "GF#" .. BS:EncodePayload(build)
end

function BS:ParseBuildCode(input)
    if not input or input == "" then return nil end
    input = string.gsub(input, "^%s*(.-)%s*$", "%1")

    -- Check if it contains GF#
    local code = string.match(input, "GF#(.+)")
    if code then
        code = string.gsub(code, "^%s*(.-)%s*$", "%1")
        return BS:DecodePayload(code, "Imported")
    end

    local runes = {}
    local seen  = {}
    for sid in string.gmatch(input, "Spell ID:%s*(%d+)") do
        sid = tonumber(sid)
        if sid and not seen[sid] then
            seen[sid] = true
            local rData = GH.RuneData and GH.RuneData[sid]
            table.insert(runes, {
                spellId = sid,
                name    = (rData and rData.name) or ("Rune #" .. sid),
                quality = (rData and rData.quality) or 3,
                desc    = (rData and rData.desc) or "Grimfall Runic Enhancement",
            })
        end
    end

    if #runes > 0 then
        local buildData = {
            name        = "Imported Build",
            level       = 80,
            class       = "Classless Hero",
            race        = "Unknown",
            stats       = { ap = 0, sp = 0, armor = 0, defense = 0, meleeCrit = "0%" },
            runes       = runes,
            talents     = {},
            talentCount = 0,
            talentSummary = "Imported",
            timestamp   = time(),
        }
        if GH.BuildEvaluator then
            pcall(function()
                buildData.evaluation = GH.BuildEvaluator:EvaluateBuild(buildData)
            end)
        end
        return buildData
    end

    return nil
end

-- ============================================================================
-- 5. SHARE BUILD TO CHAT (Party, Guild, Raid)
-- ============================================================================
function BS:ShareToChat(channel, targetPlayer)
    local build = BS:GetMyBuild()
    if not build then return end

    local eval      = build.evaluation or {}
    local score     = eval.totalScore  or 0
    local rating    = eval.ratingTitle or "Adventurer"
    local role      = eval.role        or "Classless"
    local runeCount = #(build.runes    or {})
    local code      = BS:GenerateBuildCode(build)

    local summaryMsg = string.format(
        "[Grimfall] %s (Lvl %d) | Score: %d %s | %s | %d Runes",
        build.name or "Hero", build.level or 80, score, rating, role, runeCount
    )

    channel = string.upper(channel or "PARTY")
    if channel == "WHISPER" then
        BS:SendBuildToTarget(targetPlayer)
    elseif channel == "GUILD" or channel == "PARTY" or channel == "RAID" or channel == "SAY" then
        pcall(function() SendChatMessage(summaryMsg, channel) end)
        pcall(function() SendChatMessage(code, channel) end)
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00FF96[GrimfallHelper]|r Shared build to " .. channel .. "."
        )
    end
end

-- ============================================================================
-- 6. GET LOCAL PLAYER'S FULL BUILD
-- ============================================================================
function BS:GetMyBuild()
    local name  = UnitName("player")  or "Hero"
    local level = UnitLevel("player") or 80
    local class = UnitClass("player") or "Hero"
    local race  = UnitRace("player")  or "Unknown"

    local stats = {}
    if GH.BuildExporter and GH.BuildExporter.CollectStats then
        stats = GH.BuildExporter:CollectStats()
    end

    local rawRunes = {}
    if GH.BuildExporter then
        if GH.BuildExporter.CollectRunes then
            rawRunes = GH.BuildExporter:CollectRunes()
        elseif GH.BuildExporter.CollectActiveRunes then
            rawRunes = GH.BuildExporter:CollectActiveRunes()
        end
    end

    local runes = {}
    local seen  = {}
    for _, r in ipairs(rawRunes) do
        local sid       = tonumber(r.spellId) or 0
        local cleanName = r.name or ""

        if sid == 0 and cleanName ~= "" and GH.RuneDataByName then
            sid = GH.RuneDataByName[string.lower(cleanName)] or 0
        end

        local rData = (sid > 0 and GH.RuneData and GH.RuneData[sid]) or nil
        local rName = (rData and rData.name) or cleanName
        if rName == "" then rName = "Rune #" .. sid end

        if not seen[rName] then
            seen[rName] = true
            table.insert(runes, {
                spellId = sid,
                name    = rName,
                quality = (rData and rData.quality) or tonumber(r.quality) or 2,
                desc    = (rData and rData.desc) or r.desc or "Grimfall Runic Enhancement",
            })
        end
    end

    local rawTalents        = {}
    local totalTalentPoints = 0
    if GH.BuildExporter and GH.BuildExporter.CollectTalents then
        rawTalents = GH.BuildExporter:CollectTalents()
        for _, tree in ipairs(rawTalents) do
            totalTalentPoints = totalTalentPoints + (tree.points or 0)
        end
    end

    local sortedTalents = {}
    for _, t in ipairs(rawTalents) do
        if (t.points or 0) > 0 then
            table.insert(sortedTalents, { name = t.name or "Tree", points = t.points })
        end
    end
    table.sort(sortedTalents, function(a, b) return a.points > b.points end)

    local treeParts = {}
    for _, t in ipairs(sortedTalents) do
        table.insert(treeParts, t.name .. " (" .. t.points .. ")")
    end
    local talentSummary = (#treeParts > 0) and table.concat(treeParts, "  •  ") or (totalTalentPoints .. " pts")

    local buildData = {
        name        = name,
        level       = level,
        class       = class,
        race        = race,
        stats       = stats,
        runes       = runes,
        talents     = rawTalents,
        talentCount = totalTalentPoints,
        talentSummary = talentSummary,
        timestamp   = time(),
    }

    if GH.BuildEvaluator then
        pcall(function()
            buildData.evaluation = GH.BuildEvaluator:EvaluateBuild(buildData)
        end)
    end
    return buildData
end
