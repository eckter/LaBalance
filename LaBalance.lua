local addon_name = "LaBalance"
local frame_name = addon_name .. "Frame"
local frame = CreateFrame("Frame", frame_name)
local in_combat = false
local raid_name_dict = {}
local cur_num
local cmd_name = "/labalance"

frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event_name, ...)
    return self[event_name](self, event_name, ...)
end)

function command_chan(msg)
    cmd, args = strsplit(" ", msg, 2)
    if cmd == "set" then
        if not args:match("^[a-zA-Z]+$") then
            print("error: invalid chan name")
            return false
        end
        la_balance_save["chan"] = args
    elseif cmd == "disable" then
        la_balance_save["chan"] = nil
    else
        return false
    end
    return true
end

function run_command(cmd, args)
    if cmd == "chan" then
        return command_chan(args)
    else
        return false
    end
end

SLASH_LABALANCE1 = cmd_name
SlashCmdList["LABALANCE"] = function(msg)
    cmd, args = strsplit(" ", msg, 2)
    if not run_command(cmd, args) then
        print(addon_name .. " usage:")
        print(cmd_name .. " chan set abc: sets the messages to the chan abc")
        print(cmd_name .. " chan disable: only print the messages localy")
    end
end

function frame:ADDON_LOADED(event_name, name)
    if name == addon_name then
        print(la_balance_save)
        if not la_balance_save then
            la_balance_save = {}
        end
    end
end

function frame:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
    if IsEncounterInProgress() then  -- returns 1 when you're in a fight you can't release from
    	in_combat = true
    	-- print("engaging combat")
        cur_num = GetNumGroupMembers()
        for i = 1, cur_num do
            name, rank, subgroup, level, class, fileName, zone, online, isDead,
            	role, isML = GetRaidRosterInfo(i);
            raid_name_dict[i] = name
        end
    end
end

function frame:PLAYER_REGEN_ENABLED()
    if in_combat then
        in_combat = false
        for i = 1, cur_num do
            print(raid_name_dict[i])
        end
    end
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(event,...)
    local event = {CombatLogGetCurrentEventInfo()}
    local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags,
        srcFlags2, dstGUID, dstName, dstFlags, dstFlags2 = unpack(event)
    local prefix, suffix = eventType:match("^(.-)_?([^_]*)$");

    if eventType:match("^UNIT_DIED$") then
        local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", dstGUID);
        if type == "Player" then
            print(dstName .. " est mort. BOUH !")
        end
    end

    if prefix:match("^SPELL") or prefix == "RANGE" then
        local spellId, spellName, spellSchool = select(12, unpack(event))
        if spellId == 6262 and suffix:match("HEAL$") then
            print(srcName .. " a utilisé une pierre de soins ! GG !")
        end
        skip = 3
    end
end
