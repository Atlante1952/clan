local max_number_characters = 10
local min_number_characters = 4
local message_color = "#aac729"

local function get_player_clan(player)
    local player_name = player:get_player_name()
    local folder_path = minetest.get_worldpath() .. "/clans/"

    local dir_list = minetest.get_dir_list(folder_path, false)
    if dir_list then
        for _, file_name in ipairs(dir_list) do
            local file_path = folder_path .. file_name
            local file = io.open(file_path, "r")
            if file then
                local content = file:read("*all")
                file:close()
                if content:find("Leader: " .. player_name) then
                    return file_name:sub(1, -5), true
                elseif content:find("Member: " .. player_name) then
                    return file_name:sub(1, -5), false
                end
            end
        end
    end
    return "No Faction", false
end

local function get_clan_info(clan_name)
    local folder_path = minetest.get_worldpath() .. "/clans/"
    local file_path = folder_path .. clan_name .. ".txt"
    local members = {}
    local clan_info = ""

    local file = io.open(file_path, "r")
    if file then
        local content = file:read("*all")
        file:close()

        for line in content:gmatch("[^\r\n]+") do
            local rank, name = line:match("(%w+):%s*(%S+)")
            if rank and name and (rank == "Member" or rank == "Leader") then
                table.insert(members, rank .. ": " .. name)
            elseif rank == "Information" then
                clan_info = line:sub(#rank + 2)
            end
        end
    end

    return members, clan_info
end

local function get_all_clans()
    local folder_path = minetest.get_worldpath() .. "/clans/"
    local clans = {}

    local dir_list = minetest.get_dir_list(folder_path, false)
    if dir_list then
        for _, file_name in ipairs(dir_list) do
            local clan_name = file_name:sub(1, -5)
            table.insert(clans, clan_name)
        end
    end

    return clans
end

local function get_total_clans_count()
    local folder_path = minetest.get_worldpath() .. "/clans/"
    local dir_list = minetest.get_dir_list(folder_path, false)
    if dir_list then
        return #dir_list
    end
    return 0
end

local function save_clan_info(player, public_info)
    local faction_name, is_leader = get_player_clan(player)

    if is_leader then
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. faction_name .. ".txt"

        local found_info = false
        local new_lines = {}

        local file = io.open(file_path, "r")
        if file then
            for line in file:lines() do
                if line:find("^Information:") then
                    found_info = true
                    table.insert(new_lines, "Information: " .. public_info)
                else
                    table.insert(new_lines, line)
                end
            end
            file:close()
        end

        if not found_info then
            table.insert(new_lines, "Information: " .. public_info)
        end

        file = io.open(file_path, "w")
        if file then
            for _, line in ipairs(new_lines) do
                file:write(line .. "\n")
            end
            file:close()
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Information saved successfully."))
        else
            minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Unable to open file to save information."))
        end
    else
        minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, minetest.colorize(message_color, "[Server] -!- You must be the faction leader to save public information about the clan.")))
    end
end

minetest.register_chatcommand("clan", {
    description = "Open Clan Interface",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            show_clan_interface(player)
        end
    end,
})

