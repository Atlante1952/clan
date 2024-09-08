function clans.get_clan_folder_path()
    return minetest.get_worldpath() .. "/clans/"
end

function clans.read_file(file_path)
    local dir_path = file_path:match("(.+)/[^/]*$")
    if dir_path and not minetest.mkdir(dir_path) then
        minetest.log("error", "Failed to create directory: " .. dir_path)
        return nil
    end
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end
    local content = file:read("*all")
    file:close()
    return content
end

function clans.write_file(file_path, content)
    local file = io.open(file_path, "w")
    if not file then
        minetest.log("error", "Failed to open file for writing: " .. file_path)
        return false
    end
    file:write(content)
    file:close()
    return true
end

function clans.append_file(file_path, content)
    local file = io.open(file_path, "a")
    if not file then
        minetest.log("error", "Failed to open file for appending: " .. file_path)
        return false
    end
    file:write(content)
    file:close()
    return true
end

function clans.get_player_clan(player)
    local player_name = player:get_player_name()
    local folder_path = clans.get_clan_folder_path()
    local dir_list = minetest.get_dir_list(folder_path, false)
    if not dir_list then
        minetest.log("error", "Failed to get directory list: " .. folder_path)
        return "No Clan", false
    end
    for _, file_name in ipairs(dir_list) do
        local file_path = folder_path .. file_name
        local content = clans.read_file(file_path)
        if content then
            if content:find("Leader: " .. player_name) then
                return file_name:sub(1, -5), true
            elseif content:find("Member: " .. player_name) then
                return file_name:sub(1, -5), false
            end
        end
    end
    return "No Clan", false
end

function clans.get_member_count(clan)
    local members = clans.get_clan_info(clan)
    return #members
end

function clans.get_clan_info(clan_name)
    local folder_path = clans.get_clan_folder_path()
    local file_path = folder_path .. clan_name .. ".txt"
    local members = {}
    local clan_info = ""
    local content = clans.read_file(file_path)
    if content then
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

function clans.get_all_clans()
    local folder_path = clans.get_clan_folder_path()
    local clans = {}
    local dir_list = minetest.get_dir_list(folder_path, false)
    if not dir_list then
        minetest.log("error", "Failed to get directory list: " .. folder_path)
        return {}
    end
    for _, file_name in ipairs(dir_list) do
        local clan_name = file_name:sub(1, -5)
        table.insert(clans, clan_name)
    end
    return clans
end

function clans.get_total_clans_count()
    local folder_path = clans.get_clan_folder_path()
    local dir_list = minetest.get_dir_list(folder_path, false)
    if not dir_list then
        minetest.log("error", "Failed to get directory list: " .. folder_path)
        return 0
    end
    return #dir_list
end

function clans.read_invitations(file_path, player_name)
    local invited_clans = {}
    local file = io.open(file_path, "r")
    if not file then
        return {}
    end
    for line in file:lines() do
        local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
        if invited_player == player_name then
            table.insert(invited_clans, clan_name)
        end
    end
    file:close()
    return invited_clans
end

function clans.generate_clan_list_text(all_clans)
    local clan_list_text = ""
    for _, clan in ipairs(all_clans) do
        clan_list_text = clan_list_text .. clan .. " (" .. #clans.get_clan_info(clan) .. " Members),"
    end
    return string.sub(clan_list_text, 1, -2)
end

