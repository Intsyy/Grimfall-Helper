-- ============================================================================
-- GrimfallHelper: Core/EventBus.lua
-- Central Event Bus and Event Dispatcher for WoW 3.3.5a
-- ============================================================================

GrimfallHelper = GrimfallHelper or {}
local GH = GrimfallHelper
GH.EventBus = {}
local EventBus = GH.EventBus
local Utils = GH.Utils

local frame = CreateFrame("Frame", "GrimfallHelperEventFrame")
local callbacks = {}
local customCallbacks = {}

-- Register a standard WoW Game Event
function EventBus:Register(event, fn)
    if not callbacks[event] then
        callbacks[event] = {}
        frame:RegisterEvent(event)
    end
    table.insert(callbacks[event], fn)
end

-- Register a Custom Internal GrimfallHelper Event (e.g. "GH_SPELLBOOK_UPDATED")
function EventBus:RegisterCustom(customEvent, fn)
    if not customCallbacks[customEvent] then
        customCallbacks[customEvent] = {}
    end
    table.insert(customCallbacks[customEvent], fn)
end

-- Fire a Custom Internal Event
function EventBus:Fire(customEvent, ...)
    local list = customCallbacks[customEvent]
    if list then
        for _, fn in ipairs(list) do
            local success, err = pcall(fn, ...)
            if not success then
                Utils:Debug("Error in custom event handler [" .. tostring(customEvent) .. "]: " .. tostring(err))
            end
        end
    end
end

-- Compatibility alias for EventBus:Trigger
EventBus.Trigger = EventBus.Fire

-- Main Event Script Handler
frame:SetScript("OnEvent", function(self, event, ...)
    local list = callbacks[event]
    if list then
        for _, fn in ipairs(list) do
            local success, err = pcall(fn, event, ...)
            if not success then
                Utils:Debug("Error in WoW event handler [" .. tostring(event) .. "]: " .. tostring(err))
            end
        end
    end
end)