function show_clan_interface(player)
    local player_clan = get_player_clan(player)
    local members, clan_info = get_clan_info(player_clan)
    local all_clans = get_all_clans()

    local function get_member_count(clan)
        local members = get_clan_info(clan)
        return #members
    end

    local clan_list_text = ""
    for _, clan in ipairs(all_clans) do
        clan_list_text = clan_list_text .. clan .. " (" .. get_member_count(clan) .. " Members),"
    end
    clan_list_text = string.sub(clan_list_text, 1, -2)

    local total_clans_count = get_total_clans_count()

    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]"..
        "box[-0.1,3.75;8,0.7;black]"..
        "box[-0.1,7.55;8,0.7;black]"..
        "box[-0.1,-0.1;8,9.4;#030303]"..

        "field[6.4,0.15;2,1;clan_name;;]" ..
        "field[6,6.25;2,1;clan_kick_playername;;]" ..

        --"textarea[0.35,1;3.5,3;public_info;;".. clan_info .. "]" ..

        "textlist[0,4.75;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..

        "image_button[2.8,2.9;0.75,0.75;save_icon.png;save_button;]"..

        --"button[3.95,4.95;1.75,1;fhome;Clan Home]" ..
        --"button[5.7,4.95;2,1;setfhome;Set Clan Home]" ..
        "button[3.95,5.95;1.75,1;kick;kick]" ..
        "button[4.825,-0.175;1.5,1;create;Create]" ..
        "button[3.545,-0.175;1.5,1;rename;Rename]" ..
        "button[0,8.35;2,1;leave;Leave the clan]" ..
        "style[delete;bgcolor=#202c37]" ..
        "button[6,8.35;2,1;delete;Delete Clan]" ..

        --"label[0,0.65;##Informations about the clans]" ..
        "label[0,0;#Clan : " .. minetest.colorize("#3e6789", player_clan) .. "]" ..
        "label[0,3.9;#Members of : " .. minetest.colorize("#3e6789", player_clan) .. " (" .. #members .. " Members)]" ..
        "label[0,7.7;#Personal :" .. minetest.colorize("#3e6789", " About You") .. "]" ..
        "label[4,0.6;##List of all clans (" .. total_clans_count .. " Clans)]" ..
        "textlist[4,1;3.5,2.5;all_clans;" .. clan_list_text .. "]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation;1]"

    minetest.show_formspec(player:get_player_name(), "clan_interface", formspec)
end

function show_invitation_interface(player)
    local player_clan = get_player_clan(player)
    local members, clan_info = get_clan_info(player_clan)
    local all_clans = get_all_clans()

    local function get_member_count(clan)
        local members = get_clan_info(clan)
        return #members
    end

    local player_name = player:get_player_name()
    local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
    local invited_clans = {}

    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
            if invited_player == player_name then
                table.insert(invited_clans, clan_name)
            end
        end
        file:close()
    end

    local clan_list_text = ""
    for _, clan in ipairs(all_clans) do
        clan_list_text = clan_list_text .. clan .. " (" .. get_member_count(clan) .. " Members),"
    end
    clan_list_text = string.sub(clan_list_text, 1, -2)
    local invitations_count = #invited_clans
    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]"..
        "box[-0.1,3.75;8,0.7;black]"..
        "box[-0.1,-0.1;8,9.4;#030303]"..

        "textarea[0.35,1;3.5,2;invit_msg;;]" ..

        "label[0,0;#Clan : " .. minetest.colorize("#3e6789", player_clan) .. "]" ..
        "label[0,0.65;##Invitation Message]" ..
        "label[4,4.65;##Message from the clan.]" ..
        "label[0,3.9;#Personal : " .. minetest.colorize("#3e6789", "Your Inbox") .. " (You have received " .. invitations_count .. " requests)]" ..

        "textlist[4,1;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
        "textlist[0,4.75;3.5,2.5;invited_clans;" .. table.concat(invited_clans, ",") .. "]" ..
        
        "field[1.8,3.05;2,1;invit_field;;]" ..
        "button[0.05,8.2;1.5,1;join_clan;Join]" ..
        "field[1.8,8.5;2.35,1;join_clanf;Confirm Clan Name;]" ..
        
        "button[0.05,2.75;1.5,1;invit_btn;Invite]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation;2]"

    minetest.show_formspec(player:get_player_name(), "invitation_interface", formspec)
end


