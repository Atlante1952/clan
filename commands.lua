minetest.register_chatcommand("clan_delete", {
    params = "<clan name>",
    description = "Delete a clan",
    privs = {server = true},
    func = function(name, param)
        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. param .. ".txt"

        if param == "" then
            minetest.chat_send_player(name, minetest.colorize(clans.message_color, "[Server] -!- Incorrect syntax. Usage: /clan_delete <clan_name>"))
            return
        end

        local success, err = os.remove(file_path)
        if success then
            minetest.chat_send_all(minetest.colorize(clans.message_color, "[Server] -!- The clan '" .. param .. "' was successfully deleted. (By Admin)"))
        else
            minetest.chat_send_player(name, minetest.colorize(clans.message_color,"[Server] -!- Error deleting clan '" .. param .. "': " .. tostring(err)))
        end
    end,
})

minetest.register_chatcommand("clan_members", {
    description = "Affiche la liste des membres d'un clan spécifique",
    params = "<clan_name>",
    func = function(player_name, param)
        local clan_name = param
        if not clan_name then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- Vous devez spécifier le nom du clan."))
            return
        end

        local folder_path = clans.get_clan_folder_path()
        local file_path = folder_path .. clan_name .. ".txt"
        local content = clans.read_file(file_path)

        if not content then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The Clan '" .. clan_name .. "' doesn't exist."))
            return
        end

        local members = {}
        for line in content:gmatch("[^\r\n]+") do
            local rank, name = line:match("(%w+):%s*(%S+)")
            if rank and name then
                table.insert(members, rank .. ": " .. name)
            end
        end

        if #members == 0 then
            minetest.chat_send_player(player_name, minetest.colorize(clans.message_color, "[Server] -!- The Clan '" .. clan_name .. "' does not have any members."))
            return
        end

        local message = minetest.colorize(clans.message_color, "Membres du clan '" .. clan_name .. "':\n") .. table.concat(members, "\n")
        minetest.chat_send_player(player_name, message)
    end
})

minetest.register_chatcommand("clan", {
    description = "Open Clan Interface",
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if player then
            clans.show_clan_interface(player)
        end
    end,
})

minetest.register_chatcommand("c", {
    description = "Send a message to all online members of your clan",
    privs = {shout = true},
    func = function(player_name, param)
        local player = minetest.get_player_by_name(player_name)
        if not player then
            return false, "Player not found."
        end
        local clan_name, is_leader = clans.get_player_clan(player)
        if clan_name == "No Clan" then
            return false, minetest.colorize(clans.message_color, "[Server] -!-You are not a member of any clan.")
        end
        if not param or param == "" then
            return false, minetest.colorize(clans.message_color, "[Server] -!- You must provide a message.")
        end
        local members, clan_info = clans.get_clan_info(clan_name)
        local online_members = {}
        for _, member in ipairs(members) do
            local rank, name = member:match("(%w+):%s*(%S+)")
            if rank and name then
                local member_player = minetest.get_player_by_name(name)
                if member_player then
                    table.insert(online_members, name)
                end
            end
        end
        if #online_members == 0 then
            return false, minetest.colorize(clans.message_color, "[Server] -!- No online members in your clan.")
        end

        local message = minetest.colorize("#FF0000", "[Clan]" .. " <" .. player_name .. "> ") .. param
        for _, member_name in ipairs(online_members) do
            minetest.chat_send_player(member_name, message)
        end
        return true, ""
    end
})