function clans.handle_invitation_button(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.invited_clans then
            local event = minetest.explode_textlist_event(fields.invited_clans)
            if event.type == "CHG" then
                local player_clan = clans.get_player_clan(player)
                local members = clans.get_clan_info(player_clan)
                local player_name = player:get_player_name()
                local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
                local invited_clans = clans.read_invitations(file_path, player_name)
                local invitations_count = #invited_clans
                local selected_index = event.index
                local file = io.open(file_path, "r")
                if not file then
                    return
                end
                local counter = 0
                for line in file:lines() do
                    local clan_name, invited_player = line:match("Clan: (%w+), Invited: (%w+)")
                    if invited_player == player_name then
                        counter = counter + 1
                        if counter == selected_index then
                            local message = line:match("Message:%s*(.+)")
                            if message then
                                clans.show_invitation_formspec(player, player_clan, members, invited_clans, invitations_count, selected_index, message)
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

function clans.handle_join_clan_button(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.join_clan then
            local join_clan_name = fields.join_clanf
            local player_name = player:get_player_name()
            local player_clan, is_leader = clans.get_player_clan(player)
            if player_clan ~= "No Clan" then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are already a member of a clan, you cannot join another unless you leave your current clan."))
                return
            end
            local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
            local file = io.open(file_path, "r")
            if not file then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Failed to open clan invitation file. Please try again."))
                return
            end
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
                if not clan_file then
                    minetest.log("error", "Failed to open file for appending: " .. clan_file_path)
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Failed to join the clan. Please try again."))
                    return
                end
                clan_file:write("Member: " .. player_name .. "\n")
                clan_file:close()
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You have joined the clan: " .. join_clan_name .. " !"))
                clans.handle_invitation_button(player, formname, fields)
                table.remove(lines, invite_line_index)
                local new_file = io.open(file_path, "w")
                if not new_file then
                    minetest.log("error", "Failed to open file for writing: " .. file_path)
                    return
                end
                for _, line in ipairs(lines) do
                    new_file:write(line .. "\n")
                end
                new_file:close()
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You have not been invited to join this clan. Or you need to confirm the name of the clan for join it."))
            end
        end
    end
end

function clans.handle_create_clan_button(player, formname, fields)
    if formname == "clan_interface" then
        local player_name = player:get_player_name()
        if fields.create then
            local clan_name = fields.clan_name
            if #clan_name < clans.min_number_characters then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The clan name is too short (minimum " .. clans.min_number_characters .. " characters)."))
                return
            elseif #clan_name > clans.max_number_characters then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The clan name is too long (maximum " .. clans.max_number_characters .. " characters)."))
                return
            end
            local folder_path = clans.get_clan_folder_path()
            local player_already_in_clan = false
            local dir_list = minetest.get_dir_list(folder_path, false)
            if dir_list then
                for _, file_name in ipairs(dir_list) do
                    local file_path = folder_path .. file_name
                    local content = clans.read_file(file_path)
                    if content then
                        if content:find("Leader: " .. player_name) or content:find("Member: " .. player_name) then
                            player_already_in_clan = true
                            break
                        end
                    end
                end
            end
            if player_already_in_clan then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are already a member or leader of a clan."))
                return
            end
            minetest.mkdir(folder_path)
            local file_path = folder_path .. clan_name .. ".txt"
            if not io.open(file_path, "r") then
                if clans.write_file(file_path, "Leader: " .. player_name .. "\n") then
                    minetest.chat_send_all(minetest.colorize(clans.message_color, "[Server] -!- Clan '" .. clan_name .. "' has been created by " .. player_name .. "!"))
                    clans.show_clan_interface(player)
                else
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Unable to create clan."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The clan with this name already exists. Try with another name."))
            end
        end
    end
end

function clans.handle_delete_clan_button(player, formname, fields)
    if fields.delete then
        local player_name = player:get_player_name()
        local clan_name, is_leader = clans.get_player_clan(player)
        if clan_name == "No Clan" then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are not a member of a clan."))
            return
        end
        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. clan_name .. ".txt"
        local content = clans.read_file(file_path)
        if content then
            if content:find("Leader: " .. player_name) then
                os.remove(file_path)
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Clan successfully removed."))
                clans.show_clan_interface(player)
                minetest.chat_send_all(minetest.colorize(clans.message_color, "[Server] -!- Clan '" .. clan_name .. "' has been removed by " .. player_name .. "!"))
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are not allowed to delete this clan."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Failed to find clan."))
        end
    end
end