function show_other_interface(player)
    local player_clan = get_player_clan(player)
    local members, clan_info = get_clan_info(player_clan)
    local all_clans = get_all_clans()

    local function get_member_count(clan)
        local members = get_clan_info(clan)
        return #members
    end

    local player_name = player:get_player_name()
    local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
    local invited_clans = {}

    local file = io.open(file_path, "r")
    if file then
        for line in file:lines() do
            local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
            if invited_player == player_name then
                table.insert(invited_clans, clan_name)
            end
        end
        file:close()
    end

    local clan_list_text = ""
    for _, clan in ipairs(all_clans) do
        clan_list_text = clan_list_text .. clan .. " (" .. get_member_count(clan) .. " Members),"
    end
    clan_list_text = string.sub(clan_list_text, 1, -2)
    local invitations_count = #invited_clans
    local formspec = "size[8,9]" ..
        "box[-0.1,-0.1;8,0.7;black]"..
        "box[-0.1,-0.1;8,9.4;#030303]"..

        "label[0,0;#Clan : " .. minetest.colorize("#3e6789", player_clan) .. "]" ..
        "tabheader[0,0;clan_tab;Clan,Invitation;2]"

    minetest.show_formspec(player:get_player_name(), "other_interface", formspec)
end

--------------------------------------------------------------------------------
---------- Invit Clan Button Fonction
--------------------------------------------------------------------------------



minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.invited_clans then
            local event = minetest.explode_textlist_event(fields.invited_clans)
            if event.type == "CHG" then
                local player_clan = get_player_clan(player)
                local members, clan_info = get_clan_info(player_clan)
                local all_clans = get_all_clans()
                local function get_member_count(clan)
                    local members = get_clan_info(clan)
                    return #members
                end

                local player_name = player:get_player_name()
                local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
                local invited_clans = {}

                local file = io.open(file_path, "r")
                if file then
                    for line in file:lines() do
                        local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                        if invited_player == player_name then
                            table.insert(invited_clans, clan_name)
                        end
                    end
                    file:close()
                end

                local clan_list_text = ""
                for _, clan in ipairs(all_clans) do
                    clan_list_text = clan_list_text .. clan .. " (" .. get_member_count(clan) .. " Members),"
                end
                clan_list_text = string.sub(clan_list_text, 1, -2)

                local invitations_count = #invited_clans
                local selected_index = event.index
                local player_name = player:get_player_name()
                local file_path = minetest.get_worldpath() .. "/claninvitation.txt"

                local file = io.open(file_path, "r")
                if file then
                    local counter = 0
                    for line in file:lines() do
                        local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                        if invited_player == player_name then
                            counter = counter + 1
                            if counter == selected_index then
                                local message = line:match("Message:%s*(.+)")
                                if message then
                                    local formspec = "size[8,9]" ..
                                    "box[-0.1,-0.1;8,0.7;black]"..
                                    "box[-0.1,3.75;8,0.7;black]"..
                                    "box[-0.1,-0.1;8,9.4;#030303]"..
                                    "textarea[0.35,1;3.5,2;invit_msg;;]" ..
                                    "label[0,0;#Clan : " .. minetest.colorize("#3e6789", player_clan) .. "]" ..
                                    "label[0,0.65;##Invitation Message]" ..
                                    "label[4,4.65;##Message from the clan.]" ..
                                    "label[0,3.9;#Personal : " .. minetest.colorize("#3e6789", "Your Inbox") .. " (You have received " .. invitations_count .. " requests)]" ..
                                    "textlist[4,1;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
                                    "textlist[0,4.75;3.5,2.5;invited_clans;" .. table.concat(invited_clans, ",") .. "]" ..
                                    "field[1.8,3.05;2,1;invit_field;;]" ..
                                    "button[0.05,2.75;1.5,1;invit_btn;Invite]" ..
                                    "button[0.05,8.2;1.5,1;join_clan;Join]" ..
                                    "field[1.8,8.5;2.35,1;join_clanf;Confirm Clan Name;]" ..
                                    "tabheader[0,0;clan_tab;Clan,Invitation;2]" ..
                                    "hypertext[4.2,5.5;4.1,4;;" .. message .. "]"

                                    minetest.show_formspec(player_name, "invitation_interface", formspec)
                                    break
                                end
                            end
                        end
                    end
                    file:close()
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
---------- Update Interface
--------------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.invited_clans then
            local event = minetest.explode_textlist_event(fields.invited_clans)
            if event.type == "CHG" then
                local player_clan = get_player_clan(player)
                local members, clan_info = get_clan_info(player_clan)
                local all_clans = get_all_clans()
                local function get_member_count(clan)
                    local members = get_clan_info(clan)
                    return #members
                end

                local player_name = player:get_player_name()
                local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
                local invited_clans = {}

                local file = io.open(file_path, "r")
                if file then
                    for line in file:lines() do
                        local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                        if invited_player == player_name then
                            table.insert(invited_clans, clan_name)
                        end
                    end
                    file:close()
                end

                local clan_list_text = ""
                for _, clan in ipairs(all_clans) do
                    clan_list_text = clan_list_text .. clan .. " (" .. get_member_count(clan) .. " Members),"
                end
                clan_list_text = string.sub(clan_list_text, 1, -2)

                local invitations_count = #invited_clans
                local selected_index = event.index
                local player_name = player:get_player_name()
                local file_path = minetest.get_worldpath() .. "/claninvitation.txt"

                local file = io.open(file_path, "r")
                if file then
                    local counter = 0
                    for line in file:lines() do
                        local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                        if invited_player == player_name then
                            counter = counter + 1
                            if counter == selected_index then
                                local message = line:match("Message:%s*(.+)")
                                if message then
                                    local formspec = "size[8,9]" ..
                                    "box[-0.1,-0.1;8,0.7;black]"..
                                    "box[-0.1,3.75;8,0.7;black]"..
                                    "box[-0.1,-0.1;8,9.4;#030303]"..
                                    "textarea[0.35,1;3.5,2;invit_msg;;]" ..
                                    "label[0,0;#Clan : " .. minetest.colorize("#3e6789", player_clan) .. "]" ..
                                    "label[0,0.65;##Invitation Message]" ..
                                    "label[4,4.65;##Message from the clan.]" ..
                                    "label[0,3.9;#Personal : " .. minetest.colorize("#3e6789", "Your Inbox") .. " (You have received " .. invitations_count .. " requests)]" ..
                                    "textlist[4,1;3.5,2.5;members_list;" .. table.concat(members, ",") .. "]" ..
                                    "textlist[0,4.75;3.5,2.5;invited_clans;" .. table.concat(invited_clans, ",") .. "]" ..
                                    "field[1.8,3.05;2,1;invit_field;;]" ..
                                    "button[0.05,2.75;1.5,1;invit_btn;Invite]" ..
                                    "button[0.05,8.2;1.5,1;join_clan;Join]" ..
                                    "field[1.8,8.5;2.35,1;join_clanf;Confirm Clan Name;]" ..
                                    "tabheader[0,0;clan_tab;Clan,Invitation;2]" ..
                                    "hypertext[4.2,5.5;4.1,4;;" .. message .. "]"

                                    minetest.show_formspec(player_name, "invitation_interface", formspec)
                                    break
                                end
                            end
                        end
                    end
                    file:close()
                end
            end
        end
    end
