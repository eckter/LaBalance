local addon_name = "LaBalance"
local frame_name = addon_name .. "Frame"
local frame = CreateFrame("Frame", frame_name)


frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")


frame:SetScript("OnEvent", function(self, event_name, ...)
    return self[event_name](self, event_name, ...)
end)

function frame:COMBAT_LOG_EVENT_UNFILTERED(event,...)
    local event = {CombatLogGetCurrentEventInfo()}
    local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags,
        srcFlags2, dstGUID, dstName, dstFlags, dstFlags2 = unpack(event)
    local prefix, suffix = eventType:match("^(.-)_?([^_]*)$");

    if prefix:match("^SPELL") or prefix == "RANGE" then
        local spellId, spellName, spellSchool = select(12, unpack(event))
        if spellId == 6262 and suffix:match("HEAL$") then
            print(srcName .. " a utilisé une pierre de soins ! GG !")
        end
        skip = 3
    end
end
