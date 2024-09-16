local messages = {}


function clans.get_clan_message_file_path(clan_name)
    return clans.get_clan_folder_path() .. clan_name .. "/messages.txt"
end

function clans.ensure_clan_message_file_exists(clan_name)
    local folder_path = clans.get_clan_folder_path() .. clan_name
    local file_path = folder_path .. "/messages.txt"

    if not minetest.mkdir(folder_path) then
        minetest.log("error", "Failed to create directory: " .. folder_path)
        return false
    end

    local file = io.open(file_path, "a")
    if not file then
        minetest.log("error", "Failed to open file for appending: " .. file_path)
        return false
    end
    file:close()
    return true
end

function clans.load_messages(clan_name)
    if not clans.ensure_clan_message_file_exists(clan_name) then
        minetest.log("error", "Failed to ensure clan message file exists for clan: " .. clan_name)
        return
    end

    local file_path = clans.get_clan_message_file_path(clan_name)
    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            table.insert(messages, line)
        end
        file:close()
    else
        minetest.log("error", "Failed to open file " .. file_path .. ".")
    end
end

function clans.save_messages(clan_name)
    if not clans.ensure_clan_message_file_exists(clan_name) then
        minetest.log("error", "Failed to ensure clan message file exists for clan: " .. clan_name)
        return
    end

    local file_path = clans.get_clan_message_file_path(clan_name)
    local file = io.open(file_path, "w")
    if file then
        for _, message in ipairs(messages) do
            file:write(message .. "\n")
        end
        file:close()
    else
        minetest.log("error", "Failed to open file " .. file_path .. " for writing.")
    end
end

function clans.show_chat_form(name)
    local player_clan, is_leader = clans.get_player_clan(minetest.get_player_by_name(name))
    if player_clan == "No Clan" then
        minetest.chat_send_player(name, "You have to be in a Clan")
    end

    messages = {}
    clans.load_messages(player_clan)

    local message_count = #messages
    local message_height = 1
    local container_height = math.min(8, message_count * message_height)
    local formspec = "size[8,9]" ..
                     "box[-0.1,-0.1;8,9.3;#030303]" ..
                     "box[-0.1,-0.1;8,0.7;black]" ..
                     "label[0,0;Clan Messaging]" ..
                     "scroll_container[0,1.25;10,8;scrollbar;vertical]"
    local y_pos = 0
    local previous_sender = nil
    local previous_date = nil
    for i = #messages, 1, -1 do
        local message = messages[i]
        local sender, time, msg = message:match("^([^%s]+)%s+(%d+:%d+:%d+)%s+:%s+(.+)")
        if sender and time and msg then
            local sender_color = minetest.colorize("#FF0000", sender)
            local player = minetest.get_player_by_name(name)
            local name = player:get_player_name()
            local x_pos = sender == name and 3.9 or 0.2
            local current_date = os.date("%Y-%m-%d", os.time())
            if previous_date and previous_date ~= current_date then
                formspec = formspec .. "label[0," .. tostring(y_pos) .. ";" .. current_date .. "]"
                y_pos = y_pos + 0.5
            end
            if previous_sender and previous_sender ~= sender then
                y_pos = y_pos + 0.5
            end
            formspec = formspec .. "label[" .. x_pos .. "," .. tostring(y_pos) .. ";" ..
                                   minetest.formspec_escape(sender_color) .. " - "..minetest.colorize("#FF0000",clans.get_player_clan(player)).." - ".. time .."]"
            y_pos = y_pos + 0.35
            local function split_message(msg)
                local segments = {}
                local start = 1
                while start <= #msg do
                    local end_pos = start + 35
                    if end_pos > #msg then
                        end_pos = #msg
                    else
                        while end_pos > start and msg:sub(end_pos, end_pos) ~= " " do
                            end_pos = end_pos - 1
                        end
                        if end_pos == start then
                            end_pos = start + 35
                        end
                    end
                    table.insert(segments, msg:sub(start, end_pos))
                    start = end_pos + 1
                end
                return segments
            end
            local segments = split_message(msg)
            for _, segment in ipairs(segments) do
                formspec = formspec .. "label[" .. x_pos + 0.1 .. "," .. tostring(y_pos) .. ";" ..
                                       minetest.formspec_escape(segment) .. "]"
                y_pos = y_pos + 0.35
            end
            previous_sender = sender
            previous_date = current_date
        end
    end
    formspec = formspec .. "scroll_container_end[]" ..
                            "tabheader[0,0;clan_tab;Clan,Invitation, Discussion;3]" ..
                            "field[0.5,8.35;5.5,1;msg;;]" ..
                            "button[5.75,8.05;2,1;send;Envoyer]" ..
                            "scrollbaroptions[max=" .. tostring(message_count * 10) .. ";thumbsize=50]" ..
                            "scrollbar[7.35,0.75;0.2,6.9;vertical;scrollbar;0]"
    minetest.show_formspec(name, "chat:form", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "chat:form" and fields.send then
        local name = player:get_player_name()
        local msg = fields.msg or ""
        if msg:match("^%s*$") then return end
        if #msg > 350 then
            minetest.chat_send_player(name, "Message too long. Maximum length is 255 characters.")
            return
        end
        local player_clan, is_leader = clans.get_player_clan(player)
        if player_clan == "No Clan" then
            minetest.chat_send_player(name, "You are not in a clan.")
            return
        end
        local new_message = name .. " " .. os.date("%H:%M:%S") .. " : " .. msg
        table.insert(messages, new_message)
        clans.save_messages(player_clan)
        clans.show_chat_form(name)
    end
end)

minetest.register_chatcommand("chat", {
    description = "",
    func = function(name)
        clans.show_chat_form(name)
    end,
})
-- Désactiver toutes les recettes du block default:chest_locked
minetest.clear_craft({
    output = "default:chest_locked"
})

-- Désactiver toutes les recettes où default:chest_locked est utilisé comme ingrédient
local recipes = minetest.get_all_craft_recipes("default:chest_locked")
if recipes then
    for _, recipe in ipairs(recipes) do
        minetest.clear_craft({ recipe = recipe })
    end
end