end)

--------------------------------------------------------------------------------
---------- Join Clan Button Fonction
--------------------------------------------------------------------------------

local function on_player_receive_fields(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.join_clan then
            local join_clan_name = fields.join_clanf
            local player_name = player:get_player_name()

            local player_clan, is_leader = get_player_clan(player)
            if player_clan ~= "No Faction" then
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are already a member of a clan, you cannot join another unless you leave your current clan."))
                return
            end

            local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
            local file = io.open(file_path, "r")
            if file then
                local lines = {}
                for line in file:lines() do
                    table.insert(lines, line)
                end
                file:close()

                local found_invite = false
                local invite_line_index = nil
                for i, line in ipairs(lines) do
                    local clan, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                    if invited_player == player_name and clan == join_clan_name then
                        found_invite = true
                        invite_line_index = i
                        break
                    end
                end

                if found_invite then
                    local clan_file_path = minetest.get_worldpath() .. "/clans/" .. join_clan_name .. ".txt"
                    local clan_file = io.open(clan_file_path, "a")
                    if clan_file then
                        clan_file:write("Member: " .. player_name .. "\n")
                        clan_file:close()
                        minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You have joined the clan: " .. join_clan_name .. " !"))

                        local members, _ = get_clan_info(join_clan_name)
                        for _, name in ipairs(members) do
                            if name ~= player_name then
                                minetest.chat_send_player(name:sub(9), minetest.colorize(message_color, "[Server] -!- Player " .. player_name .. " has joined the clan!"))
                            end
                        end

                        table.remove(lines, invite_line_index)
                        local new_file = io.open(file_path, "w")
                        if new_file then
                            for _, line in ipairs(lines) do
                                new_file:write(line .. "\n")
                            end
                            new_file:close()
                        end
                    else
                        minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to join the clan. Please try again."))
                    end
                else
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You have not been invited to join this clan."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to open clan invitation file. Please try again."))
            end
        end
    end
