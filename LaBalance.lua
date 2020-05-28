local addon_name = "LaBalance"
local frame_name = addon_name .. "Frame"
local frame = CreateFrame("Frame", frame_name)
local in_combat = false
local raid_name_dict = {}
local raid_pds_dict = {}
local cur_num
local cmd_name = "/labalance"


 -- list of interesting events which could be used later
 -- ZONE_CHANGED_NEW_AREA
 -- Group_roster_update

frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event_name, ...)
    return self[event_name](self, event_name, ...)
end)

local avoidable = {

    -- shadar hm ?
    [306928] = 42, -- souffle ombreux
    [307945] = 42, -- eruption ombreuse
    [306929] = 42, -- souffle entropique
    --[306930] = 42, -- souffle bouillonant
    -- irion MM
    [307053] = 42, -- flaque de lave
    [306735] = 42, -- cataclysme
                  -- bourrasque explosive
                  -- claque-queue
                  -- folie rampante
    -- Skitra MM
                  -- images deferlantes
    -- maut MM
    [314337] = 42, -- malediction
    [308044] = 42 -- annihilation
}


function trash(player_name)
    local punchlines = { "L'espoir fait vivre. Mais pas " .. player_name .. ".",
        "Tu nous manqueras, " .. player_name .. ". Ou pas !", player_name .. ", spé carpette.",
        "Libéré, délivré ! " .. player_name .. " va arrêter de taper !",
        player_name .. " feint la mort avec un réalisme a couper le souffle !",
        player_name .. " préfère discuter avec Bwonsamdi.",
        player_name .. " n'a pas réussi à maintenir ses points de vie au dessus de zéro.",
        "Qu'est-ce que c'est que ce truc sous mes semelles ? Ah, c'est " .. player_name .. " !",
        player_name .. ", heure du décès : " .. date("%H:%M.")
    }
    trash_msg = punchlines[random(table.getn(punchlines))]
    print(trash_msg)
    send_message(trash_msg)
end


function send_message(msg)
    local chan = la_balance_save["chan"]
    if chan == nil then
        print(msg)
    else
        id, name = GetChannelName(chan)
        print(id)
        print(name)
        if id > 0 then
            SendChatMessage(msg, "CHANNEL", nil, id)
        else
            print(addon_name .. " warning: can't send to chan " .. chan)
            print("return to default and only print localy")
            la_balance_save["chan"] = nil
        end
    end
end

function command_chan(msg)
    cmd, args = strsplit(" ", msg, 2)
    if cmd == "set" then
        if not args:match("^[0-9a-zA-Z]+$") then
            print("error: invalid chan name")
            return false
        end
        la_balance_save["chan"] = args
        print(addon_name .. ": set output to chan " .. args)
        send_message("Test.")
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
        if not la_balance_save then
            la_balance_save = {}
        end
    end
end

function frame:ENCOUNTER_START(encounterID, encName, difficulty, size)
    in_combat = true
    print("engaging combat with " .. encName .. ".")
    cur_num = GetNumGroupMembers()
    for i = 1, cur_num do
        name, rank, subgroup, level, class, fileName, zone, online, isDead,
            role, isML = GetRaidRosterInfo(i);
        raid_name_dict[i] = name
    end
end

function frame:ENCOUNTER_END(encounterID, name, difficulty, size, success)
    in_combat = false
    print("end of combat")
    --for key,value in pairs(raid_pds_dict) do send_message(key .. (value and " a " or " n'a pas ")
    --  .. "utilisé sa pierre de soin") end
    raid_name_dict = {}
end

function frame:COMBAT_LOG_EVENT_UNFILTERED(event,...)
    local event = {CombatLogGetCurrentEventInfo()}
    local timestamp, eventType, hideCaster, srcGUID, srcName, srcFlags,
        srcFlags2, dstGUID, dstName, dstFlags, dstFlags2 = unpack(event)
    local prefix, suffix = eventType:match("^(.-)_?([^_]*)$");

    if eventType:match("^UNIT_DIED$") then
        local type, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", dstGUID);
        if type == "Player" then
            print(dstName .. " est mort ! BOUH !")
            if in_combat then
                trash(dstName)
            end
        end
    end



    if prefix:match("^SPELL") or prefix == "RANGE" then
        if suffix == "DAMAGE" then
            local spellId, spellName, spellSchool, amount, overkill,
                school, resisted, blocked, absorbed, critical, glancing, crushing = select(12, unpack(event))
            if avoidable[spellId] then
                send_message(dstName .. " a subi " .. amount .. " de " .. GetSpellLink(spellId) .. ".")
            end
        else
            local spellId, spellName, spellSchool = select(12, unpack(event))
            if spellId == 6262 and suffix:match("HEAL$") then
                print(srcName .. " a utilisé une pierre de soins ! GG !")
            end
        end
    end
end