function clans.handle_rename_clan_button(player, formname, fields)
    if fields.rename then
        local player_name = player:get_player_name()
        local clan_name = fields.clan_name
        if #clan_name < clans.min_number_characters then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The clan name is too short (minimum " .. clans.min_number_characters .. " characters)."))
            return
        elseif #clan_name > clans.max_number_characters then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The clan name is too long (maximum " .. clans.max_number_characters .. " characters)."))
            return
        end
        local current_clan_name, is_leader = clans.get_player_clan(player)
        local folder_path = clans.get_clan_folder_path()
        local current_file_path = folder_path .. current_clan_name .. ".txt"
        local content = clans.read_file(current_file_path)
        if content then
            if content:find("Leader: " .. player_name) then
                local new_file_path = folder_path .. clan_name .. ".txt"
                local new_file = io.open(new_file_path, "r")
                if new_file then
                    new_file:close()
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- A clan with that name already exists."))
                else
                    os.rename(current_file_path, new_file_path)
                    minetest.chat_send_all(minetest.colorize(clans.message_color, "[Server] -!- Clan name has been changed from " .. current_clan_name .. " to " .. clan_name .. " by " .. player_name))
                    clans.show_clan_interface(player)
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are not allowed to change the clan name. You have to be the leader."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Unable to find clan."))
        end
    end
end

function clans.handle_leave_button(player, formname, fields)
    if fields.leave then
        local player_name = player:get_player_name()
        local clan_name, is_leader = clans.get_player_clan(player)
        if clan_name == "No Clan" then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are not a member of a clan. Create a clan or join one."))
            return
        end
        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. clan_name .. ".txt"
        local content = clans.read_file(file_path)
        if content then
            if is_leader then
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are the leader of this clan, you cannot leave. You have to delete it."))
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
                if clans.write_file(file_path, new_content) then
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You have successfully left the clan."))
                    clans.show_clan_interface(player)
                else
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Error leaving clan."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You are the leader of this clan, you cannot leave. You have to delete it."))
            end
        else
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Failed to find clan."))
        end
    end
end

function clans.handle_clan_interface(player, formname, fields)
    if formname == "clan_interface" then
        local player_name = player:get_player_name()
        local player_clan, is_leader = clans.get_player_clan(player)
        if fields.kick then
            if is_leader then
                local kick_player = fields.clan_kick_playername
                if not kick_player or kick_player == "" then
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You must specify a player to kick."))
                    return
                end
                if kick_player == player_name then
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- You cannot kick yourself from the clan."))
                    return
                end
                local folder_path = clans.get_clan_folder_path()
                local clan_file_path = folder_path .. player_clan .. ".txt"
                local content = clans.read_file(clan_file_path)
                if content then
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
                        if clans.write_file(clan_file_path, new_content) then
                            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Successfully kicked player " .. kick_player .. " from the clan."))
                        else
                            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Error kicking player from the clan."))
                        end
                    else
                        minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Player " .. kick_player .. " is not a member of the clan."))
                    end
                else
                    minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Failed to find clan file."))
                end
            else
                minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Only the clan leader can kick players from the clan."))
            end
        end
    end
end

function clans.handle_invitation(player, formname, fields)
    if formname == "invitation_interface" then
        if fields.invit_btn then
            local clan_name, is_leader = clans.get_player_clan(player)
            if clan_name == "No clan" then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- You are not in a clan. You can create one or join one."))
                return
            end
            if not is_leader then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- Only the clan leader can invite players to the clan."))
                return
            end
            local invitation_message = fields.invit_field
            local custom_message = fields.invit_msg or ""
            if not invitation_message or invitation_message:trim() == "" then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- The invitation field cannot be empty."))
                return
            end
            if invitation_message == player:get_player_name() then
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- You cannot invite yourself."))
                return
            end
            local file_path = minetest.get_worldpath() .. "/claninvitation.txt"
            local file = io.open(file_path, "r")
            if file then
                for line in file:lines() do
                    if line:find("Clan: " .. clan_name .. ", Invited: " .. invitation_message) then
                        minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- This player has already been invited by the clan."))
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
                    minetest.chat_send_player(invitation_message, minetest.colorize(clans.message_color, "[Server] -!- You have received an invitation from the clan: " .. clan_name .. "."))
                end
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- Invitation sent successfully."))
            else
                minetest.chat_send_player(player:get_player_name(), minetest.colorize(clans.message_color, "[Server] -!- Failed to send invitation."))
            end
        end
    end
end