end

--------------------------------------------------------------------------------
---------- Tabheader Fonction
--------------------------------------------------------------------------------

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "clan_interface" then
        if fields.clan_tab == "2" then
            show_invitation_interface(player)
        end
    elseif formname == "invitation_interface" then
        if fields.clan_tab == "1" then 
            show_clan_interface(player)
        end
    end
end)

--------------------------------------------------------------------------------
---------- Create Clan Button Fonction
--------------------------------------------------------------------------------

function handle_create_clan_button(player, formname, fields)
    if formname == "clan_interface" then
        local player_name = player:get_player_name()

        if fields.create then
            local clan_name = fields.clan_name

            if #clan_name < min_number_characters then
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- The clan name is too short (minimum " .. min_number_characters .. " characters)."))
                return
            elseif #clan_name > max_number_characters then
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- The clan name is too long (maximum " .. max_number_characters .. " characters)."))
                return
            end

            local folder_path = minetest.get_worldpath() .. "/clans/"
            local player_clans = {}
            local player_already_in_clan = false

            local dir_list = minetest.get_dir_list(folder_path, false)
            if dir_list then
                for _, file_name in ipairs(dir_list) do
                    local file_path = folder_path .. file_name
                    local file = io.open(file_path, "r")
                    if file then
                        local content = file:read("*all")
                        file:close()
                        if content:find("Leader: " .. player_name) or content:find("Member: " .. player_name) then
                            player_already_in_clan = true
                            break
                        end
                    end
                end
            end

            if player_already_in_clan then
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are already a member or leader of a clan."))
                return
            end

            minetest.mkdir(folder_path)

            local file_path = folder_path .. clan_name .. ".txt"
            if not io.open(file_path, "r") then
                local file = io.open(file_path, "w")
                if file then
                    file:write("Leader: " .. player_name .. "\n")
                    file:close()
                    minetest.chat_send_all(minetest.colorize(message_color, "[Server] -!- Clan '" .. clan_name .. "' has been created by " .. player_name .. "!"))
                    show_clan_interface(player)
                else
                    minetest.chat_send_player(player_name, (minetest.colorize(message_color, "[Server] -!- Unable to create clan.")))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- The clan with this name already exists. Try with another name."))
            end   
        end
    end
end

--------------------------------------------------------------------------------
---------- Delete Clan Button Fonction
--------------------------------------------------------------------------------

function handle_delete_clan_button(player, formname, fields)
    if fields.delete then
        local player_name = player:get_player_name()
        local clan_name = get_player_clan(player)

        if clan_name == "No clan" then
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are not a member of a clan."))
            return
        end

        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. clan_name .. ".txt"

        local file = io.open(file_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            if content:find("Leader: " .. player_name) then
                os.remove(file_path)
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Clan successfully removed."))
                show_clan_interface(player)

                minetest.chat_send_all(minetest.colorize(message_color, "[Server] -!- Clan '" .. clan_name .. "' has been removed by " .. player_name .. "!"))
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are not allowed to delete this clan."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to find clan."))
        end
    end
end

--------------------------------------------------------------------------------
---------- Rename Clan Fonction
--------------------------------------------------------------------------------

function handle_rename_clan_button(player, formname, fields)
    if fields.rename then
        local player_name = player:get_player_name()
        local clan_name = fields.clan_name

        if #clan_name < min_number_characters then
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- The clan name is too short (minimum " .. min_number_characters .. " characters)."))
            return
        elseif #clan_name > max_number_characters then
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- The clan name is too long (maximum " .. max_number_characters .. " characters)."))
            return
        end

        local current_clan_name, _ = get_player_clan(player)
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local current_file_path = folder_path .. current_clan_name .. ".txt"

        local file = io.open(current_file_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            if content:find("Leader: " .. player_name) then
                local new_file_path = folder_path .. clan_name .. ".txt"
                local new_file = io.open(new_file_path, "r")
                if new_file then
                    new_file:close()
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- A clan with that name already exists."))
                else
                    os.rename(current_file_path, new_file_path)
                    minetest.chat_send_all(minetest.colorize(message_color, "[Server] -!- Clan name has been changed from " .. current_clan_name .. " to " .. clan_name .. " by " .. player_name))
                    show_clan_interface(player)
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are not allowed to change the clan name. You have to be the leader."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Unable to find clan."))
        end
    end
end

--------------------------------------------------------------------------------
---------- Set Clan Home Button Fonction
--------------------------------------------------------------------------------

function handle_set_clan_home_button(player, formname, fields)
    if fields.setfhome then
        local clan_name, _ = get_player_clan(player)
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. clan_name .. ".txt"
        local player_name = player:get_player_name()
        local new_home_pos = minetest.pos_to_string(player:get_pos())

        local file = io.open(file_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            local new_content
            if content:find("Clan Home:") then
                new_content = content:gsub("Clan Home: (%S+)", "Clan Home: " .. new_home_pos)
            else
                new_content = content .. "\nClan Home: " .. new_home_pos
            end

            local new_file = io.open(file_path, "w")
            if new_file then
                new_file:write(new_content)
                new_file:close()
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Clan Home location has been updated."))
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Error updating Clan Home location."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to find clan."))
        end
    end
end

--------------------------------------------------------------------------------
---------- Clan Home Button Fonction
--------------------------------------------------------------------------------

function handle_clan_home_button(player, formname, fields)
    if fields.fhome then
        local player_name = player:get_player_name()
        local clan_name, _ = get_player_clan(player)
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. clan_name .. ".txt"

        local file = io.open(file_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            local clan_home = content:match("Clan Home: (%S+)")
            if clan_home then
                local home_pos = minetest.string_to_pos(clan_home)
                if home_pos then
                    local start_pos = player:get_pos()
                    local tolerance = 0.5
                    local timeout = 5 
                    local teleported = false

                    minetest.after(timeout, function()
                        local player = minetest.get_player_by_name(player_name)
                        if player then
                            local current_pos = player:get_pos()
                            local distance = vector.distance(current_pos, start_pos)


                            if distance < tolerance and vector.equals(current_pos, start_pos) then
                                player:set_pos(home_pos)
                                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Server] -!- You have been teleported to Clan Home."))
                                teleported = true
                            else
                                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Server] -!- Teleportation canceled. You moved or didn't stay long enough."))
                            end
                        end
                    end)
                else
                    minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Server] -!- Clan Home coordinates are invalid. Try near this point."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Server] -!- Clan Home has not been defined for this clan."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize("#aac729", "[Server] -!- Failed to find clan."))
        end
    end
end


--------------------------------------------------------------------------------
---------- Leave Clan Button Fonction
--------------------------------------------------------------------------------

function handle_leave_button(player, formname, fields)
    if fields.leave then
        local player_name = player:get_player_name()
        local clan_name, is_leader = get_player_clan(player)

        if clan_name == "Aucune clan" then
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are not a member of a clan. Create a clan or join one."))
            return
        end

        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. clan_name .. ".txt"

        local file = io.open(file_path, "r")
        if file then
            local content = file:read("*all")
            file:close()

            if is_leader then
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are the leader of this clan, you cannot leave. You have to delete it."))
                return
            end

            local new_content = ""
            local found = false
            for line in content:gmatch("[^\r\n]+") do
                if not line:find("Member: " .. player_name) then
                    new_content = new_content .. line .. "\n"
                else
                    found = true
                end
            end

            if found then
                local new_file = io.open(file_path, "w")
                if new_file then
                    new_file:write(new_content)
                    new_file:close()
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You have successfully left the clan."))
                    show_clan_interface(player)
                else
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Error leaving clan."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You are the leader of this clan, you cannot leave. You have to delete it."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to find clan."))
        end
    end
end

--------------------------------------------------------------------------------
---------- Save Button Fonction
--------------------------------------------------------------------------------

function handle_save_button(player, formname, fields)
    if fields.save_button then
        local public_info = fields.public_info or ""
        save_clan_info(player, public_info)
        show_clan_interface(player)
    end
end

--------------------------------------------------------------------------------
---------- Kick Button Fonction
--------------------------------------------------------------------------------

function handle_clan_interface(player, formname, fields)
    if formname == "clan_interface" then
        local player_name = player:get_player_name()
        local player_clan, is_leader = get_player_clan(player)

        if fields.kick then
            if is_leader then
                local kick_player = fields.clan_kick_playername

                if kick_player == player_name then
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- You cannot kick yourself from the clan."))
                    return
                end

                local folder_path = minetest.get_worldpath() .. "/clans/"
                local clan_file_path = folder_path .. player_clan .. ".txt"

                local file = io.open(clan_file_path, "r")
                if file then
                    local content = file:read("*all")
                    file:close()

                    local new_content = ""
                    local found = false
                    for line in content:gmatch("[^\r\n]+") do
                        if line:find("Member: " .. kick_player) then
                            found = true
                        else
                            new_content = new_content .. line .. "\n"
                        end
                    end

                    if found then
                        local new_file = io.open(clan_file_path, "w")
                        if new_file then
                            new_file:write(new_content)
                            new_file:close()
                            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Successfully kicked player " .. kick_player .. " from the clan."))
                        else
                            minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Error kicking player from the clan."))
                        end
                    else
                        minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Player " .. kick_player .. " is not a member of the clan."))
                    end
                else
                    minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Failed to find clan file."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(message_color, "[Server] -!- Only the clan leader can kick players from the clan."))
            end
        end
    end
end

--------------------------------------------------------------------------------
---------- Invit Button Fonction
--------------------------------------------------------------------------------

function handle_invitation(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.invit_btn then
            local clan_name, is_leader = get_player_clan(player)

            if clan_name == "No clan" then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- You are not in a clan. You can create one or join one."))
                return
            end

            if not is_leader then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Only the clan leader can invite players to the clan."))
                return
            end

            local invitation_message = fields.invit_field
            local custom_message = fields.invit_msg or ""

            local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
            local file = io.open(file_path, "r")
            if file then
                for line in file:lines() do
                    if line:find("Clan: " .. clan_name .. ", Invited: " .. invitation_message) then
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- This player has already been invited by the clan."))
                        file:close()
                        return
                    end
                end
                file:close()
            end

            file = io.open(file_path, "a")
            if file then
                file:write("Clan: " .. clan_name .. ", Invited: " .. invitation_message .. ", Message: " .. custom_message .. "\n")
                file:close()

                local invited_player = minetest.get_player_by_name(invitation_message)
                if invited_player then
                    minetest.chat_send_player(invitation_message, minetest.colorize(message_color, "[Server] -!- You have received an invitation from the clan: " .. clan_name .. "."))
                else
                    minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Invitation sent successfully, but the invited player is not online."))
                end

                minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Invitation sent successfully."))
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(message_color, "[Server] -!- Failed to send invitation."))
            end
        end
    end
end

--------------------------------------------------------------------------------
---------- On Player Receive Fields
--------------------------------------------------------------------------------
minetest.register_on_player_receive_fields(handle_invitation)
minetest.register_on_player_receive_fields(handle_clan_interface)
minetest.register_on_player_receive_fields(handle_save_button)
minetest.register_on_player_receive_fields(handle_leave_button)
minetest.register_on_player_receive_fields(handle_clan_home_button)
minetest.register_on_player_receive_fields(handle_set_clan_home_button)
minetest.register_on_player_receive_fields(handle_rename_clan_button)
minetest.register_on_player_receive_fields(handle_delete_clan_button)
minetest.register_on_player_receive_fields(handle_create_clan_button)
minetest.register_on_player_receive_fields(on_player_receive_fields)

--------------------------------------------------------------------------------
---------- On joinplayer
--------------------------------------------------------------------------------

local hud_id = {}

minetest.register_on_joinplayer(function(player)
    local player_name = player:get_player_name()
    hud_id[player_name] = player:hud_add({
        hud_elem_type = "text",
        position = {x = 0.8, y = 0.95},
        text = "",
        number = 0xaac729,
        alignment = {x = 1, y = 1},
        offset = {x = -10, y = -10},
        size = {x = 1},
    })
end)

--------------------------------------------------------------------------------
---------- GlobalStep
--------------------------------------------------------------------------------

minetest.register_globalstep(function(dtime)
    local players = minetest.get_connected_players()
    for _, player in ipairs(players) do
        local player_name = player:get_player_name()
        local player_clan, _ = get_player_clan(player)
        local members, _ = get_clan_info(player_clan)
        local member_count = #members
        local hud_text = "Your actual clan --> " .. player_clan .. " \nCurrent number of members: " .. member_count
        if hud_id[player_name] then
            player:hud_change(hud_id[player_name], "text", hud_text)
        end
    end
end)

--------------------------------------------------------------------------------
---------- Command
--------------------------------------------------------------------------------

minetest.register_chatcommand("clan_delete", {
    params = "<clan name>",
    description = "Delete a clan",
    privs = {ban=true},
    func = function(name, param)
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. param .. ".txt"

        if param == "" then
            minetest.chat_send_player(name, minetest.colorize(message_color, "[Server] -!- Incorrect syntax. Usage: /clan_delete <clan_name>"))
            return
        end

        local success, err = os.remove(file_path)
        if success then
            minetest.chat_send_all(minetest.colorize(message_color, "[Server] -!- The clan '" .. param .. "' was successfully deleted."))
        else
            minetest.chat_send_player(name, minetest.colorize(message_color,"[Server] -!- Error deleting clan '" .. param .. "': " .. tostring(err)))
        end
    end,
})

minetest.register_chatcommand("cl_who", {
    params = "<nom_du_clan>",
    description = "Affiche les membres d'un clan",
    func = function(name, param)
        local folder_path = minetest.get_worldpath() .. "/clans/"
        local file_path = folder_path .. param .. ".txt"

        local members = {}

        if minetest.file_exists(file_path) then
            local file = io.open(file_path, "r")
            if file then
                for line in file:lines() do
                    local rank, member = line:match("(%w+):%s*(%S+)")
                    if rank and member and (rank == "Member" or rank == "Leader") then
                        table.insert(members, member)
                    end
                end
                file:close()
            end

            if #members > 0 then
                local member_list = table.concat(members, ", ")
                minetest.chat_send_player(name, minetest.colorize(message_color,"[Server] -!- Clan Members '" .. param .. "': " .. member_list))
            else
                minetest.chat_send_player(name, minetest.colorize(message_color,"[Server] -!- The clan '" .. param .. "' contains no members."))
            end
        else
            minetest.chat_send_player(name, minetest.colorize(message_color,"[Server] -!- The clan '" .. param .. "' does not exist."))
        end
    end,
})


if minetest.get_modpath("unified_inventory") then

    unified_inventory.register_button("open_clan_button", {
        type = "image",
        image = "5790555.png",
        tooltip = "Open Clan Interface",
        action = function(player)
            show_clan_interface(player)
        end,
    })
end
